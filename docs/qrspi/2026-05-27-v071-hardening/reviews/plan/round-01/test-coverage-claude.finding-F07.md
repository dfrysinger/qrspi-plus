# Finding F07: Task 6 — Missing edge case: `COPILOT_CLI` set to a non-`1` non-empty value

**Artifact:** plan.md
**Task:** Task 6 (G6 part 1 — host-detection and Codex availability functions)
**Category:** Edge Cases
**Severity:** blocking

## Problem

Design DKR6 specifies:

> "Detection function probes `COPILOT_CLI=1` first"

The test expectations cover:
- `COPILOT_CLI=1` present → `copilot-cli` ✓
- `COPILOT_CLI` unset or set to empty → `claude-code` ✓

But they do not cover `COPILOT_CLI` set to a non-empty, non-`1` value (e.g., `COPILOT_CLI=0`, `COPILOT_CLI=false`, `COPILOT_CLI=yes`, `COPILOT_CLI=true`).

This gap is security-relevant: the detection function's correctness boundary is whether the exact string `1` is matched or whether any non-empty value matches. An implementation using `[[ -n "$COPILOT_CLI" ]]` instead of `[[ "$COPILOT_CLI" == "1" ]]` would pass all stated expectations while silently routing `COPILOT_CLI=0` (an operator explicitly disabling the flag) to the Copilot CLI branch, selecting the wrong transport and wrong model-routing column.

Operators who set `COPILOT_CLI=0` as a manual override to force the Claude Code path would silently get the wrong behavior.

## Recommendation

Add one expectation:

- "The host-identification function emits `claude-code` to stdout when `COPILOT_CLI` is set to any value other than the exact string `1` (e.g., `COPILOT_CLI=0`, `COPILOT_CLI=false`) — only the exact value `1` maps to `copilot-cli`."
