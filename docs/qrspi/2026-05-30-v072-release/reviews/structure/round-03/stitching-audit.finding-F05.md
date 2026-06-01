---
finding_id: R3-F05
reviewer_tag: stitching-audit
severity: medium
change_type: correctness
gap_class: missing-wiring
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/structure.md
  - docs/qrspi/2026-05-30-v072-release/design.md
line_range: [57, 97]
---

# `_shared/codex/launch-await-pattern.md` vendor-neutrality rename missing from file map

## Gap description

Design.md CD-1 "Rename inventory" (line 201) specifies:

> `_shared/codex/launch-await-pattern.md` → `_shared/third-party/launch-await-pattern.md`

This rename is part of the vendor-neutrality wave that removes the `codex/` namespace from
shared snippets (the same wave also renames `_shared/codex/` dispatcher files to
`_shared/third-party/`). The rename is co-shipped with CD-1.

Structure.md Slice 1.4 (lines 57–97) is the slice that carries the vendor-neutrality rename
rows for the `codex/` → `third-party/` migration (consistent with the CD-1 File Map
description on structure.md lines 57–60). Slice 1.4 contains 37 file rows, none of which is
a Rename row for `skills/_shared/codex/launch-await-pattern.md`.

## Compound gap: G32 also touches this file

The file is referenced twice more in design.md in G32 context:

- Line 2724: "update `skills/_shared/codex/launch-await-pattern.md` line 45 — change the
  `<!-- Embedded via: ... -->` comment to the bare-relative convention."
- Line 2791/2841: "The 2 existing legacy sites (`goals/SKILL.md:8` directive +
  `_shared/codex/launch-await-pattern.md:45` comment) are converted to the bare form as a
  co-shipped cleanup before G32 ships."

G32 requires a content edit to the file AND the CD-1 rename renames the file. Structure.md
should have:
1. A **Rename** row in Slice 1.4: `skills/_shared/codex/launch-await-pattern.md` →
   `skills/_shared/third-party/launch-await-pattern.md`
2. A **Modify** row (possibly in Slice 1.4 or Slice 1.5 alongside the G32 build pipeline
   rows) to update line 45's comment from the Claude-coupled form to the bare-relative form.

Neither row is present.

## Downstream impact

Without the rename row:
- The G32 content-edit row (if added) would target the old path, causing implementers to
  try to edit a file that has not been renamed.
- Any `!cat`-include or `source` reference to the old path (`skills/_shared/codex/launch-await-pattern.md`)
  will be a stale reference post-rename; consumers need to be updated. Without a rename row
  in the structure, the implementer has no signal to audit consumers.

Design.md G32 line 2841 states this as a G32 acceptance criterion:
> "Repo-wide grep for `${CLAUDE_SKILL_DIR}` returns zero hits in shipped files."

This criterion requires the rename + content edit to have been performed. With no file map
row, this criterion will be unmeetable.

## Minimal-altitude fix

Add two rows to Slice 1.4:

```
| `skills/_shared/codex/launch-await-pattern.md` | Rename →
  `skills/_shared/third-party/launch-await-pattern.md` | Vendor-neutrality rename per
  CD-1 rename inventory. | G3 |
```

And add a Modify row in Slice 1.4 or Slice 1.5:

```
| `skills/_shared/third-party/launch-await-pattern.md` | Modify | Update line 45 comment
  from Claude-coupled `${CLAUDE_SKILL_DIR}` form to bare-relative form per G32 co-shipped
  cleanup. | G32 |
```
