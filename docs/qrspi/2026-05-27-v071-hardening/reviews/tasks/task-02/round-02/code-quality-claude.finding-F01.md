---
reviewer: code-quality-claude
task: 2
round: 2
finding: F01
severity: low
area: id-hygiene
status: open
---

# F01 — QRSPI-internal IDs in git fixture `user.name` runtime string

## Location

`tests/unit/test-commit-hygiene-invariants.bats` — new test added in round-02 diff,
inside `@test "[commit-hygiene] git add -A does not stage scratch file…"`.

```bats
git -C "$fresh_dir" config user.name "T02-G2 Fixture"
```

## Description

The git fixture's `user.name` value `"T02-G2 Fixture"` embeds two QRSPI-internal
ID tokens:

| Token | Matches spec field |
|-------|--------------------|
| `T02` | `task: 2` (frontmatter) |
| `G2`  | `goal_ids: [G2]` (frontmatter) |

The grep-lint pattern `\b[GRDFTQ]-?[0-9]+[A-Za-z]?\b` hits both tokens.
A `git config user.name` value is a runtime string literal (strict surface) — the
value is written into every git commit the fixture creates, making it observable
in `git log` output even if only in a temporary directory.

The round-01 F01 fix renamed the test tags and section header correctly; this
`user.name` string was not part of that fix scope and carries the same tokens
forward.

## Why it matters

The rule for strict surfaces (code identifiers, runtime string literals) forbids
QRSPI-internal IDs regardless of whether the surrounding context disambiguates
them. `"T02-G2 Fixture"` couples the fixture label to a specific pipeline run
rather than to the behaviour under test.

## Suggested fix

Replace the task/goal tokens with a behaviour-descriptive label:

```diff
-  git -C "$fresh_dir" config user.email "t02g2@example.com"
-  git -C "$fresh_dir" config user.name "T02-G2 Fixture"
+  git -C "$fresh_dir" config user.email "commit-hygiene@example.com"
+  git -C "$fresh_dir" config user.name "Commit-Hygiene Fixture"
```

The email is updated in the same pass for consistency, though it uses all-lowercase
and does not formally match the ID pattern.
