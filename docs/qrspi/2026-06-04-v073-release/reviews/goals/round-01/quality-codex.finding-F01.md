---
finding_id: R1-F01
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-06-04-v073-release/goals.md:L52-L56]
artifact: goals
round: 1
reviewer: quality-codex
---

G2's "What we know so far" includes a locked solution decision ("sweep all `[Tnn]` prefixes; do NOT bless them") rather than framing the solution as candidate options for Design to weigh. This violates the goals contract for this section. Fix by rewriting that bullet to keep the problem signal and rationale but present the sweep approach as a candidate (or candidate set) that Design evaluates, not a pre-committed implementation decision.
