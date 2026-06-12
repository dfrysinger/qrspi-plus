# R08 apply-fix log

**Kept (2):**
- quality-codex.F01 (80, correctness): CD-1/G4 interface inconsistency on `--artifact-dir`. **Applied** — CD-1 L13 now explicitly says `--artifact-dir <path>` is accepted for steps with pipeline-mode-aware upstream sets (currently Plan, per G4); matches G4 internal-read pattern.
- quality-claude.F01 (75, correctness): CD-2 misattributed cross-reference "per G4's pipeline-mode rules" (G4 governs upstream_paths, not diff narrowing). **Applied** — removed clause; added explicit note that diff narrowing follows G7 convergence rule and review-prep introduces no new narrowing semantics.

**Dropped (2) below threshold:**
- quality-codex.F02 (10) — Mermaid hallucination
- quality-codex.F03 (20) — TestStrategy hallucination
