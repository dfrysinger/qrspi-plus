---
finding: F01
reviewer: tc-claude
round: 8
task: 1
severity: medium
change_type: scope
file: tests/unit/test-run-third-party-llm.bats
lines: 426-488
persistence_note: orchestrator-persisted (reviewer chat-only fallback)
---

# F01 — C0 byte exhaustive coverage absent despite spec requiring it

## Spec language (non-negotiable)
- Description: "Extended test coverage pins **each** of the 33 control bytes as a die-path trigger."
- Bullet 1: "**Every** C0 control byte (0x00 through 0x1F) supplied as a **header value** causes the script to exit"
- Bullet 2: "**Every** C0 control byte supplied as a **header name** causes the script to exit"

## Actual coverage

**Value position** (integration path via `_write_ctrl_config`):
- Tested: 0x01 SOH, 0x0B VT, 0x1B ESC, 0x1F US (line 431-465); 0x00 NUL (line 560 via pre-flight); 0x0A LF (line 524 via fn-extraction); 0x0D CR (line 632 via injection)
- **Untested: 0x02-0x09, 0x0C, 0x0E-0x1A, 0x1C-0x1E — 25 of 32 C0 bytes**

**Name position**:
- Tested: 0x01 SOH (line 471), 0x0D CR (line 480); DEL 0x7F (line 506)
- **Untested: 0x02-0x09, 0x0A-0x0C, 0x0E-0x1C, 0x1E-0x1F — 28 of 32 C0 bytes**

Test comment at line 427 acknowledges the deliberate choice: "Representative bytes: SOH (0x01), VT (0x0B), ESC (0x1B), US (0x1F)."

## Why it matters

Implementation uses `tr -d '\040-\176\200-\377'` — a byte-range deletion. A regression that silently widens the deletion range (e.g., `\040` → `\020` would erroneously delete 0x10-0x1F) would not be caught by any existing test for bytes in the 0x10-0x1A range. Same for name-side range errors covering 0x02-0x09, 0x0C, 0x0E-0x1F. The `tr` approach is correct *now*, but the suite does not mechanically pin each byte the spec guarantees will be blocked.

## Suggested remediation

Add a parametric loop test (or two dense `@test` blocks) exercising every byte in 0x00-0x1F and 0x7F, either via direct `_control_char_check` function calls or via `_write_ctrl_config` for bytes that survive the awk config parse. LF function-extraction pattern demonstrates a workable approach for bytes that can't pass through the YAML line parser.

**Note**: change_type=scope bypasses the ≥80 score filter per SKILL and routes to user gate.
