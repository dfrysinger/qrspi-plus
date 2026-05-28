---
finding_id: R5-F02
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/design.md:L555-L564]
artifact: design
round: 5
reviewer: quality-codex
---

The G12 commit-procedure rationale misstates which steps changed. The new sequence stages tracked work before writing `.qrspi-commit-msg.txt` (lines 557-560), but line 564 says only scratch removal is the reorder and that steps 1-4 and 6 are unchanged. That is factually wrong relative to the documented old procedure and can mislead Plan/Implement into preserving the old write-before-stage ordering.

Fix line 564 to say the procedure now reorders staging before scratch-file creation and also keeps the post-commit cleanup, instead of claiming steps 1-4 are unchanged.
