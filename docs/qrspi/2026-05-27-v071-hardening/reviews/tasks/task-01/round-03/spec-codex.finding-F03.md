---
finding_id: F03
severity: high
change_type: correctness
referenced_files: [tests/unit/test-run-third-party-llm.bats]
artifact: subject_code
round: 3
reviewer: spec-codex
persistence_note: orchestrator-persisted from chat-only return (OpenAI-family task-tool transport gap, GH issue #216)
---

Incomplete test coverage vs spec text ("pin each of 33 control bytes").

Spec explicitly says: "Extended test coverage pins each of the 33 control bytes" (tasks/task-01.md line 1480).

Tests only sample subset of C0 bytes: e.g., value tests cover SOH/VT/ESC/US (tests/unit/test-run-third-party-llm.bats lines 1112-1146) and name tests cover only SOH/CR (1152-1168), plus separate DEL/LF/NUL checks.

There is no exhaustive 33-byte pin set in tests, so this requirement is not fully implemented.

Orchestrator note: needs investigation. Options: (a) add the missing exhaustive 33-byte loop test, or (b) amend spec text to describe what coverage actually exists (structural pin of tr-range + assertion-class samples is the equivalence-class argument Claude's round-01 spec-reviewer accepted). Verifier-dispatch should help triage.
