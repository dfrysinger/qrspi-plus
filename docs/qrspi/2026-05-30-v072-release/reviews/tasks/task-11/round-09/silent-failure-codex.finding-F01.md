---
reviewer_tag: silent-failure-codex
round: 9
finding_id: R9-F01
severity: medium
change_type: correctness
referenced_files: [tests/acceptance/v07-phase1/test-phase1-acceptance.bats]
---

# F01 — Key-count pins (`keys | length == 5`) can pass with wrong key names

## Finding

R9 added strict-shape assertions at bats lines 2519-2523 (AC2) and 2789-2792 (AC5) that only check `keys | length == 5` for first-party entries and `dispatch_spec`. A regression that drops `tag` or `agent` and silently substitutes a different 5th key would still pass — masking incorrect manifest output.

This is a test silent-failure: the test gives confidence the schema is pinned, but only the count is checked. The key NAMES are the actual schema contract.

## Suggested fix

Assert exact key sets, e.g.:

```bash
jq -e '.[0] | (keys | sort) == ["agent","dispatch_spec","mode","status","tag"]'
jq -e '.[0].dispatch_spec | (keys | sort) == ["host","model","prompt_file","subagent_type","vendor"]'
```

Apply to both AC2 and AC5 enhancements (4 jq assertions total: top-level + dispatch_spec × AC2 + AC5).

## Severity rationale

MEDIUM — the assertion is a regression guard for the dispatch-manifest schema contract (CD-1). A guard that passes incorrectly defeats its own purpose, and the silent-failure pattern is exactly what T11's G3+CD-1 are intended to prevent. This is also a strictly stronger version of the same pattern sf-codex flagged conceptually — counts are not contracts.

## R10 bundling

Bundle with cq-codex F01 (T11 ID hygiene) + cq-codex F02 (test hermeticity /tmp/foo bar → $TMP_DIR) + the queued cs-codex F01 #1/#2 refactors. All four are tests-or-refactor scope on the same two files.
