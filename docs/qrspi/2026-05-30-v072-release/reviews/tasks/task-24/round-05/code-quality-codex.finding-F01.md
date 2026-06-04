---
finding_id: F01
severity: high
change_type: style
referenced_files: [tests/unit/test-detect-interaction-mode.bats]
---
ID hygiene: QRSPI-internal `[T24]` tokens appear in comment bullets (lines 9-32) and many `@test` names (existing tests, lines 58-257+). QRSPI-internal IDs are forbidden in comments and test surfaces outside docs/qrspi. Recommendation: remove `[T24]` from comments and `@test` names; use behavior-only wording. NOTE (orchestrator): correct on direction (opposes code-quality-claude F01). Applies to the EXISTING 34 tests, not the 5 new ones (which already omit the prefix). This is the known release-wide leak (plugin_issues pi-tnn-test-name-leak-releasewide) requiring a sweep-vs-exempt decision OUTSIDE T24 scope. DECLINED within T24 (editing 34 existing tests exceeds this additive-test task; tracked separately).
