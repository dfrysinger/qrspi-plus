---
finding_id: R1-F01
reviewer_tag: security-claude
artifact: plan.md
round: 1
severity: high
change_type: correctness
location: "Task 21 (G16 path-filter exfil hardening in dispatch-agent.sh) — Scope (In) / Definition of done / Test expectations"
---

## Issue

Task 21's Scope (In) bullet at plan.md:1312 explicitly requires the
`assert_path_under_repo_root` guard to be applied to **"the agent file and
every `--subject-code`, `--artifact-body`, `--companion`, and `--diff-file`
path family"** (emphasis on the agent file).

However, both the Definition of done (plan.md:1329) and the Test expectations
(plan.md:1336–1343) enumerate only the four `--<flag>` argument families and
silently drop the agent-file path. The DoD line reads:
> "`--subject-code`, `--artifact-body`, `--companion`, and `--diff-file` all
> pass through the same repo-boundary enforcement point"

…with no corresponding clause for the agent file. Test expectations include
fixtures for the four flag families plus a symlink regression on
`--subject-code`, but no regression that asserts the agent-file path is
canonicalized and rejected when it resolves outside `$REPO_ROOT/`.

## Why this is a security gap

The implementer is contractually bound only by what tests pin. A test-writer
working from this spec will produce RED tests for the four flag families;
the implementer will satisfy those tests and ship. The Scope mention of the
agent file becomes unenforced prose, and a `dispatch-agent.sh` invocation
that resolves the agent-body path from any caller-controllable source
(subagent-type lookup, env var, future flag) becomes a sanctioned-channel
exfil sink — exactly the regression class G16 exists to close.

This is the same fail-mode G16 itself was filed against: a path the dispatcher
reads with `cat` before emission is the load-bearing exfil surface.
Inconsistency between Scope and DoD/Tests on the very file that motivates
the guard is a load-bearing omission, not a wording nit.

## Required fix at plan level

Add to Task 21:

1. **Definition of done** — append: "The agent-file path resolved by
   `dispatch-agent.sh` (whether from `--subagent-type` lookup, an explicit
   agent-path argument, or any other caller-influenced source) passes through
   the same `assert_path_under_repo_root` enforcement point before any
   `cat`/read or prompt emission."

2. **Test expectations** — append: a regression that drives the agent-file
   resolution path with a value whose canonical target is outside
   `$REPO_ROOT/` (both the absolute-path and in-repo-symlink-to-outside
   cases) and asserts non-zero exit with the `resolves outside repository`
   diagnostic before any prompt file is emitted.

Without these, the agent-file mention in Scope is unenforceable and the
guard's coverage is materially narrower than the design intends.
