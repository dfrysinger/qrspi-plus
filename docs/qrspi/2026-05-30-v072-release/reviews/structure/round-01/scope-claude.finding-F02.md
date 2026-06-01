---
finding_id: R1-F02
severity: medium
change_type: scope
referenced_files: [docs/qrspi/2026-05-30-v072-release/structure.md:L22-L155]
artifact: structure
round: 1
reviewer: scope-claude
---

## OWNS gap — New `skills/` prose files lack section-list contracts

**What the artifact does.**  
The File Map tables (Slices 1.1–1.6) identify ten new `skills/` prose files and give each a single-sentence Responsibility description. The files in question are:

| File | Slice |
|---|---|
| `skills/reviewer-protocol/first-party-emission.md` | 1.1 |
| `skills/reviewer-protocol/third-party-emission.md` | 1.1 |
| `skills/_shared/reviewer-dispatch-prose.md` | 1.4 |
| `skills/_shared/config-validation-procedure.md` | 1.4 |
| `skills/_shared/prompt-prose-detection.md` | 1.5 |
| `skills/_shared/prompt-prose-writer-addition.md` | 1.5 |
| `skills/_shared/prompt-prose-reviewer-addition.md` | 1.5 |
| `skills/_shared/prompt-design-rules.md` | 1.5 |
| `skills/prompt-prose-writer/SKILL.md` | 1.5 |
| `skills/prompt-prose-reviewer/SKILL.md` | 1.5 |

**Why this is an OWNS gap.**  
Structure OWNS "Section-list contracts per file. Which top-level sections each file must contain (e.g., for a SKILL.md: `## Overview`, `## Process`, `## Red Flags`); which named blocks live where. Heading-level granularity, not prose content." This requirement applies to every file the project **creates** — without it, an implementer authoring these files has no structural contract to implement against.

The artifact handles this correctly for other new files: Interface §5 declares the structural skeleton of `skills/_shared/structure-altitude-boundary.md` (sections `## Structure Altitude Boundary`, `### What Structure OWNS`, `### What Structure DEFERS`), and Interface §6 does the same for `skills/_shared/design-altitude-boundary.md`. But none of the ten files listed above receive equivalent treatment.

For the two new wrapper SKILL.md files (`skills/prompt-prose-writer/SKILL.md`, `skills/prompt-prose-reviewer/SKILL.md`) the Responsibility column says "Wrapper skill that preloads detection + writer/reviewer rules" but names no required sections — which preloaded sections must appear, what the `## Overview` and `## Process` headings are called, where the shared-include blocks live.

For the shared snippet files, the same gap applies: `reviewer-dispatch-prose.md` "provides the one shared orchestrator dispatch snippet included by all review-producing skills" but the section heading that includes must reference is unspecified.

**What Structure should add.**  
For each of the ten files, an Interfaces subsection (or a brief section-list table) naming the required top-level headings and any named blocks, at the same heading-level granularity as §5 and §6. The actual prose under those headings remains deferred to Plan/Implement.
