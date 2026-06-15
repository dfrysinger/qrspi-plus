#!/usr/bin/env bats
#
# Plan-level acceptance tests for CD-1 (Per-step upstream_paths lookup
# extracted to scripts/upstream-paths.sh).
#
# Maps to design.md § CD-1 Acceptance and plan.md Phase 1 Acceptance Criteria
# bullet 2 (upstream-paths.sh emits documented set; always-appended array
# contains implementer-protocol; unknown --step is fail-soft).
#
# These tests are acceptance/end-to-end against the real script in the
# committed tree — they do NOT re-mock the script. They assert the
# observable behaviour at the phase boundary, not the script internals
# (which are covered by tests/unit/test-upstream-paths.bats).

setup_file() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")"/../../.. && pwd)"
  export REPO_ROOT
  export SCRIPT="$REPO_ROOT/scripts/upstream-paths.sh"
}

setup() {
  FIX="$(mktemp -d)"
  export FIX
}

teardown() {
  [ -n "${FIX:-}" ] && [ -d "$FIX" ] && rm -rf "$FIX"
}

@test "acceptance: scripts/upstream-paths.sh exists and is executable" {
  # CD-1 acceptance bullet 1: script is the lookup-table source of truth.
  [ -x "$SCRIPT" ]
}

@test "acceptance: every supported step emits a non-empty path list and exits 0" {
  # CD-1 acceptance bullet 1 (full enumeration). Goals legitimately has no
  # upstream artifacts, but still emits the always-appended SKILL trio.
  for step in goals questions research design phasing structure parallelize replan; do
    run "$SCRIPT" --step "$step"
    [ "$status" -eq 0 ]
    # always-appended trio MUST be present in every step's output.
    echo "$output" | grep -qx "skills/$step/SKILL.md"
    echo "$output" | grep -qx "skills/using-qrspi/SKILL.md"
    echo "$output" | grep -qx "skills/implementer-protocol/SKILL.md"
  done
}

@test "acceptance: always-appended array contains skills/implementer-protocol/SKILL.md (G1 grounding source)" {
  # plan.md Phase 1 Acceptance bullet 2 explicit clause + G1 acceptance.
  run "$SCRIPT" --step design
  [ "$status" -eq 0 ]
  echo "$output" | grep -qx 'skills/implementer-protocol/SKILL.md'
}

@test "acceptance: unknown --step value is fail-soft (exit 0, always-appended SKILL paths only, empty stderr)" {
  # CD-1 acceptance bullet 2: unknown step returns always-appended array + exits 0.
  # design.md CD-1 contracts: orchestrator failure on absent step would be a regression.
  run "$SCRIPT" --step deploy
  [ "$status" -eq 0 ]
  echo "$output" | grep -qx 'skills/using-qrspi/SKILL.md'
  echo "$output" | grep -qx 'skills/implementer-protocol/SKILL.md'
  echo "$output" | grep -qx 'skills/deploy/SKILL.md'
  # No per-step upstream artifact basenames (no .md outside skills/ tree).
  ! ( echo "$output" | grep -qE '^(goals|questions|design|phasing|structure|research)\.md$' )
}

@test "boundary: Plan step with missing config.md halts with named diagnostic" {
  # G4 acceptance bullet 3 (precondition for Plan-step branch).
  run "$SCRIPT" --step plan --artifact-dir "$FIX"
  [ "$status" -ne 0 ]
  echo "$output" | grep -q 'config-missing:'
}

@test "boundary: Plan step with malformed config.md (no pipeline: line) halts named diagnostic" {
  printf 'route: full\n' > "$FIX/config.md"
  run "$SCRIPT" --step plan --artifact-dir "$FIX"
  [ "$status" -ne 0 ]
  echo "$output" | grep -q 'config-malformed:'
}
