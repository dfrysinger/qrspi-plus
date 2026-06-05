---
finding_id: F01
reviewer_tag: spec-codex
round: 1
severity: medium
change_type: correctness
referenced_files: [tests/unit/test-config-model-routing.bats, skills/using-qrspi/SKILL.md]
---

# spec-codex round-01 F01 — Missing test coverage for one of the two required back-pointer paragraphs

**Severity:** medium · **change_type:** correctness

**Finding (verbatim, gpt-5.3-codex chat-only):**

Missing test coverage for one required back-pointer paragraph.

- Spec requires BOTH fail-loud paragraphs to be asserted:
  - `tasks/task-17.md:40` ("Each post-Task-16 fail-loud paragraph points back…") and `:49` (test expectation: "each post-Task-16 fail-loud paragraph").
  - `design.md ## G23` (`:2016-2018`, `:2032`) requires both paragraphs (dispatcher-scope none-halt + missing-block) to carry the table-link and be covered.
- Implemented tests assert only ONE of the two paragraphs:
  - `tests/unit/test-config-model-routing.bats:777-783` covers the **Missing `model_routing:` block in `config.md`** section backlink.
  - There is NO corresponding assertion for the backlink sentence in the **`#### model_routing: block`** none-halt fail-loud paragraph (the paragraph + back-pointer EXIST in prod doc at `skills/using-qrspi/SKILL.md:466`, but no matching test assertion).

Everything else in the diff is aligned and narrow, but this missing assertion means DoD / test-expectation coverage is incomplete.

**Disposition:** PENDING (awaiting cross-family corroboration + verifier).
