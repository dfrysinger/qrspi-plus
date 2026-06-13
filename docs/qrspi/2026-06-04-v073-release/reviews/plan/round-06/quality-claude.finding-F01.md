---
finding_id: R6-F01
severity: high
change_type: correctness
referenced_files:
  - docs/qrspi/2026-06-04-v073-release/plan.md:L1185-L1188
artifact: plan
round: 6
reviewer: quality-claude
---

T26's `dependent_tests:` field lists three test file paths with errors:
1. `tests/integration/test-cross-skill-contracts.bats` — file lives at `tests/unit/test-cross-skill-contracts.bats`.
2. `tests/acceptance/test-convergence-narrowing.bats` — file lives at `tests/unit/test-convergence-narrowing.bats`.
3. `tests/unit/test-narrow-round-anchor-lookup.bats` — does not exist (created by T27).

Disposition for entry 1 references "the eight files T05 modifies" but T26 modifies 14 skill files, not T05's diff-redirect prose set.

Fix: correct directory prefixes to `tests/unit/`; fix disposition text; replace T27 entry with `none` + `grep -rn -- '<pattern>' tests/` proof OR hold until T27 ships. Contract: `skills/plan/SKILL.md` § Sweep Task Contract.

