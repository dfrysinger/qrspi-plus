---
finding_id: trace-claude-F02
reviewer: qrspi-goal-traceability-reviewer (claude)
artifact: docs/qrspi/2026-06-04-v073-release/plan.md
round: 3
severity: low
change_type: scope
referenced_files:
  - docs/qrspi/2026-06-04-v073-release/plan.md
---

# F02 — T36's partition-table row (line 65) still shows the pre-remediation dependency set and "post-T13a/T21/T22 state" annotation; the round-02 F02 fix landed in the T36 spec and the dependency-graph block but did not propagate to the overview table

## Summary

Round-02 trace-claude F02 flagged that T36 (the 7-cross-cutting-skills trim
pass) was missing T13b from its dependency set, leaving the
`revert-orchestration-drift` fix-task mode (added in
`implementer-protocol/SKILL.md` by T13b) unprotected against the trim pass.

The round-03 author addressed the finding in three of the four places it
manifests:

1. **T36 detail spec § Dependencies** (line 840) — now correctly reads
   `T07, T31, T13a, T13b, T21, T22`. ✓
2. **T36 detail spec § Description** (line 846) — now correctly says
   "post-T13a/T13b/T21/T22 state" and names the revert-orchestration-drift
   mode as preservation-required content. ✓
3. **Dependency-graph block** (line 129) — now correctly reads
   `T07 + T31 + T13a + T13b + T21 + T22 → T36` with the annotation
   "T13a carries the Pre-DONE blocking prose; T13b carries the
   revert-orchestration-drift fix-task mode added in implementer-protocol".
   ✓

The fourth place — the **task-partition overview table row for T36**
(line 65) — was not updated. The row still reads:

> | T36 | Trim the 7 cross-cutting skills ... | G9, CD-3 | lightweight | high | sizing_exception: reusable-primitives (7-file bulk pass) | **T07, T31, T13a, T21, T22** | Each cross-cutting SKILL applies the four-pass trim against its **post-T13a/T21/T22 state** (G2/G5/G2 additions already in place); per-skill `references/<topic>.md` files are created at extract time. |

Both the Deps column ("T07, T31, T13a, T21, T22" — missing T13b) and the
one-sentence behavior column ("post-T13a/T21/T22 state" — missing T13b)
contradict the spec and graph that were corrected.

## Why this matters for traceability

The partition table is the canonical at-a-glance task summary; downstream
consumers (parallelize.md, the wave scheduler, code reviewers scanning the
plan for impact) typically scan the partition table row first and only drop
into the spec body for tasks they need to dig into. A stale row in the
overview produces three concrete failure modes:

1. **Parallelize scheduling input.** Parallelize derives wave assignment
   from the dependency declarations in plan.md. If parallelize's parser
   reads the partition-table row authoritatively, T36 is scheduled as
   eligible once T13a/T21/T22 are done — even when T13b is still in flight.
   The round-02 F02 schedule-order vulnerability re-emerges: T36 could be
   dispatched in parallel with T13b, and the trim pass runs against a
   `implementer-protocol/SKILL.md` state that does not include T13b's
   addition.

2. **Reviewer-of-reviewers contradiction.** A goal-traceability reviewer
   building a backward-trace matrix in a later round (or at integration)
   has two contradictory dep declarations for T36 — the partition row says
   the smaller set, the spec/graph say the larger set. The reviewer must
   either flag the contradiction or pick one source as authoritative, and
   neither choice is sound without a written convention.

3. **F02 remediation is technically incomplete.** I asked in round-02 for
   four edits (Dependencies line, Description body, Test expectations,
   Dependency graph block). Round-03 made three of those four (Dependencies
   spec, Description spec, Dependency graph block) and added a T13b
   preservation bullet to T36's test expectations (line 848). The partition
   table is the one source-of-truth surface the remediation missed —
   indicating the author worked through the F02 remediation against the
   spec body and graph but did not back-propagate to the overview row.

## Why low severity

The spec body and dependency graph already carry the correct dep set, so a
reviewer who reads the spec body gets the right contract. The schedule-
order vulnerability is mitigated as long as parallelize.md treats the spec
body (not the partition-table row) as authoritative — and that is the
convention in QRSPI: spec bodies own per-task dep edges, the partition
table is a quick-reference summary that should track the spec. So the gap
is structural-consistency drift between the overview and the spec, not a
load-bearing missing trace edge. Severity low; remediation is a 1-line
table-cell edit plus a 1-phrase edit to the behavior column.

## Recommended remediation

Single line-65 edit. Change:

> | T36 | Trim the 7 cross-cutting skills ... | ... | sizing_exception: reusable-primitives (7-file bulk pass) | **T07, T31, T13a, T21, T22** | Each cross-cutting SKILL applies the four-pass trim against its **post-T13a/T21/T22 state** (G2/G5/G2 additions already in place); per-skill `references/<topic>.md` files are created at extract time. |

to:

> | T36 | Trim the 7 cross-cutting skills ... | ... | sizing_exception: reusable-primitives (7-file bulk pass) | **T07, T31, T13a, T13b, T21, T22** | Each cross-cutting SKILL applies the four-pass trim against its **post-T13a/T13b/T21/T22 state** (G2/G5/G2/G5 additions already in place); per-skill `references/<topic>.md` files are created at extract time. |

Two textual changes, both on line 65: the Deps column (add T13b) and the
behavior-column annotation (add T13b to the state-list and the
parenthetical addition list). Round-02 F02 then closes cleanly.
