#!/usr/bin/env bats
# ============================================================================
# Unit tests for scripts/validate-stage-commit-parents.sh — G6.
#
# Pins behaviors enumerated in the task spec "Test expectations":
#   - --capture writes a runtime sidecar with separable integration_base /
#     task_tip_shas fields under reviews/implement/wave-state/.
#   - --validate reads the sidecar and asserts (a) actual_parents[0] equals
#     captured integration-base SHA (first-parent ordering invariant) and
#     (b) the set of remaining parents equals the set of captured task-tip
#     SHAs.
#   - Named diagnostics on each failure mode:
#       stage-commit-parent-mismatch:   parent invariant violated
#       sha-format-invalid:             malformed SHA in sidecar
#       sidecar-missing:                no sidecar present
#       sidecar-schema-mismatch:        sidecar present but malformed shape
#       capture-git-error:              underlying git rev-parse failed
#       capture-sidecar-write-error:    sidecar write failed
#   - Single-task-wave passes when integration-base + sole task tip make up
#     the parent set; halts when either is absent.
#   - Symbolic-only branch-map invariant: parallelization.md (if present) is
#     never touched by --capture.
#   - Sidecar-missing is distinct from sidecar-schema-mismatch and prevents
#     git log against HEAD from running in --validate.
# ============================================================================

setup() {
  TEST_ROOT=$(mktemp -d)
  REPO_ROOT=$(cd "$BATS_TEST_DIRNAME/../.." && pwd)
  SCRIPT="$REPO_ROOT/scripts/validate-stage-commit-parents.sh"

  FIX="$TEST_ROOT/repo"
  mkdir -p "$FIX"
  (
    cd "$FIX"
    git init -q -b main 2>/dev/null || git init -q
    git checkout -q -b main 2>/dev/null || true
    git config user.email t@t.local
    git config user.name tester
    git config commit.gpgsign false
    echo seed > seed.txt
    git add seed.txt
    git commit -q -m seed
  )

  WAVE_DIR="$FIX/reviews/implement/wave-state"
}

teardown() {
  rm -rf "$TEST_ROOT"
}

# ── Helpers ─────────────────────────────────────────────────────────────────

# make_task_branch <branch-name>  — branch off main, add a commit, return to main.
make_task_branch() {
  local b=$1
  (
    cd "$FIX"
    git checkout -q -b "$b" main
    echo "$b content" > "$b.txt"
    git add "$b.txt"
    git commit -q -m "work on $b"
    git checkout -q main
  )
}

# make_stage_commit <branches...>  — on main, octopus-merge the given branches
# with --no-ff. integration base = main HEAD prior to merge.
make_stage_commit() {
  (
    cd "$FIX"
    git checkout -q main
    git merge -q --no-ff -m "stage" "$@"
  )
}

sha_of() {
  (cd "$FIX" && git rev-parse "$1")
}

run_script() {
  (cd "$FIX" && "$SCRIPT" "$@")
}

# ── Existence ───────────────────────────────────────────────────────────────

@test "script exists and is executable" {
  [ -f "$SCRIPT" ]
  [ -x "$SCRIPT" ]
}

# ── --capture: sidecar shape ────────────────────────────────────────────────

@test "capture writes integration_base and task_tip_shas as separable fields" {
  make_task_branch task-aa
  make_task_branch task-bb
  base=$(sha_of HEAD)
  tip1=$(sha_of task-aa)
  tip2=$(sha_of task-bb)

  run run_script --capture --wave-id W1 --task-branch task-aa --task-branch task-bb
  [ "$status" -eq 0 ]

  sidecar="$WAVE_DIR/W1.sidecar"
  [ -f "$sidecar" ]
  grep -q "^integration_base=$base$" "$sidecar"
  grep -qE "^task_tip_shas=" "$sidecar"
  # Both tips present in task_tip_shas value (order-insensitive).
  tips_line=$(grep "^task_tip_shas=" "$sidecar" | sed 's/^task_tip_shas=//')
  echo "$tips_line" | tr ' ' '\n' | grep -qx "$tip1"
  echo "$tips_line" | tr ' ' '\n' | grep -qx "$tip2"
}

@test "capture does not modify parallelization.md (symbolic-only branch-map invariant)" {
  mkdir -p "$FIX/docs"
  echo "PINNED CONTENT" > "$FIX/parallelization.md"
  before=$(shasum "$FIX/parallelization.md" | awk '{print $1}')
  make_task_branch task-aa
  run run_script --capture --wave-id W1 --task-branch task-aa
  [ "$status" -eq 0 ]
  after=$(shasum "$FIX/parallelization.md" | awk '{print $1}')
  [ "$before" = "$after" ]
}

# ── --validate: pass paths ──────────────────────────────────────────────────

