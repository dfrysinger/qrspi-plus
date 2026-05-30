---
finding_id: F02
severity: minor
task: Task 8
goal_ids: [G7a]
category: BUNDLE
round: 2
---

# F02 — Task 8 sizing exception reason "mechanism retirement" is not in the closed set

## Summary

Task 8 carries a `Sizing exception` bullet whose reason is **"mechanism retirement"**. The closed
exception set permitted by the reviewer protocol is: `schema migration`, `CI scaffolding`, or
`reusable primitives`. "Mechanism retirement" is not in this set. Per the protocol, any other
exception value is itself a BUNDLE finding.

## Detail

**Task 8 sizing exception (verbatim):**
> Sizing exception: mechanism retirement -- deletions and removals are tightly coupled because the
> prompt-cache mechanism boundary must close atomically across script + spike + unit tests + skill
> prose + acceptance suite; splitting would create transient intermediate states where the mechanism
> is half-retired. Validated by CI-green per Design DKR8 (mechanical deletion / no new design
> surface).

**Permitted exception reasons:** schema migration | CI scaffolding | reusable primitives

"Mechanism retirement" does not match any of these. The protocol states: "Any other exception value
is itself a finding (BUNDLE)."

## Mitigating Context

The practical case for bundling is strong: Task 8 is a sweep of mechanical deletions with no new
logic, all serving one user-visible use case (prompt-cache mechanism is retired). The test
expectations all trace to this single use case. The LOC estimate is ~150, below the 200-LOC floor
that independently triggers a sizing requirement. The DKR8 design decision explicitly labels G7a
"mechanical lift-verbatim deletion / no design surface."

**Nearest applicable closed reason:** "schema migration" is the closest analogy — both are
mechanical, multi-file, atomic sweeps where partial application leaves the repository in an
inconsistent state. However, schema migrations are database/interface changes; mechanism retirement
is a different category. The plan should either:

1. **Reclassify** the exception reason to the closest permitted value with an in-plan justification
   note explaining the analogy (e.g., "schema migration: atomic multi-file sweep with no partial
   states, analogous to a schema migration"), **or**

2. **Remove the exception bullet** if the single-use-case argument holds (one use case = cache
   mechanism retired → no sizing exception needed at all under the ">1 distinct observable
   behaviors" test).

## Recommended Resolution

Option 2 is cleaner: argue that Task 8 has exactly one observable use case (prompt-cache mechanism
retirement) and therefore requires no sizing exception at all. Remove the `Sizing exception` bullet
and add a brief in-description sentence explaining that the task constitutes one behavioral unit.

If the plan author prefers Option 1, the reclassification note should be explicit: "schema
migration (by analogy: atomic multi-file retirement sweep, same atomicity argument as a schema
migration — partial application leaves SKILL.md and dispatcher out of sync)."
