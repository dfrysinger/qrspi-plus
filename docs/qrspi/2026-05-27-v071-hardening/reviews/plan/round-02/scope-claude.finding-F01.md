---
finding_id: F01
severity: medium
change_type: scope
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/plan.md]
artifact: plan
round: 2
reviewer: scope-claude
---

## "Reviewer Findings Set Aside" section is not Plan-owned content

The new `## Reviewer Findings Set Aside` section (lines 278–287, added in round-02) contains review process history: acknowledgments of prior findings, resolution rationale, and cross-reviewer finding citations (e.g. "security-codex F02", "testcov-claude F06", "scope-codex PLAN-SCOPE-002 / scope-claude SC-1").

Per owns-defers, every paragraph in plan.md must trace to one of the Plan OWNS items:

- Ordered task specs
- Test expectations per task
- Dependencies
- LOC estimates

None of the content in `## Reviewer Findings Set Aside` maps to any of these. It is review-round meta-documentation — a summary of what prior reviewers flagged and why the author chose to resolve or not resolve each finding. This category of content belongs in a per-round review response document (e.g., alongside the diff or in the review subdir), not embedded in the plan artifact.

The practical harm: embedding review-round history in plan.md conflates the artifact under review with the review audit trail. Future reviewers reading plan.md cannot distinguish normative plan content from accumulated response notes, and the plan grows with each review round for non-plan reasons.

**Recommended fix:** Remove the `## Reviewer Findings Set Aside` section from plan.md. If a record of reviewer-response rationale is needed, place it in a `review-response.md` file in the review subdir (e.g., `reviews/plan/round-02/review-response.md`) or in the PR description — not in the plan artifact itself.
