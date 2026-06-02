---
finding_id: R1-F04
severity: low
change_type: clarity
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/plan.md
artifact: plan.md
round: 1
reviewer: quality-claude
---

# T19 and T20 canonical-bullet `Model:` line carries a malformed annotation

## What's wrong

Two tasks deviate from the canonical bullet schema for the `Model:` line:

- T19 (G27 second-reviewer-available helper, plan.md line 1167):
  `- **Model:** opus  (sizing_exception → opus)`

- T20 (G3 dispatch-script rename collapse, plan.md line 1235):
  `- **Model:** opus  (sizing_exception → opus)`

The canonical shape, as carried by every other task in this plan (e.g. T12, T16, T25, T39), is two separate bullets:

```
- **Model:** opus
- **Sizing exception:** reusable primitives   ← (or "schema migration" / "CI scaffolding")
```

T19 and T20 both already include the separate `- **Sizing exception:** reusable primitives` bullet *below* the `Model:` line. The `(sizing_exception → opus)` parenthetical on the Model line is therefore redundant — and the arrow grammar is semantically ambiguous: a reader cannot tell whether it means "the sizing exception forces the model up to opus", "the sizing exception is the reason this task is opus rather than the default", or "the sizing exception's recommended model is opus." The other reusable-primitive tasks in this plan (T12 ~280 LOC; T25 ~340 LOC; T39 ~360 LOC) do not carry this annotation, so the deviation is not consistently load-bearing.

## Why it matters

- **Parser fragility.** The dispatch / Implement pipeline reads the canonical bullets via lightweight grep / awk. A parser tolerant of `**Model:** opus` is not necessarily tolerant of `**Model:** opus  (sizing_exception → opus)` — the parenthetical can spill into a captured model name or trip a strict-mode validation.
- **Schema-drift signal.** If the new prose-section template (the dispatch prompt called out as the v0.7.3 SKILL update) is meant to preserve the bullet schema *exactly*, then divergent shapes on T19/T20 weaken the per-task-spec schema contract that the rest of the file honors. Better to be uniformly clean than to leave two anomalies that a future schema-validator must learn to tolerate.

## Suggested fix

Drop the parenthetical on both tasks; the separate `Sizing exception:` bullet already carries the rationale:

T19:
```
- **Model:** opus
```

T20:
```
- **Model:** opus
```

If the intent was to document *why* opus was selected (sizing exception forced a model escalation), restate that in the Overview prose section instead — that is exactly the kind of decision context the new prose layer is built to carry.
