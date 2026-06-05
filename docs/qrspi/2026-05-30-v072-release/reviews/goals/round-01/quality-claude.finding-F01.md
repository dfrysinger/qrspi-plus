---
finding_id: R1-F01
severity: low
change_type: clarity
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/goals.md
artifact: goals
round: 1
reviewer: quality-claude
---

## quality-claude.F01 — G23 "What we know so far" prescribes a solution rather than framing it as a candidate for Design to weigh

### Location

`goals.md` → `### G23 — Validation table omits model_routing: and is uncross-linked to fail-loud paragraphs` → `#### What we know so far`

### Description

Every other goal in this file introduces candidate solutions under the explicit header "Candidates Design should weigh:" (or equivalent phrasing such as "Candidates Research should investigate:"), correctly signalling that the solution space is open and that the Design phase makes the final choice. G23's `What we know so far` section does not use that framing:

> Mechanical addition: one row in the validation table plus cross-link annotations on L470/L526. Single paragraph of work.
>
> **Coupling with G22 (model-routing schema drift).** … Order suggestion: G22 first, G23 as a sub-task of the same Plan-phase wave.

The phrase "Mechanical addition: one row … Single paragraph of work." states the solution as a fait accompli. "Order suggestion: G22 first, G23 as a sub-task" prescribes sequencing. Neither is wrapped in "Design should weigh" or equivalent. This breaks the consistent pattern established across the other 26 goals and could cause the Design phase to treat G23's solution as pre-decided rather than as a proposal to evaluate.

### Expected pattern (from sibling goals)

```
#### What we know so far

Candidates Design should weigh:

- Add one row to the validation table at L641-660 for `model_routing:`, with
  cross-links to the fail-loud paragraphs at L470 and L526.
- If G22 lands a canonical-schema decision that reorganizes `model_routing:`,
  coordinate this fix in the same edit pass to avoid churn.
```

### Suggested fix

Reframe the prescriptive sentences as candidates under the standard "Candidates Design should weigh:" header. The informational coupling note about G22 can be retained verbatim; only the framing of the mechanical-addition statement needs to change from a direct prescription to a candidate proposal.

### Impact

Low: the solution space for G23 is genuinely narrow (adding a table row), so the prescriptive framing is unlikely to produce a wrong Design decision. The issue is presentational consistency — a reader skimming all 27 goals for uniform framing will find G23 anomalous, and the Design-phase agent may treat its solution as locked rather than candidate-open.
