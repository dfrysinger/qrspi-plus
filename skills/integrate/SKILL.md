---
name: integrate
description: Use when all current-phase tasks are implemented — merges task branches, runs cross-task integration review, security review, and CI gate
---

# Integrate (QRSPI Step 9)

**PRECONDITION:** Invoke `qrspi:using-qrspi` skill to ensure global pipeline rules are in context. (Idempotent on session re-entry. Subagents are exempt — SUBAGENT-STOP in using-qrspi handles that.)

**Announce at start:** "I'm using the QRSPI Integrate skill to verify cross-task integration and run CI."

## Overview

Post-merge cross-task review. Verifies tasks work together, checks cross-task security, runs CI pipeline. Only in the full pipeline route — quick fix mode skips entirely (single task, nothing to integrate). Orchestrator in main conversation.

## When This Runs

```
ONCE PER PHASE — NOT ONCE PER TASK
```

Integrate fires only after Implement's batch gate releases. The canonical contract for the loop, batch-gate definition (including all release conditions: clean / accepted-with-issues / skipped-by-user), and the `current_step` transition mechanism lives in `implement/SKILL.md` → "Implement Is the Per-Phase Orchestration Loop". This skill does not restate that contract; consult Implement if any question arises about *when* Integrate is allowed to start.

If you find yourself reaching for Integrate after a single task finishes, stop. Per-task correctness is the responsibility of the reviewers the per-task orchestrator already ran. Cross-task and cross-cutting verification is what Integrate adds — and that signal is meaningless until every task in the phase is on the table.

Common misreads to avoid:
- "T01 just finished clean, let's Integrate it now" — no. Implement (orchestrator) fires the next per-task subagent.
- "`state.json` shows `current_step: implement` and the active task is done" — see `implement/SKILL.md` → "State Transition Contract" under "Implement Is the Per-Phase Orchestration Loop".
- "I'll integrate every couple of tasks to keep things tidy" — no. The CI gate, security review, and cross-task review are designed for one comprehensive pass per phase.

## Iron Law

```
NO CI PUSH WITHOUT INTEGRATION REVIEW
```

## Prompt Templates

```
integrate/
├── SKILL.md
└── templates/
    ├── integration-reviewer.md
    └── security-integration-reviewer.md
```

## Artifact Gating

Required inputs:

- All current-phase task review files in `reviews/tasks/`
- Task branches (and any stage commits Implement created) ready to merge
- `design.md` with `status: approved` (for cross-task context)
- `structure.md` with `status: approved` (for interface definitions)
- `parallelization.md` with `status: approved` (for branch map — which branches to merge)
- `config.md` (for `route` — determines which skill to invoke after integrate; for `codex_reviews` — determines whether Codex runs alongside Claude reviewers)

If any required artifact is missing or not approved, refuse to run and tell the user which artifact is needed.

### Config Validation

Apply the **Config Validation Procedure** in `using-qrspi/SKILL.md`. Integrate validates `route` and `codex_reviews`.

<HARD-GATE>
Do NOT push to CI or approve integration without running integration and security reviews on the merged code.
Do NOT push to CI without user approval of integration review results.
Do NOT write production code fixes directly — route all fixes through Implement → Integrate. Parallelize is not invoked for fix-task batches; Implement appends new branch entries to `parallelization.md` per its Fix Task Routing rules (see `implement/SKILL.md` → "Fix Task Routing").
This applies regardless of how simple the fix appears.
</HARD-GATE>

## Merge Strategy

