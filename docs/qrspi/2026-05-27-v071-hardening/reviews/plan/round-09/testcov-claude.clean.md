---
status: clean
reviewer: testcov-claude
round: 9
artifact: plan.md
---

# Test Coverage Review — Round 9 — Clean

## Summary

No new findings. The R8→R9 diff addresses R8-F01 (test-coverage) cleanly via
Option A from the round-8 recommendation:

1. The unverifiable Task 9 test-expectation bullet asserting that each modified
   `agents/qrspi-*.md` file contains tier-name tokens (`haiku`, `sonnet`,
   `opus`) outside the YAML frontmatter has been deleted. That bullet was
   flagged in R8-F01 as unfalsifiable (dispatcher prose in any given agent file
   is not guaranteed to mention all three tier names — the tokens are not a
   structural invariant of the file class).

2. The Manual Validation block has been expanded to explicitly attribute
   collateral-modification verification to the operator-run
   `git diff --stat HEAD~1 -- 'agents/qrspi-*.md'` check. The added parenthetical
   ("verifies that only the `model:` frontmatter line was removed and no body
   prose was collaterally modified") makes the verification target explicit and
   observable: 41 files changed, exactly 1 line removed per file, 0 lines added
   per file. This invariant deterministically catches body-prose modification
   (any collateral edit would show as a non-1 removed count or a non-0 added
   count).

## Remaining Task 9 test expectations — all pass review criteria

- **Bullet 1** (RED-phase structural lint sweep over `agents/qrspi-*.md` for
  top-level `model:` key): specific, observable, deterministic, falsifiable.
- **Bullet 2** (GREEN-phase: lint passes with zero violations after all 41
  files modified): observable, falsifiable.
- **Bullet 3** ("All other frontmatter keys ... are unmodified"): not directly
  verified by the BATS lint test, but covered by the Manual Validation
  `git diff --stat` invariant (1 line removed, 0 added per file — any other
  frontmatter key modification would surface as either an added line or a
  second removed line in the stat output).
- **Bullet 4** (RED-phase test produces useful per-file failure message):
  observable, falsifiable.

## Set-asides honored

S1–S5 unchanged and not raised per dispatch instructions.

## Confirmation

The remaining test expectations for Task 9 form a deterministic acceptance
contract that the Test skill can translate into BATS assertions without
ambiguity, and the operator-verified Manual Validation step closes the
collateral-modification gap that motivated R8-F01.
