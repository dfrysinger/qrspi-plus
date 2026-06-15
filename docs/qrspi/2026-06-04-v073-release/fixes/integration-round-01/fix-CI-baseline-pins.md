---
status: approved
task: fix-CI-baseline-pins
pipeline: full
task_type: tdd
references_finding: CI gate baseline failures (Integrate CI sub-gate, pre-emptive)
references_tasks: [T09, T13a, T28, T29]
---

# Fix CI baseline pin tests for v0.7.3 release artifacts

## Context

Four pin tests fail at integration-merged HEAD because they pin v0.7.2-era counts/strings that legitimately changed during the v0.7.3 Phase 1 work:

1. **`tests/unit/test-agent-frontmatter-no-model.bats` @ line 49** — pins `count -eq 41` but `agents/qrspi-*.md` is now 42 files (Phase 1 added `qrspi-plan-apply-fix.md`).
2. **`tests/unit/test-ci-workflow-shape.bats` @ line 322** — pins `count = 1` workflow file but Phase 1 task T29 intentionally added `.github/workflows/build-then-diff.yml` alongside `ci.yml` (now 2 files). Test description mentions "no sibling workflow added by G32" — the design decision changed (build-then-diff IS a planned sibling per T29 in `parallelization.md`).
3. **`tests/acceptance/v07-phase1/test-phase1-acceptance.bats` @ line 73 (`[Phase1 Slice 3 C-1]`)** — wraps the #2 test above; fails transitively.
4. **`tests/acceptance/v07-phase1/test-phase1-acceptance.bats` @ line 3146** — pins `version === "0.7.2"` in `.claude-plugin/marketplace.json` but `VERSION` and the live `marketplace.json` already carry `0.7.3` (per T28 version stamping).

## Target files

- `tests/unit/test-agent-frontmatter-no-model.bats` (M)
- `tests/unit/test-ci-workflow-shape.bats` (M)
- `tests/acceptance/v07-phase1/test-phase1-acceptance.bats` (M)

## Required edits

### A — agent count pin: 41 → 42

In `tests/unit/test-agent-frontmatter-no-model.bats`:
- Update the count assertion `[ "$count" -eq 41 ]` to `[ "$count" -eq 42 ]`
- Update the test description from "sweep matches the expected 41 qrspi agent files" to "sweep matches the expected 42 qrspi agent files"
- Update the error message from "expected 41 agents/qrspi-*.md files" to "expected 42 agents/qrspi-*.md files"

### B — workflow count pin: 1 → 2

In `tests/unit/test-ci-workflow-shape.bats`:
- Update the count assertion `[ "$count" = "1" ]` to `[ "$count" = "2" ]`
- Update the test description from "CI keeps a single workflow file (no sibling workflow added by G32)" to "CI carries the two planned workflow files (ci.yml + build-then-diff.yml per T29)"
- Add a content assertion that BOTH expected workflow files exist by name: `[ -f "$REPO_ROOT/.github/workflows/ci.yml" ] && [ -f "$REPO_ROOT/.github/workflows/build-then-diff.yml" ]`

### C — marketplace pin: v0.7.2 → v0.7.3

In `tests/acceptance/v07-phase1/test-phase1-acceptance.bats`:
- Update the test description from "qrspi plugin carries v0.7.2 release metadata" to "qrspi plugin carries v0.7.3 release metadata"
- Update the Node version-comparison from `q.version==="0.7.2"` to `q.version==="0.7.3"`

### D — wrapper test description (transitive)

In the same `tests/acceptance/v07-phase1/test-phase1-acceptance.bats`, the `[Phase1 Slice 3 C-1]` wrapper runs the underlying pin test — once B lands, C-1 will pass without code changes. Verify it does and do NOT edit C-1 unless the description still incorrectly says "single".

## Test Expectations

After the fix lands:
- `bats --tap tests/unit/test-agent-frontmatter-no-model.bats` GREEN (all tests)
- `bats --tap tests/unit/test-ci-workflow-shape.bats` GREEN (all tests)
- `bats --tap tests/acceptance/v07-phase1/test-phase1-acceptance.bats` GREEN (specifically the marketplace and Slice 3 C-1 tests; the rest already pass)
- No other test file modified.

## Out of scope

- Adding new workflow files
- Modifying `.claude-plugin/marketplace.json` or `VERSION` (already at v0.7.3)
- Modifying agent files

This is a pure test-pin bump.
