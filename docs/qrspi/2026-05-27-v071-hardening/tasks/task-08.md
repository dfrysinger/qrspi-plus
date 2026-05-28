---
status: approved
task: 8
phase: 1
pipeline: full
goal_ids: [G7a]
task_type: code
model: opus
---

# Task 8: Retire prompt-cache mechanism from dispatcher, skill, and test infrastructure

- **Target files:** `scripts/g4-cache-probe.sh` (delete), `docs/qrspi/2026-05-17-v07-release/spikes/g4-cache-probe.md` (delete), `tests/unit/test-cache-control-capability-gate.bats` (delete), `tests/unit/test-cache-hit-rate.bats` (delete), `skills/using-qrspi/SKILL.md` (modify), `scripts/run-third-party-llm.sh` (modify), `tests/unit/test-run-third-party-llm.bats` (modify), `tests/acceptance/v07-phase1/test-phase1-acceptance.bats` (modify), `tests/acceptance/v07-phase1/test-cache-retirement-invariants.bats` (create)
- **Dependencies:** Task 1, Task 7
- **LOC estimate:** ~150
- **Description:** The prompt-cache mechanism is fully retired: four files are deleted and cache-related content is removed from four modified files. Deleted: `scripts/g4-cache-probe.sh` (the cache-probe script), `docs/qrspi/2026-05-17-v07-release/spikes/g4-cache-probe.md` (the stub spike report), `tests/unit/test-cache-control-capability-gate.bats` (the dual-flag capability-gate unit suite), and `tests/unit/test-cache-hit-rate.bats` (the path-conditional cache-hit-rate suite). Modified: `skills/using-qrspi/SKILL.md` loses `cache_control`, `supports_prompt_cache`, and `emit_cache_control_markers` from the providers block (both the YAML example values and their description bullets); `scripts/run-third-party-llm.sh` loses the `cache_control` marker emission branch from `_dispatch_openai_chat`; `tests/unit/test-run-third-party-llm.bats` loses the four cache-control truth-table assertions that duplicate the deleted capability-gate suite and gains grep-based absence assertions verifying that `cache_control`, `supports_prompt_cache`, and `emit_cache_control_markers` literal strings are absent from `scripts/run-third-party-llm.sh` after modification; `tests/acceptance/v07-phase1/test-phase1-acceptance.bats` loses the `SPIKE` export pointing at the deleted spike report and the two `run_pin` invocations for the deleted unit suites; a new file `tests/acceptance/v07-phase1/test-cache-retirement-invariants.bats` (following the naming pattern of the deleted `test-cache-control-capability-gate.bats`) greps `test-phase1-acceptance.bats` from outside and asserts that no `SPIKE` export and no `run_pin` invocations reference the deleted files, eliminating self-referential grep. The cache mechanism boundary closes atomically across all five surfaces; CI-green is the acceptance gate per Design DKR8. Dispatch order: test-writer first (authors the grep-based absence assertions for `tests/unit/test-run-third-party-llm.bats` and the absence invariants in `tests/acceptance/v07-phase1/test-cache-retirement-invariants.bats`), implementer second (mechanical deletions and SKILL.md prose edits); RED-verification gate between confirms absence assertions fail against the pre-deletion tree. This task is no longer purely mechanical since R2 added net-new test assertions.
- **Test expectations:**
  - `scripts/g4-cache-probe.sh` does not exist in the repository after the task completes (filesystem absence)
  - `docs/qrspi/2026-05-17-v07-release/spikes/g4-cache-probe.md` does not exist in the repository after the task completes (filesystem absence)
  - `tests/unit/test-cache-control-capability-gate.bats` does not exist in the repository after the task completes (filesystem absence)
  - `tests/unit/test-cache-hit-rate.bats` does not exist in the repository after the task completes (filesystem absence)
  - `skills/using-qrspi/SKILL.md` contains no references to `cache_control`, `supports_prompt_cache`, or `emit_cache_control_markers` after modification
  - A new automated assertion in `tests/unit/test-run-third-party-llm.bats` greps `skills/using-qrspi/SKILL.md` for `cache_control`, `supports_prompt_cache`, and `emit_cache_control_markers` and fails if any of the three literal strings is found
  - `scripts/run-third-party-llm.sh` contains no `cache_control` key emission logic after modification; a grep-based absence assertion in `tests/unit/test-run-third-party-llm.bats` verifies that the literal strings `cache_control`, `supports_prompt_cache`, and `emit_cache_control_markers` are absent from `scripts/run-third-party-llm.sh`
  - `tests/unit/test-run-third-party-llm.bats` contains no cache-control truth-table test blocks after modification
  - `tests/acceptance/v07-phase1/test-phase1-acceptance.bats` contains no `SPIKE` variable export referencing the deleted spike file and no `run_pin` invocations referencing the deleted suite files after modification; `tests/acceptance/v07-phase1/test-cache-retirement-invariants.bats` greps `test-phase1-acceptance.bats` from outside to verify these absence conditions, eliminating self-reference
  - After Task 8 modifications, `tests/acceptance/v07-phase1/test-phase1-acceptance.bats` still contains the G6 host-detection acceptance assertions added by Task 7 (specifically, the `COPILOT_CLI=1` Copilot CLI path assertion and the `COPILOT_CLI` unset Claude Code path assertion)
  - The full CI suite (Lint job + BATS-under-bash-3.2 job) passes after all deletions and removals land with no regressions

**Manual Validation:**
- Pre-merge: `git diff --name-only HEAD~1` for the Task 8 commit lists no path under `docs/qrspi/2026-04-29-v0.4-bundle/` or `docs/superpowers/`. Operator-verified; BATS-level git introspection is impractical for this scope.
