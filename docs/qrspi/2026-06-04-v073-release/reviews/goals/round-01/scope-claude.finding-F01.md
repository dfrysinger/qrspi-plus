---
finding_id: R1-F01
severity: medium
change_type: scope
referenced_files:
  - "docs/qrspi/2026-06-04-v073-release/goals.md:L142"
artifact: goals
round: 1
reviewer: scope-claude
---

G6 "What we know so far" (L142) carries the sentence:

> "Acceptance must include bats coverage where a fixture stage-commit with mismatched parents is rejected."

The word "must" makes this a binding acceptance criterion, not a candidate for Design to weigh. Goals DEFERS "Acceptance criteria → Design's Test Strategy + Plan's per-task expectations" (owns-defers.md). By stating the acceptance criterion here, goals.md pre-commits a specific bats-fixture test gate before Design or Plan have been authored — constraining those artifacts in ways the user may not have intended to lock at the goals layer.

Proposed resolution: remove the sentence from goals.md and carry the acceptance intent forward as a note for Design (e.g. under G6's candidate framing: "Design should specify an acceptance criterion for parent-SHA validation"). The bats-fixture requirement itself belongs in Plan's per-task test expectations for the G6 implementation task.
