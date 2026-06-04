---
reviewer_tag: code-quality-codex
round: 1
finding_id: F02
severity: medium
change_type: clarity
referenced_files:
  - tests/unit/test-verifier-agent-file.bats:198
  - tests/unit/test-verifier-agent-file.bats:206
  - tests/unit/test-verifier-agent-file.bats:227
  - tests/unit/test-verifier-agent-file.bats:269
  - tests/unit/test-verifier-agent-file.bats:275
  - tests/unit/test-verifier-agent-file.bats:291
---

The new tests duplicate the same `awk ... | grep ...` extraction pattern many times, which makes maintenance harder and increases update risk when section boundaries change. Extract shared helpers (e.g., `verifier_body()` and `informational_section()`) to keep assertions focused and reduce repetition.

[Materialized from chat-only response by gpt-5.3-codex.]
