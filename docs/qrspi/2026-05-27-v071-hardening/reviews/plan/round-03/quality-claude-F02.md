---
id: quality-claude-F02
reviewer: quality-claude
round: 3
severity: low
task: Task 6
status: open
---

# F02 — Task 6: `detect_host` test expectation labels `COPILOT_CLI=""` a "non-empty" value (self-contradiction)

## Location

`plan.md` § Task 6 — Test expectations, third bullet (line 187 of current plan)

## Finding

The third test expectation bullet reads:

> `detect_host` emits `claude-code` to stdout and returns exit code 0 when `COPILOT_CLI` is set to **any non-empty value other than `1`** (including `COPILOT_CLI=0`, `COPILOT_CLI=true`, or `COPILOT_CLI=""`); the design intentionally defaults to Claude Code for all non-`=1` values to avoid breaking environments that set `COPILOT_CLI` to suppress signaling

`COPILOT_CLI=""` (the variable set to an empty string) is **not** a non-empty value; it is a set-but-empty value. Listing it parenthetically under an umbrella of "non-empty values" is self-contradictory, and creates two problems for the test-writer:

1. **Coverage gap risk.** A test-writer who reads "non-empty value" literally and writes one test for `COPILOT_CLI=0` and one for `COPILOT_CLI=true` will believe the umbrella is fully covered — the parenthetical `COPILOT_CLI=""` sits in a "non-empty" sentence and can be mentally filed as a redundant example rather than a third, distinct case. The "set but empty" state is a distinct shell state (`${COPILOT_CLI+x}` is set; `${COPILOT_CLI}` is empty) that any implementation distinguishing "set=1" from "all other set values" must handle correctly.

2. **Implementer confusion.** An implementer reading the bullet might attempt to distinguish `COPILOT_CLI=""` as a third branch (empty-but-set), which is unnecessary per DKR6's 2-branch design but is implied by the contradictory prose.

The correct formulation is: "emits `claude-code` when `COPILOT_CLI` is set to any value that is not equal to the string `1` — including unset, set-but-empty (`COPILOT_CLI=""`), and any non-empty non-`1` value such as `COPILOT_CLI=0` or `COPILOT_CLI=true`."

Note: the second bullet covers `COPILOT_CLI` unset; this third bullet should be explicitly described as covering the "set but not `=1`" branch (including the empty-string case).

## Required Fix

Rewrite the third test expectation bullet to replace "non-empty value" with accurate language:

> `detect_host` emits `claude-code` to stdout and returns exit code 0 when `COPILOT_CLI` is set to any value not equal to the string `1` — including set-but-empty (`COPILOT_CLI=""`), `COPILOT_CLI=0`, and `COPILOT_CLI=true`; the design defaults to Claude Code for all non-`=1` values to avoid breaking environments that set `COPILOT_CLI` to suppress signaling
