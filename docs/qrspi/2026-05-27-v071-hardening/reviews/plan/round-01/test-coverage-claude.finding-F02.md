# Finding F02: Task 1 — Empty string not covered as a happy-path edge case for `_control_char_check`

**Artifact:** plan.md
**Task:** Task 1 (G1 — POSIX control-char detection rewrite)
**Category:** Edge Cases
**Severity:** advisory

## Problem

The test expectations cover every C0 byte, DEL, LF, and clean printable ASCII as header inputs, but omit the **empty string** as an input to `_control_char_check`.

The function signature (per `structure.md` Interfaces) is `_control_char_check(str)`, where `str` is a single header name or header value. An empty header name or value is a plausible input: some provider config files may omit optional headers entirely, and a looping caller could pass `""`. The expected behavior is unambiguous (no control bytes in an empty string → return 0, allow execution to continue), but without an explicit expectation, an implementation that special-cases empty input (e.g., returns non-zero defensively, or calls `tr` in a way that produces incorrect byte counts on empty input due to locale differences) would go undetected.

Given that `wc -c` on an empty string has known portability quirks in some locales, pinning the empty-input case to a known "no-op / return 0" expectation acts as an additional POSIX portability guard.

## Recommendation

Add one expectation:

- "An empty string supplied as a header name or header value does not trigger the die path (return code 0, execution continues)."
