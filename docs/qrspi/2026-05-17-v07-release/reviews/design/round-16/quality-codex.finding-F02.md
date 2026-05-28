---
finding_id: R16-F02
severity: high
change_type: correctness
referenced_files:
  - /Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/agent-bravo/docs/qrspi/2026-05-17-v07-release/design.md:L797-L800
  - /Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/agent-bravo/docs/qrspi/2026-05-17-v07-release/design.md:L819-L823
  - /Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/agent-bravo/docs/qrspi/2026-05-17-v07-release/design.md:L837-L843
artifact: design
round: 16
reviewer: quality-codex
---

The CI design says Option B alone, a targeted grep ban-list, is sufficient to satisfy the bash-3.2 compatibility layer. That is not a real 3.2 gate; it only catches the specific constructs on the list and will silently miss unsupported syntax that is not enumerated yet. Because the same section also promises that this layer is a “true bash-3.2 gate,” the contract is internally inconsistent: Plan could legally choose grep-only and still ship scripts that fail on real bash 3.2. Fix: require an actual bash-3.2 parser/execution check (Option A or an equivalent real 3.2 interpreter gate) as the load-bearing compatibility verification, and keep the grep ban-list only as a supplemental fast-fail aid.
