**Analogy.** structure.md is the **C-header file** / **system manifest** for the project: it declares what gets built, where each unit lives, and how the units connect at their interfaces — but it does NOT contain the bodies. Implementation text (the `.c` file equivalent) is owned downstream by Plan and Implement; architecture decisions (the spec the manifest realizes) are owned upstream by Design; phase boundaries and slice authoring (which units belong to *this* manifest at all) are owned by Phasing.

The OWNS/DEFERS contract below is the locked rule set the scope-reviewer dispatch loads at review time (Read by the `qrspi-structure-scope-reviewer` agent at runtime per its rules-loading procedure). Boundary-drift detection runs against the DEFERS list; scope-compliance runs against the OWNS list.

## Structure Altitude Boundary

### Structure OWNS

Structure OWNS:
- Unified system architecture diagram(s) for the release (Mermaid or equivalent) — stitches the components named across design.md's per-solution + cross-cutting-CD blocks into a single architectural overview
- File map: which file holds which component, directory layout, module boundaries
- Module-boundary contracts: which module exports what to which other module (the structural commitments Plan's task carving consumes)
- Cross-solution component interaction specification: how the components named in design.md's per-solution blocks interact at the system-architecture level (distinct from design.md's per-solution end-to-end flows, which are inter-actor-only inside one solution)
- Unified test architecture: a top-level `## Test Architecture` section in structure.md that names the test taxonomy for the release (e.g., unit, integration, end-to-end, smoke, contract — exact taxonomy varies by release), names the coverage boundary of each type, and enumerates the cross-cutting test invariants (drawn from CDs and goals in design.md) along with which test type owns each invariant
- Per-type stitching of per-solution acceptance criteria: for each type in the test taxonomy, enumerate which per-solution `Acceptance` subsections from design.md (per goal + per CD) feed into that test type — naming the design.md source by goal/CD identifier

### Structure DEFERS

Structure DEFERS:
- Per-solution choice rationale or alternatives weighed (Design's job — Structure consumes the locked solution, does not re-litigate it)
- Per-task assertions / unit-test code (Plan/Implement's job — Structure names the test taxonomy and per-type coverage boundary; Plan authors the per-task `Test Expectations` against the taxonomy; Implement writes the test code)
- Per-solution end-to-end flows or per-solution sequence diagrams (Design's job — Structure shows components at the architectural level, not per-solution choreography)
- External-system contracts or vendor research (Design's job — Structure consumes the cited answers, does not re-research; Design is the last research-bearing phase)
- Detailed solution descriptions or per-solution decision rationale (Design's job — Structure stitches the locked solutions into a unified architecture; Design defines them)

A finding citing structure.md prose that asserts any DEFERS item — for example, embedding a literal compaction-callout sentence rather than just the placement site, or specifying per-task LOC inside a structure entry — is a boundary-drift finding emitted by the scope-reviewer with `change_type: scope` (per the schema in `skills/reviewer-protocol/SKILL.md`).
