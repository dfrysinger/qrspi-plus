---
finding_id: R2-F03
severity: low
change_type: clarity
referenced_files: [tests/unit/test-detect-interaction-mode.bats]
reviewer_tag: code-quality-codex
---
Lines 55-59 document a `run_clean_env` helper (Usage signature) that was never implemented;
all tests inline the equivalent `run bash -c` pattern. Delete the stale comment block.
