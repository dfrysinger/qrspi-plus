---
finding_id: R14-F01
severity: medium
change_type: clarity
referenced_files: [docs/qrspi/2026-05-17-v07-release/design.md:L254]
artifact: design
round: 14
reviewer: quality-claude
---

In the G5 dispatcher tolerance matrix, the row for `qrspi-test-writer` contains the sentence "G6 resolved the split universally for TDD tasks, so the conditional is closed." This phrase is confusing because the row that follows it still describes two distinct modes with separately-stated routing eligibility ("Cheap-model eligible (Implement-phase mode) ... Test-phase mode (signal: `task_definition` absent) retains the same eligibility"). A reader landing on "the conditional is closed" naturally interprets this as meaning the mode distinction no longer exists, but the intent is that both modes independently resolved to the same routing outcome (cheap-eligible). The stated resolution is not "the mode distinction was removed" — it is "both modes independently reached the same conclusion."

Proposed fix: replace "G6 resolved the split universally for TDD tasks, so the conditional is closed" with wording such as: "Both Implement-phase and Test-phase dispatches independently resolve to cheap-model eligible; no per-mode conditional routing is needed." This preserves accuracy while removing the misleading implication that the dual-mode contract itself was eliminated.
