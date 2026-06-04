---
finding_id: R1-F03
severity: medium
change_type: scope
artifact: code
round: 1
reviewer: spec-codex
model: gpt-5.3-codex
referenced_files:
  - scripts/run-codex-review.sh#L571-L572
  - tasks/task-09.md#L26
  - tasks/task-09.md#L32
  - tasks/task-09.md#L41
---

# Scope overreach: `subagent_type` persisted though out-of-scope

**Spec scope:** Task asks manifest host/vendor/model flow (`tasks/task-09.md` lines 26, 41) and explicitly marks broader G3 provenance fields (including `subagent_type`) as out-of-scope for this task (`tasks/task-09.md` line 32: "G3 dispatch-manifest provenance fields (`subagent_type`/`host`/`vendor`/`model`/`prompt_file`) on pre-rename `scripts/run-codex-review.sh` — T11 owns; this task touches the same dispatch manifest only for the `actual_model:` flow").

**Observed:** Manifest entry now writes `dispatch_spec.subagent_type` (`scripts/run-codex-review.sh` lines 571–572).

**Result:** Added functionality beyond requested scope. `host`/`vendor`/`model` are in-scope per the DoD; `subagent_type` is explicitly T11's responsibility.

**Fix:** Remove `subagent_type` from the `emit_dispatch_manifest_entry` payload. The manifest entry should carry only `host`, `vendor`, and `model` per this task's scope.
