This is the locked rule set the scope-reviewer dispatch loads at review time (Read by the `qrspi-phasing-scope-reviewer` agent at runtime per its rules-loading procedure). Boundary-drift findings dispatch off the DEFERS list; scope-compliance dispatches off the OWNS list.

### Phasing OWNS

- **Vertical-slice authoring** — enumerate end-to-end demonstrable delivery units in `phasing.md` `## Slices`. **Iron Law 1 applies** (see below).
- **Phase boundaries** — group slices into phases with explicit replan-gate criteria per phase, captured in `phasing.md` `## Phases`. **The Phase 1 PoC guideline applies** (see below).
- **roadmap.md authoring** — canonical phase → slice → goal-ID mapping table. Roadmap is the source of truth for which goals belong to which phase via which slice; downstream skills (Structure, Plan, Replan) read from it.
- **Current-phase pruning of four synthesizing artifacts** — split goals.md, questions.md, research/summary.md, and design.md into current-phase content (kept in place) and deferred content (moved to `future-goals.md`, `future-questions.md`, `future-research-summary.md`, `future-design.md`). Individual `research/q*.md` files are NOT split — they remain as full-corpus reference so the summary's Q-attribution links continue to resolve.
- **Future-* artifact maintenance** — `future-goals.md`, `future-questions.md`, `future-research-summary.md`, `future-design.md` are created and updated each Phasing run; consumed by Replan during between-phase transitions.
- **Goal-ID consistency validation** — every goal ID appearing in any of the nine target files (goals.md, questions.md, research/summary.md, design.md, future-goals.md, future-questions.md, future-research-summary.md, future-design.md, roadmap.md) must trace to the canonical roadmap.md set. Orphan IDs flagged for user review.

### Phasing DEFERS

- **Architecture, key decisions, system diagram, test strategy** → owned by Design. Phasing consumes design.md; it does NOT re-litigate architectural choices.
- **File paths, module boundaries, interface contracts, file maps** → owned by Structure. Phasing names slices and phases; it does NOT enumerate files or function signatures.
- **Task specs, LOC estimates, ordered task lists, per-task test expectations** → owned by Plan. Phasing produces the input Plan reads from (slice list + phase grouping); it does NOT write task specs.
- **Dependency graph, Wave decisions, branch maps** → owned by Parallelize.
- **Implementation prose, code, hook syntax, subagent dispatch verbs** → owned by Implement and downstream skills. Skill-implementation jargon is a boundary-drift signal in phasing.md.
