---
finding_id: R1-F03
reviewer: test-coverage-claude
artifact: plan.md
task: Task 06
severity: medium
change_type: correctness
---

# T06 — verifier sidecar `score:` integer-range bounds (0-100) not exercised

## What

Task 06 (G11 verifier sidecar extension correction) DoD specifies:

> The verifier sidecar contract requires frontmatter containing `score:` as
> an integer from 0 through 100.

But the Test expectations only verify the field's presence and extension path,
not the bounds or integer-type contract:

- "Post-implementation run of `tests/unit/test-verifier-agent-file.bats`
  passes only when the verifier agent file pins `.score.md`, **requires
  `score:` in sidecar frontmatter**, and contains no `.score.yml` allowance."

There is no edge-case coverage for:

- `score: -1` (below lower bound)
- `score: 101` (above upper bound)
- `score: 85.5` (non-integer)
- `score: "high"` (non-numeric)
- `score:` (empty value)

This is the canonical boundary-condition gap from Test criteria 2 (Edge Cases:
maximum/minimum values if the task operates on bounded quantities).

## Why this is a test-coverage problem

T06's verifier sidecar is the load-bearing input to `scripts/verifier-fan-in.sh`
(T02). If the contract documents integer-0-to-100 but no test pins the bounds,
an implementation could accept `score: 150` or `score: -5`, and the fan-in
script's score-threshold filter (also T02) could silently treat out-of-range
scores as above-threshold (passing) or as parse failures, with no clear test
to distinguish the two.

T05 covers `change_type` enum drift on both reviewer-emit and
orchestrator-consume sides. T06 should mirror that bilateral-pin pattern for
score values: pin the bounds in `agents/qrspi-finding-verifier.md` prose AND
add fan-in-script test fixtures that fail on out-of-bounds values.

## Falsifiable alternative

Add Test expectations such as:

- "Bats fixture: a verifier sidecar with `score: -1`, `score: 101`,
  `score: 85.5`, or `score: ""` is rejected by the fan-in score-parser path
  exercised in `tests/unit/test-verifier-agent-file.bats`, with a diagnostic
  naming `score out of range` or `score not integer`."
- "Grep audit confirms `agents/qrspi-finding-verifier.md` documents the
  literal range `0 through 100` (or equivalent canonical form) at the
  sidecar-frontmatter contract site."

The fan-in-script integer-bounds rejection may belong to T02 instead of T06;
if so, T02's Test expectations should also be extended to cover the bounds
case, since T02 currently tests `unparseable score` (a parser failure) but
not in-range vs out-of-range integers.

## References

- plan.md ### Task 06 — Definition of done + Test expectations.
- plan.md ### Task 02 — `unparseable score` halt cause (parser-failure path,
  distinct from out-of-range integer).
- plan.md ### Task 05 — bilateral-pin pattern for `change_type` enum
  (precedent for splitting reviewer-emit vs fan-in-consume coverage).
