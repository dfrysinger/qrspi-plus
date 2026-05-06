This is the locked rule set the scope-reviewer dispatch consumes (Read by the `qrspi-parallelize-scope-reviewer` agent at runtime per its rules-loading procedure). Boundary-drift findings dispatch off the DEFERS list; scope-compliance dispatches off the OWNS list.

### Parallelize OWNS

- The dependency graph between current-phase tasks (logical task-to-task dependencies recorded in the Dependency Analysis table).
- File-overlap analysis across tasks (the file-disjointness check that distinguishes Waves from collisions inside a Wave).
- Wave membership and Wave bases, the Wave dependency graph, the symbolic Branch Map, and the Stage Commits table when multi-parent dependencies require stage commits.
- The Mermaid dependency graph rendered into `parallelization.md`.
- The Execution Mode decision (sequential / parallel / hybrid) with one-sentence rationale.

### Parallelize DEFERS

- Task specs themselves (acceptance tests, dependencies-list, LOC estimate, description) — owned by Plan (`plan.md` + `tasks/*.md`). Parallelize consumes these as inputs and MUST NOT rewrite them.
- Per-task implementation logic (how a task achieves its goal; the actual code, test assertions, file edits) — owned by Implement (per-task TDD + review flow — see `implement/SKILL.md` § Per-Task Execution).
- Architecture decisions and trade-offs (which approach the project takes; why a slice exists) — owned by Design.
- Phasing decisions, vertical slices, Iron Law 1 rationale, the Phase 1 PoC guideline, roadmap maintenance — owned by Phasing.
- Concrete commit hashes, branch creation, worktree creation, baseline tests, runtime-injected `task-00` — owned by Implement at runtime; Parallelize records only symbolic bases.
- `review_depth` / `review_mode` / other runtime-only review configuration — owned by Implement (written into `config.md` at phase start).
