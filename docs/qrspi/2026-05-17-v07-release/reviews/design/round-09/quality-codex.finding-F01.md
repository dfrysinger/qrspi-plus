---
finding_id: R9-F01
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/design.md:L683-L700]
artifact: design
round: 9
reviewer: quality-codex
---

The G15 research summary says Replan promotes existing Formal goals that already have “IDs and criteria,” but the recommendation immediately defines Formal goals as `id:`, `type:`, and the three Goals subsections, then explicitly says Replan does not author acceptance criteria because those belong in Plan’s Test Expectations. That “criteria” wording contradicts the strip-from-goals contract and can mislead downstream Phasing/Plan agents into expecting acceptance criteria in `future-goals.md` or `goals.md`.

Fix: rewrite the G15 “What research found” sentence to say Replan promotes existing Formal goals that already have IDs, types, and the required Goals problem-framing subsections, without mentioning criteria.
