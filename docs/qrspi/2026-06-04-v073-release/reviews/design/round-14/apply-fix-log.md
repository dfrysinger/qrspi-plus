# R14 apply-fix log

**Preemptive (1 below threshold but real implementer trap):**
- quality-codex.F01 (55, correctness): G6 numbered steps were inverted — step 1 said "after merge, read parents" while step 2 said "before merge, capture HEAD". A literal-order implementer would capture from already-mutated HEAD. Applied — reordered to capture (pre-merge) → merge+read (post-merge) → validate, with explicit "Sequence is load-bearing" preamble.

**Clean: quality-claude, scope-claude, scope-codex.**
