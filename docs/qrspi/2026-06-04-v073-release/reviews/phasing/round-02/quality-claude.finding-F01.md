---
artifact: phasing
reviewer: quality-claude
finding_id: quality-claude-F01
change_type: correctness
severity: low
referenced_files: [docs/qrspi/2026-06-04-v073-release/phasing.md:L22, docs/qrspi/2026-06-04-v073-release/goals.md:L208-L211]
round: 2
---

## Finding: "Intra-slice sequencing constraints" bullet drops one of the three sequencing constraints from goals.md § Cross-Cutting Notes

The new Phase 1 bullet (introduced this round to address round-01 quality-claude F01) carries forward sequencing constraints from `goals.md`:

> **Intra-slice sequencing constraints (carried from `goals.md` § Cross-Cutting Notes).** G9's skill-body trim must land after G1–G7's correctness work settles (merge-churn avoidance). G6 and G7 are designed and implemented as a paired unit (shared round-mechanics surface). Wave ordering for these constraints is owned by Plan; Phasing surfaces them here so the constraint travels with the slice into Plan-step authoring.

`goals.md` § Cross-Cutting Notes (L208–L211) contains **three** sequencing-shaped constraints:

1. **G1 → G2 prerequisite chain** — "G2's sweep cannot be enforced until G1's verifier rubric is correct; otherwise reviewers re-flag and the verifier re-suppresses indefinitely."
2. **G6 / G7 share round-mechanics surface** — carried ✓
3. **G9 lands last** — carried ✓

(The fourth note, "G8 is independent," is a *non-*constraint and reasonably omitted.)

The G1→G2 prerequisite is the strongest of the three (hard ordering: G1 must land *before* any G2 sweep finding can survive the verifier), yet it is the one the new bullet drops. Plan's wave-ordering decision needs all three to author wave dependencies correctly. The bullet's own rationale — "Phasing surfaces them here so the constraint travels with the slice into Plan-step authoring" — applies identically to G1→G2.

### Required fix

Add a third clause to the bullet covering the G1→G2 prerequisite. Suggested wording:

> G1 (verifier rubric correctness) must land before G2's `[Tnn]` sweep, otherwise the verifier suppresses sweep findings (per goals.md § Cross-Cutting Notes "G1 → G2 prerequisite chain").

Insert before the existing "G9's skill-body trim..." sentence (chronological ordering — G1→G2 fires earliest in the wave plan).
