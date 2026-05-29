---
finding_id: F01
severity: high
change_type: correctness
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/tasks/task-01.md, scripts/run-third-party-llm.sh]
artifact: subject_code
round: 4
reviewer: spec-codex
persistence_note: orchestrator-persisted from chat-only return (OpenAI-family task-tool transport gap, GH issue #216)
---

Spec expectation misstates actual behavior for empty `api_key_env`.

Task spec now says an empty `api_key_env` must produce a `key-resolution` diagnostic (tasks/task-01.md bullet 14).

Implementation exits earlier with a **provider-field missing** diagnostic when `api_key_env` is empty (scripts/run-third-party-llm.sh lines 560-563), so the later `key-resolution` validator branch (lines 637-639) is not reached for empty values.

Therefore, the amended spec does NOT accurately match implementation for the empty-string case.

Orchestrator note: minimal resolution = trim bullet 14 to "containing characters outside `[A-Za-z0-9_]`" (drop "or an empty string" clause); empty is covered by separate earlier die-path. Alternative = re-order validators in code to put identifier check first. Spec amendment is smaller blast radius.
