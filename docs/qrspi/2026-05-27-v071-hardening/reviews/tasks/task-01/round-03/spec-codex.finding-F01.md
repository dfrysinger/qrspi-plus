---
finding_id: F01
severity: high
change_type: scope
referenced_files: [scripts/run-third-party-llm.sh, tests/unit/test-run-third-party-llm.bats]
artifact: subject_code
round: 3
reviewer: spec-codex
persistence_note: orchestrator-persisted from chat-only return (OpenAI-family task-tool transport gap, GH issue #216)
---

Out-of-scope feature: API key control-character screening added.

Spec scope: task is about replacing `default_headers` control-char detection in openai pre-flight (tasks/task-01.md lines 1475-1481, expectations lines 1482-1493).

Implementation added extra behavior: API key value is now screened via `_control_char_check` (scripts/run-third-party-llm.sh lines 649-654 in dispatch subject_code).

Extra test added for this new behavior: tests/unit/test-run-third-party-llm.bats lines 1440-1460.

This is not requested by task-01 and changes runtime behavior beyond spec. Either amend the spec to back-name the API-key screening as in-scope, or revert the fix.

Orchestrator note: added as in-scope per user "if in codebase, just fix it" directive against security-claude.F01 (round-02 finding, verifier score 30). Spec amendment is the preferred fix per user policy.
