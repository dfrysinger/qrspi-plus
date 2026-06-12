# R11 apply-fix log

**Kept (2) all applied:**
- quality-codex.F01 (75 correctness): G6 Outcome stale — said "named task-tip SHA set" but Solution captures full set. Applied — Outcome now says "expected full parent set (integration-base + task-tip SHAs)".
- quality-claude.F01 (75 correctness): G6 single-task edge case bullet stale — still presented integration-base inclusion as open deliberation after Solution locked full-set comparison. Applied — bullet now states locked design: actual = expected = {integration-base, task-tip}; no parent[0] stripping.

**Preemptive (real but below clarity floor):**
- quality-claude.F02 (72 clarity): G7 brittleness rationale listed "anchor SHA file pickup" as HEAD~1-shifter, but under one-commit-per-round that pickup IS the per-round commit. Applied — replaced with "off-pattern commit added by a parallel chain" generic example.

**Dropped: none.**

**Clean: scope-claude, scope-codex (both NO_FINDINGS).**
