---
finding_id: R7-F01
severity: high
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/design.md:L274-L280, docs/qrspi/2026-05-17-v07-release/design.md:L303-L307]
artifact: design
round: 7
reviewer: quality-codex
---

The Implement-phase test-writer split only requires the pre-implementation tests to fail before the implementer runs. That preserves the “any passing test is suspicious” check, but it drops the existing RED requirement that tests fail for the right reason. A test file with a syntax error, missing import, broken fixture setup, or assertion that never reaches the intended behavior would satisfy “all tests fail” and unblock the implementer, which undermines the stated goal of making the test-writer an independent quality boundary.

Fix: make the pre-implementer gate verify that each generated test fails for the expected task-spec reason, and pause on infrastructure, syntax, import/setup, or unrelated failures just as it pauses on pre-implementation passes.
