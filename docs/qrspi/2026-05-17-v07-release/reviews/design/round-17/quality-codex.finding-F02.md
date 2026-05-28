---
finding_id: R17-F02
severity: high
change_type: correctness
referenced_files: [design.md:L317-L319, design.md:L347-L348, design.md:L982-L982, design.md:L1142-L1145]
artifact: design
round: 17
reviewer: quality-codex
---

The RED-verification gate is internally inconsistent. The detailed G6 contract says mixed suites are allowed so long as at least one task-relevant assertion fails and there are no infrastructure failures; it even includes an explicit pass-case example with two pre-passing assertions and one targeted failing assertion. But Decision 3 and the cross-cutting test strategy later restate the rule as “pause if any pre-implementation test passes,” which would reject that same mixed-suite case. This is load-bearing behavior for Implement, so downstream agents need one rule. Fix by rewriting the later summary sections to match the detailed gate contract: pause only when no targeted assertion fails, or when any infrastructure failure occurs.
