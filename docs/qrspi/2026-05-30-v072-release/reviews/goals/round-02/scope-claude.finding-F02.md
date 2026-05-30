---
finding_id: R2-F02
artifact: goals
severity: medium
change_type: scope
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/goals.md
round: 2
reviewer: scope-claude
---

## G25 "What we know so far" quotes the full proposed invariant text — Design-territory content

### Location
`goals.md` § G25 — Per-H4 mirror-paragraph pattern, "What we know so far" block (lines ~735–741 of current file).

### Observation
The section states "**Option B from R5 (the proposed v0.7.2 invariant):** add a top-level invariant to the 'Dispatch routing' section of `skills/using-qrspi/SKILL.md`:" and then quotes the complete ready-to-use clause verbatim in a block quote. The heading explicitly describes it as "the proposed v0.7.2 invariant" rather than a candidate to weigh.

### Rule violated
`owns-defers.md` → **Goals DEFERS: Detailed solution definitions → Design.**

The exact wording of a new invariant clause to be inserted into a SKILL file is a solution definition. The label "the proposed v0.7.2 invariant" signals that Goals is pre-selecting the solution rather than offering it as one possibility Design should evaluate.

### Expected correction
Replace the quoted invariant clause with a concept-level candidate: "add a top-level class-level invariant to the Dispatch routing section in `using-qrspi/SKILL.md` that prohibits silent fallback for any dispatch path — converting the four per-H4 mirror paragraphs from load-bearing contracts to illustrative reinforcements." Design authors the exact wording.
