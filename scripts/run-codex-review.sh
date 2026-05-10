#!/usr/bin/env bash
# run-codex-review.sh — single entrypoint for Codex reviewer dispatches.
#
# Assembles a Codex reviewer prompt by concatenating the reviewer-protocol
# body, the named agent body (frontmatter stripped), the codex-emission
# override, and a Dispatch parameters block; pipes the result to
# scripts/codex-companion-bg.sh launch. The dispatch shape lives here so
# every step skill calls one entrypoint instead of duplicating the
# assembly inline.
#
# Usage:
#   scripts/run-codex-review.sh \
#     --agent-file agents/qrspi-spec-reviewer.md \
#     --reviewer-tag spec-codex \
#     --output-dir <ABS>/reviews/tasks/task-NN/round-N/ \
#     --round N \
#     (--subject-code <path> | --artifact-body <path>) \
#     [--subject-code <path> ...]    # repeatable, all wrap under same field
#     [--task-def tasks/task-NN.md]  # emits task_definition: (absence is
#                                    # load-bearing — see test-phase reuse) \
#     [--companion <name>=<path> ...] # generic, repeatable; multiple paths
#                                    # with the same name concatenate under
#                                    # one field. e.g. --companion plan=plan.md \
#     [--field <name>=<value> ...]   # generic, repeatable; emits `<name>: <value>`
#                                    # as a plain (non-wrapped) scalar field.
#                                    # Used for fields like `route:` that pass
#                                    # configuration values, not artifact bodies. \
#     [--diff-file <ABS>/reviews/tasks/task-NN/round-N.diff] \
#     [--scope-hint 'path/a.ts, path/b.ts'] \
#     [--dry-run]
#
# Field naming. Most step skills emit the primary-artifact field as
# `artifact_body:`; implement / integrate / test emit it as `subject_code:`
# (per reviewer-protocol § Dispatch Contract — the two are synonyms with
# per-step convention). Pass either `--subject-code` or `--artifact-body`
# accordingly; both are repeatable and concatenate wrapped blocks under
# the chosen field. Exactly one of the two must be present.
#
# Companions. `--companion <name>=<path>` emits the field `<name>:` followed
# by the wrapped file body. The flag is repeatable; multiple paths sharing
# the same name concatenate (used for fields like `companion_task_specs`
# that aggregate per-task wrapped blocks).
#
# All path-style flags are repo-relative (the wrapper's reference is the
# qrspi-plus repo root) UNLESS they contain a leading `/` (absolute path) —
# in that case the wrapper uses them verbatim. `--output-dir` MUST be
# absolute and is enforced (the orchestrator already computes
# `<ABS_ARTIFACT_DIR>/...`; a relative value would also defeat the
# agent-side `/reviews/test/` substring fail-loud check from
# reviewer-protocol § Phase Routing).
# `--diff-file` is documented as absolute by convention (orchestrator
# emits to `<ABS_ARTIFACT_DIR>`); only a file-existence check enforces it.
#
# `--scope-hint` takes a comma-separated string OR an empty value. When
# omitted entirely, no `scope_hint:` line is emitted (broaden semantics
# per reviewer-protocol § Reviewer Dispatch Contract). When passed with
# an empty value, an empty-wrapped scope_hint line is emitted (semantically
# equivalent to absence; reviewers treat them the same).
#
# `--dry-run` prints the assembled prompt to stdout instead of piping
# to codex-companion-bg.sh. Used for testing the wrapper's prompt shape
# without launching a real Codex job.
#
# Exit codes:
#   0   success (or jobId on stdout when not --dry-run)
#   1   missing required flag, file not found, or other validation error
#   N   any non-zero exit from codex-companion-bg.sh launch passes through

set -u
# NOT -e: we want to surface validation errors with our own diagnostics.
# pipefail is similarly off because we tolerate trailing-pipe-failure
# (codex-companion-bg.sh handles its own error contract).

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------

# Derive REPO_ROOT from the wrapper's own location (scripts/ is one level
# below repo root). This is robust against the caller's CWD — orchestrators
# may invoke the wrapper from any working directory (worktree, target repo,
# or main qrspi-plus checkout). Override via QRSPI_REPO_ROOT for tests.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT_DEFAULT="$(cd "$SCRIPT_DIR/.." && pwd -P)"
REPO_ROOT="${QRSPI_REPO_ROOT:-$REPO_ROOT_DEFAULT}"

