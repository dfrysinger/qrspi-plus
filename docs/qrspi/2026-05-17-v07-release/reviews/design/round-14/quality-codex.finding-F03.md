---
finding_id: R14-F03
severity: medium
change_type: correctness
referenced_files: [/Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/agent-bravo/docs/qrspi/2026-05-17-v07-release/design.md:L785-L795]
artifact: design
round: 14
reviewer: quality-codex
---

G17's CI contract says the four verification surfaces run on `ubuntu-latest`, but Option A for the bash-3.2 compatibility layer requires "macOS system bash (bash 3.2.57)." As written, downstream Plan can interpret Option A as valid within the stated Ubuntu-only workflow, which it is not unless the design also specifies how bash 3.2 is provisioned on Ubuntu. Fix by either constraining Option A to a separate macOS surface or removing it from the Ubuntu-only design and leaving only mechanisms that can actually execute inside the declared runner contract.
