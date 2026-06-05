---
finding_id: R1-F02
artifact: structure
severity: high
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/structure.md
  - docs/qrspi/2026-05-30-v072-release/design.md
---

## Missing component: `skills/_shared/multi-actor-flow-check.md` absent from file map

### What is missing

`skills/_shared/multi-actor-flow-check.md` is not listed as a Create action in any
slice of structure.md's file map. CD-3 (Multi-Actor Flow Check) in the approved
design.md requires creation of this shared snippet, which must be `!cat`-included into
exactly four SKILL.md consumer files:

- `skills/structure/SKILL.md`
- `skills/plan/SKILL.md`
- `skills/parallelize/SKILL.md`
- `skills/implement/SKILL.md`

CD-3 acceptance criteria include the lint check: `grep -rln "multi-actor-flow-check.md"
skills/` must return exactly 4 SKILL.md files plus the source file (5 total). That lint
check permanently fails if the file's creation is never scheduled.

### Why this is a problem

All four consumer SKILL.md files are present in the file map with Modify entries.
Their `!cat` directives will reference a file that was never created. The four checks
are a layered defense (each consumer runs the check independently per CD-3's
"Redundancy is the layered defense" contract). Without the source snippet, all four
layers silently disappear.

CD-3 is a cross-cutting design decision in the approved design.md; it is not tagged
to a specific goal ID because it resolves a pattern rather than a discrete goal.
Structure.md carries no Create entry covering it.

### Expected fix

Add a Create entry for `skills/_shared/multi-actor-flow-check.md` to Slice 1.5
(Skill prose & interactive dialog quality), alongside the four Modify entries for its
consumers. Suggested table row:

| `skills/_shared/multi-actor-flow-check.md` | Create | Hold the single Multi-Actor Flow Check snippet `!cat`-included into structure, plan, parallelize, and implement SKILL.md files. | CD-3 |

If no goal ID column is appropriate for cross-cutting design decisions, CD-3 is the
correct attribution (or a new "CD" column could be added, though aligning to the
nearest in-scope goal cluster is simpler: G9, G15, G18 all depend on plan/implement
consuming this check correctly).
