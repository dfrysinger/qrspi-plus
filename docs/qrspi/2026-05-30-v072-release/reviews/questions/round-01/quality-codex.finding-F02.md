---
finding_id: R1-F02
severity: high
change_type: scope
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/questions.md
  - docs/qrspi/2026-05-30-v072-release/goals.md
artifact: questions
round: 1
reviewer: quality-codex
---

## Question set is not comprehensive relative to the approved goals

The set is not comprehensive relative to the approved goals: several major goal areas are unasked.

### Missing major areas implied by goals

- Canonical cumulative diff helper (G4) (`goals.md` lines 96–116).
- Idempotent post-approval plan split (G5) (`goals.md` lines 117–137).
- `change_type` enum-membership drift / fail-loud behavior (G13) (`goals.md` lines 354–380).
- Reviewer-model calibration for substituted task-tool models (G20) (`goals.md` lines 571–597).
- Deferred simplify-claude advisory bundle (G24) (`goals.md` lines 698–721).
- Top-level fail-loud invariant vs per-H4 mirror pattern (G25) (`goals.md` lines 722–745).

Current questions cover many goals, but no question directly targets the above surfaces (`questions.md` lines 7–41).

### Requested fix

Add explicit objective questions for each missing area (or broaden existing ones) so all load-bearing goal zones are represented.
