# Phasing R02 — apply-fix log

3 findings, applied with conflict resolution:

- **scope-codex F01 + scope-claude F01** — sequencing bullet reduced to a pointer per scope-claude's suggested fix. This moots quality-claude F01 (which asked to *expand* the bullet to include G1→G2 — a pointer to goals.md covers all three sequencing constraints by reference). Also fixes the bullet's own misattribution ("Wave ordering for these constraints is owned by Plan" — Wave is Parallelize-owned per OWNS/DEFERS).
- **quality-codex F01** — replan-gate criterion 1 anchor changed from `## Acceptance` block (non-existent) to `**Acceptance.**` subsection (verified at design.md:23, 51, 124, 157, 184, 234, 262, 377, 409, 449, 489, 556).
- **quality-claude F01** — superseded by the pointer reduction above. The pointer to goals.md § Cross-Cutting Notes carries the G1→G2 prerequisite chain (and all other sequencing constraints) into Plan/Parallelize without restating them in phasing.md.
