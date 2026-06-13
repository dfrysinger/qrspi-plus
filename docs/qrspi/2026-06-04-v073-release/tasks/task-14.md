---
status: approved
task: 14
phase: 1
pipeline: full
goal_ids: [G2]
task_type: tdd
tier: low
---

# Task 14: Create tests/unit/test-id-hygiene-lint-fail-direction.bats

- **Target files:** `tests/unit/test-id-hygiene-lint-fail-direction.bats` (Create), `tests/fixtures/id-hygiene/bad-test-name.bats.fixture` (Create — a generated fixture file containing the forbidden internal-ID token under `tests/fixtures/`, not under `tests/**/*.bats`, so the permanent CI lint never sees it as an `@test` line)
- **Dependencies:** T12
- **LOC estimate:** ~30
- **Description:** A fail-direction fixture test drives the T12 lint against a generated fixture file under `tests/fixtures/id-hygiene/` containing a forbidden internal-ID token inside an `@test "..."` description string, and asserts non-zero exit with the documented diagnostic shape (`file:line` location and the offending string in the failure output). The fixture file lives under `tests/fixtures/` (NOT `tests/**/*.bats`) so the permanent CI lint never sees it as a real `@test` line; the test body emits or maintains the fixture content with a body-line carve-out marker on the emit step. The test's own `@test "..."` descriptions contain zero forbidden tokens — the fail-direction proof is in driving the lint against the fixture file, not in including the token in this test's own description.
- **Test expectations:**
  - Dispatch order: test-writer first, implementer second (RED-verification gate between).
  - A regression PR (synthetic) that adds a forbidden internal-ID token to a real test name is rejected at CI by the lint — exercised against the fixture file under `tests/fixtures/id-hygiene/` (G2 Acceptance bullet 4).
  - The lint's failure output for the fixture lists the fixture file path and line number with the offending string (named-diagnostic guard).
  - This test's own `@test "..."` description strings contain zero forbidden tokens (the fixture file under `tests/fixtures/` is the carrier, not this test's descriptions).
