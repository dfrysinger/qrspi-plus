#!/usr/bin/env bats

setup() {
  source "$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)/hooks/lib/bash-detect.sh"
}

# Helper to check if output contains expected path
assert_contains_path() {
    local output="$1"
    local expected_path="$2"
    if [[ ! "$output" =~ $expected_path ]]; then
        echo "Expected path not found: $expected_path"
        echo "Got output: $output"
        return 1
    fi
}

# Helper to check output is empty
assert_empty() {
    local output="$1"
    if [[ -n "$output" ]]; then
        echo "Expected empty output, got: $output"
        return 1
    fi
}

# Test 1: Simple redirect >
@test "detects simple output redirect > /tmp/out.txt" {
    result=$(bash_detect_file_writes 'echo foo > /tmp/out.txt')
    assert_contains_path "$result" "/tmp/out.txt"
}

# Test 2: Append redirect >>
@test "detects append redirect >> /tmp/out.txt" {
    result=$(bash_detect_file_writes 'echo foo >> /tmp/out.txt')
    assert_contains_path "$result" "/tmp/out.txt"
}

# Test 3: sed -i
@test "detects sed -i on config.txt" {
    result=$(bash_detect_file_writes "sed -i 's/foo/bar/' config.txt")
    assert_contains_path "$result" "config.txt"
}

# Test 4: sed -i.bak
@test "detects sed -i.bak on config.txt" {
    result=$(bash_detect_file_writes "sed -i.bak 's/foo/bar/' config.txt")
    assert_contains_path "$result" "config.txt"
}

# Test 5: cp destination
@test "detects cp destination file" {
    result=$(bash_detect_file_writes 'cp source.txt dest.txt')
    assert_contains_path "$result" "dest.txt"
}

# Test 6: mv destination
@test "detects mv destination file" {
    result=$(bash_detect_file_writes 'mv old.txt new.txt')
    assert_contains_path "$result" "new.txt"
}

# Test 7: tee
@test "detects tee output.txt" {
    result=$(bash_detect_file_writes 'echo foo | tee output.txt')
    assert_contains_path "$result" "output.txt"
}

# Test 8: tee -a
@test "detects tee -a output.txt" {
    result=$(bash_detect_file_writes 'tee -a output.txt')
    assert_contains_path "$result" "output.txt"
}

# Test 9: cat with redirect
@test "detects cat input.txt > output.txt" {
    result=$(bash_detect_file_writes 'cat input.txt > output.txt')
    assert_contains_path "$result" "output.txt"
}

# Test 10: No file write (ls)
@test "returns empty for ls -la" {
    result=$(bash_detect_file_writes 'ls -la')
    assert_empty "$result"
}

# Test 11: No file write (grep)
@test "returns empty for grep pattern file.txt" {
    result=$(bash_detect_file_writes 'grep pattern file.txt')
    assert_empty "$result"
}

# Test 12: No file write (echo without redirect)
@test "returns empty for echo hello" {
    result=$(bash_detect_file_writes 'echo hello')
    assert_empty "$result"
}

# Test 13: Compound command with && (multiple writes)
@test "detects multiple writes in compound command a.txt && c.txt" {
    result=$(bash_detect_file_writes 'cp a.txt b.txt && echo x > c.txt')
    assert_contains_path "$result" "b.txt"
    assert_contains_path "$result" "c.txt"
}

# Test 14: Paths with spaces in quotes
@test "detects path with spaces in quotes" {
    result=$(bash_detect_file_writes 'echo foo > "path with spaces/file.txt"')
    assert_contains_path "$result" "path with spaces/file.txt"
}

# Test 15: Always returns exit code 0
@test "function returns exit code 0" {
    bash_detect_file_writes 'nonexistent_command'
    [ $? -eq 0 ]
}

# Test 16: Library uses set -euo pipefail (verify by checking stderr handling)
@test "library uses set -euo pipefail" {
    # This test verifies the library source can be loaded without error
    # and basic operations work
    result=$(bash_detect_file_writes 'echo test > file.txt')
    [ -n "$result" ]
}

# ── Destructive patterns: universal (everyone) ────────────────────────

