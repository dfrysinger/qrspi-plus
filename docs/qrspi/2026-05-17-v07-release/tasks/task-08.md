---
task: 8
status: approved
pipeline: full
task_type: lightweight
model: sonnet
phase: 1
goal_ids: [G6]
dependencies: [T01]
loc_estimate: 140
---

# Task 08: Dual-mode qrspi-test-writer agent body

- **Phase:** 1
- **Target files:**
  - `agents/qrspi-test-writer.md` (Modify) — author the dual-mode contract keyed on `task_definition` presence and add the `model_role: test-writer` frontmatter alongside the existing concrete `model:` value.
- **Dependencies:** T01
- **LOC estimate:** ~140
- **Description:** Extends `agents/qrspi-test-writer.md` so a single agent body serves both the Implement-phase per-task mode (signal: `task_definition` present in the dispatch payload) and the existing Test-phase plan-level mode (signal: `task_definition` absent). The edit adds the H2 sections `## Purpose`, `## Pre-Flight`, `## Mode: implement-phase (per-task)`, `## Mode: test-phase (plan-level)`, `## Output Contract`, and `## Dispatch Signal Resolution`, with the resolution section documenting that mode selection branches on `task_definition` presence in the dispatch payload (mirroring the per-task reviewer dual-mode pattern). The Implement-phase mode consumes `task_definition`, `companion_goals`, `companion_codebase_context`, and `output_dir` and writes per-task failing tests against the un-implemented task spec without running the tests. The Test-phase mode preserves the existing parameter set (`companion_plan`, `companion_goals`, `companion_design_or_research`, `companion_fix_history`, `companion_codebase_context`, `output_dir`) and behavior unchanged. The frontmatter adds `model_role: test-writer` alongside the existing concrete `model:` value so the G1 layer-2 role-resolution chain can route the test-writer half independently per the config schema landed in T01.
- **Test expectations:**
  - The agent file's frontmatter carries both `model_role: test-writer` and a concrete `model:` value (activation-time fallback preserved).
  - The `## Dispatch Signal Resolution` section names `task_definition` presence as the load-bearing mode-selection signal.
  - The `## Mode: implement-phase (per-task)` section enumerates the Implement-phase parameter set and states the agent does not run the tests it writes.
  - The `## Mode: test-phase (plan-level)` section preserves the existing Test-phase parameter set and behavior verbatim.
  - All six required H2 sections (`## Purpose`, `## Pre-Flight`, `## Mode: implement-phase (per-task)`, `## Mode: test-phase (plan-level)`, `## Output Contract`, `## Dispatch Signal Resolution`) are present.
  - The `## Dispatch Signal Resolution` section states that `task_definition` validity requires both presence AND a non-empty (non-whitespace) value: a present-but-empty (empty string, null, or whitespace-only) `task_definition` is treated as invalid and the agent (or the dispatch site) exits 1 with a named "empty-task-definition" diagnostic before any test authoring begins. Present-and-non-empty selects Implement-phase mode; absent selects Test-phase mode; present-and-empty fails loudly. T13's `test-test-writer-dual-mode.bats` exercises the empty-string `task_definition` fixture and asserts the loud-failure path.
