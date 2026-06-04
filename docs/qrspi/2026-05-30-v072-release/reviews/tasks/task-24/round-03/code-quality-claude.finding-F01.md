---
id: F01
reviewer: code-quality-claude
round: 3
severity: low
area: id-hygiene
file: tests/unit/test-detect-interaction-mode.bats
line: 58
---

# QRSPI-internal `[T24]` ID tokens in `@test` names and file-level comment block

## Location

`tests/unit/test-detect-interaction-mode.bats`:

- **Lines 7–33** — file-level coverage-index comment block, every bullet prefixed with `[T24]` (23 occurrences).
- **Lines 58, 68, 78, 97, 107, 117, 132, 141, 150, 159, 173, 183, 193, 203, 214, 224, 235, 246, 256, 268, 280, 293, 310, 319, 331, 339, 353, 371, 390, 397, 404, 411, 419, 430, 439, 444, 449, 458, 471, 482, 505** — every `@test "..."` name starts with `[T24]`.

Representative examples:

```bash
# line 9 (file comment)
#   [T24] Copilot CLI branch (COPILOT_CLI=1): PLATFORM=copilot-cli

# line 58 (@test name)
@test "[T24] COPILOT_CLI=1 branch emits PLATFORM=copilot-cli" {
```

## Problem

`T24` is a T-prefixed numeric token — a QRSPI-internal task ID — and the ID hygiene
rules prohibit such tokens in test names (`@test "..."` blocks) and in code comments
outside `docs/qrspi/`. These tokens were copied from the `tasks/task-24.md`
test-expectation bullet list into both the coverage index comment and every test name.

The rule's stated target is exactly this failure mode: implementer copies run-specific
tracking tokens from the task spec into the diff.

## Impact

- Test-runner output (e.g., `bats --tap`) includes the full test name, so `[T24]`
  appears in CI tap logs, making test failures harder to parse without knowing the
  QRSPI tracking system.
- Code comments containing tracker IDs couple the file to the task-tracking system
  rather than standing alone as documentation.

## Fix

Strip the `[T24]` prefix from every `@test` name and from each bullet in the
coverage-index comment block. The remaining names and bullets are already descriptive
on their own:

```bash
# Before
@test "[T24] COPILOT_CLI=1 branch emits PLATFORM=copilot-cli" {

# After
@test "COPILOT_CLI=1 branch emits PLATFORM=copilot-cli" {
```

```bash
# Before (line 9)
#   [T24] Copilot CLI branch (COPILOT_CLI=1): PLATFORM=copilot-cli

# After
#   Copilot CLI branch (COPILOT_CLI=1): PLATFORM=copilot-cli
```

This is a mechanical find-and-replace of `[T24] ` → `` across the file's comments
and test-name strings. No test logic changes.
