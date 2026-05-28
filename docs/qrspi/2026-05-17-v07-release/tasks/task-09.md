---
task: 9
status: approved
pipeline: full
task_type: lightweight
model: sonnet
phase: 1
goal_ids: [G6]
dependencies: []
loc_estimate: 100
---

# Task 09: RED-verification adapter contract documentation

- **Phase:** 1
- **Target files:**
  - `skills/implement/red-verification-adapters.md` (Create) — author the per-framework adapter contract that the four adapter scripts in T10 and the orchestrator gate in T11 both consume.
- **Dependencies:** none
- **LOC estimate:** ~100
- **Description:** Creates `skills/implement/red-verification-adapters.md` documenting the per-framework adapter contract that the Implement-skill RED-verification gate consumes after dispatching `qrspi-test-writer` in Implement-phase mode. The document declares the adapter call surface (each adapter accepts `--runner-exit <int>`, `--stdout-file <path>`, `--stderr-file <path>`), the classification output contract (each adapter emits exactly one of `pass`, `assertion-failure`, or `infrastructure-failure` on stdout), the adapter exit-code contract (`0` when a classification token is emitted, `1` with a loud diagnostic on stderr when the runner output is unrecognized), the initial framework set (BATS, Vitest, Jest, pytest), and the orchestrator's pause-behavior consequence for each classification (the orchestrator dispatches the implementer on `pass` or `assertion-failure` against the targeted change; the orchestrator pauses with a load-bearing diagnostic on `infrastructure-failure` or on vacuous-RED, where vacuous-RED is the suite-level condition of zero assertion failures on the targeted behavior even when individual adapters return `pass`). The contract document is the single source of truth that the four adapter scripts (T10) implement and the Implement-skill gate (T11) consumes.
- **Test expectations:**
  - The adapter call surface section names the three required flags (`--runner-exit`, `--stdout-file`, `--stderr-file`).
  - The classification output contract enumerates exactly the three legal stdout tokens (`pass`, `assertion-failure`, `infrastructure-failure`).
  - The adapter exit-code contract states `0` on classification and `1` with stderr diagnostic on unrecognized output.
  - The initial framework set lists BATS, Vitest, Jest, and pytest by name.
  - The orchestrator pause-behavior section documents that `infrastructure-failure` and vacuous-RED both trigger a pause, while `pass` and `assertion-failure` (with at least one task-relevant assertion failing) proceed to implementer dispatch.
