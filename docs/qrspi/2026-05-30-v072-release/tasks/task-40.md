---
status: approved
task: 40
phase: 1
pipeline: full
goal_ids: [G21, G26]
task_type: code
model: sonnet
---

# Task 40: G21 bats short-circuit hardening with body-assertion-guard lint (incl. G26 BW02/minimum-version rule)

- **Target files:** `tests/unit/test-using-qrspi-vocab.bats`, `tests/lint/test-bats-body-assertion-guard.bats`, `tests/unit/test-ci-workflow-shape.bats`, `.github/workflows/ci.yml` (only if current CI/test entrypoints do not already execute `tests/lint/` or recursive `tests/` coverage)
- **Dependencies:** none. **Blocks:** none.
- **LOC estimate:** ~140

**Overview**

Harden the BATS gate against vacuous `$body` assertions by guarding existing negation pins, adding a corpus lint test, and ensuring that lint runs on the blocking CI/test path. The lint also carries the already-planned G26-ready BW02 rule surface so the corpus is walked once. (Why: see goals.md ### G21. Approach: see design.md ## G21.)

**Scope**

- **In:**
  - In `tests/unit/test-using-qrspi-vocab.bats`, add `[ -n "$body" ]` guards earlier in the same `@test` block for every existing unguarded `[[ "$body" != *...* ]]` negation assertion, preserving the already-guarded R5-era reference patterns.
  - Create `tests/lint/test-bats-body-assertion-guard.bats` to discover all `*.bats` files under `tests/` while excluding itself, parse `@test` blocks delimited by `^@test "..." \{` and a column-0 closing `}`, and fail any `[[ "$body" ... ]]` assertion without an earlier `[ -n "$body" ]` guard in the same block.
  - Emit clear `file:line` diagnostics for every unguarded `$body` assertion and rely on the existing guarded R5-era pins in `test-using-qrspi-vocab.bats` as live positive controls.
  - Structure the lint file with separate `@test` coverage for the G21 `$body` guard rule and the G26-ready BW02/minimum-version rule surface; the initial BW02 pattern set is `run --separate-stderr`, with diagnostics naming both triggering feature and `file:line`.
  - Extend CI or the existing test runner only as needed so `tests/lint/test-bats-body-assertion-guard.bats` runs on the blocking path, and update/add workflow-shape coverage that asserts the new lint coverage is executed.

- **Out:**
  - BATS deprecation sweep beyond the BW02/minimum-version rule surface this task lands — the BW02 rule is the canonical G26 deliverable (per design.md ## G26 + ## G21 Amendment at G26 design-lock); no further per-file deprecation cleanup ships under a standalone G26 task in v0.7.2.
  - G32 build-sync assertions and broader plugin build-pipeline CI behavior — T39 owns; this task keeps workflow-shape coverage scoped to G21 lint execution.
  - Shellcheck rules and pre-commit hooks — explicitly not part of G21; CI is the durable enforcement layer.
  - BATS upstream/root-cause investigation for #244 — deferred outside this task; the lint gate closes the v0.7.2 risk surface.

**Definition of done**

- Every existing unguarded `[[ "$body" != *...* ]]` negation assertion in `tests/unit/test-using-qrspi-vocab.bats` has a preceding `[ -n "$body" ]` guard earlier in the same `@test` block.
- The already-guarded R5-era reference assertions in `tests/unit/test-using-qrspi-vocab.bats` remain guarded and continue to pass.
- `tests/lint/test-bats-body-assertion-guard.bats` exists, excludes itself from discovery, walks all other `tests/**/*.bats` files, and parses `@test` blocks using the specified opener/column-0 closer shape.
- The G21 lint rule fails loudly with `file:line` diagnostics for every `[[ "$body" ... ]]` assertion that lacks an earlier `[ -n "$body" ]` guard in the same block.
- The lint file includes a separate BW02/minimum-version rule surface using the initial trigger `run --separate-stderr`, and BW02 violations report both the triggering feature and `file:line`.
- CI or the existing blocking test runner executes the new lint test; no shellcheck rule and no pre-commit hook are added.
- Workflow-shape test coverage asserts the G21 lint coverage is executed without taking over G32 build-sync assertions.
- Targeted validation passes for `tests/unit/test-using-qrspi-vocab.bats`, the new lint test, and any workflow-shape test touched by this task.

**Test expectations**

- Grep/audit `tests/unit/test-using-qrspi-vocab.bats` to confirm each existing unguarded `[[ "$body" != *...* ]]` negation now has an earlier `[ -n "$body" ]` guard in the same `@test` block.
- Run the new lint test and confirm it accepts the existing guarded R5-era pins as live positive controls.
- Review the lint implementation to confirm it discovers `tests/**/*.bats`, excludes itself, uses the specified `@test` block boundaries, and emits `file:line` diagnostics for G21 failures.
- Review the BW02 rule surface to confirm it is in separate `@test` coverage, starts with the `run --separate-stderr` trigger, and reports both triggering feature and `file:line`.
- Inspect CI/test-runner wiring and workflow-shape assertions to confirm `tests/lint/test-bats-body-assertion-guard.bats` runs on the blocking path; confirm no pre-commit hook or shellcheck rule is introduced.
- Run a targeted BATS invocation covering `tests/unit/test-using-qrspi-vocab.bats`, `tests/lint/test-bats-body-assertion-guard.bats`, and any touched workflow-shape test.

**References**

- goals.md ### G21 — problem framing for BATS short-circuit / empty-extractor silent passes.
- goals.md ### G26 — problem framing for the BW02/minimum-version regression class (absorbed into this task's lint surface).
- design.md ## G21 — locked retrofit-only, lint-gate, CI-only, and BW02-amendment implementation shape (Amendment at G26 design-lock specifies BW02 rides in the G21 lint file).
- design.md ## G26 — locked disposition that G26's runtime concern is moot (splitter already fixed pre-v0.7.2) and remaining work is the BW02 lint rule consolidated into G21's lint file.
- structure.md ### `tests/unit/test-using-qrspi-vocab.bats` — guarded `$body` retrofit surface and live positive controls.
- structure.md ### `tests/lint/test-bats-body-assertion-guard.bats` — new lint file responsibilities for G21 and G26 BW02 coverage.
- structure.md ### `tests/unit/test-ci-workflow-shape.bats` — workflow-shape assertions for recursive lint coverage.
- structure.md ### `.github/workflows/ci.yml` — CI/test-entrypoint surface that may need recursive lint coverage.
- structure.md ## CI Pipeline — release-level CI shape for lint and BATS execution.
