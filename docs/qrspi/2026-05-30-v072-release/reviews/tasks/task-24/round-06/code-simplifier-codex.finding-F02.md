---
finding_id: F02
severity: low
change_type: scope
referenced_files: [tests/unit/test-detect-interaction-mode.bats]
---
Advisory: repeated inline KEY=VALUE `while read` loops could be extracted into an `assert_key_value_lines()` helper. ORCHESTRATOR: DECLINED — test-helper refactor, out of scope (user: no substantive refactors); non-blocking advisory.
