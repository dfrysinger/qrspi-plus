---
finding_id: R1-F04
severity: low
change_type: clarity
referenced_files: [docs/qrspi/2026-05-17-v07-release/goals.md:L309-L316]
artifact: goals
round: 1
reviewer: quality-claude
---

The Cross-Cutting Notes section enumerates groupings for G1+G2+G5, G3+G4, G7+G8, G9+G10, and G11+G12+G13+G17 — but G5, G6, G14, G15, and G16 are not surfaced in any grouping. G5 does appear in the first bullet as part of the cost-opt routing trio, but G6 (fix-cycle ID hygiene), G14 (Replan↔Goals coordination), G15 (wave nesting), and G16 (CI) are entirely omitted from cross-cutting framing.

Two consequences: (a) a Design reader skimming Cross-Cutting Notes to understand inter-goal coupling will infer that the unlisted goals are standalone, which is true for some (G14, G16) but may be incomplete for others (G6 ID-hygiene relates to G17 evergreen-prose enforcement — both are runtime-prose hygiene problems with a shared lint-or-CI-gate solution shape; G15 wave nesting depends on G8 vocabulary cleanup, which the G15 body itself acknowledges by referencing F-22); and (b) the asymmetric coverage gives the impression that absence-of-mention is meaningful when in fact it appears to be incomplete enumeration.

Two reasonable resolutions: (a) add a final cross-cutting bullet noting which goals are intentionally standalone (G6, G14, G16) and update the G11/G12/G13/G17 bullet to call out G6 as related runtime-prose hygiene; or (b) add a one-line note that the section is a partial map covering the strongest couplings, not an exhaustive enumeration. Either makes the asymmetry explicit so readers do not over-read it.

This is clarity, not correctness — nothing in Cross-Cutting Notes is factually wrong; the gap is in what a reader is likely to infer from omission.
