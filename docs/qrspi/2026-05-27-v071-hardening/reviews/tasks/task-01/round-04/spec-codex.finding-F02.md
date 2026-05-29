---
finding_id: F02
severity: high
change_type: correctness
referenced_files: [tests/unit/test-run-third-party-llm.bats]
artifact: subject_code
round: 4
reviewer: spec-codex
persistence_note: orchestrator-persisted from chat-only return
---

New test expectation for `api_key_env` identifier validation is not covered by tests.

Spec adds expectation that invalid/empty `api_key_env` is rejected (tasks/task-01.md bullet 14).

Test file includes key-resolution tests for env var unset/empty VALUE (lines 847-863), but no test for malformed `api_key_env` IDENTIFIER content in config.md.

So not all current spec test expectations are asserted.

Orchestrator note: matches spec-claude.F02 — bullet 14 needs a backing test asserting `api_key_env: MY-BAD-KEY` (invalid identifier) → exit 1 with `key-resolution` diagnostic.
