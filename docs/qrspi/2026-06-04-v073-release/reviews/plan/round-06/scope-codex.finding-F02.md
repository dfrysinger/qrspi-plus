---
finding_id: R6-F02
severity: medium
change_type: scope
referenced_files:
  - /Users/dfrysinger/code/qrspi-plus-v0.7.2/docs/qrspi/2026-06-04-v073-release/plan.md:L567-L580
  - /Users/dfrysinger/code/qrspi-plus-v0.7.2/docs/qrspi/2026-06-04-v073-release/plan.md:L603-L607
  - /Users/dfrysinger/code/qrspi-plus-v0.7.2/docs/qrspi/2026-06-04-v073-release/plan.md:L392-L399
artifact: plan
round: 6
reviewer: scope-codex
---

Boundary drift: multiple task specs and test expectations prescribe implementation/control-flow mechanics (exact command invocations, branch ordering, parser/validation sequencing, and concrete grep command assertions) instead of staying at plan-level behavior expectations. Per Plan DEFERS, line-by-line logic belongs to Implement and assertion/code-level detail belongs to Implement-TDD. Tighten these sections to observable outcomes and leave execution mechanics to downstream artifacts.
