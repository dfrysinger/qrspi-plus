# Structure round-10 dispositions

3 of 4 reviewers clean. 1 finding applied. 1 dropped at verifier.

## Applied (1)

- **quality-codex R10-F01** (HIGH, correctness; verified 78) — `scripts/run-third-party-llm.sh` Interfaces block lacked a config-location parameter. `--provider` resolves against an entry in `config.md` but the script had no way to know which run's `config.md` to read. With multiple artifact directories and resumed runs, implementers couldn't locate the right config.

  Fix: added required `--artifact-dir <path>` parameter; documented that the script Reads `<artifact-dir>/config.md` to resolve providers + model_routing. Updated test row (`test-run-third-party-llm.bats`) to cover `--artifact-dir`-based config resolution.

## Stale / dropped (1)

- **quality-codex R10-F02** (medium, correctness; verified 15) — Claim: structure's R9 contrapositive reframing of `test-bash32-runtime-coverage.bats` weakens the test below design's Option-A'-load-bearing requirement. Dropped because:
  - **FD-02** (round-18 Design gate accepted v0.7 known issue) explicitly documents the contrapositive as a valid resolution: "the ban-list may already be exhaustive enough that no non-listed bash-4 construct exists to demonstrate the distinction — in which case the test should be rewritten to assert the contrapositive."
  - **phasing.md Slice 3 replan gate (L70-72)** explicitly uses contrapositive language: "the docker job validates the ban-list remains current by execution test, surfacing any new bash-4 construct authors introduce that the ban-list does not enumerate."
  - Codex read design.md in isolation without recognizing FD-02's binding acceptance and phasing's matching wording.

## Clean reviewers (3)

- quality-claude (round-10): clean (R9 G14Consumers diagram fix verified).
- scope-claude (round-10): clean (4th consecutive clean round: R7+R8+R9+R10).
- scope-codex (round-10): clean.

## Notes

- Convergence trend: R1=5/5, R2=4/5, R3=1/1, R4=1/2, R5=1/2, R6=1/1, R7=2/2, R8=2/2, R9=1/1, R10=1/2.
- Round 11 expectation: full 4-clean convergence.
