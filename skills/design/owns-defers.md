**Analogy.** design.md is the **architecture brief** for the project: it states the chosen approach, the trade-offs that were weighed, the key technical decisions and their rationale, the design-level test strategy, and a high-level system diagram. It does NOT enumerate concrete implementation surfaces (DDL, full signatures, assertion text), and it does NOT author phasing decisions (which slices belong in which phase). Implementation surfaces are owned downstream by Plan / Implement; phasing concerns — vertical slice authoring, phase boundaries, Iron Law 1, the Phase 1 PoC guideline, replan-gate criteria — are owned by `qrspi:phasing` (see `skills/phasing/SKILL.md`).

The OWNS/DEFERS contract below is the locked rule set the scope-reviewer dispatch loads at review time (Read by the `qrspi-design-scope-reviewer` agent at runtime per its rules-loading procedure). Boundary-drift detection runs against the DEFERS list; scope-compliance runs against the OWNS list.

### Design OWNS

- **Approach selection.** Which architectural approach was chosen, stated with one claim sentence.
- **Technical trade-offs with rationale.** The 2–3 alternatives weighed, what each trades off (cost, complexity, latency, blast radius), and why the chosen approach won.
- **Test strategy at the design level.** What types of tests (unit, integration, E2E), what layers get tested, what frameworks. Behavior-level — assertion text and per-test-file layout are deferred (see DEFERS).
- **Key architectural decisions.** Major decisions made during discussion, each with reasoning grounded in goals and research findings (data-flow boundaries, persistence model, transport choice, security posture).
- **System diagram (high-level boxes/flow).** Mermaid diagram of major components, their relationships, and data flow at the architecture level. Not file/module layout — that's Structure's diagram.

### Design DEFERS

- **Full DDL** (CREATE TABLE statements, column types, NOT NULL clauses) → Plan / Implement.
- **CHECK constraints** spelled out (`CHECK (status IN ('a','b','c'))`) → Plan / Implement.
- **RLS matrices** (per-role per-table policy text) → Plan / Implement.
- **Column commentary** (per-column documentation, COMMENT ON statements) → Plan / Implement.
- **Full function signatures** with parameter types and return types — design states what a function does at the boundary, not its TypeScript/Python signature → Structure / Plan / Implement.
- **Full assertion text** (literal `expect(...).toEqual(...)` lines) → Implement (TDD).
- **Line-by-line logic** (procedural pseudocode, control-flow detail) → Plan / Implement.
- **Vertical slice authoring** (Iron Law 1 — vertical-not-horizontal slicing) → `qrspi:phasing`.
- **Phase boundaries and replan gates** (Phase 1 PoC guideline — prove the full stack end-to-end when possible; replan-gate criteria) → `qrspi:phasing`.
- **roadmap.md** (goal-to-phase assignment table) → `qrspi:phasing`.

**Phasing pointer.** Phasing concerns (vertical slices, phase boundaries, Iron Law 1, the Phase 1 PoC guideline) are owned by `qrspi:phasing` — see `skills/phasing/SKILL.md`.

A finding citing design.md prose that asserts any DEFERS item — for example, embedding a CREATE TABLE block, listing a CHECK constraint inline, pasting a literal function signature, or authoring a phase split — is a boundary-drift finding emitted by the scope-reviewer with `change_type: scope` (per the schema in `skills/reviewer-protocol/SKILL.md`).
