---
finding_id: F02
severity: low
change_type: security
referenced_files:
  - scripts/dispatch-companion.sh
---

_codex_job_id from subprocess stdout of codex-companion-bg.sh is only
checked for path-traversal (`/`, `..`) — not for newlines/CR. A
compromised codex backend returning a multi-line job id would create
a malformed .jobs/<id> record AND emit a multi-line JOB_ID. dispatch-agent
parses only the first JOB_ID= line, leading to manifest/await mismatch
(DoS — review dropped silently).

Note: sec-claude advisory observed the same surface but did not file
because of read ordering; treating as a defensible LOW finding for
defense-in-depth symmetry with the rest of the launch guard.
