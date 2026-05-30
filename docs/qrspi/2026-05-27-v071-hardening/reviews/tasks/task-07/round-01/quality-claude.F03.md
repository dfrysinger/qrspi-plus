---
finding_id: quality-claude-F03
severity: minor
change_type: style
referenced_files:
  - tests/unit/test-host-detection.bats:607
  - tests/unit/test-host-detection.bats:683
artifact: task-07
round: 1
reviewer: quality-claude
---

# F03 — QRSPI task-ID `T7` leaked into test-surface comments in `test-host-detection.bats`

Both rewritten tests added orientation paragraphs prefixed:

> `# T7 update: the original scenario (no companion + codex_reviews=true) now triggers the T7 codex-unavailable short-circuit ...`

(lines 607–611 in test "mismatch is warning-only"; lines 683–686 in test "mismatch path does not suppress non-zero transport exit")

The `T7` token is QRSPI-internal and per the ID-hygiene rule is forbidden in test-surface comments outside `docs/qrspi/`. The paragraphs are otherwise valuable — they explain *why* the scenario was swapped (the old scenario stopped exercising the warning-only path once the short-circuit landed) — but the `T7` framing tethers the comment to a specific run rather than the durable behavioral contract.

**Recommendation:** Rephrase the orientation to describe the behavioral change without the task-ID prefix. Suggested edit: `# Scenario update: the original scenario (no companion + codex_reviews=true) now triggers the codex-unavailable short-circuit (avail=false AND config=true → exit non-zero before dispatch). Switch to the avail=true + config=false mismatch scenario so we still exercise warning-only-with-dispatch-continuing.` Same edit pattern for both rewritten tests.
