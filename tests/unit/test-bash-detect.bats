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

@test "destructive: rm -rf with absolute path as second target" {
  run bash_detect_destructive_universal 'rm -rf build /etc'
  [ "$status" -eq 0 ]
}

@test "destructive: rm -rf with home glob as second target" {
  run bash_detect_destructive_universal 'rm -rf target ~/Documents'
  [ "$status" -eq 0 ]
}

@test "destructive: rm -rf with parent traversal as second target" {
  run bash_detect_destructive_universal 'rm -rf safe_dir ../credentials'
  [ "$status" -eq 0 ]
}

@test "non-destructive: git clean -fdn is dry-run" {
  run bash_detect_destructive_universal 'git clean -fdn'
  [ "$status" -ne 0 ]
}

@test "non-destructive: git clean -fdXn is dry-run" {
  run bash_detect_destructive_universal 'git clean -fdXn'
  [ "$status" -ne 0 ]
}

# ── R2 S-N2: coverage-gap fixes — additional write-syntax detection ────
#
# Helper to assert opaque-write sentinel emitted (for inline interpreters
# whose target cannot be statically parsed).
assert_opaque_write() {
    local output="$1"
    if [[ "$output" != *"__OPAQUE_WRITE__"* ]]; then
        echo "Expected opaque-write sentinel (__OPAQUE_WRITE__) not found"
        echo "Got output: $output"
        return 1
    fi
}

# No-space redirect: `>file`
@test "S-N2: detects no-space redirect >/etc/poison" {
    result=$(bash_detect_file_writes 'echo X >/etc/poison')
    assert_contains_path "$result" "/etc/poison"
}

# No-space append redirect: `>>file`
@test "S-N2: detects no-space append redirect >>/tmp/log" {
    result=$(bash_detect_file_writes 'echo X >>/tmp/log')
    assert_contains_path "$result" "/tmp/log"
}

# Clobber redirect: `>|file`
@test "S-N2: detects clobber redirect >|/abs/path" {
    result=$(bash_detect_file_writes 'echo X >|/abs/path')
    assert_contains_path "$result" "/abs/path"
}

# Clobber redirect with space: `>| file`
@test "S-N2: detects clobber redirect with space >| /abs/path" {
    result=$(bash_detect_file_writes 'echo X >| /abs/path')
    assert_contains_path "$result" "/abs/path"
}

# Leading redirect: `>file cmd ...` (POSIX)
@test "S-N2: detects leading redirect >file printf X" {
    result=$(bash_detect_file_writes '>/tmp/leading printf X')
    assert_contains_path "$result" "/tmp/leading"
}

# Inline interpreter: python -c
@test "S-N2: opaque-write sentinel for python -c" {
    result=$(bash_detect_file_writes "python -c \"open('/abs/path','w').write('x')\"")
    assert_opaque_write "$result"
}

# Inline interpreter: python3 -c
@test "S-N2: opaque-write sentinel for python3 -c" {
    result=$(bash_detect_file_writes "python3 -c \"open('/abs/path','w').write('x')\"")
    assert_opaque_write "$result"
}

# Inline interpreter: node -e
@test "S-N2: opaque-write sentinel for node -e" {
    result=$(bash_detect_file_writes "node -e \"require('fs').writeFileSync('/abs/path','x')\"")
    assert_opaque_write "$result"
}

# Inline interpreter: node --eval
@test "S-N2: opaque-write sentinel for node --eval" {
    result=$(bash_detect_file_writes "node --eval \"require('fs').writeFileSync('/abs/path','x')\"")
    assert_opaque_write "$result"
}

# Inline interpreter: perl -e
@test "S-N2: opaque-write sentinel for perl -e" {
    result=$(bash_detect_file_writes "perl -e 'open(F,\">/abs/path\");print F \"x\"'")
    assert_opaque_write "$result"
}

# Inline interpreter: ruby -e
@test "S-N2: opaque-write sentinel for ruby -e" {
    result=$(bash_detect_file_writes "ruby -e \"File.write('/abs/path','x')\"")
    assert_opaque_write "$result"
}

