---
finding_id: R1-F02
severity: low
change_type: scope
referenced_files:
  - skills/_shared/multi-actor-flow-check.md
---

# F02 — "Documented assumption" branch lacks named recorder/surface (out of T28 scope)

The Alternative branch in the snippet's diagnostic template — "provide explicit guidance to accept the gap with a documented assumption recorded against this decision in the deliverable" — is the escape hatch from STOP. It lacks a named surface for the assumption record (no file path, no section name, no required heading like `## Documented Assumptions`).

In practice an agent can: STOP → ask user → receive a brief "go ahead" → write its own invented hand-off → label it "documented assumption" in prose → ship. The Iron law gets satisfied in form but defeated in substance because the audit surface for the assumption isn't pinned.

**Acknowledgment of spec scope.** Snippet body is locked verbatim by CD-3 / structure.md and DoD #1 requires preservation. NOT actionable inside T28. Logging for design-skill template owner (T30, per task's Out scope) and any future CD-3 follow-up.
