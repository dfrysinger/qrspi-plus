---
finding_id: R4-F01
severity: high
change_type: scope
referenced_files: [/Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/agent-bravo/docs/qrspi/2026-05-17-v07-release/goals.md]
artifact: goals
round: 4
reviewer: quality-codex
---

The release scope is too large for a single QRSPI run. This goals file spans 18 goals across multiple distinct surfaces at once: cost-routing policy and mechanism (G1, G2, G5, G6), plan/context-process changes (G3, G4, G15, G16), reviewer/protocol fixes (G7, G8, G9, G10, G11, G18), repo/process hardening (G12, G13, G14), and repo CI (G17). That breadth makes the request hard to reason about as one coherent run and raises the risk that downstream Design and Plan either collapse unrelated work into one oversized implementation stream or spend effort re-partitioning the release before they can proceed. Fix: narrow this artifact to one bounded release theme or split it into multiple QRSPI runs, each with a smaller, internally coherent set of goals.
