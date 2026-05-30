---
finding_id: R1-F02
severity: medium
change_type: scope
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/plan.md, docs/qrspi/2026-05-27-v071-hardening/design.md, docs/qrspi/2026-05-27-v071-hardening/structure.md]
artifact: plan
round: 1
reviewer: quality-codex
---

## G7a task introduces untraced work (design/structure traceability + scope creep)

Task 8 creates `tests/unit/test-cache-mechanism-retired.bats`, absent from structure.md Slice 7 file map; conflicts with design DKR8 "mechanical deletion, no new design surface, CI-green acceptance."

**Required fix:** remove the new test-file creation from Task 8 OR update structure/design to authorize. Convergent with spec-claude F01, spec-codex F01, traceability-claude F02, traceability-codex F02. Resolve via Option 2 (remove the test creation; CI-green is the acceptance gate per DKR8).
