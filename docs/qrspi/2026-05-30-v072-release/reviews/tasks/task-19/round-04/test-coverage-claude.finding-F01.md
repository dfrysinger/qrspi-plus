---
reviewer_tag: test-coverage-claude
round: 4
finding: F01
severity: minor
change_type: correctness
---

# F01 — Missing exact-one-line assertion for the unknown-vendor-override diagnostic path

## Location

`tests/unit/test-second-reviewer-available.bats`, lines 288–311
(tests `"second-reviewer-available: unknown vendor override exits non-zero with [second-reviewer-unavailable]"` and `"second-reviewer-available: unavailable vendor override diagnostic names the vendor argument"`)

## What the spec requires

The task spec (task-19.md § Test expectations) and the production-code header (`second-reviewer-available.sh` lines 18–20) both state:

> Stderr: on failure, **exactly one line** beginning `[second-reviewer-unavailable]` naming the detected host and the requested/default vendor.

## What the tests assert for the unknown-vendor path

```bash
# test at line 288
[ "$_status" -ne 0 ]
grep -q '^\[second-reviewer-unavailable\]' "$_stderr_file"

# test at line 302
grep -qE 'nonexistent-vendor-xyz|vendor=' "$_stderr_file"
```

The two tests together cover: **exit non-zero** ✅, **tag present** ✅, **vendor named** ✅.
They do **not** cover: **exactly one stderr line** ❌.

## How the unknown-host path handles this

For comparison, the unknown-host scenario *does* assert the line count (lines 248–260):

```bash
local line_count
line_count="$(wc -l < "$_stderr_file" | tr -d ' ')"
[ "$line_count" -eq 1 ]
grep -q '^\[second-reviewer-unavailable\]' "$_stderr_file"
```

The unknown-host-guard test at lines 414–441 also asserts line-count + tag + `host=unknown` + `vendor=openai-codex` for the override case. The equivalent coverage is absent for the unknown-vendor-override scenario.

## Why this matters

The single-line constraint is a behavioral contract, not a style preference. SKILL prose that pipes the probe's stderr, counts diagnostic occurrences, or pattern-matches the first line depends on no extra lines appearing. A future regression—a stray debug `echo`, a multi-`printf` refactor, or a sourced library emitting an extra warning—would break callers silently because neither test at lines 288–311 checks the line count.

## Suggested fix

Add a line-count assertion to the existing unknown-vendor-override test (or merge the two related tests into one):

```bash
@test "second-reviewer-available: unknown vendor override exits non-zero with [second-reviewer-unavailable]" {
  local _stderr_file="$TMP_DIR/unknown-vendor-stderr.txt"
  local _status=0
  bash -c "
    export COPILOT_CLI=1
    \"$SECOND_REVIEWER\" nonexistent-vendor-xyz
  " >/dev/null 2>"$_stderr_file" || _status=$?
  [ "$_status" -ne 0 ]
  # Exactly one stderr line — same one-line contract as the unknown-host path
  local line_count
  line_count="$(wc -l < "$_stderr_file" | tr -d ' ')"
  [ "$line_count" -eq 1 ]
  grep -q '^\[second-reviewer-unavailable\]' "$_stderr_file"
  grep -qE 'nonexistent-vendor-xyz|vendor=' "$_stderr_file"
}
```

## Notes on test 28 (empty-default-vendor-guard)

Test 28 is confirmed **solid** and genuinely exercises the `[ -z "$_default_vendor" ]` guard. The stub injects `lookup_default_second_reviewer() { printf ''; }` (empty string) while keeping `second_reviewer_vendor_known` returning 0 for `openai-codex`. With the `openai-codex` override argument: `_default_vendor=""`, `_vendor="openai-codex"`. The `[ -z "$_default_vendor" ]` guard fires (only that sub-condition evaluates true); removing it causes `second_reviewer_vendor_known "openai-codex"` to return 0 (from the stub), making the entire condition false, the probe exits 0, and the test fails. The fault-injection is correct and the test is non-vacuous.
