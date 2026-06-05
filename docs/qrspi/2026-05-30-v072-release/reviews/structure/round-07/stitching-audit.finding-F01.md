---
finding_id: R7-F01
reviewer_tag: stitching-audit
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/structure.md
artifact: structure
---

## Summary

Two test file names in Slice 1.4 (lines 97–98) still carry pre-rename script references after the R6 fix changed the script rows to Rename. The file names were not updated in lock-step with the corresponding script renames.

## Detail

The R6 fix delta changed three Slice 1.4 script rows from `Create` to `Rename → … (from scripts/run-codex-review.sh / run-third-party-llm.sh / codex-finding-splitter.sh)`. The rename inventory in design.md CD-1 (lines 198–200) is fully reflected in the script rows. However, two test rows in the same slice still use names derived from the pre-rename scripts:

| Line | File | Stale reference |
|---|---|---|
| 97 | `tests/unit/test-run-codex-review.bats` | `run-codex-review` → script renamed to `dispatch-agent.sh` |
| 98 | `tests/unit/test-codex-review-codex-availability.bats` | `codex-review` → availability probing now belongs to `dispatch-agent.sh` via `_host-detect.sh` |

These test files test behavior that lives in, or is delegated by, the renamed script. At Implement time the test filenames would be authored as shown, producing a naming asymmetry between the tested script (`dispatch-agent.sh`, `_host-detect.sh`) and the test that pins it (`test-run-codex-review.bats`, `test-codex-review-codex-availability.bats`). This makes grep-based post-mortem ("which test covers dispatch-agent.sh?") fail silently.

Post-rename names consistent with the rest of the slice would be, e.g.:
- `tests/unit/test-dispatch-agent-sanctioned-paths.bats` (G16 — path-guard)
- `tests/unit/test-dispatch-agent-availability.bats` (G27 — host-aware availability)

## Fix

Update the two Slice 1.4 File Map rows to the post-rename test file names and propagate the rename throughout any CI configuration or other structure.md references that name these files explicitly.
