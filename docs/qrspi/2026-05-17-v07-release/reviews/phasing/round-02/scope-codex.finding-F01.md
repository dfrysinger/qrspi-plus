---
finding_id: R2-F01
severity: high
change_type: scope
referenced_files: [/Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/agent-bravo/docs/qrspi/2026-05-17-v07-release/phasing.md:L29-L29, /Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/agent-bravo/docs/qrspi/2026-05-17-v07-release/phasing.md:L86-L90]
artifact: phasing
round: 2
reviewer: scope-codex
---

Slice 5 crosses Phasing's boundary into Plan, Parallelize, and Implement ownership. The slice text specifies concrete task-spec fields (`reference-gate`, `reference-artifact`, `ui-flag`, `lift-source`), wave-boundary behavior, Implement pause behavior, approval recording, and duplicate-agent constraints. The Phasing DEFERS list assigns task specs to Plan, dependency/wave decisions to Parallelize, and implementation/dispatch behavior to Implement and downstream skills. Keep the phasing artifact at the slice/phase level by naming the end-to-end deliverable and gate outcome, but defer the exact task-spec fields, wave mechanics, and Implement gate procedure to their owning artifacts.
