---
id: F01
reviewer: security-claude
round: 1
severity: medium
category: fail-closed
task: Task 1 (G1)
status: open
---

# F01: DEL (0x7F) in header-name position has no test-expectation pin

## What the plan says

Task 1 test expectations include:

> Every C0 control byte (0x00 through 0x1F) supplied as a header **name** causes the script to exit before reaching any network dispatch call
> DEL (0x7F) in a header **value** causes the script to exit before any network dispatch

## The gap

The two bullet points above are asymmetric: 0x7F (DEL) is required only in the header-*value* position. There is no test expectation requiring that 0x7F in a header *name* position also triggers the die path.

`_control_char_check` is designed to return non-zero whenever "at least one control byte [is] present," and the structure interface spec gives the function a single string argument with no name/value distinction. A correct implementation catches DEL for both positions uniformly. However, the test expectations do not *pin* this:

- An implementer who tests `name` bytes with `[0x00-0x1F]` and `value` bytes with `[0x00-0x1F\x7F]` — using different patterns for each call site rather than the shared helper — would pass all tests while leaving DEL in a header name undetected.
- The RED→GREEN gate explicitly relies on tests to constrain the implementation. Without the pin, the gate cannot catch this divergence.

## Why this matters

G1's stated motivation (goals.md) is that silent failure of control-character detection "allows prompt-injection vectors (CR/LF/NUL in user-supplied content) to reach downstream providers undetected." A header name containing DEL is a valid injection vector on providers that log or reflect header names. Leaving it unpinned means the fix can be delivered in a state where 32 of 33 target bytes are blocked in both positions, but the 33rd is blocked only in the value position.

## Required fix

Add an explicit test expectation to Task 1:

> DEL (0x7F) in a header **name** causes the script to exit before any network dispatch — regression guard parallel to the existing LF-in-value guard.

This expectation can be in the same unit test as the existing "DEL in value" case; it adds one test assertion.
