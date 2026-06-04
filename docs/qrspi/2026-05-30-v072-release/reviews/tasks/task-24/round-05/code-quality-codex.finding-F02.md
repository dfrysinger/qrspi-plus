---
finding_id: F02
severity: medium
change_type: scope
referenced_files: [tests/unit/test-detect-interaction-mode.bats]
---
Test file is 617 lines with repeated `run bash -c` setup blocks; recommend extracting helper functions and splitting into focused test files. NOTE (orchestrator): DECLINED — this is a substantive refactor of a passing, all-CLEAN test file, explicitly out of bounds per user direction ("substantive refactors doesnt sound good") and the frozen-code constraint. No correctness impact.