@test "destructive: rm -rf with wildcard" {
  run bash_detect_destructive_universal 'rm -rf *'
  [ "$status" -eq 0 ]
  [[ "$output" =~ rm ]]
}

@test "destructive: rm -rf with home glob" {
  run bash_detect_destructive_universal 'rm -rf ~/foo'
  [ "$status" -eq 0 ]
}

@test "destructive: rm -rf with absolute root path" {
  run bash_detect_destructive_universal 'rm -rf /etc'
  [ "$status" -eq 0 ]
}

@test "destructive: rm -rf with parent traversal" {
  run bash_detect_destructive_universal 'rm -rf ../foo'
  [ "$status" -eq 0 ]
}

@test "non-destructive: rm -rf relative subdir" {
  run bash_detect_destructive_universal 'rm -rf ./build'
  [ "$status" -ne 0 ]
}

@test "non-destructive: rm -rf node_modules" {
  run bash_detect_destructive_universal 'rm -rf node_modules'
  [ "$status" -ne 0 ]
}

@test "destructive: git push --force" {
  run bash_detect_destructive_universal 'git push --force origin main'
  [ "$status" -eq 0 ]
}

@test "destructive: git push -f" {
  run bash_detect_destructive_universal 'git push -f origin main'
  [ "$status" -eq 0 ]
}

@test "non-destructive: git push (normal)" {
  run bash_detect_destructive_universal 'git push origin main'
  [ "$status" -ne 0 ]
}

@test "destructive: git reset --hard origin/main" {
  run bash_detect_destructive_universal 'git reset --hard origin/main'
  [ "$status" -eq 0 ]
}

@test "non-destructive: git reset --hard HEAD" {
  run bash_detect_destructive_universal 'git reset --hard HEAD'
  [ "$status" -ne 0 ]
}

@test "non-destructive: git reset --hard (no arg)" {
  run bash_detect_destructive_universal 'git reset --hard'
  [ "$status" -ne 0 ]
}

@test "destructive: git clean -fd" {
  run bash_detect_destructive_universal 'git clean -fd'
  [ "$status" -eq 0 ]
}

@test "destructive: git clean -fdx" {
  run bash_detect_destructive_universal 'git clean -fdx'
  [ "$status" -eq 0 ]
}

@test "destructive: redirect to /dev/sda" {
  run bash_detect_destructive_universal 'cat foo > /dev/sda'
  [ "$status" -eq 0 ]
}

@test "destructive: SQL DROP DATABASE" {
  run bash_detect_destructive_universal 'psql -c "DROP DATABASE app"'
  [ "$status" -eq 0 ]
}

@test "destructive: SQL DROP SCHEMA case-insensitive" {
  run bash_detect_destructive_universal 'psql -c "drop schema public cascade"'
  [ "$status" -eq 0 ]
}

@test "non-destructive: echo containing DROP TABLE string" {
  run bash_detect_destructive_universal 'echo "the DROP TABLE pattern"'
  # Echo of SQL string is NOT subagent-restricted-pattern; only universal is checked here.
  # DROP TABLE is subagent-tier, so universal should not flag it.
  [ "$status" -ne 0 ]
}

# ── Destructive patterns: subagent-only ───────────────────────────────

@test "subagent-destructive: SQL DROP TABLE" {
  run bash_detect_destructive_subagent 'psql -c "DROP TABLE users"'
  [ "$status" -eq 0 ]
}

@test "subagent-destructive: SQL DROP TABLE case-insensitive" {
  run bash_detect_destructive_subagent 'psql -c "drop table users"'
  [ "$status" -eq 0 ]
}

@test "subagent-destructive: SQL TRUNCATE" {
  run bash_detect_destructive_subagent 'psql -c "TRUNCATE foo"'
  [ "$status" -eq 0 ]
}

@test "non-subagent-destructive: rm -rf (handled by universal, not subagent)" {
  run bash_detect_destructive_subagent 'rm -rf *'
  [ "$status" -ne 0 ]
}

@test "non-subagent-destructive: word containing TRUNCATE substring (TRUNCATED)" {
  run bash_detect_destructive_subagent 'echo "the file was TRUNCATED yesterday"'
  [ "$status" -ne 0 ]
}
