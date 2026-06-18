# Implement Phase-Entry Detail

Read this file once per phase entry (full pipeline) or once per quick-fix batch (quick mode), after the smoke check and task-count read have passed and before per-task dispatch begins. It is not re-read on fix-task dispatches within the same phase — those reuse `config.md` and the already-prepared feature branch.

This file consolidates the one-shot entry concerns: run-entry artifact preconditions, config validation, phase-level configuration prompt, subagent permissions guidance, and baseline-tests handling.

## Run-Entry Artifact Preconditions

Required inputs must exist and be approved before Implement dispatches anything. Mode-dependent (derived from `config.md.route`):

- **Full pipeline:** `parallelization.md`, `plan.md`, `tasks/*.md` (or `fixes/{type}-round-NN/*.md`), `design.md`, `phasing.md`, `structure.md`, `config.md`.
- **Quick fix:** `plan.md`, `tasks/*.md` (or `fixes/{type}-round-NN/*.md`), `goals.md`, `research/summary.md`, `config.md`.

If any required artifact is missing or not approved, refuse to run and name it.

Per-task prompt composition (which subset of inputs rides in each subagent prompt based on the task's `pipeline:` field) is a separate concern — see implement/SKILL.md § Per-Task Input Routing (Prompt Composition).

## Config Validation

Per `using-qrspi/references/config-runtime-contract.md` § Config Validation Procedure. Implement validates `route`, `second_reviewer`, and (after Phase-Level Configuration) `review_depth` and `review_mode`.

## Phase-Level Configuration (Runtime)

`review_depth` and `review_mode` are runtime concerns. At Implement entry (per phase in full pipeline; per quick-fix batch in quick mode), ask:

1. **Review depth** — Quick (4 correctness reviewers) or Deep (all 8).
2. **Review mode** — Single round or Loop until clean.

Write to `config.md` as `review_depth` and `review_mode`. Fix-task dispatches reuse — do not re-ask. Source of truth is `config.md`.

## Subagent Permissions

Subagent containment is the runtime sandbox's responsibility (auto-mode plus the host runtime's judgment); there is no in-pipeline worktree wall. Subagents should be dispatched with the task's worktree path `.worktrees/{slug}/task-NN[a-z]?/` named in the prompt and treat that path as their working scope. The optional `[a-z]?` letter suffix supports Plan-induced task splits like `task-07a`/`task-07b`.

**Recommended:** run sessions with `--dangerously-skip-permissions` enabled so per-tool approval prompts do not stall subagents.

## Baseline Tests

Run baseline tests in a single throwaway worktree at `.worktrees/{slug}/baseline/` (forked from the feature branch tip). If a prior baseline worktree exists from a halted run, delete it first.

If tests fail, present failure summary with 3 options:

- **(a) Auto-fix (recommended):** Inject baseline fix task `task-00` with all others depending on it. Implement writes `task-00.md` with `status: approved` (runtime-generated; approval asserted so the Iron Law gate passes on dispatch). `task-00` uses `task: 0` and inherits the run's mode in `pipeline:`.
    - **Full pipeline:** Append one row to the Branch Map (`task-00 → qrspi/{slug}/task-00 (base: feature branch tip)`) without rewriting existing rows. Append a `## Runtime Adjustments` section listing tasks whose effective base changed. Implement reads the Branch Map first, then applies `## Runtime Adjustments` overrides on top. Repeated failures inject `task-00b`, `task-00c`, etc.
    - **Quick fix:** `task-00` is its own isolated dispatch event — no Branch Map, no `## Runtime Adjustments`. Write `tasks/task-00.md` with `status: approved`, dispatch as a standalone event with task set `{tasks/task-00.md}`, then dispatch the originally-requested task set as a separate event (excluding the runtime-written singletons).
- **(b) Proceed anyway:** Log failures to `reviews/baseline-failures.md`.
- **(c) Stop:** Halt the pipeline.

**Invariant — baseline worktree gone before any per-task worktree exists.** Auto-fix deletes it as the first sub-step of Process Step 5; Proceed-anyway deletes it immediately after writing `reviews/baseline-failures.md`; Stop requires no deletion.
