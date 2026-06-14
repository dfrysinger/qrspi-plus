#!/usr/bin/env bats
# ============================================================================
# Unit tests for the round-NN narrow-ref anchor-file lookup contract (G7).
#
# Task spec: docs/qrspi/2026-06-04-v073-release/tasks/task-27.md
#
# Covers the four behavioral fixtures enumerated in task-27.md's
# `## Test Expectations` block:
#
#   Fixture 1: anchor-file-based diff vs HEAD~1 in the presence of an
#              unrelated commit between rounds — anchor-file lookup returns
#              round N's per-round commit content; HEAD~1-based diff returns
#              the wrong content (G7 Acceptance bullet 3 sub-bullet 1,
#              regression guard against the v0.7.2 shifted-shape bug).
#
#   Fixture 2: missing anchor file — orchestrator's call halts non-zero
#              with the `anchor-file-missing:` named diagnostic; no silent
#              fallback to HEAD~1 (G7 Acceptance bullet 3 sub-bullet 2).
#
#   Fixture 3: empty narrowed diff — divergence sanity check halts non-zero
#              with the `narrow-round-empty-diff:` named diagnostic
#              (G7 Acceptance bullet 3 sub-bullet 3).
#
#   Fixture 4: malformed anchor-file content (uppercase hex, non-hex
#              characters, or content outside the well-formed git
#              object-name shape) — orchestrator's call halts non-zero with
#              the `sha-format-invalid:` named diagnostic BEFORE any
#              `git diff` runs against the malformed value.
#
# Bash 3.2 compatible (macOS system /bin/bash).
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

  git init -q -b main "$ART_DIR"
  (
    cd "$ART_DIR"
    git config user.email "narrow-anchor@example.test"
    git config user.name "Narrow Anchor Tester"

    cat > goals.md <<'EOF'
# Goals — baseline
Initial goals body.
EOF
    git add goals.md
    git commit -q -m "base"
    git rev-parse HEAD > "$TEST_ROOT/base-sha"

    git checkout -q -b task

    # round-1 work: a real edit so `git diff <round-1-anchor> -- goals.md`
    # has hunks against the round-2 work landed below.
    printf '\nRound 1 edit line.\n' >> goals.md
    git add goals.md
    git commit -q -m "round-1 work"
    git rev-parse HEAD > "$TEST_ROOT/round1-sha"
  )
}

teardown() {
  if [ -d "$TEST_ROOT" ]; then
    chmod -R u+rwx "$TEST_ROOT" 2>/dev/null || true
    rm -rf "$TEST_ROOT"
  fi
}

# ── Fixture 1: anchor-file lookup vs HEAD~1 with unrelated commit between ──

@test "fixture 1: anchor-file lookup returns round N content when an unrelated commit lands between rounds" {
  # Test expectation: anchor-file-based diff "returns the correct content
  # (round N's per-round commit diff)" while HEAD~1-based diff "returns
  # wrong content" — regression guard against the v0.7.2 shifted-shape bug
  # (G7 Acceptance bullet 3 sub-bullet 1).
  ROUND1_SHA="$(cat "$TEST_ROOT/round1-sha")"

  # Drop the round-1 anchor file at the canonical path.
  mkdir -p "$ART_DIR/reviews/goals"
  echo "$ROUND1_SHA" > "$ART_DIR/reviews/goals/round-01-commit.txt"

  # Decoy commit between round-1 and round-2 that ALSO touches goals.md.
  # This is what makes HEAD~1 shift away from the round-1 anchor and produce
  # wrong content: HEAD~1 = decoy (which already contains the decoy goals.md
  # edit), so `git diff HEAD~1 -- goals.md` omits the decoy edit and shows
  # ONLY the round-2 edit; the anchor-file diff against round-1 correctly
  # shows BOTH edits as the round-N+1 narrow against the prior per-round
  # commit anchor.
  (
    cd "$ART_DIR"
    printf '\nDecoy intervening edit line.\n' >> goals.md
    git add goals.md
    git commit -q -m "decoy commit between round-1 and round-2 touching goals.md"

    # Round-2 work on goals.md.
    printf '\nRound 2 edit line.\n' >> goals.md
    git add goals.md
    git commit -q -m "round-2 work"
  )

  # Compute the two candidate diffs directly so the comparison is independent
  # of any review-prep implementation choices that may change.
  anchor_diff="$(git -C "$ART_DIR" diff "$ROUND1_SHA" -- goals.md)"
  head1_diff="$(git -C "$ART_DIR" diff HEAD~1 -- goals.md)"

  # The anchor-file diff MUST capture both the decoy edit and the round-2
  # edit as ADDED lines (it is the canonical "diff since round N's per-round
  # commit"; both lines were added on top of the round-1 anchor).
  printf '%s\n' "$anchor_diff" | grep -q '^+Decoy intervening edit line\.' \
    || { echo "anchor-file diff missing +decoy edit"; printf '%s\n' "$anchor_diff"; return 1; }
  printf '%s\n' "$anchor_diff" | grep -q '^+Round 2 edit line\.' \
    || { echo "anchor-file diff missing +round-2 edit"; printf '%s\n' "$anchor_diff"; return 1; }

  # The HEAD~1 diff in this layout omits the decoy edit as an addition —
  # HEAD~1 = the decoy commit already contains the decoy line, so it appears
  # only as context. Pin the divergence so a future regression that
  # re-instates HEAD~1 shorthand at the inlining sites surfaces here.
  if printf '%s\n' "$head1_diff" | grep -q '^+Decoy intervening edit line\.'; then
    echo "HEAD~1 diff unexpectedly captured the decoy edit as an addition — fixture cannot prove the bug"
    return 1
  fi

  # And review-prep.sh — the orchestrator's call — MUST produce the
  # anchor-file content, not the HEAD~1 content.
  run "$SCRIPT" --step goals --round 02 --artifact-dir "$ART_DIR" --base-ref main
  [ "$status" -eq 0 ]
  produced="$(cat "$ART_DIR/reviews/goals/round-02.diff")"
  [ "$produced" = "$anchor_diff" ]
  [ "$produced" != "$head1_diff" ]
}

