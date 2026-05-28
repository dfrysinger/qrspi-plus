# Structure round-7 dispositions

2 of 4 reviewers clean. 2 findings applied.

## Applied (2)

- **scope-codex R7-F01** (medium, scope; verified 85) — The Mechanism B section-anchor index row added in round 6 was a directory placeholder (`docs/qrspi/2026-05-17-v07-release/section-anchor-index/`) with concrete file selection deferred to Plan. That violates Structure OWNS "no directory placeholders". Fix applied:
  - Replaced the directory row with 3 concrete colocated index file rows: `skills/reviewer-protocol/SKILL.anchors.json`, `skills/using-qrspi/SKILL.anchors.json`, `skills/plan/SKILL.anchors.json` (the highest-traffic stable artifacts).
  - Changed colocation convention: index files now sit next to their source artifact instead of under a release-versioned `docs/qrspi/...` directory (also resolves a separate concern that the index files are qrspi-plus runtime artifacts, not per-release deliverables).
  - Updated `g4-section-anchor-refresh.sh` Responsibility to reference a manifest enumerating the indexed artifacts.
  - Updated the Slice 7 diagram node `AnchorIndex` to show the 3 colocated paths.

- **quality-claude R7-F01** (low, correctness; verified 72) — `tests/unit/test-wave-context-shape.bats` was tagged `G11, G14` but its Responsibility verifies marker-wrapping payload structure, not skill-markdown section extraction; it does not consume `tests/helpers/skill-markdown.bash`. Dropped the `G14` tag; kept `G11`.

## Clean reviewers (2)

- scope-claude (round-07): clean.
- quality-codex (round-07): clean (R6-F01 Mechanism B fix accepted).

## Notes

- Convergence trend: R1=5/5, R2=4/5, R3=1/1, R4=1/2, R5=1/2, R6=1/1, R7=2/2.
- quality-codex finally clean on G4 (after 4 emissions and one substantive structure fix at R6). The two-axes architecture is now correctly reflected.
- Round 8 expectation: full convergence (all 4 clean).
