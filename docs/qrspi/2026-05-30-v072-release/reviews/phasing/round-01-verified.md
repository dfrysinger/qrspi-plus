---
verifier_enabled: true
scored: 3
kept: 2
dropped: 1
failed: 0
clean: 2
---

<!-- @@FINDING: quality-claude.finding-F01 @@ -->
---
finding_id: R1-F01
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/phasing.md:L75-L82
  - docs/qrspi/2026-05-30-v072-release/phasing.md:L84-L93
  - docs/qrspi/2026-05-30-v072-release/roadmap.md:L18-L19
  - docs/qrspi/2026-05-30-v072-release/goals.md
artifact: phasing
round: 1
reviewer: quality-claude
---

## G25 is placed in slice 1.3 but belongs in slice 1.4 (dispatch-routing cluster)

**The mismatch.** `phasing.md` slice 1.3 ("Per-task review pipeline corrections") is described as covering "Implement-phase per-task review orchestration (scope-tagger firing, round-NN.diff and round-NN-commit.txt creation, dependent-test scope for sweep tasks, cross-task consumer surface in Plan)" — i.e., the per-task review-loop wiring covered by G9/G15/G18. G25 is listed as a member of this slice (`**Goals:** G9, G15, G18, G24, G25` at L77), but G25 is "Per-H4 mirror-paragraph pattern requires every future dispatch-path author to remember the fail-loud contract." G25 has nothing to do with per-task review orchestration; it is about the **top-level fail-loud invariant for the Dispatch routing section of `skills/using-qrspi/SKILL.md`** (L470/L488/L501/L526 H4s).

**Goals.md's own clustering analysis disagrees with the phasing placement.** The Cross-Cutting Notes section of `goals.md` (the pre-approved input to Phasing) explicitly groups G25 under the **dispatch-routing schema cluster**, not the per-task review cluster:

> "**Dispatch-routing schema cluster (G22 / G23 / G24-F02 / G24-F04 / G25 / G27).** These goals all touch `model_routing:` / dispatch-path in `using-qrspi/SKILL.md`: schema reconciliation (G22), validation table (G23), per-H4 prose redundancy (G24-F02) and tier-regex consolidation (G24-F04), top-level fail-loud invariant (G25), and Goals-side inline probe (G27). … The cluster shares the same H4 paragraphs as an edit surface; Phasing should evaluate whether the cluster benefits from being scheduled together."

G25's own body confirms this: "Couples tightly with G22 (model-routing schema drift) and G24 F02 (prose redundancy). All three goals touch the dispatch-routing section and share an edit surface; Phasing should evaluate whether the cluster benefits from being scheduled together to avoid churn on the same H4 paragraphs."

The phasing.md slice 1.4 ("Dispatch infrastructure") already groups G3, G4, G16, G22, G23, G27 — i.e., five of the six goals goals.md identifies in the dispatch-routing cluster. G25 is the missing sixth member; placing it in slice 1.3 instead of 1.4 leaves the H4-edit-surface co-scheduling concern goals.md explicitly raised unresolved.

**Why this matters for downstream phases.** Slices are the unit Plan and Parallelize consume to decide what work can land in the same wave / on the same branch. Splitting the dispatch-routing edit surface across two slices (G22/G23/G27 in 1.4, G25 in 1.3) means Plan can't see at a glance that all five goals churn the same H4 paragraphs in `using-qrspi/SKILL.md`. The "shared edit surface" argument goals.md asked Phasing to evaluate gets buried.

**Suggested fix.** Move G25 from slice 1.3 to slice 1.4. Update both `phasing.md` § Slices (1.3 Goals line and 1.4 Goals line) and `roadmap.md`'s Phase 1 table rows accordingly. The slice 1.4 surface description already mentions "validation table cross-linking" (G23-shaped); add a phrase covering the top-level fail-loud invariant so G25 is visibly home.
<!-- @@SCORE: quality-claude.finding-F01.score @@ -->
score: 70
reason: Verified — goals.md Cross-Cutting Notes explicitly clusters G25 with the dispatch-routing cluster (G22/G23/G24-F02/G24-F04/G25/G27) and G25's body says "Phasing should evaluate whether the cluster benefits from being scheduled together"; slice 1.4 already groups 5 of 6 dispatch-cluster members while slice 1.3's "per-task review orchestration" surface description has no overlap with G25's fail-loud-invariant subject, so the placement contradicts the upstream clustering input Phasing was told to evaluate.
<!-- @@FINDING: quality-claude.finding-F02 @@ -->
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
<!-- @@SCORE: quality-claude.finding-F02.score @@ -->
score: 72
reason: Verified — goals.md Cross-Cutting Notes explicitly clusters G24-F02/F04 with the dispatch-routing cluster (slice 1.4 surface) and G24-F05 with the test-gate hardening cluster (slice 1.7 surface); phasing.md placing G24 wholesale in slice 1.3 ("per-task review pipeline corrections," which maps to zero G24 sub-findings) contradicts that explicit guidance and would mis-shape Plan's task carving.
<!-- @@FINDING: scope-codex.finding-F01 @@ -->
---
finding_id: R1-F01
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/phasing.md:L72-L83
  - docs/qrspi/2026-05-30-v072-release/phasing.md:L131-L163
  - skills/phasing/owns-defers.md:L15-L18
artifact: phasing
round: 1
reviewer: scope-codex
---

`phasing.md` crosses the Phasing boundary by specifying deferred implementation/task-level content (explicit file paths/config keys and procedural test/task specs), e.g. `round-NN.diff`, `run-codex-review.sh`, `scripts/build-plugin.sh`, `~/.copilot/...`, and stepwise trap-testing instructions in the phase gate. Per OWNS/DEFERS, Phasing should stay at slice/phase grouping with replan gates, and defer file/module/task/implementation details to Structure/Plan/Implement. Fix by rewriting these sections to phase-level outcomes and acceptance criteria without naming concrete files/scripts or task-procedure details.
<!-- @@SCORE: scope-codex.finding-F01.score @@ -->
score: 55
reason: Real boundary drift — phasing.md explicitly names files/scripts (`run-codex-review.sh`, `scripts/build-plugin.sh`, `round-NN.diff`, `~/.copilot/...`) and gives Plan-level procedural test specs in the gate, which DEFERS lists assign to Structure/Plan; but acceptance gates legitimately need some concrete handles so the fix is partial/debatable rather than clearly load-bearing.
<!-- @@CLEAN: quality-codex.clean @@ -->
---
reviewer: quality-codex
artifact: phasing
round: 1
result: clean
---

Codex quality reviewer (gpt-5.3-codex) emitted `NO_FINDINGS` for round 01.
<!-- @@CLEAN: scope-claude.clean @@ -->
---
reviewer: scope-claude
round: 1
findings: 0
---
