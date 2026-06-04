---
finding_id: R4-F03
severity: low
change_type: correctness
referenced_files: [tests/acceptance/v07-phase1/test-phase1-acceptance.bats]
---

# TE8 — no test pins scripts/verifier-fan-in.sh was not modified

Spec TE8 (L57): "Grep/audit confirms no changes to scripts/verifier-fan-in.sh, its audit JSON shape, kept-findings.txt semantics, verifier_enabled, or per-skill review-loop wiring."

R4 diff confirms the script was not modified. AC4 runs it (behavioral), AC6/AC8 (T9) regression-pin threshold + verified.md absence. But no T10 test provides the specific grep/audit TE8 calls for — content pin asserting no new fields/tokens appear.

Convergent with tc-claude.finding-F02 → PI-V072-T10-020. Same gap, different reviewer; both surfaced as TE8 coverage miss.

**Recommended fix:** add `[AC6]` test asserting `scripts/verifier-fan-in.sh` does not reference `defect_class|representative_score|sub.threshold.obs`.
