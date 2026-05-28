---
finding_id: F02
reviewer: goal-traceability-claude
round: 1
severity: minor
artifact: plan.md
section: "Task 8 — Target files"
goal_ids: [G7a]
---

# F02 — Task 8 creates `test-cache-mechanism-retired.bats` absent from structure.md Slice 7 File Map

## Summary

Task 8 lists `tests/unit/test-cache-mechanism-retired.bats (create)` in its target files, but `structure.md`'s Slice 7 File Map has no entry for this file. The structure names exactly 8 files for Slice 7 (4 deletes, 4 modifies, zero creates). The structure's Section Contracts covers created files only for Slices 6 and 8. This is a spec-to-design fidelity gap: a new file introduced by the plan is unaccounted for in the structure.

## Evidence

**Task 8 target files (plan.md):**

```
`scripts/g4-cache-probe.sh` (delete),
`docs/qrspi/2026-05-17-v07-release/spikes/g4-cache-probe.md` (delete),
`tests/unit/test-cache-control-capability-gate.bats` (delete),
`tests/unit/test-cache-hit-rate.bats` (delete),
`skills/using-qrspi/SKILL.md` (modify),
`scripts/run-third-party-llm.sh` (modify),
`tests/unit/test-run-third-party-llm.bats` (modify),
`tests/acceptance/v07-phase1/test-phase1-acceptance.bats` (modify),
`tests/unit/test-cache-mechanism-retired.bats` (create)   ← not in structure
```

**structure.md Slice 7 File Map** (complete reproduction):

| File | Action | Responsibility | Goal IDs |
|------|--------|----------------|----------|
| `scripts/g4-cache-probe.sh` | Delete | … | G7a |
| `docs/qrspi/2026-05-17-v07-release/spikes/g4-cache-probe.md` | Delete | … | G7a |
| `tests/unit/test-cache-control-capability-gate.bats` | Delete | … | G7a |
| `tests/unit/test-cache-hit-rate.bats` | Delete | … | G7a |
| `skills/using-qrspi/SKILL.md` | Modify | … | G7a |
| `scripts/run-third-party-llm.sh` | Modify | … | G7a |
| `tests/unit/test-run-third-party-llm.bats` | Modify | … | G7a |
| `tests/acceptance/v07-phase1/test-phase1-acceptance.bats` | Modify | … | G7a |

**Eight entries, zero creates.** `test-cache-mechanism-retired.bats` is absent.

**structure.md Section Contracts:** Covers created files for Slice 6 (`test-host-detection.bats`) and Slice 8 (`test-agent-frontmatter-no-model.bats`) with heading-level block definitions. No Section Contract exists for any Slice 7 created file.

**Task 8 description (plan.md):**

> A new structural test file asserts the post-retirement invariants (deleted files absent, patterns absent from modified files); these assertions fail RED against current state and pass GREEN after all deletions and removals land.

The intent is clear in the task description, but the structure that should have captured the file's boundary responsibility and section shape does not.

## Why this matters

The structure is the source for boundary responsibility and heading-level shape contracts for new files. Without a structure entry:
1. The implementer has no structure-authored boundary responsibility or `setup` block guidance for the new file — the plan's task description provides implementation intent, but the structure is the correct home for file-shape contracts.
2. Structure-to-design fidelity reviewers have no reference to verify the created file against.
3. The file's section contract (what `@test` blocks it must contain, isolation harness shape) is informal — specified only in the task description prose rather than in the structures' typed interface definition area.

In practice, the task description in plan.md is specific enough about what assertions the new file must contain, so the omission is minor and will not block implementation. However it is a spec-to-design fidelity gap that the structure reviewer should have caught before plan was authored.

## Recommended fix

**Option A (preferred):** Add `tests/unit/test-cache-mechanism-retired.bats` to structure.md's Slice 7 File Map with Action = Create and a one-line boundary responsibility statement. Add a Section Contracts entry for the file listing the `setup` block and expected `@test` blocks (deleted-files-absent assertions, patterns-absent-from-modified-files assertions).

**Option B (lightweight):** Acknowledge the gap in plan.md Task 8's description with a note that the structure omitted this file, and confirm that the structure's omission was an oversight (since DKR8 states "G7a has no design surface"). If the broader reviewer consensus is that mechanical-deletion tasks don't require structure entries, document that explicitly in the structure's introduction.

## Spec-to-design fidelity context

All other new files in the plan are accounted for in the structure:
- Task 6 creates `tests/unit/test-host-detection.bats` → present in structure Slice 6 File Map + Section Contracts ✓
- Task 9 creates `tests/unit/test-agent-frontmatter-no-model.bats` → present in structure Slice 8 File Map + Section Contracts ✓
- Task 8 creates `tests/unit/test-cache-mechanism-retired.bats` → **absent from structure** ✗
