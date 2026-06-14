# Plan — Common Rationalizations

Read this file when reviewing a plan and you need a quick rebuttal to common pushback against the Iron Laws and Task Sizing rules.

| Rationalization | Reality |
|----------------|---------|
| "The implementation agent will figure out the details" | No. The plan is the contract. Vague specs produce wrong implementations. |
| "This task is similar to Task N, I'll just reference it" | Each task must be self-contained. The agent may read tasks out of order. |
| "Test expectations are implied by the description" | Write them explicitly. The Test skill uses them to generate acceptance tests. |
| "LOC estimates don't matter" | They signal scope. Unrealistic estimates mean the task is misunderstood. |
| "We can split this task during implementation" | Split now. The plan is where decomposition happens, not implementation. |
| "Splitting these features adds coordination overhead" | SWE-Bench Pro reports ~23% frontier-model success at 107-LOC median patch size; tasks above the 200-LOC ceiling sit well past that empirical cliff. Coordination overhead is cheaper than the retry cost on a sub-50% pass rate. |
| "These features all live in the same file" | File overlap is not handler overlap. One handler per task even if multiple share a file — separate tasks can sequence edits inside one file via Dependencies. |
| "Schema setup naturally bundles, this is fine" | True only for the closed exception set: schema migration, CI scaffolding, reusable primitives. Mark `sizing_exception: <reason>` and explain in the Description. Do not use as a general escape hatch. |
| "Quick fix doesn't need a plan" | Quick fix mode still produces a plan — it's just a single-task plan. The plan ensures the fix is reviewed before implementation. |
