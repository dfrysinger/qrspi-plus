---
status: approved
task: 29
phase: 1
pipeline: full
goal_ids: [G34]
task_type: lightweight
model: sonnet
---

# Task 29: G34 Design scope-reviewer alignment with detailed-solution boundary (design-altitude-boundary primitive + scope-reviewer + owns-defers)

- **Target files:** create `skills/_shared/design-altitude-boundary.md`; modify `agents/qrspi-design-scope-reviewer.md`; modify `skills/design/owns-defers.md`; create `tests/lint/test-design-altitude-boundary-include.bats`
- **Dependencies:** none. **Blocks:** T30 (Design SKILL decision-completeness template consumes the superseded-G1-deliverable boundary), T37 (Structure-side boundary migration follows the Design boundary split).
- **LOC estimate:** ~150

**Overview**

Create a single shared Design altitude boundary and wire both Design enforcement surfaces to it so the Design scope-reviewer stops flagging content that Design is supposed to own. The task closes the G34 false-positive loop by making `skills/design/owns-defers.md` and `agents/qrspi-design-scope-reviewer.md` consume the same `!cat` source. (Why: see goals.md ### G34. Approach: see design.md ## G34.)

**Scope**

- **In:**
  - Create `skills/_shared/design-altitude-boundary.md` as the single source of truth for the Design OWNS block followed by the Design DEFERS block, lifted from design.md ## G34 D2/D3 and kept as one contiguous boundary contract.
  - Replace the inline contract body in `skills/design/owns-defers.md` with the literal directive `!cat skills/_shared/design-altitude-boundary.md`, preserving the file's existing surrounding structure.
  - In `agents/qrspi-design-scope-reviewer.md`, insert the exact introducer prose `The contract you just read carries the following allowances and deferrals; restated here so they are present in your immediate reasoning context:` immediately after the Step 1 Read citation, followed by the literal directive `!cat skills/_shared/design-altitude-boundary.md`.
  - Preserve the boundary's positive OWNS allowances and matching DEFERS list so detailed solution descriptions, edge cases, flows, prompt-writing specifics, acceptance examples, per-solution diagrams, naming/rename inventory, and phasing labels are allowed while implementation bodies, full test code, executable shell, file architecture, unified architecture/test strategy, and task carving remain deferred.
  - Create `tests/lint/test-design-altitude-boundary-include.bats` asserting that `agents/qrspi-design-scope-reviewer.md` contains the literal `!cat skills/_shared/design-altitude-boundary.md` directive on the line immediately after the Step 1 Read citation introducer prose, and that `skills/design/owns-defers.md` contains the same literal directive in place of the previous inline contract body. Removal of either include directive must fail the lint with a diagnostic naming the violating file and the missing directive.

- **Out:**
  - Rewriting the Design SKILL's per-goal template and other G1 deliverables — T30 owns; G1 deliverable #6 is superseded by this task's positive OWNS plus DEFERS boundary and must not be implemented a second time.
  - Moving unified system/test architecture responsibility into Structure — T37 owns.
  - Auditing or changing non-Design artifact scope reviewers and their owns-defers files — explicitly deferred outside G34.
  - Changing dispatch parameters, reviewer model selection, tool grants, reviewer-protocol `change_type` semantics, or scope-finding pause behavior.
  - Moving file architecture, unified system architecture, unified test architecture, or task decomposition back into Design ownership.
  - Adding or modifying files outside the four target files, unless a directly coupled include-resolution break prevents those files from being valid.

**Definition of done**

- `skills/_shared/design-altitude-boundary.md` exists and its boundary body is one contiguous Design OWNS block followed by one contiguous Design DEFERS block.
- The shared boundary contains the explicit OWNS allowances and DEFERS exclusions named in design.md ## G34 D2/D3, with no implementation instructions, task carving, or file-architecture material outside those blocks.
- `skills/design/owns-defers.md` keeps its existing surrounding structure and contains the literal line `!cat skills/_shared/design-altitude-boundary.md` in place of the previous inline contract body.
- `agents/qrspi-design-scope-reviewer.md` contains the exact introducer prose immediately after the Step 1 Read citation, followed by the literal line `!cat skills/_shared/design-altitude-boundary.md`.
- Neither consumer inlines the full boundary contract; both rely on the `!cat` directive so build expansion remains the single-source mechanism.
- No second Design owns-defers rewrite is introduced for G1 deliverable #6, and no non-Design scope-reviewer surfaces are broadened into this task.
- Prompt prose remains concrete and audit-friendly: no TODO/TBD placeholders, no stale `docs/prompt-design-guide.md` reference, no bare prohibition without a positive substitute and decision rule.
- `tests/lint/test-design-altitude-boundary-include.bats` exists and asserts the literal `!cat skills/_shared/design-altitude-boundary.md` directive is present in both consumer files at the canonical insertion points; removal of either directive fails the lint with a file-and-directive-naming diagnostic.

**Test expectations**

- File-existence check confirms `skills/_shared/design-altitude-boundary.md` exists and the two consumer files still exist at their canonical paths.
- Grep audit confirms the literal `!cat skills/_shared/design-altitude-boundary.md` line is present in both `skills/design/owns-defers.md` and `agents/qrspi-design-scope-reviewer.md`.
- Ordering inspection confirms the Design scope-reviewer introducer prose appears immediately after the Step 1 Read citation and immediately before the `!cat` directive.
- Boundary-body inspection confirms `Design OWNS:` precedes `Design DEFERS:` and includes the named OWNS allowances and DEFERS exclusions from design.md ## G34 D2/D3.
- Consumer-source inspection confirms the full OWNS/DEFERS boundary is not duplicated inline in either consumer beyond the required `!cat` directive.
- Run `tests/lint/test-design-altitude-boundary-include.bats` and confirm it passes against the implemented consumer files; a negative-test fixture (removing the include directive from one consumer) must cause the lint to fail with a diagnostic naming the violating file and the missing directive.
- Diff audit confirms only the four target files changed, unless the implementer documents a directly coupled include-resolution break.
- Apply R1-R7 + cross-cutting principles from `skills/_shared/prompt-design-rules.md` (resolved from the installed plugin path per host convention) to the new prompt prose; reviewer verifies single-source prompt prose, positive OWNS allowances paired with DEFERS, exact anchor phrase preservation, evergreen/non-host-specific wording, no placeholder bodies, and compaction-resilient load-bearing instructions at the point of use.

**References**

- goals.md ### G34 — problem framing for the Design scope-reviewer vs Design SKILL boundary contradiction.
- design.md ## G34 — detailed solution D1-D6, locked OWNS/DEFERS lists, consumer insertion points, and acceptance criteria.
- structure.md ### `skills/_shared/design-altitude-boundary.md` — per-file contract for the shared boundary primitive.
- structure.md ### `agents/qrspi-design-scope-reviewer.md` — per-file contract for the reviewer insertion point and immediate reasoning context.
- structure.md ### `skills/design/owns-defers.md` — per-file contract for replacing the inline body with the shared include.
- structure.md ## Hook-Point Cross-Slice Index → G34 design-altitude-boundary `!cat` include sites — cross-slice list of the two required consumers.
