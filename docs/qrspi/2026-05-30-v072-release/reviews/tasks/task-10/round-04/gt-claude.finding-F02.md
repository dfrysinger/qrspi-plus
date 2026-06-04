---
finding_id: R4-F02
severity: medium
change_type: clarity
referenced_files: [docs/qrspi/2026-05-30-v072-release/tasks/task-10.md]
---

# task-10.md DoD/TE5 use Reading A language; Reading B adoption not recorded in spec

**Locations:** task-10.md L42 (DoD: "each finding's defect class, each score"), L54 (TE5: "scores"). Both use plural per-finding language — Reading A.

R4 implementation adopted Reading B (`representative_score:` — single representative figure per cluster, typically the minimum). SKILL.md inline disambiguation is thorough; task-10.md still carries Reading A language with no inline note that Reading B was adopted. An auditor reading task-10.md would read "each score" → expect per-finding scores → conclude spec was not met until finding the PI-V072-T10-005 note buried in SKILL.md prose.

The traceability chain has an unresolved visible divergence at the spec level. PI-V072-T10-005 resolves it, but the task spec never records the resolution.

**Recommended fix:** add inline note to task-10.md DoD L42 + TE5 L54 (or `## Spec Disambiguation` block) recording Reading B adoption with PI-V072-T10-005 cross-reference.
