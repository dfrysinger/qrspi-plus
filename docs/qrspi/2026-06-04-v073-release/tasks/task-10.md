---
status: approved
task: 10
phase: 1
pipeline: full
goal_ids: [G1]
task_type: tdd
tier: high
---

# Task 10: Create tests/unit/test-finding-verifier-id-hygiene-grounding.bats

- **Target files:** `tests/unit/test-finding-verifier-id-hygiene-grounding.bats` (Create)
- **Dependencies:** T09, T01
- **LOC estimate:** ~70
- **Description:** A bats test drives a synthetic verifier dispatch against a fixture finding whose subject is a `[Tnn]` token in a bats test name; the test inspects the resulting sidecar and asserts the score is ≥ 70 against the post-T09 rubric. A regression-direction sub-test drives the same fixture finding against a v0.7.2-baseline rubric stub (one that lacks the T09 clause) and asserts the score is < 70 — proving G1 actually moves the score across the correctness floor.
- **Test expectations:**
  - Dispatch order: test-writer first, implementer second (RED-verification gate between).
  - A synthetic verifier dispatch on a `[Tnn]` fixture finding "scores ≥ 70" against `skills/implementer-protocol/SKILL.md` § Hygiene contract via the post-T09 rubric (G1 Acceptance bullet 3) — read by inspecting the sidecar at `<finding_file_path>` with `.md` → `.score.md` (canonical sidecar path per `agents/qrspi-finding-verifier.md` § Write `<sidecar_path>`) and extracting the integer value of the `score:` YAML frontmatter field (range 0–100, schema per the same agent file).
  - The same fixture finding "scored under the v0.7.2 verifier scores < 70" — regression-direction guard against a v0.7.2-baseline rubric stub (G1 Acceptance bullet 4).
  - The fixture finding's grounding section in the sidecar names `skills/implementer-protocol/SKILL.md` § Hygiene contract as the authority cited (not `CONTRIBUTING.md`, not improvised).
  - The fixture forbidden token is carried via an inline `# bats lint:no-id-hygiene` carve-out marker so T12's permanent lint does not false-positive against this test's own fixture string.
