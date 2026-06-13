---
status: approved
task: 9
phase: 1
pipeline: full
goal_ids: [G1]
task_type: lightweight
tier: high
---

# Task 09: Append ID-hygiene rubric clause to agents/qrspi-finding-verifier.md

- **Target files:** `agents/qrspi-finding-verifier.md` (Modify)
- **Dependencies:** T01
- **LOC estimate:** ~20
- **Description:** A new rubric clause is appended to `agents/qrspi-finding-verifier.md` § Rubric directing the verifier to ground findings whose subject is an identifier-hygiene token (forbidden-token-table match) in `skills/implementer-protocol/SKILL.md` § Hygiene contract via `<upstream_paths>` Read. The clause treats absence of the path from `<upstream_paths>` as a dispatch defect with no improvised fallback, and names both forbidden-token tables (Internal-ID, Evergreen-markdown) as load-bearing. The clause is the verbatim prose-design block from design.md G1 § Solution change 1. R1 (the clause is a new section appended to § Rubric — anchor-phrase preservation for the existing rubric headings), R2 (self-contained — no cross-document references the verifier would have to chase), R3 (the clause lands at the end of § Rubric, the load-bearing position), R7 (verbatim phrasing the T10 fixture asserts), and R8 (prose-density tightening applied to the clause itself) shape the edit.
- **Test expectations:**
  - Implementer applies R1-R7 + cross-cutting principles from `skills/_shared/prompt-design-rules.md`; reviewer (`qrspi-code-quality-reviewer` and/or `qrspi-design-reviewer` per surface in scope) verifies via the same content-semantic rules application; specific findings to verify: R1 — anchor-phrase preservation for the existing § Rubric headings; R2 — the new clause is self-contained, references `skills/implementer-protocol/SKILL.md` § Hygiene contract by exact path and section name; R3 — the new clause lands at the end of § Rubric, the load-bearing position; R7 — verbatim phrasing of the design.md G1 § Solution change 1 prose-design block (the T10 fixture grep depends on the literal phrasing); R8 — prose-density tightening of the new clause; the clause names both forbidden-token tables (Internal-ID, Evergreen-markdown) as load-bearing.
- **cross_task_consumers:**
  - `tests/unit/test-finding-verifier-id-hygiene-grounding.bats` (T10) — disposition: `pass-through` (T10 drives a synthetic verifier dispatch against the post-T09 rubric and asserts the rubric clause grounds findings in `skills/implementer-protocol/SKILL.md` § Hygiene contract; no edit to this task's deliverables required).
