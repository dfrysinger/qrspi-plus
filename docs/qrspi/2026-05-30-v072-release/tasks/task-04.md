---
status: approved
task: 4
phase: 1
pipeline: full
goal_ids: [G8]
task_type: code
model: opus
---

# Task 04: G8 reviewer frontmatter emits `change_type` not `category`

- **Target files:** skills/reviewer-protocol/SKILL.md (modify), tests/unit/test-change-type-partition.bats (modify)
- **Dependencies:** Task 03. **Blocks:** T05 (G13 enum drift hardening consumes the missing-field behavior and shared test surface introduced here).
- **LOC estimate:** ~90

**Overview**

Centralize `change_type:` as the required reviewer finding-file frontmatter key in the reviewer protocol, then pin the field-name contract with regression coverage so `category:` cannot be accepted or silently default-routed. This protects verifier fan-in, scope routing, and apply-fix behavior from the G8 field-name drift while leaving enum hardening to the dependent task. (Why: see goals.md ### G8. Approach: see design.md ## G8 and design.md ### CD-4.)

**Scope**

- **In:**
  - Update `skills/reviewer-protocol/SKILL.md` so the required finding-file frontmatter schema names `change_type:` and does not present `category:` as an allowed synonym.
  - Add regression coverage in `tests/unit/test-change-type-partition.bats` for a finding file that has `category:` but no `change_type:`, asserting it is malformed with a missing-field diagnostic rather than accepted or silently routed.
  - Add/keep coverage in `tests/unit/test-change-type-partition.bats` for a well-formed finding with `change_type:`, asserting acceptance and routing by that field name.
  - Audit the touched protocol examples and test fixtures so valid finding-frontmatter examples do not use `category:`.

- **Out:**
  - Out-of-enum `change_type:` validation, canonical enum drift hardening, and script/protocol enum lock-step — T05 owns.
  - Creating or expanding `scripts/verifier-fan-in.sh` beyond the missing-field behavior exercised by this task — T05 owns the dependent script-side enum hardening surface.
  - Editing individual reviewer agent bodies or transport-specific emission files beyond the central reviewer-protocol contract — outside this task's target-file set.

**Definition of done**

- `skills/reviewer-protocol/SKILL.md` documents `change_type:` as the required finding-file frontmatter key for reviewer findings.
- `skills/reviewer-protocol/SKILL.md` does not describe `category:` as an accepted alias or synonym for `change_type:`.
- `tests/unit/test-change-type-partition.bats` contains a failing-first fixture/assertion where `category:` without `change_type:` produces a missing-field diagnostic and is not accepted, silently kept, silently dropped, or default-routed.
- `tests/unit/test-change-type-partition.bats` asserts a well-formed finding with `change_type:` is accepted and routed by the `change_type:` field name.
- Repository search over reviewer-output schema examples and test fixtures in the touched files finds no valid finding-frontmatter example using `category:`.

**Test expectations**

- Run the targeted `tests/unit/test-change-type-partition.bats` test and confirm the missing-`change_type:` / legacy-`category:` fixture fails loudly with the expected missing-field diagnostic.
- Run the same targeted test and confirm the well-formed `change_type:` fixture is accepted and routed by that field name.
- Grep `skills/reviewer-protocol/SKILL.md` for the required `change_type:` schema wording and verify no nearby protocol wording permits `category:` as an alias.
- Grep `skills/reviewer-protocol/SKILL.md` and `tests/unit/test-change-type-partition.bats` for valid finding-frontmatter examples using `category:`; the audit must find none.

**References**

- goals.md ### G8 — problem framing for reviewer findings drifting from schema-required `change_type:` to free-text `category:`.
- design.md ## G8 — CD-4 resolution summary: centralize `change_type:` in reviewer protocol and halt with a named cause when missing.
- design.md ### CD-4 — verifier-fan-in component shape, missing-`change_type:` loud-failure path, and G8 acceptance mapping.
- structure.md ### `skills/reviewer-protocol/SKILL.md` — Slice 1.1 per-file block for centralizing the `change_type:` field name in the reviewer protocol.
- structure.md ### `tests/unit/test-change-type-partition.bats` — per-file block for pinning the `change_type:` field-name requirement and loud failure on missing/out-of-contract values.
