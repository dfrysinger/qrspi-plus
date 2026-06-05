---
id: F01
reviewer: silent-failure-claude
round: 4
file: tests/integration/test-reference-gate-pause.bats
line: 618
severity: medium
change_type: correctness
status: accepted
---
Sibling instance of the R3-fixed masking pattern: `section="$(extract_section "$PLAN_REVIEWER_AGENT" H3 "Cross-task consumer surface detection")"`
at L618 lacks `|| return 1`; on extract_section failure section="" and the grep chain emits a wrong
"Missing 'missing field' failure mode" diagnostic masking the real section-not-found cause.
T15-authored G18 pin (outside the narrowed R4 diff). ADJUDICATION: ACCEPTED — additive one-liner, cap-bent fix-4.
