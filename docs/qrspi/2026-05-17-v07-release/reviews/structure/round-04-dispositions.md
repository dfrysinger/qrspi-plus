# Structure round-4 dispositions

2 of 4 reviewers clean. 1 finding applied. 1 dropped at verifier (resurrected stale claim).

## Applied (1)

- **scope-claude R4-F01** (low, scope; verified 78) — Slice 3 row for `.github/workflows/ci.yml` (line 53) embedded the literal command `docker run --rm bash:3.2 bats tests/` AND the literal trigger glob list — both contradicted the artifact's own line 309 deferral of "container-launch command shape" and trigger-shape detail to Plan/Implement. Replaced the command with "unit + acceptance BATS surfaces under a real bash 3.2 runtime (container-launch command shape owned by Plan/Implement)" and rewrote the trigger list at family level ("`main`, qrspi feature branches, agent-handle issue branches, and PRs to `main`").

## Stale / dropped (1)

- **quality-codex R4-F01** (high, correctness; verified 12) — Resurrected claim that G4 section-anchor index requires concrete file allocation pre-spike. Same root cause as R2-F02 (verifier 10): misreads design's "Both A and B (accepted)" mechanism philosophy as unconditional v0.7 requirement. phasing.md Slice 7 explicitly gates Mechanism B on spike outcome ("downstream implementation work is either green-lit-by-measurement or scoped against the gap the measurement surfaced"); structure.md correctly reflects this with a Path-B follow-up placeholder. Documents are consistent. Dropped.

## Clean reviewers (2)

- quality-claude (round-04): clean. Full coverage check passed; round-03 fix verified correctly applied.
- scope-codex (round-04): clean.

## Notes

- Convergence trend: R1=5/5 kept, R2=4/5 kept, R3=1/1 kept, R4=1/2 kept (1 dropped). Only the codex G4 false-positive prevents perfect convergence.
- After R4 fix, round 5 should converge if codex doesn't resurrect R2-F02/R4-F01 a third time. If it does, the dropped-at-verifier disposition is durable and structure.md can be approved with codex's false-positive noted in the gate presentation.
