---
finding_id: R4-F02
severity: medium
change_type: correctness
referenced_files: [tests/acceptance/v07-phase1/test-phase1-acceptance.bats, tests/unit/test-verified-file-shape.bats]
---

# No test pins verifier-fan-in.sh / audit JSON shape / kept-findings.txt unchanged (L57)

Spec L57 explicitly requires "Grep/audit confirms no changes to `scripts/verifier-fan-in.sh`, its audit JSON shape, `kept-findings.txt` semantics, `verifier_enabled`, or per-skill review-loop wiring."

There is no automated assertion verifying these invariants. The diff confirms no changes were made, but structural additions (new audit fields, new env vars, new output paths) would pass silently. G28 explicitly defers cluster-analysis automation; this invariant is load-bearing for the scope deferral.

AC8 (T9) already sets the precedent: asserts `verified.md` does not appear in `qrspi-finding-verifier.md` or `verifier-fan-in.sh` — parallel pin for T10's "no fan-in changes" follows the same established pattern.

**Recommended remediation:** assert audit JSON does not carry `defect_class|cluster|representative_score` fields.
