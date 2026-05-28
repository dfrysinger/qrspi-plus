---
finding_id: R3-F03
reviewer: quality-claude
verifier_score: 75
verdict: KEEP
---

Verified: `conditional: true` appears in T43 frontmatter (L1288); no other task uses it; not documented in plan.md's task-spec template. T31 sub-subagent needs the schema. Apply via cluster: add a `## Task Specs` preamble explaining the field + `conditional_precondition`.
