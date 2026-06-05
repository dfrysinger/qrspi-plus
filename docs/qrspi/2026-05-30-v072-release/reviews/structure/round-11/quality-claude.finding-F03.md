---
artifact: structure
reviewer_tag: quality-claude
finding_id: R11-F03
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/structure.md:19
  - docs/qrspi/2026-05-30-v072-release/structure.md:665-676
  - docs/qrspi/2026-05-30-v072-release/structure.md:683-702
  - docs/qrspi/2026-05-30-v072-release/structure.md:729-736
  - docs/qrspi/2026-05-30-v072-release/structure.md:743-751
  - docs/qrspi/2026-05-30-v072-release/structure.md:2058-2067
  - docs/qrspi/2026-05-30-v072-release/structure.md:2589-2603
severity: medium
change_type: correctness
---

# Verbatim-block convention drift — G15/G18 lifts preserve `> ` blockquote markers contrary to the Prose Provenance Convention

## What is broken

The Prose Provenance Convention at structure.md L19 declares an explicit rule for verbatim payloads:

> "The fenced code block (e.g., ```markdown for `.md` targets, ```bash for shell scripts) is the unambiguous payload boundary and carries the lifted prose **byte-identical to design.md, with no leading `> ` blockquote markers**."

The convention is applied **inconsistently** across the per-file blocks:

**Correctly stripped (no `> ` markers in payload):**
- G34 OWNS lift (structure.md L2058-2067) — design.md L2892-2899 uses `> ` markers in source; structure.md strips them.
- G34 DEFERS lift (structure.md L2073-2081) — same pattern.
- G35 OWNS+DEFERS lift (structure.md L2589-2603) — design.md L2966-2981 uses `> ` markers; structure.md strips them.

**Incorrectly preserved (`> ` markers carried into payload):**
- G15 Sweep Task Contract → `skills/plan/SKILL.md` (structure.md L665-676): payload reads `> ### Sweep Task Contract\n>\n> A **sweep task** removes…`
- G18 Cross-Task Consumer Surface → `skills/plan/SKILL.md` (structure.md L683-702): payload reads `> ### Cross-Task Consumer Surface\n>\n> A task is …`
- G15 Sweep-task detection → `agents/qrspi-plan-reviewer.md` (structure.md L729-735): payload starts `> **Sweep-task detection.** …`
- G18 Cross-task consumer surface detection → `agents/qrspi-plan-reviewer.md` (structure.md L743-751): payload starts `> **Cross-task consumer surface detection.** …`

All four of these lifts originate from design.md sections that wrap their content in `> ` blockquote prefixes as a design-display affordance (the same affordance the convention's display-fence carve-out treats as non-payload). The G34/G35 lifts apply the convention; the G15/G18 lifts do not.

## Why it matters

The verbatim payload is contract-binding: Plan/Implement consumers MUST write the target file with the fenced payload exactly. Whichever of the two contradictory behaviors gets shipped:

- **If G15/G18 ship with `> ` preserved:** `skills/plan/SKILL.md` § Sweep Task Contract and § Cross-Task Consumer Surface render as blockquoted sub-sections — a different visual category from the surrounding SKILL.md prose. `agents/qrspi-plan-reviewer.md` gains two blockquoted bullets where the file's existing rubric items are plain bullets. The structural shape of two key downstream files diverges from the convention's locked rule.

- **If a downstream author silently strips the `> ` markers during authoring:** the verbatim block is no longer byte-identical to what landed; the "stitching audit" the convention promises (L19, L24) cannot grep for the payload as written.

Either way, the locked-prose contract is broken — either the convention is wrong or these four blocks are wrong.

Note: this finding is about the **convention's own rule being inconsistently applied**, not about whether the target files should ultimately carry `> ` markers. If the target files genuinely want blockquoted sections (a defensible authoring choice for the Sweep Task Contract callout in plan/SKILL.md), the convention's "no leading `> ` blockquote markers" rule itself needs amendment — the choice cannot be made silently per-lift.

## Suggested fix

Two coherent options:

- **Option A (apply the convention as written):** Strip the `> ` markers from the four G15/G18 payloads. The plan/SKILL.md Sweep Task Contract subsection lands as a plain `### Sweep Task Contract` with plain body paragraphs and plain `-` bullets; same for Cross-Task Consumer Surface. The plan-reviewer rubric clauses become plain bold-prefixed paragraphs.

- **Option B (amend the convention to permit explicit blockquote callouts):** Replace the convention's "with no leading `> ` blockquote markers" clause with "leading `> ` blockquote markers are preserved when (and only when) design.md's surrounding prose marks the lift as an explicit callout-style spec block; outer display-only blockquote prefixes added solely for design.md's rendering affordance are stripped." This would require a Backward Loop to Design to lock the distinguishing criterion.

Option A is the smaller fix and lands inside structure.md alone. Option B requires a Design re-open. Pick one and apply consistently across all six lifts (G15×2 + G18×2 + G34×2 + G35×1).
