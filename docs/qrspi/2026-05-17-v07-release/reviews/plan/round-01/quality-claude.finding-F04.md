---
finding_id: R1-F04
severity: low
change_type: clarity
referenced_files: [docs/qrspi/2026-05-17-v07-release/plan.md:L879-L898]
artifact: plan
round: 1
reviewer: quality-claude
---

Task 30's description contains a contradictory statement about its LOC estimate. The frontmatter declares `loc_estimate: 200` (a valid numeric estimate), but the description body states "Test files are unmetered per the LOC-budget rule; the pin count (5) and the integration-tier pin (a real cross-skill exercise rather than a markdown-section assertion) drive the opus classification." The phrase "test files (unmetered)" also appears in the description's LOC estimate line within the target-files section at line 897: `- **LOC estimate:** test files (unmetered)`.

These two representations are contradictory: the frontmatter says 200, the description says unmetered. A reader comparing the two cannot tell which is authoritative. The implementer dispatched against this task will see a frontmatter value of 200 and a description that says unmetered — likely harmless for this task since the classification rationale is clear, but the inconsistency undermines confidence in the LOC-estimate field across the plan.

The description's "unmetered" language likely predates the frontmatter's numeric value being added; the frontmatter value is the operative one for downstream tooling. The description body should either be updated to drop the "unmetered" claim and reference the 200 estimate, or the description's rationale for "unmetered" should be preserved and the frontmatter updated to `loc_estimate: 0` with a `sizing_exception: reusable primitives` note — matching the T13/T19 pattern consistently.

Resolution: reconcile the description's "test files (unmetered)" statement with the frontmatter `loc_estimate: 200` by picking one representation and making both consistent. The frontmatter value 200 is the simplest fix — remove the "unmetered" language from the description.
