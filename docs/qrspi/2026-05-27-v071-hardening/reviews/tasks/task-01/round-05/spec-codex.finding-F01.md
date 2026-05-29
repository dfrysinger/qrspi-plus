---
finding_id: F01
severity: medium
change_type: clarity
referenced_files: [tests/unit/test-run-third-party-llm.bats]
artifact: subject_code
round: 5
reviewer: spec-codex
persistence_note: orchestrator-persisted from chat-only return (OpenAI-family transport gap, GH #216)
adjudication: KEPT, orchestrator hand-fix (single-char convention alignment; not worth spawning a 4th fix-cycle agent)
---

The new `api_key_env` invalid-character regression test (test-run-third-party-llm.bats:174-182) asserts `[ "$status" -ne 0 ]` rather than `[ "$status" -eq 1 ]`. Convention in this file: all 7 other key-resolution tests (lines 119/127/133/139/146/159/168) and 29 of 32 total exit-failure assertions use `-eq 1`. The looser `-ne 0` would pass even if the script crashed with exit 127 or segfault-derived status as long as the output happened to contain "key-resolution", weakening the regression guard.

Recommendation: change line 180 to `[ "$status" -eq 1 ]`.
