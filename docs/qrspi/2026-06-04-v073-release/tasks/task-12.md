---
status: approved
task: 12
phase: 1
pipeline: full
goal_ids: [G2]
task_type: tdd
tier: medium
---

# Task 12: Create tests/lint/test-bats-test-name-id-hygiene.bats permanent CI lint

- **Target files:** `tests/lint/test-bats-test-name-id-hygiene.bats` (Create)
- **Dependencies:** T11
- **LOC estimate:** ~50
- **Description:** A permanent CI lint greps every `@test` line under `tests/**/*.bats` and fails when a description matches a forbidden internal-ID token (`[Tnn]` or sub-task suffix shape) or a forbidden finding-ID token. Failure output lists offending `file:line` locations and the offending strings (the documented diagnostic shape). The carve-out marker `# bats lint:no-id-hygiene` is honoured only on fixture-construction body lines inside a test body that emit a forbidden token to a generated fixture file under `tests/fixtures/`; the lint does NOT exempt `@test "..."` description strings on the basis of an adjacent carve-out marker (the Acceptance grep must pass without `@test`-description carve-out exemption). The lint runs in CI on every PR; reintroduction of the swept tokens into an `@test "..."` description is mechanically impossible to land.
- **Test expectations:**
  - Dispatch order: test-writer first, implementer second (RED-verification gate between).
  - The lint exists and passes on the post-sweep clean tree (Acceptance bullet 3, first half).
  - The lint fails (with the documented diagnostic shape) against a fixture file under `tests/fixtures/` that carries a forbidden internal-ID token (`[T<digits>]`) inside an `@test "..."` description string AND against a fixture file that carries a forbidden round-finding-ID token (`R<digits>-F<digits>`) inside an `@test "..."` description string (Acceptance bullet 3, second half — both token classes from goals.md and design.md Solution change 1 produce a lint failure; the fail-direction is exercised by T14).
  - The carve-out marker `# bats lint:no-id-hygiene` on a fixture-construction body line inside a test body exempts that body line from the lint match.
  - An `@test "..."` description string containing a forbidden token is NOT exempted by an adjacent carve-out marker — the `@test`-description rule has no carve-out.
  - The lint's failure output lists `file:line` locations and the offending strings (named-diagnostic discipline; no silent fail).
