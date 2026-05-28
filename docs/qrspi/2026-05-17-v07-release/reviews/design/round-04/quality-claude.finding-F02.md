---
finding_id: R4-F02
severity: medium
change_type: clarity
referenced_files: [docs/qrspi/2026-05-17-v07-release/design.md:L272-L282]
artifact: design
round: 4
reviewer: quality-claude
---

G6's "Dispatch shape on the TDD path" specifies that Implement dispatches `qrspi-test-writer` with `task_definition` present as the per-task-mode signal, mirroring the per-task reviewer reuse pattern. The signal mechanism is clear, but the dispatch parameter set for the new Implement-phase mode is left entirely unspecified. This creates two clarity problems for downstream agents (Structure, Plan):

1. **Companion mismatch is not addressed.** Per `research/summary.md` Q10, the existing Test-phase `qrspi-test-writer` dispatch carries `companion_plan`, `companion_goals`, `companion_design_or_research`, `companion_fix_history`, `companion_codebase_context`, and `output_dir`. These are whole-phase scopes appropriate for Test-phase work. An Implement-phase per-task test-writer dispatch needs different scope (the task spec, the task's pipeline inputs, the task's target files), but the design says nothing about which companions Implement passes. A downstream agent has no way to know whether the existing companion set is reused, replaced, or extended.

2. **The agent body's two-mode behavior is unspecified.** The existing `qrspi-test-writer` agent body (per Q10) writes acceptance/integration/e2e/boundary tests against `companion_plan` criteria. The new Implement-phase mode would write failing unit tests against a task spec. These are materially different jobs — the design's "per-task signal" framing implies the agent body needs to branch on `task_definition` presence to do them, but Structure/Plan won't know what behavior to specify for the Implement-phase branch without a design-level statement.

The design owns the dispatch contract at the parameter level (Decision 1 of the reviewer-protocol contract treats dispatch parameter sets as load-bearing). Resolution: add a short subsection to G6 naming the Implement-phase dispatch parameter set (companions + scalar fields) and a one-line statement of how the agent body's behavior differs between the two modes. Detailed wording can defer to Structure/Plan, but the parameter list and the mode-behavior split belong at design.

Without this, Structure faces two genuine open questions (which companions, which behavior) that the design implicitly defers without flagging.
