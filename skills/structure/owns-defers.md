**Analogy.** structure.md is the **C-header file** / **system manifest** for the project: it declares what gets built, where each unit lives, and how the units connect at their interfaces — but it does NOT contain the bodies. Implementation text (the `.c` file equivalent) is owned downstream by Plan and Implement; architecture decisions (the spec the manifest realizes) are owned upstream by Design; phase boundaries and slice authoring (which units belong to *this* manifest at all) are owned by Phasing.

The OWNS/DEFERS contract below is the locked rule set the scope-reviewer dispatch loads at review time (Read by the `qrspi-structure-scope-reviewer` agent at runtime per its rules-loading procedure). Boundary-drift detection runs against the DEFERS list; scope-compliance runs against the OWNS list.

!cat skills/_shared/structure-altitude-boundary.md

A finding citing structure.md prose that asserts any DEFERS item — for example, embedding a literal compaction-callout sentence rather than just the placement site, or specifying per-task LOC inside a structure entry — is a boundary-drift finding emitted by the scope-reviewer with `change_type: scope` (per the schema in `skills/reviewer-protocol/SKILL.md`).
