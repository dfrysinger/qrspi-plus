---
finding_id: R2-F05
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/plan.md:L336-L348]
artifact: plan
round: 2
reviewer: silent-failure-claude
---

T08 describes the dual-mode qrspi-test-writer agent with mode selection keyed on "`task_definition` presence in the dispatch payload." "Presence" is the binary signal: present = Implement-phase mode, absent = Test-phase mode.

The test expectations require that "The `## Dispatch Signal Resolution` section names `task_definition` presence as the load-bearing mode-selection signal." This tests that the contract is documented, not that the agent fails closed when `task_definition` is present but empty (empty string, null, or whitespace-only).

If `task_definition` is dispatched with an empty-string value, the binary presence check routes the agent into Implement-phase mode with an empty task spec. The agent would then write per-task failing tests against a null/empty spec — producing either trivially vacuous tests (that may pass the RED-verification gate because they target nothing) or completely absent tests (if the agent detects the empty spec and produces no output). In neither case does the caller know that `task_definition` was empty: the dispatcher receives the test-writer output and routes to the RED gate without surfacing the empty-spec condition as an error.

This is a silent fallback by design: present-but-empty `task_definition` is treated as a valid Implement-phase dispatch, allowing downstream RED-verification to proceed against a vacuous test set.

Resolution: Add a test expectation to T08 stating that the agent (or the dispatch site) must validate that `task_definition` when present is non-empty (non-whitespace), and that an empty-string `task_definition` exits 1 with a named diagnostic before any test authoring begins. The fix should also add a corresponding test case to T13's `test-test-writer-dual-mode.bats` (or a new expectation in T13's test list) that exercises empty-string `task_definition` and asserts the loud failure path.
