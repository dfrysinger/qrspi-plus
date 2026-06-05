---
status: approved
task: 33
phase: 1
pipeline: full
goal_ids: [G2]
task_type: lightweight
model: sonnet
---

# Task 33: G2 Plan schema-migration task shape

- **Target files:** modify `skills/plan/SKILL.md`; modify `agents/qrspi-plan-reviewer.md`
- **Dependencies:** none
- **LOC estimate:** ~80

**Overview**

Add the Plan schema-migration task shape so Plan can author one narrow, self-verifying task for many same-shaped file edits without weakening ordinary task-size discipline. The contract must make the exception explicit and reviewer-checkable through the required exception, rationale, and structural-lint fields. (Why: see goals.md ### G2. Approach: see design.md ## G2.)

**Scope**

- **In:**
  - Add a schema-migration task-shape contract to `skills/plan/SKILL.md` that permits oversized same-shape migrations only when the spec declares `sizing_exception: schema-migration`.
  - Require schema-migration specs to carry `sizing_rationale:` plus mandatory `structural_lint:` naming a bash check that proves the diff is mechanical-only.
  - State that the exception is ungated by file count only after the structural lint succeeds; the lint, exception field, and rationale field are mandatory together.
  - Update `agents/qrspi-plan-reviewer.md` so the plan reviewer exempts LOC/file-count ceilings only when all three fields are present and the `structural_lint` command executes successfully on the proposed diff.
  - Ensure missing `structural_lint` or an otherwise incomplete schema-migration declaration fails plan-spec review with a clear diagnostic.

- **Out:**
  - G15/G18 sweep-task `dependent_tests:` and cross-task consumer-surface contracts in the same Plan/reviewer files — T14 and T15 own those surfaces.
  - G31 prompt-prose classification, writer-addition, and reviewer preload/include work in the same Plan/reviewer structure rows — out of this G2-only task.
  - Changing ordinary task-size limits or adding new sizing-exception categories beyond the existing closed set (`schema-migration`, `CI scaffolding`, `reusable primitives`).

**Definition of done**

- `skills/plan/SKILL.md` documents a `sizing_exception: schema-migration` task shape that allows LOC/file-count exceptions only for mechanical same-shape migrations.
- The Plan contract requires `sizing_exception: schema-migration`, `sizing_rationale:`, and `structural_lint:` as a mandatory trio; no field is optional when the exception is used.
- The Plan contract defines `structural_lint:` as a bash check that proves the proposed diff is mechanical-only, with N-files otherwise ungated.
- `agents/qrspi-plan-reviewer.md` verifies the mandatory trio and re-runs or otherwise requires successful execution of the named structural lint before exempting LOC/file-count ceilings.
- Plan-spec review fails clearly when a schema-migration task omits `structural_lint` or declares the exception incompletely.
- The prose keeps the exception narrow and does not relax ordinary task-size discipline for non-schema-migration work.

**Test expectations**

- Grep audit of `skills/plan/SKILL.md` confirms the schema-migration contract includes the exact field names `sizing_exception: schema-migration`, `sizing_rationale:`, and `structural_lint:`.
- Grep audit of `agents/qrspi-plan-reviewer.md` confirms the review rubric checks the same three fields and ties LOC/file-count exemption to successful structural-lint execution.
- Content review confirms the Plan prose says the structural lint is mandatory, N-files are ungated only under the exception, and all three fields are mandatory together.
- Content review confirms the reviewer prose emits a clear defect for an attempted schema-migration task missing `structural_lint`.
- Implementer applies R1-R7 + cross-cutting principles from `skills/_shared/prompt-design-rules.md` (resolved from the installed plugin path per host convention); reviewer (`qrspi-code-quality-reviewer` and/or `qrspi-design-reviewer` per surface in scope) verifies via the same content-semantic rules application, especially load-bearing-rule clarity for distinguishing schema migrations from ordinary oversized tasks and positive-substitute wording for what schema migrations do.
- Anchor-phrase audit confirms the closed exception set remains clear (`schema-migration`, `CI scaffolding`, `reusable primitives`) and reviewers exempt LOC/file-count ceilings only when all schema-migration fields are present and the lint succeeds.

**References**

- goals.md ### G2 — problem framing for recurring same-shape schema migrations and why Plan/reviewer support is needed.
- design.md ## G2 — required schema-migration fields, mandatory structural lint, ungated file count, and review acceptance conditions.
- structure.md ### `skills/plan/SKILL.md` → Slice 1.5 — Plan SKILL insertion surface for the schema-migration task-shape contract.
- structure.md ### `agents/qrspi-plan-reviewer.md` → Slice 1.5 — plan-reviewer rubric addition for field completeness and structural-lint success before exemption.
