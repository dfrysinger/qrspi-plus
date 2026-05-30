---
finding_id: R4-F02
severity: low
change_type: clarity
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/plan.md]
artifact: plan
round: 4
reviewer: testcov-claude
---

# Task 6 — Mismatch-warning exit-code assertion is relative, not absolute

## Location

Task 6 test expectations, the mismatch-diagnostic bullet:

> "Under a mocked mismatch between `detect_host` output and the `codex_reviews` config value, the dispatch surface emits a single line to stderr identifying the disagreement and continues with the configured policy; the mismatch does not change the exit code or block dispatch"

Also the follow-up bullet:

> "The mismatch diagnostic is a warning signal only -- it does not gate dispatch"

## Problem

"Does not change the exit code" is a relative assertion — it specifies what the exit code is *not* (different from baseline) rather than what it *is*. A deterministic test assertion requires an absolute expected value. To write `assert_equal "$status" X`, the test writer needs to know X.

The implicit intent is that mismatch + successful dispatch = exit code 0, but this requires the test writer to reason outside the stated expectation. The phrasing could also be read as "exit code equals whatever the non-mismatch case returns," which is not testable without a separately-established baseline.

## Why This Matters

The original R3 expectation said "returns non-zero exit code" — which was wrong per design intent (mismatch is a warning), so R4 corrected it by removing the non-zero claim. But the correction stopped short of specifying the correct exit code. The result is an expectation that says what the exit code is NOT without saying what it IS.

## Fix

Replace the relative assertion with an absolute one:

> "Under a mocked mismatch between `detect_host` output and the `codex_reviews` config value, the dispatch surface emits a single line to stderr identifying the disagreement, returns exit code 0, and dispatch proceeds normally. The mismatch is a warning only and does not affect the dispatch exit code."

This is deterministic: the test asserts `$status -eq 0` after setting up a mismatch scenario.
