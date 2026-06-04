---
finding_id: R1-F01
reviewer_tag: silent-failure-claude
round: 1
task: 02
severity: medium
change_type: correctness
referenced_files:
  - scripts/verifier-fan-in.sh
---

## F01 — Halt path stderr-after-audit; set -e silences halt diagnostic

Lines 263-268. `write_audit` called BEFORE stderr echo. If write_audit fails (jq missing, disk full, perm), set -e exits before stderr diagnostic emits. Caller sees non-zero exit with no halt-cause message and no audit file. Contract violation.

Fix: emit stderr first; `write_audit ... || true; exit 1`.