`parallelization.md` lists every task branch (with symbolic bases per `parallelize/SKILL.md`'s Branch Model). Implement creates any stage commits between groups at runtime; Integrate merges in this order:

1. **Sequential chains: merge the leaf only.** When tasks form a sequential chain (task-N forks from task-(N-1)'s tip), task-N's branch already contains every ancestor's commits. Merging the leaf brings the entire chain in via fast-forward or a single merge commit; merging each member individually is redundant and produces noisy history.
2. **Parallel groups: merge each leaf.** When a parallel group has independent leaves (no downstream task depends on more than one of them), merge each leaf into the feature branch in dependency order. Git's merge-base resolution handles any shared ancestors automatically.
3. **Hybrid with stage commits: merge leaves only; stage commits flow in transitively.** Each leaf descends from the stage commit it forked from, so merging the leaf brings the stage commit's ancestry along. **Do not merge stage branches directly** — they are scratch infrastructure Implement created for downstream forks; merging them separately produces duplicate history with the leaves and increases the chance of spurious conflicts.
4. **Conflict-free invariant.** Because parallel-group members are file-disjoint by construction (Parallelize's analysis enforces no file overlap, and Implement re-verifies at runtime) and sequential dependencies are linear, the merge sequence above should be conflict-free. If it isn't, a parallelization-plan invariant was violated upstream — STOP and present the conflict to the user with file-level details rather than auto-resolving.

After all task-branch merges complete, delete the stage branches (`qrspi/{slug}/stage-after-G*`) since they have no further role; the feature branch tip now contains everything.

## Process Steps

1. **Merge task branches** into the feature branch using `parallelization.md` branch map and the Merge Strategy above (leaf-only for chains; each leaf for parallel groups; never merge stage branches directly). **STOP if merge conflicts** — present conflicts to user with file-level details. Do not attempt auto-resolution.
2. **Integration reviews** — follows **Review Pattern 2 (Outer Loop)**. Run both Claude reviewers (integration-reviewer + security-integration-reviewer) in parallel. If `codex_reviews: true`, dispatch `codex:rescue` once per template (2 calls total, one per template) in parallel with the Claude reviewers, passing the same template + the merged code + `design.md`/`structure.md` for cross-reference. Merge findings into `reviews/integration/round-NN-review.md` — Claude findings under each reviewer's `## Integration Review` / `## Security Integration Review` heading, Codex findings appended under `### Codex` subsections beneath each. Present to user regardless of outcome.
   - **Clean:** User chooses: re-run reviews (confidence check), continue to CI gate, or stop.
   - **Issues found:** Converge on unchanged code (up to 3 rounds to build complete issue list), then present converged list. User chooses: dispatch fix tasks, re-run reviews, accept and continue, or stop.
3. **Fix task dispatch:** Write fix tasks to `fixes/integration-round-NN/`. Each fix task includes:
   - The specific integration issue(s) to fix (with `file:line` references from reviewers)
   - The `pipeline: full` field (integration fixes are cross-task by definition)
   - References to the affected task specs for context
   Route through Implement → back to Integrate. (Parallelize is not invoked for fix-task batches — Implement appends new branch entries to `parallelization.md` per its Fix Task Routing rules.) After fixes return, re-run from step 1 (merge fix branches, then re-run reviews).

## CI Pipeline Gate (Sub-Gate Within Integrate)

1. Push branch, trigger CI (GitHub Actions or equivalent)
2. Wait for results: tests, linting, security scanning, build
3. If failures: present to user. User chooses: dispatch fix tasks, accept, or stop.
4. Write fix tasks to `fixes/ci-round-NN/`. Fix tasks include the **specific CI check/test that must pass** in the task spec. The implementer fixes the issue AND verifies the CI check passes locally before returning. Reviewers also verify it passes.
5. Fix tasks route through Implement → back to Integrate → re-run CI. If CI still fails, present to user again (no cycle counting — user is in the loop each time).
6. If no CI pipeline exists, skip this gate entirely.

## Fix Task File Format

```markdown
---
status: approved
task: NN
phase: {current phase}
pipeline: full
fix_type: integration
---

# Integration Fix NN: {description}

- **Files:** {exact paths from reviewer findings}
- **Dependencies:** none
- **LOC estimate:** ~{N}
- **Description:** {what the integration issue is and how to fix it}
- **Integration issue:** {file:line references from reviewer}
- **Test expectations:**
  - {specific integration behavior that must work after fix}
  - {existing tests that must still pass}
```

## CI Fix Task File Format

```markdown
---
status: approved
task: NN
phase: {current phase}
pipeline: full
fix_type: ci
---

# CI Fix NN: {description}

- **Files:** {exact paths from CI failure output}
- **Dependencies:** none
- **LOC estimate:** ~{N}
- **Description:** {what the CI failure is and how to fix it}
- **CI check to pass:** {specific check name, test name, or build step that must pass}
- **Test expectations:**
  - {the specific CI check listed above must pass locally before returning}
  - {all existing tests must still pass}
```

## Artifacts

- `reviews/integration/round-NN-review.md` — integration review findings per round (both integration reviewer and security integration reviewer findings, attributed separately with `## Integration Review` and `## Security Integration Review` headers)
- `reviews/ci/round-NN-review.md` — CI failure analysis per round

## Human Gate

Present integration review results (clean or converged issue list) to user after each review round. Present CI results to user after each CI run. User must approve or choose an action (dispatch fixes, re-run reviews, accept, stop) at each gate before the pipeline advances. On rejection, write the user's feedback to `feedback/integrate-round-{NN}.md` (using the standard feedback file format from `using-qrspi`).

## Phase Learnings Gate

At the integration review human gate, after presenting review results and before invoking the terminal state, ask the user:

> "Before we proceed: do you have any phase learnings or ideas for future phases?
> - **Current-phase items** (things to fix now, constraints found): discuss these in conversation — we'll handle them before moving on.
> - **Future work ideas** (new features, improvements for later phases): these will be appended to `future-goals.md` Ideas section.
> (Press Enter to skip.)"

If the user provides **future work ideas**: append as bullet points under `## Ideas` in `future-goals.md` in the artifact directory. If `## Ideas` section does not exist, create it.

If the user provides **current-phase items**: discuss in conversation and resolve before proceeding.

If the user presses Enter or provides no input: skip silently.

## Terminal State

Recommend compaction: "Integration complete. This is a good point to compact context before the next step (`/compact`)."

**REQUIRED:** Invoke the next skill in the `config.md` route after `integrate`.

## Model Selection Guidance

| Task complexity | Recommended model |
|-----------------|-------------------|
| Integration reviewer dispatch | Most capable (opus) — cross-task reasoning |
| Security integration reviewer dispatch | Most capable (opus) — security analysis |
| Fix task writing | Standard (sonnet) — translating findings to task specs |

## Task Tracking (TodoWrite)

Create granular tasks for each step:

1. Merge task branches
2. Run integration reviewer
3. Run security integration reviewer
4. Present review results to user
5. Dispatch fix tasks (if needed)
6. Push to CI (if CI exists)
7. Handle CI results

Mark each task in_progress when starting, completed when done.

## Red Flags — STOP

- Merging branches without checking for conflicts first
- Auto-resolving merge conflicts without presenting to user
- Writing code fixes directly instead of routing through the fix pipeline
- Skipping security integration review because "integration review was clean"
- Pushing to CI without user approval of integration review results
- Accepting CI failures without user confirmation
- Re-running CI without fixing the failures first (deterministic — same code = same result)

## Common Rationalizations — STOP

| Rationalization | Reality |
|----------------|---------|
| "The merge conflicts are trivial, I can resolve them" | Present all conflicts to the user — trivial conflicts can mask semantic issues |
| "Integration review was clean, skip security" | Security issues are a different class — integration correctness doesn't imply security correctness |
| "This fix is one line, I can patch it directly" | All production code goes through Implement with reviews — that's the invariant |
| "CI is flaky, just re-run it" | Investigate the failure first. If truly flaky, present to user and let them decide |
| "No CI exists, so integration is done" | CI is one gate. Integration and security reviews are the primary gates — those still run |

## Worked Example — Good Integration Review Finding

```markdown
## Integration Review — Round 1

### Issue 1: Interface mismatch between Task 2 and Task 3
**Severity:** High
**Files:**
- `src/services/box-service.ts:45` — `createBox()` returns `Box`
- `src/api/routes/invitations.ts:23` — expects `createBox()` to return `Promise<Box>`

**Description:** Task 2 implemented `createBox()` as synchronous (returns `Box` directly), but Task 3's invitation flow calls it with `await`. The call won't fail (awaiting a non-promise resolves immediately), but the return type mismatch will cause TypeScript compilation errors if strict mode is enabled, and the synchronous DB call will block the event loop.

**Recommendation:** `createBox()` should be async — it performs a database write which should not be synchronous.
```

## Worked Example — Bad (Vague Finding)

```markdown
## Integration Review — Round 1

### Issue 1: Tasks don't work together
The box service and invitation service have some integration issues that should be fixed.
```

**Why this fails:** no `file:line` references so the implementer can't locate the issue; "some integration issues" is not actionable; no severity classification, no specific description, no fix recommendation.

## Iron Laws — Final Reminder

The three override-critical rules for Integrate, restated at end:

1. **NO CI PUSH WITHOUT INTEGRATION REVIEW.** Both integration-reviewer AND security-integration-reviewer must run on the merged code, and their results must reach the human gate before pushing.

2. **ONCE PER PHASE, NEVER PER TASK.** Integrate fires only after Implement's batch gate releases. The cross-task signal is meaningless until every task in the phase is on the table.

3. **No production code fixes from Integrate.** All fixes route through Implement → back to Integrate. Writing code directly here bypasses the per-task TDD/review pipeline and breaks the invariant.

Behavioral directives D1-D3 apply — see `using-qrspi/SKILL.md` → "BEHAVIORAL-DIRECTIVES".
