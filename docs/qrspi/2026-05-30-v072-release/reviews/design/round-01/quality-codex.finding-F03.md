---
finding_id: R1-F03
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/design.md:L2100-L2101
  - docs/qrspi/2026-05-30-v072-release/design.md:L2130-L2131
artifact: design
round: 1
reviewer: quality-codex
---

G27 contradicts itself on config migration semantics: D1 says `codex_reviews` is a hard-error unknown field with no alias, but acceptance later says dispatcher reads `second_reviewer` "(or its alias)." This ambiguity will produce divergent implementations and validator behavior.
