---
finding_id: R1-F01
reviewer: test-coverage-claude
artifact: plan.md
task: Task 22
severity: high
change_type: correctness
---

# T22 — "concise references" and "manual review" test expectations are not falsifiable

## What

Task 22 (G24-F02 `using-qrspi` per-H4 prose redundancy consolidation) has two
test expectations that are not deterministically verifiable:

1. **Grep/diff audit of `skills/using-qrspi/SKILL.md` confirms the four old
   H4-specific fail-loud mirror paragraphs have been collapsed to *concise
   references* while the class-level fail-loud contract remains present.**
2. **Manual review of the `model_routing:`, `trusted_path:`, `validators:`, and
   missing-`model_routing:` backfill surfaces confirms each still communicates
   halt-loudly/no-silent-fallback semantics.**

The matching DoD bullets are equally soft:

- "Each affected H4 retains a concise local reference *or equivalent wording*
  that points readers back to the single class-level fail-loud contract rather
  than restating the full invariant."
- "No dispatch path loses the no-silent-fallback / halt-loudly requirement..."

## Why this is a test-coverage problem

The Test phase will need to write an acceptance test for "the four old H4
mirror paragraphs have been collapsed to concise references." There is no
falsifiable criterion:

- "Concise reference" has no measurable property (line count? word count?
  absence of a specific anchor phrase?). Two implementations — one that leaves
  a 3-sentence reference paragraph and one that leaves a 1-line cross-reference
  — would both arguably satisfy this expectation.
- "Manual review … confirms each still communicates halt-loudly semantics" is
  a thought-experiment, not a test recipe. The Test writer cannot generate a
  deterministic assertion from it. T44 (G24-F05) DOES pin silent-fallback
  intent regex assertions — but T22 lands BEFORE T44 in the dependency graph
  (T18 → T22 → T23 → … → T44), so T22 has no executable backstop at its
  commit point.

## Falsifiable alternative

Make the test expectation name observable properties:

- Either pin an explicit anchor phrase that the consolidated reference must
  contain (e.g., "see the class-level fail-loud invariant above") and a max
  line count for each of the four H4 sections after the edit, OR
- Defer T22's pass criterion to the post-T44 acceptance surface and explicitly
  state that T22's only verifiable contract is "the four named H4 sections no
  longer carry the four pre-T22 literal pin strings X, Y, Z, W" (positive
  identification of what was removed).

The Test writer needs at least one of: a positive-anchor presence check or an
enumerated negative-anchor absence check, with the specific anchor strings
named in the expectation.

## References

- plan.md ### Task 22 — DoD and Test expectations sections.
- plan.md ### Task 44 — silent-fallback intent regex pins, which would be the
  proper backstop but lands later in the dependency chain.
