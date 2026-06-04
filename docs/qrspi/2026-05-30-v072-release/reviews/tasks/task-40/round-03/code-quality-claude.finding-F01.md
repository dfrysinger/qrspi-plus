---
finding_id: F01
reviewer: code-quality-claude
reviewer_role: code-quality
round: 3
task: 40
severity: low
change_type: cleanliness
file: tests/unit/test-ci-workflow-shape.bats
lines: "382-393"
status: open
---

# F01 — Comment enumerating scanned hook surfaces is stale after regex extension

The R3 fix correctly extends the C1-enforcement path filter on line 393 to include `.pre-commit-config` and `.pre-commit-hooks`, but the orienting comment on line 383 still reads:

> Assert no tracked file under scripts/, .husky/, .githooks/, or lefthook.*
> references body-guard or bats-body-assertion.

The comment now under-describes what the test enforces — a future reader auditing C1 coverage by skimming the comment will not see pre-commit-framework configs in the list, even though they are now scanned. This is the kind of comment-code drift that re-opens the F01 vacuity surface in human review (e.g., someone "rationalizing" the regex back down to match the comment).

**Recommendation:** Append `.pre-commit-config*, or .pre-commit-hooks*` to the surface list in the comment so it tracks the regex.
