---
finding_id: R4-F02
severity: low
change_type: correctness
referenced_files: ["docs/qrspi/2026-06-04-v073-release/plan.md:L210"]
artifact: plan
round: 4
reviewer: test-coverage-claude
---

T02's test expectation at line 210 reads: "Missing or unreadable design path exits non-zero with a named diagnostic, not a silent empty map." The phrase "a named diagnostic" does not name the diagnostic. The description (line 203) is equally underspecified: "exits non-zero with a named diagnostic." A test writer implementing `tests/unit/test-design-absorption-markers.bats` can assert non-zero exit but cannot write a deterministic assertion on the specific error message prefix. Every peer script in this plan names its error diagnostics explicitly (e.g., T19 names `phase-base-missing:` and `phase-base-malformed:` separately). The missing-design-path error case should name its diagnostic (e.g., `design-path-unreadable:`) so the test can assert the correct error output and distinguish it from other failure modes.

