---
finding_id: R6-SA-F02
reviewer_tag: stitching-audit
artifact: structure
severity: medium
change_type: clarity
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/structure.md
  - docs/qrspi/2026-05-30-v072-release/design.md
---

# Missing Hook-Point G31 section — direct `!cat` include sites for `prompt-prose-detection.md` and `prompt-prose-writer-addition.md` in `skills/plan/SKILL.md` not locked

## What

Structure.md § Hook-Point Locations documents six cross-cutting `!cat` insertion surfaces: CD-1 (reviewer-dispatch-prose), CD-2 (evergreen-output-rule), CD-3 (multi-actor-flow-check), CD-4 (verifier-dispatch-prose), G34 (design-altitude-boundary), and G35 (structure-altitude-boundary). G31 requires two additional direct-`!cat` insertion surfaces in SKILL.md files; neither is listed in § Hook-Point Locations.

Design.md G31 § consumers specifies two groups of direct `!cat` inserts in SKILL.md files (distinct from the `skills:` frontmatter preloads that go in agent files):

- **Consumer #2 — `skills/plan/SKILL.md`**, writer-subagent dispatch payloads (2 sites): `!cat skills/_shared/prompt-prose-detection.md` + `!cat skills/_shared/prompt-prose-writer-addition.md` + Addition B verbatim.
- **Consumer #3 — `skills/design/SKILL.md`**, authoring step (1 site): `!cat skills/_shared/prompt-prose-detection.md` + `!cat skills/_shared/prompt-prose-writer-addition.md`.

Neither consumer is listed in § Hook-Point Locations. There is no "### G31 prompt-prose-writer `!cat` include sites" subsection.

Note: Consumer #3's file-map row gap is the subject of R6-SA-F01 (design/SKILL.md missing G31 entirely). This finding focuses specifically on the Hook-Point locking gap for Consumer #2 (`skills/plan/SKILL.md`), where the file map row IS present with G31 (Slice 1.5) but the specific `!cat` site locations are not locked in the Hook-Point section.

## Why it matters

The Hook-Point Locations section exists precisely to lock `!cat` insertion sites so Plan task authors for consumer files don't have to re-derive them from design.md. The pattern is consistent for every other shared snippet that uses direct `!cat` in SKILL.md files (G34, G35, CD-1 through CD-4 all have explicit Hook-Point subsections). G31's direct-`!cat` surfaces in SKILL.md files are the same kind of insertion contract but are left unlocked at the structure layer:

1. **`skills/plan/SKILL.md` — Consumer #2 (2 sites).** The Slice 1.5 row confirms G31 is assigned, but a Plan task author must navigate to design.md G31 § Consumer #2 to locate the specific insertion points (writer-subagent dispatch payload locations + Addition B). Without a Hook-Point entry, structure.md is not the authoritative single-source for `!cat` site locations that its own section header claims.

2. **`skills/design/SKILL.md` — Consumer #3 (1 site).** Compounded by the file-map gap in R6-SA-F01 (no G31 in design/SKILL.md's row), this site is doubly invisible at structure altitude.

The test `tests/unit/test-author-skill-uses-cat.bats` (Slice 1.5, G31, G34) would catch the *absence* of `!cat` includes post-implementation — but that is a downstream safety net, not a substitute for the planning guidance the Hook-Point section is supposed to provide.

## Suggested fix

Add a Hook-Point G31 subsection to § Hook-Point Locations, modeled after the G34 and G35 subsections:

```markdown
### G31 prompt-prose-writer `!cat` include sites

`skills/_shared/prompt-prose-detection.md` + `skills/_shared/prompt-prose-writer-addition.md`
are `!cat`-included directly into SKILL.md consumer files (per design.md G31 Consumers #2–#3).
This is distinct from the `skills:` frontmatter preload used in agent files.

| Consumer file | Section / location |
|---|---|
| `skills/plan/SKILL.md` | writer-subagent dispatch payloads (2 sites): each site carries `!cat skills/_shared/prompt-prose-detection.md` + `!cat skills/_shared/prompt-prose-writer-addition.md` + Addition B verbatim (per design.md G31 Consumer #2) |
| `skills/design/SKILL.md` | authoring step: `!cat skills/_shared/prompt-prose-detection.md` + `!cat skills/_shared/prompt-prose-writer-addition.md` (per design.md G31 Consumer #3) |
```

This entry also closes the coupling to the R6-SA-F01 fix: once design/SKILL.md's row gains G31, the Hook-Point section provides the concrete site location, matching the structure of every other shared-snippet hook-point in the artifact.
