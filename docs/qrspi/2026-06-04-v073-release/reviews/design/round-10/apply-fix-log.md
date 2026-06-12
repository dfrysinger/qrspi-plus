# R10 apply-fix log

**Kept (4) all applied:**
- quality-claude.F01 (72, correctness): G7 Outcome reframed — old framing (HEAD~1 hitting same round's fix) was structurally impossible under one-commit-per-round. New framing: unrelated-commit shift + SKILL-prose orchestrator-skippability.
- quality-codex.F01 (75, correctness): G6 capture procedure now includes integration-base SHA (`git rev-parse HEAD` before merge) plus task tips; comparison stays full-set with no parent[0] stripping (resolves edge-case asymmetry).
- scope-codex.F01 (40, scope): G6 sidecar path softened — concrete path removed; described as "runtime sidecar under the artifact-dir's review-state tree, exact path Structure's call".
- scope-codex.F02 (60, scope): G6 acceptance added bullet — fixture proves capture writes integration-base + task tips, validation reads from sidecar, parallelization.md unchanged.

**Preemptive (below clarity floor of 80 but real):**
- quality-claude.F02 (72, clarity): G7 Solution L425 "(the anchor-capture commit)" — corrected to "(the anchor SHA file-write — not its own commit; per research Q13/Q14 each round produces exactly one commit)". Same change cleans up G7 Acceptance bats fixture wording for F03.

**Dropped (1):**
- quality-claude.F03 (40, clarity) — minor fixture-naming nit; already partially addressed via F02 cleanup.
