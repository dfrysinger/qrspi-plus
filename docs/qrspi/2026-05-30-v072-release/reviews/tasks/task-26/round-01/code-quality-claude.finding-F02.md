---
reviewer: code-quality-claude
round: 1
finding_id: R1-F02
severity: medium
change_type: prose
referenced_files:
  - skills/plan/SKILL.md
---

# F02 — "Addition A" design-time label leaks into production SKILL.md prose

Both Addition B occurrences reference "per Addition A's content-semantic test." "Addition A" is design.md G31 vocabulary; an operator reading plan/SKILL.md has no way to resolve the reference. Self-referential phrasing ("per the detection include above") is what Addition A's own insertion point uses elsewhere in the file.

**Fix:** Replace "per Addition A's content-semantic test" with "per the detection include above" (or drop the parenthetical entirely — the `!cat` line above makes the source unambiguous).

**Adjudication: ACT.** Direct prose quality issue on T26's own output; trivial fix.
