---
id: F02
reviewer: test-coverage-claude
round: 5
file: tests/integration/test-reference-gate-pause.bats
line: 493
severity: low
change_type: correctness
status: accepted
---
Worked-example-A pin counts co-edit>=2 + no-change>=1 across the WHOLE section; does not verify the
"public-symbol rename" framing — prose definitions alone could satisfy the count (false-pass).
DUPLICATE of test-coverage-codex.F01. ADJUDICATION: ACCEPTED — add an additive "public-symbol rename" framing grep.
(Exact-three-consumer count not pinned to avoid fragile section parsing.)
