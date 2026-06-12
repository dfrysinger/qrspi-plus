---
verifier_status: passed
score: 20
actual_model: unknown
defect_class: altitude-mismatch
---

Finding claims design.md lacks a consolidated Test Strategy section naming unit/integration/contract/e2e vocabulary. Design artifact does scatter acceptance bullets citing bats tests per cross-decision (e.g. CD-1, CD-2 acceptance lines reference bats fixtures), and the QRSPI design step does not mandate a consolidated test-strategy section with that specific vocabulary — test detail lives at Plan altitude. The finding is a low-severity style suggestion not grounded in a design-step requirement; it reads as altitude mismatch (Plan-level detail flagged at Design). Low confidence it represents a real defect.
