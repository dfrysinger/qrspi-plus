---
finding_id: R2-F01
severity: medium
change_type: scope
referenced_files: [docs/qrspi/2026-05-17-v07-release/goals.md:L9]
artifact: goals
round: 2
reviewer: scope-claude
---

The Purpose section makes a phasing decision that belongs to the Phasing skill, not Goals. Per `skills/goals/owns-defers.md`, "Phasing decisions, vertical slice authoring, roadmap → Phasing" — Goals does not assign goals to phases.

The drift sits in the second and third sentences of `## Purpose` (goals.md L9):

1. "v0.7 is a multi-surface release across four tiers: cost+context optimization, prompt-bug fixes, interface and process improvements, and evergreen-prose enforcement." — Naming the four tiers (P1/P2/P3/P4 implicit) is a release-shape commitment that Phasing should own. Goals can state purpose and constraints; it should not pre-commit a tier structure.

2. "P1 contains six cost and context goals — a routing policy, a shared dispatch mechanism, the Plan post-approval split, context optimization for repeated reads, a dispatcher tolerance research surface, and a separate investigation of whether Implement should split test-writing into its own subagent." — This explicitly enumerates phase membership (G1, G2, G3, G4, G5, G6 are assigned to P1). That is the central decision Phasing makes; Goals owning it here pre-empts Phasing.

The Cross-Cutting Notes section already captures the substantive goal-to-goal relationships (cost-opt trio = G1/G2/G5; G6 adjacency; G3/G4 cost+context leaves; G8/G9 reviewer false-positive pair; G10/G11 Keeplii lessons; G12/G13/G14/G18 process-quality hardening; G7/G15/G17 standalone). That bullet-list grouping is legitimately Goals-owned (it documents which goals cross-cut), and it does not depend on the Purpose sentence's tier-and-P1 framing.

Suggested fix: drop the tier enumeration and the "P1 contains six cost and context goals…" sentence from Purpose. A purpose paragraph like "v0.7 is a multi-surface release covering cost+context optimization, prompt-bug fixes, interface and process improvements, and evergreen-prose enforcement. The release frames the next set of risks and opportunities after v0.6 without committing the design to any single implementation path." preserves the framing of the surface areas while letting Phasing decide the phase count and per-phase membership. The Cross-Cutting Notes section can stand unchanged because it does not assign phase numbers.

This is `scope` (not `intent`) because the OWNS/DEFERS rule itself is the locked authority being crossed; there is no captured user decision in `feedback/*.md` directing Goals to pre-assign phases.
