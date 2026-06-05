---
finding_id: F06
severity: medium
change_type: scope
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/questions.md
  - docs/qrspi/2026-05-30-v072-release/goals.md
artifact: questions
---

# Missing Area — G25 (Per-H4 Mirror-Paragraph Fragility) Has No Corresponding Question

## Goal Not Covered

**G25** — Per-H4 mirror-paragraph pattern requires every future dispatch-path author to remember the fail-loud contract: `skills/using-qrspi/SKILL.md` currently enforces the fail-loud contract via four per-H4 mirror paragraphs (L470, L488, L501, L526). A future author adding a fifth dispatch path is expected to remember to author a fifth mirror paragraph. G25 is `known-fix` and requires Research to characterize the current structural pattern in the dispatch-routing section before Design can evaluate Option B (top-level invariant) vs. Option A (stay on per-H4 enumeration).

## Why This Is a Gap

Q7 asks about the validation table at L641-660 and whether the fail-loud paragraphs are bidirectionally referenced from it. That is the G23 question. Q7 does NOT ask:
- How are the four per-H4 paragraphs (L470, L488, L501, L526) structurally related to each other — do they use a consistent prose template?
- Is there any class-level preamble or invariant in the "Dispatch routing" section that would generalize to future dispatch paths?
- What exactly do R5 and R6 security-claude findings say about the structural fragility of per-H4 enforcement vs. a top-level invariant?

Without these research questions, Design for G25 enters without knowing the current structural pattern (how repetitive the four paragraphs are), which directly affects whether Option B's invariant would naturally subsume them or require non-trivial restructuring.

G25 also couples tightly with G24-F02 (prose redundancy of the same four H4s). Q11 covers G1 (design skill), and Q8 covers G21 (bats assertion forms). No question exists to characterize the dispatch-routing section's structural pattern.

## Suggested Addition

`[codebase]`:
> "How are the four per-H4 fail-loud paragraphs at `skills/using-qrspi/SKILL.md` L470 (`model_routing:`), L488 (`trusted_path:`), L501 (`validators:`), and L526 (missing-block backfill) structured? Do they share a common prose template, or does each paragraph have unique wording? Is there any class-level preamble or invariant statement in the 'Dispatch routing' section that covers all four, or does each paragraph stand alone? What do the R5 and R6 review round finding files in `docs/qrspi/2026-05-27-v071-hardening/reviews/` say specifically about the fragility of the per-H4 pattern vs. a top-level invariant?"
