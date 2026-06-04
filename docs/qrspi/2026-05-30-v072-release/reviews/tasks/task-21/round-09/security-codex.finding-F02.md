---
finding_id: F02
severity: high
change_type: security
referenced_files:
  - scripts/dispatch-companion.sh
---

Job-record line injection in the launch handler. dispatch-companion.sh
writes `key=value\n` lines per --vendor/--model/--prompt-file/--round-dir/--tag
to the per-job record without rejecting newlines or carriage returns.
The await handler parses these records with `sed | head -1` (first match
wins). A control-character-bearing --vendor like `codex\ncodex_job_id=<x>\ntag=<y>`
synthesizes additional record lines and lets await read forged routing
fields back, diverting it to an attacker-chosen broker job or output path.

Closed in fix-cycle 10 (commit 4ec927b): added newline/CR rejection on
every raw launch arg value before the existing tag-allowlist check.
Regression test added.
