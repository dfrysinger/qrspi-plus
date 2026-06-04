---
finding_id: F02
reviewer: code-quality-codex
severity: low
change_type: clarity
referenced_files: [tests/unit/test-dispatch-agent.bats:1412-1709]
---
**Test-file size + duplication.** Added G16 block (~300 lines, repeated setup/run/assert/cleanup). Suggest extracting helpers or splitting into dedicated file.

**Adjudication:** DEFER to v0.7.3 (refactor scope, not correctness).
