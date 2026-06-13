---
status: approved
task: 7
phase: 1
pipeline: full
goal_ids: [CD-3]
task_type: lightweight
tier: medium
---

# Task 07: Insert R8 prose-density rule in skills/_shared/prompt-design-rules.md

- **Target files:** `skills/_shared/prompt-design-rules.md` (Modify)
- **Dependencies:** none
- **LOC estimate:** ~90
- **Description:** A new `### R8 — Prose density: short declarative sentences, full behavioral precision` section is inserted between R7 and the cross-cutting-principles `---` separator. The section carries the tightening-pattern table header `| Pattern in current prose | Tightened form | Why it works |`, the `What NOT to tighten` subheading, the reviewer-test sentence "Could this sentence be shorter without losing behavioral precision OR load-bearing rationale?", and the "minimal does NOT mean short" guardrail tying R8 to the existing cross-cutting principles. The finding-type gate `rule-violation` row updates its citation to `R1-R8`. R1 (anchor-phrase preservation for the heading), R2 (the new section is self-contained — no cross-rule references that bury the rule), R3 (R8 lands at the end of the R-rule list, the load-bearing position before the cross-cutting principles), R7 (verbatim phrasing of the new anchor phrases the T08 lint depends on), and R8 itself (the new rule, applied to its own prose) shape the edit.
- **Test expectations:**
  - Implementer applies R1-R7 + cross-cutting principles from `skills/_shared/prompt-design-rules.md`; reviewer (`qrspi-code-quality-reviewer` and/or `qrspi-design-reviewer` per surface in scope) verifies via the same content-semantic rules application; specific findings to verify: R1 — heading `### R8 — Prose density: short declarative sentences, full behavioral precision` present verbatim; R2 — the R8 section is self-contained, no cross-rule external references; R3 — R8 lands at the load-bearing end-position of the R-rule list, before the cross-cutting principles `---` separator; R7 — all anchor phrases (table header, `What NOT to tighten` subheading, reviewer-test sentence) are exact and match the T08 lint's grep expectations; R8 — applied to the new section's own prose; finding-type gate `rule-violation` row cites `R1-R8` as a literal substring.
- **cross_task_consumers:**
  - `tests/lint/test-prompt-design-rules-r8.bats` (T08) — disposition: `pass-through` (T08 anchor-phrase grep verifies the post-T07 prose state; no edit to this task's deliverables required).
  - `skills/using-qrspi/SKILL.md` (T32), `skills/implement/SKILL.md` (T33), `skills/plan/SKILL.md` (T34), the 8 artifact-step SKILLs (T35), the 7 cross-cutting SKILLs (T36) — disposition: `pass-through` (each trim task applies the R8 reviewer test to its tightened prose; none edits prompt-design-rules.md).
