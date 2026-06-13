---
finding_id: R5-F02
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-06-04-v073-release/plan.md:L829-L834
artifact: plan
round: 5
reviewer: test-coverage-claude
---

T10 (`test-finding-verifier-id-hygiene-grounding.bats`) Test Expectations — sidecar schema not specified for ≥70 score assertion.

T10's primary test expectation is: "A synthetic verifier dispatch on a `[Tnn]` fixture finding `inspects the resulting sidecar and asserts the score is ≥ 70` against the post-T09 rubric." The secondary expectation similarly says "scored under the v0.7.2 verifier scores < 70."

**What is unverifiable:** The test writer cannot write a deterministic test from these expectations because the "resulting sidecar" schema is not specified anywhere in the plan:
- Which file on disk holds the score? (filename pattern, location)
- Which field within that file holds the numeric score? (field name, nesting)
- What format/type is the value? (integer, float, string like "73/100")

Without this, "inspects the resulting sidecar" is an implementation assumption — the test writer must discover the existing verifier's output format from v0.7.2 source code rather than from the plan's test expectations. This violates the determinism criterion: the same specification should produce the same test regardless of whether the test writer has access to the existing codebase.

**The third bullet partially addresses this** ("the fixture finding's grounding section in the sidecar names `skills/implementer-protocol/SKILL.md` § Hygiene contract as the authority cited") but uses the same underspecified "sidecar" reference.

**Fix:** Add a parenthetical to the ≥70 bullet that names the sidecar file pattern and the field/key holding the score (e.g., "by reading `reviews/implement/<task>/verifier-score.md` and extracting the `score:` YAML field, or whichever schema the existing verifier writes"). If the sidecar schema is already documented elsewhere in the codebase and stable, a reference to that schema file is sufficient.
