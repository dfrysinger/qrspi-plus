---
finding: F02
reviewer: code-simplifier-claude
round: 7
file: tests/unit/test-detect-interaction-mode.bats
lines: 296-308
category: Inconsistency
severity: advisory
blocking: false
---

# F02 — `auto`-override host test is weaker than its `interactive` twin

## Location

`tests/unit/test-detect-interaction-mode.bats`, lines 296–308 vs.
lines 310–325.

## Pattern observed

The two "override wins even on a recognized host" tests are mirror
scenarios, but the `auto` variant is noticeably weaker:

**`auto` test (lines 296–308) — current:**
```bats
@test "[T24] QRSPI_INTERACTION_MODE=auto override wins even on COPILOT_CLI=1 host" {
  run bash -c "
    export COPILOT_CLI=1
    export QRSPI_INTERACTION_MODE=auto
    bash \"$SCRIPT\"
  "
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '^VERDICT=auto$'
  ! echo "$output" | grep -q '^DETECTION_TYPE=llm-context$'
  echo "$output" | grep -q '^DETECTION_TYPE=user-override-only$'
}
```

**`interactive` twin (lines 310–325) — current:**
```bats
@test "QRSPI_INTERACTION_MODE=interactive override wins even on COPILOT_CLI=1 host" {
  run bash -c "
    export COPILOT_CLI=1
    unset CLAUDE_PROJECT_DIR          # ← explicit env isolation
    export QRSPI_INTERACTION_MODE=interactive
    bash \"$SCRIPT\"
  "
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '^PLATFORM=copilot-cli$'   # ← PLATFORM asserted
  echo "$output" | grep -q '^VERDICT=interactive$'
  ! echo "$output" | grep -q '^DETECTION_TYPE=llm-context$'
  echo "$output" | grep -q '^DETECTION_TYPE=user-override-only$'
  echo "$output" | grep -q '^EVIDENCE=.*QRSPI_INTERACTION_MODE.*interactive'  # ← EVIDENCE asserted
}
```

Two differences:

1. **Missing `unset CLAUDE_PROJECT_DIR`** — The test strategy comment at
   lines 34–37 states that subshells use "explicit env overrides so that
   the host's own COPILOT_CLI=1 does not bleed into tests for other
   branches."  The `auto` test omits the `unset`, meaning a parent-env
   `CLAUDE_PROJECT_DIR` could silently change which PLATFORM token the
   override block emits to `claude-code` instead of `copilot-cli`.

2. **Missing `PLATFORM=copilot-cli` and `EVIDENCE` assertions** — The
   `interactive` twin verifies both, but the `auto` variant checks only
   VERDICT and DETECTION_TYPE.  A regression that emitted the wrong
   PLATFORM token (or omitted EVIDENCE) would pass the `auto` test and
   fail the `interactive` test — an asymmetry that makes the suite
   harder to reason about.

## Proposed fix

Bring the `auto` test up to parity with its `interactive` twin:

```bats
@test "[T24] QRSPI_INTERACTION_MODE=auto override wins even on COPILOT_CLI=1 host" {
  run bash -c "
    export COPILOT_CLI=1
    unset CLAUDE_PROJECT_DIR
    export QRSPI_INTERACTION_MODE=auto
    bash \"$SCRIPT\"
  "
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '^PLATFORM=copilot-cli$'
  echo "$output" | grep -q '^VERDICT=auto$'
  ! echo "$output" | grep -q '^DETECTION_TYPE=llm-context$'
  echo "$output" | grep -q '^DETECTION_TYPE=user-override-only$'
  echo "$output" | grep -q '^EVIDENCE=.*QRSPI_INTERACTION_MODE.*auto'
}
```

No new test scenarios — same assertions as the `interactive` twin,
transposed to `auto`.
