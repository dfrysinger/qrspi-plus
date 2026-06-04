**Analogy.** structure.md is the **C-header file** / **system manifest** for the project: it declares what gets built, where each unit lives, and how the units connect at their interfaces — but it does NOT contain the bodies. Implementation text (the `.c` file equivalent) is owned downstream by Plan and Implement; architecture decisions (the spec the manifest realizes) are owned upstream by Design; phase boundaries and slice authoring (which units belong to *this* manifest at all) are owned by Phasing.

The OWNS/DEFERS contract below is the locked rule set the scope-reviewer dispatch loads at review time (Read by the `qrspi-structure-scope-reviewer` agent at runtime per its rules-loading procedure). Boundary-drift detection runs against the DEFERS list; scope-compliance runs against the OWNS list.

### Structure OWNS

- **File paths and module boundaries.** Concrete repo-relative paths for every file the project creates or modifies, grouped by vertical slice. No directory placeholders, no "various", no "TBD".
- **Section-list contracts per file.** Which top-level sections each file must contain (e.g., for a SKILL.md: `## Overview`, `## Process`, `## Red Flags`); which named blocks live where. Heading-level granularity, not prose content.
- **Function/script exports and parameter shapes.** Public function signatures, exported types, script entry points, CLI argument shapes — what the unit exposes at its boundary.
- **Inter-file dependencies.** Which files import/consume which other files; consumer-producer edges between modules; data-flow direction.
- **Cross-cutting hook-point locations.** The *places* where hooks fire across files (e.g., the four compaction-callout placement sites per skill — which sections of which files they live in) — locations only, never the text.
- **Test file layout (behavior level).** Which test files exist, the behavior each test file exercises at a one-line description level. Not assertion code, not assertion text, not commit ranges.
- **Architectural diagram.** Mermaid diagram of file/module relationships, API endpoints, data flow, interface boundaries.

### Structure DEFERS

- **Actual prompt or SKILL.md text content** → Plan / Implement.
- **Actual reviewer-protocol or agent-file body content** → `skills/reviewer-protocol/SKILL.md` and `agents/qrspi-*.md`. (structure.md must not paste reviewer infrastructure prose; the protocol lives in the dedicated skill, agent bodies live in agent files.)
- **Actual compaction-callout wording at each placement site** (Structure owns the *locations*; Plan/Implement own the *words*) → Plan / Implement.
- **Test assertion code** → Implement (TDD).
- **Per-task LOC, full assertion text, per-task commit ranges, line-by-line logic** → Plan / Implement.
- **Architecture decisions** (which approach, which components exist at all) → Design.
- **Phasing / vertical slice authoring** (Iron Law 1, the Phase 1 PoC guideline, which slices belong in this phase, replan-gate criteria) → Phasing.

A finding citing structure.md prose that asserts any DEFERS item — for example, embedding a literal compaction-callout sentence rather than just the placement site, or specifying per-task LOC inside a structure entry — is a boundary-drift finding emitted by the scope-reviewer with `change_type: scope` (per the schema in `skills/reviewer-protocol/SKILL.md`).
