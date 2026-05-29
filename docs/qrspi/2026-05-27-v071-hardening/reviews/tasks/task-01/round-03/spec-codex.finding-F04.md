---
finding_id: F04
severity: low
change_type: scope
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/tasks/task-01.md]
artifact: subject_code
round: 3
reviewer: spec-codex
persistence_note: orchestrator-persisted from chat-only return; downgraded from advisory per reviewer-protocol schema (everything that matters becomes a finding; severity:low maps the advisory weight)
---

Target-files deviation (advisory): task target files are only scripts/run-third-party-llm.sh and tests/unit/test-run-third-party-llm.bats (tasks/task-01.md line 1477). Diff also modifies docs/qrspi/.../tasks/task-01.md (diff lines 1-19).

Orchestrator note: the task-01.md edit is the round-1 spec relaxation (commit 23ba4c8 — NUL die-message header-name carve-out) explicitly approved by user. Orchestrator decided to retroactively include task-doc as an allowed target for spec amendments. No code action needed beyond acknowledging the deviation in done-report.
