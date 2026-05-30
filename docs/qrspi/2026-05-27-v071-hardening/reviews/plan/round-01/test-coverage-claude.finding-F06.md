# Finding F06: Task 6 — "bash-3.2 portable" is a constraint, not an observable test expectation

**Artifact:** plan.md
**Task:** Task 6 (G6 part 1 — host-detection and Codex availability functions)
**Category:** Test Expectation Quality
**Severity:** advisory

## Problem

The expectation "Both functions are bash-3.2 portable (no bash 4+ features)" describes an implementation constraint, not a behavior observable by a test harness.

There is no BATS assertion that can verify "uses no bash 4+ features" — static analysis is out of scope for BATS, and the test file `tests/unit/test-host-detection.bats` is a unit test, not a lint job. The constraint cannot be made falsifiable at the test level without an additional mechanism.

However, the CI pipeline already has a "BATS-under-bash-3.2 job" that would catch this: if the functions use bash 4+ syntax, that job fails. The constraint is therefore already enforced by the CI structure, making the expectation redundant as written — but also impossible to translate into a new BATS test beyond "the job passes."

## Recommendation

Replace this expectation with an observable CI-gated form:

- "Both functions execute without error when sourced in the BATS-under-bash-3.2 CI job (the existing bash-3.2 CI job is the enforcement mechanism; no separate BATS assertion is required)."

Or, alternatively, convert it into a structural constraint noted in the description (not in test expectations), since the CI infrastructure already enforces it and no new test needs to be written.
