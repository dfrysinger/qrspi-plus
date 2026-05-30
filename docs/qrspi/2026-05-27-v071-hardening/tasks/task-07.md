---
status: approved
task: 7
phase: 1
pipeline: full
goal_ids: [G6]
task_type: code
model: opus
---

# Task 7: Update using-qrspi skill with per-host Codex dispatch transport routing

- **Target files:** `skills/using-qrspi/SKILL.md` (modify), `tests/acceptance/v07-phase1/test-phase1-acceptance.bats` (modify)
- **Dependencies:** Task 6
- **LOC estimate:** ~90
- **Description:** The Codex detection section in `skills/using-qrspi/SKILL.md` is updated to name both dispatch transports explicitly with per-host conditional prose. Under Copilot CLI the dispatch uses the native task tool with `agent_type: code-review` and `model: gpt-5.3-codex`. Under Claude Code the dispatch uses the shell pipeline via `scripts/run-codex-review.sh`. The skill prose documents that when the detected host output disagrees with the `codex_reviews` config value, the dispatch surface (implemented in Task 6) emits a single-line diagnostic to stderr identifying the disagreement and continues with the configured policy; the mismatch diagnostic does not gate dispatch. The acceptance test gains end-to-end host-detection assertions exercising the dispatch surface under mocked conditions for each host path; each assertion verifies the transport-distinguishing trace marker emitted by the dispatch surface (per the trace markers added in Task 6) rather than only a success signal. Dispatch order: test-writer first, implementer second (RED-verification gate between).
- **Test expectations:**
  - `skills/using-qrspi/SKILL.md` Codex detection section contains conditional prose that explicitly names both the Copilot CLI task-tool transport and the Claude Code shell-pipeline transport
  - The SKILL prose specifies `agent_type: code-review` and `model: gpt-5.3-codex` as the parameters for Copilot CLI Codex dispatch
  - The SKILL prose names `scripts/run-codex-review.sh` as the Claude Code Codex dispatch mechanism
  - `skills/using-qrspi/SKILL.md` contains prose documenting that when the detected host disagrees with the `codex_reviews` config value, the dispatch surface emits a single-line diagnostic to stderr identifying the disagreement and continues with the configured policy; the mismatch diagnostic does not gate dispatch
  - With `COPILOT_CLI=1` set, the acceptance test asserts the dispatch surface emits the `[transport: task-tool]` marker to stderr exactly once and does not emit the `[transport: shell-pipeline]` marker (exercising a mocked Codex dispatch via the task tool wrapper)
  - With `COPILOT_CLI` unset and the shell pipeline via `scripts/run-codex-review.sh` mocked, the dispatch surface emits the `[transport: shell-pipeline]` marker to stderr exactly once and does not emit the `[transport: task-tool]` marker
  - When `check_codex_available` returns non-zero for the detected host, the dispatch surface emits a single-line diagnostic to stderr and propagates non-zero exit (no log-and-continue)
  - The acceptance test assertion for the Copilot CLI path passes when `COPILOT_CLI=1` is set and fails (RED) when it is absent
  - The acceptance test assertion for the Claude Code path passes when `COPILOT_CLI` is unset and fails (RED) when the Copilot CLI signal is active
  - For the Copilot CLI path: the mocked task-tool dispatch exits with code 0 and captured stdout contains a distinguishable marker string emitted by the mock transport (a value the mock produces and no other code path produces), proving the dispatch invoked the mock rather than falling back; exit code 0 alone is insufficient proof.
  - For the Claude Code path: the mocked `scripts/run-codex-review.sh` dispatch exits with code 0 and captured stdout contains a distinguishable marker string emitted by the mock transport (a value the mock produces and no other code path produces), proving the dispatch invoked the mock rather than falling back; exit code 0 alone is insufficient proof.
  - When the mocked transport command (correctly-routed, Codex available) exits with a non-zero exit code, the dispatch surface propagates that same non-zero exit code to the caller -- no suppression, no log-and-continue.
  - When the dispatch-surface detects a mismatch (warning emitted) and then invokes a mocked transport that exits with a non-zero exit code, the dispatch surface propagates that same non-zero exit code to the caller. The mismatch warning path does not suppress dispatch failures.
