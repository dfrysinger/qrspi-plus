---
finding_id: R2-F02
severity: high
change_type: added
artifact: plan
round: 2
reviewer: quality-claude
referenced_files:
  - docs/qrspi/2026-05-27-v071-hardening/plan.md
  - docs/qrspi/2026-05-27-v071-hardening/structure.md
  - docs/qrspi/2026-05-27-v071-hardening/design.md
---

# R2-F02: Task 6 test expectation for `detect_host` with COPILOT_CLI=0 contradicts structure.md interface and design DKR6

## Location

`plan.md` → Task 6, Test expectations, new sub-expectation added in round 2 (diff line 94):

```
- `detect_host` with `COPILOT_CLI` set to any non-empty value other than `1` (e.g., `COPILOT_CLI=0`, `COPILOT_CLI=true`) returns non-zero and emits a single-line diagnostic to stderr naming the rejected value -- does NOT silently treat the value as `claude-code` or `copilot-cli`
```

## Observation

This new test expectation specifies that `detect_host` returns a **non-zero exit code** when `COPILOT_CLI` is set to a non-empty value other than `1`.

This directly contradicts two authoritative specs:

**Contradiction 1 — structure.md interface contract.** `structure.md` §Interfaces defines the `detect_host()` function signature:

```bash
# detect_host()
#
# Output: host identifier ("copilot-cli" or "claude-code") to stdout
# Returns: 0
# No arguments.
detect_host()
```

The interface explicitly states `Returns: 0` with no error-return case. The only output variants are `"copilot-cli"` and `"claude-code"` — no third signal is specified. A non-zero return for `COPILOT_CLI=0` is outside the interface's stated contract.

**Contradiction 2 — design DKR6 "otherwise defaults to Claude Code."** `design.md` DKR6 reads:

> Detection function probes `COPILOT_CLI=1` first (Copilot CLI host signal since v0.0.421 per research/q09-web.md); otherwise defaults to Claude Code.

"Otherwise defaults to Claude Code" covers all cases where `COPILOT_CLI` is not set to `1`, including `COPILOT_CLI=0`, `COPILOT_CLI=true`, and any other non-`1` value. Under DKR6, `COPILOT_CLI=0` must produce `claude-code` on stdout with a zero return — not an error.

## Why it matters

The plan's test expectation and the structure.md interface spec are logically incompatible. An implementer faces an unresolvable conflict:

- Implementing `detect_host` per the structure.md interface (always returns 0, outputs one of two known strings) causes the new test expectation to fail for `COPILOT_CLI=0`.
- Implementing `detect_host` per the plan's test expectation (non-zero return for `COPILOT_CLI=0`) causes the function to violate the structure.md interface contract that downstream callers (`check_codex_available`, skills prose) depend on.

The test-writer for `tests/unit/test-host-detection.bats` (Task 6) will write a test asserting non-zero return for `COPILOT_CLI=0`; the implementer will then face a failing test if they follow the structure interface. The most common resolution will be implementing the error path (following the test), which silently breaks the DKR6 design decision for all non-Copilot-CLI operators who happen to have an unrelated env var like `COPILOT_CLI=false` set in their shell.

The COPILOT_CLI env var is not a public API (goals.md notes it is "not documented as a public API in the README"). Treating any non-`1` non-empty value as an error rather than a Claude Code default would make the detection brittle against legitimate env-var name collisions.

## Suggested resolution

The test expectation should align with design DKR6's "otherwise defaults to Claude Code" rule:

```
- `detect_host` emits `claude-code` to stdout and returns 0 when `COPILOT_CLI` is unset, set to empty, or set to any value other than `1`
```

If the authoring intent was to add a diagnostic for unexpected `COPILOT_CLI` values WITHOUT changing the return code, the expectation should read:

```
- `detect_host` with `COPILOT_CLI` set to a non-empty value other than `1` emits `claude-code` to stdout (treating unrecognized values as the Claude Code default) and MAY emit a single-line informational message to stderr, but still returns 0 (does not error out)
```

The existing test expectation "`detect_host` emits `claude-code` to stdout when `COPILOT_CLI` is unset" should be extended to cover all non-`=1` cases, and the contradicting non-zero-return expectation should be removed or corrected.
