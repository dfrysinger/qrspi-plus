# F03 — Primary G9 loud-failures (exit 1) collapse into "other non-zero → surface diagnostic" with no recovery

**Category:** 4 — Inappropriate Error Transformation (under-specified branch)
**Severity:** Low-Medium
**File:** `skills/implement/SKILL.md:1189` (changed)

## What happens

Checklist step 4 says the script "asserts that prior-round artifacts (`round-NN-commit.txt`,
and `round-NN-scope-set.txt` when narrowing-eligible) exist and are well-formed", then lists
exit-code branches:

> 0 → proceed; 10 → orchestrator bug, halt; 11 → worktree integrity break, halt;
> 12 → re-dispatch implementer, restart from step 3; **other non-zero → surface diagnostic.**

The prior-round artifact assertions — the missing/malformed `round-(NN-1)-commit.txt` and
missing/empty `round-(NN-1)-scope-set.txt` checks that are *named* in the same sentence and
are a **primary G9 deliverable** (task-13.md DoD lines 40-41) — all exit `1` in
`round-prepare.sh` (lines 195, 207, 218, 222). They therefore fall into the generic
"other non-zero → surface diagnostic" bucket with **no recovery guidance**, despite being
the central new fail-loud behavior this task adds.

## Why this matters

The exit-1 conditions are recoverable in distinct ways (a missing prior commit anchor means
a *prior* round's capture was skipped — different remediation than a missing scope-set, which
means the scope-tagger dispatch in a prior round failed). Collapsing both into an unguided
"surface diagnostic" means the orchestrator (and the human it surfaces to) cannot distinguish
the failure class from a non-git workspace (exit 2) or an anchor-write disk error (also
exit 1) — the caller cannot tell these failures apart, which is the I-can't-distinguish-this
hazard. The asymmetry with the richly-specified 10/11/12 branches makes the most important
new behavior the least actionable one.

## Recommendation

Add an explicit branch in the checklist for the exit-1 prior-artifact assertion failures
(e.g. "1 → prior-round bookkeeping gap: a prior round's commit-anchor or scope-set capture
was skipped/failed; halt and surface the named diagnostic; do not auto-retry"). Optionally
split the script's bookkeeping failures from generic exit-1 with a distinct code so the
checklist can branch deterministically rather than on stderr text.
