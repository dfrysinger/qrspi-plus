---
finding_id: F02
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/plan.md
artifact: docs/qrspi/2026-05-30-v072-release/plan.md
---

# Task 12 backward-loop flag deletion failure is "surfaces a diagnostic" — log-and-continue on state-bookkeeping failure

## Where

Task 12 (G4 canonical cumulative diff helper), Definition of done:

> Backward-loop flag handling is consume-once: a present flag forces base-branch preparation for the next round, deletes the flag when possible, and **surfaces a diagnostic if deletion fails**.

And the matching Test expectations row:

> Exercise backward-loop flag handling and verify the next round is forced to base-branch preparation, the flag is consumed once, and **deletion failure is diagnosed**.

Neither bullet states that the round-prepare invocation **exits non-zero** when flag deletion fails. The plan only requires "surfaces a diagnostic" and "deletion failure is diagnosed." This is the log-and-continue pattern: a state-management failure produces a stderr line but the script returns success.

## Why this matters

The backward-loop flag is consume-once state: round N reads the flag, forces base-branch preparation, deletes the flag, so round N+1 returns to normal narrow/broaden convergence. If deletion fails (FS permissions, read-only mount, concurrent run, partial filesystem corruption) but the script proceeds:

1. Round N still produces the correct base-branch diff and exits 0.
2. The orchestrator continues with reviewer dispatch.
3. Round N+1 re-reads the still-present flag, forces base-branch preparation again, and again fails to delete it.
4. Every subsequent round is silently stuck in "forced base-branch" mode until a human notices the diagnostic line in scrollback.

This defeats the convergence-rule's narrowing optimisation indefinitely. More importantly, **deletion failure is almost always a signal of a real filesystem problem** (permissions drift on the artifact directory, read-only remount, full disk, host-tooling sandbox change) — the operator needs to know NOW, not after N rounds of "why is review never narrowing?". A diagnostic line buried in stderr is not loud-failure; an exit-non-zero is.

This is structurally identical to the silent-fallback pattern Task 18 explicitly prohibits at the class level:

> require a loud halt with a named diagnostic for unresolved routing, model, provider, tier, trusted-path, validator-rerun, or fallback target cases

— state-bookkeeping failure during round preparation belongs in the same loud-halt category.

## What the plan should require instead

Specify that `round-prepare.sh` **exits non-zero** with a documented recovery code (e.g., exit 13) when the backward-loop flag deletion fails after the flag has been consumed semantically. The plan already has a clean precedent for this (exit 10 / 11 / 12 with documented recovery paths); add exit 13 for "backward-loop flag consumed but file deletion failed; check artifact-directory permissions and retry."

Suggested DoD edit: "…deletes the flag when possible, and **exits non-zero (exit 13) with a diagnostic naming the artifact-directory permission/IO failure** if deletion fails."

Suggested Test expectations edit: "…the flag is consumed once, and deletion failure produces a non-zero exit with the documented recovery code."
