---
finding_id: R2-F01
severity: high
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/structure.md:L114-L116, docs/qrspi/2026-05-17-v07-release/design.md:L641-L647]
artifact: structure
round: 2
reviewer: quality-codex
---

Slice 8's file map says `skills/implementer-protocol/SKILL.md` should codify the three commit-hygiene invariants while preserving the "literal command sequence." That conflicts with the approved G12 design: the staging-before-scratch invariant requires staging to complete before `.qrspi-commit-msg.txt` is written, and Design explicitly leaves the line-by-line procedure to Plan/Implement so it can realize those invariants. Preserving the existing literal command sequence would keep the old bug shape, where the scratch file can exist during staging.

Fix: change the structure responsibility for `skills/implementer-protocol/SKILL.md` to require updating the literal commit procedure to satisfy the three invariants, especially staging-before-scratch, while preserving only the higher-level state-machine behavior and file-based commit-message convention.
