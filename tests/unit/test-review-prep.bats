#!/usr/bin/env bats
# ============================================================================
# Unit tests for scripts/review-prep.sh — task-03 (CD-2, G3, G7).
#
# Pins behaviors enumerated in task-03.md "Test expectations":
#   1.  --step goals produces only round-NN.diff at the documented path.
#   2.  --step design produces both round-NN.diff and round-NN.absorption-map.tsv.
#   3.  --step plan produces both round-NN.diff and round-NN.absorption-map.tsv.
#   4.  round-NN.diff content shape: non-empty unified diff (`diff --git`).
#   5.  round-NN.absorption-map.tsv content shape: TSV, absorbing-id (or
#       sentinel "no-task") in column 2 — same contract as
#       scripts/design-absorption-markers.sh emits.
#   6.  Round >= 2 narrowing reads reviews/<step>/round-<NN-1>-commit.txt
#       (NOT HEAD~1) and the produced round-NN.diff matches
#       `git diff <prev-anchor-SHA> -- <artifact>` (G7).
#   7.  Round 01 falls back to <base-branch> and emits no `anchor-file-missing:`
#       diagnostic for the absent round-00 anchor.
#   8.  Malformed SHA in round-<NN-1>-commit.txt halts with `sha-format-invalid:`
#       and no git command runs against the malformed value (no diff file
#       appears on disk).
#   9.  Corrupt artifact-dir halts with `review-prep-corrupt-artifact-dir:`.
#  10.  Silent-on-no-input: artifact-dir not in a git working tree → exit 0,
#       no files written.
#  11.  Silent-on-no-input: empty diff for a step → exit 0, no files written.
#  12.  Silent-on-unknown-step: --step bogus → exit 0, no files written,
#       empty stderr.
#  13.  Round >= 2 missing anchor file → `anchor-file-missing:` diagnostic and
#       non-zero exit (distinct from the round-01 fallback path).
#  14.  Mid-write failure → `review-prep-write-failed:` diagnostic and no
#       partial file appears at the final round-NN.diff path.
# ============================================================================

bats_require_minimum_version 1.5.0

setup_file() {
  REPO_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../.." && pwd -P)"
  export REPO_ROOT
  SCRIPT="$REPO_ROOT/scripts/review-prep.sh"
  export SCRIPT
}

setup() {
  TEST_ROOT="$(mktemp -d)"
  export TEST_ROOT
  ART_DIR="$TEST_ROOT/artifact"
  export ART_DIR
  mkdir -p "$ART_DIR"

  # Initialise a git repo with a base commit on "main" and a second commit
  # that modifies goals.md / design.md / plan.md so there is a real diff to
  # narrow against.
  git init -q -b main "$ART_DIR"
  (
    cd "$ART_DIR"
    git config user.email "t@example.test"
    git config user.name "Tester"

    cat > goals.md <<'EOF'
# Goals v0.0
Initial body.
EOF
    cat > design.md <<'EOF'
# Design — baseline
Initial design body.
EOF
    cat > plan.md <<'EOF'
# Plan — baseline
Initial plan body.
EOF
    git add goals.md design.md plan.md
    git commit -q -m "base"
    BASE_SHA=$(git rev-parse HEAD)
    echo "$BASE_SHA" > "$TEST_ROOT/base-sha"

    # Move round-1 work to a separate branch so `main` continues to point at
    # the base commit; otherwise `git diff main` resolves to empty after the
    # second commit and the round-01 base-branch fallback has nothing to emit.
    git checkout -q -b task

    # Modify each artifact to create diffs.
    printf '\nNew goals line.\n' >> goals.md

    # Replace design.md with the canonical four-marker fixture so the
    # absorption-map TSV has a deterministic, non-empty content shape.
    cp "$REPO_ROOT/tests/fixtures/design-absorption-markers/all-four.md" design.md

    printf '\nNew plan line.\n' >> plan.md
    git add goals.md design.md plan.md
    git commit -q -m "round-1 work"
    HEAD_SHA=$(git rev-parse HEAD)
    echo "$HEAD_SHA" > "$TEST_ROOT/head-sha"
  )
}

