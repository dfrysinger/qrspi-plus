---
finding_id: F02
round: 2
reviewer: test-coverage-claude
severity: medium
task: Task 6
category: edge_cases
status: open
---

# F02 — Task 6: `COPILOT_CLI=""` (set-to-empty) behavior is unspecified

## Problem

The R2 diff narrows the `detect_host` → `claude-code` expectation from
"unset **or set to empty**" (R1) to "unset" only (R2). This creates an untested
boundary condition: `COPILOT_CLI=""` (variable set but empty).

**R1 wording (removed):**
> The host-identification function emits `claude-code` to stdout when `COPILOT_CLI` is
> **unset or set to empty**

**R2 wording (replacement):**
> `detect_host` emits `claude-code` to stdout when `COPILOT_CLI` is **unset**

**The three R2 cases and the gap:**

| COPILOT_CLI value | R2 expectation |
|---|---|
| `COPILOT_CLI=1` | → `copilot-cli` (item 1) |
| Unset | → `claude-code` (item 2) |
| Non-empty non-`1` (e.g., `0`, `true`) | → non-zero + stderr diagnostic (item 3) |
| **`""` (set to empty)** | **← no expectation; behavior undefined** |

## Why This Is an Actionable Gap

Under common bash idioms the distinction matters:

- `[[ -z "$COPILOT_CLI" ]]` is true for both unset and empty-string — silent
  `claude-code` default
- `[[ ! -v COPILOT_CLI ]]` is true only for unset — empty-string triggers error branch
- Item 3 says "any non-empty value other than `1`" returns an error — an empty string is
  not non-empty, so item 3's error path does NOT cover it

Without a test expectation, the test writer may implement the boundary differently from
what the design intends, and the resulting behaviour will not be caught during review.
This is particularly relevant because CI-level bash-3.2 portability testing (as the
enforcement surface for portable idioms) does not distinguish between "unset" and
"empty" in the same way across bash versions.

## Required Fix

Add one test expectation that specifies the intended behaviour for `COPILOT_CLI=""`.
Either of the following is acceptable; pick one and make it explicit:

**Option A (treat empty as claude-code, matching R1):**
> `detect_host` emits `claude-code` to stdout when `COPILOT_CLI` is set to the empty
> string (`COPILOT_CLI=""`), treating set-but-empty the same as unset

**Option B (treat empty as an invalid value, emit diagnostic):**
> `detect_host` with `COPILOT_CLI` set to the empty string returns non-zero and emits a
> single-line diagnostic to stderr naming the rejected value — treated equivalently to
> other non-`1` non-unset values
