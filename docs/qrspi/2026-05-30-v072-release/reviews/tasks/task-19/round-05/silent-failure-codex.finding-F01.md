---
finding_id: R5-F01
reviewer_tag: silent-failure-codex
round: 5
severity: medium
change_type: additive-test
referenced_files: [tests/unit/test-second-reviewer-available.bats]
model: gpt-5.3-codex
---

Silent-fallback / vacuous-assertion gap: the unknown-vendor single-line test (test-second-reviewer-available.bats:287-308) was expanded to enforce the single-line host=+vendor= diagnostic contract (per docstring L288/L292) but only asserts host= (grep -q 'host=', L307) and never asserts vendor=. If production regresses to omit vendor= on the unknown-vendor path, this test still passes, masking the contract break. Converges with code-quality-codex R5-F01. Fix is test-only additive: add grep -q 'vendor=' to the single-line test (which also makes the docstring accurate).
