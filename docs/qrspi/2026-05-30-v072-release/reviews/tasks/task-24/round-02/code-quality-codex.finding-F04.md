---
finding_id: R2-F04
severity: medium
change_type: style
referenced_files: [tests/unit/test-detect-interaction-mode.bats]
reviewer_tag: code-quality-codex
---
The bats file is large and repetitive (many near-identical `run bash -c` setup blocks).
Extracting shared execution/assertion helpers would reduce copy/paste drift. ADVISORY —
declined this round per the no-substantive-refactors constraint (touches ~25 call sites).
