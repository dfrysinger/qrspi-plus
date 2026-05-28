---
finding_id: R1-F08
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/research/summary.md:L226-L238]
artifact: research
round: 1
reviewer: quality-claude
---

The combined Q15/Q16/Q30 section is `[codebase]` research about reference-artifact treatment (visual-fidelity binding chain) in the QRSPI pipeline. Four Key findings bullets and the Surprises bullet make concrete claims about content of named files but none carries a `file:line` citation:

- "`agents/qrspi-visual-fidelity-reviewer.md` explicitly states that wireframe references are ground truth and limits its review surface to `visual_fidelity_check.wireframe_refs` plus corresponding code under review." — names the file but no line range for the "ground truth" statement.
- "Present reference-artifact kinds in the visual-fidelity chain are Figma URLs and embedded PNG paths in Design, artifact names cited in Phasing, and path-or-URL `wireframe_refs` in Plan; Implement only dispatches local absolute paths after canonicalization and allow-prefix filtering." — claim spans Design, Phasing, Plan, Implement skills but no file:line citations to any of them.
- "Current Plan task-spec template surfaces `wireframe_refs` and `ui_producing` only; it does not include a task-spec field for intentional visual deviations from the cited reference source." — no `skills/plan/SKILL.md:LXX-LYY` citation for the task-spec template.
- "Current validation/versioning is mostly structural and path-based: non-empty binding checks, legal-name citation checks, non-empty per-task refs, canonicalization/existence/allow-prefix validation, skip/path-filter audit records, and git commit/diff anchoring for QRSPI artifacts." — enumerates many distinct mechanisms but cites no file:line for any of them.
- "The visual-fidelity reviewer has strong ground-truth language, but the task-spec template provides no corresponding intentional-deviation field" — no file:line citations supporting the absence claim.

The reviewer-protocol research check requires `[codebase]` research to include `file:line` references for every factual claim. The absence claim ("no content hash, explicit version field, or Figma revision pin") is particularly load-bearing for downstream consumers and would benefit from explicit file:line citations to the wireframe-related sections searched.