AGENT_FILE=""
REVIEWER_TAG=""
OUTPUT_DIR=""
ROUND=""
TASK_DEF=""
DIFF_FILE=""
SCOPE_HINT=""
SCOPE_HINT_SET="false"
DRY_RUN="false"

# Primary-artifact field. Exactly one of subject_code or artifact_body is
# emitted (both flags collect into separate arrays so we can detect misuse).
SUBJECT_CODE_PATHS=()
ARTIFACT_BODY_PATHS=()

# Companion fields. Parallel arrays (name, path); multiple paths with the
# same name concatenate under one field. Bash 3-compatible — no associative.
COMPANION_NAMES=()
COMPANION_PATHS=()

# Plain scalar fields — emitted as `name: value` with no wrapping.
SCALAR_NAMES=()
SCALAR_VALUES=()

# Helper: ensure a value-taking flag has its value present in argv. With
# `set -u` enabled, dereferencing `$2` for a flag passed as the last arg
# would otherwise crash with `unbound variable` instead of the wrapper's
# documented `error:` diagnostic.
require_value() {
  # $1 = flag name (for diagnostic), $2 = $# from the caller's scope
  if [[ "$2" -lt 2 ]]; then
    echo "error: $1 requires a value" >&2
    exit 1
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --agent-file)     require_value "--agent-file"   "$#"; AGENT_FILE="$2"; shift 2 ;;
    --reviewer-tag)   require_value "--reviewer-tag" "$#"; REVIEWER_TAG="$2"; shift 2 ;;
    --output-dir)     require_value "--output-dir"   "$#"; OUTPUT_DIR="$2"; shift 2 ;;
    --round)          require_value "--round"        "$#"; ROUND="$2"; shift 2 ;;
    --subject-code)   require_value "--subject-code" "$#"; SUBJECT_CODE_PATHS+=("$2"); shift 2 ;;
    --artifact-body)  require_value "--artifact-body" "$#"; ARTIFACT_BODY_PATHS+=("$2"); shift 2 ;;
    --task-def)       require_value "--task-def"     "$#"; TASK_DEF="$2"; shift 2 ;;
    --companion)
      require_value "--companion" "$#"
      # Expect NAME=PATH. Split on the first `=`.
      if [[ "$2" != *=* ]]; then
        echo "error: --companion requires NAME=PATH (got: $2)" >&2
        exit 1
      fi
      cname="${2%%=*}"
      cpath="${2#*=}"
      if [[ -z "$cname" || -z "$cpath" ]]; then
        echo "error: --companion NAME=PATH must have non-empty NAME and PATH (got: $2)" >&2
        exit 1
      fi
      # Restrict NAME to valid identifier chars to keep the emitted dispatch
      # parameter line well-formed.
      if [[ ! "$cname" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
        echo "error: --companion NAME must match [A-Za-z_][A-Za-z0-9_]* (got: $cname)" >&2
        exit 1
      fi
      COMPANION_NAMES+=("$cname")
      COMPANION_PATHS+=("$cpath")
      shift 2
      ;;
    --field)
      require_value "--field" "$#"
      # Expect NAME=VALUE. Same NAME validation as --companion (kept consistent
      # so the emitted field-name is well-formed). VALUE may be empty.
      if [[ "$2" != *=* ]]; then
        echo "error: --field requires NAME=VALUE (got: $2)" >&2
        exit 1
      fi
      fname="${2%%=*}"
      fvalue="${2#*=}"
      if [[ -z "$fname" ]]; then
        echo "error: --field NAME=VALUE must have non-empty NAME (got: $2)" >&2
        exit 1
      fi
      if [[ ! "$fname" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
        echo "error: --field NAME must match [A-Za-z_][A-Za-z0-9_]* (got: $fname)" >&2
        exit 1
      fi
      SCALAR_NAMES+=("$fname")
      SCALAR_VALUES+=("$fvalue")
      shift 2
      ;;
    --diff-file)      require_value "--diff-file"  "$#"; DIFF_FILE="$2"; shift 2 ;;
    --scope-hint)     require_value "--scope-hint" "$#"; SCOPE_HINT="$2"; SCOPE_HINT_SET="true"; shift 2 ;;
    --dry-run)        DRY_RUN="true"; shift ;;
    *)
      echo "error: unrecognized flag: $1" >&2
      exit 1
      ;;
  esac
