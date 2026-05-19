#!/usr/bin/env bash
# run-codex-review.sh — thin forwarder around scripts/run-third-party-llm.sh.
#
# Per T04 of the v0.7 release: this script no longer drives the Codex broker
# directly. It preserves its existing caller-facing flag surface (assembling
# the reviewer prompt from the reviewer-protocol body, the named agent body
# with frontmatter stripped, the codex-emission override, and a Dispatch
# parameters block), and then forwards the assembled prompt over stdin to
# `scripts/run-third-party-llm.sh` with `--provider codex --model <id>
# --output-file <path> --artifact-dir <dir>`. Transport selection
# (codex-broker) is config-driven via the `codex` entry in
# `<artifact-dir>/config.md`'s `providers:` block — this shim does NOT pass
# a transport flag. The dispatcher's exit code is propagated unchanged.
#
# Usage (existing flag surface preserved, three new required flags added
# for the dispatcher hand-off):
#   scripts/run-codex-review.sh \
#     --agent-file agents/qrspi-spec-reviewer.md \
#     --reviewer-tag spec-codex \
#     --output-dir <ABS>/reviews/tasks/task-NN/round-N/ \
#     --round N \
#     --model <codex-model-id> \                           # NEW: forwarded as --model
#     --output-file <ABS>/.../result.md \                  # NEW: forwarded as --output-file
#     --artifact-dir <ABS>/docs/qrspi/<run-id>/ \          # NEW: forwarded as --artifact-dir
#     (--subject-code <path> | --artifact-body <path>) \
#     [--subject-code <path> ...]
#     [--task-def tasks/task-NN.md]
#     [--companion NAME=PATH ...]
#     [--field NAME=VALUE ...]
#     [--diff-file <ABS>/reviews/tasks/task-NN/round-N.diff] \
#     [--scope-hint 'path/a.ts, path/b.ts'] \
#     [--timeout-seconds <int>] \
#     [--dry-run]
#
# Stdin is NOT consumed from the caller — the shim assembles the prompt
# itself from the named artifacts (per the existing caller contract) and
# pipes the assembled prompt to the dispatcher's stdin. The dispatcher's
# prompt-source contract (stdin-only) is preserved end-to-end.
#
# Exit codes (propagated unchanged from the dispatcher; no remapping):
#   0   success — --output-file populated
#   1   validation / argument failure (this shim or the dispatcher)
#   10  upstream timeout (forwarded from dispatcher)
#   11  job not found (forwarded from dispatcher)
#   13  upstream hard-error (forwarded from dispatcher)
#   14  malformed result body (forwarded from dispatcher)
#   15  phantom-launch (forwarded from dispatcher)

set -u
# NOT -e: we want to surface validation errors with our own diagnostics.
# pipefail is off because the dispatcher handles its own error contract.

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------

# Derive REPO_ROOT from the wrapper's own location (scripts/ is one level
# below repo root). Override via QRSPI_REPO_ROOT for tests.
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
MODEL=""
OUTPUT_FILE=""
ARTIFACT_DIR=""
TIMEOUT_SECONDS=""

SUBJECT_CODE_PATHS=()
ARTIFACT_BODY_PATHS=()

COMPANION_NAMES=()
COMPANION_PATHS=()

SCALAR_NAMES=()
SCALAR_VALUES=()

require_value() {
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
    --model)          require_value "--model"        "$#"; MODEL="$2"; shift 2 ;;
    --output-file)    require_value "--output-file"  "$#"; OUTPUT_FILE="$2"; shift 2 ;;
    --artifact-dir)   require_value "--artifact-dir" "$#"; ARTIFACT_DIR="$2"; shift 2 ;;
    --timeout-seconds) require_value "--timeout-seconds" "$#"; TIMEOUT_SECONDS="$2"; shift 2 ;;
    --subject-code)   require_value "--subject-code" "$#"; SUBJECT_CODE_PATHS+=("$2"); shift 2 ;;
    --artifact-body)  require_value "--artifact-body" "$#"; ARTIFACT_BODY_PATHS+=("$2"); shift 2 ;;
    --task-def)       require_value "--task-def"     "$#"; TASK_DEF="$2"; shift 2 ;;
    --companion)
      require_value "--companion" "$#"
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

# New required flags for the dispatcher hand-off. Without --artifact-dir
# the dispatcher would exit 1 per T03's required-flag contract — surface
# that as a shim-side diagnostic so callers see the missing flag clearly.
require_flag "model"        "$MODEL"
require_flag "output-file"  "$OUTPUT_FILE"
require_flag "artifact-dir" "$ARTIFACT_DIR"

