---
status: approved
task: 13
phase: 1
pipeline: full
goal_ids: [G2]
task_type: lightweight
tier: medium
---

# Task 13a: Promote implementer-protocol Pre-DONE self-check to blocking

- **Target files:** `skills/implementer-protocol/SKILL.md` (Modify)
- **Dependencies:** none
- **LOC estimate:** ~20
- **Description:** One anchor sentence is added to `skills/implementer-protocol/SKILL.md` § Pre-DONE self-check (combined hygiene scan) promoting the existing self-check from advisory to halt-DONE: any ID-hygiene match in added or modified `@test "..."` description strings halts the DONE signal, requiring the implementer to fix the violation before reporting complete. R1 (anchor-phrase preservation for the surrounding § Pre-DONE self-check section), R3 (the new blocking sentence lands at the end of the existing self-check paragraph, the load-bearing position), R7 (verbatim phrasing the T12 lint and downstream reviewer agents rely on), and R8 (prose-density tightening of the new sentence) shape the edit.
- **Test expectations:**
  - Implementer applies R1-R7 + cross-cutting principles from `skills/_shared/prompt-design-rules.md`; reviewer verifies via the same content-semantic rules application; specific findings to verify: R1 — anchor-phrase preservation for the surrounding § Pre-DONE self-check section; R2 — the new sentence is self-contained, naming the scope (`@test "..."` description strings) and the halt direction inline; R3 — promotion-to-blocking sentence lands at the end of the self-check paragraph, the load-bearing position; R7 — verbatim phrasing the T12 lint and the downstream Pre-DONE-aware reviewer agents depend on; R8 — prose-density tightening of the new sentence.
