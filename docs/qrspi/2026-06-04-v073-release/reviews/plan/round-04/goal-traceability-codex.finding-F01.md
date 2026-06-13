---
finding_id: R4-F01
severity: high
change_type: intent
referenced_files:
  - /Users/dfrysinger/code/qrspi-plus-v0.7.2/docs/qrspi/2026-06-04-v073-release/design.md:L381-L382
  - /Users/dfrysinger/code/qrspi-plus-v0.7.2/docs/qrspi/2026-06-04-v073-release/plan.md:L149-L150
  - /Users/dfrysinger/code/qrspi-plus-v0.7.2/docs/qrspi/2026-06-04-v073-release/plan.md:L561-L565
artifact: plan
round: 4
reviewer: goal-traceability-codex
---

G5 traceability/fidelity is internally inconsistent: the approved design commits `scripts/orchestration-boundary-check.sh` to fail-soft (`exit 0 on clean and dirty`, with report content as the signal), but the plan now requires non-zero exits for `## Dispatch defects` and treats that as G5 acceptance coverage. That is a design-contract change authored in plan.md without a corresponding design amendment, so the "G5 Acceptance bullet 4" trace is no longer valid. Resolve by either (a) amending design.md G5 acceptance to explicitly adopt the dispatch-defect fail-loud branch, or (b) reverting the plan's G5 criteria/tasks back to the current design's fail-soft contract.
