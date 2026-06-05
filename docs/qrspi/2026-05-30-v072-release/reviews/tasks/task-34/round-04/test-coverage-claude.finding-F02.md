---
finding_id: R4-F02
reviewer_tag: test-coverage-claude
round: 4
task: 34
severity: minor
change_type: test_coverage
referenced_files:
  - tests/unit/test-plan-post-approval-split.bats
---

# F02 — No behavioral fixture for Task-ID validation halting the full dispatch phase

## Location

`tests/unit/test-plan-post-approval-split.bats`, lines 1053–1101 (all three Task-ID Validation tests).

## Context

The multi-task pre-fan-out HALT for hash mismatch (lines 942–1039) includes a behavioral fixture that seeds a 3-task scenario, runs a scan phase that detects the mismatch, gates the dispatch phase on `mismatch_detected=false`, and asserts `dispatch_count==0`. The test comment explains why this is non-vacuous: a fused scan+dispatch implementation would dispatch task-01 before reaching task-02's mismatch.

## What is missing

Task-ID validation has the same "halts the entire run" property. Its tests cover doc-audit of the pattern, doc-audit of ordering prose, and a behavioral regex test against 5 invalid IDs.

No fixture simulates: a plan.md with one invalid Task ID (`../etc/passwd`) among otherwise-valid headings, a validation-then-scan-then-dispatch loop, and an assertion that `dispatch_count==0` and no `test -e` or path construction occurred for any task.

The security-critical ordering property — "validation before any filesystem operation" — is doc-audited but not behaviorally demonstrated via fixture.

## Why it matters

Task-ID validation is a path-traversal security gate. The ordering invariant (validate all IDs → scan all hashes → dispatch absent tasks) is the mechanism that prevents the attack. The multi-task HALT test established a precedent for demonstrating the scan/dispatch gating via fixture; the same pattern is missing for the validation gate.

Note: Task-ID Validation is beyond the T34 DoD six required sections and was added as an extra section in R4. This finding is therefore out of scope for the T34 Definition of Done and is reported as an accepted-with-issues observation.

## Remediation (informational — budget exhausted, accepted-with-issues)

Add a behavioral test analogous to the multi-task HALT test, gating the dispatch phase on `invalid_id_detected`. Asserts: `invalid_detected=true`, `dispatch_count==0`, no task files written.
