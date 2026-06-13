---
status: approved
task: 4
phase: 1
pipeline: full
goal_ids: [CD-2]
task_type: tdd
tier: high
---

# Task 04a: Add high-level entry mode to scripts/dispatch-agent.sh

- **Target files:** `scripts/dispatch-agent.sh` (Modify), `tests/unit/test-dispatch-agent-highlevel-mode.bats` (Create)
- **Dependencies:** T03
- **LOC estimate:** ~80
- **Description:** `scripts/dispatch-agent.sh` gains a high-level entry mode keyed on the presence of `--step <step> --round <N> --artifact-dir <path>` in addition to today's `--output-dir / --artifact / --agents` batched-mode flags. In high-level mode, dispatch-agent invokes `scripts/review-prep.sh` first and threads the produced paths into reviewer prompts as `diff_file_path:` and `absorption_map_path:` parameters. The existing low-level `--diff-file <path>` mode is preserved for tests and non-standard callers. review-prep failure propagates verbatim — dispatch-agent exits non-zero with review-prep's stderr.
- **Test expectations:**
  - Dispatch order: test-writer first, implementer second (RED-verification gate between).
  - High-level `--step --round --artifact-dir` invocation produces a dispatch byte-identical (in prompt content and manifest entries) to the equivalent low-level invocation with pre-computed paths — side-by-side bats fixture asserts byte-equality of the resulting prompt (CD-2 Acceptance bullet 2).
  - High-level mode threads `diff_file_path:` and `absorption_map_path:` (when applicable) into the dispatch prompt; a Design-step fixture proves both parameters appear, a Goals-step fixture proves only `diff_file_path:` appears.
  - review-prep failure causes dispatch-agent to exit non-zero with review-prep's stderr verbatim (CD-2 § Why this approach — single-exit-code shape).
  - The low-level `--diff-file <path>` mode remains functional — a regression-guard fixture invokes dispatch-agent with the explicit `--diff-file <path>` flag (no `--step/--round/--artifact-dir` triple), captures the resulting dispatch-prompt content, and asserts byte-equality against the v0.7.2 baseline prompt content for the equivalent invocation (proves the low-level mode's prompt-content contract is unchanged by the high-level mode addition).
  - Partial high-level flag combinations (e.g., `--step <step>` without `--round`, or `--step` + `--round` without `--artifact-dir`) cause visible failure — the script exits non-zero with a named diagnostic identifying which required flag is absent, never silently falling through to the low-level mode or producing an empty dispatch prompt (test-coverage-codex R6-F02 — caller-visible malformed-CLI behaviour is verifiable).
- **cross_task_consumers:**
  - `skills/goals/SKILL.md`, `skills/questions/SKILL.md`, `skills/research/SKILL.md`, `skills/design/SKILL.md`, `skills/phasing/SKILL.md`, `skills/structure/SKILL.md`, `skills/parallelize/SKILL.md`, `skills/replan/SKILL.md` (T05) — disposition: `pass-through` (T05 calls the new flag set in every artifact-step SKILL § Review Round; the dispatch-agent script itself is not edited by T05, and the consumer-side edits live in T05).
  - `scripts/review-prep.sh` (T03) — disposition: `pass-through` (this task's high-level mode invokes review-prep; review-prep's own contract handles its own failure direction per T03 and design.md CD-2 § Dependencies + edge cases).
