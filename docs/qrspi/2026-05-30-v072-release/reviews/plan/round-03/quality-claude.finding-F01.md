---
finding_id: F01
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/plan.md
  - docs/qrspi/2026-05-30-v072-release/design.md
artifact: docs/qrspi/2026-05-30-v072-release/plan.md
---

## Plan overview misattributes G24 and G26 dispositions as "absorbed-by-CD-1"

**Location.** `plan.md` line 11, in the Overview paragraph:

> "...into 38 tasks (task numbers 1–44 with gaps at 18, 22, 23, 41, 42, 43 — those goal IDs are moot/absorbed-by-CD-1 per design.md ## G24/G25/G26/G29 and ship no standalone v0.7.2 task; numbering preserved for stable cross-references)."

**Problem.** The single umbrella phrase "moot/absorbed-by-CD-1 per design.md ## G24/G25/G26/G29" is correct for G25 and G29, but inaccurate for G24 and G26 — and the inaccuracy obscures the actual reason each gap-task ID exists.

Cross-checking design.md:

- **G25** (design.md L2084–2119, title "Per-H4 fail-loud mirror pattern: moot / absorbed by CD-1"). ✓ Correctly "absorbed by CD-1".
- **G29** (design.md L2308–2347, title "Reviewer dispatch artifact escape hatch: moot / absorbed by CD-1"). ✓ Correctly "absorbed by CD-1".
- **G24** (design.md L2045–2080, title "R4 simplify-claude advisories: re-scoped to F05 after tree audit (F01/F03/F04 moot; F02 defers to G25)"). ✗ G24 is NOT uniformly "absorbed by CD-1" — F01/F03/F04 are "moot after tree audit" (the target helpers/regex never materialized in the current tree), F02 defers to G25 (which is then absorbed by CD-1), and F05 ships as standalone T44.
- **G26** (design.md L2123–2162, title "BW02 deprecation warnings: moot / already fixed (regression-prevention rides on G21)"; also cited at plan.md L2339 in Task 40 References). ✗ G26 is NOT absorbed by CD-1 — design.md explicitly says G26's runtime concern is moot ("already-fixed" / premise inverted vs. bats-core upstream) and the regression-prevention BW02 lint rule is consolidated into G21's lint file via the G21 Amendment block (T40, plan.md L2284–2344). T40 itself carries `goals: [G21, G26]`.

The plan's own Task 40 references at L2339 quote design.md ## G26 accurately ("G26's runtime concern is moot (splitter already fixed pre-v0.7.2) and remaining work is the BW02 lint rule consolidated into G21's lint file"), so the Overview's umbrella framing actively contradicts the per-task framing later in the same plan.

**Impact.** A reader using the plan Overview to understand why six task slots are gaps will form an incorrect mental model of *why* each gap exists — and will not know to look for the G26 BW02 work inside T40, or for G24-F02's resolution chain through G25→CD-1, or for G24-F01/F03/F04's "moot after tree audit" disposition (a distinct disposition class from CD-1 absorption). The mis-attribution also hides the fact that not every gap has the same root cause, which matters when later QRSPI runs revisit the "gap-task ID" pattern to extract reusable disposition vocabulary (design.md ## G29 Open Question (c) explicitly calls out three distinct absorption flavors in this release).

**Suggested edit.** Replace the umbrella "moot/absorbed-by-CD-1 per design.md ## G24/G25/G26/G29" wording with per-gap dispositions matching design.md:

> "...into 38 tasks (task numbers 1–44 with gaps at 18 (G25, absorbed by CD-1), 22 (G24-F02, defers to G25 → CD-1), 23 (G24-F04, moot after tree audit), 41 (G26, runtime concern already fixed; BW02 regression-prevention rides on G21 in T40), 42 (G24-F01, moot after tree audit), 43 (G24-F03, moot after tree audit); G29 is also absorbed by CD-1 and ships no standalone task — T11 was repurposed to a CD-1 dispatch-manifest-provenance task under G3 rather than being deleted. See design.md ## G24/G25/G26/G29 for per-disposition rationales; numbering preserved for stable cross-references)."

Or, if a shorter overview is preferred, at minimum drop G24/G26 from the "absorbed-by-CD-1" framing and replace with the broader "moot/absorbed/already-fixed per design.md ## G24/G25/G26/G29" so the umbrella is technically defensible against all four references.
