---
finding_id: R1-F01
artifact: structure
severity: high
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/structure.md
  - docs/qrspi/2026-05-30-v072-release/design.md
---

## Missing component: `skills/_shared/evergreen-output-rule.md` absent from file map

### What is missing

`skills/_shared/evergreen-output-rule.md` is not listed as a Create action in any slice
of structure.md's file map. CD-2 in the approved design.md explicitly requires creation
of this file as the single source of truth for the Evergreen-Output Rule. Nine consumer
SKILL.md files are specified to `!cat`-include it:

- `skills/goals/SKILL.md`
- `skills/questions/SKILL.md`
- `skills/research/SKILL.md`
- `skills/design/SKILL.md`
- `skills/structure/SKILL.md`
- `skills/phasing/SKILL.md`
- `skills/plan/SKILL.md`
- `skills/parallelize/SKILL.md`
- `skills/replan/SKILL.md`

### Why this is a problem

Without a file-map entry for this snippet, Plan phase has no task to create it.
The nine consumer skills are all present in the file map with "Modify" entries, but
their `!cat` includes will point to a file that was never created. All nine consumers
depend on a single shared file that structure.md is silent about.

CD-2's acceptance criteria include a lint check (`grep -rln "evergreen-output-rule.md"
skills/` returns 9 hits) — that check will always fail if the file's creation is never
scheduled. This is also a YAGNI-inverse violation: nine file-map entries describe a
dependency on a component that has no corresponding Create entry.

### Expected fix

Add a Create entry for `skills/_shared/evergreen-output-rule.md` to Slice 1.5 (Skill
prose & interactive dialog quality) with goal IDs covering CD-2's consumer set. CD-2
spans all 9 artifact-producing skills, which are exactly the files Slice 1.5 touches.
Suggested table row:

| `skills/_shared/evergreen-output-rule.md` | Create | Hold the single Evergreen-Output Rule snippet consumed by all nine artifact-producing skills via `!cat`. | CD-2 |
