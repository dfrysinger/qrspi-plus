---
finding_id: F03
round: 2
reviewer: test-coverage-claude
severity: medium
task: Task 1
category: edge_cases
status: open
---

# F03 — Task 1: Mixed-content header injection pattern is not tested

## Problem

All Task 1 test expectations describe header values that ARE the control character
(i.e., a single control byte is the entire value). None test the case where a control
byte is **embedded within otherwise printable content**, which is the actual HTTP header
injection attack pattern.

**Existing expectations (all describe single-control-char or all-clean scenarios):**
- "Every C0 control byte … supplied as a header value causes the script to exit"
- "LF (0x0A) in a header value causes the script to exit"
- "NUL (0x00) in a header value causes exit"
- "A header containing only printable ASCII … does not trigger the die path"

None of these test a header value such as `"application/json\r\nX-Injected: evil"`,
where a control byte is embedded within a string that starts with printable characters.

## Why This Is an Actionable Gap

The natural language "Every C0 control byte … supplied as a header value" is ambiguous:

- Narrow reading: the header value **is** that byte (the entire value is a single
  control char)
- Broad reading: the header value **contains** that byte anywhere (including mid-string)

An implementation that only tests `value == "\n"` would pass all current expectations
but miss the injection payload `"text/plain\nX-Evil: injected"`.

Design DKR1's description says "any control-character match causes the script to abort"
— the word "match" implies detection anywhere in the value, not only when the value is
exclusively a control byte. But the test expectations leave the boundary ambiguous, and
a security pre-flight control that misses embedded control bytes provides incomplete
protection.

This function is the sole security gate before network calls in the
`openai-chat-completions` path. An untested mixed-content case is the gap the test suite
is most likely to miss, because the clean-ASCII and pure-control-byte cases will
naturally drive implementation in opposite directions without anchoring the mixed case.

## Required Fix

Add one test expectation for the mixed-content (embedded) case:

> A header value consisting of printable ASCII characters followed by an embedded CR LF
> sequence (e.g., `Content-Type: text/plain\r\nX-Injected: evil`) causes the script to
> exit before any network dispatch call — the control-character detection matches
> embedded control bytes, not only values that are exclusively a single control byte

A similar assertion for header names (e.g., a header name containing an embedded colon
followed by printable content) is also warranted but optional if the implementation
description is clear that headers are split on `:` before detection.
