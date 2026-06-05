---
id: F01
reviewer: code-quality-codex
round: 3
file: tests/integration/test-reference-gate-pause.bats
line: 588
severity: moderate
change_type: correctness
status: accepted
---
Loose assertions risk false-pass. Primary actionable: test-5 regex second alternative
`patterns starting with` matches without the `reject` framing. (`[Vv]alidat` and `argument separator`
are verbatim mirrors of the approved G15 suite — kept as established convention.)
ADJUDICATION: ACCEPTED for the test-5 branch only; consolidated with cq-claude.F01 / sf-claude.F02 / sec-claude.F01.
