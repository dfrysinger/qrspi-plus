---
finding_id: quality-claude-F02
artifact: research
severity: minor
change_type: intent
referenced_files:
  - docs/qrspi/2026-06-04-v073-release/research/summary.md
---

`research/summary.md` line 247 (the Q3 × Q4 cross-reference) ends with the sentence: "Both findings suggest that adding a project-specific grep-based CI gate is the viable path." This is a recommendation/solution suggestion embedded in the research summary, not a description of what is. The objectivity check for research artifacts requires that "findings report what IS, not what SHOULD BE; no opinions, recommendations, or solution suggestions embedded in the research." Phrases like "the viable path" prescribe a future action and editorialize on the implications of the findings rather than describing observed evidence.

By contrast, the other five cross-reference bullets (Q5×Q6, Q1×Q7, Q9×Q16, Q10×Q16, Q13×Q15) restrict themselves to descriptive observations ("are functional analogs", "define the full chain", "identify a gap", "concrete instances of this pattern", "implementation of the same principle") without prescribing an action — which is the form research-summary cross-references should take if retained.
