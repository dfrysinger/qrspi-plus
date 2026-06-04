# F02 — Checklist step 1 "confirm no background entries pending" has no failure branch

**Category:** 3 — Missing Error Paths
**Severity:** Medium
**File:** `skills/implement/SKILL.md:1186` (changed)

## What happens

The new between-rounds checklist step 1 states:

> Read `<round-dir>/.round-complete.json` (written by `await-round.sh`). Confirm no
> `mode: background` entries are still `pending`.

The step describes a precondition check but provides **no instruction for the failure case**.
If `.round-complete.json` is missing, unreadable, or *does* still contain `pending`
`mode: background` entries (a background third-party reviewer that has not finished or whose
manifest entry was not finalized), the checklist gives the orchestrator nothing to do. The
remaining four steps (scope-tagger dispatch, SHA read, dispatch-agent invocation, reviewer
fan-out) read as unconditionally next.

Compare step 4, which enumerates explicit exit-code branches (0/10/11/12 + "other non-zero").
Step 1 is asymmetric: it has a stated invariant but no enforcement and no halt.

## Why this is a silent failure

If a background reviewer is still pending and the orchestrator proceeds anyway, the round's
findings are incomplete, but the scope-tagger (step 2) runs against a partial finding set and
the next round is prepared on a partial convergence picture. The system produces a wrong
narrow/broaden decision with no signal that a reviewer was dropped — exactly the silent
per-task review-loop drift G9 exists to prevent (goals.md ### G9).

## Recommendation

Give step 1 an explicit failure branch: if `.round-complete.json` is absent/unreadable, or
any `mode: background` entry is still `pending`, **halt and surface to user** (or re-invoke
`await-round.sh` to drain the background queue) rather than continuing to step 2. Mirror the
"halt + surface" phrasing used by the exit-10/11 branches in step 4.
