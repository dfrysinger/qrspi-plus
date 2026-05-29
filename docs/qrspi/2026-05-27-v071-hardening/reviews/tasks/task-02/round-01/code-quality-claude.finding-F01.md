---
reviewer: code-quality-claude
task: 2
round: 1
finding: F01
severity: low
area: id-hygiene
status: open
---

# F01 — QRSPI-internal IDs in test names and code comments

## Location

`tests/unit/test-commit-hygiene-invariants.bats` — new lines added in round-01 diff.

## Description

Three occurrences of QRSPI-internal IDs (T- and G-prefixed numeric tokens) appear
in the newly added code, violating the ID-hygiene rule that forbids such tokens in
test names and code comments outside `docs/qrspi/`:

| Line (full file) | Surface        | Token(s)         |
|-----------------|----------------|------------------|
| Section header comment | code comment | `G2` — `# G2 committed-gitignore invariant: …` |
| `@test "[T02-G2-hygiene] committed root …"` | test name | `T02`, `G2` |
| `@test "[T02-G2-hygiene] git add -A does not …"` | test name | `T02`, `G2` |

`T02` is the task ID (`task: 2`) and `G2` is the goal ID (`goal_ids: [G2]`) from
the task spec frontmatter — exactly the run-specific tokens the grep-lint procedure
is designed to catch.

## Why it matters

Test names are stable identifiers that appear in CI output, test reports, and search
history long after a pipeline run. Embedding task/goal IDs couples the test name to a
specific QRSPI run rather than to the behaviour under test. When the rule fires on a
genuinely distinct concept (e.g., a domain enum value named `G2`) the textual
neighbourhood provides disambiguation; here it does not — the neighbourhood is a bats
`@test` block and a section header comment, both clearly labelling QRSPI provenance.

Note: the pre-existing suite uses the same pattern (`[T39-hygiene]`, `# T39 — G12:`)
but those lines are not in this diff. The new additions compound an existing
convention rather than originating it.

## Suggested fix

Replace the task/goal tokens in test names with behaviour-descriptive labels:

```diff
-@test "[T02-G2-hygiene] committed root .gitignore contains .qrspi-commit-msg.txt verbatim" {
+@test "[commit-hygiene] committed root .gitignore contains .qrspi-commit-msg.txt verbatim" {

-@test "[T02-G2-hygiene] git add -A does not stage scratch file on fresh-clone simulation (gitignore-only, no per-clone exclude)" {
+@test "[commit-hygiene] git add -A does not stage scratch file on fresh-clone simulation (gitignore-only, no per-clone exclude)" {
```

Replace the section header comment:

```diff
-# G2 committed-gitignore invariant: .qrspi-commit-msg.txt in committed
-# root .gitignore closes the fresh-clone / fresh-worktree staging gap.
+# committed-gitignore invariant: .qrspi-commit-msg.txt in committed
+# root .gitignore closes the fresh-clone / fresh-worktree staging gap.
```
