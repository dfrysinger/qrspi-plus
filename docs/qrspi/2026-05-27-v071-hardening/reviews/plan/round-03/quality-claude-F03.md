---
id: quality-claude-F03
reviewer: quality-claude
round: 3
severity: medium
task: Task 8
status: open
introduced_by: R2
---

# F03 — Task 8 (R2 regression): Path-scope constraint weakened to bare declarative — verification mechanism removed

## Location

`plan.md` § Task 8 — Test expectations block, seventh bullet (line 237 of current plan)

## Finding

Round 2 replaced the following test expectation:

> The `git diff --name-only` output for the Task 8 commit does not list any path under `docs/qrspi/2026-04-29-v0.4-bundle/` or `docs/superpowers/`; a path-scope assertion in the modify-pass verifies historical run-record directories are not touched

with:

> The Task 8 commit modifies no path under `docs/qrspi/2026-04-29-v0.4-bundle/` or `docs/superpowers/`

The new version is a bare declarative statement with no named verification mechanism. As written, this expectation:

1. **Cannot produce a RED-phase failure.** The test-writer has no specification for what file to write the assertion in, what tool to use, or what observable output to assert. No target file in Task 8's `Target files` list is a logical home for a "verify no paths outside this set were modified" structural lint test.

2. **Has no enforcement surface at CI.** The existing CI jobs (Lint + BATS-under-bash-3.2) do not contain a gate that checks the diff scope of individual commits. If an implementer's mechanical sweep accidentally touches a file under `docs/qrspi/2026-04-29-v0.4-bundle/`, no test fails.

3. **Is misplaced in Test Expectations.** A constraint with no concrete test surface belongs in the Description as an implementation guard ("Task 8 must not modify any file under... — the implementer verifies this before committing via `git diff --name-only HEAD`"), not in Test Expectations as if it were a verifiable BATS assertion.

This is a regression from R2: the prior version at least named a concrete tool (`git diff --name-only`) and a named mechanism ("path-scope assertion in the modify-pass") that indicated what to check, even if the host file was implicit. The R2 simplification removed that specificity without providing an alternative enforcement surface.

## Required Fix

Either:

**Option A (preferred):** Move the constraint into the Task 8 Description as an explicit implementation guard, and remove it from Test Expectations:

> _Description addition:_ "Before committing, the implementer must verify that `git diff --name-only` against the task branch lists no path under `docs/qrspi/2026-04-29-v0.4-bundle/` or `docs/superpowers/`; historical run records are not touched by this mechanical deletion."

**Option B:** Reinstate a concrete test expectation naming the verification tool and file:

> The `git diff --name-only` output for the Task 8 commit lists no path under `docs/qrspi/2026-04-29-v0.4-bundle/` or `docs/superpowers/`; verified by a static `grep`-based assertion in `tests/acceptance/v07-phase1/test-phase1-acceptance.bats` that checks Task 8's target-file list against those prefixes.
