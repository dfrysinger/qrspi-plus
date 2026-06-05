---
finding_id: F01
severity: medium
change_type: code_quality
referenced_files:
  - scripts/dispatch-agent.sh
  - tests/unit/test-dispatch-agent.bats
---

ID-hygiene: 5 reviewer-tag/round-attribution strings in code/test comments
violate the strict hygiene rule (attribution belongs only in commit
messages and persisted reviews/ sentinels). Sites:
- scripts/dispatch-agent.sh:768  "(sf-claude review)"
- scripts/dispatch-agent.sh:1020 "(sec-claude review)"
- tests/unit/test-dispatch-agent.bats:747 "(sec-claude review)"
- tests/unit/test-dispatch-agent.bats:1794 "round-3 review"

(Note: dispatch-agent.sh:794 mentions "spec-codex, sec-claude" as example
TAG VALUES, not as reviewer attribution — not flagged.)
