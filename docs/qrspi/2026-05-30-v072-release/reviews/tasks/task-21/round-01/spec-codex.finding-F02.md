---
reviewer: spec-codex
round: 1
finding_id: R1-F02
severity: medium
change_type: correctness
referenced_files:
  - tests/unit/test-dispatch-agent.bats
---

# F02 — Canonicalization-failure test does not verify "no raw path read"

Spec (task-21.md:54) requires canonicalization-failure coverage to confirm fail-closed behavior **and that no raw path is read before checks pass**. Current test (tests/unit/test-dispatch-agent.bats:1542-1555) asserts status + diagnostic text only; does not assert absence of raw file content in output.

**Fix:** Strengthen canonicalization-failure tests to grep `output` for absence of file content / fence markers proving no read happened before guard.
