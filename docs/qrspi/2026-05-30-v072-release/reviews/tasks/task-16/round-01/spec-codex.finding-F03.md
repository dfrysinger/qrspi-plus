---
finding_id: R1-F03
reviewer: spec-codex
round: 1
severity: medium
change_type: correctness
referenced_files:
  - skills/test/SKILL.md:126
  - skills/test/SKILL.md:134
  - skills/test/SKILL.md:142
---
Hardcoded `Agent({ ..., model: "sonnet" })` dispatch args remain in skills/test/SKILL.md (Test-phase reviewer dispatches: spec-reviewer line 126, code-quality-reviewer 134, goal-traceability-reviewer 142, and peers). T16 removed these from implement/SKILL.md but NOT test/SKILL.md. Migration requires removing hardcoded model: pins from ALL migrated routing surfaces — reviewer dispatches should resolve vendor+model via tier (as the test-writer dispatch at test/SKILL.md:92 already does). ORCHESTRATOR-VERIFIED via grep.
