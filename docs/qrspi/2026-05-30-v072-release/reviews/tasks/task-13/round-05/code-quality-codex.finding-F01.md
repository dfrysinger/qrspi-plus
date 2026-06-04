---
finding_id: R5-F01
severity: medium
change_type: test
referenced_files: [tests/unit/test-scope-tagger-dispatch.bats]
disposition: accepted-with-issues (declined — test-layout refactor out of cap-bend scope)
---

# F01 — Test file-size / single-responsibility (non-blocking, declined)

The file now mixes legacy scope-tagger contract tests with the large new round-prepare/checklist
[T13] suite, growing to ~1000+ lines. cq-codex suggests splitting the T13 block into a dedicated
file (e.g., round-prepare per-task orchestration tests) for discoverability/maintainability.

DISPOSITION: Declined for this release. Splitting an existing 1000-line passing test file is a
substantive test-layout refactor; the user explicitly constrained this cap-bend round to additive
changes only ("substantive refactors doesnt sound good"), and the fix-cap is exhausted. The dead-code
removal itself was confirmed clean/an improvement by cq-codex. Recorded as deferred test-hygiene.
