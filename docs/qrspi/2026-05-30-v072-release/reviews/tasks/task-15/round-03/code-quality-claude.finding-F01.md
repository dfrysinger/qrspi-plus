---
id: F01
reviewer: code-quality-claude
round: 3
file: tests/integration/test-reference-gate-pause.bats
line: 587
severity: moderate
change_type: correctness
status: accepted
---
test-5 regex `reject.*patterns starting with|patterns starting with` — second alternative is
unpinned and false-positive-prone; diverges from tighter G15 `"NOT start with"` precedent.
Recommend dropping the second alternative. ADJUDICATION: ACCEPTED. Consolidated finding (5 reviewers).
