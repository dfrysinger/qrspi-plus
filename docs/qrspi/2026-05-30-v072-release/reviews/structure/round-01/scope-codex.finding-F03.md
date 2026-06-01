---
finding_id: R1-F03
severity: low
change_type: correctness
artifact: structure
referenced_files: [docs/qrspi/2026-05-30-v072-release/structure.md]
round: 1
reviewer: scope-codex
---

Placeholder content remains in interface contracts in the Interfaces section
(structure.md L222-L233 carries literal `<boundary rule prose>` and `- ...` inside
the Structure altitude-boundary snippet shape; L307-L328 carries `/abs/path/...`
shape placeholders inside the dispatch manifest schema illustration), which
conflicts with the no-placeholder boundary expectation for structure-level
contracts. Replace placeholders with concrete contract shapes (a one-line schema
description of what the snippet body must contain; concrete `<example>` paths
labeled as example rather than `...` stubs) so downstream agents are not forced to
infer missing structure.

Originally hand-persisted from chat-only Codex dispatch (per qrspi-plus issue #288).
