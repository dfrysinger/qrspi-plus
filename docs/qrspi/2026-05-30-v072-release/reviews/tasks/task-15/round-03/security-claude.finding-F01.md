---
id: F01
reviewer: security-claude
round: 3
file: tests/integration/test-reference-gate-pause.bats
line: 588
severity: low
change_type: correctness
status: accepted
---
R2 F01 (HIGH) CONFIRMED CLOSED — all 5 G18 injection-guard pins match agent prose at
qrspi-plan-reviewer.md L73; agent now carries the dash-prefix/metachar/`--` contract and tests enforce it.
NEW (Low): test-5 second regex alternative `patterns starting with` permits a future dash-prefix-rejection
regression to pass silently. ADJUDICATION: ACCEPTED. Consolidated with the test-5 regex finding.
Out-of-scope advisory (pre-existing): extract_section /tmp TOCTOU at skill-markdown.bash:93 — already in v0.7.3 backlog; DEFERRED.
