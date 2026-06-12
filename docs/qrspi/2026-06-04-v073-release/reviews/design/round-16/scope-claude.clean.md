---
reviewer: scope-claude
artifact: design
round: 16
status: clean
---

# Scope review — clean

Round-16 diff against round-15's per-round commit is a single prose tightening in G6's "Why this approach" paragraph (design.md line 401):

1. `"a set comparison"` → `"a two-invariant check"` — aligns the mechanism summary with G6 step 3's actual two-invariant structure (first-parent ordering + task-tip set match).
2. Expansion of the "No new architecture / No new artifacts" clause to acknowledge the runtime sidecar introduced earlier in G6, qualifying it as out-of-band of `parallelization.md` per the symbolic-only invariant.

Both edits are rationale-altitude prose inside a per-goal Solution block — squarely inside Design OWNS (per-goal solution definitions including rationale and edge cases).

**Boundary-drift check:** none. The edit introduces no function bodies, no executable shell, no unit-test code, no file-architecture commitments (the "review-state" tree-name is already established vocabulary in untouched G6 prose above; the exact sidecar path remains explicitly deferred to Structure in the unchanged step 1 of the Solution and in the Dependencies bullet), no unified diagrams, no unified test strategy, no task carving.

**Scope-compliance check:** the edit strengthens the per-solution rationale Design OWNS. Nothing newly missing.

**Lexical-drift scan:** no new file paths, LOC budgets, task IDs, fixture filenames, or assertion text. "Sidecar" and "review-state" are pre-existing G6 vocabulary, not new this round.

No findings.
