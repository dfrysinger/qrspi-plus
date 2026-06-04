---
id: F01
reviewer: silent-failure-claude
round: 3
file: tests/integration/test-reference-gate-pause.bats
line: 564
severity: medium
change_type: correctness
status: accepted
---
metachar-loop block: `section="$(extract_section ...)"` has no `|| return 1` guard. On
extract_section failure (heading rename, unreadable file) section="" and the loop emits a wrong
diagnostic ("Missing rejected metachar ';'") masking the real section-not-found cause.
Recommend `|| return 1` after the assignment. ADJUDICATION: ACCEPTED (additive one-liner).
