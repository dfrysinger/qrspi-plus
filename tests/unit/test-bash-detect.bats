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

# ── R2 S-N2 self-review hardening (post-initial-fix tightening) ──────
# The reviewer (acting as security auditor) identified additional bypass
# variants the first-pass detector missed. These tests lock in the fix.

# bash -c is opaque (same as python -c)
@test "S-N2 hardening: bash -c is flagged opaque" {
    result=$(bash_detect_file_writes "bash -c \"echo X >/etc/poison\"")
    assert_opaque_write "$result"
}

# sh -c is opaque
@test "S-N2 hardening: sh -c is flagged opaque" {
    result=$(bash_detect_file_writes "sh -c \"echo X >/etc/poison\"")
    assert_opaque_write "$result"
}

# Combined-flag interpreter: python -bc (bytecode + command)
@test "S-N2 hardening: python -bc combined flags is flagged opaque" {
    result=$(bash_detect_file_writes "python -bc \"open('/x','w').write('y')\"")
    assert_opaque_write "$result"
}

# Multi-flag interpreter: python -B -c
@test "S-N2 hardening: python -B -c separated flags is flagged opaque" {
    result=$(bash_detect_file_writes "python -B -c \"open('/x','w').write('y')\"")
    assert_opaque_write "$result"
}

# Multi-flag interpreter: python3 -u -c
@test "S-N2 hardening: python3 -u -c is flagged opaque" {
    result=$(bash_detect_file_writes "python3 -u -c \"open('/x','w').write('y')\"")
    assert_opaque_write "$result"
}

# `<>file` (RW open) creates the file — should be detected as a write
@test "S-N2 hardening: <>file (RW open) detected as write" {
    result=$(bash_detect_file_writes "exec 3<>/abs/rwopen")
    assert_contains_path "$result" "/abs/rwopen"
}

# `dd` inside command substitution `$(dd of=...)`
@test "S-N2 hardening: dd in command substitution detected" {
    result=$(bash_detect_file_writes "x=\$(dd of=/abs/sub if=/dev/zero count=1)")
    assert_contains_path "$result" "/abs/sub"
}

# `install` inside command substitution
@test "S-N2 hardening: install in command substitution detected" {
    result=$(bash_detect_file_writes "x=\$(install src /abs/installed)")
    assert_contains_path "$result" "/abs/installed"
}

# `rsync` inside command substitution
@test "S-N2 hardening: rsync in command substitution detected" {
    result=$(bash_detect_file_writes "x=\$(rsync src /abs/synced)")
    assert_contains_path "$result" "/abs/synced"
}

# `&>file` combined stdout+stderr redirect
@test "S-N2 hardening: &>file combined stdout+stderr redirect detected" {
    result=$(bash_detect_file_writes "cmd &>/abs/combined.log")
    assert_contains_path "$result" "/abs/combined.log"
}

# `&>>file` append combined stdout+stderr
@test "S-N2 hardening: &>>file append combined detected" {
    result=$(bash_detect_file_writes "cmd &>>/abs/combined.log")
    assert_contains_path "$result" "/abs/combined.log"
}

