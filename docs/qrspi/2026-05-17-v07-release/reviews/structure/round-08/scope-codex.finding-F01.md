---
finding_id: R8-F01
severity: medium
change_type: scope
referenced_files: [docs/qrspi/2026-05-17-v07-release/structure.md:L240-L265]
artifact: structure
round: 8
reviewer: scope-codex
---

The `tests/helpers/skill-markdown.bash` interface section says the exact function names land in Plan/Implement, but then Structure defines the exact helper function names and argument lists (`extract_section`, `extract_and_grep`, `assert_section_contains`, `require_repo_root`). That crosses the boundary the artifact itself assigns to Plan/Implement: Structure should declare the behavioral surface the helper must provide, not lock the literal API names after saying those names are downstream-owned.

Fix by either removing the exact function names and keeping only capability-level requirements, or changing the ownership sentence if Structure is intentionally taking responsibility for the helper API names.
