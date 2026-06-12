---
artifact: structure
reviewer_tag: quality-codex
finding_id: quality-codex-F01
change_type: correctness
severity: major
location: docs/qrspi/2026-06-04-v073-release/structure.md:119-123
---

## G8 consumer manifests are missing from the File Map

Design G8 names five consumer files that `tools/build-plugin.mjs` must stamp and the release commit must carry:

- `.claude-plugin/marketplace.json`
- `.claude-plugin/plugin.json`
- `.github/plugin/marketplace.json`
- `.github/plugin/plugin.json`
- `build/.claude-plugin/plugin.json`

Structure mentions them in the `VERSION` interface and diagram, but the File Map only lists `VERSION`, `tools/build-plugin.mjs`, the workflow, runbook, and tests. The manifest files need explicit File Map rows, likely `Modify` / regenerated build output, so Plan has concrete implementation targets and review can verify all design-named components are represented.
