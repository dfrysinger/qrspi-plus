---
artifact: design
reviewer_tag: quality-codex
finding_id: quality-codex-F01
change_type: correctness
---

# G6 capture procedure misaligns with edge-case integration-base parent rule

## Location

design.md G6 Solution step 2 capture procedure; G6 edge case at L405-406.

## Finding

R09's capture procedure resolves only task branch tips into the expected-parents sidecar. But the existing edge case requires expected = full parent set including the integration base (parent[0] of `--no-ff` merge). As written, an implementation following the capture procedure would produce expected = {task tips only} while actual parents = {integration-base, task tips}, causing every valid merge to halt.

## Expected fix

Either: (a) extend capture to include `git rev-parse HEAD` (the integration-base SHA, which becomes parent[0]) before the merge, or (b) change the comparison rule to exclude parent[0] (compare actual_parents[1:] against expected).
