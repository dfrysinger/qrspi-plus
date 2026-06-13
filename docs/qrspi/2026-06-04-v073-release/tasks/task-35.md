---
status: approved
task: 35
phase: 1
pipeline: full
goal_ids: [G9, CD-3]
task_type: lightweight
tier: high
sizing_exception: reusable-primitives
---

# Task 35: Trim the 8 artifact-step skills to target <300 lines each

- **Target files:** `skills/goals/SKILL.md` (Modify), `skills/questions/SKILL.md` (Modify), `skills/research/SKILL.md` (Modify), `skills/design/SKILL.md` (Modify), `skills/phasing/SKILL.md` (Modify), `skills/structure/SKILL.md` (Modify), `skills/parallelize/SKILL.md` (Modify), `skills/replan/SKILL.md` (Modify)
- **Dependencies:** T07, T31, T05
- **LOC estimate:** ~sizing_exception: reusable-primitives (8-file bulk-pass sweep — single repeated trim shape across the 8 artifact-step skills)
- **Sizing rationale:** Bulk-pass mechanical sweep applying the four-pass trim to eight skill bodies; the unit of work is the full pass against the post-T05 state.
- **Description:** Each of the eight artifact-step skills (`goals`, `questions`, `research`, `design`, `phasing`, `structure`, `parallelize`, `replan`) applies the three-tier placement plus deletion plus R8 tightening passes against its post-T05 state (the high-level-dispatch replacement prose from T05 is already in place). `_shared/` `!cat` references replace any inlined boilerplate; per-skill `references/<topic>.md` files are created at extract time for optional examples or rare-path procedures. R1 (anchor-phrase preservation for each skill's distinctive headings), R2, R3, R5 (`references/` extraction only under R5 conditions), R7, R8 shape the sweep.
- **Test expectations:**
  - Implementer applies R1-R7 + cross-cutting principles from `skills/_shared/prompt-design-rules.md`; reviewer verifies via the same content-semantic rules application; specific findings to verify: R1 — preservation of each artifact-step skill's distinctive headings and the T05 high-level-dispatch replacement prose through the trim; R2 — every kept paragraph self-contained; R3 — load-bearing per-step process retained, informational content moved to per-skill `references/<topic>.md`; R5 — `references/` extraction only under R5 conditions; R7 — T05's anchor phrases preserved verbatim (the T06 lint depends on the absence of the diff-redirect pattern, which post-trim must still hold); R8 — R8 reviewer test applied across all 8 files; trim audit (T38) passes for all 8 files; target <300 lines each.
- **cross_task_consumers:**
  - `tests/lint/test-no-diff-redirect-prose.bats` (T06) — disposition: `pass-through` (T06 lints the post-T05 anchor — zero `git diff > round-NN.diff` Bash redirect blocks remain across the eight artifact-step skills; T35's trim must preserve the post-T05 high-level-dispatch replacement prose so the T06 lint's zero-match invariant continues to hold after the trim. T06's dependency is on T05 and not on T35 — if T35 silently re-introduced the diff-redirect pattern via Pass-3 prose-density edits to the dispatch-incantation prose, T06 would not block the trim; the `pass-through` disposition documents the anchor-preservation expectation explicitly).
