---
finding_id: R3-F02
severity: medium
change_type: scope
referenced_files: [docs/qrspi/2026-06-04-v073-release/design.md]
artifact: design
round: 3
reviewer: scope-codex
---

Boundary drift: several sections prescribe **implementation-level test mechanics and command specifics** (exact lint/test filenames, concrete grep/awk command patterns, and detailed script invocation behavior) beyond “rough test-pairing shape.” Design OWNS acceptance criteria examples, but DEFERS full test implementation/mechanics.  
Fix: keep acceptance intent and test-shape expectations at design altitude; move exact test file wiring, regex/command details, and concrete script-level mechanics to plan/implement artifacts.
