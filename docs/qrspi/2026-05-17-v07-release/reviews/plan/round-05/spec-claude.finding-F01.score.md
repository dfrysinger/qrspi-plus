---
finding_id: R5-F01
reviewer: spec-claude
score: 92
decision: KEEP
---

## Score breakdown

- Citation accuracy: 20/20 — L926-L932 verified; `loc_estimate: 250` present, `sizing_exception:` absent.
- Specificity: 20/20 — exact frontmatter location named; analogous T07 precedent cited.
- Severity calibration: 18/20 — medium correct (review-checklist convention violation; reusable-primitives rationale is exactly the T07/T13 pattern).
- Actionability: 20/20 — frontmatter line + body bullet text provided verbatim.
- Non-redundant: 14/20 — distinct from the R3 sizing-exception finding that fixed T03/T07; this is a NEW instance the prior fix missed.

## Decision rationale

Convention enforcement: any task with LOC > 200 needs the sizing_exception declaration. T30 fits the reusable-primitives pattern (Slice 5 contract-lock). Apply.
