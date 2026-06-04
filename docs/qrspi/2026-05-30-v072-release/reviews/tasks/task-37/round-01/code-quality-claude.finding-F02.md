---
finding_id: F02
reviewer: code-quality-claude
round: 1
severity: routine
change_type: code
file: skills/structure/SKILL.md
line: 209
---

# F02 — ID hygiene: QRSPI-internal example tokens `G1, G5` in runtime SKILL prompt template

The new `## Test Architecture` procedure step 1 contains:

> Record each by goal/CD identifier (e.g., G1, G5, CD-4).

`G1` and `G5` match the QRSPI-internal `G\d+` pattern and appear inside a **prompt template authored within this task's diff** — a strict surface per the ID Hygiene rule. While these are illustrative examples rather than run-specific copy from the task spec, the strict-surface clause for prompt templates does not carve out illustrative-example use, and concrete G-numbers in a permanent skill prompt risk:

1. Future readers treating the examples as referent identifiers rather than placeholders.
2. Collision/confusion with whatever real `G1`/`G5` exists in any future release the skill runs against.

`CD-4` does not match the QRSPI-internal regex strictly, but the consistency argument applies.

## Recommended fix

Use shape-only placeholders that don't pattern-match the QRSPI-internal regex:

```
1. Enumerate every per-solution `Acceptance` subsection in design.md — one per
   goal block and one per CD block. Record each by its goal/CD-block
   identifier (e.g., `G<n>`, `CD-<n>`).
```

The `<n>` notation makes the placeholder nature explicit and removes the strict-surface violation while preserving the orientation value the example provides.
