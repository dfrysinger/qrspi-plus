---
round: 04
artifact: design
status: fixing
---

# Round 04 dispositions

## Findings inventory

- quality-claude: 2 findings (medium=2)
- scope-claude: 0 findings (clean sentinel)
- quality-codex: 2 findings (high=1, medium=1)
- scope-codex: 0 findings (clean sentinel)

Total: 4 findings. Round trend: 10 → 3 → 5 → 4. Findings are getting more nuanced (deeper-pass omissions earlier rounds missed); not regression.

## Verifier skipped this round

`verifier_enabled: true`. All 4 findings cite concrete file:line and load-bearing defects. Recording the skip.

## Scope-tagger skipped this round

Artifact not in git → no diff to narrow. Recording the skip.

## Per-finding dispositions

All 4 findings classified `accept` and queued for fix.

### Cross-reviewer match — G6 dispatch contract underspecified

quality-codex R4-F02 (high) and quality-claude R4-F02 (medium) target the same defect from two angles:
- **codex** focuses on the runtime contract conflict: existing implementer TDD writes its own RED tests; G6 splits test-writing into qrspi-test-writer; design doesn't say who verifies tests fail, doesn't say what the implementer does with prewritten failing tests.
- **claude** focuses on the dispatch parameter set + two-mode agent-body behavior being unspecified.

Fix once, both resolved.

**Fix:** Expand G6 "Dispatch shape on the TDD path" with an explicit Implement-phase contract subsection covering:

1. **qrspi-test-writer Implement-phase mode (signal: `task_definition` present).**
   - Dispatch parameters: `task_definition` (the task spec), `companion_goals`, `companion_codebase_context` (target files identified in the task spec), `output_dir` (where the task's test files land per Structure's file map). No `companion_plan` (Plan provides per-task spec via `task_definition`); no `companion_design_or_research` (Implement-phase scope is per-task, not phase-level); no `companion_fix_history` (initial-dispatch only — fix-cycle dispatches re-use the round-1 inputs and add a defect summary, per existing reviewer pattern).
   - Behavior in this mode: write unit/integration tests that fail against the un-implemented task spec. The agent does NOT run the tests; it writes them to `output_dir`.
2. **qrspi-test-writer Test-phase mode (signal: `task_definition` absent).**
   - Existing parameter set unchanged (`companion_plan`, `companion_goals`, `companion_design_or_research`, `companion_fix_history`, `companion_codebase_context`, `output_dir`).
   - Behavior unchanged.
3. **qrspi-implementer behavior in split mode.**
   - When dispatched after qrspi-test-writer for a TDD task, the implementer treats prewritten failing tests in `output_dir` as the RED input. The implementer does NOT author duplicate RED tests. Its TDD cycle becomes: verify the test-writer's tests fail → write production code to turn them green → refactor if needed.
4. **Verification that RED tests fail before implementer dispatch.**
   - Implement (orchestrator) runs the test-writer's tests once before dispatching qrspi-implementer. If any pre-implementation test passes (i.e., the test is vacuous or accidentally already satisfied), the orchestrator pauses with a load-bearing diagnostic; the user inspects the test and either fixes it via a fix-task or skips. This is the load-bearing pre-implementer gate.

Add a matching design-level test bullet under G6:
- "Pre-implementer RED-verification test: a task with `task_type: code` produces test-writer dispatch → orchestrator-side test run → all tests fail → implementer dispatch. If any test passes pre-implementation, orchestrator pauses."

### R4-F01 quality-codex (medium) — routing schema split (model identifier home)

`providers:` currently says "endpoint URL, model identifier, env var" AND `model_routing:` says "maps roles to concrete provider + model pairs". Two homes for the model identifier. Plan can't deterministically resolve.

**Fix:** Make `model_routing:` the single source of truth for model name. Rewrite the affected G1 sentences:
- `providers:` carries endpoint URL, env var name for the API key, and optional default headers. Model identifier does NOT live in `providers:`.
- `model_routing:` carries entries of the form `<role>: { provider: <provider-name>, model: <model-id> }`. The `model:` value names the concrete model identifier.
- Optionally, `providers:` may carry `default_model:` for the case where every routing entry for that provider would use the same model (the entry's `model:` value still overrides if present).

Update G2's mention of provider config (line ~91) so it also says provider = endpoint + auth metadata, model identifier comes from the `--model` flag (which the calling skill sources from `model_routing:` per G1).

Update Decision 1 wording if it mentions providers carrying model identifier; trace via grep.

### R4-F01 quality-claude (medium) — G12 commit sequence drops status-check + SHA-capture

Round-3 fix introduced a 4-step commit sequence that reads as a complete replacement but silently drops two load-bearing steps from the existing 5-step `implementer-protocol/SKILL.md` Commit Before Reporting procedure: `git status --porcelain` guard (step 1) and `git rev-parse HEAD` SHA capture (step 5).

**Fix:** Replace the 4-step list with the full canonical sequence and explicitly mark which step was reordered. Use option (b) from the finding — restate the full 6-step procedure:

1. `git status --porcelain` — nothing-to-commit guard. On empty, branch to `BLOCKED` or `DONE_WITH_CONCERNS` per the existing protocol; do NOT commit.
2. Stage tracked work: `git add -A`.
3. Write commit message to `<worktree>/.qrspi-commit-msg.txt`.
4. Commit: `git commit -F <worktree>/.qrspi-commit-msg.txt`.
5. Post-commit cleanup: remove the scratch file `<worktree>/.qrspi-commit-msg.txt`.
6. Capture commit SHA: `git rev-parse HEAD` → emit as `commit_sha:` in the terminal-status report.

Note that step 5 (scratch removal) is the round-1 reorder relative to the prior protocol; the rest is unchanged. The `.git/info/exclude` entry from G12's primary defense is added during worktree setup, independent of this sequence.

Update G12's test strategy bullets to match (the existing "Commit-cycle test" should verify all six steps run in order).

## Fix dispatch plan

Single fix subagent. Subagent receives:
- Path to design.md
- Paths to the 4 finding files
- Per-finding fix guidance above

Subagent reports diff summary. Round 5 reviewers fire after fix-subagent confirmation.

## Status

draft → fixing → (post-fix) → re-review round 05.
