---
id: F02
reviewer: security-claude
round: 1
severity: low-medium
category: fail-closed
task: Task 6 (G6)
status: open
---

# F02: `check_codex_available()` has no fail-closed test expectation for unrecognized host argument

## What the plan says

Task 6 test expectations for `check_codex_available()` are:

> Returns exit code 0 (success) when called with `copilot-cli` as the host argument, without requiring any filesystem path to exist
> Returns exit code 0 (success) when called with `claude-code` and the companion-script glob resolves to at least one existing file path
> Returns a non-zero exit code when called with `claude-code` and the companion-script glob resolves to no file paths

The structure.md interface spec for the function:

```bash
# $1  host -- output of detect_host
# Returns: 0 (Codex reachable on this host)
#          non-zero (not reachable)
```

## The gap

No test expectation covers the case where `$1` is an unrecognized value — not `copilot-cli`, not `claude-code`, and not empty.

If the function is implemented as a `case`/`if-else` with no `*)` default branch, bash's implicit exit code after a non-matching case statement is the exit code of the last executed command before the case, which is typically 0. This means an unrecognized host value falls through and returns 0 (Codex available), causing the subsequent dispatch to proceed against an unknown host.

The normal runtime path is safe: `detect_host()` only emits `copilot-cli` or `claude-code`, so `check_codex_available()` in practice only receives those two values. The risk is:

1. A future host value is added to `detect_host()` before `check_codex_available()` is updated, and the function silently treats the new host as "Codex available."
2. A caller other than the established `detect_host()` → `check_codex_available()` pipeline passes an arbitrary value (e.g., during testing with mocked env signals).

## Why this matters

Fail-open on availability means the pipeline attempts a Codex dispatch on an unrecognized host, which will fail — but the failure occurs downstream at the dispatch boundary, not at the availability-check gate where it is cheapest to catch. The availability gate's purpose is to fail before committing to a dispatch. A fall-through-to-success default defeats that purpose.

## Required fix

Add one test expectation to Task 6:

> `check_codex_available()` returns a non-zero exit code when called with an unrecognized (neither `copilot-cli` nor `claude-code`) host argument

This pins the interface contract as fail-closed for unknown inputs and prevents silent fall-through in future-host-extension scenarios.

Alternatively, the task description can explicitly name the default-case behavior ("unrecognized host: return non-zero") so the implementer cannot accidentally omit it.
