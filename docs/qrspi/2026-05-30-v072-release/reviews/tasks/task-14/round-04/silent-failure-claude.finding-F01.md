---
reviewer_tag: silent-failure-claude
round: 4
finding_id: R4-F01
severity: low
change_type: correctness
referenced_files:
  - tests/integration/test-reference-gate-pause.bats
---

# F01 — `-`-prefix-rejection pin uses bare `"start"` (silent-pass risk)

Same as cq-codex R4-F02 + cq-claude R4-F02. Three-reviewer convergence on a LOW silent-failure: the new pin at L380 asserts only `"start"` which could match unrelated prose (e.g., "starting from repo root", "validation starts with"). 1-line fix: tighten to `"NOT start with"` or `"start with.*-"`.
