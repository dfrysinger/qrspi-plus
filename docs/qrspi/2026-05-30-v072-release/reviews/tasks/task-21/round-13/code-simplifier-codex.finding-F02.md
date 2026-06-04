---
finding_id: R13-F02
severity: low
change_type: clarity
reviewer_tag: code-simplifier-codex
referenced_files: [scripts/dispatch-agent.sh]
---

# Duplicated job-id validation grammar

Same job-id regex grammar exists in two places: helper at ~L2181–L2194
(`_validate_job_id`, exit-on-fail) and an inline reimplementation at
~L2770–L2780 that intentionally avoids hard-exit/orphan behavior.
Suggested refactor: split into a shared predicate (e.g.,
`_job_id_is_valid` returning 0/1) plus caller-specific handling
(fatal vs warn/continue) to remove duplicated grammar and drift risk.

Behavior-preserving. Non-blocking.
