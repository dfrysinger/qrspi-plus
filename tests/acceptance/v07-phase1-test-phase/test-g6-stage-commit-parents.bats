#!/usr/bin/env bats
bats_require_minimum_version 1.5.0
#
# Plan-level acceptance / e2e tests for G6 (Stage-commit parent SHAs
# validated against named task tips).
#
# Maps to design.md § G6 Acceptance and plan.md Phase 1 Acceptance Criteria
# bullet 12 (every Implement-wave stage commit passes
# validate-stage-commit-parents.sh --validate silently; parallelization.md
# unchanged across the phase — preserving symbolic-only branch-map invariant
# per research Q11/Q12).
#
# Per-script behaviour is exhaustively covered by
# tests/unit/test-validate-stage-commit-parents.bats; this file proves the
# end-to-end capture+validate round-trip plus the SKILL wrap.

setup_file() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")"/../../.. && pwd)"
  export REPO_ROOT
  export VSCP="$REPO_ROOT/scripts/validate-stage-commit-parents.sh"
  export IMPLEMENT_SKILL="$REPO_ROOT/skills/implement/SKILL.md"
}

setup() {
  # Per-test scratch under bats-managed tmpdir (see g5 note).
  TMP_DIR="$BATS_TEST_TMPDIR/work"
  mkdir -p "$TMP_DIR"
  cd "$TMP_DIR"
  git init -q -b main .
  git config user.email "human@example.com"
  git config user.name "Human Author"
  echo seed > seed.txt
  git add seed.txt
  git commit -q -m seed
  INTEGRATION_BASE="$(git rev-parse HEAD)"
  # Two task branches diverging from base.
  for t in task-A task-B; do
    git checkout -q -b "$t" "$INTEGRATION_BASE"
    echo "$t" > "$t.txt"
    git add "$t.txt"
    git commit -q -m "$t work"
  done
  git checkout -q main
  export TMP_DIR INTEGRATION_BASE
}

# No teardown() needed — bats removes $BATS_TEST_TMPDIR itself.

@test "acceptance: validate-stage-commit-parents.sh exists and is executable (G6 primitive)" {
  [ -x "$VSCP" ]
}

@test "acceptance: implement SKILL Wave Dispatch wraps merge with --capture and --validate" {
  # G6 acceptance bullet 3 — capture step and validate step both invoked.
  grep -qE 'validate-stage-commit-parents\.sh[[:space:]]+--capture' "$IMPLEMENT_SKILL"
  grep -qE 'validate-stage-commit-parents\.sh[[:space:]]+--validate' "$IMPLEMENT_SKILL"
}

@test "e2e: --capture + correct stage merge + --validate round-trip passes silently" {
  # design.md § G6 Acceptance bullet 1 (positive direction).
  run "$VSCP" --capture --wave-id W2 \
      --task-branch task-A --task-branch task-B \
      --wave-state-dir "$TMP_DIR/reviews/implement/wave-state"
  [ "$status" -eq 0 ]
  [ -f "$TMP_DIR/reviews/implement/wave-state/W2.sidecar" ]

  # Perform a real first-parent stage merge: octopus with --no-ff. Use `run`
  # + status check so a conflict surfaces a clear diagnostic instead of
  # being swallowed by `>/dev/null 2>&1`.
  run git merge --no-ff -m "stage W2" task-A task-B
  [ "$status" -eq 0 ] || {
    echo "stage merge failed unexpectedly; output:" >&2
    echo "$output" >&2
    false
  }

  run "$VSCP" --validate --wave-id W2 \
      --wave-state-dir "$TMP_DIR/reviews/implement/wave-state"
  [ "$status" -eq 0 ]
}

@test "boundary: --validate halts named stage-commit-parent-mismatch when an extra parent is present" {
  # design.md § G6 Acceptance bullet 1 (extra-parent direction).
  run "$VSCP" --capture --wave-id W3 \
      --task-branch task-A \
      --wave-state-dir "$TMP_DIR/reviews/implement/wave-state"
  [ "$status" -eq 0 ]

  # Merge BOTH task tips though only task-A was captured. Status-checked so
  # a precondition-failure (conflict) is visible rather than masquerading
  # as a --validate signal downstream.
  run git merge --no-ff -m "stage W3 extra" task-A task-B
  [ "$status" -eq 0 ] || {
    echo "stage merge failed unexpectedly; output:" >&2
    echo "$output" >&2
    false
  }

  run "$VSCP" --validate --wave-id W3 \
      --wave-state-dir "$TMP_DIR/reviews/implement/wave-state"
  [ "$status" -ne 0 ]
  echo "$output" | grep -q 'stage-commit-parent-mismatch'
}
