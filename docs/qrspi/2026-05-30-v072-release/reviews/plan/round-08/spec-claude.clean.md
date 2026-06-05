---
reviewer: spec-claude
round: 8
verdict: clean
---

# Spec Review — Round 8 (broaden-vs-main) — Clean

Verified the round-07 E1 surgical fix (T25 L1408 added Test Expectation bullet binding the L1400 DoD invariant to an executable repo-wide grep audit for stale `docs/prompt-design-guide.md` references) and scanned the full broaden-vs-main diff for any new spec-level defects.

## E1 fix verification

**Target:** plan.md T25 (G31 prompt-prose primitives), Test Expectations block.

**Added bullet (L1408):**
> Repo-wide grep audit asserts zero remaining live references to `docs/prompt-design-guide.md` outside historical CHANGELOG entries (matches DoD invariant — fails the build on any stale source-of-truth reference).

**DoD invariant it verifies (L1400):**
> No stale `docs/prompt-design-guide.md` references remain in the repo (grep returns zero matches outside historical CHANGELOG entries).

Checks:
- Carve-out language identical on both sides (`outside historical CHANGELOG entries`).
- "Zero remaining live references" mirrors "zero matches" — equivalent semantics.
- Parenthetical correctly cites the DoD link, no ambiguity about which invariant.
- Specific, executable Test Expectation (grep → non-zero exit on stale ref), not vague.
- No duplication with other T25 test expectations (L1413 file-existence, L1415 byte-for-byte diff, L1416 frontmatter, L1417 `git log --follow`, L1418 A-H edits audit, L1419 R1-R7 meta-pass, L1420 anchor-phrase audit — none covered the "no stale refs outside CHANGELOG" surface before E1).
- No scope drift: migration + delete already in-scope at T25 Scope.In L1391–L1392 and DoD L1402.

## Full-diff sweep for new defects

1. **Completeness** — only T25 Test Expectations changed this round; full goal-coverage mapping unchanged from prior rounds where it was verified clean.
2. **Scope** — no new task or deliverable introduced; the added bullet strengthens an existing invariant.
3. **Interpretation** — E1 bullet matches the DoD invariant intent (block any post-migration stale references in source-of-truth files).
4. **Test coverage mapping** — E1 strictly improves G31 verifiability by converting a DoD assertion into an executable acceptance probe. No new gaps.
5. **Placeholder detection** — new bullet contains no TBD/TODO/"as needed"/vague phrasing.
6. **Task sizing** — T25 carries `sizing_exception: reusable primitives` (closed-set value); LOC budget ~340 unaffected by a single added bullet; no rebundling triggered.

## Dropped round-07 findings (per dispatch directive)

The four dropped findings (sec-codex F01 path-traversal halt; scope-codex F01 L11 vs L110 phrasing; silent-failure-codex F01 T16 medium fallback; test-coverage-codex F01 T39 build-twice determinism) all sit outside T25's E1 surface and are not reopened by the surgical fix. Not re-raised.

## Verdict

Clean. The round-07 E1 fix is consistent, complete, and well-bound to the DoD invariant it verifies. No new spec defects emerge across the broaden-vs-main diff.
