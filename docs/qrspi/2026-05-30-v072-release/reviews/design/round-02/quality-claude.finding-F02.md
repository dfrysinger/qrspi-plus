---
finding_id: R2-F02
severity: medium
change_type: correctness
artifact: design
round: 2
reviewer: quality-claude
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/design.md
---

## Test Strategy § Cross-cutting invariants — G6 clause assigns T5 to assert iron-law clause content in emission files, outside T5's `agents/qrspi-*.md` coverage boundary

**Location:** `design.md` L734 (Test Strategy § Cross-cutting invariants)

**Problem.** The G6 cross-cutting invariant reads:

> "G6 emission iron-law (T5 asserts the iron-law clause is present in both emission files verbatim)."

T5's coverage boundary is defined at L726:

> "Coverage boundary: every reviewer agent in `agents/qrspi-*.md`."

T5's defined assertions are:
- (a) the agent's frontmatter `tier:` field is set
- (b) the agent body contains the `change_type:` enum block in canonical form
- (c) the first-party-emission OR third-party-emission file is present in the dispatch-prompt assembly for that agent

The emission files themselves (`skills/reviewer-protocol/first-party-emission.md`, `skills/reviewer-protocol/third-party-emission.md`) are **protocol files**, not reviewer agents. They live under `skills/reviewer-protocol/`, not `agents/`. Asserting that the iron-law clause is present verbatim in those files' *content* falls outside T5's stated coverage boundary.

Note: T5 item (c) verifies that the emission file is *referenced* in the dispatch-prompt assembly for each agent — file presence, not file content. The G6 cross-cutting invariant requires checking what's *inside* the files, which is a different assertion and a different coverage surface.

**Impact.** Plan authors following T5's coverage boundary would write T5 tasks that check agent frontmatter and enum blocks. The iron-law clause content check in emission files would either be silently added as an undeclared T5 extension (scope creep on T5) or omitted from the test suite entirely.

**Suggested fix.** Reassign the G6 iron-law invariant to T1 (a `grep -L 'Iron law'` check over `skills/reviewer-protocol/{first,third}-party-emission.md` run in CI) or to T2 (a bats test that reads the emission files and asserts the clause verbatim). If T5's boundary is extended to include protocol files, that extension must be stated explicitly in T5's definition.
