---
finding_id: R6-F01
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/plan.md]
artifact: plan
round: 6
reviewer: testcov-claude
---

Task 7 mock-sentinel expectations weakened to unfalsifiable "provides evidence"

R5 fix to address scope-claude R5-F02 (test-code structure parenthetical) over-corrected. New wording: "captured stdout provides evidence that the dispatch invoked the mock transport rather than falling back; exit code 0 alone is insufficient proof." This is unfalsifiable — names no string, no pattern, no assertion.

Note this directly contradicts scope-claude R5-F02 disposition. There's a tension between:
- scope-claude: parenthetical describes test-code structure (Implement-TDD layer)
- testcov-claude: behavioral expectation needs to be specific enough to be deterministic

DISPOSITION: ACCEPT with middle-ground wording. State the behavioral content requirement (stdout contains a distinguishable marker emitted by the mock) without prescribing the assertion mechanism. Suggested:
"captured stdout contains a distinguishable marker string emitted by the mock transport, proving the dispatch invoked the mock path rather than falling back; exit code 0 alone is insufficient proof."

This names the behavior (mock emits distinguishable marker, stdout contains it) without specifying assertion code or sentinel value. Should satisfy both scope and testcov.
