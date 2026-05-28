---
finding_id: R5-F01
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-17-v07-release/plan.md:L926-L932
artifact: plan
round: 5
reviewer: spec-claude
---

Task 30's frontmatter carries `loc_estimate: 250` (plan.md line 932) but no `sizing_exception:` field, and the task body has no `**Sizing exception:**` bullet. The review checklist requires that any task with LOC > 200 carry a `sizing_exception` whose reason is from the closed set (schema migration, CI scaffolding, or reusable primitives).

T30 authors five BATS pin files (four unit, one integration). The description at line 945 explains the estimate inline — "The pin count (5) and the integration-tier pin (a real cross-skill exercise rather than a markdown-section assertion) drive the opus classification, with a ~250 LOC estimate (roughly proportional to the five behaviors covered)" — but does not name a formal sizing exception from the closed set.

The analogous task T07 (also five co-shipped BATS pins, 220 LOC) carries `sizing_exception: reusable primitives` with the rationale that the five pins co-ship as the Slice 1 contract-lock and cannot land separately without leaving contracts unobserved. T30's situation is identical: the five Slice 5 pins together form the observable contract surface for G10+G11+G14, and separating them would leave the Slice 5 acceptance criteria unobserved.

**Fix:** Add `sizing_exception: reusable primitives` to T30's frontmatter (alongside the existing `task_type`, `model`, `phase`, `goal_ids`, `dependencies`, `loc_estimate` fields), and add a corresponding `**Sizing exception:** reusable primitives — the five pins co-ship as the Slice 5 contract-lock; splitting them would leave the reference-gate-fields, ui-task-fields, wave-context-shape, quick-tier-wording, and reference-gate-pause contracts unobserved independently` bullet to the task body, consistent with how T07 and T13 document their same-pattern exception.
