---
finding_id: R8-F01
severity: blocking
change_type: criterion-correctness
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/plan.md:L269]
artifact: plan
round: 8
reviewer: quality-claude
---

# Task 9 replacement Test Expectation is factually false against repository reality

## Problem

The R7→R8 edit at plan.md:269 replaced the prior baseline-relative wording with:

> "Each modified `agents/qrspi-*.md` file in its post-modification state contains at least one occurrence of each of the tier-name tokens `haiku`, `sonnet`, and `opus` outside the YAML frontmatter block (verifying dispatcher prose and `<!-- model: -->`-style inline annotations were not collaterally removed)"

This is testable (good — addresses R7-F01) but **false against the current agent files**. The acceptance criterion asserts that each of the 41 modified files contains all three tier-name tokens in its body. Multiple agent files do not.

**Direct evidence** — `agents/qrspi-implementer.md` (full file, 85 lines, read end-to-end this round):

- Frontmatter has only `model: inherit` (no tier-name token in frontmatter either).
- Body (lines 8–85): zero occurrences of `haiku`, `sonnet`, or `opus`. The body discusses TDD process, split-mode dispatch, the Iron Law, self-review, red flags, and rationalizations — none of which name a Claude tier.

After Task 9 deletes the `model: inherit` line, the post-modification file body is unchanged — and still contains zero tier-name tokens outside frontmatter. The Task 9 structural lint test (`test-agent-frontmatter-no-model.bats`) implementing this Test Expectation as written would FAIL on `qrspi-implementer.md`.

Other agents read this round that are likely in the same bucket (frontmatter-only tier reference, no body tier mentions in the first ~30 lines): `qrspi-test-writer.md` (`model: inherit`), `qrspi-implementer-lightweight.md` (`model: inherit`), `qrspi-research-specialist.md` (`model: inherit`), `qrspi-finding-verifier.md` (`model: haiku`), `qrspi-scope-tagger.md` (`model: haiku`). For files whose only tier-name reference lives in the frontmatter being deleted, the new acceptance criterion is unsatisfiable.

The criterion also contradicts the Task 9 Description's own constraint at plan.md:265: *"Tier-name references in dispatcher prose blocks (haiku, sonnet, opus, inherit) within each file are not modified; only the standalone `model:` key in the YAML front matter block is removed."* The implementer is forbidden from adding tier-name tokens to body prose, so they cannot make the assertion GREEN where the body did not already contain all three.

The intent of the replacement was clearly *"verify no collateral removal of body tier-name prose"*. The intent is sound; the universal-quantifier framing is wrong. The check is meaningful only for agents whose body actually carries tier-name references — and even then, demanding all three tokens per file is stronger than the property being verified.

## Suggested fix

Two viable paths; pick one. Both restore satisfiability without re-introducing R7-F01's baseline-relative wording.

**Option A — Drop the body-content Test Expectation; rely on the existing Manual Validation block.**

The Manual Validation block added at plan.md:273–274 (`git diff --stat HEAD~1 -- 'agents/qrspi-*.md'` shows 41 files × 1 deletion × 0 additions) already provides operator-verifiable assurance of no collateral body changes. The structural lint test (Test Expectations 1, 2, 4, 5 at plan.md:267–271) covers the no-`model:`-key invariant. Removing line 269 entirely is clean: the surviving criteria are testable and the diff-stat operator check covers collateral-damage detection.

**Option B — Restate the criterion as a body-content equality check, scoped per-file.**

Replace line 269 with a structural assertion that does not depend on tier-name presence:

> "For each modified `agents/qrspi-*.md` file, the file body below the closing YAML frontmatter delimiter (`---` line) is byte-identical between the pre-modification and post-modification states. The structural lint test verifies this by extracting the post-frontmatter substring and comparing against a fixture captured from the pre-modification tree."

This is testable (a BATS test can read both states from `git show HEAD~1:path` and the working tree), addresses R7-F01's BATS-testability concern with an explicit baseline pin (commit ref), and verifies the actual property being asserted (no collateral body change) without making false claims about tier-name presence.

Option A is simpler and lower-risk; Option B preserves an automated check at the cost of one `git show` invocation per file in the BATS sweep. Either resolves the blocking defect.
