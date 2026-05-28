---
task: 10
status: approved
pipeline: full
task_type: code
model: opus
phase: 1
goal_ids: [G6]
dependencies: [T09]
loc_estimate: 200
sizing_exception: reusable primitives
---

# Task 10: Four RED-verification adapter scripts (bats, vitest, jest, pytest)

- **Phase:** 1
- **Target files:**
  - `scripts/red-verify/bats-adapter.sh` (Create) — classifies BATS runner output per the T09 contract.
  - `scripts/red-verify/vitest-adapter.sh` (Create) — classifies Vitest runner output per the T09 contract.
  - `scripts/red-verify/jest-adapter.sh` (Create) — classifies Jest runner output per the T09 contract.
  - `scripts/red-verify/pytest-adapter.sh` (Create) — classifies pytest runner output per the T09 contract.
- **Dependencies:** T09
- **LOC estimate:** ~200
- **Sizing exception:** reusable primitives
- **Description:** Creates the four per-framework adapter scripts that the Implement-skill RED-verification gate dispatches after `qrspi-test-writer` writes pre-implementation tests. Each script consumes the runner's exit code plus its captured stdout/stderr files via the call surface defined in T09, distinguishes assertion failures from infrastructure failures (syntax errors, import/load errors, fixture/setup errors, missing-symbol errors) using framework-specific output signals — Implement selects the specific markers per framework — and emits exactly one of `pass`, `assertion-failure`, or `infrastructure-failure` on stdout. Each adapter exits `0` on successful classification or `1` with a loud diagnostic on stderr when the runner output is unrecognized, matching the T09 exit-code contract. All four adapters are bash-3.2-compatible per Slice 3's CI bash32 runtime gate and avoid bash-4-only constructs (no `mapfile`, no `${var,,}`, no associative arrays). Source layout under `scripts/red-verify/` is the colocated directory the orchestrator (T11) selects from by framework name.
- **Test expectations:**
  - Each of the four adapters accepts the `--runner-exit`, `--stdout-file`, and `--stderr-file` flags and rejects any other invocation shape.
  - Given a BATS runner output where individual tests fail due to assertions (not setup or syntax errors), `bats-adapter.sh` emits `assertion-failure`; given output where all tests passed, the adapter emits `pass`; given output indicating a parse or setup error before tests ran, the adapter emits `infrastructure-failure`.
  - Given a Vitest runner output indicating a module-resolution or syntax error (any failure that prevents test code from loading), `vitest-adapter.sh` emits `infrastructure-failure`; given individual test assertion failures, the adapter emits `assertion-failure`; given a clean run, the adapter emits `pass`.
  - Given a Jest runner output indicating a module-resolution or syntax error, `jest-adapter.sh` emits `infrastructure-failure`; otherwise the pass-vs-assertion-failure classification follows the same rule as above.
  - Given a pytest runner output indicating a collection or import error (a failure to load the test module before any test ran), `pytest-adapter.sh` emits `infrastructure-failure`; given individual test assertion failures, the adapter emits `assertion-failure`; given a clean run, the adapter emits `pass`.
  - Per-adapter unrecognized-output specificity: each adapter receives at least one named fixture whose output matches none of its classification rules and asserts the adapter exits `1` with a diagnostic written to stderr (e.g., for BATS: output with no `ok`/`not ok` lines and no parse-error markers; for Vitest: ANSI-escape-only output with no classification markers; for Jest: non-zero runner exit with no `FAIL`/`PASS` lines in stdout; for pytest: output beginning with `INTERNALERROR` with an exit code outside the usual classification surface). No silent default classification is emitted.
  - All four adapters run under bash 3.2 without parse errors or runtime failures.