# --output-dir must be absolute (load-bearing for agent-side Phase Routing
# fail-loud substring check on /reviews/test/).
if [[ "$OUTPUT_DIR" != /* ]]; then
  echo "error: --output-dir must be absolute (got: $OUTPUT_DIR)" >&2
  exit 1
fi

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

AGENT_FILE_ABS="$(resolve_path "$AGENT_FILE")"
assert_file_exists "agent-file" "$AGENT_FILE_ABS"

REVIEWER_PROTOCOL_ABS="$REPO_ROOT/skills/reviewer-protocol/SKILL.md"
assert_file_exists "reviewer-protocol/SKILL.md" "$REVIEWER_PROTOCOL_ABS"

EMISSION_OVERRIDE_ABS="$REPO_ROOT/skills/reviewer-protocol/codex-emission-override.md"
assert_file_exists "codex-emission-override.md" "$EMISSION_OVERRIDE_ABS"

# Parse the agent's `skills:` frontmatter field to discover additional
# shared skills the agent depends on (load chain unchanged from pre-T04).
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

SKILL_NAMES_OUTPUT="$(extract_skill_names "$AGENT_FILE_ABS")"
extract_status=$?
if [ "$extract_status" -ne 0 ]; then
  exit "$extract_status"
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

PRIMARY_ABS=()
for sc in "${PRIMARY_PATHS[@]}"; do
  abs="$(resolve_path "$sc")"
  assert_file_exists "$PRIMARY_FIELD" "$abs"
  PRIMARY_ABS+=("$abs")
done

TASK_DEF_ABS=""
if [[ -n "$TASK_DEF" ]]; then
  TASK_DEF_ABS="$(resolve_path "$TASK_DEF")"
  assert_file_exists "task-def" "$TASK_DEF_ABS"
fi

COMPANION_ABS=()
for i in "${!COMPANION_PATHS[@]}"; do
  cpath="${COMPANION_PATHS[$i]}"
  cname="${COMPANION_NAMES[$i]}"
  abs="$(resolve_path "$cpath")"
  assert_file_exists "companion[$cname]" "$abs"
  COMPANION_ABS+=("$abs")
done

if [[ -n "$DIFF_FILE" ]]; then
  if [[ ! -f "$DIFF_FILE" ]]; then
    echo "error: diff-file not found: $DIFF_FILE" >&2
    exit 1
  fi
fi

# ---------------------------------------------------------------------------
# Marker-injection guard (unchanged from pre-T04). The dispatcher applies
# its own boundary-marker guard on stdin; this shim's guard is an additional
# defense-in-depth layer on the per-flag inputs before the prompt is
# assembled.
MARKER_LITERAL="<<<AGENT-BODY-END>>>"

reject_if_contains_marker_file() {
  if grep -F -q -- "$MARKER_LITERAL" "$2" 2>/dev/null; then
    echo "error: ${1} contains the wrapper-private marker '${MARKER_LITERAL}' (path: $2). This would defeat the agent-body carve-out; reject the input." >&2
    exit 1
  fi
}

reject_if_contains_marker_value() {
  if [[ "$2" == *"$MARKER_LITERAL"* ]]; then
    echo "error: ${1} contains the wrapper-private marker '${MARKER_LITERAL}'. This would defeat the agent-body carve-out; reject the input." >&2
    exit 1
  fi
}

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
if [[ "$SCOPE_HINT_SET" == "true" ]]; then
  reject_if_contains_marker_value "scope-hint" "$SCOPE_HINT"
fi
for i in "${!SCALAR_NAMES[@]}"; do
  reject_if_contains_marker_value "field[${SCALAR_NAMES[$i]}]" "${SCALAR_VALUES[$i]}"
done

# ---------------------------------------------------------------------------
# Prompt-assembly helpers (unchanged from pre-T04)
# ---------------------------------------------------------------------------

strip_frontmatter() {
  awk '/^---$/ && n<2 {n++; next} n>=2 {print}' "$1"
}

emit_untrusted_artifact() {
  local path="$1"
  local id="${2:-$1}"
  printf '<<<UNTRUSTED-ARTIFACT-START id=%s>>>\n' "$id"
  cat "$path"
  printf '\n<<<UNTRUSTED-ARTIFACT-END id=%s>>>\n' "$id"
}

emit_dispatch_parameters() {
  printf '\n\n## Dispatch parameters\n\n'

  printf '%s:\n' "$PRIMARY_FIELD"
  for i in "${!PRIMARY_ABS[@]}"; do
    emit_untrusted_artifact "${PRIMARY_ABS[$i]}" "${PRIMARY_PATHS[$i]}"
    printf '\n'
  done

  if [[ -n "$TASK_DEF_ABS" ]]; then
    printf 'task_definition:\n'
    emit_untrusted_artifact "$TASK_DEF_ABS" "$TASK_DEF"
    printf '\n'
  fi

  emitted_names=" "
  for i in "${!COMPANION_NAMES[@]}"; do
    name="${COMPANION_NAMES[$i]}"
    if [[ "$emitted_names" != *" $name "* ]]; then
      printf '%s:\n' "$name"
      emitted_names="${emitted_names}${name} "
      for j in "${!COMPANION_NAMES[@]}"; do
        if [[ "${COMPANION_NAMES[$j]}" == "$name" ]]; then
          emit_untrusted_artifact "${COMPANION_ABS[$j]}" "${COMPANION_PATHS[$j]}"
          printf '\n'
        fi
      done
    fi
  done

  for i in "${!SCALAR_NAMES[@]}"; do
    printf '%s: %s\n' "${SCALAR_NAMES[$i]}" "${SCALAR_VALUES[$i]}"
  done

  printf 'round_subdir: %s\n' "$OUTPUT_DIR"
  printf 'round: %s\n' "$ROUND"
  printf 'reviewer_tag: %s\n' "$REVIEWER_TAG"

  if [[ -n "$DIFF_FILE" ]]; then
    printf 'diff_file_path: %s\n' "$DIFF_FILE"
  fi

  if [[ "$SCOPE_HINT_SET" == "true" ]]; then
    printf 'scope_hint: <<<UNTRUSTED-SCOPE-HINT-START id=scope_hint>>>%s<<<UNTRUSTED-SCOPE-HINT-END id=scope_hint>>>\n' "$SCOPE_HINT"
  fi
}

compose_prompt() {
  strip_frontmatter "$REVIEWER_PROTOCOL_ABS"
  printf '\n\n---\n\n'
  if (( ${#ADDITIONAL_SKILL_PATHS[@]} > 0 )); then
    for skill_path in "${ADDITIONAL_SKILL_PATHS[@]}"; do
      strip_frontmatter "$skill_path"
      printf '\n\n---\n\n'
    done
  fi
  strip_frontmatter "$AGENT_FILE_ABS"
  printf '\n\n---\n\n'
  cat "$EMISSION_OVERRIDE_ABS"
  printf '\n\n<<<AGENT-BODY-END>>>\n'
  emit_dispatch_parameters
}

# ---------------------------------------------------------------------------
# Forward to the universal dispatcher.
# Per T04: this shim does NOT pass a transport flag — transport selection is
# config-driven through the `codex` entry in `<artifact-dir>/config.md`'s
# `providers:` block (which carries `transport_type: codex-broker`). The
# shim does NOT source or invoke `scripts/codex-companion-bg.sh` directly;
# the broker chaining happens inside the dispatcher's codex-broker branch.
# ---------------------------------------------------------------------------

if [[ "$DRY_RUN" == "true" ]]; then
  compose_prompt
  exit 0
fi

DISPATCHER="$REPO_ROOT/scripts/run-third-party-llm.sh"
if [[ ! -x "$DISPATCHER" && ! -r "$DISPATCHER" ]]; then
  echo "error: run-third-party-llm.sh not found at $DISPATCHER" >&2
  exit 1
fi

# Build dispatcher argv. --provider codex is hardcoded; --model, --output-file,
# and --artifact-dir come from the shim's caller. Optional --timeout-seconds
# is forwarded when present.
DISPATCHER_ARGS=(
  --provider codex
  --model "$MODEL"
  --output-file "$OUTPUT_FILE"
  --artifact-dir "$ARTIFACT_DIR"
)
if [[ -n "$TIMEOUT_SECONDS" ]]; then
  DISPATCHER_ARGS+=(--timeout-seconds "$TIMEOUT_SECONDS")
fi

# Pipe the assembled prompt to the dispatcher's stdin and propagate its
# exit code unchanged (per the exit-code matrix above).
compose_prompt | bash "$DISPATCHER" "${DISPATCHER_ARGS[@]}"
exit "$?"
