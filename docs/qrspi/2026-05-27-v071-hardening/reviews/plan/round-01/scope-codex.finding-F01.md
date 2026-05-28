---
finding_id: PLAN-SCOPE-001
severity: medium
change_type: scope
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/plan.md]
artifact: plan
round: 1
reviewer: scope-codex
---

## Phasing-owned content in plan.md

plan.md contains phase-structure justification ("single-phase structure is warranted because...") and explicit replan-gate criteria mapping. The phase-structure justification belongs in phasing.md.

**Disposition:** Trim the "single-phase structure is warranted because..." paragraph from plan.md Phase 1 prose. The per-phase Acceptance Criteria section (which references replan-gate criteria) is Plan-owned per the SKILL.md template; keep that.
