---
finding_id: R4-F01
severity: medium
change_type: correctness
referenced_files: [tests/acceptance/v07-phase1/test-phase1-acceptance.bats, skills/using-qrspi/SKILL.md]
---

# Apply-fix patching prohibition clause not verified by any test

Spec L53 requires grepping SKILL.md for BOTH the override prohibition AND the apply-fix patching prohibition.

AC4 greps `MUST NOT.*(override|keep)` which matches clause 1 only. The second clause — "the orchestrator MUST NOT apply patches addressing dropped findings under the guise of the round's apply-fix work" — is operationally distinct and verified by zero tests. Regression risk: someone editing out the apply-fix clause from the prose would not be caught.

**Recommended remediation:** add grep assertion matching `MUST NOT apply patches` or equivalent.
