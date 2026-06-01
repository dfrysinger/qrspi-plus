---
finding_id: R2-F01
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-30-v072-release/design.md:199-205, docs/qrspi/2026-05-30-v072-release/design.md:1245-1250, docs/qrspi/2026-05-30-v072-release/design.md:675-678]
artifact: design
round: 2
reviewer: quality-codex
---
CD-1's rename inventory still says `reviewer-protocol/codex-emission-override.md -> third-party-emission-override.md`, but later sections and the Component Map use `third-party-emission.md` as the target artifact. This leaves two conflicting canonical names for the same deliverable inside one design doc and risks implementation drift (wrong filename created/validated by one section, different filename expected by another). Normalize all references to the single final name.
