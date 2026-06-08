---
finding_id: R3-F01
severity: high
change_type: correctness
referenced_files: ["docs/qrspi/2026-06-04-v073-release/goals.md:L189"]
artifact: goals
round: 3
reviewer: quality-claude
---

G9 fails the Required-presence check: the `#### Problem` subsection is absent. In its place is `#### What's wrong` (L189), which is not the canonical subsection name. Every goal must carry exactly the three subsections `Problem`, `Why we care`, and `What we know so far` — non-canonical naming does not satisfy the requirement even if the content is equivalent, because downstream agents (plan-author, design reviewer, scope tagger) key on the exact heading text.

Fix: rename `#### What's wrong` to `#### Problem`.
