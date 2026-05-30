---
reviewer: testcov-claude
round: 8
artifact: plan.md
severity: high
category: test-expectation-quality
task_ref: Task 9
status: open
---

# F01 — Task 9 per-file tier-token presence assertion overspecified; likely unreachable GREEN and omits `inherit`

## Where

`plan.md` line 269, Task 9 Test expectations bullet 3 (introduced this round to close R7-F01):

> Each modified `agents/qrspi-*.md` file in its post-modification state contains at least one occurrence of each of the tier-name tokens `haiku`, `sonnet`, and `opus` outside the YAML frontmatter block (verifying dispatcher prose and `<!-- model: -->`-style inline annotations were not collaterally removed)

## What the expectation claims

The assertion is per-file and conjunctive: every one of the 41 modified files, individually, must contain at least one `haiku` token AND one `sonnet` token AND one `opus` token outside YAML frontmatter, post-modification.

## Why it is likely unverifiable as a GREEN gate

Goals.md line 163 establishes the only documented per-file tier-name distribution:

> All 41 files in `agents/*.md` declare Claude short model names in YAML frontmatter (33 `sonnet`, 5 `inherit`, 1 `opus`, 2 `haiku` = 41 sites across 41 files)

Each file declares exactly one tier in its frontmatter. Neither goals.md, nor the Task 9 description (lines 263–265), nor the prior R7 review trail establishes an invariant that every agent file's body prose mentions all three (or all four) tier names. The intuitive content shape is the opposite: an agent like `qrspi-finding-verifier.md` (declared `haiku` per goals.md line 202) is most likely to mention `haiku` in its own self-description and unlikely to mention `opus` in body prose. The R8 test expectation therefore requires a property of the file set that has not been established and is unlikely to hold.

If the assertion is implemented faithfully, the structural lint will fail GREEN on every file whose body prose does not happen to mention all three tier names — even when the implementation is correct (i.e., only the YAML `model:` line was removed). The Task 9 success path depends on this expectation being satisfiable; as written, it likely is not.

## Secondary problem: `inherit` token is omitted

The Task 9 description on line 265 explicitly enumerates four tier-name tokens whose prose references must be preserved:

> Tier-name references in dispatcher prose blocks (haiku, sonnet, opus, inherit) within each file are not modified

But the test expectation on line 269 covers only three of the four (`haiku`, `sonnet`, `opus`), silently dropping `inherit`. Per goals.md line 163, 5 of the 41 files carry `inherit` in frontmatter, so `inherit` body-prose mentions are a real surface that could be collaterally damaged and the structural lint would not detect it. The asymmetry between description (four tokens) and test expectation (three tokens) is either a typo or a hidden assumption that should be made explicit.

## Suggested remediation (reviewer does not prescribe wording)

Two example shapes the author may choose between (both deterministic and falsifiable):

1. **Aggregate (whole-set) assertion** — Replace the per-file conjunction with an across-the-set claim that matches the goals.md frontmatter counts after migration to prose, e.g. "Across the 41 modified files combined, each of the tier-name tokens `haiku`, `sonnet`, `opus`, and `inherit` appears at least once outside YAML frontmatter blocks." This is verifiable from final state alone, requires no per-file prose invariant, and covers all four tokens.

2. **Per-file existential (any-tier) assertion** — "Each modified file, post-modification, contains at least one tier-name token from the set {`haiku`, `sonnet`, `opus`, `inherit`} outside the YAML frontmatter block." This detects whole-file body-prose deletion without asserting which specific tiers each file mentions.

Either shape preserves the R7-F01 fix (no baseline-relative comparison; final-state-only) while staying within what the documented file properties actually support. The author should pick the shape that matches the collateral-damage surface they actually want to gate on.

## Impact

High: the test expectation as written gates Task 9 GREEN on a property that goals.md does not establish and that is unlikely to hold for all 41 files. The structural lint test built from this expectation will likely fail on correctly-modified files, blocking the GREEN gate the task depends on. The `inherit` omission is a smaller scope-completeness gap inside the same assertion.

## Scope check

In-scope for this round: the line 269 bullet and the surrounding Test expectations / Manual Validation block were the only Task 9 changes in the R7→R8 diff. The Manual Validation block (line 274) cleanly addresses R7-F01's per-file-diff concern and is not part of this finding. Confirmed set-asides S1–S5 untouched.
