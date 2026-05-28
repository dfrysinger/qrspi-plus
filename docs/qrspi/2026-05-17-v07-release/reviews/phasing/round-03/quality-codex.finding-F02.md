---
finding_id: R3-F02
severity: high
change_type: correctness
referenced_files: [/Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/agent-bravo/docs/qrspi/2026-05-17-v07-release/phasing.md:L27-L29, /Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/agent-bravo/docs/qrspi/2026-05-17-v07-release/phasing.md:L87-L89, /Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/agent-bravo/docs/qrspi/2026-05-17-v07-release/design.md]
artifact: phasing
round: 3
reviewer: quality-codex
---

Slice 5 under-specifies G10's load-bearing behavior, so Phase 1 can appear complete without proving the actual reference-gate contract. In `phasing.md`, Slice 5 and its gate criteria only require (a) surfacing the reference in renderable form and (b) having the visual-fidelity reviewer participate with sibling-awareness. But the approved design for G10 is stronger: a `reference_gate: true` task must become a wave boundary, dependent tasks must not dispatch until explicit approval, and that approval must be recorded. Those blocking/recording semantics are what prevent bad references from propagating downstream; omitting them from the slice and gate criteria weakens the phase contract to a UI/display check. Fix by adding the dependency-block and approval-record conditions to Slice 5's success criteria so the phase cannot pass without exercising the real gate.
