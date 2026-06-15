---
status: approved
task: fix-F02
pipeline: full
task_type: tdd
references_finding: docs/qrspi/2026-06-04-v073-release/reviews/integration/round-01/integration-claude.finding-F02.md
references_tasks: [T19, T19c, T20a]
---

# Fix F02 — Implement-phase wave-1 sidecar bridge to OBC contract

## Context

Integration review round-01 found that for `--phase implement`, the OBC script reads `reviews/implement/wave-state/wave-1.txt` parsed as YAML-colon form `integration_base: <SHA>`. The only writer in the merged tree — `scripts/validate-stage-commit-parents.sh` (T19c) driven by Implement's Wave Dispatch fence — writes `reviews/implement/wave-state/W{N}.sidecar` parsed as `integration_base=<SHA>`. Filename, separator, and wave-N coverage all diverge. OBC always fires `wave-1-sidecar-missing:` under `## Dispatch defects` → autopilot halts unconditionally at the Implement batch gate.

The OBC contract (`wave-1.txt`, YAML colon, single-wave) is pinned by `tests/unit/test-orchestration-boundary-check.bats:240-246`. T19c's `W{N}.sidecar` schema is pinned by `tests/unit/test-validate-stage-commit-parents.bats` and is correct for its own purpose (multi-wave parent validation). The bridge is the right shape.

## Resolution chosen

Reviewer's option #2: have `scripts/validate-stage-commit-parents.sh --capture` ALSO emit a `wave-1.txt` companion in the OBC's expected shape, but only when `--wave-id W1`. T19c's existing `W{N}.sidecar` output unchanged.

For waves where Wave 1 is fan-out only (no stage commit, so `--capture --wave-id W1` is never invoked), the Implement SKILL must invoke a new lightweight `--seed-wave-1-obc` mode of the same script that writes `wave-1.txt` from the current HEAD as a one-shot. This closes the "Wave 1 is fan-out only" gap the reviewer flagged.

## Target files

- `scripts/validate-stage-commit-parents.sh` (M)
  - In `--capture` mode, when `--wave-id W1`: ALSO write `reviews/implement/wave-state/wave-1.txt` with body `integration_base: <SHA>\ntask_tips:\n` (YAML colon, matching OBC's parser; trailing `task_tips:` line matches the pinned fixture shape — kept empty since OBC only reads `integration_base`)
  - NEW `--seed-wave-1-obc --integration-base <SHA>` mode: write `wave-1.txt` (same shape) without performing stage-commit parent validation. Used by Implement when Wave 1 has no stage commit.
- `skills/implement/SKILL.md` (M) — Wave 1 Dispatch fence: invoke `scripts/validate-stage-commit-parents.sh --seed-wave-1-obc --integration-base "$(git rev-parse HEAD)" --artifact-dir "<ABS_ARTIFACT_DIR>"` as the first orchestrator action when Wave 1 will have no stage commit. (When a stage commit IS planned, the existing `--capture --wave-id W1` invocation handles it via the dual-write above.)
- `tests/unit/test-validate-stage-commit-parents.bats` (M) — ADD: dual-write assertion (`--capture --wave-id W1` produces both `W1.sidecar` AND `wave-1.txt`); seed-mode assertion (`--seed-wave-1-obc` produces `wave-1.txt` only, with body matching the OBC fixture exactly).
- `tests/unit/test-orchestration-boundary-check.bats` (M, additive) — ADD: end-to-end test that runs `validate-stage-commit-parents.sh --capture --wave-id W1 ...` then `orchestration-boundary-check.sh --phase implement` and asserts `## Dispatch defects` is EMPTY (closes the detection gap the reviewer flagged).

## Test Expectations

After the fix lands:
- All existing tests in `tests/unit/test-validate-stage-commit-parents.bats` remain GREEN.
- All existing tests in `tests/unit/test-orchestration-boundary-check.bats` remain GREEN.
- The new dual-write test passes: `--capture --wave-id W1` produces both `W1.sidecar` (existing schema) AND `wave-1.txt` (OBC schema).
- The new seed-mode test passes: `--seed-wave-1-obc --integration-base <SHA>` produces `wave-1.txt` with body exactly `integration_base: <SHA>\ntask_tips:\n` and no other side effects.
- The new end-to-end test passes: full `--capture` + OBC chain produces empty `## Dispatch defects`.

## Out of scope

- F01's phase-base.txt fix (separate fix task)
- Reshaping T19c's `W{N}.sidecar` to OBC's contract (reviewer rejected this as broadening blast radius)
- Adding `wave-N.txt` for N>1 (OBC's current contract is wave-1 only; no new behavior introduced)
