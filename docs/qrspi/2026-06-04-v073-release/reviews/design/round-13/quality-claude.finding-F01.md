---
artifact: design
reviewer_tag: quality-claude
finding_id: quality-claude-F01
change_type: correctness
---

# G6 step 2 prose and single-task edge case contradict step 3's new parent[0]-stripping algorithm

## Location

`design.md` L396 (Solution step 2, "Capture procedure" trailing prose) and L405 (Dependencies + edge cases, single-task wave bullet); contrast with L397 (Solution step 3, as updated this round).

## Finding

Round 13 tightened Solution step 3 to validate two distinct invariants:

> (a) `actual_parents[0] == captured_integration_base_sha` (first-parent ordering is load-bearing for the integration spine), and (b) `set(actual_parents[1:]) == set(captured_task_tip_shas)` (full task-tip set match).

Invariant (b) explicitly strips `parent[0]` from the actual set and compares it against task tips only (not against the full combined set). It also presumes the sidecar exposes `integration_base_sha` and `task_tip_shas` as **separable** fields — they must be addressable independently for invariant (a) and (b) to be evaluated separately.

But the round-12 prose around step 3 was not updated to match:

1. **Step 2 (L396) describes the sidecar as a single combined set and disclaims parent[0]-stripping:**
   > "...writing the full {integration-base, task-tips...} set to a runtime sidecar... The validation in step 3 reads from this sidecar and compares the full parent set, with no parent[0]-stripping normalization."

   This contradicts step 3's invariant (b) on two counts: (i) step 3 *does* strip parent[0] from the actual set; (ii) step 3 needs the captured integration-base SHA and task-tip SHAs as separately readable fields, not as a single union set.

2. **Single-task edge case (L405) restates the no-stripping disclaimer:**
   > "Edge case — single-task wave: actual parents = {integration-base, task-tip}; expected = {integration-base, task-tip}... The validation always compares full parent set vs. full expected set with no parent[0]-stripping normalization."

   Same contradiction. After round 13, the single-task validation actually performs (a) `actual_parents[0] == integration_base_sha` AND (b) `set(actual_parents[1:]) == {task_tip_sha}` — which is parent[0]-stripping by definition.

The net effect: an implementer reading L396 and L405 would build a different validator (single set-equality, no ordering, sidecar as one combined set) than an implementer reading L397 (two ordered+set invariants, sidecar exposing two named fields). The first-parent ordering invariant the round-12 finding asked for becomes ambiguously specified.

## Expected fix

Update step 2's "Capture procedure" prose to (a) describe the sidecar as storing the integration-base SHA and the task-tip SHA set as **two separately addressable fields** (since invariant (a) and (b) read them independently), and (b) remove or replace the "compares the full parent set, with no parent[0]-stripping normalization" sentence — which is now actively false. Update the L405 single-task edge case bullet to describe the same two-invariant validation (parent[0] check + set check on parents[1:]) and remove the "no parent[0]-stripping normalization" claim. After the rewrite, steps 2, 3, the single-task edge case, and the L412 acceptance fixture should describe the same algorithm.
