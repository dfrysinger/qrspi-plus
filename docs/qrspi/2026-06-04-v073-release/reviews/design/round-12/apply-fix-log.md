# R12 apply-fix log

**Preemptive (1 below threshold but real):**
- quality-codex.F01 (55, correctness): G6 stated parent[0] invariant but validator was set-only. Applied — Solution step 1 preserves order; step 3 splits into two-invariant validation (parent[0] equality + set match on tail); diagnostic enriched; acceptance bullet added for wrong-first-parent fixture.

**Clean: quality-claude, scope-claude, scope-codex (all NO_FINDINGS).**
