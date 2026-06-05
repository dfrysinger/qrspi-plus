---
finding_id: R1-F01
severity: high
change_type: correctness
artifact: code
round: 1
reviewer: spec-codex
model: gpt-5.3-codex
referenced_files:
  - tests/acceptance/v07-phase1/test-phase1-acceptance.bats#L1350-L1387
  - tasks/task-09.md#L42
  - tasks/task-09.md#L48
---

# Missing required acceptance coverage for end-to-end `actual_model` flow

**Spec requirement:** Acceptance must prove reviewer-frontmatter `actual_model` flows to verifier sidecars and `*.clean.md` carries the field (`tasks/task-09.md` lines 42, 48).

**Observed:** New acceptance tests only grep documentation text in `agents/qrspi-finding-verifier.md` and `skills/using-qrspi/SKILL.md` (`tests/acceptance/v07-phase1/test-phase1-acceptance.bats` lines 1350–1387). They do NOT exercise a finding/clean-sentinel artifact and assert emitted sidecar/clean frontmatter content.

**Result:** Test expectation is not actually verified — the tests only confirm the prose documents the contract, not that the contract is enforced end-to-end.

**Fix:** Add a fixture-driven acceptance test that:
1. Writes a finding file with `actual_model: <value>` in frontmatter
2. Writes the corresponding sidecar (manually or via verifier prose simulation)
3. Asserts the sidecar frontmatter contains `actual_model: <value>` (verbatim copy)
4. Repeats with omitted `actual_model:` → assert sidecar contains `actual_model: unknown`
5. Adds equivalent coverage for `*.clean.md` sentinel files
