---
finding_id: F03
reviewer_tag: silent-failure-codex
severity: medium
change_type: correctness
referenced_files:
  - scripts/_resolve-lib.sh:237-246
---
resolve_second_reviewer_vendor has a set -u argument hazard: `local host="$1" primary_vendor="$2"`
dereferences $2 without validating arity. In a caller running with nounset, a missing second
argument aborts with a generic shell unset-variable error, not a tagged [second-reviewer-unavailable]
or [second-reviewer-same-vendor] diagnostic — an unstructured failure path outside the loud-failure contract.
