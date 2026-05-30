---
status: approved
task: 6
phase: 1
pipeline: full
goal_ids: [G6]
task_type: code
model: sonnet
---

# Task 6: Implement host-aware Codex availability detection in Codex dispatch helper

- **Target files:** `scripts/run-codex-review.sh` (modify), `tests/unit/test-host-detection.bats` (create)
- **Dependencies:** none
- **LOC estimate:** ~100
- **Description:** Two new functions are added to `scripts/run-codex-review.sh`: a host-identification function (`detect_host`) that probes the `COPILOT_CLI` environment variable and emits either `copilot-cli` or `claude-code` to stdout (always returning exit code 0 -- a 2-branch probe per DKR6), and a per-host Codex availability check (`check_codex_available`) that returns success under Copilot CLI (where Codex is a natively routable model requiring no filesystem probe) and under Claude Code probes the companion-script glob path. Each dispatch-transport selection path emits a one-line trace marker to stderr at dispatch time: `[transport: shell-pipeline]` when the Claude Code shell-pipeline path is selected, and `[transport: task-tool]` when the Copilot CLI native task-tool path is selected. When the detected host disagrees with the `codex_reviews` config value, the dispatch surface emits a single line to stderr identifying the disagreement, then continues with the configured policy. The mismatch diagnostic does not change exit code or block dispatch. These two functions are the single shared host-probe implementation required by Design DKR10; Task 7 (SKILL prose) and Task 10 (model_routing prose) both reference this implementation. A new unit test file covers both functions under mocked environment signals. Both functions are bash-3.2 portable (no nameref, no `declare -A` outside functions, no `$'...'` ANSI-C strings); the CI bash-3.2 job is the enforcement surface. The transport-marker and mismatch-diagnostic assertions exercise the dispatch-surface helper in `scripts/run-codex-review.sh` (the code path that calls `detect_host` and `check_codex_available` and selects transport); structure.md does not assign this path an explicit function name. Dispatch order: test-writer first, implementer second (RED-verification gate between).
- **Test expectations:**
  - `detect_host` emits `copilot-cli` to stdout and exits 0 when `COPILOT_CLI=1` is present in the environment
  - `detect_host` emits `claude-code` to stdout and exits 0 when `COPILOT_CLI` is unset
  - `detect_host` emits `claude-code` to stdout and exits 0 when `COPILOT_CLI` is set to the empty string (`COPILOT_CLI=""`)
  - `detect_host` emits `claude-code` to stdout and exits 0 when `COPILOT_CLI` is set to a non-empty value other than `1` (e.g., `COPILOT_CLI=0`, `COPILOT_CLI=true`, `COPILOT_CLI=yes`)
  - The 2-branch probe accepts only the literal string `1` as the Copilot CLI signal per design DKR6; all other states (unset, empty, or any non-`1` value) default to Claude Code
  - When `COPILOT_CLI_BINARY_VERSION` is set (to any value) but `COPILOT_CLI` is not `=1`, `detect_host` emits `claude-code` to stdout -- `COPILOT_CLI_BINARY_VERSION` alone is not a host-detection trigger
  - `detect_host` output is determined solely by `COPILOT_CLI`'s value; the presence or absence of other environment variables does not affect the result.
  - `check_codex_available` returns exit code 0 (success) when called with `copilot-cli` as the host argument, without requiring any filesystem path to exist
  - `check_codex_available` returns exit code 0 (success) when called with `claude-code` and the companion-script glob resolves to at least one existing file path
  - `check_codex_available` returns a non-zero exit code when called with `claude-code` and the companion-script glob resolves to no file paths
  - `check_codex_available` called with an unrecognized host argument returns non-zero and emits a single-line diagnostic to stderr identifying the unsupported host value
  - Under a mocked mismatch between `detect_host` output and the `codex_reviews` config value, the dispatch surface emits a single line to stderr that names both the detected host value (e.g., `claude-code`) and the `codex_reviews` config value (e.g., `true`) so an operator can act on the disagreement. The mismatch is a warning signal only -- the mismatch warning does not override the dispatch exit code; the exit code propagated to the caller is the exit code returned by the underlying dispatch, and dispatch is not blocked.
  - When the dispatch surface selects the Claude Code shell-pipeline path (detected host = `claude-code`), `[transport: shell-pipeline]` appears exactly once in stderr and `[transport: task-tool]` is absent (asserted in `tests/unit/test-host-detection.bats`)
  - When the dispatch surface selects the Copilot CLI task-tool path (detected host = `copilot-cli`), `[transport: task-tool]` appears exactly once in stderr and `[transport: shell-pipeline]` is absent (asserted in `tests/unit/test-host-detection.bats`)
  - Neither function writes to stderr under normal (non-error) operation
  - When the dispatch-surface helper (correctly-routed, Codex available) invokes a mocked transport command that exits with a non-zero exit code, the dispatch surface propagates that same non-zero exit code to the caller -- no suppression, no log-and-continue.
  - When the dispatch-surface detects a mismatch (warning emitted) and then invokes a mocked transport that exits with a non-zero exit code, the dispatch surface propagates that same non-zero exit code to the caller. The mismatch warning path does not suppress dispatch failures.
