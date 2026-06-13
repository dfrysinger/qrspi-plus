---
status: approved
task: 18
phase: 1
pipeline: full
goal_ids: [G3]
task_type: tdd
tier: low
---

# Task 18: Create tests/lint/test-design-absorption-marker-set.bats structural lint

- **Target files:** `tests/lint/test-design-absorption-marker-set.bats` (Create)
- **Dependencies:** T02
- **LOC estimate:** ~30
- **Description:** A structural lint scans every `design.md` under `docs/qrspi/**/` and asserts any absorption-shaped marker text matches one of the 4 enumerated patterns (heading-suffix, block-internal explicit non-goal, acceptance-criterion no-separate-task, free-prose deferred-to). Drift surfaces as a lint failure on the design.md PR. The lint runs in CI on every PR; new absorption marker forms cannot land without a paired design-decision update to the enumerated set.
- **Test expectations:**
  - Dispatch order: test-writer first, implementer second (RED-verification gate between).
  - The lint "passes against the v0.7.3 design.md (this very document — meta-acceptance)" (G3 Acceptance bullet 2, first half).
  - The lint "fails against a fixture design.md containing a non-enumerated marker form" (G3 Acceptance bullet 2, second half).
  - The lint's failure output names the offending file, line, and the non-enumerated marker text (named-diagnostic discipline).
  - A design.md with zero absorption markers passes the lint silently.
- **Author Note (defer-to-upstream):** test-coverage-codex R9-F02 requests T18's meta-acceptance bullet ("passes against the v0.7.3 design.md") be replaced (or augmented) with a pinned-snapshot fixture for deterministic future verification; the meta-acceptance shape is contracted by design.md § G3 Acceptance bullet 2 first half ("passes against the v0.7.3 design.md — meta-acceptance"). The meta-acceptance is the load-bearing G3 contract — it locks the lint against the actual artifact being delivered. Adding a pinned-snapshot fixture in addition is a structure.md G3 fourth-bullet expansion. Re-opening requires a Design-phase (or Structure-phase) amendment per `skills/plan/owns-defers.md` § Upstream-contract deferrals.