teardown() {
  # Restore perms so rm -rf can clean up after the mid-write-failure test.
  if [ -d "$TEST_ROOT" ]; then
    chmod -R u+rwx "$TEST_ROOT" 2>/dev/null || true
    rm -rf "$TEST_ROOT"
  fi
}

# ── Script existence ────────────────────────────────────────────────────────

@test "script file exists and is executable" {
  # Test expectation: target file scripts/review-prep.sh (Create).
  [ -f "$SCRIPT" ]
  [ -x "$SCRIPT" ]
}

# ── Per-step deliverable presence (bullets 1, 2, 3, 4, 5) ──────────────────

@test "--step goals round 01 produces only round-01.diff (no absorption-map)" {
  # Test expectation: --step goals fixture asserts only round-NN.diff is
  # produced (no round-NN.absorption-map.tsv, no error).
  run "$SCRIPT" --step goals --round 01 --artifact-dir "$ART_DIR" --base-ref main
  [ "$status" -eq 0 ]
  [ -f "$ART_DIR/reviews/goals/round-01.diff" ]
  [ ! -e "$ART_DIR/reviews/goals/round-01.absorption-map.tsv" ]
}

@test "--step design round 01 produces both round-01.diff and round-01.absorption-map.tsv" {
  # Test expectation: --step design fixture asserts both round-NN.diff and
  # round-NN.absorption-map.tsv are produced with the expected content shapes.
  run "$SCRIPT" --step design --round 01 --artifact-dir "$ART_DIR" --base-ref main
  [ "$status" -eq 0 ]
  [ -f "$ART_DIR/reviews/design/round-01.diff" ]
  [ -f "$ART_DIR/reviews/design/round-01.absorption-map.tsv" ]
}

@test "--step plan round 01 produces both round-01.diff and round-01.absorption-map.tsv" {
  # Test expectation: --step plan fixture asserts absorption-map file is
  # written for the plan-spec reviewer to consume (CD-2 / G3 change 3).
  run "$SCRIPT" --step plan --round 01 --artifact-dir "$ART_DIR" --base-ref main
  [ "$status" -eq 0 ]
  [ -f "$ART_DIR/reviews/plan/round-01.diff" ]
  [ -f "$ART_DIR/reviews/plan/round-01.absorption-map.tsv" ]
}

# ── Content shape (bullets 2, 3, 4) ────────────────────────────────────────

@test "round-NN.diff contains a unified-diff payload (diff --git line present)" {
  # Test expectation: round-NN.diff contains a non-empty unified-diff payload
  # (`diff --git ` line present, valid hunk markers).
  run "$SCRIPT" --step goals --round 01 --artifact-dir "$ART_DIR" --base-ref main
  [ "$status" -eq 0 ]
  grep -q '^diff --git ' "$ART_DIR/reviews/goals/round-01.diff"
  grep -q '^@@' "$ART_DIR/reviews/goals/round-01.diff"
}

@test "design round-NN.absorption-map.tsv matches design-absorption-markers.sh output shape" {
  # Test expectation: round-NN.absorption-map.tsv (Design/Plan only) is
  # tab-separated, one line per absorbed ID, with the absorbing-ID (or the
  # sentinel `no-task`) in column 2 — matching the contract
  # scripts/design-absorption-markers.sh emits.
  run "$SCRIPT" --step design --round 01 --artifact-dir "$ART_DIR" --base-ref main
  [ "$status" -eq 0 ]
  MAP="$ART_DIR/reviews/design/round-01.absorption-map.tsv"
  expected="$(bash "$REPO_ROOT/scripts/design-absorption-markers.sh" "$ART_DIR/design.md")"
  actual="$(cat "$MAP")"
  [ "$actual" = "$expected" ]
  # Sanity: column 2 of every line is either CD-N or the literal "no-task".
  while IFS=$'\t' read -r col1 col2; do
    [ -n "$col1" ]
    case "$col2" in
      CD-*|no-task) ;;
      *) echo "unexpected col2 value: '$col2'"; return 1 ;;
    esac
  done < "$MAP"
}

