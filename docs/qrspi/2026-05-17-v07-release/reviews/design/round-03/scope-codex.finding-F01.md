---
finding_id: R3-F01
severity: medium
change_type: scope
referenced_files: [docs/qrspi/2026-05-17-v07-release/design.md:L614-L619]
artifact: design
round: 3
reviewer: scope-codex
---

The G14 helper section defines the exact helper function surface with argument-shaped signatures (`extract_section <file> <section_heading>`, `grep_in_section <file> <section_heading> <pattern>`, and `assert_section_contains <file> <section_heading> <pattern>`). Design owns the architectural decision to introduce a shared helper and the behavior it should provide, but the Design DEFERS contract sends full function signatures and implementation surfaces downstream to Structure / Plan / Implement. Resolve by keeping the helper responsibilities at the behavior/contract level and deferring the exact function names and parameter shapes to downstream artifacts.
