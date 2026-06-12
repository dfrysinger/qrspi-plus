---
finding_id: R1-F04
severity: low
change_type: clarity
referenced_files: ["docs/qrspi/2026-06-04-v073-release/design.md"]
artifact: design
round: 1
reviewer: quality-claude
---

G5's prose-design block for `skills/{integrate,test}/SKILL.md § Process Steps` opens with:

  `### Step N — Orchestration boundary observability check`

"N" is an unresolved placeholder. This block will be inserted verbatim into two separate skill files (integrate/SKILL.md and test/SKILL.md), each of which has its own existing step numbering scheme. An implementer inserting the block without resolving "N" would produce literally `### Step N —` in the skill prose, which is broken. If two implementers resolve "N" independently in each skill, the numbers may diverge (e.g., integrate uses "8" and test uses "7"), creating inconsistency between the two skills' step sequences.

The design note that the step comes "before batch gate" is correct directional guidance but does not replace a resolved step number in the verbatim prose-design block.

Fix: Either (a) replace "N" with the qualifier "Step (before Batch Gate)" or a description like "Step: Orchestration Boundary Check" that is position-relative rather than numerically indexed, or (b) specify the exact step number for each target skill after consulting the current step structures of integrate/SKILL.md and test/SKILL.md, or (c) add an inline implementer note `<!-- implementer: replace N with the next available step number in this skill's sequence -->` immediately after the heading so the placeholder is explicitly signaled as requiring resolution.
