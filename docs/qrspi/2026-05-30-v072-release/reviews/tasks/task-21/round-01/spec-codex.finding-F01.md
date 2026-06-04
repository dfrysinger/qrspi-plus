---
reviewer: spec-codex
round: 1
finding_id: R1-F01
severity: medium
change_type: correctness
referenced_files:
  - tests/unit/test-dispatch-agent.bats
---

# F01 — Symlink-outside-repo test does not assert "before prompt emission"

Spec (task-21.md:50) requires the symlink-outside-repo regression to prove rejection happens **before any prompt file is emitted**. Current test (tests/unit/test-dispatch-agent.bats:1523-1538) asserts non-zero exit + diagnostic text only; does not assert absence of emitted prompt content/markers.

**Fix:** Add an assertion that the dispatch produces no prompt body / fenced markers / passes-through file content when symlink rejection fires.
