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
#     --subject-code <repo-relative path> \
#     [--subject-code <repo-relative path> ...] \
#     [--task-def tasks/task-NN.md] \
#     [--companion-plan plan.md] \
#     [--companion-goals goals.md] \
#     [--companion-test-expectations-file <path>] \
#     [--diff-file <ABS>/reviews/tasks/task-NN/round-N.diff] \
#     [--scope-hint 'path/a.ts, path/b.ts'] \
#     [--dry-run]
#
# All path-style flags (`--subject-code`, `--task-def`, `--companion-plan`,
# `--companion-goals`, `--diff-file`, `--agent-file`) are repo-relative
# (the wrapper Cwd is the qrspi-plus repo root) UNLESS they contain a
# leading `/` (absolute path) — in that case the wrapper uses them verbatim.
# The `--output-dir` flag must be absolute (the orchestrator already
# computes `<ABS_ARTIFACT_DIR>/reviews/...` so this is naturally absolute).
#
# `--companion-test-expectations-file` takes a path because the test-
# expectations block is extracted from plan.md by the orchestrator and
# spelled out into a tempfile (no canonical location to wrap-by-path).
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
COMPANION_PLAN=""
COMPANION_GOALS=""
COMPANION_TEST_EXP_FILE=""
DIFF_FILE=""
SCOPE_HINT=""
SCOPE_HINT_SET="false"
DRY_RUN="false"

# Repeating flag: --subject-code can appear N times.
SUBJECT_CODE_PATHS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --agent-file)                       AGENT_FILE="$2"; shift 2 ;;
    --reviewer-tag)                     REVIEWER_TAG="$2"; shift 2 ;;
    --output-dir)                       OUTPUT_DIR="$2"; shift 2 ;;
    --round)                            ROUND="$2"; shift 2 ;;
    --subject-code)                     SUBJECT_CODE_PATHS+=("$2"); shift 2 ;;
    --task-def)                         TASK_DEF="$2"; shift 2 ;;
    --companion-plan)                   COMPANION_PLAN="$2"; shift 2 ;;
    --companion-goals)                  COMPANION_GOALS="$2"; shift 2 ;;
    --companion-test-expectations-file) COMPANION_TEST_EXP_FILE="$2"; shift 2 ;;
    --diff-file)                        DIFF_FILE="$2"; shift 2 ;;
    --scope-hint)                       SCOPE_HINT="$2"; SCOPE_HINT_SET="true"; shift 2 ;;
    --dry-run)                          DRY_RUN="true"; shift ;;
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

