---
id: F02
reviewer: silent-failure-claude
round: 4
file: tests/integration/test-reference-gate-pause.bats
line: 496
severity: medium
change_type: correctness
status: accepted
---
Sibling instance of the masking pattern: `section="$(extract_section "$PLAN_SKILL" H3 "Cross-Task Consumer Surface")"`
at L496 lacks `|| return 1`; on failure co_edit_count=0 and the test emits a wrong "must list at least two
co-edit ... found 0" diagnostic masking the real section-not-found cause.
T15-authored G18 pin. ADJUDICATION: ACCEPTED — additive one-liner, cap-bent fix-4.
