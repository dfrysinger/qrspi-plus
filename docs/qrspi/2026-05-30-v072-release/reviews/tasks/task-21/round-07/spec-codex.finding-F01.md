---
finding_id: F01
severity: LOW
change_type: scope
referenced_files:
  - tasks/task-21.md:24-29
  - scripts/dispatch-agent.sh:635-641
  - scripts/dispatch-agent.sh:762-763
  - scripts/dispatch-agent.sh:962-965
  - scripts/dispatch-companion.sh:547-559
  - scripts/dispatch-companion.sh:625-655
  - tests/unit/test-dispatch-agent.bats:1718-1972
reviewer_tag: spec-codex
round: 7
---

Scope exceeds task-21 spec. The spec explicitly scopes enforcement to dispatch-agent prompt-ingested families (--subject-code, --artifact-body, --companion, --diff-file) plus agent file, and companion audit/doc for raw-path surface. Implementation additionally introduces new hardening behaviors not requested in task-21 (batch --agents tag allowlist, skill-path boundary enforcement, batch job_id validation, companion launch/await tag+round_dir record validation/canonicalization) with substantial extra tests. This is over-implementation relative to the task definition.
