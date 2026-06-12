# R09 apply-fix log

**Kept (3):**
- quality-codex.F03 (80, correctness): G7 mis-cited "two-commit-per-round" — research Q13/Q14 confirms one commit per round, anchor file is uncommitted file-write. **Applied** — corrected G7 Solution L431, Why bullets L433-436, Edge cases L445.
- quality-codex.F04 (80, correctness): G6 cited non-existent "recorded task-tip SHA set" — research Q11/Q12 says branch map is symbolic only. **Applied** — G6 Solution step 2 now specifies runtime-sidecar capture (`<artifact-dir>/.wave-state/wave-N-expected-parents.json`) at wave-dispatch resolution time; dependency bullet L404 corrected to mark capture as new behavior.

**Preemptive (below threshold but real):**
- quality-codex.F02 (60, correctness): G4 acceptance examples omitted `--artifact-dir` introduced in R08. **Applied** — L263-265 now include `--artifact-dir <fixture>` in all three example invocations.

**Dropped (1) below threshold:**
- quality-codex.F01 (10) — Mermaid hallucination.

**Clean (3):** quality-claude, scope-claude, scope-codex.
