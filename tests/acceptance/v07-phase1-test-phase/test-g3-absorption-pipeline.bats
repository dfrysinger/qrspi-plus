#!/usr/bin/env bats
#
# Plan-level acceptance tests for G3 (Plan-author respects design-absorption
# markers — no manufactured-cleanup tasks).
#
# Maps to design.md § G3 Acceptance and plan.md Phase 1 Acceptance Criteria
# bullet 8 (zero plan-spec-reviewer absorption findings against the v0.7.3
# self-host).
#
# This file asserts the chain wiring across the four producers/consumers of
# the absorption map: the script primitive (design-absorption-markers.sh),
# the plan SKILL's pre-fanout anchor, the plan-spec reviewer rubric clause +
# dispatch-defect halt, and the design reviewer fidelity clause + dispatch-
# defect halt. Per-script and per-fixture mechanics are covered by
# tests/unit/test-design-absorption-markers.bats,
# tests/unit/test-plan-spec-reviewer-absorption.bats,
# tests/unit/test-design-reviewer-fidelity.bats,
# tests/unit/test-design-reviewer-dispatch-defect.bats, and
# tests/lint/test-design-absorption-marker-set.bats.

setup_file() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")"/../../.. && pwd)"
  export REPO_ROOT
  export ABS_SCRIPT="$REPO_ROOT/scripts/design-absorption-markers.sh"
  export PLAN_SKILL="$REPO_ROOT/skills/plan/SKILL.md"
  export PLAN_REVIEWER="$REPO_ROOT/agents/qrspi-plan-spec-reviewer.md"
  export DESIGN_REVIEWER="$REPO_ROOT/agents/qrspi-design-reviewer.md"
}

@test "acceptance: design-absorption-markers.sh exists and is executable (G3 primitive)" {
  [ -x "$ABS_SCRIPT" ]
}

@test "acceptance: plan SKILL § pre-fanout anchor cites design-absorption-markers.sh and the BLOCKED halt" {
  # G3 acceptance bullet 3 + design.md § G3 Solution change 1.
  grep -qF 'design-absorption-markers.sh' "$PLAN_SKILL"
  grep -qF 'absorbed-goal redirect map' "$PLAN_SKILL"
  grep -qF 'BLOCKED' "$PLAN_SKILL"
}

@test "acceptance: plan-spec reviewer rubric carries the absorption-map clause" {
  # G3 acceptance bullet 4.
  grep -qF 'absorption_map_path' "$PLAN_REVIEWER"
  # The clause asserts no plan task carries an absorbed-goal ID; finding is `change_type: scope`.
  grep -qF 'change_type: scope' "$PLAN_REVIEWER"
}

@test "acceptance: plan-spec reviewer carries the mandatory dispatch-defect halt at Plan step" {
  # design.md § G3 fail-loud branch: absent map at Plan step halts non-zero.
  grep -qF 'dispatch-defect:' "$PLAN_REVIEWER"
  grep -qiE 'absent.*plan step|plan step.*absent|absorption_map_path absent' "$PLAN_REVIEWER"
}

@test "acceptance: design reviewer rubric carries the fidelity-check clause" {
  # G3 acceptance bullet 5.
  grep -qF 'absorption_map_path' "$DESIGN_REVIEWER"
  grep -qiE 'fidelity|preserve.*intent|intent/marker' "$DESIGN_REVIEWER"
}

@test "acceptance: design reviewer carries the mandatory dispatch-defect halt at Design step" {
  grep -qF 'dispatch-defect:' "$DESIGN_REVIEWER"
  grep -qiE 'absent.*design step|design step.*absent' "$DESIGN_REVIEWER"
}

setup() {
  # Per-test scratch under bats-managed tmpdir (auto-removed even on crash).
  FIX="$BATS_TEST_TMPDIR/abs"
  mkdir -p "$FIX"
}

@test "integration: design-absorption-markers.sh produces TSV redirect map shape against marker fixture" {
  # End-to-end shape check; map preserves <absorbed-ID> → <absorbing-ID|"no-task"> contract.
  cat > "$FIX/design.md" <<'EOF'
# Design
## G7 — Some goal: absorbed by CD-1
Body referring to absorption.
## G8 — Another goal
Body.
EOF
  run "$ABS_SCRIPT" "$FIX/design.md"
  [ "$status" -eq 0 ]
  # Output is tab-separated; G7 maps to CD-1, G8 should not appear (no marker).
  echo "$output" | grep -qE '^G7[[:space:]]+CD-1$'
}
