---
finding_id: R1-F03
reviewer_tag: silent-failure-claude
round: 1
task: 02
severity: low
change_type: correctness
referenced_files:
  - scripts/verifier-fan-in.sh
---

## F03 — Clean path leaves kept-findings.txt without audit on write_audit failure

Lines 272-276. kept-findings.txt written first; if write_audit fails, file exists but audit doesn't. Naive presence-check callers proceed without audit. Symmetric to codex F02 (halt-path stale-file).

Fix: ERR trap removes kept-findings.txt; or atomic-mv ordering (audit-first or all-or-nothing).
