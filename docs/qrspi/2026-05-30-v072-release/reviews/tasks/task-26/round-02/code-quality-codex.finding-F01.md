---
reviewer: code-quality-codex
round: 2
finding_id: R2-F01
severity: medium
change_type: prose
referenced_files:
  - agents/qrspi-design-reviewer.md
---

# F01 — ID hygiene violation: G31/T29 internal tokens in agent prompt prose

`agents/qrspi-design-reviewer.md:48` (Addition D scope-gap note added in T26 R1 fix-cycle 2 closing sf-claude F03):

> scope-dimension **G31** checks … deferred … (**T29** plumbing)

Per ID hygiene rules, QRSPI-internal IDs (G## goal IDs, T## task IDs) are forbidden on strict prompt surfaces outside `docs/qrspi/`. Replace with descriptive phrasing.

**Fix:** Replace with run-ID-free phrasing, e.g.:
> Note: scope-dimension prompt-prose checks (marker-absent prompt prose blocks, altitude mismatches, mis-targeted markers) are out of scope for the quality dimension and are addressed by the design scope-reviewer's prompt-prose plumbing.

**Adjudication: ACT.** Trivial prose fix; ID hygiene is a load-bearing rule.
