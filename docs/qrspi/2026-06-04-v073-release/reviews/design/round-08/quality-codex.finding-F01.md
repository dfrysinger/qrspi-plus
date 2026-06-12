---
artifact: design
reviewer_tag: quality-codex
finding_id: quality-codex-F01
change_type: correctness
---

# CD-1 / G4 define an inconsistent `upstream-paths.sh` interface

## Location

`design.md` lines 13, 21, 246-250, 263-265

## Finding

CD-1 says `scripts/upstream-paths.sh` accepts only `--step <step>` (line 13) and is context-free (line 21). G4 says the Plan branch reads `pipeline:` from `<artifact-dir>/config.md` (line 246) and lines 263-265 test `upstream-paths.sh --step plan` against a fixture artifact-dir without specifying how artifact-dir is passed. Implementers cannot tell whether the script is context-free or artifact-dir-aware.

## Expected fix

Reconcile the contract: either add `--artifact-dir <path>` to `upstream-paths.sh` (and update CD-1) or move pipeline-mode branching out of `upstream-paths.sh` into the orchestrator / `review-prep.sh` layer.
