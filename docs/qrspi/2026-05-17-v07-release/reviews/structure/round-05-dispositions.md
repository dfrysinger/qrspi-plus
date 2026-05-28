# Structure round-5 dispositions

3 of 4 reviewers clean. 1 finding applied. 1 dropped at verifier (3rd-time false positive).

## Applied (1)

- **quality-codex R5-F01** (HIGH, correctness; verified 75) — NEW finding. Slice 2 (TDD test-writer split) wired the test-writer agent + Implement skill + RED-verification adapters but did NOT update `agents/qrspi-implementer.md` for the split-mode contract. Without an explicit agent-body change, the existing implementer would still author its own RED tests when dispatched after the test-writer, duplicating work and breaking design G6's separation. Added a new Slice 2 row for `agents/qrspi-implementer.md` with responsibility: "Add split-mode awareness: when dispatched after a test-writer in the same task wave, treat prewritten failing tests as the RED input and skip the implementer's own RED-authoring step. Dispatch signal that flips the behavior is declared in `skills/implement/SKILL.md` (e.g. presence of a `prewritten_red_tests:` companion or equivalent field); the agent body changes only the RED-authoring control flow, not the GREEN/refactor cycle."

## Stale / dropped (1)

- **quality-codex R5-F02** (HIGH, correctness; verified 12) — Third consecutive resurrection of the G4 anchor-index claim (R2-F02 scored 10, R4-F01 scored 12, R5-F02 scored 12). Persistent codex false positive: misreads design.md "Both A and B (accepted)" as v0.7 deliverable mandate; phasing.md Slice 7 explicitly gates Mechanism B on the measurement spike outcome. Disposition is durable.

## Clean reviewers (3)

- quality-claude (round-05): clean.
- scope-claude (round-05): clean.
- scope-codex (round-05): clean.

## Notes

- Convergence trend: R1=5/5 kept, R2=4/5 kept, R3=1/1 kept, R4=1/2 kept, R5=1/2 kept.
- Round 5 emitted 1 NEW high-correctness finding (R5-F01) — the dispatch-signal gap for split-mode RED handling — that prior rounds missed. Worth the additional round; not stale-churn.
- Round 6 expectation: full convergence (4-clean) IF quality-codex stops resurrecting R5-F02. If codex resurrects again at round 6, the disposition pattern (3 verifier drops at scores 10/12/12) is durable enough to declare scope-set convergence and present to user.
