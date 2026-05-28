---
finding_id: F02
severity: blocking
change_type: correctness
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/plan.md, docs/qrspi/2026-05-27-v071-hardening/goals.md, docs/qrspi/2026-05-27-v071-hardening/design.md]
artifact: plan
round: 1
reviewer: spec-claude
---

## Mismatch-diagnostic test expectation verifies prose presence, not behavioral emission

goals.md G6: "emit a one-line diagnostic naming the disagreement." design.md DKR6: "emit a one-line diagnostic naming the disagreement." Both use behavioral language. Task 7 description says the hook "fires." The test expectation only checks SKILL.md prose presence, not runtime behavior. Untestable as a true behavioral acceptance.

**Resolution (Option A, preferred — matches goal/design language):** Add a behavioral test expectation in Task 6 or Task 7 asserting that under a mocked mismatch between detect_host output and codex_reviews config, the dispatch surface emits a single line to stderr identifying the disagreement. Update Task 6 target list and test pin in `tests/unit/test-host-detection.bats` accordingly.
