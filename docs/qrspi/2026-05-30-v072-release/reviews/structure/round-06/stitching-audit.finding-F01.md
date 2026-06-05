---
finding_id: R6-SA-F01
reviewer_tag: stitching-audit
artifact: structure
severity: high
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/structure.md
  - docs/qrspi/2026-05-30-v072-release/design.md
---

# G31 integration footprint incomplete — `design/SKILL.md` row missing G31, three agents' `skills:` preload additions unassigned

## What

Design.md G31 § Distribution Table requires wiring five surfaces into the prompt-prose detection + rules architecture. Structure.md captures two of the five; three are unassigned.

### Gap 1 — `skills/design/SKILL.md` has no G31 row

Design.md G31 Consumer #3 specifies:

> `skills/design/SKILL.md` at the authoring step contains `!cat skills/_shared/prompt-prose-detection.md` + `!cat skills/_shared/prompt-prose-writer-addition.md`.

Structure.md has two rows for `skills/design/SKILL.md`:

| Slice | Responsibility | Goal IDs |
|---|---|---|
| 1.4 | Replace inline reviewer-dispatch prose with a thin preamble plus shared include. | G3 |
| 1.5 | Author richer per-goal design blocks, simple-language dialog conduct, and direct-to-artifact drafting. | G1, G30, G33 |

Neither row mentions G31. The prompt-prose-aware authoring step required by G31 Consumer #3 is not assigned to any row that touches `skills/design/SKILL.md`.

### Gap 2 — Three agents' G31 `skills:` frontmatter preloads are unassigned

Design.md G31 Distribution Table requires five agents to receive `skills:` frontmatter preload additions:

| # | Agent | Preload | Coverage in structure.md |
|---|---|---|---|
| 4 | `agents/qrspi-implementer-lightweight.md` | `prompt-prose-writer` | G22 sweep only ("no behavioral logic") |
| 5 | `agents/qrspi-code-quality-reviewer.md` | `prompt-prose-reviewer` | Slice 1.4 row, G22 only |
| 6 | `agents/qrspi-design-reviewer.md` | `prompt-prose-reviewer` + Addition D | Slice 1.5, **G31 present** ✓ |
| 7 | `agents/qrspi-plan-reviewer.md` | `prompt-prose-reviewer` | Slice 1.5, **G31 present** ✓ |
| 8 | `agents/qrspi-plan-spec-reviewer.md` | `prompt-prose-reviewer` | G22 sweep only ("no behavioral logic") |

Agents #4, #5, and #8 have no structure.md row carrying G31. The G22 sweep row explicitly states "no behavioral logic" — it covers only `tier:` frontmatter migration and `DISPATCH_FILE` first-action additions, not `skills:` list additions.

## Why it matters

G31's stated outcome is: "every QRSPI run that touches prompt prose has the prompt-prose subject to the canonical prompt-design rules at every gate — authoring, classification, and review — regardless of the project." Three of five required enforcement points are dropped:

1. **`qrspi-implementer-lightweight.md` without `prompt-prose-writer`**: lightweight tasks that author prompt prose will not receive detection + writer-addition at dispatch time. The TDD-exclusion rationale ("prompt prose never lands on the TDD path") relies on the lightweight implementer correctly applying R1-R7 before drafting; without the preload, that guarantee is absent.

2. **`qrspi-code-quality-reviewer.md` without `prompt-prose-reviewer`**: quality review on tasks whose diff contains prompt prose will not apply G31's reviewer-side rules. This is the high-volume reviewer dispatched on every implement-phase task, making it the most impactful omission.

3. **`qrspi-plan-spec-reviewer.md` without `prompt-prose-reviewer`**: plan-spec review on tasks classifying prompt prose as lightweight misses G31 reviewer coverage.

The `skills/design/SKILL.md` gap (Gap 1) means the Design phase skill will not include the prompt-prose authoring `!cat` inclusions, undermining G31's coverage of the Design gate.

## Suggested fix

**Gap 1** — Add G31 to one of the `skills/design/SKILL.md` rows (Slice 1.5 is the natural home) and extend the Responsibility cell to include: "apply prompt-prose-aware authoring step (`!cat skills/_shared/prompt-prose-detection.md` + `!cat skills/_shared/prompt-prose-writer-addition.md` per G31 Consumer #3)".

**Gap 2** — Add explicit rows for the three unassigned agents (or extend existing rows):

| File | Action | Responsibility addition | Goal IDs to add |
|---|---|---|---|
| `agents/qrspi-implementer-lightweight.md` | Modify | Add `prompt-prose-writer` to `skills:` frontmatter alongside existing `implementer-protocol`. | G31 |
| `agents/qrspi-code-quality-reviewer.md` | Modify (extend Slice 1.4 row) | Add `prompt-prose-reviewer` to `skills:` frontmatter. | G31 |
| `agents/qrspi-plan-spec-reviewer.md` | Modify | Add `prompt-prose-reviewer` to `skills:` frontmatter. | G31 |

Adding these rows also gives Plan a concrete surface to author tasks against; without them, Plan has no target file row to generate a G31 preload task for these three agents.
