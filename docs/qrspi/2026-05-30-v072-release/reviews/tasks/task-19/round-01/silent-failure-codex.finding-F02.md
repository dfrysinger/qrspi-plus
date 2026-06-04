---
finding_id: F02
reviewer_tag: silent-failure-codex
severity: medium
change_type: correctness
referenced_files:
  - scripts/second-reviewer-available.sh:30-47
  - scripts/second-reviewer-available.sh:51-55
---
Non-zero failures from sourcing/shared-helper execution are not enforced. The script uses set -u
but not set -e, and does not check the status of sourcing _host-detect.sh / _resolve-lib.sh or the
command substitutions. If sourcing or helper execution fails, execution can continue and emit
misleading output or multiple stderr lines (shell error + tagged diagnostic), breaking the
"exactly one [second-reviewer-unavailable] line per failure path" contract.
