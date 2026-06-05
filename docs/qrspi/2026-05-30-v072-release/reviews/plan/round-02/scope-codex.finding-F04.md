---
reviewer_tag: scope-codex
change_type: scope
severity: low
artifact: plan.md
location: "Plan-wide — artifact length"
referenced_files:
  - plan.md
---

# F04 — Plan length over-expansion vs OWNS concision target

## Defect

Artifact length (2742 lines / 44 tasks, ~62 lines/task) is materially beyond the Plan soft top band (~2000 lines per `skills/plan/owns-defers.md` guidance, ~52 lines/task baseline). Repeated rationale/reference prose reads like downstream design/implementation contract text rather than negotiable plan scope.

## Impact

Plan-altitude artifacts that grow too large dilute the per-task spec signal and increase main-chat context cost during Implement dispatch.

## Recommended fix

Compress per-task References sections — replace verbose citation prose with anchor-only references (e.g., "See design.md §G31" instead of paragraphs of paraphrased design content).

## Counter-argument to consider

Scope-claude round-02 explicitly cleared this dimension: "Length: 2742 lines / 44 tasks ≈ 62 lines/task — close to Keeplii ~52 baseline; aggregate ~37% over the 2000-line soft top but accounted for by per-task References overhead; not 'well outside' the band." The per-task overhead is intentional (the v0.7.3 enhanced shape from issue #292 we authored mid-pipeline).
