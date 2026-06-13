---
finding_id: R4-F05
severity: low
change_type: correctness
referenced_files: ["docs/qrspi/2026-06-04-v073-release/plan.md:L269"]
artifact: plan
round: 4
reviewer: test-coverage-claude
---

T04b's test expectation at line 269 reads: "An `<agent>` value containing characters outside the valid agent-name charset (e.g., a space, a control byte, a path separator) halts dispatch with a named diagnostic and exits non-zero before any git command runs (no silently-malformed marker)." The diagnostic name is unspecified — the description (line 265) is equally vague: "halts dispatch with a named diagnostic and exits non-zero." A test writer implementing `tests/unit/test-dispatch-agent-author-marker.bats` can assert non-zero exit but cannot assert the specific diagnostic string in stderr/stdout. The expectation should name the diagnostic (e.g., `agent-name-charset-invalid:`) so the test can distinguish this failure from other non-zero exits (e.g., a review-prep failure). This is a consistent gap: contrast with T19, T25, T28, and T37, all of which name their error diagnostics precisely.

