---
artifact: research
reviewer: quality-claude
round: 1
finding_id: R1-F01
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/research/summary.md
---

## Summary

`research/summary.md` contains a synthesized `## Cross-References` section (lines 422–436) that was not sourced from any per-question `## Summary` block in the 23 companion `q*.md` files. This section introduces synthesis by drawing cross-question relationships (e.g., "Q1 ↔ Q3 ↔ Q16", "Q2 ↔ Q21", "Q4 ↔ Q5 ↔ Q22", etc.) that do not appear in any individual question's Summary. The verbatim-collation contract for `research/summary.md` prohibits paraphrasing, editorializing, or synthesis introduced during collation; only verbatim extractions of `## Summary` blocks are permitted.

## Evidence

- `research/summary.md` lines 422–436 contain a `## Cross-References` section with 11 cross-question bullets.
- All 23 `q*.md` files were read in full. None contain a `## Cross-References` section, nor does any individual question's `## Summary` block contain the relationship text reproduced at lines 422–436.
- The `## Summary` blocks in every `q*.md` file (Q1–Q23) are reproduced verbatim in `summary.md` lines 7–421 — no paraphrasing was found in those 414 lines.
- The Cross-References section is the sole synthesized addition beyond the verbatim per-question extractions.

## Impact

The Cross-References section is substantive synthesis: it establishes conceptual chains across 23 questions that no single question's Summary asserts on its own (e.g., linking the verifier sidecar pipeline to the filter threshold rule and scoring rubric as "one continuous chain"). This introduces research-agent analysis that belongs, if anywhere, in the research q-files themselves — not in the collation document. Downstream artifacts that treat `summary.md` as a neutral verbatim collation may erroneously import the cross-question relationships as established research findings rather than collation-stage editorializing.
