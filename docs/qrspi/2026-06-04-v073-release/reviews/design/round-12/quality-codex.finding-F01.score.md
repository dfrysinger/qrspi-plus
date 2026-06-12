---
verifier_status: passed
score: 55
actual_model: unknown
defect_class: invariant-not-enforced
---

Cite Check passes: design.md L391 frames the captured integration-base SHA as "will become parent[0]" and L395-397 explicitly specify a set comparison "with no parent[0]-stripping normalization." L405 confirms "full parent set vs. full expected set" semantics. Acceptance (L410-416) covers missing/extra parents but not order.

Finding is real: a set-equality validator cannot detect first-parent reordering, yet the design itself frames parent[0]=integration-base as the spine property. The v0.7.2 failure shape that motivates G6 happens to differ as a set too (so the set check would have caught it), which weakens "this will be hit in practice" — in normal `git merge --no-ff` invocation from HEAD, parent[0] is always HEAD by construction. A pure ordering-only drift requires a contrived invocation pattern.

Still, the finding correctly identifies that the design states an invariant the validator does not enforce, and the proposed fix (one-line tightening of the comparison + one acceptance fixture) is cheap and structurally honest. Moderate correctness gap, not a nitpick, but not a load-bearing showstopper either.
