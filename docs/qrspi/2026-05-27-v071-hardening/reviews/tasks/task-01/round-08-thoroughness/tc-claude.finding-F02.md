---
finding: F02
reviewer: tc-claude
round: 8
task: 1
severity: low
change_type: correctness
file: tests/unit/test-run-third-party-llm.bats
lines: 550
persistence_note: orchestrator-persisted (reviewer chat-only fallback)
---

# F02 — LF regression test uses imprecise exit-code assertion

Line 550: `[ "$status" -ne 0 ]`
Should be: `[ "$status" -eq 1 ]`

## Why

`die()` unconditionally calls `exit 1`. 29+ sibling die-path tests use `[ "$status" -eq 1 ]`. This LF test is one of the few remaining exceptions (R5 fixed the other one).

`-ne 0` allows exit codes 2, 127 (command not found), or any other non-zero value — masking scenarios where the function crashes rather than dies gracefully. Particularly relevant because the LF test involves bash script construction + sourcing (`_extract_ctrl_check_fn`) where a syntax error or missing helper would produce non-1 non-zero exit.

## Fix
Change line 550: `-ne 0` → `-eq 1`. Same as the R5 hand-fix for the API-key test.