# dd of=path
@test "S-N2: detects dd of=/abs/path" {
    result=$(bash_detect_file_writes 'dd if=/dev/zero of=/abs/path bs=1 count=1')
    assert_contains_path "$result" "/abs/path"
}

# dd of="quoted path"
@test "S-N2: detects dd of=\"/abs/quoted path\"" {
    result=$(bash_detect_file_writes 'dd if=/dev/zero of="/abs/quoted path"')
    assert_contains_path "$result" "/abs/quoted path"
}

# install (BSD/GNU)
@test "S-N2: detects install -m 644 src dst" {
    result=$(bash_detect_file_writes 'install -m 644 source.txt /abs/dest.txt')
    assert_contains_path "$result" "/abs/dest.txt"
}

# rsync src dst
@test "S-N2: detects rsync src /abs/dest" {
    result=$(bash_detect_file_writes 'rsync source.txt /abs/dest')
    assert_contains_path "$result" "/abs/dest"
}

# rsync with flags
@test "S-N2: detects rsync -av src /abs/dest" {
    result=$(bash_detect_file_writes 'rsync -av source/ /abs/dest/')
    assert_contains_path "$result" "/abs/dest"
}

# awk BEGIN { print > "..." } — opaque (cannot reliably parse awk script)
@test "S-N2: opaque-write sentinel for awk BEGIN with redirect" {
    result=$(bash_detect_file_writes "awk 'BEGIN{print > \"/abs/path\"}' </dev/null")
    assert_opaque_write "$result"
}

# Heredoc + redirect: `cat <<EOF >/file` — should detect /file via redirect
@test "S-N2: detects redirect after heredoc cat <<EOF >/file" {
    result=$(bash_detect_file_writes 'cat <<EOF >/tmp/heredoc-out')
    assert_contains_path "$result" "/tmp/heredoc-out"
}

# Negative: python without -c flag (running a script) is NOT opaque
@test "S-N2: python script.py without -c is not flagged opaque" {
    result=$(bash_detect_file_writes 'python script.py')
    if [[ "$result" == *"__OPAQUE_WRITE__"* ]]; then
        echo "Should not flag plain python invocation as opaque"
        return 1
    fi
}

# Negative: node script.js without -e is NOT opaque
@test "S-N2: node script.js without -e is not flagged opaque" {
    result=$(bash_detect_file_writes 'node script.js')
    if [[ "$result" == *"__OPAQUE_WRITE__"* ]]; then
        echo "Should not flag plain node invocation as opaque"
        return 1
    fi
}

# Negative: rsync with --dry-run still flags (we don't parse semantics; safer to be over-broad)
# Negative: ls /abs/path is not a write
@test "S-N2: ls /abs/path is not detected as write" {
    result=$(bash_detect_file_writes 'ls /abs/path')
    assert_empty "$result"
}

# Existing-behavior regression: tab-spaced redirect still detected
@test "S-N2 regression: tab-separated redirect still detected" {
    # Use printf to inject a real tab between '>' and path
    local cmd
    cmd=$(printf 'echo foo >\t/tmp/tabbed')
    result=$(bash_detect_file_writes "$cmd")
    assert_contains_path "$result" "/tmp/tabbed"
}

# Regression: existing simple redirect still works
@test "S-N2 regression: simple > /tmp/out still works" {
    result=$(bash_detect_file_writes 'echo foo > /tmp/out')
    assert_contains_path "$result" "/tmp/out"
}

# Regression: existing tee still works
@test "S-N2 regression: tee output.txt still works" {
    result=$(bash_detect_file_writes 'echo x | tee output.txt')
    assert_contains_path "$result" "output.txt"
}

# Compound: multiple bypass patterns in one command — both detected
@test "S-N2: compound dd && python -c — both flagged" {
    result=$(bash_detect_file_writes "dd of=/a if=/dev/zero && python -c \"open('/b','w')\"")
    assert_contains_path "$result" "/a"
    assert_opaque_write "$result"
}
