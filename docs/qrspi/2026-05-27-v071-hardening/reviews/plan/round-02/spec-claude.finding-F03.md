---
finding_id: F03
severity: major
task: Task 6
goal_ids: [G6]
category: interpretation
round: 2
---

# F03 — Task 6 detect_host behavior for COPILOT_CLI=non-1 contradicts Design DKR6

## Summary

Task 6 specifies that `detect_host` returns **non-zero with a stderr diagnostic** when
`COPILOT_CLI` is set to any non-empty value other than `1` (e.g., `COPILOT_CLI=0`,
`COPILOT_CLI=true`). Design DKR6 and the DKR6 mermaid diagram both specify that
`detect_host` **defaults to Claude Code** for any non-Copilot-CLI signal — explicitly including
the Codex CLI host (which would arrive via a non-1 `COPILOT_CLI` value or no value at all). The
plan introduces a third error-on-unexpected-value branch that is not in the design and that
contradicts the design's "otherwise defaults to Claude Code" fall-through.

## Detail

**Design DKR6 (verbatim):**
> Detection function probes `COPILOT_CLI=1` first (Copilot CLI host signal since v0.0.421);
> **otherwise defaults to Claude Code**. Standalone Codex CLI as a host is explicitly out of scope
> for v0.7.1 (per `goals.md` G6 deferral); a Codex-CLI host falls through to the Claude Code branch.

**Design mermaid diagram (DKR6 subgraph):**
```
A1["COPILOT_CLI=1?"] -->|yes| H_COPILOT["Host = Copilot CLI"]
A1 -->|no| H_CLAUDE["Host = Claude Code (default; Codex CLI host out of scope for v0.7.1)"]
```

The design specifies exactly two branches: `COPILOT_CLI=1` → Copilot CLI; anything else (including
`COPILOT_CLI=0`, `COPILOT_CLI=true`, and `COPILOT_CLI` unset) → Claude Code.

**Task 6 test expectation (verbatim):**
> `detect_host` with `COPILOT_CLI` set to any non-empty value other than `1` (e.g.,
> `COPILOT_CLI=0`, `COPILOT_CLI=true`) returns non-zero and emits a single-line diagnostic to
> stderr naming the rejected value -- does NOT silently treat the value as `claude-code` or
> `copilot-cli`

This introduces a third branch — error-on-unexpected-value — that DKR6 does not permit.

## Why This Matters

The value `COPILOT_CLI=0` is a plausible explicit signal meaning "this process is NOT a Copilot CLI
subprocess." CI pipelines and test harnesses that set `COPILOT_CLI=0` to explicitly suppress
Copilot-CLI signals (analogous to how `CI=true` suppresses interactive prompts) would receive a
non-zero exit with a diagnostic instead of the designed claude-code fallback. This can silently
break test environments and CI scripts.

Additionally, DKR6 explicitly places "a Codex-CLI host falls through to the Claude Code branch" —
meaning even if a future Codex CLI sets some variant of COPILOT_CLI (e.g., unset or =0), the
designed behavior is to fall through, not to error. The plan's error-on-unexpected-value behavior
blocks that fall-through.

## Required Fix

Remove the `COPILOT_CLI=non-1` error expectation and replace it with a fall-through expectation
consistent with DKR6:

**Remove:**
> `detect_host` with `COPILOT_CLI` set to any non-empty value other than `1` (e.g.,
> `COPILOT_CLI=0`, `COPILOT_CLI=true`) returns non-zero and emits a single-line diagnostic to
> stderr naming the rejected value

**Replace with:**
> `detect_host` emits `claude-code` to stdout when `COPILOT_CLI` is set to any non-1 value
> (including `COPILOT_CLI=0`, `COPILOT_CLI=false`, or any other non-1 string) — consistent with
> DKR6's "otherwise defaults to Claude Code" fall-through semantics

The mismatch diagnostic described in the remainder of Task 6 and Task 7 is for a different
condition: when `detect_host` output disagrees with the `codex_reviews` config value. That
diagnostic belongs at the dispatch surface (which Task 6 correctly implements), not inside
`detect_host` itself.
