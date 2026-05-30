---
finding_id: R1-F01
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/plan.md, docs/qrspi/2026-05-27-v071-hardening/goals.md]
artifact: plan
round: 1
reviewer: quality-codex
---

## Criterion-authoring contract violation (acceptance criteria still in goals)

goals.md still contains acceptance-style criteria ("G7b Acceptance under Candidate A" bullets). Violates strip-from-goals contract. Normative acceptance checks should live only in plan.md / phasing.md.

**Required fix:** remove acceptance criteria from goals.md (or convert to non-normative context). NOTE: goals.md is already approved; this fix requires an upstream amendment outside Plan round-1 scope. Surface to user.
