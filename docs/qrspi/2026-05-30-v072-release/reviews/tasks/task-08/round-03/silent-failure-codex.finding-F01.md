---
finding_id: R3-F01
severity: medium
change_type: correctness
artifact: code
round: 3
reviewer: silent-failure-codex
model: gpt-5.3-codex
referenced_files:
  - scripts/verifier-fan-in.sh#L320
---

# Swallowed audit-write failure on halt path

**Category:** Swallowed Errors / Log-and-Continue
**Location:** `scripts/verifier-fan-in.sh:320`
**Issue:** In the halt path, the script does:
  `write_audit "$SCORED" "$KEPT" "$DROPPED" || true`
This suppresses audit write failures (e.g., permission/disk I/O errors), then exits `1` as if halt handling completed normally.

**Why this is a silent failure:** The contract says exit-1 path writes audit JSON, but a failed write is ignored with no surfaced error. Downstream consumers lose the audit artifact and cannot distinguish "real halt with audit" from "halt + failed audit write."

**Risk:** Runtime diagnostics are masked, making triage difficult and potentially breaking fan-in consumers that depend on `.verifier-fan-in-audit.json`.

**Suggested fix:** Remove `|| true` and fail loudly on audit-write failure (or emit a second explicit stderr diagnostic and distinct exit code/cause when audit emission fails).

**Disposition note (orchestrator):** Pre-existing pattern not introduced by this fix-cycle (verified: line 320 unchanged in 224bd83's diff against b6ae44f). This is the recurring `|| true` defect class already on the v0.7.3 backlog ("`|| true` defect class recurring per round"). The intent at line 320 appears deliberate (the inline comment says "the message is visible even if write_audit fails" — they want exit 1 and the halt-cause stderr to still propagate), but the rationale should be made explicit or the pattern restructured to surface audit-write failures distinctly. Deferred to v0.7.3 as part of the consolidated `|| true` audit.
