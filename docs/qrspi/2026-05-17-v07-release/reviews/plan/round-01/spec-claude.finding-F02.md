---
finding_id: R1-F02
severity: low
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/plan.md:885]
artifact: plan
round: 1
reviewer: spec-claude
---

Task 30's frontmatter carries `loc_estimate: 200` (plan.md line 885), but the task body (at the `- **LOC estimate:**` bullet) reads `test files (unmetered)`. The two values contradict each other: the frontmatter claims a 200-LOC budget, while the body prose asserts the task is exempt from LOC budgeting under the "test files unmetered" convention.

This creates an ambiguity for the apply-fix LOC-budget rule. If the frontmatter value is authoritative, the task is within budget and no sizing exception is needed. If the body prose is authoritative, the frontmatter estimate is misleading. A reader of the task spec cannot determine which convention the author intended.

The correct resolution depends on which value the author intended:

- If T30 is genuinely unmetered, set `loc_estimate: 0` and add a `sizing_exception` or else use the same "test files (unmetered)" annotation in the frontmatter comment as T30's description intends, then remove the contradictory `200` from the frontmatter.
- If T30 carries a real ~200 LOC budget, remove the "test files (unmetered)" language from the body.

Other test-bundle tasks in this plan are consistent: T13 says `loc_estimate: 220` with a body note about the helper being the first consumer; T36 says `loc_estimate: 200` in frontmatter with no "unmetered" body language. T30 is the only task with a contradiction between frontmatter and body on this field.

**Fix:** Align the frontmatter `loc_estimate:` value and the body `- **LOC estimate:**` bullet so they state the same thing. The preferred form is a real LOC estimate in the frontmatter (removing the "unmetered" body claim) since the same estimate is machine-readable by the apply-fix LOC check.
