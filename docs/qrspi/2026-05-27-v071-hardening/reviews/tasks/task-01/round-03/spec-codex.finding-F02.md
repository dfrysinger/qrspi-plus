---
finding_id: F02
severity: high
change_type: scope
referenced_files: [scripts/run-third-party-llm.sh]
artifact: subject_code
round: 3
reviewer: spec-codex
persistence_note: orchestrator-persisted from chat-only return (OpenAI-family task-tool transport gap, GH issue #216)
---

Out-of-scope feature: api_key_env identifier validator + eval removal behavior change.

Spec scope: no requirement to alter API key env-var resolution mechanism (tasks/task-01.md lines 1475-1493).

Implementation changed behavior: added api_key_env format gate and switched from eval-based lookup to indirect expansion (scripts/run-third-party-llm.sh lines 633-645).

This is additional functionality outside task-01 scope.

Orchestrator note: added as in-scope per user "if in codebase, just fix it" directive against security-claude.F02 (round-02 finding, verifier score 20). Spec amendment to mention eval-removal + identifier-validator defense-in-depth is the preferred fix per user policy.
