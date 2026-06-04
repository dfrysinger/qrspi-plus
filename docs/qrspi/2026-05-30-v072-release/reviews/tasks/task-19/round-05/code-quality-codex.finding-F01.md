---
finding_id: R5-F01
reviewer_tag: code-quality-codex
round: 5
severity: low
change_type: additive-test
referenced_files: [tests/unit/test-second-reviewer-available.bats]
model: gpt-5.3-codex
---

The "unknown vendor override exits non-zero" test (test-second-reviewer-available.bats:289-308) docstring (L288/L292) states the diagnostic must name both host= and vendor= on a single stderr line, but the assertions verify only host= (L307) plus tag + line-count==1. There is no vendor= assertion in this single-line test, so the unknown-vendor vendor= naming behavior can regress without failing here. (Note: vendor= naming is checked in a SEPARATE test L311-320, but that test does not assert single-line — so no single test jointly verifies one-line + host= + vendor= for the unknown-vendor path, unlike the explicit-none test L324-348 which is fully joint.)