@test "plan round-NN.absorption-map.tsv has same content as design absorption map" {
  # Test expectation: --step plan fixture asserts the absorption-map content
  # matches the expected absorbed-goal redirect map for the fixture design.md
  # (CD-2 Acceptance bullet 1, parenthetical for G3 change 3).
  run "$SCRIPT" --step plan --round 01 --artifact-dir "$ART_DIR" --base-ref main
  [ "$status" -eq 0 ]
  expected="$(bash "$REPO_ROOT/scripts/design-absorption-markers.sh" "$ART_DIR/design.md")"
  actual="$(cat "$ART_DIR/reviews/plan/round-01.absorption-map.tsv")"
  [ "$actual" = "$expected" ]
}

# ── Diff narrowing — round >= 2 uses anchor file (bullet 6, G7) ─────────────

@test "round >= 2 narrowing reads reviews/<step>/round-<NN-1>-commit.txt (not HEAD~1)" {
  # Test expectation: Diff narrowing in round >= 2 reads
  # reviews/<step>/round-<NN-1>-commit.txt; the resulting round-NN.diff
  # content matches `git diff <prev-anchor-SHA> -- <artifact>`
  # (traces G7 Acceptance bullet 3, sub-bullet 1).
  PREV_SHA="$(cat "$TEST_ROOT/base-sha")"
  mkdir -p "$ART_DIR/reviews/goals"
  echo "$PREV_SHA" > "$ART_DIR/reviews/goals/round-01-commit.txt"

  # Add an extra commit on top so HEAD~1 != PREV_SHA — proves narrowing is
  # NOT using HEAD~1.
  (
    cd "$ART_DIR"
    printf 'decoy line\n' >> plan.md
    git add plan.md
    git commit -q -m "decoy between round-01 anchor and HEAD"
  )

  run "$SCRIPT" --step goals --round 02 --artifact-dir "$ART_DIR" --base-ref main
  [ "$status" -eq 0 ]
  expected="$(git -C "$ART_DIR" diff "$PREV_SHA" -- goals.md)"
  actual="$(cat "$ART_DIR/reviews/goals/round-02.diff")"
  [ "$actual" = "$expected" ]
}

# ── Round 01 fallback to base-branch (bullet 7) ─────────────────────────────

@test "round 01 falls back to base-branch (no anchor-file-missing diagnostic)" {
  # Test expectation: Round 1 diff narrowing falls back to <base-branch>
  # rather than reading a non-existent reviews/<step>/round-00-commit.txt;
  # the resulting round-01.diff content is `git diff <base-branch> -- <artifact>`
  # and no `anchor-file-missing:` diagnostic is surfaced.
  run "$SCRIPT" --step goals --round 01 --artifact-dir "$ART_DIR" --base-ref main
  [ "$status" -eq 0 ]
  [[ "$output" != *"anchor-file-missing:"* ]]
  expected="$(git -C "$ART_DIR" diff main -- goals.md)"
  actual="$(cat "$ART_DIR/reviews/goals/round-01.diff")"
  [ "$actual" = "$expected" ]
}

# ── SHA shape validation (bullet 8) ─────────────────────────────────────────

@test "malformed SHA (uppercase) halts with sha-format-invalid: and no git run" {
  # Test expectation: A SHA read from reviews/<step>/round-<NN-1>-commit.txt
  # that fails the well-formed git object-name shape halts non-zero with the
  # `sha-format-invalid:` named diagnostic — no `git` command runs against
  # the malformed value.
  mkdir -p "$ART_DIR/reviews/goals"
  # Uppercase hex — 40 chars but fails lowercase-hex 7..64 shape check.
  echo "DEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEF" > "$ART_DIR/reviews/goals/round-01-commit.txt"

  run "$SCRIPT" --step goals --round 02 --artifact-dir "$ART_DIR" --base-ref main
  [ "$status" -ne 0 ]
  # No diff file should exist on disk — git was never invoked against the
  # malformed SHA, and no partial-write artifact leaks.
  [ ! -e "$ART_DIR/reviews/goals/round-02.diff" ]
  [[ "$output" == *"sha-format-invalid:"* ]]
}

