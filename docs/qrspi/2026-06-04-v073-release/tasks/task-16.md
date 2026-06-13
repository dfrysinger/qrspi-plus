---
status: approved
task: 16
phase: 1
pipeline: full
goal_ids: [G3]
task_type: lightweight
tier: medium
---

# Task 16: Append G3 rubric clauses to plan-spec and design reviewer agent bodies (including absorption_map_path dispatch-defect contract for Plan and Design)

- **Target files:** `agents/qrspi-plan-spec-reviewer.md` (Modify), `agents/qrspi-design-reviewer.md` (Modify)
- **Dependencies:** T02
- **LOC estimate:** ~50
- **cross_task_consumers:**
  - `tests/unit/test-plan-spec-reviewer-absorption.bats` (T17a), `tests/unit/test-design-reviewer-fidelity.bats` (T17b), `tests/unit/test-design-reviewer-dispatch-defect.bats` (T17c) — disposition: `pass-through` (each fixture asserts the verbatim rubric clauses this task installs; no edit to this task's deliverables required).
- **Description:** Two coordinated rubric-clause appendments. The plan-spec reviewer body gains (a) a clause asserting no plan task carries an absorbed-goal ID (per the redirect map produced by `scripts/design-absorption-markers.sh`); a violation surfaces as a `change_type: scope` finding — and (b) a dispatch-defect contract clause: at the Plan step, an absent `absorption_map_path:` parameter is a dispatch defect; the reviewer halts with a `dispatch-defect:` named diagnostic and exits non-zero rather than silently proceeding with an empty absorbed-ID set (which would silently produce zero absorption findings and false-satisfy the G3 acceptance — silent-claude R2-F02 fail-loud direction). The design reviewer body gains (a) a fidelity-check clause asserting every absorption marker in `design.md` preserves authorial intent — a marker that contradicts its goal block's body (intent/marker contradiction) surfaces as a fidelity-mismatch finding — and (b) the same dispatch-defect contract clause at the Design step: an absent `absorption_map_path:` parameter is a dispatch defect; the reviewer halts with a `dispatch-defect:` named diagnostic and exits non-zero. The `absorption_map_path:` parameter is mandatory at exactly two steps — Plan and Design — and is optional only at goals/research/phasing/structure/parallelize steps, where the design absorption map has no applicable role. R1 (anchor-phrase preservation for both agents' § Rubric headings), R2 (self-contained clauses), R3 (each clause lands at the end of its agent's § Rubric, the load-bearing position), R7 (verbatim phrasing the T17a/T17b/T17c bats fixtures assert), and R8 (prose-density tightening) shape the edits.
- **Test expectations:**
  - Implementer applies R1-R7 + cross-cutting principles from `skills/_shared/prompt-design-rules.md`; reviewer verifies via the same content-semantic rules application; specific findings to verify: R1 — anchor-phrase preservation for both agents' § Rubric headings; R2 — every new clause is self-contained, naming the redirect-map source, the `change_type`, the fidelity-mismatch direction, and the dispatch-defect halt direction inline; R3 — each clause lands at the end of its agent's § Rubric; R7 — verbatim phrasing the T17a/T17b/T17c bats fixtures assert against; R8 — prose-density tightening.
  - The plan-spec reviewer's dispatch-defect clause names absent `absorption_map_path:` at the Plan step as a dispatch defect (`dispatch-defect:` diagnostic, non-zero exit) — the plan-spec reviewer does not proceed with an empty absorbed-ID set.
  - The design reviewer's dispatch-defect clause names absent `absorption_map_path:` at the Design step as a dispatch defect (`dispatch-defect:` diagnostic, non-zero exit), and names goals/research/phasing/structure/parallelize as the only steps where the parameter is optional.
