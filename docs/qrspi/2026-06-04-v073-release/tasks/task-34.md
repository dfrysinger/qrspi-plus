---
status: approved
task: 34
phase: 1
pipeline: full
goal_ids: [G9, CD-3]
task_type: lightweight
tier: high
sizing_exception: reusable-primitives
---

# Task 34: Trim skills/plan/SKILL.md (Pass 1+2+3) to target <400 lines

- **Target files:** `skills/plan/SKILL.md` (Modify)
- **Dependencies:** T07, T31, T15
- **LOC estimate:** sizing_exception: reusable-primitives (plan-skill trim)
  - **sizing_rationale:** Trim pass against the plan-authoring spine; the unit of work is the full pass against the post-T15 state.
- **Description:** Three-tier placement plus deletion plus R8 tightening applied to `skills/plan/SKILL.md`. The new T15 pre-fanout absorption-map anchor sentence is preserved verbatim through the trim. `_shared/` `!cat` references replace any inlined reviewer-dispatch, review-loop, or pause-gate boilerplate. Optional pedagogical content (worked examples, rare-path procedures) moves to `skills/plan/references/<topic>.md`. R1 (the T15 anchor sentence is anchor-phrase-preserved), R2, R3, R5, R7, R8 shape the trim.
- **Test expectations:**
  - Implementer applies R1-R7 + cross-cutting principles from `skills/_shared/prompt-design-rules.md`; reviewer verifies via the same content-semantic rules application; specific findings to verify: R1 — preservation of plan/SKILL.md's distinctive headings and the T15 pre-fanout absorption-map anchor sentence verbatim through the trim; R2 — every kept paragraph self-contained; R3 — load-bearing plan-authoring content retained, informational content moved to `references/<topic>.md`; R5 — `references/` extraction only under R5 conditions; R7 — T15's anchor sentence preserved verbatim; R8 — R8 reviewer test applied; trim audit (T38) passes; target <400 lines.
