---
finding_id: R9-F01
severity: medium
change_type: scope
referenced_files: ["plan.md:L383-L406","plan.md:L786-L806"]
artifact: plan
round: 9
reviewer: scope-codex
---
Generic boundary-drift claim that test expectations include grep/regex commands. NOTE: REJECT — Sweep Task Contract (skills/plan/SKILL.md § Sweep Task Contract L589-680) EXPLICITLY requires `dependent_tests: none` followed by a literal `grep -rn -- '<pattern>' tests/` command (reviewer re-runs it). Same false claim as R8-F02; same rejection basis.

