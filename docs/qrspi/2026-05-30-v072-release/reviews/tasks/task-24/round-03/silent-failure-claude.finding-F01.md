---
finding: F01
reviewer: silent-failure-claude
round: 3
artifact: tests/unit/test-detect-interaction-mode.bats
lines: 256-265
severity: medium
category: silent-pass-hazard
---

# Silent Pass: Claude Code + Override Combination Lacks DETECTION_TYPE / VERDICT Assertions

## What Was Fixed (Round 2 — Verified Correct)

The test `"[T24] QRSPI_INTERACTION_MODE=auto override wins even on COPILOT_CLI=1 host"` at
lines 293–304 now carries three independent assertions:

```bash
echo "$output" | grep -q '^VERDICT=auto$'
! echo "$output" | grep -q '^DETECTION_TYPE=llm-context$'
echo "$output" | grep -q '^DETECTION_TYPE=user-override-only$'
```

A regression that breaks the override on Copilot CLI (e.g., reordering the host-detection
`if` block before the override check) would fail at assertion 1 immediately, and would also
fail at assertions 2 and 3. The negative assertion is genuine and functional.

## Remaining Silent-Pass Hazard (New Finding)

The equivalent test for the **Claude Code + override** combination does **not** include those
assertions. The sole test that exercises `CLAUDE_PROJECT_DIR` set alongside
`QRSPI_INTERACTION_MODE=auto` is:

```bash
# tests/unit/test-detect-interaction-mode.bats, lines 256–265
@test "[T24] QRSPI_INTERACTION_MODE=auto override (Claude Code host): emits PLATFORM=claude-code" {
  run bash -c "
    unset COPILOT_CLI
    export CLAUDE_PROJECT_DIR='/some/project'
    export QRSPI_INTERACTION_MODE=auto
    bash \"$SCRIPT\"
  "
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '^PLATFORM=claude-code$'
}
```

This asserts **only** `PLATFORM=claude-code`. The problem is that _both_ possible code paths
emit `PLATFORM=claude-code`:

| Path actually taken | PLATFORM | DETECTION_TYPE | VERDICT |
|---|---|---|---|
| Override wins (correct) | `copilot-cli` / `claude-code` / `unknown` | `user-override-only` | `auto` |
| Claude Code host branch runs (regression) | `claude-code` | `llm-context` | *(absent)* |

When `CLAUDE_PROJECT_DIR` is set, the override path also emits `PLATFORM=claude-code`
(script lines 105–108 mirror the host discriminators inside the override block). So the
single assertion `grep -q '^PLATFORM=claude-code$'` is satisfied by **both** paths and
cannot distinguish them.

### Regression Scenario

If someone reorders the `if` chain in `detect-interaction-mode.sh` so that the
`elif [[ -n "${CLAUDE_PROJECT_DIR:-}" ]]` host-detection branch appears before the
`QRSPI_INTERACTION_MODE` override check:

- `PLATFORM=claude-code` is emitted → **test passes**
- `DETECTION_TYPE=llm-context` is emitted instead of `user-override-only` → *not checked*
- No `VERDICT` line is emitted → *not checked*

The test suite reports green while the override contract is broken for every Claude Code
user who sets `QRSPI_INTERACTION_MODE`.

No other test in the suite covers this combination; the general override tests
(`QRSPI_INTERACTION_MODE=auto override (unknown host): emits DETECTION_TYPE=user-override-only`,
etc.) all use `unset COPILOT_CLI CLAUDE_PROJECT_DIR` and therefore do not exercise the
conflict between Claude Code host detection and override priority.

### Contrast with the Fixed Test

For Copilot CLI the test at line 293 explicitly checks:

```bash
! echo "$output" | grep -q '^DETECTION_TYPE=llm-context$'
echo "$output" | grep -q '^DETECTION_TYPE=user-override-only$'
```

No parallel negative+positive guard exists for Claude Code.

## Suggested Fix

Add a dedicated test (or extend the existing one) for the Claude Code + override case that
mirrors the structure now used for Copilot CLI:

```bash
@test "[T24] QRSPI_INTERACTION_MODE=auto override wins even on CLAUDE_PROJECT_DIR host" {
  run bash -c "
    unset COPILOT_CLI
    export CLAUDE_PROJECT_DIR='/some/project'
    export QRSPI_INTERACTION_MODE=auto
    bash \"$SCRIPT\"
  "
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '^VERDICT=auto$'
  # Must NOT emit DETECTION_TYPE=llm-context when override wins
  ! echo "$output" | grep -q '^DETECTION_TYPE=llm-context$'
  echo "$output" | grep -q '^DETECTION_TYPE=user-override-only$'
}
```

The existing test can keep its PLATFORM check; the new test adds the discriminating
assertions that make it a genuine regression detector.

## Secondary Note: Grep Regression Tests on Absent Directories

The tests at lines 430–452 of the form:

```bash
run grep -rl 'autopilot_mode' "$REPO_ROOT/skills"
[ "$status" -ne 0 ]
```

pass vacuously if the `skills/` or `agents/` directories do not exist, because `grep -rl`
returns exit code 2 (error) when the path is absent. `[ "$status" -ne 0 ]` is satisfied
by both "no matches" (exit 1) and "directory missing" (exit 2). The test does not
distinguish between encapsulation being maintained and the directory simply not being there.
This is a pre-existing weaker concern (not introduced in round 2) but is noted here for
completeness. Fixing it would require a `[ -d "$REPO_ROOT/skills" ]` prerequisite guard.
