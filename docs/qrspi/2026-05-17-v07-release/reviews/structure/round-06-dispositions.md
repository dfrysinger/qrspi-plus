# Structure round-6 dispositions

3 of 4 reviewers clean. 1 HIGH finding applied. **Important correction:** the G4 axis concern that codex emitted at R2/R4/R5 (then dropped at verifier scores 10/12/12) was actually LOAD-BEARING — prior verifiers misread the design's Path A/B vs Mechanism A/B axes. R6-F01's refined two-axes framing made the issue legible; verified 85 and applied substantively.

## Applied (1)

- **quality-codex R6-F01** (HIGH, correctness; verified 85) — REFINED restatement of the G4 concern from R2-F02/R4-F01/R5-F02. The refined framing surfaced the two-axes architecture in design G4 (lines 191-245):
  - **Mechanism A** (prompt caching) and **Mechanism B** (section-anchor narrow Reads) are both UNCONDITIONALLY accepted per the trade-offs table ("Both A and B (accepted)").
  - **Path A vs Path B** is a Mechanism-A-only sub-decision the spike resolves (Path A = caching already active, Path B = `cache_control` markers needed).

  Structure.md prior wording conflated the two axes: "Path-A keeps prefixes stable; no index needed" wrongly tied Mechanism B (anchor index) to Path B.

  Fix applied: Slice 7 reorganized with explicit Mechanism A (path-gated on spike) and Mechanism B (unconditional, ships in v0.7) sub-sections. Added concrete file allocations for Mechanism B:
  - `docs/qrspi/2026-05-17-v07-release/section-anchor-index/<artifact>.anchors.json` (per-artifact JSON index)
  - `scripts/g4-section-anchor-refresh.sh` (regenerator; manual invocation, future automation deferred)
  - `skills/structure/SKILL.md` updated with `## Section-Anchor Index` section spec (location, refresh ownership, consumer contract)
  - 3 new tests: index-shape, byte-identical narrow-Read, refresh idempotency
  - Path-A/Path-B cache-hit-rate test + capability-gated cache-control test for Mechanism A
  - Architectural diagram Slice 7 subgraph extended with `AnchorIndex`, `AnchorRefresh`, `StructureSkill7` nodes + arrows

## Self-correction on prior dispositions

Round 2 dropped quality-codex R2-F02 at verifier score 10. Round 4 dropped R4-F01 at score 12. Round 5 dropped R5-F02 at score 12. All three verifiers anchored on phasing.md Slice 7's "measurement-and-decision spike" framing and concluded Mechanism B was conditional on spike outcome. The misread was: phasing.md Slice 7's gating language applies to Mechanism A's site-by-site cache_control work, not to Mechanism B's anchor index. The codex reviewer was correct each time; the verifier kept matching on the wrong phasing.md axis. R6-F01's two-axes framing made the error legible.

This is the system working as intended: persistent codex re-emission with refined framing caught a real architectural gap that 3 prior verifier passes missed.

## Clean reviewers (3)

- quality-claude (round-06): clean (R5-F01 fix verified correct).
- scope-claude (round-06): clean.
- scope-codex (round-06): clean.

## Notes

- Convergence trend: R1=5/5 kept, R2=4/5 kept, R3=1/1 kept, R4=1/2 kept, R5=1/2 kept, R6=1/1 kept (substantive fix).
- Slice 7 file count grew from 4 rows to 11 rows (+ 3 grouping subheadings). Diagram grew by 3 nodes + 2 arrows.
- Round 7 expectation: full convergence (4-clean) since the substantive Mechanism B allocation now matches design intent. If codex emits R7-F01 against G4 again, it would be NEW grounds beyond R6-F01's framing.
