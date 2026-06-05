---
finding_id: R3-F02
reviewer_tag: spec-codex
severity: high
change_type: scope
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/tasks/task-10.md#L31-L32,L44,L57
  - scripts/verifier-fan-in.sh#L39-L48
---

# scripts/verifier-fan-in.sh modified despite explicit out-of-scope prohibition

Task-10 spec L31 (Out): "Changing `scripts/verifier-fan-in.sh`, its audit JSON shape, `kept-findings.txt` semantics, `verifier_enabled`, or per-skill review-loop wiring."

Task-10 spec L44 (DoD): "No changes are made to `scripts/verifier-fan-in.sh`..."

Task-10 spec L57 (test expectations): "Grep/audit confirms no changes to `scripts/verifier-fan-in.sh`..."

R2 fix added ~12 lines of header documentation to `scripts/verifier-fan-in.sh` (field-ordering invariant documentation), violating all three spec citations. Even though behavior is unchanged, the prohibition is unconditional.

**Convergent with spec-claude R3 F02 (severity MED there).**

**Disposition:** REVERT — remove the header documentation block from `scripts/verifier-fan-in.sh`; the agent body invariant text is sufficient and in-scope. Remove the associated unit test pinning the fan-in header content.
