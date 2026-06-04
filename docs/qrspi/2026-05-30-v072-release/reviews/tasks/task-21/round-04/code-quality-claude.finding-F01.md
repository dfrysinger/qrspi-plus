---
finding_id: F01
reviewer: code-quality-claude
severity: low
change_type: hygiene
referenced_files: [tests/unit/test-dispatch-agent.bats:1429-1431, tests/unit/test-dispatch-agent.bats:1446, tests/unit/test-dispatch-agent.bats:1553]
---
**G16 ID tokens in fixture function names + temp-dir patterns + sentinel string.** Convergent with cq-codex F01: `_g16_setup_fixtures`, `_g16_teardown_fixtures`, `.bats-tmp-g16.XXXXXX`, `bats-g16-oor.XXXXXX`, `G16CANONFAIL_SENTINEL_NOREAD_XQZ_SHOULD_NOT_EMIT`. Rename to descriptive: `_path_guard_setup_fixtures`, `bats-tmp-pguard.XXXXXX`, `CANONFAIL_SENTINEL_NOREAD_XQZ_SHOULD_NOT_EMIT`.
