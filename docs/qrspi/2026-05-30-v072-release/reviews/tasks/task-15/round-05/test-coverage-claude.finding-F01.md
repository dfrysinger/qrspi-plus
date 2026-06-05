---
id: F01
reviewer: test-coverage-claude
round: 5
file: tests/integration/test-reference-gate-pause.bats
line: 615
severity: low
change_type: correctness
status: accepted
---
Test named "covers malformed-field and false-none cases" (L615) greps missing-field/malformed/invalid-disposition
but NEVER greps the false-`none` failure mode its name advertises. The mechanism is pinned separately at L545-550,
but this named coverage point does not assert it. ADJUDICATION: ACCEPTED — add an additive false-none grep assertion.
