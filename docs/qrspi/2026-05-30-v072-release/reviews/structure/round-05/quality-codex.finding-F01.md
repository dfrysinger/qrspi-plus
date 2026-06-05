---
finding_id: R5-F01
severity: medium
change_type: correctness
referenced_files:
  - structure.md (line 212, §3 verifier-fanout invocation)
  - design.md (line 470, CD-4 §H verifier-fanout invocation form)
---

## Finding

Structure §3 verifier-fanout invocation declares `[--tier-override qrspi-finding-verifier=<tier>]`, but design.md CD-4 §H authority specifies `[--tier-override <tier>]` for the same surface. Two artifacts now contractually disagree on the verifier-fanout `--tier-override` argument shape.

## Evidence

- structure.md:212 (post-R4): `[--tier-override qrspi-finding-verifier=<tier>]`
- design.md:470 (CD-4 §H authority): `[--tier-override <tier>]`

## Why this matters

design.md is the authoritative spec for CD-4 (which both Plan and Implement will consume); structure.md is the architect-of-the-phase translation. A divergence here propagates to the Plan-task that implements the verifier-fanout flag parser: it will be told two different argument shapes by the two artifacts and will pick one (likely the structure.md shape, since structure.md is closer in the QRSPI handoff chain).

The R4 fix that introduced this drift (R4-F01) was responding to a R3 finding about structure-internal disagreement between §3 and §7. The reconciliation direction was inverted: §7's CSV grammar exists for the reviewer-fanout case (CD-1), where multiple reviewers can have distinct tier overrides; verifier-fanout (CD-4) has a singleton agent, so the tag-prefix is meaningless and design.md uses the simpler bare-`<tier>` form.

## Suggested fix

1. Revert §3 line 212 from `[--tier-override qrspi-finding-verifier=<tier>]` to `[--tier-override <tier>]` (match design.md authority).
2. Tighten §7 wording to clarify that the CSV grammar `tag=tier,...` applies to reviewer-fanout's multi-reviewer surface; verifier-fanout takes a simpler bare `<tier>` because its agent is a singleton. One added sentence in §7 should suffice.
