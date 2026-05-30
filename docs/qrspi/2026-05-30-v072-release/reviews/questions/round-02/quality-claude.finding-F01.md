---
finding_id: F01
severity: high
change_type: clarity
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/questions.md
artifact: questions
---

# Goal Leakage — Q10 Three Sub-Questions Directly Surface G2, G15, and G18 as Named Gaps

## Location

Question 10, third sentence:

> "Does the skill include any special handling for tasks whose scope covers many files of the same shape, any requirement to enumerate downstream consumers of contracts being changed, or any requirement to enumerate dependent tests?"

## Problem

Each of the three bracketed capabilities is precisely a named gap in a distinct goal:

| Sub-question phrasing | Goal telegraphed |
|---|---|
| "special handling for tasks whose scope covers many files of the same shape" | G2 — Schema-migration task shape: the Plan skill has no schema-migration exception |
| "requirement to enumerate downstream consumers of contracts being changed" | G18 — Plan-phase under-scopes cross-task consumer surface |
| "requirement to enumerate dependent tests" | G15 — Per-task test scope misses dependent tests for sweep tasks |

The framing "does the skill include any X?" presupposes that X is a desirable capability the skill lacks. A researcher reading only Q10 in isolation immediately understands: the project is trying to add (1) a schema-migration handling shape, (2) cross-task consumer enumeration, and (3) sweep-dependent-test enumeration to `skills/plan/SKILL.md`. All three goals are disclosed simultaneously.

The first two sentences of Q10 are neutral: they ask how the plan skill currently defines its spec template and LOC ceiling guidance, which is legitimate objective research. The leakage is isolated to the compound "does the skill include any X, Y, or Z?" clause appended to that neutral preamble.

## Why It Matters

This is the highest-density goal leakage in the current question set: three distinct planning goals (G2, G15, G18) are all inferable from a single compound sub-question. A researcher who now knows these three capabilities are absent from `skills/plan/SKILL.md` will investigate those specific absences rather than characterizing the plan skill's general template structure objectively. Research output will likely confirm "no, the skill doesn't have X" without exploring what alternative patterns the skill *does* use for related concerns — the evidence base that Design needs for evaluating candidates.

## Suggested Rewrite

Replace the third sentence with a neutral characterization request:

> "Examine the spec template fields prescribed by the skill and compare against representative tasks under `docs/qrspi/2026-05-27-v071-hardening/tasks/` (e.g., `task-09.md`, `task-10.md`) to characterize what the template produces in practice, noting any task shapes or concerns the template addresses explicitly and any observable patterns in how the template handles scope breadth."

This asks the researcher to describe what the template produces empirically, without naming the three specific capabilities as expected absences.
