---
status: approved
task: 37
phase: 1
pipeline: full
goal_ids: [G35]
task_type: lightweight
model: sonnet
---

# Task 37: G35 Structure SKILL absorbs unified architecture content with `structure-altitude-boundary` primitive

- **Target files:** skills/structure/SKILL.md (modify), skills/_shared/structure-altitude-boundary.md (create), skills/structure/owns-defers.md (modify), tests/lint/test-structure-altitude-boundary-include.bats (create)
- **Dependencies:** Task 29. **Blocks:** T38 (Structure reviewer/scope-reviewer enforcement of the G35 boundary).
- **LOC estimate:** ~190

**Overview**

Move the destination side of the Design-to-Structure architecture migration into the Structure authoring surface by creating the shared Structure altitude primitive and teaching Structure to author unified system architecture plus unified test architecture. This keeps v0.7.2 from removing Design's unified architecture/test responsibilities without giving Structure the replacement contract. (Why: see goals.md ### G35. Approach: see design.md ## G35. File map: see structure.md ### `skills/structure/SKILL.md` and structure.md ### `skills/_shared/structure-altitude-boundary.md`.)

**Scope**

- **In:**
  - Create `skills/_shared/structure-altitude-boundary.md` as the single shared primitive carrying the locked Structure OWNS allowances and Structure DEFERS list as one contiguous markdown contract.
  - Update `skills/structure/SKILL.md` so Structure explicitly acknowledges ownership of unified system architecture diagram(s), file maps, module-boundary contracts, cross-solution component interactions, unified test architecture, and per-type stitching of per-solution acceptance criteria.
  - Add the Structure-side `## Test Architecture` authoring procedure that runs after Design approval, enumerates per-solution `Acceptance` subsections from design.md, groups them by release test taxonomy, identifies cross-cutting test invariants, and names the test type that owns each invariant.
  - Preserve positive Structure authoring guidance: tell Structure what to produce without re-litigating locked Design choices or descending into Plan/Implement-level test assertions.
  - Create `tests/lint/test-structure-altitude-boundary-include.bats` asserting that `agents/qrspi-structure-scope-reviewer.md` contains the literal `!cat skills/_shared/structure-altitude-boundary.md` directive on the line immediately after the introducer prose, and that `skills/structure/owns-defers.md` contains the same literal directive in place of the previous inline contract body. Removal of either include directive must fail the lint with a diagnostic naming the violating file and the missing directive.

- **Out:**
  - Reviewer-agent recognition/enforcement of unified system architecture and `## Test Architecture` as expected Structure content — T38 owns.
  - Scope-reviewer immediate-reasoning placement of `!cat skills/_shared/structure-altitude-boundary.md` — T38 owns.
  - Re-litigating Design decisions, per-solution flows, vendor research, detailed solution rationale, or per-task/unit-test assertions — Structure defers these by the G35 boundary.
  - Unrelated Structure procedure rewrites outside the unified architecture posture and `## Test Architecture` procedure.

**Definition of done**

- `skills/_shared/structure-altitude-boundary.md` exists and carries the locked Structure OWNS block plus the locked Structure DEFERS block from design.md ## G35 as a single shared primitive.
- `skills/structure/SKILL.md` states that Structure owns unified system architecture diagram(s), file map/module boundaries, cross-solution component interactions, unified test architecture, and per-type stitching of per-solution acceptance criteria.
- `skills/structure/SKILL.md` contains a `## Test Architecture` authoring procedure that is explicitly after Design approval and includes the load-bearing anchor phrases `name the test taxonomy`, `enumerate cross-cutting test invariants`, and `name the test type that owns each invariant`.
- The `## Test Architecture` procedure stitches locked per-solution `Acceptance` material from design.md into a release-level test taxonomy without re-opening Design rationale or adding Plan/Implement-level assertions.
- The edited prompt prose uses positive-substitute wording that describes what Structure authors, not only what Design no longer owns.
- The task does not edit reviewer agents, assume unresolved runtime `!cat` expansion beyond the primitive's intended source form, introduce implementation-level test assertions beyond the named include-guard lint, or rewrite unrelated Structure procedures.
- `tests/lint/test-structure-altitude-boundary-include.bats` exists and asserts the literal `!cat skills/_shared/structure-altitude-boundary.md` directive is present in both consumer files at the canonical insertion points; removal of either directive fails the lint with a file-and-directive-naming diagnostic.

**Test expectations**

- File-existence checks confirm `skills/_shared/structure-altitude-boundary.md` exists and `skills/structure/SKILL.md` remains a modified existing target file for this task.
- Diff or grep audit confirms the primitive carries the locked Structure OWNS and Structure DEFERS content from design.md ## G35 / structure.md ### `skills/_shared/structure-altitude-boundary.md` without drift.
- Grep `skills/structure/SKILL.md` for `## Test Architecture`, `after Design approval`, `name the test taxonomy`, `enumerate cross-cutting test invariants`, and `name the test type that owns each invariant`.
- Content audit confirms `skills/structure/SKILL.md` names unified system architecture, module boundaries, cross-solution component interactions, unified test architecture, and per-type stitching as Structure-owned responsibilities.
- Run `tests/lint/test-structure-altitude-boundary-include.bats` and confirm it passes against the implemented consumer files; a negative-test fixture (removing the include directive from one consumer) must cause the lint to fail with a diagnostic naming the violating file and the missing directive.
- Scope audit confirms no reviewer-agent edits, no implementation-level test assertions beyond the named include-guard lint, and no unrelated Structure procedure rewrites were introduced by this task.
- Implementer applies R1-R7 plus cross-cutting principles from `skills/_shared/prompt-design-rules.md` (resolved from the installed plugin path per host convention); reviewer verifies the same content-semantic rules application against the new primitive and Structure SKILL prose.

**References**

- goals.md ### G35 — problem framing for the empty Structure-side destination after Design relinquishes unified architecture/test architecture.
- design.md ## G35 — locked D2/D3 OWNS/DEFERS contract, D4 Structure SKILL procedure skeleton, D5 target surfaces, and acceptance criteria.
- structure.md ### `skills/structure/SKILL.md` — G35 Structure authoring surface for unified architecture posture and `## Test Architecture` procedure.
- structure.md ### `skills/_shared/structure-altitude-boundary.md` — shared primitive body carrying the G35 Structure OWNS/DEFERS contract.
