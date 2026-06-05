---
finding_id: R1-F04
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/design.md:L1789-L1792
  - docs/qrspi/2026-05-30-v072-release/design.md:L194-L205
  - docs/qrspi/2026-05-30-v072-release/design.md:L1146-L1151
artifact: design
round: 1
reviewer: quality-codex
---

G20 deliverables still target pre-CD-1 transport artifacts (`codex-emission-override.md`, `run-codex-review.sh`) even though CD-1/G6 rename and restructure these surfaces (`third-party-emission*`, `dispatch-agent.sh`/`dispatch-companion.sh`). This is an internal architectural conflict that will misdirect implementation work.
