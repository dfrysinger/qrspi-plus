---
finding_id: quality-claude-F01
artifact: research
severity: major
change_type: scope
referenced_files:
  - docs/qrspi/2026-06-04-v073-release/research/summary.md
---

`research/summary.md` lines 245–252 introduce a `## Cross-References` section that is not a verbatim extraction from any per-question `q*.md` file. None of `q01-q02-q03-codebase.md`, `q04-web.md`, `q05-codebase.md`, `q06-web.md`, `q07-q08-codebase.md`, `q09-codebase.md`, `q10-web.md`, `q11-q12-codebase.md`, `q13-q14-codebase.md`, `q15-web.md`, `q16-codebase.md`, or `q17-web.md` contains a `## Summary` block whose body includes any of the six bullets in this section (Q3×Q4, Q5×Q6, Q1×Q7, Q9×Q16, Q10×Q16, Q13×Q15). The bullets are synthesis statements that combine claims from two different questions (e.g., "Q3 × Q4: The codebase has no positive bats `@test` naming convention document … Q4 confirms this gap is industry-wide …"); they were authored at collation time rather than extracted.

The reviewer-protocol research-quality check states: "`research/summary.md` must be a verbatim extraction of the per-question `## Summary` blocks from the `q*.md` files; any paraphrasing, editorializing, or synthesis introduced during collation is a finding." The Cross-References section is synthesis introduced during collation. Each Q1–Q17 H2 block above the Cross-References section does match its source q-file verbatim — the violation is scoped to the Cross-References section only.