done

# ---------------------------------------------------------------------------
# Validation
# ---------------------------------------------------------------------------

require_flag() {
  local name="$1"
  local val="$2"
  if [[ -z "$val" ]]; then
    echo "error: --${name} required" >&2
    exit 1
  fi
}

require_flag "agent-file"   "$AGENT_FILE"
require_flag "reviewer-tag" "$REVIEWER_TAG"
require_flag "output-dir"   "$OUTPUT_DIR"
require_flag "round"        "$ROUND"

# --output-dir must be absolute. The orchestrator already computes
# <ABS_ARTIFACT_DIR>/... at every dispatch site, so a non-absolute value
# is always a mistake. This is also load-bearing for the agent-side
# Phase Routing fail-loud check (reviewer-protocol § Phase Routing):
# per-task reviewer agents
# detect the contradiction `task_definition supplied + output dir contains
# /reviews/test/`. A relative `reviews/test/...` would defeat the
# substring check; rejecting non-absolute values closes the bypass.
if [[ "$OUTPUT_DIR" != /* ]]; then
  echo "error: --output-dir must be absolute (got: $OUTPUT_DIR)" >&2
  exit 1
fi

# Exactly one of --subject-code or --artifact-body must be present.
if [[ ${#SUBJECT_CODE_PATHS[@]} -eq 0 && ${#ARTIFACT_BODY_PATHS[@]} -eq 0 ]]; then
  echo "error: at least one --subject-code or --artifact-body required" >&2
  exit 1
fi
if [[ ${#SUBJECT_CODE_PATHS[@]} -gt 0 && ${#ARTIFACT_BODY_PATHS[@]} -gt 0 ]]; then
  echo "error: --subject-code and --artifact-body are mutually exclusive (pick the per-step name)" >&2
  exit 1
fi
if [[ ${#SUBJECT_CODE_PATHS[@]} -gt 0 ]]; then
  PRIMARY_FIELD="subject_code"
  PRIMARY_PATHS=("${SUBJECT_CODE_PATHS[@]}")
else
  PRIMARY_FIELD="artifact_body"
  PRIMARY_PATHS=("${ARTIFACT_BODY_PATHS[@]}")
fi

# Resolve a flag's path: if absolute, use verbatim; otherwise resolve against REPO_ROOT.
resolve_path() {
  local p="$1"
  if [[ "$p" == /* ]]; then
    echo "$p"
  else
    echo "$REPO_ROOT/$p"
  fi
}

assert_file_exists() {
  local label="$1"
  local p="$2"
  if [[ ! -f "$p" ]]; then
    echo "error: ${label} not found: $p" >&2
    exit 1
  fi
}

# Resolve required files
AGENT_FILE_ABS="$(resolve_path "$AGENT_FILE")"
assert_file_exists "agent-file" "$AGENT_FILE_ABS"

REVIEWER_PROTOCOL_ABS="$REPO_ROOT/skills/reviewer-protocol/SKILL.md"
assert_file_exists "reviewer-protocol/SKILL.md" "$REVIEWER_PROTOCOL_ABS"

EMISSION_OVERRIDE_ABS="$REPO_ROOT/skills/reviewer-protocol/codex-emission-override.md"
assert_file_exists "codex-emission-override.md" "$EMISSION_OVERRIDE_ABS"

# Parse the agent's `skills:` frontmatter field to discover additional
# shared skills the agent depends on. Claude-side dispatches preload
# these via Claude Code's frontmatter mechanism; the Codex wrapper has
# no equivalent, so we load them here. Each named skill resolves to
# `skills/<name>/SKILL.md` and is concatenated before the agent body in
# `compose_prompt`. The hardcoded `reviewer-protocol` is skipped to
# avoid double-loading.
#
# Supported shape (the only shape this parser accepts):
#   skills: [reviewer-protocol]
#   skills: [reviewer-protocol, research-isolation]
#
# Any other `skills:` frontmatter form (block-list `skills:\n  - a`,
# scalar `skills: foo`, etc.) is rejected loudly with exit code 2 — a
# silent skip would replicate the very semantic-loss bug this load
# chain exists to fix. Surrounding quotes on individual names are
# tolerated and stripped (so `["a", "b"]` and `[a, b]` are equivalent
# inputs).
extract_skill_names() {
  awk '
    /^---$/ { n++; if (n == 2) exit; next }
    n == 1 && /^skills:/ {
      if ($0 !~ /^skills:[[:space:]]*\[/) {
        printf "error: skills: frontmatter must use inline-list form `skills: [a, b, c]`; other forms (block-list, scalar) are not supported.\n" > "/dev/stderr"
        exit 2
      }
      sub(/^skills:[[:space:]]*\[/, "")
      sub(/\].*$/, "")
      gsub(/[[:space:]"'\'']/, "")
      n_items = split($0, items, ",")
      for (i = 1; i <= n_items; i++) {
        if (items[i] != "") print items[i]
      }
    }
  ' "$1"
}

# Capture into a variable so the awk exit code propagates (process
# substitution would discard it). The wrapper does not use `set -e`,
# so check the exit status explicitly: a nonzero awk exit means the
# parser detected an unsupported `skills:` shape and already wrote a
# diagnostic to stderr.
if ! SKILL_NAMES_OUTPUT="$(extract_skill_names "$AGENT_FILE_ABS")"; then
  exit 1
fi

ADDITIONAL_SKILL_PATHS=()
while IFS= read -r skill_name; do
  if [[ -z "$skill_name" || "$skill_name" == "reviewer-protocol" ]]; then
    continue
  fi
  skill_path="$REPO_ROOT/skills/$skill_name/SKILL.md"
  assert_file_exists "skill[$skill_name]" "$skill_path"
  ADDITIONAL_SKILL_PATHS+=("$skill_path")
done <<< "$SKILL_NAMES_OUTPUT"

# Resolve primary-artifact files (repeating). PRIMARY_PATHS holds either
# the --subject-code or --artifact-body inputs per the field selection above.
PRIMARY_ABS=()
for sc in "${PRIMARY_PATHS[@]}"; do
  abs="$(resolve_path "$sc")"
  assert_file_exists "$PRIMARY_FIELD" "$abs"
  PRIMARY_ABS+=("$abs")
done

# Resolve optional task-def
TASK_DEF_ABS=""
if [[ -n "$TASK_DEF" ]]; then
  TASK_DEF_ABS="$(resolve_path "$TASK_DEF")"
  assert_file_exists "task-def" "$TASK_DEF_ABS"
fi

# Resolve companions (parallel arrays)
COMPANION_ABS=()
for i in "${!COMPANION_PATHS[@]}"; do
  cpath="${COMPANION_PATHS[$i]}"
  cname="${COMPANION_NAMES[$i]}"
  abs="$(resolve_path "$cpath")"
  assert_file_exists "companion[$cname]" "$abs"
  COMPANION_ABS+=("$abs")
done

# diff_file is absolute by convention (orchestrator emits to ABS_ARTIFACT_DIR)
if [[ -n "$DIFF_FILE" ]]; then
  if [[ ! -f "$DIFF_FILE" ]]; then
    echo "error: diff-file not found: $DIFF_FILE" >&2
    exit 1
  fi
fi

# ---------------------------------------------------------------------------
# Marker-injection guard.
#
# `compose_prompt` emits `<<<AGENT-BODY-END>>>` between the trusted
# protocol/agent-body sections and the orchestrator-supplied dispatch
# parameters; agent self-reference exception clauses (e.g.
# research-isolation Pre-Flight) reference that marker for a positional
# carve-out.
#
# An attacker- or drift-controlled artifact body containing the literal
# marker would emit a SECOND occurrence inside an UNTRUSTED-ARTIFACT
# block, after which the agent — looking only for the marker name — could
# treat post-second-marker content as trusted, defeating the carve-out.
#
# Refuse the dispatch if any orchestrator-supplied input contains the
# literal marker. The marker is a wrapper-private invariant; legitimate
# inputs have no reason to carry it. (Trusted body files — agent file,
# reviewer-protocol, emission-override — are NOT scanned: their content
# IS the agent body the marker delimits.)
MARKER_LITERAL="<<<AGENT-BODY-END>>>"

reject_if_contains_marker_file() {
  # $1 = label for diagnostic, $2 = file path
  if grep -F -q -- "$MARKER_LITERAL" "$2" 2>/dev/null; then
    echo "error: ${1} contains the wrapper-private marker '${MARKER_LITERAL}' (path: $2). This would defeat the agent-body carve-out; reject the input." >&2
    exit 1
  fi
}

reject_if_contains_marker_value() {
  # $1 = label for diagnostic, $2 = value (string)
  if [[ "$2" == *"$MARKER_LITERAL"* ]]; then
    echo "error: ${1} contains the wrapper-private marker '${MARKER_LITERAL}'. This would defeat the agent-body carve-out; reject the input." >&2
    exit 1
  fi
}

# Scan every orchestrator-supplied path-style input.
for p in "${PRIMARY_ABS[@]}"; do
  reject_if_contains_marker_file "${PRIMARY_FIELD}" "$p"
done
if [[ -n "$TASK_DEF_ABS" ]]; then
  reject_if_contains_marker_file "task-def" "$TASK_DEF_ABS"
fi
for i in "${!COMPANION_ABS[@]}"; do
  reject_if_contains_marker_file "companion[${COMPANION_NAMES[$i]}]" "${COMPANION_ABS[$i]}"
done
if [[ -n "$DIFF_FILE" ]]; then
  reject_if_contains_marker_file "diff-file" "$DIFF_FILE"
fi
# Scan inline scalar values too (--scope-hint, --field VALUE).
if [[ "$SCOPE_HINT_SET" == "true" ]]; then
  reject_if_contains_marker_value "scope-hint" "$SCOPE_HINT"
fi
for i in "${!SCALAR_NAMES[@]}"; do
  reject_if_contains_marker_value "field[${SCALAR_NAMES[$i]}]" "${SCALAR_VALUES[$i]}"
done

# ---------------------------------------------------------------------------
# Wrapping helpers
# ---------------------------------------------------------------------------

# Strip ONLY the leading YAML frontmatter block (between the file's first
# two `^---$` lines), then print the body verbatim. The earlier pattern
# (`/^---$/{n++; next} n>=2{print}`) ate every `^---$` line, including
# body-level horizontal rules and fenced YAML mini-frontmatter examples
# (e.g., `skills/reviewer-protocol/SKILL.md` body and the `## Output`
# template inside `agents/qrspi-research-{specialist,collator}.md`).
# Silent body corruption — fixed here by gating `next` on `n<2`.
strip_frontmatter() {
  awk '/^---$/ && n<2 {n++; next} n>=2 {print}' "$1"
}

# Emit a single UNTRUSTED-ARTIFACT block: header, file body, footer.
# `id` defaults to the input path; allow override for callers that need it.
emit_untrusted_artifact() {
  local path="$1"
  local id="${2:-$1}"
  printf '<<<UNTRUSTED-ARTIFACT-START id=%s>>>\n' "$id"
  cat "$path"
  printf '\n<<<UNTRUSTED-ARTIFACT-END id=%s>>>\n' "$id"
}

# Build the dispatch-parameters block. Optional fields are omitted entirely
# when their inputs were not provided.
emit_dispatch_parameters() {
  printf '\n\n## Dispatch parameters\n\n'

  # Required: primary artifact field (subject_code OR artifact_body) — one
  # wrapped block per path, concatenated under a single field header.
  printf '%s:\n' "$PRIMARY_FIELD"
  for i in "${!PRIMARY_ABS[@]}"; do
    emit_untrusted_artifact "${PRIMARY_ABS[$i]}" "${PRIMARY_PATHS[$i]}"
    printf '\n'
  done

  # Optional: task_definition. Absence is the load-bearing signal in
  # test-step reuse mode (test/SKILL.md § Test-phase reuse contract).
  if [[ -n "$TASK_DEF_ABS" ]]; then
    printf 'task_definition:\n'
    emit_untrusted_artifact "$TASK_DEF_ABS" "$TASK_DEF"
    printf '\n'
  fi

  # Companions: walk parallel arrays, emit each unique field name once
  # (header), then concatenate every wrapped block whose name matches.
  # Preserves caller-given order. Bash 3-compatible (no associative array).
  emitted_names=" "
  for i in "${!COMPANION_NAMES[@]}"; do
    name="${COMPANION_NAMES[$i]}"
    if [[ "$emitted_names" != *" $name "* ]]; then
      printf '%s:\n' "$name"
      emitted_names="${emitted_names}${name} "
      # Walk all entries with this name in caller order.
      for j in "${!COMPANION_NAMES[@]}"; do
        if [[ "${COMPANION_NAMES[$j]}" == "$name" ]]; then
          emit_untrusted_artifact "${COMPANION_ABS[$j]}" "${COMPANION_PATHS[$j]}"
          printf '\n'
        fi
      done
    fi
  done

  # Plain scalar fields (no wrapping) — emitted in caller-given order.
  for i in "${!SCALAR_NAMES[@]}"; do
    printf '%s: %s\n' "${SCALAR_NAMES[$i]}" "${SCALAR_VALUES[$i]}"
  done

  # Canonical field name per reviewer-protocol/SKILL.md § Reviewer Dispatch
  # Contract. The 4 step skills that previously emitted `output:` (an
  # undocumented per-step alias) are normalized via the wrapper.
  printf 'round_subdir: %s\n' "$OUTPUT_DIR"
  printf 'round: %s\n' "$ROUND"
  printf 'reviewer_tag: %s\n' "$REVIEWER_TAG"

  if [[ -n "$DIFF_FILE" ]]; then
    printf 'diff_file_path: %s\n' "$DIFF_FILE"
  fi

  if [[ "$SCOPE_HINT_SET" == "true" ]]; then
    # Wrapper emits the line unconditionally when --scope-hint was passed,
    # even with empty value (semantically equivalent to absence; reviewers
    # treat the empty-wrapped form and the omitted form the same).
    printf 'scope_hint: <<<UNTRUSTED-SCOPE-HINT-START id=scope_hint>>>%s<<<UNTRUSTED-SCOPE-HINT-END id=scope_hint>>>\n' "$SCOPE_HINT"
  fi
}

# ---------------------------------------------------------------------------
# Compose the prompt
# ---------------------------------------------------------------------------

compose_prompt() {
  strip_frontmatter "$REVIEWER_PROTOCOL_ABS"
  printf '\n\n---\n\n'
  # Gate on length to avoid `unbound variable` under `set -u` on Bash 3.2
  # (macOS system /bin/bash) when the additional-skills array is empty.
  if (( ${#ADDITIONAL_SKILL_PATHS[@]} > 0 )); then
    for skill_path in "${ADDITIONAL_SKILL_PATHS[@]}"; do
      strip_frontmatter "$skill_path"
      printf '\n\n---\n\n'
    done
  fi
  strip_frontmatter "$AGENT_FILE_ABS"
  printf '\n\n---\n\n'
  cat "$EMISSION_OVERRIDE_ABS"
  # Structural boundary marker. Everything BEFORE this marker is the
  # trusted protocol/agent body assembled by the wrapper; everything
  # AFTER is orchestrator-supplied dispatch parameters. Agent
  # self-reference exception clauses (e.g., research agents' Pre-Flight
  # Isolation Check) reference this marker so the carve-out is
  # positional, not prose-only — closing the "leak quotes the exception
  # language" bypass surface.
  #
  # Marker uniqueness is enforced by the marker-injection guard above:
  # any orchestrator-supplied input containing this literal string is
  # rejected before we get here, so the marker emitted on this line is
  # the only occurrence in the assembled prompt. Without that guard, an
  # injected literal could produce a SECOND marker inside an UNTRUSTED-
  # ARTIFACT block, re-opening the bypass.
  printf '\n\n<<<AGENT-BODY-END>>>\n'
  emit_dispatch_parameters
}

# ---------------------------------------------------------------------------
# Dispatch
# ---------------------------------------------------------------------------

if [[ "$DRY_RUN" == "true" ]]; then
  compose_prompt
  exit 0
fi

LAUNCH="$REPO_ROOT/scripts/codex-companion-bg.sh"
if [[ ! -x "$LAUNCH" ]]; then
  echo "error: codex-companion-bg.sh not executable at $LAUNCH" >&2
  exit 1
fi

compose_prompt | "$LAUNCH" launch
exit "$?"
