---
reviewer: gt-claude
round: 9
task: task-03
finding_id: F03
change_type: style
severity: low
file: tests/unit/test-helpers-skill-markdown.bats
---

# F03 — Test naming inconsistency: `[r7-sf.F01]` prefix vs sibling finding tests

## Finding

The test `[r7-sf.F01] mktemp failure surfaces mktemp-named diagnostic` carries a round prefix (`r7-`) that its sibling finding-tests do not:

| Test tag | Round prefix? |
|---|---|
| `[sf-F01] extract_section_fence_aware: awk crash…` | none |
| `[sec-F01] extract_section_fence_aware: mktemp-generated signal-tmp…` | none |
| `[r7-sf.F01] mktemp failure surfaces mktemp-named diagnostic` | **`r7-` prefix** |
| `[sf-F03] extract_section_fence_aware: section containing only an empty fenced block…` | none |

The `r7-` prefix appears to encode the review round in which the finding was raised (round 7), which is implementation-process metadata — not a property of the test's behavioral contract.

## Impact

No correctness impact. The inconsistency can cause confusion when searching for tests by tag or when the test's origin round becomes irrelevant over time.

## Suggested fix

Rename to `[sf-F02]` (matching the `sf.FNN` naming sequence used by the awk-crash and fence-delimiter tests, and keeping the sequence unambiguous), or otherwise remove the round prefix:

```
@test "[sf-F02] extract_section_fence_aware: mktemp failure surfaces mktemp-named diagnostic" {
```
