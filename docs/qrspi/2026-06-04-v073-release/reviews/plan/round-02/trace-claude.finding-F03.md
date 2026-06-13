---
finding_id: trace-claude-F03
reviewer: qrspi-goal-traceability-reviewer (claude)
artifact: docs/qrspi/2026-06-04-v073-release/plan.md
round: 2
severity: low
change_type: scope
referenced_files:
  - docs/qrspi/2026-06-04-v073-release/plan.md
---

# F03 — Phase-1 Acceptance Criteria bullet at line 146 conflates an unrelated G5 dispatch-defects halt criterion with a G9 Pass 4 regression-guard criterion in one checkbox; the bullet is also missing a goal-ID tag

## Summary

Round-02 added a new phase-1 acceptance bullet at line 146 that bundles two
unrelated criteria into a single `- [ ]` checkbox:

> The Implement-phase autopilot terminates the wave loop and writes
> `HALT-orchestration-boundary-undeterminable.md` when the OBC report carries
> any `## Dispatch defects` entry; no skip-and-continue path exists. G9 Pass 4
> regression-guard execution against the v0.7.2 phase-1 acceptance suite stays
> green across every trim task.

The first sentence is a G5 criterion (sourced from round-01's silent-claude
F02 dispatch-defect fail-loud direction, now wired through T20b's autopilot
branched-default). The second sentence is a G9 criterion (G9 Pass 4 per
design.md G9 § Solution Pass 4 and round-01's trace-claude F03 remediation
option 3). The two criteria have no shared goal, share no covering task, and
have no shared verification mechanism.

The bullet also carries no `(G5)` / `(G9)` parenthetical tag, breaking the
established pattern across every other bullet in the block (each ends with a
parenthetical naming the covering goal IDs, e.g., `(G6)`, `(G7)`, `(G8)`,
`(G9)`, `(CD-1, G1, G4)`).

## Why this matters for traceability

Per the strip-from-goals contract, the per-phase Acceptance Criteria block is
the canonical home for plan-authored phase-boundary criteria, and each bullet
should be independently checkable. Two consequences of the bundling:

1. **Independent-pass ambiguity.** A phase-end gate inspector who finds the
   G5 dispatch-defects halt working but the G9 regression suite failing (or
   vice versa) cannot tick the box honestly either way — the box asserts both
   properties hold. The bundling collapses two pass/fail signals into one
   muddied state.

2. **Goal-trace lookup gap.** The bullet's absence of a `(G5)` or `(G9)` tag
   breaks the matrix scan pattern. Every other bullet in the block carries
   the goal-ID tag at the end; a downstream reader (or the goal-traceability
   reviewer at integration time) loses one trace edge per untagged bullet.
   In this case, the bullet is the *only* phase-level criterion for G9 Pass
   4's escalation back-path (the explicit-task-owner remediation that
   round-01's trace-claude F03 declined in favor of phase-gate framing), so
   the missing tag matters more than it might for a redundant bullet.

3. **Redundancy with line 150.** Line 150 already carries:
   > The v0.7.2 phase-1 acceptance suite (`tests/acceptance/v07-phase1/`)
   > passes against the trimmed skill set with zero regressions; … (G9).

   The "G9 Pass 4 regression-guard execution … stays green across every trim
   task" half of line 146 substantially duplicates line 150's first clause.
   The trace from G9 Pass 4 → phase-level acceptance bullet now has two
   candidate edges, neither of which is canonical.

## Recommended remediation

Split the bundled bullet into two distinct bullets, each with its own
parenthetical goal-ID tag, and remove the G9 Pass 4 duplication with line
150. Suggested shape:

```
- [ ] The Implement-phase autopilot terminates the wave loop and writes
      `HALT-orchestration-boundary-undeterminable.md` when the OBC report
      carries any `## Dispatch defects` entry; no skip-and-continue path
      exists (G5).
```

… and either fold the G9 sentence into line 150's existing G9 bullet (e.g.,
"…zero regressions across every trim task pass at task DONE; …") or leave
line 150 as the sole G9 Pass 4 carrier and drop the duplicate.

This is a low-severity finding because the underlying coverage exists in both
halves; the gap is in trace-clarity and independent-pass evaluability rather
than missing coverage. Fix is two edits to lines 146 and (optionally) 150.
