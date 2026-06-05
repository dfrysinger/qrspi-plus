---
finding_id: R6-F01
severity: high
change_type: correctness
referenced_files: [docs/qrspi/2026-05-30-v072-release/plan.md]
---

AC #2 explicitly treats both routing and second-reviewer slot selection as fail-loud release invariants in one chain: line 22 requires loud failure for both "dispatch on misrouted `model_routing` entries" and `_resolve-lib.sh` `[second-reviewer-same-vendor]` cases.

But the task graph does not enforce that ordering: Task 16 (the `model_routing` migration + `_resolve-lib.sh` routing semantics) is line 63 and blocks only T17 (line 974), while Task 19 (which adds `_resolve-lib.sh` same-vendor / second-reviewer fail-loud behavior) has "**Dependencies:** none" (line 1103 / list line 65).

This leaves a fail-open planning gap: T19 acceptance can pass before the G22 resolver migration lands, then later `_resolve-lib.sh` edits from T16 can invalidate T19's fail-loud guarantees without a dependency-enforced gate. For an AC #2 invariant that is explicitly cross-task and fail-loud, the plan should force T16-before-T19 (or equivalent explicit gating) instead of allowing independent sequencing.
