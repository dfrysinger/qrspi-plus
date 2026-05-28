---
finding_id: R1-F01
severity: high
change_type: scope
referenced_files: [docs/qrspi/2026-05-17-v07-release/design.md:L620-L620, docs/qrspi/2026-05-17-v07-release/design.md:L829-L833, docs/qrspi/2026-05-17-v07-release/design.md:L914-L932]
artifact: design
round: 1
reviewer: scope-claude
---

design.md authors phase boundaries, wave assignments, and goal-to-phase ordering in multiple places. Per `skills/design/owns-defers.md`, "Phase boundaries and replan gates" and "roadmap.md (goal-to-phase assignment table)" — including vertical slice authoring and Iron Law 1 — are explicitly DEFERRED to `qrspi:phasing` and `roadmap.md`. Design owns approach, trade-offs, key architectural decisions, design-level test strategy, and the high-level system diagram. It does NOT own which-goal-lands-in-which-wave/phase decisions.

Concrete boundary-drift sites:

1. G14 "Sequencing — G14 lands early" (L620): "Phasing should put G14 in the first wave that contains any of those tests."
2. G18 "Sequencing — co-ship with G7 and depend on G14 and G17" (L829-L833): "Land them together as a sibling pair... G14's BATS helper lands earlier so G18's BATS pin uses the helper... G17's CI workflow must exist so G18's BATS pin has a place to run automatically. Sequencing: G14 → (G7 + G18 + G17) co-ship."
3. "Decision 7: G14 lands early in the implementation order" (L914-L925): Names six other goals (G7, G8, G9, G12, G15, G18) and asserts "Phasing should put G14 in the first wave that contains any of these tests." This is a wave-assignment directive.
4. "Decision 8: G16 deferred. G17 and G18 ship together" (L927-L931): "G18 has nowhere to run automatically until G17 ships, so they must land in the same release. Phasing should keep them in the same phase." Goal-to-phase assignment.
5. "Decision 1: G1, G2, and G5 are one routing system in three layers" (L872): "Implementation order should be G1 then G2 then G5." Wave-ordering directive.

Each of these statements binds Phasing's hands on wave composition and ordering. The dependency facts themselves (G18 needs G17's CI to exist; G18's BATS pin can reuse G14's helper; G5 needs G1's schema; G2 calls what G1 declares) are legitimate Design content — they belong in trade-offs and key architectural decisions as **dependency facts**. The boundary-drift is the prescriptive "Phasing should..." / "must land in the same release" / "Implementation order should be..." framing that authors the phase split.

Recommended fix: rewrite each "Sequencing" subsection and the "lands early" / "ship together" / "Implementation order should be" decision prose as **dependency declarations** without phase prescriptions. For example, replace "Phasing should put G14 in the first wave that contains any of these tests" with "G14 produces a BATS helper consumed by G7, G8, G9, G12, G15, G18 BATS pins; consumers cannot pass their BATS pins until the helper exists." That's a dependency fact Phasing/roadmap.md will consume. The same rewrite applies to G18's sequencing block and the affected Decision entries.