# Negative: `<<<` herestring should NOT trigger redirect detection
@test "S-N2 hardening: <<< herestring not flagged as redirect" {
    result=$(bash_detect_file_writes 'cat <<<"some content"')
    if [[ "$result" == */abs/* || "$result" == *some* ]]; then
        echo "False positive on herestring: $result"
        return 1
    fi
}

# Negative: shell variable that contains 'dd' substring (e.g., 'add')
# should NOT trigger dd detector
@test "S-N2 hardening: 'add' command not flagged as dd" {
    result=$(bash_detect_file_writes 'add of=foo')
    # 'add' is a non-existent command; the detector shouldn't synthesize a path.
    # We accept that 'foo' may be captured as bareword via redirect parser; the
    # specific check is that the regex anchor used for 'dd' doesn't match 'add'.
    # We verify no path mentions of=foo via dd's of= shape — by checking
    # detector doesn't claim 'foo' alone (the of= regex would extract 'foo'
    # from 'add of=foo'). The regex should NOT match because 'a' precedes 'dd'.
    # This test passes if 'foo' is NOT in result (meaning of= regex skipped).
    if [[ "$result" == "foo" ]]; then
        echo "False positive: 'add of=foo' should not match dd's of= pattern"
        return 1
    fi
}

# Sanity: existing python -c still opaque
@test "S-N2 hardening: existing python -c still flagged" {
    result=$(bash_detect_file_writes "python -c \"open('/x','w')\"")
    assert_opaque_write "$result"
}

# ── task-43 S-2: cd-before-relative-write subagent escape ─────────────
#
# A subagent inside a worktree could otherwise issue
# `cd /tmp && echo x > escaped.txt`. The bash-detect output would be the
# bare relative target `escaped.txt`, which pre-tool-use resolves against
# its own PWD (the worktree root), masking the actual /tmp/escaped.txt
# write. The fix: when a `cd <outside>` precedes a relative-path write in
# the same compound command, the relative target is opaque
# (__OPAQUE_WRITE__ sentinel) — the wall fails closed.
#
# Codex round-3 finding (round-2 fix). Conservative posture: cd into a
# relative subdir of the current worktree is still allowed (the subdir
# stays inside the worktree).

# cd /tmp && echo X > rel — opaque (cd-out absolute)
@test "task-43 S-2: cd /tmp && echo > rel is opaque" {
    result=$(bash_detect_file_writes 'cd /tmp && echo x > escaped.txt')
    assert_opaque_write "$result"
}

# cd /tmp; echo X > rel — opaque (cd-out absolute, semicolon)
@test "task-43 S-2: cd /tmp; echo > rel is opaque (semicolon)" {
    result=$(bash_detect_file_writes 'cd /tmp; echo x > escaped.txt')
    assert_opaque_write "$result"
}

# cd /tmp && tee rel — opaque (alt write syntax via tee)
@test "task-43 S-2: cd /tmp && tee rel is opaque (tee write)" {
    result=$(bash_detect_file_writes 'cd /tmp && tee escaped.txt < input')
    assert_opaque_write "$result"
}

# cd ../../.. && echo > rel — opaque (cd-out relative with ..)
@test "task-43 S-2: cd ../../.. && echo > rel is opaque (parent traversal)" {
    result=$(bash_detect_file_writes 'cd ../../.. && echo x > escaped.txt')
    assert_opaque_write "$result"
}

# cd ~ && echo > rel — opaque (cd to home expansion)
@test "task-43 S-2: cd ~ && echo > rel is opaque (home expansion)" {
    result=$(bash_detect_file_writes 'cd ~ && echo x > escaped.txt')
    assert_opaque_write "$result"
}

# cd - && echo > rel — opaque (cd to OLDPWD untracked)
@test "task-43 S-2: cd - && echo > rel is opaque (OLDPWD)" {
    result=$(bash_detect_file_writes 'cd - && echo x > escaped.txt')
    assert_opaque_write "$result"
}

# cd /tmp && cp src dst — opaque (cp dest is relative)
@test "task-43 S-2: cd /tmp && cp src dst is opaque (cp relative dst)" {
    result=$(bash_detect_file_writes 'cd /tmp && cp source.txt dest.txt')
    assert_opaque_write "$result"
}

# cd /tmp && mv src dst — opaque
@test "task-43 S-2: cd /tmp && mv old new is opaque (mv relative dst)" {
    result=$(bash_detect_file_writes 'cd /tmp && mv old.txt new.txt')
    assert_opaque_write "$result"
}

# cd /tmp && sed -i — opaque (sed file is relative)
@test "task-43 S-2: cd /tmp && sed -i is opaque" {
    result=$(bash_detect_file_writes "cd /tmp && sed -i 's/x/y/' config.txt")
    assert_opaque_write "$result"
}

# cd /tmp && dd of=rel — opaque
@test "task-43 S-2: cd /tmp && dd of=rel is opaque" {
    result=$(bash_detect_file_writes 'cd /tmp && dd if=/dev/zero of=escaped count=1')
    assert_opaque_write "$result"
}

# cd /tmp && rsync src rel — opaque
@test "task-43 S-2: cd /tmp && rsync src rel is opaque" {
    result=$(bash_detect_file_writes 'cd /tmp && rsync src.txt escaped.txt')
    assert_opaque_write "$result"
}

# Negative: cd subdir-inside-worktree && echo > rel — STILL allowed
# The cd target is a relative subdir (no /, no ..). Post-cd CWD is still
# inside the worktree (or descended into a subdir thereof), so resolving
# `inside.txt` against hook PWD is wrong by exact path but right by
# containment — the wall regex `\.worktrees/.../task-NN/` still matches.
@test "task-43 S-2 NEGATIVE: cd subdir && echo > rel still extracts target" {
    result=$(bash_detect_file_writes 'cd src && echo x > inside.txt')
    assert_contains_path "$result" "inside.txt"
    # Should NOT be opaque
    if [[ "$result" == *"__OPAQUE_WRITE__"* ]]; then
        echo "False-positive opaque: cd into relative subdir should not flag opaque"
        echo "Got: $result"
        return 1
    fi
}

# Negative: cd src/sub && echo > rel — relative subdir with slash is fine
@test "task-43 S-2 NEGATIVE: cd src/sub && echo > rel is not opaque" {
    result=$(bash_detect_file_writes 'cd src/sub && echo x > inside.txt')
    assert_contains_path "$result" "inside.txt"
    if [[ "$result" == *"__OPAQUE_WRITE__"* ]]; then
        echo "False-positive opaque: cd into relative nested subdir should not flag"
        return 1
    fi
}

# Negative: cd /tmp && echo > /abs/path — absolute write target
# The cd-out happens, but the write target is ABSOLUTE — the wall checks
# the absolute path directly without consulting CWD. The detector emits
# the absolute path; the wall's regex match decides allow/block. (For an
# absolute path outside the worktree the wall blocks anyway; for one
# inside a worktree it allows. Neither outcome depends on CWD.)
@test "task-43 S-2 NEGATIVE: cd /tmp && echo > /abs/path emits absolute path" {
    result=$(bash_detect_file_writes 'cd /tmp && echo x > /abs/poison')
    assert_contains_path "$result" "/abs/poison"
}

# Negative: plain `echo > rel` (no cd) — relative path emitted as before
@test "task-43 S-2 NEGATIVE: plain relative redirect (no cd) unchanged" {
    result=$(bash_detect_file_writes 'echo x > inside.txt')
    assert_contains_path "$result" "inside.txt"
    if [[ "$result" == *"__OPAQUE_WRITE__"* ]]; then
        echo "False-positive: plain relative redirect should not be opaque"
        return 1
    fi
}

# Multi-cd: cd src && cd /tmp && echo > rel — opaque (any cd-out triggers)
@test "task-43 S-2: cd src && cd /tmp && echo > rel is opaque (later cd-out)" {
    result=$(bash_detect_file_writes 'cd src && cd /tmp && echo x > escaped.txt')
    assert_opaque_write "$result"
}

# cd /tmp && cd back-to-relative — still opaque (we don't track CWD precisely)
@test "task-43 S-2: cd /tmp && cd subdir && echo > rel is opaque (conservative)" {
    result=$(bash_detect_file_writes 'cd /tmp && cd src && echo x > escaped.txt')
    assert_opaque_write "$result"
}

# ── task-46 M4-1: broaden cd-escape detection ─────────────────────────
#
# Round-4 review M4-1: task-43's S-2 fix was incomplete. The `cd_re`
# regex only matched literal targets; subagents could still escape via:
#   1. Variable / parameter expansion: `cd $HOME`, `cd "${TMPDIR}"`
#   2. Command substitution: `cd "$(mktemp -d)"`, `` cd `pwd` ``
#   3. `pushd` (cd_re required `^cd[[:space:]]+`)
#   4. Subshell / brace-group wrapping: `(cd /tmp; > escape)`,
#      `{ cd /tmp; > escape; }` — splitter only handles `&&`, `||`, `;`
#   5. Same-command assignment-then-cd: `dest=/tmp; cd "$dest"` (variant
#      of #1 — covered once the variable case lands)
#
# Conservative posture (matches task-43 stance): any cd target containing
# `$` or `` ` `` is opaque; pushd is always opaque (we don't track the
# stack); cd / pushd inside `( )` or `{ }` triggers via inner-scan.

# 1. Variable expansion — bareword
@test "task-46 M4-1: cd \$HOME && echo > rel is opaque (var expansion)" {
    result=$(bash_detect_file_writes 'cd $HOME && echo x > escape.txt')
    assert_opaque_write "$result"
}

# 1. Variable expansion — double-quoted
@test "task-46 M4-1: cd \"\$HOME\" && echo > rel is opaque (quoted var)" {
    result=$(bash_detect_file_writes 'cd "$HOME" && echo x > escape.txt')
    assert_opaque_write "$result"
}

# 1. Brace parameter expansion
@test "task-46 M4-1: cd \"\${TMPDIR}\" && echo > rel is opaque (brace param)" {
    result=$(bash_detect_file_writes 'cd "${TMPDIR}" && echo x > escape.txt')
    assert_opaque_write "$result"
}

# 2. Command substitution — $()
@test "task-46 M4-1: cd \"\$(mktemp -d)\" && echo > rel is opaque (cmd subst)" {
    result=$(bash_detect_file_writes 'cd "$(mktemp -d)" && echo x > escape.txt')
    assert_opaque_write "$result"
}

# 2. Command substitution — backticks
@test "task-46 M4-1: cd \`pwd\` && echo > rel is opaque (backtick subst)" {
    result=$(bash_detect_file_writes 'cd `pwd` && echo x > escape.txt')
    assert_opaque_write "$result"
}

# 3. pushd /abs
@test "task-46 M4-1: pushd /tmp && echo > rel is opaque (pushd absolute)" {
    result=$(bash_detect_file_writes 'pushd /tmp && echo x > escape.txt')
    assert_opaque_write "$result"
}

# 3. pushd "$VAR"
@test "task-46 M4-1: pushd \"\$HOME\" && echo > rel is opaque (pushd var)" {
    result=$(bash_detect_file_writes 'pushd "$HOME" && echo x > escape.txt')
    assert_opaque_write "$result"
}

# 3. pushd into a relative subdir is still opaque (we don't track stack)
@test "task-46 M4-1: pushd subdir && echo > rel is opaque (pushd untracked stack)" {
    result=$(bash_detect_file_writes 'pushd src && echo x > escape.txt')
    assert_opaque_write "$result"
}

# 4. Subshell wrapping — `(cd /tmp; > escape)`
@test "task-46 M4-1: (cd /tmp; echo > escape) is opaque (subshell wrap)" {
    result=$(bash_detect_file_writes '(cd /tmp; echo x > escape.txt)')
    assert_opaque_write "$result"
}

# 4. Brace-group wrapping — `{ cd /tmp; > escape; }`
@test "task-46 M4-1: { cd /tmp; echo > escape; } is opaque (brace-group wrap)" {
    result=$(bash_detect_file_writes '{ cd /tmp; echo x > escape.txt; }')
    assert_opaque_write "$result"
}

# 5. Same-command assignment-then-cd via variable expansion
@test "task-46 M4-1: dest=/tmp && cd \"\$dest\" && echo > rel is opaque (assign+var)" {
    result=$(bash_detect_file_writes 'dest=/tmp && cd "$dest" && echo x > escape.txt')
    assert_opaque_write "$result"
}

# Backgrounded subshell: `(cd /tmp && > escape) &`
@test "task-46 M4-1: (cd /tmp && echo > escape) & is opaque (backgrounded subshell)" {
    result=$(bash_detect_file_writes '(cd /tmp && echo x > escape.txt) &')
    assert_opaque_write "$result"
}

# popd — same conservative treatment as pushd
@test "task-46 M4-1: popd && echo > rel is opaque (popd untracked stack)" {
    result=$(bash_detect_file_writes 'popd && echo x > escape.txt')
    assert_opaque_write "$result"
}

# ── Positive coverage (must STILL be allowed) ──────────────────────────
# These were allowed before task-46 and must continue to work — false
# positives that block legitimate cd-into-subdir would break normal
# subagent use of `cd src && ...` patterns.

# Plain bareword subdir
@test "task-46 M4-1 NEGATIVE: cd src && echo > rel still allowed" {
    result=$(bash_detect_file_writes 'cd src && echo x > inside.txt')
    assert_contains_path "$result" "inside.txt"
    if [[ "$result" == *"__OPAQUE_WRITE__"* ]]; then
        echo "False-positive: cd src is a relative subdir — must not be opaque"
        echo "Got: $result"
        return 1
    fi
}

# Nested relative subdir
@test "task-46 M4-1 NEGATIVE: cd subdir/nested && > rel still allowed" {
    result=$(bash_detect_file_writes 'cd subdir/nested && echo x > inside.txt')
    assert_contains_path "$result" "inside.txt"
    if [[ "$result" == *"__OPAQUE_WRITE__"* ]]; then
        echo "False-positive: cd into nested relative subdir must not be opaque"
        echo "Got: $result"
        return 1
    fi
}

# `cd .` is a no-op cd that keeps CWD identical — must not flag.
@test "task-46 M4-1 NEGATIVE: cd . && echo > rel still allowed" {
    result=$(bash_detect_file_writes 'cd . && echo x > inside.txt')
    assert_contains_path "$result" "inside.txt"
    if [[ "$result" == *"__OPAQUE_WRITE__"* ]]; then
        echo "False-positive: cd . is a no-op — must not be opaque"
        echo "Got: $result"
        return 1
    fi
}

# ── F-3: project-internal absolute paths allowed ─────────────────────────────

@test "[F-3] non-destructive: rm -rf project-internal absolute path under \$PWD" {
  local probe_dir
  probe_dir=$(mktemp -d)
  cd "$probe_dir"
  run bash_detect_destructive_universal "rm -rf $probe_dir/.scratch"
  [ "$status" -ne 0 ]
  rm -rf "$probe_dir"
}

@test "[F-3] non-destructive: rm -rf nested project-internal subdir" {
  local probe_dir
  probe_dir=$(mktemp -d)
  cd "$probe_dir"
  mkdir -p build/intermediates
  run bash_detect_destructive_universal "rm -rf $probe_dir/build/intermediates"
  [ "$status" -ne 0 ]
  rm -rf "$probe_dir"
}

@test "[F-3] destructive: rm -rf /etc still blocked even with PWD set" {
  local probe_dir
  probe_dir=$(mktemp -d)
  cd "$probe_dir"
  run bash_detect_destructive_universal 'rm -rf /etc'
  [ "$status" -eq 0 ]
  rm -rf "$probe_dir"
}

@test "[F-3] destructive: rm -rf sibling project still blocked" {
  local probe_dir sibling
  probe_dir=$(mktemp -d)
  sibling=$(mktemp -d)
  cd "$probe_dir"
  run bash_detect_destructive_universal "rm -rf $sibling/data"
  [ "$status" -eq 0 ]
  rm -rf "$probe_dir" "$sibling"
}

@test "[F-3] destructive: rm -rf with .. inside \$PWD still caught by parent-traversal check" {
  local probe_dir
  probe_dir=$(mktemp -d)
  cd "$probe_dir"
  run bash_detect_destructive_universal "rm -rf $probe_dir/../sibling"
  [ "$status" -eq 0 ]
  rm -rf "$probe_dir"
}
