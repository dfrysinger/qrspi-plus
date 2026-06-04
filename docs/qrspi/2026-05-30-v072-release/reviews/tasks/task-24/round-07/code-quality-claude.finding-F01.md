---
finding: F01
reviewer: code-quality-claude
round: 7
file: tests/unit/test-detect-interaction-mode.bats
lines: "322, 339 (new); 267, 306, 484, 612 (pre-existing)"
category: Test Reliability
severity: advisory
blocking: false
---

# F01 — `!`-prefixed negative assertions are silently skipped on failure

## Location

New round-07 tests:
- Line 322: `! echo "$output" | grep -q '^DETECTION_TYPE=llm-context$'`
  in `"QRSPI_INTERACTION_MODE=interactive override wins even on COPILOT_CLI=1 host"`
- Line 339: `! echo "$output" | grep -q '^DETECTION_TYPE=llm-context$'`
  in `"QRSPI_INTERACTION_MODE=interactive override (Claude Code host): emits PLATFORM=claude-code"`

Same pattern in pre-existing tests (introduced in earlier rounds, perpetuated here):
- Line 267, 306, 484: override-wins-on-host tests
- Line 612: native-detection-precedence test (`! grep -q '^PLATFORM=claude-code$'`)

## What the bash spec says

POSIX and GNU bash both specify that `set -e` (and the `ERR` trap) are
**not triggered** when the failing command is negated via `!`:

> "The -e option does not cause an exit when a pipeline prefixed with `!`
> returns a failure status."

Concretely, when `grep -q` finds the pattern (exit 0):

```
! echo "$output" | grep -q '^DETECTION_TYPE=llm-context$'
  → grep exits 0 (found)
  → ! inverts → exit 1
  → set -e would normally exit here … but the ! exemption suppresses it
  → test continues without failing
```

The negative assertion is **silently ignored** if violated. Bats inherits
this behavior: the `ERR` trap bats sets is also subject to the same `!`
exemption in all bash versions that implement the POSIX rule (3.x–5.x).

## Practical impact

In the new interactive-override×host tests the negative `!` guard is
paired with a positive `grep -q '^DETECTION_TYPE=user-override-only$'`
assertion immediately after it. That positive assertion would catch the
case where the script emits the *wrong* type entirely. What the `!` guard
defends against specifically is **duplicate output** — the script
emitting *both* `DETECTION_TYPE=user-override-only` (correct) and
`DETECTION_TYPE=llm-context` (stale, from a partial branch-cut bug). The
script's current structure (one `exit 0` per branch) makes that scenario
unlikely, but the guard was written to be authoritative and is not.

## Reliable alternative

Use `run` + status check, which is unconditionally reliable in bats:

```bash
# Instead of:
! echo "$output" | grep -q '^DETECTION_TYPE=llm-context$'

# Use:
run grep -c '^DETECTION_TYPE=llm-context$' <<< "$output"
[ "$output" -eq 0 ]
```

Or more idiomatically for a single-line check in bats:

```bash
run bash -c "echo '$BATS_OUTPUT' | grep -qc '^DETECTION_TYPE=llm-context$'"
[ "$status" -ne 0 ]
```

The clearest pattern that avoids the subshell quoting complexity is the
inline count approach used elsewhere in the suite:

```bash
local llm_count
llm_count="$(echo "$output" | grep -c '^DETECTION_TYPE=llm-context$' || true)"
[ "$llm_count" -eq 0 ]
```

`[ "$llm_count" -eq 0 ]` returns non-zero under `set -e` if the count is
non-zero, and that *is* covered by `set -e` / the bats ERR trap.

## Recommendation

Fix the two new assertions at lines 322 and 339 (round-07 additions).
Treat the four pre-existing occurrences as a backlog item so they do not
spread further. No test-logic or behavioral change required — the same
scenario is covered; only the assertion mechanism changes.
