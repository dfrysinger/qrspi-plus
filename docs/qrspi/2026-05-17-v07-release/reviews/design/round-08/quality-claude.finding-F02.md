---
finding_id: R8-F02
severity: low
change_type: clarity
referenced_files: [docs/qrspi/2026-05-17-v07-release/design.md:L234, docs/qrspi/2026-05-17-v07-release/design.md:L922-L928]
artifact: design
round: 8
reviewer: quality-claude
---

G5's initial routing matrix (line 234) lists `qrspi-test-writer` as:

> "Cheap-model eligible only if G6 splits test writing into its own dispatch | Coupled to G6's decision. Standalone test-writer dispatches are bounded enough to tolerate cheap models."

But Decision 3 (lines 922–928) and G6's Recommendation (line 270) both commit unconditionally: "Split test writing from code writing at the Implement phase for every TDD task. Universal for `task_type: code` (or absence of `task_type:`, which defaults to the TDD path)." There is no remaining conditionality — G6 resolved the conditional to "yes split, universally, for TDD tasks."

Leaving the G5 row phrased as a conditional dependency on a decision that has already been made forces a downstream reader (Phasing, Plan, or anyone tuning the matrix later) to re-resolve the chain rather than reading the final state. Recommend simplifying the row to:

> "Cheap-model eligible (Implement-phase mode) | Per Decision 3 / G6, test-writer is split from implementer for every TDD task. The Implement-phase dispatch is bounded (per-task spec, no production code), well-suited to cheap-model routing. Test-phase dispatches retain existing routing."

This also disambiguates that the routing applies to the **Implement-phase mode** of `qrspi-test-writer` (signal: `task_definition` present), since the Test-phase mode's routing should remain governed by `plan.md`'s `test_writer_model` per the existing dispatch pattern in research Q1/Q26.
