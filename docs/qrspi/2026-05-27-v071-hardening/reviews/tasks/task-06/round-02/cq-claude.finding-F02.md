---
reviewer: cq-claude
round: 2
finding: F02
change_type: style
file: tests/unit/test-host-detection.bats
lines: "162-171"
severity: minor
---

# F02 — Redundant exit-code-only test for TE1 duplicates the combined test immediately above it

## Location
`tests/unit/test-host-detection.bats` lines 162–171:

```bash
@test "[host-detect] detect_host exits 0 when COPILOT_CLI=1" {
  # Test expectation: TE1 — exit code must be 0 on the copilot-cli path.
  run bash -c "
    export QRSPI_SOURCE_ONLY=1
    export COPILOT_CLI=1
    . \"$WRAPPER\"
    detect_host
  "
  [ "$status" -eq 0 ]
}
```

## Problem

The immediately preceding test (lines 149–160) already asserts `[ "$status" -eq 0 ]`
as well as `[ "$output" = "copilot-cli" ]` — making it a strict superset.  The
exit-code-only test at lines 162–171 adds no coverage that the combined test does not
already provide: if `detect_host` started exiting non-zero, both tests would fail
simultaneously.

A reader scanning the suite sees two near-identical test bodies sourcing the same
wrapper, exporting the same variable, calling the same function — and must determine
whether the second one is testing something distinct.  It is not.

## Recommended fix

Remove the exit-code-only test at lines 162–171.  The combined test already constitutes
complete coverage of TE1.  Alternatively, if the intent is to keep separate
single-assertion tests for each property (output value AND exit code as separate
concerns), the combined test should be replaced by the two narrower ones — but the
current arrangement (both combined and exit-code-only) is unambiguously redundant.
