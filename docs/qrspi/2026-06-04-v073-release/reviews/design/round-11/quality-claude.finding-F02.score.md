---
verifier_status: passed
score: 72
defect_class: internal-contradiction
---

Cite Check: L422, L426, L432 all exist and the quoted excerpts match verbatim
("anchor SHA file pickup" appears in L422's parenthetical; the one-commit-per-round
phrasing and "remains uncommitted until the NEXT round's per-round commit picks it
up" appear at L426 and L432). Citations clean.

The contradiction is real and well-argued. Under the design's stated model
(L426/L432, citing research Q13/Q14), each round produces exactly one commit, and
the anchor SHA file written at end of round N is picked up BY round N+1's
per-round commit — it is not an additional commit between rounds. Therefore from
round N+1's per-round commit, HEAD~1 still resolves to round N's per-round commit;
"anchor SHA file pickup" cannot be a HEAD~1-shifting hazard under this model. The
other two examples in the parenthetical (hotfix, bookkeeping) genuinely are
additional commits that would shift HEAD~1, so they hold up — only the third
example contradicts the section's own model.

This is an internal contradiction inside a single section (G7 Outcome vs G7
Solution), introduced/reframed in round 11 per the finding's framing. Readers
trying to reconcile L422 against L426/L432 will be left uncertain whether the
model is one-commit or two-commit per round, which is exactly the framing
ambiguity the round-11 rewrite was meant to resolve.

Fix is small and the suggested option (a) — drop the contradictory example and
let "etc." carry the open-ended list — is low-risk. Worth fixing in the next
round. Solid clarity finding; not load-bearing for correctness of the design
choice itself (the solution still works), but the contradictory example
undermines the section's reasoning.
