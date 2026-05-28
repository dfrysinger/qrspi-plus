---
finding_id: R8-F01
severity: high
change_type: correctness
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/plan.md]
artifact: plan
round: 8
reviewer: quality-codex
---

Task 9 test expectation over-constrained: forcing each file to contain all three tokens haiku/sonnet/opus is not derived from G7b and misreads design intent. Goals require preserving tier vocabulary where it EXISTS, not forcing every file to mention all three. Most agent files declare exactly one tier (33 sonnet, 5 inherit, 1 opus, 2 haiku).

DISPOSITION: ACCEPT. Convergent finding with traceability-codex, testcov-claude, spec-codex. Resolved in R9 by removing the over-constrained bullet entirely; structural lint covers no-model invariant, Manual Validation block covers no-collateral-changes invariant via git diff --stat.
