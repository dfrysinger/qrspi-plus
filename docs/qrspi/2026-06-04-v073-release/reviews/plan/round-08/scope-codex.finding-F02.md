---
finding_id: R8-F02
severity: medium
change_type: scope
referenced_files:
  - plan.md:L150-L166
  - plan.md:L398-L406
artifact: plan
round: 8
reviewer: scope-codex
---

Claim: test expectations include grep/regex command strings instead of plain-language behavior. NOTE: The Sweep Task Contract (skills/plan/SKILL.md § Sweep Task Contract) EXPLICITLY requires `dependent_tests: none` followed by a literal `grep -rn -- '<pattern>' tests/` command (reviewer re-runs it). This is the contract-mandated shape, not a scope drift. Low confidence.
