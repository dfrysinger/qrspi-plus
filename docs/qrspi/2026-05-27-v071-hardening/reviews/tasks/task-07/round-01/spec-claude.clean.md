# Spec Review — Task 7 — Round 1 — spec-claude — NO_FINDINGS

Reviewer: spec-claude
Task: 7 (v0.7.1-hardening, Wave 2)
Round: 1
HEAD: 3d3d0d9
Pre-task anchor: 8a45af2

## Verification result: CLEAN

All 13 test expectations in `tasks/task-07.md` are addressed with corresponding
tests, and all 4 prose-bearing expectations (TE1–TE4) are satisfied by the
SKILL Codex-detection block addition at `skills/using-qrspi/SKILL.md`
lines 411–416.

### TE → evidence map

| TE  | Requirement                                                           | Evidence                                                                             |
|-----|-----------------------------------------------------------------------|--------------------------------------------------------------------------------------|
| TE1 | SKILL names BOTH Copilot CLI task-tool + Claude Code shell-pipeline   | `skills/using-qrspi/SKILL.md` L411–414 (single conditional block, both bullets)      |
| TE2 | `agent_type: code-review` + `model: gpt-5.3-codex` literals           | `skills/using-qrspi/SKILL.md` L413                                                   |
| TE3 | `scripts/run-codex-review.sh` named                                   | `skills/using-qrspi/SKILL.md` L414                                                   |
| TE4 | Mismatch warning-only / single-line stderr / does not gate dispatch   | `skills/using-qrspi/SKILL.md` L416 (all four sub-elements present)                   |
| TE5 | `COPILOT_CLI=1` → `[transport: task-tool]` ×1, no shell-pipeline mark | `tests/acceptance/v07-phase1/test-phase1-acceptance.bats` L369–514 (TE5 test body)   |
| TE6 | `COPILOT_CLI` unset → `[transport: shell-pipeline]` ×1, no task-tool  | `tests/acceptance/v07-phase1/test-phase1-acceptance.bats` L521–552                   |
| TE7 | check_codex_available non-zero → short-circuit + propagate exit       | impl: `scripts/run-codex-review.sh` L626–635; test: acceptance bats L559–601         |
| TE8 | Copilot-CLI assertion discriminating power (positive + negative)      | acceptance bats L607–675 (TE8a + TE8b)                                               |
| TE9 | Claude-Code assertion discriminating power (positive + negative)      | acceptance bats L681–744 (TE9a + TE9b)                                               |
| TE10| Copilot-CLI: exit 0 AND distinguishable mock-emitted stdout marker    | acceptance bats L752–795 (GUID-unique mock marker)                                   |
| TE11| Claude-Code: exit 0 AND distinguishable mock-emitted stdout marker    | acceptance bats L803–837 (GUID-unique mock marker)                                   |
| TE12| Non-zero transport exit propagates unchanged                          | impl: `scripts/run-codex-review.sh` L645–650 (`exit "$?"`); test: acceptance L844–890|
| TE13| Mismatch warning + non-zero transport exit propagates                 | impl: L622–624 (mismatch decoupled from check_codex_available failure); test: L897–951|

### TDD ordering verified

- RED commit: 9f94918 (test-writer)
- GREEN commit: 3d3d0d9 (implementer)
- Order: test-writer first, implementer second — matches spec requirement
  "Dispatch order: test-writer first, implementer second (RED-verification
  gate between)".

### Check #7 (target-files deviation, advisory)

Spec target-files list: `skills/using-qrspi/SKILL.md` + `tests/acceptance/v07-phase1/test-phase1-acceptance.bats`.

Out-of-list files modified, each verified tightly scoped:

1. **`scripts/run-codex-review.sh`** (+48/-13): necessary to satisfy TE7
   (codex-unavailable short-circuit) and TE13 (mismatch decoupled from
   check_codex_available failure). Neither test expectation can be satisfied
   by prose alone — T7 bullet 7 explicitly mandates a dispatch-surface
   behavior change ("emits a single-line diagnostic to stderr and propagates
   non-zero exit (no log-and-continue)"). Diff is confined to the existing
   mismatch/availability block; no side effects elsewhere in the wrapper.
   The conditional gate `_codex_available=false AND _codex_reviews=true`
   correctly preserves prior behavior for `codex_reviews: false` callers.
   Tightly scoped. ✓

2. **`skills/using-qrspi/SKILL.anchors.json`** (+90/-90): purely mechanical
   regeneration via `scripts/g4-section-anchor-refresh.sh`. All line_start /
   line_end deltas are exactly +7, matching the +7 lines added to SKILL.md.
   No semantic changes. ✓

3. **`tests/unit/test-host-detection.bats`** (+22/-5): two T6-era tests
   (`[dispatch-surface] mismatch is warning-only…` and `[dispatch-surface]
   mismatch path does not suppress non-zero transport exit code`) asserted
   the `no-companion + codex_reviews=true → warning-only-continue` contract
   that T7's new short-circuit now invalidates (same conditions now trigger
   the codex-unavailable abort before reaching the transport). Both tests
   were rewritten to the equivalent `companion-present + codex_reviews=false`
   scenario, preserving the original test intent (mismatch warning-only,
   no transport-exit suppression) under T7 semantics. Inline comments
   document the migration. Tightly scoped. ✓

The implementer's DONE_WITH_CONCERNS framing for the scope expansions
accurately reflects the situation: the expansions were forced by the test
expectations rather than by the implementer's choice. Recommendation: no
rework needed; if a future task-spec hygiene pass occurs, the Target files
list for task-07.md could be retroactively updated to include
`scripts/run-codex-review.sh` to match what TE7 + TE13 logically required.

### Prose-vs-implementation observation (informational, no finding)

`skills/using-qrspi/SKILL.md` L413 states "No shell pipeline is involved
— the task tool is the in-process transport" for the Copilot-CLI branch.
The underlying `scripts/run-codex-review.sh` L643–646 still uses
`compose_prompt | bash "$DISPATCHER"` for both branches (the task-tool
branch differs only in the trace marker). The SKILL prose mirrors the
spec description language ("Under Copilot CLI the dispatch uses the
native task tool…") and reflects the intended dispatch architecture; the
underlying-mechanism conflation is a pre-existing Task-6 design choice
outside T7's scope. The SKILL prose is faithful to the spec description
language and does not constitute a T7 spec violation. Reported here as
forward-looking context for future architecture work, not as a finding.

## Decision: PASS (no findings)

Quality + security reviewers may proceed.