@test "malformed SHA (too short) halts with sha-format-invalid:" {
  mkdir -p "$ART_DIR/reviews/goals"
  echo "abc123" > "$ART_DIR/reviews/goals/round-01-commit.txt"

  run "$SCRIPT" --step goals --round 02 --artifact-dir "$ART_DIR" --base-ref main
  [ "$status" -ne 0 ]
  [ ! -e "$ART_DIR/reviews/goals/round-02.diff" ]
  [[ "$output" == *"sha-format-invalid:"* ]]
}

@test "malformed SHA (non-hex characters) halts with sha-format-invalid:" {
  mkdir -p "$ART_DIR/reviews/goals"
  echo "zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz" > "$ART_DIR/reviews/goals/round-01-commit.txt"

  run "$SCRIPT" --step goals --round 02 --artifact-dir "$ART_DIR" --base-ref main
  [ "$status" -ne 0 ]
  [ ! -e "$ART_DIR/reviews/goals/round-02.diff" ]
  [[ "$output" == *"sha-format-invalid:"* ]]
}

# ── Corrupt artifact-dir (bullet 9) ─────────────────────────────────────────

@test "corrupt artifact-dir (path is a file, not a directory) halts with review-prep-corrupt-artifact-dir:" {
  # Test expectation: A corrupt artifact-dir surfaces the
  # `review-prep-corrupt-artifact-dir:` named diagnostic and non-zero exit.
  CORRUPT="$TEST_ROOT/not-a-dir"
  echo "i am a file, not a directory" > "$CORRUPT"

  run "$SCRIPT" --step goals --round 01 --artifact-dir "$CORRUPT" --base-ref main
  [ "$status" -ne 0 ]
  [[ "$output" == *"review-prep-corrupt-artifact-dir:"* ]]
}

# ── Silent-on-no-input (bullets 10, 11) ─────────────────────────────────────

@test "non-git artifact-dir → exit 0 with no files written (silent-on-no-input)" {
  # Test expectation: artifact-dir not in a git working tree → script emits
  # no files for that step and exits 0.
  NONGIT="$TEST_ROOT/not-a-repo"
  mkdir -p "$NONGIT"
  echo "# goals" > "$NONGIT/goals.md"

  run "$SCRIPT" --step goals --round 01 --artifact-dir "$NONGIT" --base-ref main
  [ "$status" -eq 0 ]
  [ ! -e "$NONGIT/reviews/goals/round-01.diff" ]
  [ ! -e "$NONGIT/reviews/goals/round-01.absorption-map.tsv" ]
}

@test "step with empty diff → exit 0 with no files written (silent-on-no-input)" {
  # Test expectation: git diff returned no output for a step that has no
  # diff today → script emits no files for that step and exits 0.
  # Phasing artifact has no diff between base and HEAD (file does not exist).
  # Use an empty file added at base so HEAD diff is empty.
  (
    cd "$ART_DIR"
    : > phasing.md
    git add phasing.md
    git commit -q -m "add empty phasing.md"
  )
  run "$SCRIPT" --step phasing --round 01 --artifact-dir "$ART_DIR" --base-ref main
  [ "$status" -eq 0 ]
  [ ! -e "$ART_DIR/reviews/phasing/round-01.diff" ]
}

# ── Unknown step is silent (bullet 12) ──────────────────────────────────────

