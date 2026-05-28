---
finding_id: R15-F01
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/design.md:L252-L260]
artifact: design
round: 15
reviewer: quality-claude
---

The G5 dispatcher tolerance matrix entry for `qrspi-test-writer` has a contradictory label. The "Initial routing" cell reads "Cheap-model eligible (Implement-phase mode)" — implying the cheap-path eligibility applies only in Implement-phase mode. But the prose in the same cell immediately contradicts this: "G6 resolved the split universally for TDD tasks; both modes (Test-phase and Implement-phase) route to cheap-eligible models under the same conditional — the modes are preserved (per the G6 dual-mode contract), but no model-routing split exists between them."

If both modes are cheap-eligible under the same conditional, the table cell should not carry the parenthetical "(Implement-phase mode)." A reader building the routing matrix from the table alone will configure cheap routing only for Implement-phase dispatches of the test-writer and leave Test-phase dispatches on the trusted path — exactly the split the prose says does NOT exist.

The fix is to change the "Initial routing" cell to "Cheap-model eligible (both modes)" and update the "Reasoning" cell to reflect that eligibility is mode-agnostic: "Standalone test-writer dispatches are bounded enough to tolerate cheap models regardless of mode. Mode distinction is preserved in agent behavior but does not affect model routing."
