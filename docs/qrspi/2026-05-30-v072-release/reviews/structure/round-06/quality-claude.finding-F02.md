---
finding_id: R6-F02
reviewer_tag: quality-claude
artifact: structure
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/structure.md
  - docs/qrspi/2026-05-30-v072-release/design.md
---

# CD-2 antagonist-pattern reviewer hook is missing from the File Map

## What

`design.md` CD-2 § Acceptance criteria includes (item #4):

> Reviewer protocol updated to surface a finding when an `status: draft → approved` artifact contains any of the named antagonist patterns. (Either fold the check into existing quality reviewers, or define a sibling check — sizing TBD in Plan.)

That deliverable has two permitted shapes:
- **Shape A — fold into existing quality reviewers** (e.g., add antagonist-pattern detection to `agents/qrspi-code-quality-reviewer.md` or one of the per-artifact quality reviewers like `qrspi-design-reviewer.md`, `qrspi-structure-reviewer.md`, etc.)
- **Shape B — define a sibling check** (a new `agents/qrspi-<something>-reviewer.md` or a new lint test)

Neither shape is represented in `structure.md`. Specifically:

- The only `skills/reviewer-protocol/SKILL.md` row in the File Map (Slice 1.5) is scoped to `G10` only — "Ban fabricated procedural authority and keep reviewer findings tied to real contract surfaces." That row does not cover antagonist-pattern surfacing.
- No reviewer-agent file (`agents/qrspi-*-reviewer.md`) carries `CD-2` in its Goal IDs column anywhere across the seven slices.
- No new sibling-check agent or lint test is created under `CD-2`.
- The `skills/_shared/evergreen-output-rule.md` Create row (Slice 1.5, CD-2) holds only the shared rule prose itself — it is not a reviewer surface.

## Why it matters (structure-quality dimension: no-missing-components + structure-matches-design)

CD-2's stack is: (1) authoritative rule snippet → (2) `!cat`-include into 9 artifact-producing skills → (3) **reviewer enforcement that surfaces violations as findings**. Structure.md captures layers (1) and (2) — the snippet creation and the 9 include sites in the Hook-Point Locations table — but layer (3), the load-bearing enforcement, has no file in the File Map. Without it:

- The Evergreen-Output Rule becomes advisory prose with no enforcement surface. Skills `!cat`-include the rule into their writer-side prompts, but no reviewer agent is contracted to flag violations when antagonist patterns slip into a draft.
- Plan has no place to author the "review-side antagonist-pattern check" task because there is no target file in the file map.
- The Test Architecture's CD-2 entry under § Cross-cutting invariants says "**CD-2** evergreen-output-rule strips dialogue exhaust from draft→approved artifacts — T4 + T3" — T4 is lint (covered by `tests/unit/test-author-skill-uses-cat.bats` for include presence) and T3 is acceptance, but neither names the reviewer-side antagonist-pattern enforcement that CD-2 acceptance #4 contracts.

This is the same component-vs-flow gap CD-3's Multi-Actor Flow Check is designed to catch in design.md, applied to structure.md itself: the actors and rule are enumerated, but a hand-off (rule → reviewer enforcement → finding) is unrepresented.

## Suggested fix

Pick one of the two shapes design.md permits and add the corresponding file row(s) under Slice 1.5. Two illustrative options:

**Option A — fold into the existing per-artifact quality reviewers.** Add CD-2 to the goal IDs of (and a short Responsibility note for) each of the per-artifact quality reviewers that gate artifact promotion. Minimum touch surface would be `agents/qrspi-design-reviewer.md`, `agents/qrspi-structure-reviewer.md`, `agents/qrspi-plan-reviewer.md`, plus the matching reviewers for goals/questions/research/phasing/parallelize/replan. The Responsibility text would be "Surface antagonist-pattern violations from the Evergreen-Output Rule when reviewing artifact drafts" or similar.

**Option B — define a sibling check.** Add a single new row, e.g.:

| File | Action | Responsibility | Goal IDs |
|---|---|---|---|
| `agents/qrspi-evergreen-output-reviewer.md` | Create | Surface findings for any `status: draft → approved` artifact containing the named antagonist patterns from `_shared/evergreen-output-rule.md`. | CD-2 |

…plus dispatch entries in each of the 9 artifact-producing SKILL.md files' reviewer-dispatch preamble (those SKILL.md rows already exist in the file map under Slice 1.4 for the dispatch-prose collapse, so the goal-ID column on those rows would gain `CD-2`).

Plan-time can pick between A and B; Structure's job is to make the deliverable visible. Either option also justifies a `tests/lint/test-evergreen-output-rule-enforcement.bats` (or equivalent T4 surface) so the Test Architecture's CD-2 invariant is grounded in a concrete pin.

A complete fix should also reconcile § Test Architecture's CD-2 entry: name which test file pins the reviewer-side enforcement, alongside the existing include-presence + acceptance pins.
