---
finding_id: F03
reviewer: security-claude
reviewer_tag: security-claude
artifact: plan.md
round: 1
severity: medium
change_type: defect
category: fail-closed
referenced_files:
  - docs/qrspi/2026-06-04-v073-release/plan.md
tasks_affected: [T13, T20]
---

# F03 — T13 `revert-orchestration-drift` fix-task mode has unspecified partial-failure semantics; T20 autopilot auto-dispatches it without a halt-on-conflict requirement

## Summary

T13 adds the `revert-orchestration-drift` fix-task mode to
`skills/implementer-protocol/SKILL.md` § Mode payloads. The mode reads the OBC
violation report, runs `git revert --no-edit <SHA>` for each non-subagent commit
in reverse chronological order, commits the reverts under the subagent author
marker, and writes `orchestration-boundary-revert.md` summarizing actions.

T20 wires this mode into the autopilot batch-gate: when the OBC report contains
commit-based violations, the autopilot auto-dispatches the fix-task subagent
with mode `revert-orchestration-drift`, re-runs the check, and on still-non-empty
result writes `HALT-orchestration-boundary-recurring.md` and exits the autopilot
loop (cap 1 auto-revert per phase).

**Neither task specifies what happens when an individual `git revert --no-edit`
invocation fails partway through the sequence** — the most common cause being
merge conflicts when reverting a non-trivial commit, or refusing to revert a
merge commit without `-m`. The specification permits at least two non-equivalent
implementations, and neither is fail-closed:

- **Interpretation A — skip-and-continue:** if revert N fails, log it, run
  `git revert --abort` to clean the index, and proceed to revert N+1. Result:
  silent partial revert; the autopilot's re-run of OBC sees fewer violations
  but not zero, classifies as "recurring", and writes the halt marker — but
  the workspace already has half the reverts applied, the author of the halt
  marker is unaware of which reverts succeeded and which were skipped, and
  the next phase begins from an inconsistent base.
- **Interpretation B — halt mid-sequence:** if revert N fails, leave the
  conflict in-tree and exit non-zero. Result: the next operation (whether
  human inspection or autopilot retry) inherits a working tree with conflict
  markers in unrelated files, the subagent has not written
  `orchestration-boundary-revert.md`, and no diagnostic names which SHA
  failed or why.

Both are silent partial-state outcomes from the autopilot's perspective. The
autopilot has no signal beyond "re-run found violations" — it cannot
distinguish "the revert sequence couldn't complete" from "new non-subagent
commits arrived between rounds".

## Concrete failure scenario

Phase end. OBC report lists 3 non-subagent commits:

- `C3` (most recent): touches `skills/implement/SKILL.md`, conflicts with
  later subagent work that also touched the same file.
- `C2`: touches a deleted file (now revert needs `--ours`).
- `C1`: a merge commit (refuses revert without `-m`).

Autopilot dispatches `revert-orchestration-drift`. Subagent reverts `C3`
successfully (no conflict at that depth), attempts `C2` and hits the
deleted-file conflict, attempts `C1` and the bare `git revert --no-edit`
errors with "is a merge but no -m option was given". The plan's spec does not
say what the subagent does at either failure point.

Under Interpretation A: workspace has `C3` reverted, `C2` and `C1` skipped,
`orchestration-boundary-revert.md` claims one revert SHA. Next phase starts
from a partially-cleaned tree. The original orchestration-drift problem is
half-fixed.

Under Interpretation B: workspace has `C3` reverted and `C2` mid-revert with
conflict markers. No summary file written. Autopilot's OBC re-run sees the
uncommitted-edit (the conflict markers) and writes
`HALT-orchestration-boundary.md` — but the diagnostic message is "uncommitted
workspace changes", not "revert sequence failed at SHA C2", losing the actual
failure signal.

## Plan-spec gap

T13 § Mode payloads currently lists four behaviors (read report, revert each,
commit under marker, write summary). It does not specify:

1. **What constitutes revert failure** — non-zero exit from `git revert`,
   detection of conflict markers, refusal-to-revert errors.
2. **What to do on first failure** — abort the in-progress revert? Halt the
   whole sequence? Skip and continue?
3. **What to write when halted partway** — summary file content describing
   which SHAs succeeded, which failed, what error.
4. **What exit status to return** — non-zero so the autopilot does not
   re-dispatch and instead hits the cap-1 halt path.
5. **How to leave the working tree** — must `git revert --abort` run on
   failure to clean conflict markers, so the next phase doesn't inherit a
   dirty tree?

## What the plan should require

Add to T13's Edit 2 description (the `revert-orchestration-drift` mode bullet
list) the explicit partial-failure contract:

- On `git revert --no-edit <SHA>` non-zero exit, run `git revert --abort` to
  clean any in-progress conflict state.
- Write `orchestration-boundary-revert.md` with: list of SHAs successfully
  reverted (with new commit SHAs), the failed SHA, the captured stderr from
  the failing revert, and a `revert-sequence-halted:` named diagnostic.
- Exit non-zero. Do NOT continue to subsequent SHAs in the sequence.
- The summary file's existence with the `revert-sequence-halted:` marker is
  the contract — the autopilot's re-run logic must inspect for this marker
  before classifying the situation as "recurring violation".

Add to T20's autopilot block in the batch-gate section: before re-running the
OBC check, the autopilot inspects
`reviews/implement/orchestration-boundary-revert.md` for a
`revert-sequence-halted:` marker. If present, skip the re-run, write
`HALT-orchestration-boundary-revert-failed.md` (distinct from the recurring-
violation halt), and exit the autopilot loop with the revert-failure
diagnostic surfaced.

Add to T13's Test expectations:

- A fixture where one revert in a sequence of three produces a conflict
  results in: (a) `git revert --abort` running, (b) summary file written
  with the `revert-sequence-halted:` named diagnostic naming the failing
  SHA and its stderr, (c) exit non-zero, (d) no subsequent SHAs attempted.
- A fixture where the first SHA refuses to revert (e.g., the SHA is a merge
  commit and `git revert` returns an `is a merge but no -m option` error) is
  treated identically — halt at first failure, summary names the refusal,
  exit non-zero.
- After a halted revert sequence, the working tree contains no conflict
  markers (the `--abort` ran).

Add to T20's Test expectations:

- A fixture autopilot run where the dispatched `revert-orchestration-drift`
  subagent's summary contains `revert-sequence-halted:` causes the autopilot
  to write `HALT-orchestration-boundary-revert-failed.md` and NOT to re-run
  OBC.

## Why this matters

The fail-closed property the OBC was added to enforce — main-chat
orchestration drift cannot silently corrupt phase boundaries — is undermined
when the *correction mechanism* can itself silently leave the workspace in a
mixed state. Under autopilot (the path with no human in the loop), an
unspecified partial-failure mode is exactly the regression class the design
was meant to close.

The cost is one paragraph in T13 and one paragraph in T20; the benefit is
that the auto-revert path either fully succeeds or fully halts with a named
diagnostic, never partially executes.
