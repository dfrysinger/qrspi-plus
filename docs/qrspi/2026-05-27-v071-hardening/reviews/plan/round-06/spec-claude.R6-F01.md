---
finding_id: R6-F01
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/plan.md]
artifact: plan
round: 6
reviewer: spec-claude
---

Task 7 "provides evidence" too vague for specific behavioral requirement

R5 fix to scope-claude R5-F02 correctly stripped test-code parenthetical but replacement is undefined. Any non-empty (or even empty) stdout could satisfy "provides evidence". G6 requires verifiable proof correct transport invoked.

Fix: "captured stdout contains a distinguishable marker string emitted by the mock transport, proving the dispatch invoked the mock path rather than falling back to a different code path; exit code 0 alone is insufficient proof."

DISPOSITION: 5th reviewer converging on this finding (testcov-claude, testcov-codex, spec-codex, silentfail-claude, spec-claude). Apply middle-ground "distinguishable marker string emitted by the mock" wording in fix synthesis.
