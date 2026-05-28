---
finding_id: R3-F01
severity: medium
change_type: scope
referenced_files: [docs/qrspi/2026-05-17-v07-release/structure.md:L85-L85]
artifact: structure
round: 3
reviewer: scope-codex
---

The Slice 5 file-map entry for `skills/reviewer-protocol/SKILL.md` crosses Structure's boundary by embedding the exact reviewer-protocol wording to add: `"inline-patch high findings AND correctness-medium findings; accept lows; do NOT blanket-merge quick-tier tasks."` Structure's OWNS/DEFERS contract explicitly defers actual reviewer-protocol body content to `skills/reviewer-protocol/SKILL.md`; Structure may declare the file being modified and the boundary-level responsibility, but not paste the literal prose that belongs in the protocol body.

Resolve by replacing the quoted sentence with a boundary-level responsibility, for example: add quick-tier guidance that distinguishes high and correctness-medium inline patching from low-finding acceptance and prohibits blanket quick-tier merges.
