# Pre-Implementer Test-Writer Dispatch + RED-Verification Gate

Read this file when running the two-step pre-implementer flow for `task_type: code` (or absent `task_type:`) tasks BEFORE the implementer dispatch. Lightweight tasks bypass this gate entirely; proceed directly to § Dispatching the Implementer.

The gate's classification semantics are defined in `skills/implement/red-verification-adapters.md`; this file defines the orchestrator-side dispatch steps.

#### Step 1 — Test-writer dispatch (Implement-phase mode)

Dispatch `Agent({ subagent_type: "qrspi-test-writer" })` — the concrete `(vendor, model)` pair is resolved at the dispatch boundary by the Tier Resolution Chain (the test-writer's `tier:`, co-escalated to the task's tier for high-tier tasks):

- `task_definition` — wrapped body of `tasks/task-NN.md` between `<<<UNTRUSTED-ARTIFACT-START id=tasks/task-NN.md>>>` and END markers. Presence of a non-empty `task_definition` selects Implement-phase mode per `agents/qrspi-test-writer.md`.
- `output_dir` — absolute path to the per-task test output directory inside the task's worktree.
- `companion_pipeline_inputs` — concatenated wrapped bodies of upstream pipeline artifacts (same set as the implementer dispatch).

The test-writer returns a terminal status, writes failing test files under `output_dir`, and reports the targeted framework (`bats`, `jest`, `vitest`, `pytest`) in its DONE report.

#### Step 2 — Test-writer dispatch-failure handling

If the `qrspi-test-writer` dispatch exits non-zero — dispatch failure, agent cannot parse `task_definition`, `output_dir` unwritable, zero test files written, or partial test files written but agent reported non-DONE — the gate treats this as infrastructure-failure-equivalent and **pauses** with: `"test-writer dispatch failed: task=task-NN, status=<reported-status>, output_dir=<path>, files_written=<count>, reason=<verbatim or 'dispatch-exit-nonzero'>"`. The gate does NOT run tests, does NOT invoke any adapter against partial output, and does NOT proceed to the implementer. This diagnostic is distinct from both adapter-classification-failure (Step 4) and the post-test-run `infrastructure-failure` classification (Step 5).

#### Step 3 — Run tests once and select the adapter

Run the framework's test runner against the new test files in `output_dir` exactly once, capturing stdout, stderr, exit code. The framework name reported by the test-writer selects the adapter from `scripts/red-verify/` (`bats-adapter.sh`, `jest-adapter.sh`, `vitest-adapter.sh`, `pytest-adapter.sh`). Invoke the adapter per `skills/implement/red-verification-adapters.md` (`--runner-stdout`, `--runner-stderr`, `--runner-exit`).

#### Step 4 — Adapter-classification-failure handling (exit 1)

When the adapter exits `1` (unrecognized runner output or flag-validation error), the gate **pauses** with: `"adapter-classification-failure: task=task-NN, adapter=<adapter-name>, framework=<framework>, adapter_exit=1, stderr=<verbatim adapter stderr>"`. Do NOT dispatch the implementer; do NOT treat adapter exit 1 as a proceed signal or infrastructure-failure synonym.

#### Step 5 — Adapter classification → proceed/pause decision

When the adapter exits `0`, parse the single classification token and act:

| Adapter classification | Orchestrator action |
|------------------------|---------------------|
| `assertion-failure` (≥1 targeted assertion failing — including mixed suites where some unchanged behaviors pass and ≥1 targeted behavior fails) | **Proceed** to the implementer dispatch with the `prewritten_red_tests:` signal set (Step 6) |
| `infrastructure-failure` (setup failure, missing binary, import/compilation error, timeout, or any non-assertion cause that prevented the suite from reaching assertion evaluation) | **Pause** with: `"infrastructure-failure: task=task-NN, adapter=<adapter-name>, framework=<framework>, stderr=<verbatim runner stderr>"`. |
| `pass` with zero targeted assertion failures (vacuous-RED) | **Pause** with: `"vacuous-RED: task=task-NN, adapter=<adapter-name>, framework=<framework>, classification=pass, targeted_failures=0"`. A `pass` token with zero targeted failures is NEVER a proceed signal — the TDD cycle has no RED step to verify; only a human can decide whether to re-run the test-writer or accept the gap. |

`infrastructure-failure` takes precedence over vacuous-RED detection: if classified `infrastructure-failure`, the gate pauses for infrastructure resolution before any vacuous-RED check runs.

#### Step 6 — Proceed: set `prewritten_red_tests:` and dispatch

On the `assertion-failure` proceed path, append `prewritten_red_tests:` to the implementer's dispatch parameters. The signal carries `output_dir:` (absolute path to the test-writer's output) and `framework:` (the reported framework name). `agents/qrspi-implementer.md` documents the split-mode behavior keyed on this signal — the implementer skips its own RED-authoring step and proceeds directly to GREEN/refactor against the prewritten tests.

#### Behavioral observability

End-to-end against a `task_type: code` task, the dispatch log records test-writer entry before implementer entry on the proceed path (Step 1 → Step 5 `assertion-failure` → Step 6). On the `infrastructure-failure`, vacuous-RED, adapter-classification-failure, or test-writer dispatch-failure pause paths, the gate halts with the named diagnostic and no implementer dispatch occurs. The lightweight bypass is observable as the absence of a test-writer dispatch line for the task.
