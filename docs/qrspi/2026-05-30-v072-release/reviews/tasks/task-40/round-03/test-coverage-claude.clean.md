# Test Coverage Review — Task 40, Round 3 (claude)

**Status:** clean

## Summary

Round-03 lands a focused fix for round-02 tc-F01 (medium): the C1 enforcement
test in `tests/unit/test-ci-workflow-shape.bats` (`@test "[T40/G21] no tracked
hook script wires body-guard or bats-body-assertion (C1 enforcement)"`) now
extends its `git ls-files` prefix filter from
`^(scripts|\.husky|\.githooks|lefthook)` to
`^(scripts|\.husky|\.githooks|lefthook|\.pre-commit-config|\.pre-commit-hooks)`,
covering the pre-commit-framework config surface that tc-F01 flagged as a blind
spot.

## Coverage Analysis

### 1. Behavioral coverage of tc-F01
The R2 finding asserted that a C1 violation landing in
`.pre-commit-config.yaml` / `.pre-commit-config.yml` /
`.pre-commit-hooks.yaml` would not be caught because the prefix regex did not
include those paths. The R3 diff adds both prefixes; the inner
`grep -qE 'body-guard|bats-body-assertion' "$REPO_ROOT/$f"` substring check is
unchanged and still asserts the observable behavior the test name claims.

### 2. Edge cases
- Both `.yaml` and `.yml` filename variants are covered via prefix anchoring on
  `\.pre-commit-config` / `\.pre-commit-hooks`.
- Dot in the regex is correctly escaped, so the alternatives match only literal
  dot-prefixed top-level paths (no accidental over-match).
- Top-level anchoring (`^...`) preserves the original locality guarantee: the
  test still runs against tracked, top-level hook-config surfaces and does not
  inadvertently scan vendored copies under unrelated directories.

### 3. Error / failure modes
- Failure mode is unchanged: violations accumulate into `$violations` and the
  final `[ -z "$violations" ]` fails loudly with the offending path list. The
  fix does not weaken or vacuum the assertion.
- The `git -C "$REPO_ROOT" ls-files` source remains deterministic against the
  repo index, so the test still fires on a clean CI checkout (load-bearing
  property called out in the test comment).

### 4. Test quality
- Assertion remains behavior-oriented (no tracked hook config references the
  body-guard / bats-body-assertion surface) rather than implementation-detail
  oriented.
- The test name continues to describe the observable invariant (`C1
  enforcement`), and a failure would surface the violating filename via the
  accumulated list.
- No vacuous / tautological assertion introduced.

### 5. Missing scenarios
None newly introduced by R3. R2 findings F02 and F03 were explicitly deferred
at score=30 per dispatch and are out of scope here.

### 6. Test isolation
- No new shared mutable state.
- No execution-order dependence.
- No time-dependent behavior; relies on `git ls-files` index state which is
  deterministic in CI.

## Minor Observation (informational, not a finding)

The regex group does not cover a hypothetical dot-prefixed lefthook config
(e.g. `.lefthook.yml`); the existing `lefthook` prefix matches the canonical
`lefthook.yml` / `lefthook.yaml` / `lefthook/` shapes. This is not a tc-F01
regression and is unrelated to the deferred R2 findings; flagging only as
context, not as a coverage gap to address in this round.

## Verdict

The R3 fix correctly closes the tc-F01 coverage gap without weakening the
existing C1 enforcement assertion or introducing test-quality regressions. No
new test-coverage findings for round-03.
