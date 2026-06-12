---
artifact: design
reviewer_tag: quality-codex
finding_id: quality-codex-F02
change_type: correctness
---

# `upstream-paths.sh --step plan` acceptance omits the now-required `--artifact-dir`

## Location

design.md L263-264 (G4 acceptance bullets); CD-1 L13.

## Finding

R08 made CD-1 say `scripts/upstream-paths.sh` accepts `--artifact-dir <path>` for pipeline-mode-aware steps (Plan). G4 says Plan mode is determined by reading `<artifact-dir>/config.md` (L246-250). But G4 acceptance bullets still show:

- `scripts/upstream-paths.sh --step plan` against a full fixture (L263)
- same for quick fixture (L264)
- same for missing/malformed config.md (L265)

Without `--artifact-dir`, the script cannot read `config.md`. Acceptance examples are inconsistent with the CLI surface introduced in R08.

## Expected fix

Update G4 acceptance bullets (L263-265) to include `--artifact-dir <fixture-artifact-dir>` in the example invocations.