# ── Fixture 2: missing anchor file → anchor-file-missing: diagnostic ────────

@test "fixture 2: missing anchor file halts non-zero with anchor-file-missing diagnostic (no silent fallback)" {
  # Test expectation: missing anchor file — orchestrator's call halts with
  # the `anchor-file-missing:` named diagnostic and exits non-zero "with a
  # clear error (no silent fallback)" (G7 Acceptance bullet 3 sub-bullet 2).

  # Land a round-2 commit so there's plausible work to diff — but DO NOT
  # write the round-01-commit.txt anchor file.
  (
    cd "$ART_DIR"
    printf '\nRound 2 edit line.\n' >> goals.md
    git add goals.md
    git commit -q -m "round-2 work without anchor"
  )

  [ ! -e "$ART_DIR/reviews/goals/round-01-commit.txt" ]

  run "$SCRIPT" --step goals --round 02 --artifact-dir "$ART_DIR" --base-ref main
  [ "$status" -ne 0 ]
  case "$output" in
    *"anchor-file-missing:"*) ;;
    *) echo "expected anchor-file-missing: diagnostic, got: $output"; return 1 ;;
  esac
  # No silent fallback — no round-02.diff was produced.
  [ ! -e "$ART_DIR/reviews/goals/round-02.diff" ]
}

# ── Fixture 3: empty narrowed diff → narrow-round-empty-diff: diagnostic ────

@test "fixture 3: empty narrowed diff halts non-zero with narrow-round-empty-diff diagnostic" {
  # Test expectation: empty narrowed diff — "the divergence sanity check
  # fires with the narrow-round-empty-diff diagnostic"
  # (G7 Acceptance bullet 3 sub-bullet 3).
  #
  # Construct an empty-narrow-round condition: the round-2 anchor points at
  # HEAD itself, so `git diff <anchor> -- goals.md` has no hunks. A narrow
  # round whose diff is structurally empty is the divergence sanity-check's
  # named failure case — silently exiting 0 here is the bug this fixture
  # guards against.
  HEAD_SHA="$(git -C "$ART_DIR" rev-parse HEAD)"

  mkdir -p "$ART_DIR/reviews/goals"
  echo "$HEAD_SHA" > "$ART_DIR/reviews/goals/round-01-commit.txt"

  # Sanity: confirm the narrow diff really is empty in the fixture state
  # (no hunks against HEAD).
  empty_diff="$(git -C "$ART_DIR" diff "$HEAD_SHA" -- goals.md)"
  if printf '%s' "$empty_diff" | grep -q '^@@'; then
    echo "fixture setup error: anchor diff is not empty"
    return 1
  fi

  run "$SCRIPT" --step goals --round 02 --artifact-dir "$ART_DIR" --base-ref main
  [ "$status" -ne 0 ]
  case "$output" in
    *"narrow-round-empty-diff:"*) ;;
    *) echo "expected narrow-round-empty-diff: diagnostic, got: $output"; return 1 ;;
  esac
}

# ── Fixture 4: malformed anchor content → sha-format-invalid: diagnostic ────

@test "fixture 4: malformed anchor content halts non-zero with sha-format-invalid before any git diff runs" {
  # Test expectation: malformed anchor file (e.g., uppercase hex, non-hex
  # characters, or content outside the well-formed git object-name shape) —
  # the orchestrator's call halts with the `sha-format-invalid:` named
  # diagnostic and exits non-zero before any `git diff` runs against the
  # malformed value.

  mkdir -p "$ART_DIR/reviews/goals"
  # Uppercase hex is outside the lowercase-hex 7..64-char object-name shape.
  echo "ABCDEF1234567890" > "$ART_DIR/reviews/goals/round-01-commit.txt"

  run "$SCRIPT" --step goals --round 02 --artifact-dir "$ART_DIR" --base-ref main
  [ "$status" -ne 0 ]
  case "$output" in
    *"sha-format-invalid:"*) ;;
    *) echo "expected sha-format-invalid: diagnostic, got: $output"; return 1 ;;
  esac
  # No `git diff` was run against the malformed value — no diff file written.
  [ ! -e "$ART_DIR/reviews/goals/round-02.diff" ]
}
