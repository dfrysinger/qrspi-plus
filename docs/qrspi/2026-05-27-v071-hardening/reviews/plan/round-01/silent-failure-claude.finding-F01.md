---
id: F01
reviewer: silent-failure-claude
round: 1
artifact: plan.md
category: SWALLOWED_ERROR
severity: high
tasks_affected: [Task 6, Task 7]
goal_ids: [G6]
---

# F01 — `check_codex_available` non-zero return has no specified caller handling; Codex-unavailable scenario is silently swallowed

## What the plan says

Task 6 introduces `check_codex_available(host)` in `scripts/run-codex-review.sh`. Its interface contract
(structure.md `## Interfaces`) is:

```
# Returns: 0 (Codex reachable on this host)
#          non-zero (not reachable)
```

Under Claude Code this means: if the companion-script glob (`~/.claude/plugins/…/codex-companion.mjs`)
resolves to no file paths, the function returns non-zero.

Task 6's test expectations verify that the function *returns* non-zero in that case.
Task 7 (the only caller-side task) specifies test expectations that only cover the **happy path**:

> "The acceptance test assertion for the Copilot CLI path passes when `COPILOT_CLI=1` is set and fails (RED) when it is absent."
> "The acceptance test assertion for the Claude Code path passes when `COPILOT_CLI` is unset and fails (RED) when the Copilot CLI signal is active."

Both Task 7 expectations verify which transport is selected *when Codex is available*. Neither task
names what the caller does — or what tests pin — when `check_codex_available` returns non-zero.

## Why this is a silent failure

The function hands its non-zero return code to the caller and stops. The plan gives the caller
no specified obligation: no `die`, no warn-and-abort, no explicit fallback description. Without a
mandate, an implementer will likely write:

```bash
check_codex_available "$host" || true   # or simply ignore $?
```

and continue into the dispatch path, silently omitting all Codex reviews for that pipeline run.
The operator sees a completed pipeline with no Codex findings — indistinguishable from a run where
Codex ran and found nothing.

The mismatch-diagnostic in Task 7 ("fires when the detected host disagrees with the `codex_reviews`
config value") is a different signal: it fires on a *config-vs-probe disagreement*, not on a
*Codex-binary-absent* situation. The two failure modes are orthogonal; only the first is covered
by prose guidance. The second has no plan-level handler.

## What needs to be added

Task 6's description or test expectations must specify what the caller must do when
`check_codex_available` returns non-zero:

- Option A (loud): caller must call `die` / `exit 1` with a diagnostic naming the unavailable
  binary path, stopping the pipeline before any dispatch.
- Option B (warn): caller emits a diagnostic to stderr and skips Codex dispatch; the diagnostic
  must be detectable by the acceptance test (e.g., the test checks stderr for the warning string).

Task 7's acceptance test expectations must include a negative-path case:

> "When `check_codex_available` returns non-zero (Claude Code companion script absent), the
> dispatcher emits a named diagnostic to stderr / exits non-zero, and the acceptance test asserts
> that outcome."

Without this, a caller that silently swallows the non-zero return is spec-compliant as written.
