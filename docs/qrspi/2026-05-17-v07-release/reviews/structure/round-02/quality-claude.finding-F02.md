---
finding_id: R2-F02
severity: low
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/structure.md:L455, docs/qrspi/2026-05-17-v07-release/design.md:L594-L595]
artifact: structure
round: 2
reviewer: quality-claude
---

The Mermaid diagram (line 455) contains the arrow:

```
PlanSkill5 --> StructureSkill5
```

This arrow implies that `skills/plan/SKILL.md` dispatches to or invokes `skills/structure/SKILL.md` at runtime, but the relationship is the reverse. Design G11 states: "Structure records UI reference affordances once. Structure.md gets an optional `## UI Reference Affordances` section capturing the sibling reference repo path, the canonical lift codemod or process, the image asset pipeline, and any other shared UI infrastructure. Plan tasks reference this section instead of each re-deriving the same transformation."

Structure is the provider; Plan tasks are the consumers. The arrow direction `PlanSkill5 --> StructureSkill5` portrays Structure as a downstream product of Plan, when the intended meaning is that Structure's affordances section is a shared reference that Plan tasks read. A reader tracing call flow from this diagram would conclude that Plan causes Structure to run, which is incorrect.

The arrow should be inverted to `StructureSkill5 -.provides ref.-> PlanSkill5` (or replaced with a dotted/labeled form that signals a read dependency rather than a dispatch call), to match the actual consumer/provider relationship described in the design.
