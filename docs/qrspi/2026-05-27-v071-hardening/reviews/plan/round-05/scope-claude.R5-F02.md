---
finding_id: R5-F02
severity: advisory
change_type: scope
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/plan.md]
artifact: plan
round: 5
reviewer: scope-claude
---

Task 7 mock-sentinel parenthetical describes test-code structure

R4 fix changed "non-empty stdout" to "captured stdout matches a known mock-sentinel pattern (the mock emits a distinguishable string the test asserts against)". The parenthetical describes test code structure — what the mock does, what the assertion does. Plan should describe behavioral intent only.

Fix: "captured stdout provides evidence that the dispatch invoked the mock transport rather than falling back -- exit code 0 alone is insufficient proof"

DISPOSITION: ACCEPT — refine to drop parenthetical. The behavioral intent (prove dispatch actually invoked transport) is the legitimate Plan-OWNS surface; the sentinel mechanism is Implement-TDD's choice.
