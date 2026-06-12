# R13 apply-fix log

**Kept (1) applied:**
- quality-claude.F01 (80, correctness): G6 step 2 + L405 still said "no parent[0]-stripping normalization" after R12 step 3 explicitly split parent[0] vs set(parents[1:]). Applied — step 2 now describes capture as two separable fields (integration_base + task_tips list); L405 edge case restated to apply two-invariant validation uniformly.

**Clean: quality-codex, scope-claude, scope-codex.**
