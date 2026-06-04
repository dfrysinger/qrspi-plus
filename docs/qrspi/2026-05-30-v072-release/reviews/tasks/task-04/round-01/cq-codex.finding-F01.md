---
finding_id: R1-F01
severity: medium
change_type: correctness
referenced_files: ["tests/unit/test-change-type-partition.bats:87-88"]
artifact: code
round: 1
reviewer: code-quality-codex
---

**Hardcoded `/tmp/ct-stderr-$$.log` introduces flake/race/portability risk.**

Avoidable flake/race risk: shared global path, cleanup timing, parallel execution collisions, platform fragility. Capture stderr without global temp files (Bats `run`-based capture or `$BATS_TEST_TMPDIR`) so test remains hermetic.

Materialized from chat-only Codex output.
