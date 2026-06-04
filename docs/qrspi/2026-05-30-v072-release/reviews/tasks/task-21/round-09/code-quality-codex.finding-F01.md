---
finding_id: F01
severity: low
change_type: code_quality
referenced_files:
  - scripts/lib/path-guard.sh
  - tests/unit/test-dispatch-agent.bats
---

Comments in path-guard.sh (~L96) and test-dispatch-agent.bats (~L1956)
referenced the prior round's reviewer tag and finding ID inline in the
code-visible prose ("sf-claude R8 finding" / "sf-claude R8 regression:").
Same class as the R8 cq-claude/cq-codex F01 finding: review-process IDs
belong in commit-message attribution and persisted reviews/ sentinels,
not in code or test comments. Closed in fix-cycle 10 (commit 4ec927b);
both comment lines rewritten with neutral domain wording.
