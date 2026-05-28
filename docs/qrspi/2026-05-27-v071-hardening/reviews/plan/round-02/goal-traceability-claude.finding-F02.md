---
finding_id: F02
reviewer: goal-traceability-claude
round: 2
severity: high
artifact: plan.md
section: "Task 6: Implement host-aware Codex availability detection in Codex dispatch helper"
checklist_item: "4. Spec-to-Design Fidelity — task spec introduces behavior not in design.md or structure.md"
---

# F02 — Task 6 `detect_host` test expectation contradicts approved design DKR6 and structure.md interface contract

## Problem

A new test expectation added in round 2 specifies that `detect_host` returns **non-zero
and emits a stderr diagnostic** when `COPILOT_CLI` is set to any non-empty, non-`1`
value (e.g., `COPILOT_CLI=0`, `COPILOT_CLI=true`). This behavior is not in the approved
design and directly contradicts two authoritative upstream documents.

**The round-2 test expectation (Task 6):**

> `detect_host` with `COPILOT_CLI` set to any non-empty value other than `1`
> (e.g., `COPILOT_CLI=0`, `COPILOT_CLI=true`) returns non-zero and emits a
> single-line diagnostic to stderr naming the rejected value — does NOT silently
> treat the value as `claude-code` or `copilot-cli`

## Contradiction 1 — design.md DKR6 (approved)

`design.md` § DKR6 states:

> **Decision:** Detection function probes `COPILOT_CLI=1` first (Copilot CLI host
> signal since v0.0.421 per `research/q09-web.md`); otherwise **defaults to Claude
> Code**. Standalone Codex CLI as a host is explicitly out of scope for v0.7.1;
> a Codex-CLI host falls through to the Claude Code branch.

"Otherwise defaults to Claude Code" is unambiguous: any value other than `COPILOT_CLI=1`
— including `COPILOT_CLI=0` and `COPILOT_CLI=true` — should cause the function to emit
`claude-code` (not return non-zero). The plan test expectation reverses this default,
turning an ambiguous-but-valid env-var state into a hard error.

## Contradiction 2 — structure.md interface contract (approved)

`structure.md` § `detect_host` interface:

```bash
# detect_host()
#
# Output: host identifier ("copilot-cli" or "claude-code") to stdout
# Returns: 0
# No arguments.
detect_host()
```

"Returns: 0" is the sole documented return code; no non-zero case is listed. The
round-2 test expectation introduces a non-zero return path that the approved structure
contract does not describe.

## Impact

An implementer following design.md DKR6 and structure.md will build a `detect_host`
that returns `claude-code` (exit 0) for `COPILOT_CLI=0`. The test writer following
the round-2 plan test expectation will write a test that asserts `detect_host` returns
non-zero for `COPILOT_CLI=0`. The resulting test will fail RED against the
design-compliant implementation and cannot reach GREEN without deviating from the
upstream approved documents.

This is also a security-surface concern: rejecting `COPILOT_CLI=0` with a hard error
means any environment that sets `COPILOT_CLI=0` as a defensive flag (e.g., to disable
Copilot CLI detection deliberately) will cause the dispatch to abort rather than fall
back to Claude Code, which DKR6 explicitly intended as the safe default.

## Suggested resolution

Replace the round-2 test expectation with behavior consistent with DKR6 and the
structure.md interface:

> `detect_host` emits `claude-code` to stdout and returns exit code 0 when
> `COPILOT_CLI` is set to any value other than `1` — including when set to
> an empty string, `0`, or `true` — treating these as "not Copilot CLI" per
> design DKR6 ("otherwise defaults to Claude Code")

If the authors intend to tighten the behavior (rejecting ambiguous values) relative
to the approved design, that change requires an amendment to design.md DKR6 and
structure.md `detect_host` interface before it can be expressed as a plan test
expectation. The current state creates an unresolvable contradiction for the
implementer and test writer.
