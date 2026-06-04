---
reviewer_tag: code-quality-claude
round: 3
finding_id: R3-F01
severity: low
change_type: style
status: dismissed-following-convention
referenced_files:
  - tests/integration/test-reference-gate-pause.bats
---

# F01 — ID Hygiene: [G15-sweep] tokens in test names (DISMISSED-following-convention)

**Reviewer finding:** Test names introduced in R1/R3 carry `[G15-sweep]` prefix; G15 is a QRSPI goal ID and ID-hygiene rule forbids G-prefixed tokens in test names outside `docs/qrspi/`.

**Dismissal rationale:** Identical finding raised by cq-codex at R2 and DISMISSED-following-convention. Investigation confirmed 315 such tokens exist across 23 pre-existing test files (e.g., `[T30-rg-pause]`, `[T19-shape]`, `[T4-shape]`). T14 followed established convention; resolving in T14 would create inconsistency with the rest of the corpus.

Backlog target: v0.7.3 sweep-task to migrate all 23 files at once. Tracked in session SQL backlog table.

No runtime impact; organizational convention issue only.
