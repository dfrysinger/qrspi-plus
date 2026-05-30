---
finding_id: R2-F01
severity: medium
change_type: correctness
referenced_files: [agents/qrspi-test-writer.md]
artifact: integration
round: 2
reviewer: integration-claude
---

## Implement-phase Output: line (line 78) inconsistent with new Output Contract token set (line 271)

**Surface:** `agents/qrspi-test-writer.md:78` vs `agents/qrspi-test-writer.md:271`

The round-01 fix (575c00a) expanded the status-token set in the new "All modes" Output Contract from 3 tokens to 4:
- Line 271 (post-fix, "All modes"): `DONE`, `DONE_WITH_CONCERNS`, `NEEDS_CONTEXT`, or `BLOCKED`
- Line 78 (unchanged, implement-phase Behavior "Output:"): `DONE`, `DONE_WITH_CONCERNS`, or `NEEDS_CONTEXT`

This is the same class of intra-file contradiction R1-F02 flagged — different section, smaller scope. An LLM following the implement-phase Behavior block at line 78 has no in-prompt warrant to emit `BLOCKED`; an LLM following the Output Contract sees `BLOCKED` as a permitted token without enumeration of when it applies.

**Suggested fix:** smallest coherent change — update line 78 to enumerate all four tokens:
> "Report as `DONE`, `DONE_WITH_CONCERNS`, `NEEDS_CONTEXT`, or `BLOCKED` ..."

**Self-scored:** ~62 (below typical KEEP threshold). Reviewer recommends routing to v0.7.2 followup alongside #233 prose drift rather than spawning another fix round.
