---
finding: F01
reviewer: code-simplifier-claude
round: 6
severity: advisory
blocking: false
category: inconsistency
file: tests/unit/test-detect-interaction-mode.bats
lines: [528, 546, 563, 585, 604]
---

# F01 — Five tests missing the `[T24]` tag prefix

## Summary

All tests in the `[T24]`-tagged block (lines 58–522) consistently name themselves
`[T24] <description>`, establishing a searchable task-tag convention.  Five tests
appended later — covering the `## Auto Mode Active` grep regression, the Claude Code
output-shape, the precedence scenario, the semantic EVIDENCE assertion, and the
Claude Code no-file-write check — omit that prefix:

| Line | Test name (current) |
|------|---------------------|
| 528 | `"Grep regression: '## Auto Mode Active' Claude Code signal absent from agents/ dir"` |
| 546 | `"Output-shape: every stdout line from Claude Code branch is KEY=VALUE"` |
| 563 | `"Native-detection precedence: COPILOT_CLI=1 wins over CLAUDE_PROJECT_DIR when no override"` |
| 585 | `"Unknown host safe-default EVIDENCE contains semantic safe-default content"` |
| 604 | `"Claude Code branch creates no files at all"` |

## Impact

- `bats --filter-tags T24` (or equivalent grep on test names) silently misses these
  five tests, creating an invisible gap in any per-task test filtering.
- The test index comment at lines 7–31 lists all five covered behaviours under
  the `[T24]` heading, so the header and the test names are also inconsistent with
  each other.

## Proposed change

Add the `[T24] ` prefix to each of the five test names.  Examples:

```diff
-@test "Grep regression: '## Auto Mode Active' Claude Code signal absent from agents/ dir" {
+@test "[T24] Grep regression: '## Auto Mode Active' Claude Code signal absent from agents/ dir" {
```

```diff
-@test "Output-shape: every stdout line from Claude Code branch is KEY=VALUE" {
+@test "[T24] Output-shape: every stdout line from Claude Code branch is KEY=VALUE" {
```

```diff
-@test "Native-detection precedence: COPILOT_CLI=1 wins over CLAUDE_PROJECT_DIR when no override" {
+@test "[T24] Native-detection precedence: COPILOT_CLI=1 wins over CLAUDE_PROJECT_DIR when no override" {
```

```diff
-@test "Unknown host safe-default EVIDENCE contains semantic safe-default content" {
+@test "[T24] Unknown host safe-default EVIDENCE contains semantic safe-default content" {
```

```diff
-@test "Claude Code branch creates no files at all" {
+@test "[T24] Claude Code branch creates no files at all" {
```

No test logic changes.  Pure rename — semantics-preserving.
