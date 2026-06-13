---
status: approved
task: 33
phase: 1
pipeline: full
goal_ids: [G9, CD-3]
task_type: lightweight
tier: high
sizing_exception: reusable-primitives
---

# Task 33: Trim skills/implement/SKILL.md (Pass 1+2+3) to target <500 lines

- **Target files:** `skills/implement/SKILL.md` (Modify)
- **Dependencies:** T07, T31, T20a, T20b
- **LOC estimate:** sizing_exception: reusable-primitives (canonical implementer-spine trim)
- **Sizing rationale:** Trim pass against the heaviest active skill body; the unit of work is the full pass against the post-T20a/T20b state.
- **Description:** Three-tier placement plus deletion plus R8 tightening applied to `skills/implement/SKILL.md`. The 4× verifier-wiring duplication collapses to one canonical reference; the 2× visual-fidelity dispatch duplication collapses to one canonical reference; jobId / tmpfile / HEAD~1 / convergence-table / sidecar-schema / change_type-enum / third-party-splitter narrative restatements are deleted (scripts are SSoT); `_shared/` `!cat` references are added for reviewer-dispatch, review-loop, pause-gate, feedback-format as applicable. The T20a additions (Wave Dispatch validation wrap) and T20b additions (OBC step, batch-gate additions including the unconditional dispatch-defects halt branch) are preserved through the trim. R1, R2, R3, R5, R7, R8 shape the trim.
- **Test expectations:**
  - Implementer applies R1-R7 + cross-cutting principles from `skills/_shared/prompt-design-rules.md`; reviewer verifies via the same content-semantic rules application; specific findings to verify: R1 — preservation of implement/SKILL.md's distinctive headings and the T20a + T20b additions (OBC step, Wave Dispatch validation wrap, batch-gate additions including the unconditional dispatch-defects halt branch) through the trim; R2 — every kept paragraph self-contained; R3 — load-bearing wave-dispatch and batch-gate content retained, informational content moved to `references/<topic>.md`; R5 — `references/` extraction only under R5 conditions; R7 — anchor phrases the T24 lint and any reviewer dispatch depend on are exact post-trim; R8 — R8 reviewer test applied; 4× verifier-wiring and 2× visual-fidelity duplications collapsed; jobId / tmpfile / HEAD~1 / convergence-table / sidecar-schema / change_type-enum / third-party-splitter narrative restatements deleted; trim audit (T38) passes; target <500 lines.
