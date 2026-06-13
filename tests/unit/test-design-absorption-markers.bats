#!/usr/bin/env bats
#
# Tests for scripts/design-absorption-markers.sh.
#
# Behavior under test: the script reads design.md from an explicit path
# argument and prints a tab-separated absorbed-goal redirect map to stdout —
# one line per marker hit, with columns <absorbed-id> <TAB> <absorbing-id|"no-task">.
# Exactly the four canonical marker forms are recognised; non-enumerated
# absorption-shaped markers are ignored (the structural lint at the design.md
# authoring boundary owns marker-set discipline). A marker-free design.md
# exits 0 with empty stdout. A missing or unreadable design path exits
# non-zero with the named diagnostic 'design-path-unreadable:'.

setup_file() {
  REPO_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../.." && pwd -P)"
  export REPO_ROOT
  SCRIPT="$REPO_ROOT/scripts/design-absorption-markers.sh"
  export SCRIPT
  FIX_DIR="$REPO_ROOT/tests/fixtures/design-absorption-markers"
  export FIX_DIR
}

@test "script file exists and is executable" {
  [ -f "$SCRIPT" ]
  [ -x "$SCRIPT" ]
}

@test "all four marker forms together produce the expected map" {
  run "$SCRIPT" "$FIX_DIR/all-four.md"
  [ "$status" -eq 0 ]
  expected="$(cat "$FIX_DIR/all-four.expected.tsv")"
  [ "$output" = "$expected" ]
}

@test "marker-free design exits 0 with empty stdout" {
  run "$SCRIPT" "$FIX_DIR/marker-free.md"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "heading-suffix marker form is recognised" {
  run "$SCRIPT" "$FIX_DIR/heading-suffix.md"
  [ "$status" -eq 0 ]
  expected="$(cat "$FIX_DIR/heading-suffix.expected.tsv")"
  [ "$output" = "$expected" ]
}

@test "block-internal explicit-non-goal marker form is recognised" {
  run "$SCRIPT" "$FIX_DIR/block-internal.md"
  [ "$status" -eq 0 ]
  expected="$(cat "$FIX_DIR/block-internal.expected.tsv")"
  [ "$output" = "$expected" ]
}

@test "acceptance-criterion no-separate-task marker form is recognised" {
  run "$SCRIPT" "$FIX_DIR/acceptance-criterion.md"
  [ "$status" -eq 0 ]
  expected="$(cat "$FIX_DIR/acceptance-criterion.expected.tsv")"
  [ "$output" = "$expected" ]
}

@test "free-prose deferred-to marker form is recognised" {
  run "$SCRIPT" "$FIX_DIR/free-prose.md"
  [ "$status" -eq 0 ]
  expected="$(cat "$FIX_DIR/free-prose.expected.tsv")"
  [ "$output" = "$expected" ]
}

@test "non-enumerated absorption-shaped markers are NOT recognised" {
  run "$SCRIPT" "$FIX_DIR/non-enumerated.md"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "missing design path exits non-zero with named diagnostic" {
  run "$SCRIPT" "$REPO_ROOT/tests/fixtures/design-absorption-markers/does-not-exist.md"
  [ "$status" -ne 0 ]
  [[ "$output" == *"design-path-unreadable:"* ]]
}

@test "unreadable design path exits non-zero with named diagnostic" {
  tmp="$(mktemp "$REPO_ROOT/.bats-tmp-design.XXXXXX")"
  chmod 000 "$tmp"
  run "$SCRIPT" "$tmp"
  chmod 600 "$tmp"
  rm -f "$tmp"
  [ "$status" -ne 0 ]
  [[ "$output" == *"design-path-unreadable:"* ]]
}

@test "missing argument exits non-zero (usage)" {
  run "$SCRIPT"
  [ "$status" -ne 0 ]
}
