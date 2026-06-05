---
reviewer: code-quality-claude
round: 2
finding_id: R2-F01
severity: medium
change_type: prose
referenced_files:
  - agents/qrspi-design-reviewer.md
---

# F01 — ID hygiene: G31 and T29 in production prompt template body

`agents/qrspi-design-reviewer.md:48` Addition D scope-gap note (added in T26 R1 fix-cycle 2 closing sf-claude F03) carries QRSPI-internal IDs (G31, T29) on a strict prompt surface.

**Fix:** Strip both IDs. Express as "scope-dimension checks for prompt-prose marker accuracy" and drop "(T29 plumbing)" parenthetical (qrspi-design-scope-reviewer is already named in the same sentence).

**Adjudication: ACT.** Converges with cq-codex R2-F01.
