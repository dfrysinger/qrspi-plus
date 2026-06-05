---
status: approved
task: 13
phase: 1
pipeline: full
goal_ids: [G9]
task_type: code
model: opus
---

# Task 13: G9 per-task review orchestration fires scope-tagger, `round-NN.diff`, and `round-NN-commit.txt` artifacts

- **Target files:** scripts/round-prepare.sh (modify), skills/implement/SKILL.md (modify), tests/unit/test-scope-tagger-dispatch.bats (modify)
- **Dependencies:** Task 12. **Blocks:** T20 (G3 dispatch-script rename consumes this task's `scripts/round-prepare.sh` per-task scope-tagger + commit-anchor edits).
- **LOC estimate:** ~120

**Overview**

Make per-task review rounds leave the durable bookkeeping required for the next reviewer dispatch: scope-set emission, per-round diff emission, and commit-anchor capture with loud recovery-coded failures when the sequence is missing or malformed. This is a G9 hardening task layered on top of the Task 12/G4 round-preparation helper so the orchestrator keeps first-party Task dispatch in main chat while deterministic scripts enforce file-state invariants. (Why: see goals.md ### G9. Approach: see design.md ## G9.)

**Scope**

- **In:**
  - Extend `scripts/round-prepare.sh` per-task behavior so task-branch mode writes `round-NN-commit.txt` with the passed implementer SHA plus trailing newline, emits `round-NN.diff` through the canonical preparation path, and fails with distinct documented recovery codes for missing SHA, worktree/self-reported SHA mismatch, and non-advanced implementer SHA.
  - Add prior-round loud-failure checks in `round-prepare.sh` for missing or malformed `round-(NN-1)-commit.txt`, and for missing or empty `round-(NN-1)-scope-set.txt` when later-round narrowing is eligible and scope tagging is enabled.
  - Insert the G9 between-round checklist into `skills/implement/SKILL.md` at the per-task reviewer fan-out site, covering scope-tagger dispatch, implementer `commit_sha:` extraction, `dispatch-agent.sh --implementer-commit` invocation, and exit-code branches for success, orchestrator bug, worktree integrity break, and implementer re-dispatch.
  - Update `tests/unit/test-scope-tagger-dispatch.bats` to prove scope-tagger dispatch against kept finding files, sibling `round-NN-scope-set.txt` artifact creation, commit-anchor writing, per-round diff production, and the grep-style guard that scripts do not dispatch first-party Task-tool subagents or capture Task-tool return values.

- **Out:**
  - Creating the canonical `round-prepare.sh` / `await-round.sh` helper scaffolding and the general G4 diff/ref-selection behavior — T12 owns.
  - Artifact-level review-loop orchestration in `using-qrspi/SKILL.md` Standard Review Loop — explicitly out of G9 per design.md ## G9.
  - Moving first-party Task-tool subagent dispatch or Task-tool return capture into bash scripts — main chat remains the owner of those actions.

**Definition of done**

- `round-prepare.sh` writes `round-NN-commit.txt` containing exactly the passed implementer SHA plus a trailing newline when task-branch mode receives a fresh SHA matching the worktree HEAD.
- `round-prepare.sh` preserves canonical `round-NN.diff` emission in task-branch mode.
- `round-prepare.sh` exits with distinct documented recovery codes for missing implementer SHA, implementer SHA not matching worktree HEAD, and implementer SHA not advancing beyond the prior round anchor.
- Round-one non-advance detection compares against the task base commit and names that base condition in the diagnostic instead of referencing a prior round anchor.
- Later-round preparation fails loudly when the prior `round-(NN-1)-commit.txt` file is missing or malformed.
- Narrowing-eligible later-round preparation with scope tagging enabled fails loudly when the prior `round-(NN-1)-scope-set.txt` file is missing or empty.
- `skills/implement/SKILL.md` contains the between-round checklist in the per-task reviewer fan-out section and no longer tells main chat to run its own worktree HEAD comparison there.
- Unit coverage proves scope-tagger dispatch produces sibling `round-NN-scope-set.txt` artifacts for reviewed rounds and scripts do not dispatch first-party Task-tool subagents or capture Task-tool returns.

**Test expectations**

- Bats fixture: happy-path task-branch invocation writes `round-NN-commit.txt` with the passed SHA and trailing newline when that SHA matches worktree HEAD and advances past the prior anchor.
- Bats fixtures: missing implementer SHA, mismatched worktree HEAD, unadvanced later-round SHA, and unadvanced round-one task-base SHA each return the documented distinct recovery code and diagnostic language.
- Bats fixtures: later-round invocation fails loudly for missing or malformed `round-(NN-1)-commit.txt`; narrowing-eligible later-round invocation with scope tagging enabled fails loudly for missing or empty `round-(NN-1)-scope-set.txt`.
- Bats or file assertions: task-branch mode still emits `round-NN.diff` through the inherited canonical preparation path.
- Grep audit on `skills/implement/SKILL.md`: the per-task reviewer fan-out section contains the checklist items for scope-tagger dispatch, implementer `commit_sha:` extraction, `dispatch-agent.sh --implementer-commit`, and exit-code branches 0/10/11/12.
- Grep audit on `skills/implement/SKILL.md`: the per-task review section no longer contains main-chat-side `rev-parse HEAD` comparison instructions; the residual responsibility is reading the implementer SHA, passing it to the dispatcher, and branching on script exit code.
- Unit assertion: `qrspi-scope-tagger` is dispatched against kept finding files between rounds and writes `round-NN-scope-set.txt` as a sibling artifact for every reviewed round.
- Grep-style script guard: `scripts/` contains no first-party Task-tool subagent dispatch or direct Task-tool return capture patterns.

**References**

- goals.md ### G9 — problem framing for silent per-task review-loop drift and missing scope-set / commit-anchor / diff artifacts.
- design.md ## G9 — four-layer per-task arrangement, between-round checklist, out-of-scope artifact-level boundary, and acceptance criteria.
- structure.md ### `scripts/round-prepare.sh` — G9 Slice 1.3 per-file block for per-task SHA checks, commit-anchor write, prior-artifact assertions, and diff inheritance.
- structure.md ### `skills/implement/SKILL.md` — G9 Slice 1.3 per-file block for the between-round checklist insertion and main-chat residual narrowing.
- structure.md ### `tests/unit/test-scope-tagger-dispatch.bats` — G9 Slice 1.3 per-file block for scope-tagger dispatch, scope-set artifact, commit-anchor, and diff tests.