if [[ ${#SUBJECT_CODE_PATHS[@]} -eq 0 ]]; then
  echo "error: at least one --subject-code required" >&2
  exit 1
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

# Resolve subject_code files (repeating)
SUBJECT_CODE_ABS=()
for sc in "${SUBJECT_CODE_PATHS[@]}"; do
  abs="$(resolve_path "$sc")"
  assert_file_exists "subject-code" "$abs"
  SUBJECT_CODE_ABS+=("$abs")
done

# Resolve optional files
TASK_DEF_ABS=""
if [[ -n "$TASK_DEF" ]]; then
  TASK_DEF_ABS="$(resolve_path "$TASK_DEF")"
  assert_file_exists "task-def" "$TASK_DEF_ABS"
fi

COMPANION_PLAN_ABS=""
if [[ -n "$COMPANION_PLAN" ]]; then
  COMPANION_PLAN_ABS="$(resolve_path "$COMPANION_PLAN")"
  assert_file_exists "companion-plan" "$COMPANION_PLAN_ABS"
fi

COMPANION_GOALS_ABS=""
if [[ -n "$COMPANION_GOALS" ]]; then
  COMPANION_GOALS_ABS="$(resolve_path "$COMPANION_GOALS")"
  assert_file_exists "companion-goals" "$COMPANION_GOALS_ABS"
fi

COMPANION_TEST_EXP_ABS=""
if [[ -n "$COMPANION_TEST_EXP_FILE" ]]; then
  COMPANION_TEST_EXP_ABS="$(resolve_path "$COMPANION_TEST_EXP_FILE")"
  assert_file_exists "companion-test-expectations-file" "$COMPANION_TEST_EXP_ABS"
fi

# diff_file is absolute by convention (orchestrator emits to ABS_ARTIFACT_DIR)
if [[ -n "$DIFF_FILE" ]]; then
  if [[ ! -f "$DIFF_FILE" ]]; then
    echo "error: diff-file not found: $DIFF_FILE" >&2
    exit 1
  fi
fi

# ---------------------------------------------------------------------------
# Wrapping helpers
# ---------------------------------------------------------------------------

# Strip YAML frontmatter (everything up through the second `---` line) and
# print the body. Matches the awk pattern used at every prior dispatch site.
strip_frontmatter() {
  awk '/^---$/{n++; next} n>=2{print}' "$1"
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

  # Required: subject_code (one wrapped block per file, concatenated).
  printf 'subject_code:\n'
  for i in "${!SUBJECT_CODE_ABS[@]}"; do
    local path="${SUBJECT_CODE_ABS[$i]}"
    local id="${SUBJECT_CODE_PATHS[$i]}"
    emit_untrusted_artifact "$path" "$id"
    printf '\n'
  done

  # Optional: task_definition. Absence is the load-bearing signal in
  # test-step reuse mode (test/SKILL.md § Test-phase reuse contract).
  if [[ -n "$TASK_DEF_ABS" ]]; then
    printf 'task_definition:\n'
    emit_untrusted_artifact "$TASK_DEF_ABS" "$TASK_DEF"
    printf '\n'
  fi

  # Optional: companion_plan / companion_goals (goal-traceability, test-coverage).
  if [[ -n "$COMPANION_PLAN_ABS" ]]; then
    printf 'companion_plan:\n'
    emit_untrusted_artifact "$COMPANION_PLAN_ABS" "$COMPANION_PLAN"
    printf '\n'
  fi
  if [[ -n "$COMPANION_GOALS_ABS" ]]; then
    printf 'companion_goals:\n'
    emit_untrusted_artifact "$COMPANION_GOALS_ABS" "$COMPANION_GOALS"
    printf '\n'
  fi
  if [[ -n "$COMPANION_TEST_EXP_ABS" ]]; then
    printf 'companion_test_expectations:\n'
    emit_untrusted_artifact "$COMPANION_TEST_EXP_ABS" "test-expectations"
    printf '\n'
  fi

  printf 'output: %s\n' "$OUTPUT_DIR"
  printf 'round: %s\n' "$ROUND"
  printf 'reviewer_tag: %s\n' "$REVIEWER_TAG"

  if [[ -n "$DIFF_FILE" ]]; then
    printf 'diff_file_path: %s\n' "$DIFF_FILE"
  fi

  if [[ "$SCOPE_HINT_SET" == "true" ]]; then
    # Codex pattern emits the line unconditionally with the wrapper, even when
    # the value is empty (broaden semantics). Reviewers treat empty-value as
    # semantically identical to absence per reviewer-protocol contract.
    printf 'scope_hint: <<<UNTRUSTED-SCOPE-HINT-START id=scope_hint>>>%s<<<UNTRUSTED-SCOPE-HINT-END id=scope_hint>>>\n' "$SCOPE_HINT"
  fi
}

# ---------------------------------------------------------------------------
# Compose the prompt
# ---------------------------------------------------------------------------

compose_prompt() {
  strip_frontmatter "$REVIEWER_PROTOCOL_ABS"
  printf '\n\n---\n\n'
  strip_frontmatter "$AGENT_FILE_ABS"
  printf '\n\n---\n\n'
  cat "$EMISSION_OVERRIDE_ABS"
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
