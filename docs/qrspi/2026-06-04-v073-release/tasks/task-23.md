---
status: approved
task: 23
phase: 1
pipeline: full
goal_ids: [G5]
task_type: lightweight
tier: low
---

# Task 23: Insert cross-cutting Orchestration Boundary note in skills/using-qrspi/SKILL.md

- **Target files:** `skills/using-qrspi/SKILL.md` (Modify)
- **Dependencies:** T19
- **LOC estimate:** ~15
- **Description:** A verbatim `### Orchestration Boundary applies to every phase` cross-cutting note is added to `skills/using-qrspi/SKILL.md`, pointing readers at the per-phase prose in `integrate/SKILL.md` and `test/SKILL.md` (which T21 and T22 author). The note is self-contained — it carries the HARD-RULE summary inline so the using-qrspi-only context still surfaces the rule even when the per-phase skills are not yet loaded. R1 (anchor-phrase preservation for surrounding universal-orchestrator-behaviours sections), R2 (self-contained inline HARD-RULE summary), R3 (load-bearing — placed in the universal-rules section, not buried), R7 (verbatim heading phrasing), and R8 (prose-density tightening) shape the edit.
- **Test expectations:**
  - Implementer applies R1-R7 + cross-cutting principles from `skills/_shared/prompt-design-rules.md`; reviewer (`qrspi-code-quality-reviewer` and/or `qrspi-design-reviewer` per surface in scope) verifies via the same content-semantic rules application; specific findings to verify: R1 — anchor-phrase preservation for the surrounding universal-orchestrator-behaviours sections; R2 — the cross-cutting note is self-contained (carries the HARD-RULE summary inline so using-qrspi alone surfaces the rule); R3 — the note lands in the universal-rules section, not buried; R7 — verbatim heading `### Orchestration Boundary applies to every phase`; R8 — prose-density tightening of the note.
- **cross_task_consumers:**
  - `skills/using-qrspi/SKILL.md` (T32) — disposition: `pass-through` (T32's Pass-1/2/3 trim of `using-qrspi/SKILL.md` must preserve the verbatim `### Orchestration Boundary applies to every phase` cross-cutting heading and its inline HARD-RULE summary verbatim through the trim; T32's R1 anchor-phrase preservation expectation covers this).
