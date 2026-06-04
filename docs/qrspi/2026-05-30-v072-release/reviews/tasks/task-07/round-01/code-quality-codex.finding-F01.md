---
reviewer_tag: code-quality-codex
round: 1
finding_id: F01
severity: high
change_type: correctness
referenced_files:
  - tests/unit/test-verifier-agent-file.bats:156
  - tests/unit/test-verifier-agent-file.bats:158
  - tests/unit/test-verifier-agent-file.bats:220
  - tests/unit/test-verifier-agent-file.bats:222
---

ID hygiene violation: QRSPI-internal token `G14` is newly introduced in test-surface strings/comments (e.g., test names and section headers). Per the strict rule, these IDs are forbidden outside `docs/qrspi/` on comments/test names/fixtures. Replace `G14`-prefixed labels with descriptive, non-ID wording.

[Materialized from chat-only response by gpt-5.3-codex.]
