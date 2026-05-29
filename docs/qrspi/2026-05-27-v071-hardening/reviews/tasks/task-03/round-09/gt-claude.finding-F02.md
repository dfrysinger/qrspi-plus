---
reviewer: gt-claude
round: 9
task: task-03
finding_id: F02
change_type: style
severity: low
file: reviews/tasks/task-03/done-report.md
---

# F02 — done-report.md implementation note is stale (superseded by mktemp fix)

## Finding

`done-report.md` (line 18) reads:

> Bash 3.2 portable; PID-scoped signal file (/tmp/skill-md-fence-signal-$$) for awk-to-shell communication

The current implementation uses `mktemp "${TMPDIR:-/tmp}/skill-md-fence-signal-XXXXXXXX"` (not PID-scoped). The PID-scoped path was replaced during rounds 5–8 as part of the sec.F01 TOCTOU hardening. The done-report was written before those fixes landed.

## Impact

No production impact. The done-report is an audit record, not a live artifact. However, the note incorrectly describes the implementation and could confuse a reader examining the done-report alongside the source.

## Suggested fix

Update the implementation note to reflect the current approach:

```
Bash 3.2 portable; mktemp-generated signal file (XXXXXXXX suffix) for awk-to-shell
communication; predictable PID-scoped path replaced by mktemp in sec.F01 hardening.
```
