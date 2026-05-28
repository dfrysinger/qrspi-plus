---
finding_id: R1-F02
severity: medium
change_type: scope
referenced_files: [/Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/agent-bravo/docs/qrspi/2026-05-17-v07-release/phasing.md:L45-L84]
artifact: phasing
round: 1
reviewer: scope-codex
---

The replan-gate criteria have drifted into Plan/Test-owned task specification detail: exact command invocations, fixture names, task spec fields, test file paths, expected test classifications, generated task-file counts, and per-task acceptance expectations. Phasing owns explicit replan-gate criteria, but the boundary rule defers task specs, ordered task lists, per-task test expectations, file paths, and implementation prose to Plan/Structure/Implement. Fix by rewriting these bullets as phase-level gate outcomes that are demonstrable without prescribing task-level implementation or test inventory details.
