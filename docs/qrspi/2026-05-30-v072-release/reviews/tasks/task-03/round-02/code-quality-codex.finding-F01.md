---
finding_id: R2-F01
reviewer_tag: code-quality-codex
round: 2
task: 3
severity: medium
change_type: style
referenced_files:
  - tests/unit/test-per-finding-file-emission.bats
---

# F01 — ID hygiene regression: QRSPI orchestrator tokens in new test comments

## Location

`tests/unit/test-per-finding-file-emission.bats:157–160`

```bash
# Pins the post-split self-description: after G6/Task-03 moved the disk-write
# contract prose out of SKILL.md into first-party-emission.md, the frontmatter
# description and intro paragraph must not still advertise it as a core
# protocol concern. (Round-2 fix for spec-claude/spec-codex F01.)
```

## Hygiene rule violation

Two leaks in one block:

1. **`G6` token** — QRSPI goal ID. Forbidden in test code outside `docs/qrspi/` per hygiene rules.
2. **`Task-03` token** — orchestrator task identifier. Same forbidden class.
3. **`(Round-2 fix for spec-claude/spec-codex F01.)`** — round-counter narration plus per-reviewer ID citations. This is exactly the "inside baseball" pattern the user has previously called out — comments documenting orchestrator state instead of explaining the test behavior.

## Why this matters

The bats file ships with the plugin and the contract layer. Goal IDs, task numbers, and reviewer-round IDs are orchestrator state — they are not load-bearing for understanding the test. The test pins behavior; comments should describe the behavior, not the review cycle that motivated the test.

## Suggested fix

Replace the comment block with behavior-only prose:

```bash
# The reviewer-protocol skill is split: SKILL.md owns transport-neutral
# protocol surfaces (finding schema, classifier, dispatch contract,
# untrusted-data handling) while first-party-emission.md and
# third-party-emission.md own the per-channel emission contracts. The
# frontmatter description and intro paragraph must not still advertise
# the moved-out disk-write contract as a core protocol concern.
```

## Severity rationale

Medium — same severity class as the cq-codex T06 R1 G11 finding (orchestrator ID leak into shipped surface). The bats file is a hygiene artifact: leaks here propagate forever in the test suite and are visible to every contributor.

## Recurring pattern note (v0.7.3 candidate)

This is the second wave-2 instance of orchestrator-ID leakage in implementer-generated test comments (T06 R1 cq-codex F01 caught the same class). The pattern suggests the implementer agent prompt or the hygiene rule callout in `implementer-protocol/SKILL.md` is not loud enough about comment-surface hygiene. Worth surfacing at the phase-1 batch gate as a v0.7.3 hardening candidate (e.g., add a lint rule that greps test files for `\bG[0-9]+\b`, `\bTask-[0-9]+\b`, `\bR[0-9]+(-F[0-9]+)?\b`, `\bspec-(claude|codex)\b` etc.).
