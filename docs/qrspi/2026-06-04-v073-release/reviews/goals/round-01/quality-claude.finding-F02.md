---
finding_id: R1-F02
severity: low
change_type: correctness
referenced_files: [docs/qrspi/2026-06-04-v073-release/goals.md:L142]
artifact: goals
round: 1
reviewer: quality-claude
---

G6's "What we know so far" contains an acceptance criterion stated as a requirement rather than a candidate:

> "Acceptance must include bats coverage where a fixture stage-commit with mismatched parents is rejected."

The "must" phrasing commits Design and Implementation to a specific verification mechanism — a bats fixture for mismatched stage-commit parents — rather than offering it as a candidate Design will weigh. Goals should record what is known and name candidates; acceptance criteria decisions belong to Design (and ultimately the Plan step).

The same section correctly frames the fix approach as "Candidate fix Design should weigh" (L137); the acceptance line immediately after it breaks that pattern by switching from candidate language to requirement language.

**Fix:** Reframe as a candidate, e.g.:

> "Candidate acceptance approach Design should weigh: bats coverage where a fixture stage-commit with mismatched parents causes the validation to HALT with a named diagnostic."
