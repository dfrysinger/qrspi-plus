---
finding_id: R2-F01
severity: medium
change_type: scope
referenced_files: [docs/qrspi/2026-05-30-v072-release/design.md:720-736]
artifact: design
round: 2
reviewer: scope-codex
---
The new `## Test Strategy` section crosses from design-level test taxonomy into Plan/Implement test specification detail. OWNS allows test **types/layers/frameworks**, but this block prescribes concrete assertion mechanics and layout/spec obligations (e.g., exact negative-assertion forms, "one bats file per script," specific fixture-per-path expectations, and named per-agent contract checks). These are deferred surfaces under the locked contract ("full assertion text" and "per-test-file layout" are DEFERS). Keep this section at taxonomy/coverage-boundary altitude and move concrete assertion/layout requirements to Plan/Implement.
