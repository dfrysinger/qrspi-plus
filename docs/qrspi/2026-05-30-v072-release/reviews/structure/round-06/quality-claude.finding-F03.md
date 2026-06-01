---
finding_id: R6-F03
reviewer_tag: quality-claude
artifact: structure
severity: low
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/structure.md
  - docs/qrspi/2026-05-30-v072-release/design.md
---

# CD-2 `using-qrspi/SKILL.md` by-reference pointer is unmapped

## What

`design.md` CD-2 § Acceptance criteria item #5:

> Documentation: the cross-skill rule appears in `using-qrspi/SKILL.md`'s artifact-quality section by reference (one-line pointer to `_shared/evergreen-output-rule.md`), not by copy.

This deliverable is not represented in `structure.md`:

- The two `skills/using-qrspi/SKILL.md` rows in the File Map (Slice 1.2 and Slice 1.4) carry goal IDs `G20, G28, G29, CD-4` and `G3, G22, G23, G24, G25, G27` respectively — neither lists `CD-2`, and neither Responsibility cell mentions the artifact-quality-section pointer.
- The Hook-Point Locations § "CD-2 evergreen-output-rule `!cat` include sites" table lists exactly the 9 `!cat` consumer skills (goals, questions, research, design, structure, phasing, plan, parallelize, replan). `using-qrspi/SKILL.md` is correctly **not** in that list (the design specifies a by-reference pointer, not a `!cat` include) — but the by-reference pointer itself has no representation in any other table either.

The result is that the pointer's location and content are unspecified at structure altitude even though design explicitly requires it.

## Why it matters (structure-quality dimension: no-missing-components)

This is a low-severity gap relative to F02 — the deliverable is one line of prose rather than a full reviewer mechanism — but it is still an unmapped acceptance criterion. The structural risk is that Plan won't author a task for it (no file row → no task surface) and Implement will ship CD-2 without the pointer, leaving `using-qrspi/SKILL.md` readers (the orchestrator audience) without a discoverable path to the Evergreen-Output Rule from the artifact-quality section they actually consult.

This is also the same shape as F02: design CD-2 enumerates a small handful of deliverables (snippet, 9 includes, reviewer enforcement, using-qrspi pointer); structure.md covers two of the four. Both gaps are "the rule is created and propagated to its writer-side homes but the discoverability and enforcement surfaces are missing."

## Suggested fix

Either:

**(a) Add a Hook-Point row** under a new sub-section "CD-2 by-reference pointer site" naming the consumer file and the section heading where the one-line pointer lands:

```markdown
### CD-2 by-reference pointer site

`using-qrspi/SKILL.md`'s artifact-quality section gains a one-line pointer to
`_shared/evergreen-output-rule.md` (not a `!cat`-include — by-reference only).

| Consumer file | Section heading |
|---|---|
| `skills/using-qrspi/SKILL.md` | artifact-quality section |
```

**(b) Add `CD-2` to the goal IDs** of one of the existing `skills/using-qrspi/SKILL.md` rows (Slice 1.4 is the more natural home given its scale) and extend the Responsibility text with "; add one-line by-reference pointer to `_shared/evergreen-output-rule.md` from the artifact-quality section per CD-2 acceptance #5."

Option (a) is more discoverable for Plan because it sits next to the other CD-2 hook-point sites. Option (b) is lower-touch. Either closes the gap.
