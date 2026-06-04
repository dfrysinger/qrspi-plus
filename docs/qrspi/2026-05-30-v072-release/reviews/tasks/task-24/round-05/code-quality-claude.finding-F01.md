---
finding_id: F01
severity: low
change_type: style
referenced_files: [tests/unit/test-detect-interaction-mode.bats]
---
Missing `[T24]` prefix on all 5 new test names (lines 528,546,563,585,604). All 34 prior tests in this file carry `[T24]`. NOTE (orchestrator): this finding is DECLINED — it conflicts with the canonical ID-hygiene rule (implementer-protocol/SKILL.md:101) which FORBIDS `[Tnn]` Task IDs in test names. The new tests CORRECTLY omit the prefix. The inconsistency is the existing 34 tests carrying the leak (tracked release-wide as plugin_issues pi-tnn-test-name-leak-releasewide), not the new tests. Directly contradicts code-quality-codex F01 (which correctly asks to REMOVE the prefix).
