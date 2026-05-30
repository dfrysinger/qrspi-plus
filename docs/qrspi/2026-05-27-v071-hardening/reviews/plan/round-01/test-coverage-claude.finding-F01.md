# Finding F01: Task 1 — BSD-grep unavailability expectation is not deterministically verifiable

**Artifact:** plan.md
**Task:** Task 1 (G1 — POSIX control-char detection rewrite)
**Category:** Test Expectation Quality
**Severity:** advisory

## Problem

The expectation "The detection produces correct results when invoked in an environment where `grep -P` is unavailable (BSD grep without PCRE support)" is not a falsifiable, deterministic test as written.

The implementation replaces `grep -qP` with `LC_ALL=C tr` + `wc -c`, so after the fix the codebase no longer calls `grep -P` at all. "Correct results when `grep -P` is unavailable" therefore conflates two separable checks:

1. A **structural** check that the new implementation contains no call to `grep -P` (grep the script for the old pattern).
2. A **behavioral** check that the die path still fires on a control byte in the absence of PCRE grep — which is already covered by the other die-path expectations if the test harness itself doesn't invoke `grep -P`.

As written the expectation provides no mechanism a test writer can use: should they `PATH`-stub grep to exit non-zero on `-P`? Should they assert `grep -P` is absent from the code path? Should they run the BATS suite under macOS system grep? Without a specified mechanism the test is unwritable, and the expectation is therefore unfalsifiable.

## Recommendation

Replace with two specific expectations:

- "`scripts/run-third-party-llm.sh`'s `_control_char_check` function contains no call to `grep -P` (verified by a `grep` structural assertion in the test suite)."
- "The existing die-path expectations (every C0 byte causes exit) pass in the CI BATS-under-bash-3.2 job, which runs in the test environment without requiring PCRE grep."

This makes both the structural guarantee and the behavioral guarantee independently verifiable.
