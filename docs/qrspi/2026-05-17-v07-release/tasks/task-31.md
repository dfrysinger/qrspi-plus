---
task: 31
status: approved
pipeline: full
task_type: lightweight
model: sonnet
phase: 1
goal_ids: [G3]
dependencies: [T24]
loc_estimate: 110
---

# Task 31: Plan-skill post-approval split orchestration with N-threshold carve-out

- **Phase:** 1
- **Target files:**
  - `skills/plan/SKILL.md` (Modify) — add the post-approval split orchestration section that fans approved per-task spec authoring out to sub-subagents, declare the N-threshold carve-out (N >= 3 dispatches sub-subagents in parallel; N <= 2 performs the split inline in main chat), and retain the main-chat transactional steps (sub-subagent confirmation collection, file-count verification, `plan.md` overview-only rewrite, `phase_start_commit:` capture, `status: approved` write) so downstream skills never see an approved `plan.md` without corresponding `tasks/task-NN.md` files on disk.
- **Dependencies:** T24
- **LOC estimate:** ~110
- **Description:** Adds a post-approval split orchestration section to `skills/plan/SKILL.md` that replaces the current main-chat per-task spec writing with a sub-subagent fan-out reusing the generation-side dispatch shape already documented in the skill, closing the Plan post-approval split-via-subagent gap captured in qrspi-plus issue #172 and realizing design decision G3. The orchestration section declares the N-threshold carve-out explicitly: when the approved `plan.md` overview enumerates N >= 3 tasks the skill dispatches one sub-subagent per task in parallel, each consuming the merged `plan.md` task section as wrapped input plus the canonical task-file template (now carrying the Slice 5 spec frontmatter shape established by T24) plus the G7 ID-hygiene contract, and each writing exactly one `tasks/task-NN.md` file without editing `plan.md`; when N <= 2 the skill performs the split inline in main chat because sub-subagent dispatch overhead exceeds the context saving below that threshold (combined two-task plan + specs estimated at under 600 lines per design line 157). The main chat retains the transactional ordering — collect sub-subagent confirmations, verify the resulting `tasks/task-NN.md` file count matches the expected task count, rewrite `plan.md` to overview-only, capture `phase_start_commit:` in `plan.md` frontmatter, then write `status: approved` to `plan.md` frontmatter — so an approved `plan.md` is never observable on disk without all corresponding task files present. This task is the single touch on `skills/plan/SKILL.md` for Slice 6 and is co-aligned with T24 (Slice 5), which edits the same SKILL.md to add the per-task spec frontmatter shape; T24 lands first so T31's orchestration reasons over the finalized frontmatter shape carried into each sub-subagent's task-file template payload, avoiding a double-touch on the file within the same wave.
- **Test expectations:**
  - The post-approval split section in `skills/plan/SKILL.md` documents the N-threshold carve-out, stating N >= 3 triggers sub-subagent fan-out and N <= 2 triggers inline main-chat split.
  - The section enumerates the per-sub-subagent input payload (wrapped `plan.md` task section, canonical task-file template, G7 ID-hygiene contract) and the per-sub-subagent output contract (exactly one `tasks/task-NN.md` per dispatch; no `plan.md` edits).
  - The section preserves the main-chat transactional steps in order: collect confirmations, verify file count, rewrite `plan.md` to overview-only, capture `phase_start_commit:`, write `status: approved`.
  - The verification step checks the EXACT SET of `tasks/task-NN.md` files present after the fan-out — specifically that `{task-01.md, task-02.md, ..., task-N.md}` is exactly the expected set with no duplicates and no missing IDs — not only that N files exist. A duplicate-ID condition (two sub-subagents writing the same `task-NN.md`) or a missing-ID condition (gaps in the expected set) is detected and surfaces a loud diagnostic naming the duplicated or missing IDs, aborting the split rather than proceeding with mismatched files.
  - The section states the carve-out rationale (sub-subagent overhead exceeds context saving below N=3) so the threshold is defensible against future tuning.
  - The orchestration section reuses the generation-side sub-subagent dispatch shape already declared elsewhere in `skills/plan/SKILL.md` rather than introducing a parallel dispatch grammar.
  - The Slice 5 spec frontmatter fields introduced by T24 (`reference_gate:`, `reference_artifact:`, `ui:`, `lift_source:`) appear in the canonical task-file template carried into each sub-subagent payload so the post-approval split emits frontmatter-complete `tasks/task-NN.md` files.
  - When a task spec carries `conditional: true` and a `conditional_precondition:` value (the T43 conditional-dispatch fields documented in the `## Task Specs` preamble), the sub-subagent payload template includes both fields verbatim and the emitted `tasks/task-NN.md` file carries both fields verbatim in its frontmatter so the Implement orchestrator can evaluate the precondition at dispatch time.
