---
finding_id: R1-F03
severity: low
change_type: scope
referenced_files:
  - "docs/qrspi/2026-06-04-v073-release/goals.md:L138-L141"
artifact: goals
round: 1
reviewer: scope-claude
---

G6 "What we know so far" (L138–L141) provides shell-level implementation pseudocode as part of "Candidate fix Design should weigh":

  - Compute `expected_tips` from `git rev-parse "qrspi/{slug}/task-${t}"` for each wave task ID.
  - `git merge ${expected_tips}` (explicit list).
  - Read `actual_parents=$(git log -1 --format='%P')`.
  - Assert order-independent set equality; on mismatch, HALT with a named diagnostic and do not advance the wave.

Goals DEFERS "implementation logic, function signatures, assertion text → Structure / Plan / Implement" (owns-defers.md). This block provides: specific shell variable names, git option strings, and an assertion step — all implementation-logic-register content. The candidate framing ("Design should weigh") partially mitigates the severity, but the level of specificity (actual git command flags, variable names) goes beyond what a goals artifact needs to express the mechanism ("validate that actual merge parents match the expected task-tip SHA set").

Proposed resolution: replace the pseudocode block with a one-sentence mechanism description (e.g. "validate actual merge-parent SHAs against the named task-tip SHA set; halt on mismatch") and leave the shell-level detail for Plan/Implement. The specific pseudocode can be preserved in a linked issue or Design's candidate-evaluation notes.