@test "unknown --step value → exit 0, no files written, empty stderr" {
  # Test expectation: An unknown --step value triggers the silent-on-no-input
  # shape: emits no files and exits 0 with no stderr output (Author Note
  # defer-to-upstream).
  STDERR_FILE="$TEST_ROOT/stderr.out"
  "$SCRIPT" --step bogus --round 01 --artifact-dir "$ART_DIR" --base-ref main \
    > "$TEST_ROOT/stdout.out" 2> "$STDERR_FILE"
  status=$?
  [ "$status" -eq 0 ]
  [ ! -d "$ART_DIR/reviews/bogus" ] || {
    # If reviews/bogus/ exists it must contain zero files.
    [ -z "$(find "$ART_DIR/reviews/bogus" -type f)" ]
  }
  # Stderr must be empty.
  [ ! -s "$STDERR_FILE" ]
}

# ── Round >= 2 missing anchor → anchor-file-missing: (bullet 13) ────────────

@test "round >= 2 with absent anchor file halts with anchor-file-missing:" {
  # Test expectation: At round >= 2, an absent round-anchor file at
  # reviews/<step>/round-<NN-1>-commit.txt halts non-zero with the
  # `anchor-file-missing:` named diagnostic — distinct from the round-1
  # fallback case which falls back to <base-branch>.
  # Note: do NOT pre-create reviews/goals/round-01-commit.txt.
  run "$SCRIPT" --step goals --round 02 --artifact-dir "$ART_DIR" --base-ref main
  [ "$status" -ne 0 ]
  [ ! -e "$ART_DIR/reviews/goals/round-02.diff" ]
  [[ "$output" == *"anchor-file-missing:"* ]]
}

# ── Mid-write atomicity (bullet 14) ─────────────────────────────────────────

@test "mid-write failure halts with review-prep-write-failed: and leaves no partial file" {
  # Test expectation: A mid-write failure (fixture: unwritable target
  # directory) halts with the `review-prep-write-failed:` named diagnostic
  # before any partial-content file appears at the final
  # <artifact-dir>/reviews/<step>/round-NN.diff path.
  if [ "$(id -u)" = "0" ]; then
    skip "cannot exercise unwritable-dir failure as root"
  fi
  mkdir -p "$ART_DIR/reviews/goals"
  chmod 555 "$ART_DIR/reviews/goals"

  run "$SCRIPT" --step goals --round 01 --artifact-dir "$ART_DIR" --base-ref main
  rc="$status"
  # Restore perms before assertions so failure paths can still inspect/cleanup.
  chmod 755 "$ART_DIR/reviews/goals"

  [ "$rc" -ne 0 ]
  # No partial-content file at the final path (atomic temp+rename contract).
  [ ! -e "$ART_DIR/reviews/goals/round-01.diff" ]
  [[ "$output" == *"review-prep-write-failed:"* ]]
}

# ── #341 regression: research step narrows to research/summary.md ──────────

@test "[#341] --step research narrows diff to research/summary.md (not research.md)" {
  # Test expectation: artifact_for_step('research') returns research/summary.md
  # (the canonical artifact per upstream-paths.sh + skills/research/SKILL.md),
  # NOT research.md. Pre-fix, --step research --round 01 emitted no diff because
  # git diff filtered on the nonexistent research.md; post-fix it correctly
  # narrows to research/summary.md and emits the expected unified diff.
  (
    cd "$ART_DIR"
    mkdir -p research
    cat > research/summary.md <<'EOF'
# Research Summary

Initial body.
EOF
    git add research/summary.md
    git commit -q -m "add research/summary.md baseline"

    printf '\nNew research line.\n' >> research/summary.md
    git add research/summary.md
    git commit -q -m "research round-1 work"
  )
  run "$SCRIPT" --step research --round 01 --artifact-dir "$ART_DIR" --base-ref main
  [ "$status" -eq 0 ]
  [ -f "$ART_DIR/reviews/research/round-01.diff" ]
  # The emitted diff must reference the canonical path; the pre-fix bogus
  # 'research.md' path must NOT appear.
  grep -q "research/summary.md" "$ART_DIR/reviews/research/round-01.diff"
  ! grep -qE "^diff --git a/research\.md " "$ART_DIR/reviews/research/round-01.diff"
}
