---
finding_id: R5-CQ-F01
reviewer: code-quality-codex
severity: low
change_type: regression
referenced_files:
  - tests/acceptance/v07-phase1/test-phase1-acceptance.bats
at_cap: false
escalate: false
---

# F01 — ID hygiene violation: R5 FIX-* tests reference internal finding IDs in comments

**Introduced by R5 (new FIX-A through FIX-E tests).**

## Location

`tests/acceptance/v07-phase1/test-phase1-acceptance.bats` lines 2639-2640, 2655, 2669, 2705, 2753

## Defect

The 5 new R5 tests reference QRSPI-internal finding IDs (`sec-codex F01`, `sec-codex F02`, `cq-codex F01`, `sf-codex F01`, `sf-claude F01`) in their `@test` descriptors and surrounding comments. This is the same ID-hygiene class that R4's cq-codex F02 caught for `T11` prefixes — internal run-specific tokens leaked into test surfaces outside `docs/qrspi/`.

The criterion is: comment/test surfaces outside `docs/qrspi/` should use descriptive text about WHAT the test verifies (e.g., "mktemp + mv -f for first-party prompt write — TOCTOU closed"), not WHO flagged it ("R4 sec-codex F01").

## Recommended fix

Rename the 5 FIX-* test descriptors and comments to drop the reviewer-attribution and finding IDs, keeping descriptive text only:

- `@test "FIX-A — first-party prompt write uses mktemp+mv-f (sec-codex F01)"` → `@test "first-party prompt write uses mktemp+mv-f (no TOCTOU)"`
- `@test "FIX-B — manifest tmp uses mktemp (sec-codex F02)"` → `@test "manifest tmp uses mktemp (no predictable-path)"`
- `@test "FIX-C — DISPATCHER check only in third-party branch (cq-codex F01)"` → `@test "DISPATCHER check fires only in third-party branch"`
- `@test "FIX-D — failure-path emit wrapped to preserve exit code (sf-codex F01)"` → `@test "failure-path emit preserves dispatcher exit code"`
- `@test "FIX-E — split traps so signals don't resume function (sf-claude F01)"` → `@test "split EXIT/INT/TERM traps so signals don't resume function"`

(Persisted by orchestrator — gpt-5.3-codex returned chat-only per stored memory.)
