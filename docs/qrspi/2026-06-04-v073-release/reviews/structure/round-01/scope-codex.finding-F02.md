---
finding_id: R1-F02
artifact: structure
round: 1
reviewer: scope-codex
severity: medium
change_type: scope
referenced_files:
  - docs/qrspi/2026-06-04-v073-release/structure.md:L147-L416
---

The `## Interfaces` section drifts below structure altitude into implementation-body detail. The bash code blocks specify command syntax, internal sequences, shell commands, regexes, exit-code numerology, diagnostics, and sidecar serialization details. Structure owns module-boundary contracts and architectural stitching, but implementation mechanics belong downstream to Plan/Implement. Replace these blocks with structural interface summaries: component exports, consumers, inputs/outputs, and read/write boundaries.
