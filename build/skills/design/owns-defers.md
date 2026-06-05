**Analogy.** design.md is the **architecture brief** for the project: it states the chosen approach, the trade-offs that were weighed, the key technical decisions and their rationale, the design-level test strategy, and a high-level system diagram. It does NOT enumerate concrete implementation surfaces (DDL, full signatures, assertion text), and it does NOT author phasing decisions (which slices belong in which phase). Implementation surfaces are owned downstream by Plan / Implement; phasing concerns — vertical slice authoring, phase boundaries, Iron Law 1, the Phase 1 PoC guideline, replan-gate criteria — are owned by `qrspi:phasing` (see `skills/phasing/SKILL.md`).

The OWNS/DEFERS contract below is the locked rule set the scope-reviewer dispatch loads at review time (Read by the `qrspi-design-scope-reviewer` agent at runtime per its rules-loading procedure). Boundary-drift detection runs against the DEFERS list; scope-compliance runs against the OWNS list.

## Design Altitude Boundary

### Design OWNS

Design OWNS:
- Per-goal outcome statements (the end-state being targeted)
- Per-goal solution definitions at outcome altitude including: detailed descriptions of the solutions with full edge cases, end-to-end flows specifying actor sequence and per-step inputs/outputs, prompt-writing specifics (the actual prose a SKILL or agent file will carry, paraphrased or verbatim when load-bearing), acceptance criteria including concrete examples and rough test-pairing shapes (e.g., "one bats file per script under `scripts/`"; naming the shape is acceptance-criteria-altitude — authoring the test code is Plan/Implement's job)
- Cross-Goal Decisions (CDs) that establish vocabulary, named architectural components by purpose, and cross-cutting invariants
- Per-solution diagrams (zero or more per goal block or per cross-cutting CD block) when they aid comprehension of that specific solution — Mermaid sequence diagrams for per-solution end-to-end flows, or Mermaid flowcharts for branch-heavy per-solution control flow. NOT a unified system-wide architecture diagram across goals/CDs (Structure's job).
- Test Strategy at the per-solution altitude: each goal/CD block carries its own Acceptance subsection with concrete examples and rough test-pairing shapes; design.md does NOT carry a top-level Test Strategy section stitching acceptance criteria across goals (Structure's job).
- Naming and renames that establish cross-skill vocabulary (rename inventory blocks)
- Phasing/release-assignment phrases that name which goal/CD ships in which release (operator-authoritative; phasing.md is the canonical artifact but design.md may carry the labels inline for self-host reasoning)

### Design DEFERS

Design DEFERS:
- Function bodies (procedural code blocks with executable logic — full implementations belong in Implement)
- Full unit-test code (specific assertion text, fixture file contents, test scaffolding — belongs in Plan/Implement; Design names the test type and rough shape only)
- Executable shell beyond a few illustrative lines (a 2-3 line block illustrating shape is fine; a 20-line script body is not)
- File architecture (which file holds which component, directory layout, module boundary lines — Structure's job)
- Unified system-wide architecture diagrams that stitch components across goals/CDs into a single architectural overview (Structure's job; per-solution diagrams inside a single goal/CD block remain in Design's OWNS)
- Unified Test Strategy / Test Architecture section that stitches per-solution acceptance criteria from individual goal/CD blocks into a release-wide test plan, names cross-cutting test invariants by type, or enumerates the release's test taxonomy (Structure's job; per-solution Acceptance subsections inside individual goal/CD blocks remain in Design's OWNS)
- Task carving (per-task LOC budgets, per-task dependency graphs, per-task test-case enumeration — Plan's job)

**Phasing pointer.** Phasing concerns (vertical slices, phase boundaries, Iron Law 1, the Phase 1 PoC guideline) are owned by `qrspi:phasing` — see `skills/phasing/SKILL.md`.

A finding citing design.md prose that asserts any DEFERS item from the included contract above is a boundary-drift finding emitted by the scope-reviewer with `change_type: scope` (per the schema in `skills/reviewer-protocol/SKILL.md`).
