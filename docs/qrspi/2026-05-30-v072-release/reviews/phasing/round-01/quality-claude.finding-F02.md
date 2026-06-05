---
finding_id: R1-F02
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/phasing.md:L75-L82
  - docs/qrspi/2026-05-30-v072-release/phasing.md:L84-L93
  - docs/qrspi/2026-05-30-v072-release/phasing.md:L116-L123
  - docs/qrspi/2026-05-30-v072-release/roadmap.md:L18-L19
  - docs/qrspi/2026-05-30-v072-release/roadmap.md:L24
  - docs/qrspi/2026-05-30-v072-release/goals.md
artifact: phasing
round: 1
reviewer: quality-claude
---

## G24 is placed wholesale in slice 1.3 but its sub-findings (F01–F05) split across slices 1.4 and 1.7 per goals.md's own clustering

**The mismatch.** `phasing.md` slice 1.3 ("Per-task review pipeline corrections") at L77 lists G24 as a member alongside G9/G15/G18 (per-task review-loop wiring). G24 is "R4 simplify-claude advisories: 5 deferred code-quality simplifications" — a bundle of five distinct simplification findings (F01–F05) covering bats test parameterization, SKILL.md H4 prose consolidation, test-helper deduplication, tier-regex consolidation, and anti-pattern pin regex hardening. **None of G24's five sub-findings touch per-task review orchestration**; the slice 1.3 theme (scope-tagger firing, round-NN.diff, dependent-test scope for sweep tasks, cross-task consumer surface) maps to zero F-items in G24.

**Goals.md's Cross-Cutting Notes explicitly splits G24 across two non-1.3 clusters:**

> "**Dispatch-routing schema cluster (G22 / G23 / **G24-F02** / **G24-F04** / G25 / G27)** … per-H4 prose redundancy (G24-F02) and tier-regex consolidation (G24-F04) … The cluster shares the same H4 paragraphs as an edit surface."

> "**Test-gate hardening cluster (G21 / **G24-F05** / G26)** … silent-pass `[[ ]]` form (G21), literal anti-pattern pin fragility (G24-F05), and deprecated shebang noise (G26). All three are small, mechanical, and share a 'add a lint rule to prevent recurrence' extension candidate — a single 'test-pin hardening' wave covers all three."

G24's own body also cross-links its sub-items to other goals: F02 "Couples with G25" (dispatch-routing); F04 cross-links G22 (dispatch-routing); F05 cross-links G21 (test-gate hardening). F01 (parameterize `_assert_host_block_has_routing` across 4 bats files) and F03 (consolidate `_extract_h4` / `_extract_routing_block` into `test_helpers/extract.bash`) are bats-test refactors that share the test-infrastructure surface with slice 1.7's G21/G26 work, not the per-task review-loop surface of slice 1.3.

**Why the current placement matters for downstream phases.** Plan will read this slice grouping when carving tasks. With G24 placed in 1.3, Plan sees five goals in slice 1.3 (G9/G15/G18/G24/G25) and is invited to author tasks that touch per-task review wiring alongside bats helper refactors and using-qrspi H4 prose — three unrelated edit surfaces co-mingled in one slice. Meanwhile slice 1.4 (where G24-F02/F04 belong by edit-surface) is missing the H4-prose-consolidation work that pairs naturally with G22/G23/G25/G27, and slice 1.7 (where G24-F05 belongs) is missing the bats anti-pattern pin hardening that pairs naturally with G21/G26. The "single test-pin hardening wave" goals.md recommended for G21/G24-F05/G26 is not visible in the current slice layout.

**Suggested fix.** Two options:

1. **Split G24 across slices** matching goals.md's cluster analysis: F02/F04 → 1.4 (dispatch infrastructure), F05 → 1.7 (build & release tooling, alongside G21/G26), F01/F03 → 1.7 (bats-test infrastructure). Note this is precedented inside the release: the slice membership row would list "G24 (F02, F04)" and "G24 (F01, F03, F05)" the way the Cross-Cutting Notes do.

2. **Move G24 as a whole to slice 1.7** ("Build & release tooling"). This is the closest single-slice fit because four of G24's five sub-items (F01/F03/F05 + the part of F04 that's a bats-shared regex constant) touch the test-infrastructure surface; only F02 is purely SKILL.md prose. Less faithful to goals.md's split than option 1, but simpler.

Either fix also requires the same edit in `roadmap.md`'s Phase 1 table (row "1.3" remove G24; row "1.4" and/or "1.7" add the appropriate G24 sub-items). The goal-count footer (`7 + 4 + 5 + 6 + 9 + 1 + 3 = 35`) will need to update with the new slice totals.
