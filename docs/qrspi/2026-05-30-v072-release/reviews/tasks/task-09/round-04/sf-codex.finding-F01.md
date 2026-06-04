---
finding_id: R4-F01
reviewer_tag: sf-codex
round: 4
severity: medium
change_type: correctness
referenced_files: [scripts/run-codex-review.sh]
---

# sf-codex F01: Manifest write filesystem operations are unchecked (error-and-continue)

**Status of prior F01:** CLOSED — jq command substitution now explicitly guarded at scripts/run-codex-review.sh:620-627; jq failure no longer swallowed.

## New finding

**Location:** scripts/run-codex-review.sh:628-640

**Issue:** `mkdir -p`, `sed`, `printf` redirections, and `mv` are all unchecked inside `emit_dispatch_manifest_entry()` while the script runs without `set -e`.

**Silent-failure impact:** if any filesystem step fails (permissions, disk full, bad existing manifest shape, rename failure), the function can fail/partially fail but the script still proceeds to dispatch and may exit success based on dispatcher status. That masks loss/corruption of the audit manifest.

**Why it matters:** T09's audit trail can be missing or corrupted without a hard failure signal to callers/CI.

## Disposition note (orchestrator)

R4 = 4th review pass; per QRSPI 3-round budget, no further fix-cycle is dispatched. This finding is real but defers to T09 batch-gate as **accept-with-issues** or routes to v0.7.3 backlog under the broader "fail-loud filesystem writes in audit emission" theme.

The R3 fix for the prior F01 was scoped to jq failure (the convergent attack-surface signal). The filesystem-write surface is a parallel-but-distinct silent-failure class that sf-codex first surfaces in R4 after the R3 jq fix made it the most-prominent residual gap.
