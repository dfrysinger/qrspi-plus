---
artifact: structure
reviewer_tag: quality-codex
finding_id: quality-codex-F02
change_type: correctness
severity: major
location: docs/qrspi/2026-06-04-v073-release/structure.md:412-499
---

## Architecture diagram omits major design surfaces

The unified architecture diagram is present, but it does not stitch together all major per-solution and cross-cutting design blocks. It covers CD-1/CD-2/G1/G3/G5/G6/G7/G8 runtime flows, but omits the G2 ID-hygiene sweep/lint/self-check surface, CD-3 R8 prompt-rule surface, and the G9 shared-snippet / references / footprint-measurement architecture.

Because Structure expects the unified diagram to provide a release-wide overview, add these omitted component groups or explicitly show them as non-runtime/static-analysis branches so the diagram matches the File Map and design.
