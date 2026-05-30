---
finding_id: F04
reviewer: silent-failure-claude
round: 2
task: Task 8
category: PARTIAL_STATE
severity: high
---

# F04 — Task 8: Structural retirement-invariant test dropped; partial cache removal passes CI silently

## Location

Task 8 target files (removed from R2) and test expectations.

## What the round-01 plan said (removed in R2)

Round-01 included `tests/unit/test-cache-mechanism-retired.bats` (create) in the target files and described:

> A new structural test file asserts the post-retirement invariants (deleted files absent, patterns absent from modified files); these assertions fail RED against current state and pass GREEN after all deletions and removals land.

## What the round-02 plan says instead

`tests/unit/test-cache-mechanism-retired.bats` was removed from the target files list. The description now reads:

> Deletions and removals are a mechanical sweep with no new design surface; CI-green is the acceptance gate per Design DKR8.

The task still lists "patterns absent" test expectations:

- `scripts/run-third-party-llm.sh` contains no `cache_control` key emission logic after modification
- `skills/using-qrspi/SKILL.md` contains no references to `supports_prompt_cache` or `emit_cache_control_markers` after modification
- `tests/unit/test-run-third-party-llm.bats` contains no cache-control truth-table test blocks after modification

## The silent failure

Task 8 **deletes** four test files including:

- `tests/unit/test-cache-control-capability-gate.bats` — the suite that exercised the cache-control branches in `run-third-party-llm.sh`
- `tests/unit/test-cache-hit-rate.bats` — the suite that covered cache-path conditions

When these test files are deleted, CI no longer exercises the cache-control code paths. If the implementer removes the test files but **leaves the `cache_control` logic in `run-third-party-llm.sh`** (partial retirement), CI will pass:

- The deleted test files are gone — no tests fail for their absence
- The residual cache logic in the script has no test exercising it — no tests fail for its presence
- CI is green on a half-retired mechanism

The test expectations for Task 8 state that `run-third-party-llm.sh` must contain no `cache_control` emission logic, but **without `test-cache-mechanism-retired.bats`** there is no CI-testable assertion that enforces this condition. The expectations become documentation of intent, not automated enforcement.

## The partial-state shape

Task 8 performs a multi-file deletion and multi-file modification sweep. The retirement boundary must close atomically across all five surfaces (script, SKILL prose, spike doc, two unit suites). The structural test file was the mechanism that would have detected "four files deleted but residual patterns remain in modified files." With it gone:

- Deleting the four files alone → CI green (silent partial retirement)
- Removing patterns from files alone → CI green (no test exercises the patterns, so no test breaks)
- Only the combination: deleting files AND removing patterns → correct state

No automated test distinguishes partial from complete retirement.

## Why this matters at runtime

The `cache_control` marker emission branch in `run-third-party-llm.sh` is a conditional code path. If left in place after `g4-cache-probe.sh` is deleted, a downstream pipeline configuration that still specifies `supports_prompt_cache: true` would reach the marker branch—which now references deleted infrastructure—and fail at runtime. The retirement appears complete on the surface (test files gone, CI green) while the mechanism is still partially live in the dispatch script.

## Proposed fix

Restore `tests/unit/test-cache-mechanism-retired.bats` to the target files. This file should contain structural grep assertions:

> The file `scripts/run-third-party-llm.sh` does not contain the string `cache_control` (grep absence assertion against the current repository file).

> The file `skills/using-qrspi/SKILL.md` does not contain the strings `supports_prompt_cache` or `emit_cache_control_markers`.

These assertions are independent of the deleted test files; they verify the modified-files side of the retirement sweep. They will fail RED before Task 8 (the patterns exist) and pass GREEN after all removals land, giving the implementer a machine-checkable gate for completeness.
