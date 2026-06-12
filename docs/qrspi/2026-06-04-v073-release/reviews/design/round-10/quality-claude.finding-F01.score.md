---
verifier_status: passed
score: 72
actual_model: unknown
defect_class: internal-contradiction
---

Cite Check: Verified.
- design.md L419: goal title reads "Narrow-round ref selection robust under multi-commit-per-round patterns" — matches finding's quote.
- design.md L421 Outcome: contains the quoted "HEAD~1 happens to point at the same round's fix commit instead of the prior round's" failure-mode description, framed around an in-round same-round fix commit.
- design.md L431: contains "Keep the existing one-commit-per-round shape ... confirmed in research Q13/Q14."

The contradiction the finding identifies is real and self-contained within G7: the same section asserts (a) one-commit-per-round is the structural model AND (b) the failure mode is HEAD~1 landing on a same-round fix commit, which by construction requires ≥2 commits per round. Under the one-commit-per-round shape L431 asserts, HEAD~1 from round N+1 by definition resolves to round N's per-round commit; the precise failure mode the Outcome describes cannot occur.

The finding correctly notes that the fix is still defensible (HEAD~1 is fragile against any unrelated intermediate commit, and explicit anchor lookup is also more readable / less skip-prone), so this is a framing/rationale defect, not a "the whole goal should be cut" defect. The expected-fix menu (rewrite Outcome to describe the actual failure window OR scope L431's claim narrower) is appropriately balanced.

Severity: a reader auditing G7's rationale will hit this contradiction and lose confidence in the section. Not a functional defect in the proposed mechanism (the mechanism is fine), but a load-bearing rationale defect — the Outcome paragraph is what justifies G7 existing at all, and as written it justifies it via a bug premise the same section says cannot occur. Worth fixing before Plan.

Not a CLAUDE.md/Iron-Law violation, but a meaningful internal-consistency defect in a design artifact whose entire job is to nail down rationale. Scoring 72.
