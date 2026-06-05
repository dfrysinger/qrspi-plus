---
finding_id: R2-F01
reviewer: silent-failure-claude
task: 29
round: 2
severity: high
change_type: correctness
referenced_files:
  - tests/lint/test-design-altitude-boundary-include.bats
  - skills/_shared/design-altitude-boundary.md
---

# F01 — HIGH — Lint passes silently when the single source of truth is deleted, emptied, or gutted

The lint asserts directive presence in the **consumers** but never asserts anything about the include target itself (`skills/_shared/design-altitude-boundary.md`). If a future edit deletes, renames, empties, polarity-inverts (DEFERS↔OWNS), or paraphrases the source, all four bats tests still pass and the boundary contract has silently collapsed. This directly undermines the task's "single source of truth makes drift structurally impossible" thesis.

**Recommended fix:** add tests against `skills/_shared/design-altitude-boundary.md`:
1. file exists and is non-empty
2. body contains `Design OWNS:` preceding `Design DEFERS:` (line-order check)
3. canonical OWNS allowance + DEFERS exclusion anchors are present (e.g., `Per-goal outcome statements`, `Per-solution diagrams`, `Function bodies`, `File architecture`, `Task carving`).
