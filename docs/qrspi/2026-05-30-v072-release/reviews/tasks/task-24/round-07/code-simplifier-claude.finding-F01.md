---
finding: F01
reviewer: code-simplifier-claude
round: 7
file: tests/unit/test-detect-interaction-mode.bats
category: Inconsistency
severity: advisory
blocking: false
---

# F01 — 8 tests missing the `[T24]` task-tag prefix

## Location

Lines 311, 328, 562, 580, 597, 619, 638, 657 of
`tests/unit/test-detect-interaction-mode.bats`.

## Pattern observed

The entire first half of the suite uses a consistent `[T24]` tag:

```bats
@test "[T24] COPILOT_CLI=1 branch emits PLATFORM=copilot-cli" { …
@test "[T24] QRSPI_INTERACTION_MODE=auto override wins even on COPILOT_CLI=1 host" { …
```

But 8 tests — all in the latter portion of the file, added across later
rounds — omit it:

```bats
@test "QRSPI_INTERACTION_MODE=interactive override wins even on COPILOT_CLI=1 host" {
@test "QRSPI_INTERACTION_MODE=interactive override (Claude Code host): emits PLATFORM=claude-code" {
@test "Grep regression: '## Auto Mode Active' Claude Code signal absent from agents/ dir" {
@test "Output-shape: every stdout line from Claude Code branch is KEY=VALUE" {
@test "Native-detection precedence: COPILOT_CLI=1 wins over CLAUDE_PROJECT_DIR when no override" {
@test "Unknown host safe-default EVIDENCE contains semantic safe-default content" {
@test "Claude Code branch creates no files at all" {
@test "Override branch creates no files at all" {
```

## Why it matters

The `[T24]` prefix is the sole mechanism for filtering or counting this
task's tests by name (e.g. `bats --filter '[T24]'` or a CI report
query).  The 8 untagged tests are invisible to that filter, making the
suite appear to have fewer test than it does and silently excluding
these cases from any tag-based triage.

## Proposed fix

Prefix each of the 8 names with `[T24] ` to match the established
convention:

```bats
@test "[T24] QRSPI_INTERACTION_MODE=interactive override wins even on COPILOT_CLI=1 host" {
@test "[T24] QRSPI_INTERACTION_MODE=interactive override (Claude Code host): emits PLATFORM=claude-code" {
@test "[T24] Grep regression: '## Auto Mode Active' absent from agents/ dir" {
@test "[T24] Output-shape: every stdout line from Claude Code branch is KEY=VALUE" {
@test "[T24] Native-detection precedence: COPILOT_CLI=1 wins over CLAUDE_PROJECT_DIR when no override" {
@test "[T24] Unknown host safe-default EVIDENCE contains semantic safe-default content" {
@test "[T24] Claude Code branch creates no files at all" {
@test "[T24] Override branch creates no files at all" {
```

No test logic, assertion, or behavior changes — name strings only.
