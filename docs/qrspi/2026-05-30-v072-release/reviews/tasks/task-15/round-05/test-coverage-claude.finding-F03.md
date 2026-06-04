---
id: F03
reviewer: test-coverage-claude
round: 5
file: tests/integration/test-reference-gate-pause.bats
line: 580
severity: low
change_type: correctness
status: accepted
---
G18 `--` separator security pin greps the concept "argument separator" while the G15 sibling pin (L371)
greps the literal `-- '`. The G18 injection-hardening pin is looser than its sibling set 4 tests earlier —
a regression on the standard the R2 HIGH finding established. ADJUDICATION: ACCEPTED — tighten the G18 pin to
require the literal `--` token (matched to G18's actual prose "require `--` argument separator").
