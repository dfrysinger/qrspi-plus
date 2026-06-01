---
finding_id: R3-F04
reviewer_tag: stitching-audit
severity: medium
change_type: correctness
gap_class: missing-wiring
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/structure.md
  - docs/qrspi/2026-05-30-v072-release/design.md
line_range: [20, 50]
---

# `verifier-dispatch-prose.md` consumer SKILL.md Modify rows missing `!cat` include wiring

## Gap description

`skills/_shared/verifier-dispatch-prose.md` is created in Slice 1.1 (structure.md line 20)
with the explicit purpose:

> "Hold the shared verifier dispatch prose snippet … consumed by `using-qrspi/SKILL.md`
> and `implement/SKILL.md`."

The Hook-Point Locations section (structure.md lines 689–696) specifies the exact include
sites:

| Consumer file | Include-site heading |
|---|---|
| `skills/using-qrspi/SKILL.md` | artifact-level Apply-fix protocol section |
| `skills/implement/SKILL.md` | task-level Apply-fix protocol section |

However, **neither of the Modify rows for these two SKILL.md files mentions the `!cat`
include**:

- `skills/using-qrspi/SKILL.md` Slice 1.2 (line 36): "Define round instrumentation,
  sub-threshold observation logging, and verifier-visible audit surfaces." ← No `!cat`
- `skills/using-qrspi/SKILL.md` Slice 1.4 (line 69): "Carry the unified five-tier
  `model_routing:` schema, host matrix, validation rows, and fail-loud invariant prose."
  ← No `!cat`
- `skills/implement/SKILL.md` Slice 1.3 (line 50): "Require `round-prepare` outputs and
  scope-tagger/fan-in artifacts on each per-task review cycle." ← No `!cat`
- `skills/implement/SKILL.md` Slice 1.4 (line 85): "Adopt shared reviewer dispatch and pass
  per-task tier overrides into implementer/test-writer fan-out." ← No `!cat`

## Asymmetry with CD-1 reviewer-dispatch-prose

This is a direct structural asymmetry. For the analogous CD-1 shared snippet
(`skills/_shared/reviewer-dispatch-prose.md`), every consumer SKILL.md's Modify row
explicitly calls out "Replace inline reviewer-dispatch prose with a thin preamble plus shared
include." The R1 round applied this pattern consistently across 12 consumer skills.

The CD-4 `verifier-dispatch-prose.md` has only **2** consumers (much simpler), yet neither
consumer's Modify row mentions the include. This asymmetry means:

1. An implementer modifying `using-qrspi/SKILL.md` for Slice 1.2 (G20/G28/G29 scope) will
   add round instrumentation prose but won't know to insert the `!cat` include.
2. An implementer modifying `using-qrspi/SKILL.md` for Slice 1.4 (G3/G22 scope) will add
   model-routing schema but won't know to insert the `!cat` include.
3. The build step (`tools/build-plugin.mjs`, Slice 1.4) will encounter a missing `!cat`
   include site in these SKILL.md files and produce incomplete built output.

## Dead-end output

`skills/_shared/verifier-dispatch-prose.md` will be **created** (Slice 1.1) but never
**included** anywhere, because neither consumer Modify row wires the include. This is a
dead-end output for the created file.

## Minimal-altitude fix

Add a single sentence to one of each consumer's Modify rows (either the existing row or a
new dedicated row) calling out the include:

- `skills/using-qrspi/SKILL.md` Slice 1.2 or Slice 1.4 row: append "Add
  `!cat skills/_shared/verifier-dispatch-prose.md` at the Apply-fix protocol section per
  CD-4/G12 Hook-Point Locations."
- `skills/implement/SKILL.md` Slice 1.3 or Slice 1.4 row: append "Add
  `!cat skills/_shared/verifier-dispatch-prose.md` at the task-level Apply-fix protocol
  section per CD-4/G12 Hook-Point Locations."

The Slice 1.3/1.4 rows are the better candidates because they are the ones closest in
concern (reviewer dispatch / fan-in) to the verifier prose content.
