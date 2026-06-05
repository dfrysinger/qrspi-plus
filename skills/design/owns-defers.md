**Analogy.** design.md is the **architecture brief** for the project: it states the chosen approach, the trade-offs that were weighed, the key technical decisions and their rationale, the design-level test strategy, and a high-level system diagram. It does NOT enumerate concrete implementation surfaces (DDL, full signatures, assertion text), and it does NOT author phasing decisions (which slices belong in which phase). Implementation surfaces are owned downstream by Plan / Implement; phasing concerns — vertical slice authoring, phase boundaries, Iron Law 1, the Phase 1 PoC guideline, replan-gate criteria — are owned by `qrspi:phasing` (see `skills/phasing/SKILL.md`).

The OWNS/DEFERS contract below is the locked rule set the scope-reviewer dispatch loads at review time (Read by the `qrspi-design-scope-reviewer` agent at runtime per its rules-loading procedure). Boundary-drift detection runs against the DEFERS list; scope-compliance runs against the OWNS list.

!cat skills/_shared/design-altitude-boundary.md

**Phasing pointer.** Phasing concerns (vertical slices, phase boundaries, Iron Law 1, the Phase 1 PoC guideline) are owned by `qrspi:phasing` — see `skills/phasing/SKILL.md`.

A finding citing design.md prose that asserts any DEFERS item from the included contract above is a boundary-drift finding emitted by the scope-reviewer with `change_type: scope` (per the schema in `skills/reviewer-protocol/SKILL.md`).
