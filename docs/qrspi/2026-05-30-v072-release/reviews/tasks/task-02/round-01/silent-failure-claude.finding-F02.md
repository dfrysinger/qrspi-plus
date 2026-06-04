---
finding_id: R1-F02
reviewer_tag: silent-failure-claude
round: 1
task: 02
severity: medium
change_type: correctness
referenced_files:
  - scripts/verifier-fan-in.sh
---

## F02 — jq failure inside record_halt exits mid-loop with no output

Line 88. `entry=$(jq -nc ...)` standalone assignment under set -e propagates failure. If jq absent or fails, script dies before HALTS_JSON updated, before write_audit, before stderr emit. No audit, no kept-findings, raw shell exit.

Fix: upfront `command -v jq` check at script start (exit 2 if absent).
