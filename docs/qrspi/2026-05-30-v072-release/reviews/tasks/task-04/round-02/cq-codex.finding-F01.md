---
finding_id: R2-F01
severity: low
change_type: style
referenced_files: ["tests/unit/test-change-type-partition.bats:60-62"]
artifact: code
round: 2
reviewer: code-quality-codex
---

**ID hygiene violation: internal tracker token in code comments.**

The R1-fix orientation comment block introduced in the helper rename includes `T05` (QRSPI-internal tracker ID) in test code comments:

> "The production schema guard that enforces this contract is added in T05..."

Per the implementer-protocol ID-hygiene rule, internal IDs (G/R/D/T/Q/F-style tokens) must not appear in code comments outside `docs/qrspi/`. `tests/unit/` is not under `docs/qrspi/` — the comment leaks planning-tracker coupling into test source.

**Fix:** Reword to remove tracker token, e.g., "in a subsequent verifier task" or "in the verifier script implementation," without embedding the task ID.

Materialized from chat-only Codex output.
