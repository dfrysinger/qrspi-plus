---
finding_id: R5-F04
severity: low
change_type: correctness
referenced_files: [docs/qrspi/2026-06-04-v073-release/design.md:L193-L230]
artifact: design
round: 5
reviewer: quality-claude
---

G3 Solution enumerates 5 coordinated changes with letter labels (G3.a, G3.b, G3.b-safety-net, G3.e, G3.d). Two inconsistencies:
1. G3.c is absent (gap between G3.b and G3.e).
2. G3.d appears after G3.e (out of alphabetical order).

Fix: either explain the non-sequential lettering (e.g., "letters reflect goals.md sub-requirement IDs") or re-label sequentially.
