---
status: approved
task: 17
phase: 1
pipeline: full
goal_ids: [G23]
task_type: code
model: opus
---

# Task 17: G23 validation table covers `model_routing` and cross-links fail-loud paragraphs

- **Target files:** `skills/using-qrspi/SKILL.md` (modify), `tests/unit/test-config-model-routing.bats` (modify)
- **Dependencies:** Task 16. **Blocks:** none.
- **LOC estimate:** ~80

**Overview**

Add the missing `model_routing:` validation-table row and bidirectional fail-loud paragraph cross-links so config authors see the required validated block before dispatch. Keep the change narrow: one documentation row, two one-sentence pointers, and the existing bats coverage for that contract. (Why: see goals.md ### G23. Approach: see design.md ## G23.)

**Scope**

- **In:**
  - Add exactly one `model_routing:` row to `skills/using-qrspi/SKILL.md` under `### Fields that affect pipeline behavior (must be validated)`.
  - Describe the row as a required top-level block using the post-Task-16 per-vendor five-tier map shape, and point readers to the schema-definition heading by literal heading text.
  - Point the row to the missing-`model_routing:` fail-loud enforcement paragraph by literal heading text, not by line number.
  - Append one-sentence back-pointers from each post-Task-16 fail-loud paragraph to `### Fields that affect pipeline behavior (must be validated)`.
  - Add/adjust bats assertions in `tests/unit/test-config-model-routing.bats` that pin the validation-table row and the missing-block fail-loud behavior.

- **Out:**
  - Defining the `model_routing:` schema, dispatch chain, per-vendor tier resolution, or `none`-halt semantics — Task 16 owns.
  - Adding the top-level dispatch-routing fail-loud invariant paragraph — dropped per design.md ## G25 (absorbed by CD-1; no separate v0.7.2 task ships under G25).
  - Replacing the validation table with a generated index, adding a canonical-source file, adding a validator framework, or adding rows for other config blocks (`providers:`, `trusted_path:`, `validators:`) — explicit non-goals in design.md ## G23.

**Definition of done**

- `skills/using-qrspi/SKILL.md` contains exactly one `model_routing:` row in the validation table.
- The row names the required per-vendor five-tier map shape and cross-references the schema-definition heading by literal heading text.
- The row cross-references the missing-`model_routing:` fail-loud enforcement paragraph by literal heading text.
- Each post-Task-16 fail-loud paragraph points back to `### Fields that affect pipeline behavior (must be validated)` by literal heading text.
- A config missing `model_routing:` still fails loudly through the existing config-routing test path; no silent default or table-only documentation pass is introduced.
- The production-doc diff remains narrow: one table row plus the required one-sentence fail-loud paragraph pointers, with no generated index, new canonical-source file, or extra validator framework.

**Test expectations**

- Bats assertion verifies the `skills/using-qrspi/SKILL.md` validation table contains exactly one `model_routing:` row.
- Bats assertion verifies the row identifies the required per-vendor five-tier map shape and points to the schema-definition heading by literal heading text.
- Bats assertion verifies the row points to the missing-`model_routing:` fail-loud enforcement paragraph by literal heading text, not by line number.
- Bats assertion verifies each post-Task-16 fail-loud paragraph points back to `### Fields that affect pipeline behavior (must be validated)` by literal heading text.
- Existing config-routing missing-block test path verifies a config missing `model_routing:` fails loudly.

**References**

- goals.md ### G23 — problem framing for validation-table discoverability and missing bidirectional links.
- design.md ## G23 — exact validation-table row contract, cross-link annotations, non-goals, and acceptance criteria.
- structure.md ### `skills/using-qrspi/SKILL.md` → Goal IDs {G3, G22, G23, G24, G25, G27, CD-2} — production documentation edit surface for the validation-table row and cross-link annotations.
- structure.md ### `tests/unit/test-config-model-routing.bats` — executable coverage for the schema shape, missing-block validation error, `none`-tier halt smoke test, and G23 validation-table row/cross-link verification.
