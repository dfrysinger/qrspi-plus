#!/usr/bin/env bats
#
# T07 Slice 1 unit pin — G5 per-task telemetry emission contract.
#
# Pins the contract documented in skills/implement/SKILL.md §
# "Per-Task Telemetry Emission" (`reviews/telemetry/round-NN/task-NN.json`):
#   - file location shape
#   - four required fields (routing_decision, fix_cycle_count,
#     review_finding_category_counts, citation_density_rerun_count)
#   - loud-failure-on-absence orchestrator-side contract
#
# Bash 3.2 portable.

load '../helpers/skill-markdown'

_extract_h4() {
  local file="$1" text="$2"
  local target="#### $text"
  local out
  out="$(awk -v target="$target" '
    BEGIN { inside=0; found=0 }
    {
      if (inside == 1) {
        if ($0 ~ /^#{1,4} /) { inside=0; next }
        print $0
        next
      }
      if ($0 == target) { inside=1; found=1; next }
    }
    END { if (found == 0) exit 1 }
  ' "$file")" || { echo "h4 anchor not found: $target in $file" >&2; return 1; }
  if [ -z "$out" ]; then
    echo "h4 extract empty: $target in $file" >&2
    return 1
  fi
  printf '%s\n' "$out"
}

setup_file() {
  require_repo_root
  IMPLEMENT="$REPO_ROOT/skills/implement/SKILL.md"
  export IMPLEMENT
}

# ---------------------------------------------------------------------------
# File location shape: reviews/telemetry/round-NN/task-NN.json
# ---------------------------------------------------------------------------

@test "telemetry path shape: reviews/telemetry/round-NN/task-NN.json is documented" {
  run grep -F "reviews/telemetry/round-NN/task-NN.json" "$IMPLEMENT"
  [ "$status" -eq 0 ]
}

@test "telemetry path: emitted at task-DONE time, after per-task fix loop terminates" {
  out="$(_extract_h4 "$IMPLEMENT" 'Per-Task Telemetry Emission (`reviews/telemetry/round-NN/task-NN.json`)')"
  [[ "$out" == *"task-DONE time"* ]]
  [[ "$out" == *"after the per-task fix loop terminates"* ]]
}

@test "telemetry emission: fires regardless of outcome (success, BLOCKED, escalated)" {
  out="$(_extract_h4 "$IMPLEMENT" 'Per-Task Telemetry Emission (`reviews/telemetry/round-NN/task-NN.json`)')"
  [[ "$out" == *"regardless of outcome"* ]]
  [[ "$out" == *"success"* ]]
  [[ "$out" == *"BLOCKED"* ]]
  [[ "$out" == *"escalated"* ]]
}

# ---------------------------------------------------------------------------
# Four required fields: each named in the contract prose.
# ---------------------------------------------------------------------------

@test "required field: routing_decision (with role/provider/model/layer)" {
  out="$(_extract_h4 "$IMPLEMENT" 'Per-Task Telemetry Emission (`reviews/telemetry/round-NN/task-NN.json`)')"
  [[ "$out" == *"routing_decision"* ]]
  [[ "$out" == *"role"* ]]
  [[ "$out" == *"provider"* ]]
  [[ "$out" == *"model"* ]]
  [[ "$out" == *"layer"* ]]
}

@test "required field: fix_cycle_count (0..3 hardcoded fix-loop ceiling)" {
  out="$(_extract_h4 "$IMPLEMENT" 'Per-Task Telemetry Emission (`reviews/telemetry/round-NN/task-NN.json`)')"
  [[ "$out" == *"fix_cycle_count"* ]]
  [[ "$out" == *"hardcoded fix-loop ceiling"* ]] || [[ "$out" == *"up to 3"* ]]
}

@test "required field: review_finding_category_counts (style/clarity/correctness/scope/intent)" {
  out="$(_extract_h4 "$IMPLEMENT" 'Per-Task Telemetry Emission (`reviews/telemetry/round-NN/task-NN.json`)')"
  [[ "$out" == *"review_finding_category_counts"* ]]
  [[ "$out" == *"style"* ]]
  [[ "$out" == *"clarity"* ]]
  [[ "$out" == *"correctness"* ]]
  [[ "$out" == *"scope"* ]]
  [[ "$out" == *"intent"* ]]
}

@test "required field: citation_density_rerun_count (integer; 0 when no specialist or no re-run)" {
  out="$(_extract_h4 "$IMPLEMENT" 'Per-Task Telemetry Emission (`reviews/telemetry/round-NN/task-NN.json`)')"
  [[ "$out" == *"citation_density_rerun_count"* ]]
  [[ "$out" == *"integer"* ]]
}

# ---------------------------------------------------------------------------
# Loud-failure-on-absence: orchestrator emits named diagnostic + halts.
# ---------------------------------------------------------------------------

@test "absence: loud failure — orchestrator MUST emit named diagnostic and halt the batch" {
  out="$(_extract_h4 "$IMPLEMENT" 'Per-Task Telemetry Emission (`reviews/telemetry/round-NN/task-NN.json`)')"
  [[ "$out" == *"Absence is a loud failure"* ]]
  [[ "$out" == *"MUST emit a named diagnostic and halt the batch"* ]]
}

@test "absence: telemetry absence is NOT a silent skip" {
  out="$(_extract_h4 "$IMPLEMENT" 'Per-Task Telemetry Emission (`reviews/telemetry/round-NN/task-NN.json`)')"
  [[ "$out" == *"NOT a silent skip"* ]]
}

# ---------------------------------------------------------------------------
# G5 acceptance contract dependency.
# ---------------------------------------------------------------------------

@test "G5 contract: telemetry corpus completeness gates G5 living-matrix tuning" {
  out="$(_extract_h4 "$IMPLEMENT" 'Per-Task Telemetry Emission (`reviews/telemetry/round-NN/task-NN.json`)')"
  [[ "$out" == *"G5 living-config matrix is tuned from this corpus"* ]] || [[ "$out" == *"G5 acceptance contract depends on the corpus being complete"* ]]
}
