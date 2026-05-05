#!/usr/bin/env bats

setup() {
  ROUND_DIR=$(mktemp -d)
  TAG=quality-codex
}

teardown() {
  rm -rf "$ROUND_DIR"
}

@test "splitter exists and is executable" {
  [ -x scripts/codex-finding-splitter.sh ]
}

@test "boundary-delimited input writes per-finding files with role-distinct tag" {
  scripts/codex-finding-splitter.sh \
    tests/fixtures/issue-109/codex-stdout/boundary-delimited.txt \
    "$ROUND_DIR" \
    "$TAG"
  [ -f "$ROUND_DIR/${TAG}.finding-F01.md" ]
  [ -f "$ROUND_DIR/${TAG}.finding-F02.md" ]
  grep -qF 'finding_id: R3-F01' "$ROUND_DIR/${TAG}.finding-F01.md"
  grep -qF 'finding_id: R3-F02' "$ROUND_DIR/${TAG}.finding-F02.md"
  # Preamble before the first boundary must be discarded.
  ! grep -qF 'must be discarded' "$ROUND_DIR/${TAG}.finding-F01.md"
}

@test "NO_FINDINGS sentinel writes a clean marker (and only a clean marker)" {
  scripts/codex-finding-splitter.sh \
    tests/fixtures/issue-109/codex-stdout/no-findings.txt \
    "$ROUND_DIR" \
    "$TAG"
  [ -f "$ROUND_DIR/${TAG}.clean.md" ]
  ! ls "$ROUND_DIR"/${TAG}.finding-*.md 2>/dev/null
}

@test "NO_FINDINGS without trailing newline (11-byte form) also writes a clean marker" {
  scripts/codex-finding-splitter.sh \
    tests/fixtures/issue-109/codex-stdout/no-findings-no-newline.txt \
    "$ROUND_DIR" \
    "$TAG"
  [ -f "$ROUND_DIR/${TAG}.clean.md" ]
  ! ls "$ROUND_DIR"/${TAG}.finding-*.md 2>/dev/null
}

@test "malformed input writes nothing and exits non-zero with stderr diagnostic" {
  run --separate-stderr scripts/codex-finding-splitter.sh \
    tests/fixtures/issue-109/codex-stdout/malformed.txt \
    "$ROUND_DIR" \
    "$TAG"
  [ "$status" -ne 0 ]
  echo "$stderr" | grep -qiE 'malformed|FINDING-BOUNDARY|NO_FINDINGS'
  ! ls "$ROUND_DIR"/${TAG}.finding-*.md 2>/dev/null
  ! ls "$ROUND_DIR"/${TAG}.clean.md 2>/dev/null
}

@test "empty input writes nothing and exits non-zero with stderr diagnostic" {
  run --separate-stderr scripts/codex-finding-splitter.sh \
    tests/fixtures/issue-109/codex-stdout/empty.txt \
    "$ROUND_DIR" \
    "$TAG"
  [ "$status" -ne 0 ]
  echo "$stderr" | grep -qiE 'malformed|empty'
  ! ls "$ROUND_DIR"/${TAG}.finding-*.md 2>/dev/null
}

@test "splitter is idempotent on the success path" {
  scripts/codex-finding-splitter.sh \
    tests/fixtures/issue-109/codex-stdout/boundary-delimited.txt \
    "$ROUND_DIR" \
    "$TAG"
  local first_sha
  first_sha=$(shasum "$ROUND_DIR/${TAG}.finding-F01.md" "$ROUND_DIR/${TAG}.finding-F02.md")
  scripts/codex-finding-splitter.sh \
    tests/fixtures/issue-109/codex-stdout/boundary-delimited.txt \
    "$ROUND_DIR" \
    "$TAG"
  local second_sha
  second_sha=$(shasum "$ROUND_DIR/${TAG}.finding-F01.md" "$ROUND_DIR/${TAG}.finding-F02.md")
  [ "$first_sha" = "$second_sha" ]
}
