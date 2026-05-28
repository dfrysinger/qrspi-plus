# Structure round-9 dispositions

3 of 4 reviewers clean. 1 finding applied (with FD-02 cross-reference).

## Applied (1)

- **quality-codex R9-F01** (medium, correctness; verified 78) — Slice 3 row for `tests/unit/test-bash32-runtime-coverage.bats` (line 62) claimed `declare -A` is a fixture that "ban-list-only scan misses" — but `declare -A` IS on Option B's ban-list. Internal contradiction with design.

  Same root cause as **FD-02** (future-design.md known issue): the ban-list may be exhaustive enough that no in-the-wild bash-4+ construct exists outside it. Per FD-02's contrapositive suggestion, rewrote the row: the `bash32` docker job executes EVERY construct on the ban-list under bash:3.2 runtime, asserting each fails. This proves the ban-list claims hold in bash-3.2 reality and validates Option A as the backstop when authors add new constructs to the ban-list before grep coverage catches them. Fixture set = the ban-list itself; docker job = the load-bearing list-currency check.

  Note: this resolves FD-02 at the structure level by adopting the contrapositive framing FD-02 recommended. FD-02 stays in future-design.md as historical context (the round-18 Design gate accepted the issue as a v0.7 known issue); structure now provides the implementation framing that makes the test load-bearing.

## Applied — late-arriving (1)

- **quality-claude R9-F01** (low, correctness; verifier-skipped — trivial half-fix from earlier rounds) — G14Consumers diagram node missing `test-helpers-skill-markdown.bats` (the helper's own self-test, identified at line 45 as "first consumer of the helper itself"). Added the file to the diagram node string (now 7 entries total).

## Clean reviewers (2)

- scope-claude (round-09): clean.
- scope-codex (round-09): clean.

## Notes

- Convergence trend: R1=5/5, R2=4/5, R3=1/1, R4=1/2, R5=1/2, R6=1/1, R7=2/2, R8=2/2, R9=1/1.
- Round 10 expectation: full convergence (4-clean).
