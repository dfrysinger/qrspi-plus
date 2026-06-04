---
finding_id: R3-F02
severity: low
change_type: clarity
referenced_files: [tests/unit/test-per-finding-file-emission.bats:L188-L237]
artifact: task-03
round: 3
reviewer: code-quality-claude
---

The four new tests added in R3 (lines 188-237) each lead with a "Fix N" reference in their orientation comment:

- L189 — `# Fix 2: schema fields/audit fields/finding_id uniqueness paragraphs must live in`
- L211 — `# Fix 4: the parenthetical 'will fail silently' must be pinned so regressions are caught.`
- L219 — `# Fix 5: reviewer_tag must be validated against ^[a-z0-9-]+$ before path construction.`
- L231 — `# Fix 6: NO_FINDINGS must be emitted only as result of own analysis, never as`

These "Fix 2/4/5/6" labels are direct references to the round-3 disposition-list numbering ("the 2nd / 4th / 5th / 6th of the 6 in-scope R3 fixes"). They carry no signal once the round-3 dispositions are no longer the active context — a reader six months from now will see "Fix 2" and have no way to know which round, which artifact, or which disposition list that ordinal indexes.

This is the same class of round-artifact leakage the R3 sweep deliberately scrubbed elsewhere in this very file (diff line 248: `post-G6 split` → `post-split`; diff line 280: `Round-2 fix for spec-claude/spec-codex F01.` → `Post-split hygiene fix.`). The new tests added in the same diff reintroduce a near-identical pattern with a different prefix.

The rest of each comment is actually a fine durable orientation: "schema fields/audit fields/finding_id uniqueness paragraphs must live in SKILL.md only; siblings must cross-reference rather than duplicate them verbatim" describes the invariant the test pins without needing the round-N context. Just dropping the `Fix N:` prefix from each of the four comments leaves a clean, self-contained orientation.

**Suggested fix.** Strip `Fix 2:`, `Fix 4:`, `Fix 5:`, `Fix 6:` from the four comment-leads. The remaining prose already documents what each test pins and why.
