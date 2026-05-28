---
finding_id: R7-F01
severity: medium
change_type: scope
referenced_files: [docs/qrspi/2026-05-17-v07-release/structure.md:L121-L124]
artifact: structure
round: 7
reviewer: scope-codex
---

The section-anchor index entry only creates the directory `docs/qrspi/2026-05-17-v07-release/section-anchor-index/` and explicitly defers concrete site-by-site selection to Plan. That violates Structure OWNS: structure.md owns concrete repo-relative paths for every file the project creates or modifies, with no directory placeholders or deferred file selection. Because the release is shipping initial index coverage, Structure needs to name the concrete initial `<artifact-basename>.anchors.json` files in the File Map instead of leaving the set to Plan.
