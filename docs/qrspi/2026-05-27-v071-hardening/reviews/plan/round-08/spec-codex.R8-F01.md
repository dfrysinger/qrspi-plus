---
finding_id: R8-F01
severity: high
change_type: scope
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/plan.md]
artifact: plan
round: 8
reviewer: spec-codex
---

Task 9 acceptance assertion is untraceable and over-constraining. Introduces a new requirement not present in G7b. Changes "don't collaterally remove prose" into "every file must contain all tier tokens". Likely false for many agent files that naturally mention only one tier in body prose.

DISPOSITION: ACCEPT. Convergent with quality-codex, traceability-codex, testcov-claude. Resolved in R9.
