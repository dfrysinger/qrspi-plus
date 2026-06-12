---
finding_id: R2-F02
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-06-04-v073-release/design.md]
artifact: design
round: 2
reviewer: quality-claude
---

No consolidated test strategy section is present. The design quality check requires: "the design includes a testing approach; it names the test types (unit, integration, contract, e2e) and explains what's being tested at each level." The design scatters per-goal acceptance criteria throughout (bats unit tests for scripts, anchor-phrase grep tests for prose, synthetic fixture tests, and a "v0.7.3 self-host" meta-acceptance round) but never pulls these into a named test strategy section that identifies the test types and what each type is responsible for verifying.

A reader must mentally assemble the testing picture from nine separate Acceptance blocks. This makes it impossible to assess coverage gaps at a glance (e.g., is there an integration-level test that exercises the full dispatch-agent.sh → review-prep.sh → upstream-paths.sh chain end-to-end? Is the v0.7.3 self-host the only integration-level gate, or are there intermediate ones?).

Fix: add a `## Test Strategy` section (or `### Test Approach` under `## Cross-Goal Decisions`) that names test layers — at minimum: (1) bats unit tests (per-script/per-agent acceptance, anchor-phrase greps), (2) bats lint tests (structural invariants — test-name hygiene, marker-set correctness), (3) integration-level/self-host acceptance (v0.7.3 pipeline run as regression guard) — and explains what each layer verifies and what it explicitly does not verify.

