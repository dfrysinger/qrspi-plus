# stitching-audit.finding-F04

**reviewer_tag:** stitching-audit
**round:** 8
**artifact:** structure
**section:** ## File Map → Slice 1.2 + Slice 1.4
**severity:** medium
**change_type:** ordering-dependency-gap

## Finding

After the R7 rename-row correction, two File Map rows now visibly touch `dispatch-agent.sh` with incompatible ordering assumptions:

| Slice | File | Action |
|---|---|---|
| 1.2 | `scripts/dispatch-agent.sh` | Modify (L37) |
| 1.4 | `scripts/run-codex-review.sh` | Rename → `scripts/dispatch-agent.sh` (L60) |

The Slice 1.4 rename **creates** `dispatch-agent.sh` from the pre-existing `run-codex-review.sh`. The Slice 1.2 Modify assumes `dispatch-agent.sh` already exists to receive the modification (host/vendor/model metadata persistence, G20, G29).

If slices are implemented in numeric order (1.2 before 1.4), the Slice 1.2 Modify targets a file that does not yet exist under its final name. The file lives at `scripts/run-codex-review.sh` until Slice 1.4 renames it. Before the R7 fix both rows showed `dispatch-agent.sh` in the File column, so the conflict was hidden. After the fix, the rename source (`run-codex-review.sh`) is explicit, making the dependency visible.

## Impact

Plan decomposition that produces per-task specs from the File Map in slice order would generate a Slice 1.2 task for `dispatch-agent.sh` that fails at the "file exists" precondition. Alternatively, if a Plan implementer reorders execution to resolve this implicitly, there is no documented authority for that reordering decision — it is a silent assumption.

## Fix

Add an explicit ordering note to the Slice 1.2 entry for `scripts/dispatch-agent.sh`, or add a `depends_on: Slice 1.4 rename` annotation in the Slice 1.2 File Map table. Minimal wording:

> **Responsibility:** Add host/vendor/model metadata persistence into the dispatch manifest for later observability. **Implementation note: depends on Slice 1.4 rename of `run-codex-review.sh` → `dispatch-agent.sh`; apply this modification after the rename completes.** | G20, G29

Alternatively, restructure to move the Slice 1.2 Modify row after Slice 1.4 in the plan ordering, or add a slice-ordering constraint block (similar to the dependency entries in `todo_deps`).
