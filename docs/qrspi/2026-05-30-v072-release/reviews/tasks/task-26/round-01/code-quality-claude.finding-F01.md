---
reviewer: code-quality-claude
round: 1
finding_id: R1-F01
severity: medium
change_type: prose
referenced_files:
  - skills/plan/SKILL.md
---

# F01 — Addition B Test-Expectations clause duplicated verbatim at 2 sites in plan/SKILL.md

The Test-Expectations clause paragraph for prompt-prose tasks is copy-pasted byte-for-byte at two sites (Plan Overview Subagent ~L100; Sub-Subagent Dispatch ~L147). The `!cat` mechanism factored detection and writer-addition into shared files but Addition B itself is inlined twice.

**Fix:** Extract Addition B into `skills/_shared/prompt-prose-test-expectations-clause.md` and replace both inline copies with `!cat skills/_shared/prompt-prose-test-expectations-clause.md`, consistent with the pattern already used for detection and writer-addition.

**Adjudication: ACT.** Same DRY pattern T26 already uses for detection/writer; trivial extension; no scope creep.
