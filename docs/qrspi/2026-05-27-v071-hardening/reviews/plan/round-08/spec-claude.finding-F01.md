---
status: finding
severity: substantive
category: test-coverage
artifact: plan.md
round: 8
reviewer: spec-claude
target: Task 9 — Test Expectations (R8 replacement)
---

# F01 — Task 9 final-state token-presence assertion is unsatisfiable against current repo state

## What changed in R8

R7 → R8 replaces the per-file diff-preservation test expectation in Task 9 with a final-state assertion (plan.md line 269):

> Each modified `agents/qrspi-*.md` file in its post-modification state contains at least one occurrence of each of the tier-name tokens `haiku`, `sonnet`, and `opus` outside the YAML frontmatter block (verifying dispatcher prose and `<!-- model: -->`-style inline annotations were not collaterally removed)

## Why this is a defect

The parenthetical clarifies the *intent* — "verifying dispatcher prose and `<!-- model: -->`-style inline annotations were not collaterally removed" — but the operative clause requires **every** modified file to contain **all three** tier-name tokens in body prose. That is almost certainly impossible against the existing repo state.

Evidence from goals.md (G7b, lines 162–163):

> All 41 files in `agents/*.md` declare Claude short model names in YAML frontmatter (33 `sonnet`, 5 `inherit`, 1 `opus`, 2 `haiku` = 41 sites across 41 files; verified via `grep -h '^model:' agents/*.md | sort | uniq -c` against `HEAD`).

Each agent file carries exactly one tier assignment. There is no plan-side claim (and no goals-side claim) that every agent body also contains prose referencing all of `haiku`, `sonnet`, and `opus`. Typical agent dispatcher prose mentions only the tier the agent itself runs at (e.g., a sonnet-tier reviewer's body does not need to discuss haiku or opus). Many of the 41 files almost certainly contain zero tier-name tokens outside their YAML frontmatter — particularly since the task description (plan.md line 265) only says *references that exist* are not modified:

> Tier-name references in dispatcher prose blocks (haiku, sonnet, opus, inherit) within each file are not modified

This is a per-file-conditional preservation claim, not a per-file presence claim.

## Consequence

The test expectation as worded is unsatisfiable at GREEN: most or all of the 41 files will fail the "contains all three tokens" check trivially, regardless of whether collateral removal occurred. This forces one of two bad outcomes:

1. The implementer cannot close the task without inserting tier-name tokens into every agent body — a scope expansion not in G7b.
2. The expectation is silently weakened during implementation, defeating its stated purpose.

Either way, the assertion fails to detect what it claims to detect (collateral prose removal).

## Recommended fix

Re-cast the assertion as a per-file conditional preservation check, e.g.:

> For each `agents/qrspi-*.md` file, the set of tier-name tokens (`haiku`, `sonnet`, `opus`, `inherit`) appearing outside the YAML frontmatter block in the post-modification file equals the set appearing outside the YAML frontmatter block in the pre-modification file.

A BATS-friendly approximation that avoids needing the pre-modification tree at test time:

> A new test in `tests/unit/test-agent-frontmatter-no-model.bats` greps each `agents/qrspi-*.md` body (excluding the leading YAML frontmatter block) for `haiku|sonnet|opus|inherit` and emits the per-file token-set to a fixture file. The test fails if the per-file token-set differs from a checked-in expected-set fixture authored in the RED phase from the pre-modification tree.

Or, if a simpler aggregate check is acceptable:

> Across all 41 modified `agents/qrspi-*.md` files combined, the count of tier-name token occurrences (`haiku`, `sonnet`, `opus`, `inherit`) outside YAML frontmatter blocks is ≥ the count present in the pre-modification tree (captured into a checked-in fixture during RED phase).

Either reframing preserves the collateral-removal-detection intent without falsely requiring every file to mention every tier.

## Scope note

The added Manual Validation block (plan.md lines 273–274) is fine — `git diff --stat HEAD~1 -- 'agents/qrspi-*.md'` showing 41 files × (1 line removed, 0 added) is a reasonable operator check and mirrors the established Task 8 pattern. The defect is confined to the test-expectation rewording.
