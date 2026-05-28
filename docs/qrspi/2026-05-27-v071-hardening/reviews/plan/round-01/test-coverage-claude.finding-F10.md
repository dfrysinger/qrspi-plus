# Finding F10: Task 9 — "Tier-name strings remain intact" is not a specific, testable expectation

**Artifact:** plan.md
**Task:** Task 9 (G7b part 1 — agent model: field deletion with structural lint coverage)
**Category:** Test Expectation Quality
**Severity:** advisory

## Problem

The expectation is:

> "Tier-name strings (haiku, sonnet, opus, inherit) appearing in the body prose or inline dispatch annotations of each agent file remain intact after the frontmatter deletion"

This expectation is not falsifiable as written because:

1. **No baseline count is given.** Not every agent file contains all four tier names; some may have none. Without a pre-deletion count of occurrences per file (or total), a test cannot assert "remain intact."
2. **Location is vague.** "Body prose or inline dispatch annotations" covers the entire file body — a test would need to differentiate between the now-deleted frontmatter block and the body, which requires YAML front-matter parsing beyond a simple grep.
3. **"Intact" is undefined.** Does this mean the same count? The same positions? The same surrounding context?

A test writer cannot produce a deterministic, falsifiable test from "strings remain intact" without a specified mechanism.

## Recommendation

Replace with a specific, falsifiable expectation:

- "The total number of occurrences of the strings `haiku`, `sonnet`, `opus`, and `inherit` across all 41 agent files in the body (non-frontmatter) content is unchanged before and after the frontmatter `model:` deletion — verified by a grep count that excludes the `---`-delimited frontmatter block."

Or, if per-file counts are stable, alternatively:

- "No agent file body loses any occurrence of `haiku`, `sonnet`, `opus`, or `inherit` that was present before the frontmatter deletion (the structural lint test compares grep counts on the body section only)."