@test "validate passes silently on correct multi-task stage commit" {
  make_task_branch task-aa
  make_task_branch task-bb
  run run_script --capture --wave-id W1 --task-branch task-aa --task-branch task-bb
  [ "$status" -eq 0 ]
  make_stage_commit task-aa task-bb

  run run_script --validate --wave-id W1
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "validate passes silently on correct single-task stage commit (lower-bound boundary)" {
  make_task_branch task-aa
  run run_script --capture --wave-id W1 --task-branch task-aa
  [ "$status" -eq 0 ]
  make_stage_commit task-aa

  run run_script --validate --wave-id W1
  [ "$status" -eq 0 ]
}

# ── --validate: stage-commit-parent-mismatch ───────────────────────────────

@test "validate halts when integration-base is not parent[0] (first-parent ordering invariant)" {
  make_task_branch task-aa
  make_task_branch task-bb
  base=$(sha_of HEAD)
  run run_script --capture --wave-id W1 --task-branch task-aa --task-branch task-bb
  [ "$status" -eq 0 ]

  # Construct a stage commit where task-aa is parent[0] (wrong ordering).
  (
    cd "$FIX"
    git checkout -q task-aa
    git merge -q --no-ff -m "wrong-order stage" main task-bb
  )

  run run_script --validate --wave-id W1
  [ "$status" -ne 0 ]
  echo "$output" | grep -q "stage-commit-parent-mismatch:"
  # Diagnostic names the wrong first-parent SHA.
  wrong_first=$(cd "$FIX" && git log --format='%P' -n 1 HEAD | awk '{print $1}')
  echo "$output" | grep -q "$wrong_first"
}

@test "validate halts when a task tip is missing from the parent set" {
  make_task_branch task-aa
  make_task_branch task-bb
  tip_bb=$(sha_of task-bb)
  # Capture both tips, but stage-merge only task-aa.
  run run_script --capture --wave-id W1 --task-branch task-aa --task-branch task-bb
  [ "$status" -eq 0 ]
  make_stage_commit task-aa

  run run_script --validate --wave-id W1
  [ "$status" -ne 0 ]
  echo "$output" | grep -q "stage-commit-parent-mismatch:"
  # Diagnostic names the missing task-tip SHA.
  echo "$output" | grep -q "$tip_bb"
}

@test "validate halts when an unexpected extra parent is present" {
  make_task_branch task-aa
  make_task_branch task-bb
  make_task_branch task-extra
  tip_extra=$(sha_of task-extra)
  # Capture only aa+bb, but octopus-merge aa+bb+extra.
  run run_script --capture --wave-id W1 --task-branch task-aa --task-branch task-bb
  [ "$status" -eq 0 ]
  make_stage_commit task-aa task-bb task-extra

  run run_script --validate --wave-id W1
  [ "$status" -ne 0 ]
  echo "$output" | grep -q "stage-commit-parent-mismatch:"
  echo "$output" | grep -q "$tip_extra"
}

@test "single-task wave halts when sole task tip absent from parent set" {
  make_task_branch task-aa
  make_task_branch task-bb
  tip_aa=$(sha_of task-aa)
  # Capture aa, but stage commit merges bb instead.
  run run_script --capture --wave-id W1 --task-branch task-aa
  [ "$status" -eq 0 ]
  make_stage_commit task-bb

  run run_script --validate --wave-id W1
  [ "$status" -ne 0 ]
  echo "$output" | grep -q "stage-commit-parent-mismatch:"
  echo "$output" | grep -q "$tip_aa"
}

# ── --validate: sidecar-missing ────────────────────────────────────────────

@test "validate halts with sidecar-missing when no --capture has run" {
  run run_script --validate --wave-id W1
  [ "$status" -ne 0 ]
  echo "$output" | grep -q "sidecar-missing:"
  # Should NOT report schema-mismatch (these are distinct diagnostics).
  ! echo "$output" | grep -q "sidecar-schema-mismatch:"
}

@test "validate with sidecar-missing does not run git log against HEAD" {
  # If the script were to run `git log --format='%P' -n 1 HEAD` before
  # checking sidecar existence, an empty repo with no commits would emit
  # a different diagnostic. Verify we exit cleanly with sidecar-missing
  # even when HEAD is unusual: detached at root, no parents.
  run run_script --validate --wave-id NONEXISTENT
  [ "$status" -ne 0 ]
  echo "$output" | grep -q "sidecar-missing:"
  # No mention of "parent" or "git log" diagnostics from the validate path.
  ! echo "$output" | grep -q "stage-commit-parent-mismatch:"
}

# ── --validate: sidecar-schema-mismatch ────────────────────────────────────

@test "validate halts with sidecar-schema-mismatch when integration_base missing" {
  mkdir -p "$WAVE_DIR"
  printf 'task_tip_shas=abc1234\n' > "$WAVE_DIR/W1.sidecar"
  run run_script --validate --wave-id W1
  [ "$status" -ne 0 ]
  echo "$output" | grep -q "sidecar-schema-mismatch:"
  echo "$output" | grep -q "integration_base"
}

@test "validate halts with sidecar-schema-mismatch when task_tip_shas missing" {
  mkdir -p "$WAVE_DIR"
  printf 'integration_base=abc1234\n' > "$WAVE_DIR/W1.sidecar"
  run run_script --validate --wave-id W1
  [ "$status" -ne 0 ]
  echo "$output" | grep -q "sidecar-schema-mismatch:"
  echo "$output" | grep -q "task_tip_shas"
}

@test "validate halts with sidecar-schema-mismatch on extra unknown top-level field" {
  mkdir -p "$WAVE_DIR"
  printf 'integration_base=abc1234\ntask_tip_shas=def5678\nbogus_extra=oops\n' > "$WAVE_DIR/W1.sidecar"
  run run_script --validate --wave-id W1
  [ "$status" -ne 0 ]
  echo "$output" | grep -q "sidecar-schema-mismatch:"
  echo "$output" | grep -q "bogus_extra"
}

@test "validate halts with sidecar-schema-mismatch on malformed key/value structure" {
  mkdir -p "$WAVE_DIR"
  # Line with no '=' separator is structurally malformed.
  printf 'integration_base=abc1234\nthis-line-has-no-separator\ntask_tip_shas=def5678\n' > "$WAVE_DIR/W1.sidecar"
  run run_script --validate --wave-id W1
  [ "$status" -ne 0 ]
  echo "$output" | grep -q "sidecar-schema-mismatch:"
}

# ── --validate: sha-format-invalid ─────────────────────────────────────────

@test "validate halts with sha-format-invalid when integration_base is malformed" {
  mkdir -p "$WAVE_DIR"
  # 'XYZ123' is hex-invalid (uppercase + 'X'/'Y'/'Z' non-hex).
  printf 'integration_base=XYZ123\ntask_tip_shas=abc1234\n' > "$WAVE_DIR/W1.sidecar"
  run run_script --validate --wave-id W1
  [ "$status" -ne 0 ]
  echo "$output" | grep -q "sha-format-invalid:"
  # Must NOT report stage-commit-parent-mismatch (script halted before any
  # comparison or git invocation against the malformed value).
  ! echo "$output" | grep -q "stage-commit-parent-mismatch:"
}

@test "validate halts with sha-format-invalid when a task_tip_sha is malformed" {
  mkdir -p "$WAVE_DIR"
  # 6 chars is below the 7-char minimum for git object names.
  printf 'integration_base=abc1234\ntask_tip_shas=abcdef\n' > "$WAVE_DIR/W1.sidecar"
  run run_script --validate --wave-id W1
  [ "$status" -ne 0 ]
  echo "$output" | grep -q "sha-format-invalid:"
}

@test "validate halts with sha-format-invalid when SHA contains uppercase hex" {
  mkdir -p "$WAVE_DIR"
  printf 'integration_base=ABC1234\ntask_tip_shas=def5678\n' > "$WAVE_DIR/W1.sidecar"
  run run_script --validate --wave-id W1
  [ "$status" -ne 0 ]
  echo "$output" | grep -q "sha-format-invalid:"
}

# ── --capture: capture-git-error ───────────────────────────────────────────

@test "capture halts with capture-git-error when a task branch does not exist" {
  run run_script --capture --wave-id W1 --task-branch task-does-not-exist
  [ "$status" -ne 0 ]
  echo "$output" | grep -q "capture-git-error:"
  # Diagnostic names the failed git command.
  echo "$output" | grep -q "rev-parse"
  echo "$output" | grep -q "task-does-not-exist"
  # No sidecar should have been written.
  [ ! -f "$WAVE_DIR/W1.sidecar" ]
}

# ── --capture: capture-sidecar-write-error ─────────────────────────────────

@test "capture halts with capture-sidecar-write-error when wave-state dir is not writable" {
  make_task_branch task-aa
  # Pre-create wave-state as a read-only directory so mkdir -p succeeds but
  # writes inside fail.
  mkdir -p "$WAVE_DIR"
  chmod a-w "$WAVE_DIR"

  run run_script --capture --wave-id W1 --task-branch task-aa
  status_saved=$status
  # Restore writability so teardown can clean up.
  chmod u+w "$WAVE_DIR"

  [ "$status_saved" -ne 0 ]
  echo "$output" | grep -q "capture-sidecar-write-error:"
  [ ! -f "$WAVE_DIR/W1.sidecar" ]
}
