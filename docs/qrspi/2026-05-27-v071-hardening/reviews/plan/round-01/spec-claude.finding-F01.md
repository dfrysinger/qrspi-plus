---
finding_id: F01
severity: blocking
change_type: scope
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/plan.md, docs/qrspi/2026-05-27-v071-hardening/structure.md]
artifact: plan
round: 1
reviewer: spec-claude
---

## Task 8 creates `test-cache-mechanism-retired.bats` — absent from structure.md

`structure.md` Slice 7 file map enumerates 4 deletes + 4 modifies, zero creates for G7a. Section Contracts "Created files" lists only `test-host-detection.bats` (Slice 6) and `test-agent-frontmatter-no-model.bats` (Slice 8). `tests/unit/test-cache-mechanism-retired.bats` appears in neither. Plan introduces a new file the approved companion structure does not authorize.

**Resolution options:**
1. Update structure.md to add the file (with section contract).
2. Drop the new file from Task 8; rely on CI-green as the G7a acceptance gate per design DKR8.

Design DKR8 explicitly says "mechanical deletion / no new design surface / CI-green as acceptance." Option 2 matches the approved design intent.
