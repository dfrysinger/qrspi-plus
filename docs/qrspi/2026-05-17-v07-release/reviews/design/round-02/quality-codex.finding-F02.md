---
finding_id: R2-F02
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/design.md:L651-L663]
artifact: design
round: 2
reviewer: quality-codex
---

The G15 Replan contract contradicts its own Formal-vs-Idea schema. Lines 651-654 define a Formal goal as requiring all three of `id:`, `type:`, and acceptance criteria, and lines 663 says missing any of those fields classifies the entry as an Idea. But line 658 then says Replan promotes Formal goals with only an `id:` and acceptance criteria, omitting `type:`. This would let downstream agents implement a weaker promotion rule than the one the design just defined. Fix the contract bullet to require all three fields: `id:`, `type:`, and acceptance criteria.
