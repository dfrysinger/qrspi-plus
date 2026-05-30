---
finding_id: R8-F01
severity: high
change_type: must-fix
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/plan.md]
artifact: plan
round: 8
reviewer: traceability-claude
---

Task 9 Test Expectation #3 is empirically unsatisfiable: sampled agent files contain their tier token only in the frontmatter model: line being deleted. After Task 9, those files will contain zero tier tokens — structural lint cannot reach GREEN.

Expectation also contradicts goals.md G7b Candidate A and structure.md Slice 8, both of which route tier vocabulary into dispatching skill prose (skills/using-qrspi/SKILL.md, handled by Task 10), not into each agent file's body.

The collateral-preservation property the bullet claims to verify is already covered by the new Manual Validation block (strictly stronger).

DISPOSITION: ACCEPT — Option A (delete expectation #3). Convergent with quality-claude, quality-codex, spec-claude, spec-codex, testcov-claude, traceability-codex. Resolved in R9 by removing the bullet entirely.
