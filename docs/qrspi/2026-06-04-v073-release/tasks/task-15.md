---
status: approved
task: 15
phase: 1
pipeline: full
goal_ids: [G3]
task_type: lightweight
tier: high
---

# Task 15: Add pre-fanout absorption-map anchor sentence to skills/plan/SKILL.md

- **Target files:** `skills/plan/SKILL.md` (Modify)
- **Dependencies:** T02
- **LOC estimate:** ~15
- **Description:** A verbatim anchor sentence is added to `skills/plan/SKILL.md` directing the plan-author to run `scripts/design-absorption-markers.sh` against `design.md` before fan-out, ingest the resulting redirect map, refuse to author standalone tasks for absorbed goal IDs, and halt with BLOCKED rather than manufacture a task home for residual work under an absorbed/moot/deferred goal. R1 (anchor-phrase preservation for the surrounding § Pre-fanout section), R2 (the sentence is self-contained — names the script and the BLOCKED halt without external cross-references), R3 (the sentence lands at the start of the pre-fanout step list, the load-bearing position for a gate directive), R7 (verbatim phrasing the T16 reviewer clauses and T17a plan-spec-reviewer fixture assert), and R8 (prose-density tightening) shape the edit.
- **Test expectations:**
  - Implementer applies R1-R7 + cross-cutting principles from `skills/_shared/prompt-design-rules.md`; reviewer (`qrspi-code-quality-reviewer` and/or `qrspi-design-reviewer` per surface in scope) verifies via the same content-semantic rules application; specific findings to verify: R1 — anchor-phrase preservation for the surrounding § Pre-fanout section; R2 — the anchor sentence is self-contained, names the script, the redirect-map consumption step, and the BLOCKED halt inline; R3 — the sentence lands at the start of the pre-fanout step list, the load-bearing position for a gate directive; R7 — verbatim phrasing the T16 plan-spec reviewer clause and the T17 plan-spec fixture depend on; R8 — prose-density tightening of the anchor sentence.
- **cross_task_consumers:**
  - `agents/qrspi-plan-spec-reviewer.md`, `agents/qrspi-design-reviewer.md` (T16) — disposition: `pass-through` (T16 adds rubric clauses that depend on the verbatim anchor phrasing this task installs; the reviewer bodies are edited by T16, not this task).
  - `tests/unit/test-plan-spec-reviewer-absorption.bats` (T17a) — disposition: `pass-through` (the T17a plan-spec-reviewer fixture asserts against the verbatim phrasing this task installs; no edit to this task's deliverables required).
  - `skills/plan/SKILL.md` (T34) — disposition: `pass-through` (the T34 trim preserves the anchor sentence this task adds — anchor-phrase preservation is part of T34's specific findings to verify).
