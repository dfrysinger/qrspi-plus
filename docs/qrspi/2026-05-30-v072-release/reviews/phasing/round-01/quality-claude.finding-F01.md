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
