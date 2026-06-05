---
finding: F03
reviewer: code-quality-claude
round: 2
severity: minor
area: id-hygiene
---

# F03 — QRSPI-internal tokens T34 and G5 embedded in test names and section comments

## Location

`tests/unit/test-plan-post-approval-split.bats`, every new test added in this
commit and all new section separator comments.

- **Test names:** all 30 new `@test` blocks begin with `[T34-G5]` — e.g.:
  ```
  @test "[T34-G5] Contract declares Block-Hash Header Format section" {
  ```
- **Section separator comments** (18 occurrences):
  ```
  # G5 — Block-hash header format (contract doc sections)
  # G5 — Idempotent split contract (3-case decision rule)
  # G5 — HALT diagnostic exact text
  … (and 15 more)
  ```

## Grep-lint hits

Pattern `\b[GRDFTQ]-?[0-9]+[A-Za-z]?\b` applied to the changed bats file
surfaces `T34` and `G5` in test names and `G5` in every section comment header
in the new block. Both tokens are copied directly from the task spec frontmatter
(`task: 34`, `goal_ids: [G5]`).

## Problem

The ID hygiene contract forbids QRSPI-internal G/T-prefixed numeric tokens in
test names, `describe`/`it` blocks, and code comments outside `docs/qrspi/`.
`T34` (task ID) and `G5` (goal ID) are both QRSPI-internal tokens; they appear
in all 30 new test names and in 18 section comment lines.

The pre-existing tests in this file use `[T32-split]` in test names (a pre-existing
violation of the same rule), so this follows an established (but incorrect) local
convention. That pre-existing pattern does not excuse the new additions; the new
tests double down by also embedding a goal ID (`G5`) which the older tests did not.

## Note on the contract doc

`skills/plan/post-approval-split-contract.md` introduces `## Pre-G5 Migration
Diagnostic` as a required section name (specified verbatim in `structure.md` and
`task-34.md`). That section heading is in the skill document itself (not a test
name or comment) and the task spec required the exact text, so it is not flagged
here — the intent is clearly a version-era label, not a run-specific tracker
token in a test identifier.

## Fix

Drop the task and goal tokens from test names and section comments. For test names
use a short domain label following the existing `split` pattern, e.g.
`[split-G5-hash]` or simply descriptive names without any ID prefix. For section
comments, the prose description alone is sufficient (e.g.
`# Block-hash header format` instead of `# G5 — Block-hash header format`).
