#!/usr/bin/env bats
#
# Plan-level acceptance tests for G4 (Apply-fix protocol carries a plan-step
# upstream-artifact entry; pipeline-mode-aware).
#
# Maps to design.md § G4 Acceptance and plan.md Phase 1 Acceptance Criteria
# bullet 9 (Plan-step verifier dispatch carries a deterministic
# upstream_paths parameter equal to the fixture-expected set for
# pipeline: full).

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

@test "acceptance: Plan step pipeline:full emits the documented full upstream set" {
  # design.md § G4 Acceptance bullet 1.
  printf 'pipeline: full\n' > "$FIX/config.md"
  run "$SCRIPT" --step plan --artifact-dir "$FIX"
  [ "$status" -eq 0 ]
  for expected in goals.md research/summary.md design.md phasing.md structure.md \
                  skills/plan/SKILL.md skills/using-qrspi/SKILL.md \
                  skills/implementer-protocol/SKILL.md; do
    echo "$output" | grep -qxF "$expected" || {
      echo "missing expected path: $expected" >&2
      echo "actual output:" >&2
      echo "$output" >&2
      false
    }
  done
}

@test "acceptance: Plan step pipeline:quick emits the documented quick upstream set" {
  # design.md § G4 Acceptance bullet 2.
  printf 'pipeline: quick\n' > "$FIX/config.md"
  run "$SCRIPT" --step plan --artifact-dir "$FIX"
  [ "$status" -eq 0 ]
  for expected in goals.md research/summary.md \
                  skills/plan/SKILL.md skills/using-qrspi/SKILL.md \
                  skills/implementer-protocol/SKILL.md; do
    echo "$output" | grep -qxF "$expected" || {
      echo "missing expected path: $expected" >&2
      false
    }
  done
  # quick mode does NOT include design.md / phasing.md / structure.md.
  ! echo "$output" | grep -qxF 'design.md'
  ! echo "$output" | grep -qxF 'phasing.md'
  ! echo "$output" | grep -qxF 'structure.md'
}

@test "boundary: Plan step with malformed pipeline: value halts named diagnostic" {
  # G4 acceptance bullet 3 — fail-loud direction.
  printf 'pipeline: turbo\n' > "$FIX/config.md"
  run "$SCRIPT" --step plan --artifact-dir "$FIX"
  [ "$status" -ne 0 ]
  echo "$output" | grep -q 'config-malformed:'
}

@test "acceptance: Plan-step output is deterministic across repeat invocations (G4 reproducibility)" {
  # plan.md Phase 1 Acceptance bullet 9 — deterministic upstream_paths.
  printf 'pipeline: full\n' > "$FIX/config.md"
  run "$SCRIPT" --step plan --artifact-dir "$FIX"
  [ "$status" -eq 0 ]
  first="$output"
  run "$SCRIPT" --step plan --artifact-dir "$FIX"
  [ "$status" -eq 0 ]
  [ "$first" = "$output" ]
}
