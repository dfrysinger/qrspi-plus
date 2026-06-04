---
finding_id: F01
reviewer: code-quality-codex
severity: low
change_type: hygiene
referenced_files: [tests/unit/test-dispatch-agent.bats:1429-1430, tests/unit/test-dispatch-agent.bats:1446, tests/unit/test-dispatch-agent.bats:1553, tests/unit/test-dispatch-agent.bats:1646, tests/unit/test-dispatch-agent.bats:1663, tests/unit/test-dispatch-agent.bats:1681, tests/unit/test-dispatch-agent.bats:1696, tests/unit/test-dispatch-agent.bats:1723, tests/unit/test-dispatch-agent.bats:1777]
---
**G16 ID tokens leak in fixture/variable names + sentinels.** `_g16_setup_fixtures`, `.bats-tmp-g16*`, `G16CANONFAIL_SENTINEL_*` — test descriptions cleaned in fix-cycle 3, but identifiers/fixture-paths still carry G16. Rename to descriptive: `path_guard_setup_fixtures`, `bats-pathguard-*`, `CANONFAIL_SENTINEL_NOREAD`.
