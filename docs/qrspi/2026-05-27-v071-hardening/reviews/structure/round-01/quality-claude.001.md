---
artifact: structure
reviewer: qrspi-structure-reviewer
reviewer_tag: quality-claude
round: 1
severity: medium
change_type: addition
status: open
---

# G6 integration test is required by design + phasing but absent from the file map

## Location

`structure.md` § File Map § Slice 6 (lines 49–54).

## What I observed

Slice 6's file map adds only one test file:

> `tests/unit/test-host-detection.bats` | Create | Unit tests for `detect_host()` under mocked `COPILOT_CLI` env signals and `check_codex_available()` per host; pins transport-selection correctness for both Claude Code and Copilot CLI paths

That row is unit-level (mocked env signals, isolated function calls under `tests/unit/`). No integration-level test file is named for Slice 6 anywhere in the file map.

## Why it matters

Two upstream artifacts explicitly require an integration test for this slice:

1. **`design.md` § Test Strategy § G6** (lines 143–144) names three tests for G6: "Unit test for the new host-detection function with mocked environment signals. Unit test for the Codex availability check per detected host. **Integration test that dispatching a Codex review via the host-appropriate transport succeeds.**" The structure covers the two unit tests in one file, but the integration test has no file representation.

2. **`phasing.md` § Phase 1 § Replan gate criterion #3** (line 55): "Codex reviewer dispatches succeed end-to-end on both Claude Code and Copilot CLI hosts using the host-appropriate transport (G6 acceptance, per `design.md` DKR7)." End-to-end transport success is the gate, and no test file in the structure exercises it.

Structure.md does name integration-shaped coverage for other slices where design called for it — e.g., Slice 2's `test-commit-hygiene-invariants.bats` explicitly covers "scratch file is absent from the staged index **in a simulated implementer commit flow**", mirroring design's G2 integration-test requirement. The asymmetry with Slice 6 (where the analogous integration test exists in design but not in the file map) is what makes this a structural omission rather than a Plan-owned detail: the file-naming convention has already been set by the other slices.

This is a missing-component issue: a test artifact the design names and the replan gate depends on has no row in the file map, leaving Plan without a structural anchor to extend.

## Suggested resolution

Add one row to Slice 6's table for the integration test. Candidate file path consistent with the existing `tests/acceptance/v07-phase1/` layout used by Slice 7's acceptance suite touch, e.g.:

| File | Action | Responsibility | Goal IDs |
|------|--------|----------------|----------|
| `tests/acceptance/v07-phase1/test-codex-dispatch-per-host.bats` | Create | End-to-end integration: dispatch a Codex review via the host-appropriate transport (shell pipeline under Claude Code; native task-tool under Copilot CLI) and assert success on both host paths; satisfies Phase 1 replan-gate #3 | G6 |

(Exact filename, suite layout, and host-mocking strategy are Plan-owned details; the structural commitment that an integration test exists for G6 is what belongs in `structure.md`.)

Optionally, also extend the Slice 6 sub-paragraph of the Architectural Diagram to show the integration-test node alongside the existing `tests/unit/test-host-detection.bats` unit-test surface.
