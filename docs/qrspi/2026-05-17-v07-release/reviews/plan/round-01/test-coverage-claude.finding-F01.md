---
finding_id: R1-F01
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/plan.md, docs/qrspi/2026-05-17-v07-release/design.md]
artifact: plan
round: 1
reviewer: test-coverage-claude
---

T04's test expectation for exit-code pass-through is not falsifiable as written. The current expectation reads: "Existing callers that pipe a prompt into run-codex-review.sh observe identical success-path behavior and identical exit codes for the timeout, job-not-found, hard-error, malformed-body, and phantom-launch error paths."

The phrase "identical exit codes" is not a testable specification — it states that codes are preserved but does not name the expected numeric code for each error path. A test writer cannot write a deterministic test from this: the fixture must set up a timeout condition and assert the shim exits specifically 10 (not 11, not 13), but the expectation does not say "timeout produces exit 10" — it says "identical to the dispatcher." The dispatcher's codes are enumerated in T03's expectations (0/1/10/11/13/14/15), but T04's expectation only cross-references them implicitly.

To make this verifiable: name each expected exit code explicitly in T04's test expectations, parallel to T03. For example: "A timeout condition forwarded through the shim produces exit 10; a job-not-found condition produces exit 11; a hard-error produces exit 13; a malformed result body produces exit 14; a phantom-launch produces exit 15." This makes each test case independently verifiable without relying on cross-task implicit reference.

The design's G2 test strategy (design.md around line 132) specifies "simulate each failure case... verify the matching numbered exit code" — this determinism requirement applies to the shim's pass-through as well.
