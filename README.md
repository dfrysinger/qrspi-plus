# qrspi-plus

**A structured agentic development pipeline for Claude Code.**

qrspi-plus is a Claude Code plugin that implements QRSPI — a methodology for agentic software development where every phase produces a reviewable artifact, gets human approval, and runs in isolated context. Based on Human Layer's QRSPI framework, extended with worktree parallelization, tiered code reviews, integration verification, acceptance testing, and between-phase replanning.

---

## Pipeline Overview

```mermaid
flowchart TD
    subgraph alignment["Alignment (Goals through Plan)"]
        Goals[Goals] --> Questions[Questions]
        Questions --> Research[Research]
        Research --> Design[Design]
        Design --> Structure[Structure]
        Structure --> Plan[Plan]
    end
    subgraph execution["Execution (Worktree through Test)"]
        Worktree[Worktree] --> Implement[Implement]
        Implement --> Integrate[Integrate]
        Integrate --> Test[Test]
        Test --> PR[Create PR]
        PR -->|more phases| Replan[Replan]
        Replan -->|next phase| Worktree
    end
    Plan --> Worktree
    PR -->|last phase| Done((Done))
    Integrate -.->|fix tasks| Worktree
    Test -.->|fix tasks full| Worktree
    Test -.->|fix tasks quick| Implement
```

The pipeline has two route variants:

**Full pipeline** -- for features, new products, and anything requiring architectural design:

```mermaid
flowchart LR
    G[Goals] --> Q[Questions]
    Q --> R[Research]
    R --> D[Design]
    D --> S[Structure]
    S --> P[Plan]
    P --> W[Worktree]
    W --> I[Implement]
    I --> Int[Integrate]
    Int --> T[Test]
    T --> PR[PR]
    PR -->|more phases| Re[Replan]
    Re --> W
    PR -->|final| Done((Done))
```

**Quick fix** -- for targeted bug fixes, small changes, and 1-3 file modifications. Skips Design, Structure, Worktree, and Integrate. Plan produces a single task.

```mermaid
flowchart LR
    G[Goals] --> Q[Questions]
    Q --> R[Research]
    R --> P[Plan]
    P --> I[Implement]
    I --> T[Test]
    T --> PR[PR]
    PR --> Done((Done))
```

### Route Changes

Route changes are allowed before Plan executes:

- **Full to Quick Fix:** Drop Design, Structure, Worktree, Integrate from the route.
- **Quick Fix to Full:** Insert Design, Structure before Plan, and Worktree, Integrate after Plan.

After Plan is approved, the route is locked. Changing it after that point requires a backward loop to re-run Plan.

---

## How It Works

**Tiered human review at every stage.** Each step produces a focused artifact that humans review, but the review depth varies by artifact type:

- **Goals, Questions, Research, Design** -- closely reviewed by the human. These are the alignment artifacts that determine whether the right thing gets built.
- **Structure, Plan, Tasks** -- spot-checked by the human. The detail is too dense to read line by line, but the human reviews the overall approach and catches structural issues.
- **Code** -- reviewed by the human during the Test step before the PR is created. The pipeline produces heavily commented, well-structured code designed to be reviewable in a standard code review.

**Human approval gates between steps.** Every artifact is presented to the user for approval before the pipeline advances. Rejection captures feedback and re-generates the artifact in a fresh subagent with the feedback included. No artifact is silently mutated.

**Fresh subagent per step.** Each step runs in a clean subagent with only its declared inputs. No context accumulation, no "dumb zone." Subagent boundaries are compaction boundaries -- every step gets clean context, guaranteed.

**Structural enforcement over instructional discipline.** Where possible, constraints are enforced architecturally. Research agents never see the goals document (prevents confirmation bias). Implement cannot write production code without a failing test. Review patterns are codified, not suggested.

**Hook-based deterministic enforcement.** Pipeline rules that were previously prompt-instructed are now code-enforced via Claude Code hooks that run on every tool call:

- **Pipeline step ordering:** The PreToolUse hook blocks artifact writes that skip prerequisites. You cannot write `design.md` before `goals.md` is approved -- the hook rejects the tool call with an actionable error message.
- **Task boundary enforcement:** In strict mode, the PreToolUse hook blocks file writes outside the active task's allowlist, preventing scope creep during implementation.
- **Audit logging:** The PostToolUse hook logs all Write, Edit, and Bash calls to per-task JSONL files for traceability.
- **Fail-closed security model:** All error paths in the hooks block with actionable messages rather than silently allowing violations.
- **State management:** `.qrspi/state.json` tracks pipeline progress, artifact map, and active task. `.qrspi/task-NN-runtime.json` files capture mid-task user decisions as runtime overrides.

---

## Pipeline Steps

### Step 1: Goals

Captures user intent, constraints, and acceptance criteria through interactive dialogue. The user and agent discuss purpose, constraints, success criteria, and scope. A subagent then synthesizes `goals.md` with structured acceptance criteria. This step also determines the pipeline mode (quick fix or full) and writes `config.md` with the route.

Each goal must be independently scopeable -- it can be moved between phases without surgery on other goals. Goals that bundle multiple distinct deliverables are split into separate goals with their own IDs. Late splitting is classified like any amendment (clarifying, additive, or architectural) and presented as a before/after diff.

**Artifact:** `goals.md`

```mermaid
flowchart TD
    A["Interactive dialogue\n(purpose, constraints, criteria, scope)"] --> B[Pipeline mode selection]
    B --> C[Write config.md with route]
    C --> D["Launch synthesis subagent\n(conversation content only)"]
    D --> E["Artifact Review (Pattern 4)"]
    E --> F((Approved goals.md))
```

### Step 2: Questions

Generates tagged research questions from the approved goals. Each question is tagged with a research type (`codebase`, `web`, or `hybrid`) to dispatch the right specialist agent. Questions must not leak goals or intent -- they are neutral inquiries about how things work, not what the user wants to change. This goal leakage prevention is enforced by the review subagent, which flags any question where a researcher could infer the planned changes.

**Artifact:** `questions.md`

```mermaid
flowchart TD
    A["Launch subagent\n(goals.md only)"] --> B[Generate tagged research questions]
    B --> C["Review checks for\ngoal leakage + completeness"]
    C --> D["Human gate\n(full questions presented verbatim)"]
    D --> E((Approved questions.md))
```

### Step 3: Research

Dispatches parallel specialist subagents per question. Codebase researchers read code and trace logic flows. Web researchers search for competitors, libraries, and best practices. Each specialist writes per-question findings, then a synthesis subagent produces a unified summary. Research isolation is structural: no research subagent ever receives `goals.md`. The synthesis subagent also never sees goals. If findings don't organize well without knowing the goals, that signals the questions were too vague.

**Artifact:** `research/summary.md` (plus per-question `research/q*.md` files)

```mermaid
flowchart TD
    A[Parse questions by research type] --> B[Dispatch parallel specialist subagents]
    B --> C1["Codebase agent\n(file read, grep, glob)"]
    B --> C2["Web agent\n(search, fetch)"]
    B --> C3["Hybrid agent\n(all tools)"]
    C1 --> D["q01-codebase.md"]
    C2 --> E["q02-web.md"]
    C3 --> F["q03-hybrid.md"]
    D & E & F --> G["Synthesis subagent\n(NO goals.md)"]
    G --> H["Artifact Review (Pattern 4)"]
    H --> I((Approved summary.md))
```

### Step 4: Design

Interactive design discussion in the main conversation. The agent proposes 2-3 approaches with trade-offs and a recommendation. The user and agent converge on an approach, then a subagent synthesizes the artifact. Design enforces vertical slice decomposition -- end-to-end feature slices, not horizontal layers. Phases are defined with replan gates between them. Phase 1 is always the PoC that proves the full stack works. Includes test strategy and a high-level Mermaid system diagram.

Design entries are phase-scoped: `design.md` contains only current-phase entries keyed by `### {GOAL_ID} -- {name}`. Out-of-scope entries live in `future-design.md` and are pulled in when goals are promoted.

**Artifact:** `design.md`

```mermaid
flowchart TD
    A["Interactive: propose 2-3 approaches\nwith trade-offs"] --> B[User selects approach]
    B --> C["Launch synthesis subagent\n(goals + research + discussion)"]
    C --> D["Artifact Review (Pattern 4)"]
    D --> E((Approved design.md))
```

### Step 5: Structure

Maps each vertical slice from the design to specific files and components. Defines interfaces between components (function/class signatures, not implementations), identifies create vs. modify for each file, and produces a detailed architectural diagram. The key design decision: the file-level mapping makes the gap between design and plan concrete -- downstream agents know exactly which files to touch and what interfaces to honor.

**Artifact:** `structure.md`

```mermaid
flowchart TD
    A["Launch subagent\n(goals + research + design)"] --> B["Map slices to files\n+ define interfaces"]
    B --> C[Generate Mermaid architecture diagram]
    C --> D["Artifact Review (Pattern 4)"]
    D --> E((Approved structure.md))
```

### Step 6: Plan

Breaks the structure into ordered tasks with detailed specs. Each task spec includes exact file paths, a description, test expectations in plain language (behaviors, edge cases, error conditions), dependencies, and LOC estimates. No placeholders, no TBDs, no "similar to Task N." For large plans (6+ tasks), task spec writing is farmed to sub-subagents. In quick fix mode, Plan produces a single task directly from research (no design or structure). The plan is reviewed as a single merged document by 5 specialized reviewer templates, then split into individual task files after approval.

**Artifact:** `plan.md` + `tasks/task-NN.md`

```mermaid
flowchart TD
    A["Launch overview subagent\n(goals + research + design + structure)"] --> B{6+ tasks?}
    B -->|yes| C[Farm task specs to sub-subagents]
    C --> D[Merge into single plan.md]
    B -->|no| D[Single merged plan.md]
    D --> E["Architectural Plan Review (Pattern 5)\n5 parallel reviewer templates"]
    E --> F[Human gate]
    F --> G["Split into tasks/task-NN.md\nReduce plan.md to overview"]
    G --> H((Approved plan + task files))
```

### Step 7: Worktree

Analyzes the task dependency graph for the current phase and determines the execution mode: sequential (chain dependencies), parallel (independent tasks on different files), or hybrid (mixed). Creates git worktrees forked from the feature branch, runs baseline tests, and dispatches tasks to Implement. Three execution modes ensure tasks run with maximum parallelism while respecting dependencies. If baseline tests fail, the user can auto-fix (inject a task-00), proceed with known failures, or stop.

Before dispatching subagents, Worktree writes permission settings into each worktree's `.claude/settings.json` to prevent silent stalls from approval prompts inside subagents.

```mermaid
flowchart TD
    A[Analyze task dependencies] --> B[Determine execution mode]
    B --> C[Present parallelization plan]
    C --> D{User approves?}
    D -->|no| E[Revise plan]
    E --> C
    D -->|yes| F[Create worktrees from feature branch]
    F --> G[Write subagent permissions per worktree]
    G --> H[Run baseline tests per worktree]
    H --> I{Baseline passes?}
    I -->|no| J[Present to user: auto-fix / proceed / stop]
    I -->|yes| K[Dispatch N implementation subagents]
    J -->|auto-fix| L["Inject task-00, all others depend on it"]
    L --> K
```

Example parallelization plan:

```mermaid
flowchart LR
    subgraph parallel1["Parallel Group 1"]
        T1[Task 1: Auth + profiles\nworktree: task-01]
        T2[Task 2: Box CRUD\nworktree: task-02]
    end
    subgraph sequential["Sequential"]
        T3[Task 3: Invitations\nworktree: task-03]
    end
    T1 --> T3
    T2 --> T3
```

**Artifact:** `parallelization.md`

### Step 8: Implement

TDD execution per task in an isolated worktree. The iron law: no production code without a failing test first. Write failing tests from the task spec's test expectations, verify they fail, write minimal implementation, verify they pass, self-review and commit. After implementation, reviewers run in two tiers: 4 correctness reviewers always run; 4 thoroughness reviewers run in deep mode only. Review depth is configurable per phase.

Every function gets a header comment (purpose, inputs, outputs, failure behavior). Every non-obvious conditional gets an inline "why" comment.

```mermaid
flowchart TD
    subgraph dispatch["Worktree dispatches N parallel subagents"]
        direction TB
        SA1["Subagent 1\n(Task 1 in worktree)"]
        SA2["Subagent 2\n(Task 2 in worktree)"]
        SAN["Subagent N\n(Task N in worktree)"]
    end

    subgraph pertask["Each subagent runs TDD + reviews"]
        A[Read test expectations from task spec] --> B[Write failing tests]
        B --> C[Run tests -- VERIFY FAIL]
        C --> D{Tests fail as expected?}
        D -->|no -- tests pass| E[STOP -- test is vacuous, fix it]
        E --> B
        D -->|yes| F[Write minimal implementation]
        F --> G[Run tests -- verify pass]
        G --> H{All tests pass?}
        H -->|no| I[Fix implementation -- not the test]
        I --> G
        H -->|yes| J[Self-review and commit]
        J --> K["Review fix loop (Pattern 1)"]
    end

    dispatch --> pertask

    K --> L["Batch gate\n(all tasks complete)"]
    L --> M{User decision}
    M -->|fix remaining + re-run| N[Re-enter fix cycles]
    M -->|re-run all reviews| O[Confidence check]
    M -->|continue| P((Proceed to Integrate))
```

**Reviewers:**

| Group | Reviewer | Mode |
|-------|----------|------|
| Correctness | spec-reviewer (runs first, gates the rest) | Quick + Deep |
| Correctness | code-quality-reviewer | Quick + Deep |
| Correctness | silent-failure-hunter | Quick + Deep |
| Correctness | security-reviewer | Quick + Deep |
| Thoroughness | goal-traceability-reviewer | Deep only |
| Thoroughness | test-coverage-reviewer | Deep only |
| Thoroughness | type-design-analyzer | Deep only |
| Thoroughness | code-simplifier | Deep only |

**Artifact:** `reviews/tasks/task-NN-review.md` (per-task review results with verbatim prompt/response pairs)

### Step 8.5: Integrate

Merges worktree branches into the feature branch and runs cross-task reviews. Two reviewers check integration: an integration-reviewer verifies components work together, and a security-integration-reviewer checks cross-task security boundaries. After review, pushes the branch and triggers CI. Both integration review failures and CI failures generate fix tasks that route back through the pipeline (Worktree -> Implement -> Integrate). The user is in the loop at every decision point -- dispatch fixes, re-run reviews, accept, or stop.

At the integration review human gate, the skill asks about phase learnings and future work ideas. Ideas are appended to `future-goals.md`; current-phase items are discussed before proceeding.

```mermaid
flowchart TD
    A[Merge worktree branches into feature branch] --> B{Merge conflicts?}
    B -->|yes| C[STOP -- present conflicts to user]
    B -->|no| D[Run integration + security reviewers]
    D --> D2{Issues found?}
    D2 -->|no| D3[Present clean result to user]
    D3 --> D4{User decision}
    D4 -->|re-run reviews| D
    D4 -->|continue| PL[Phase learnings gate]
    D4 -->|stop| N[Pipeline halted]
    D2 -->|yes| E[Converge: re-run on same code, up to 3 rounds]
    E --> G[Present issue list to user]
    G --> H{User decision}
    H -->|dispatch fixes| I[Write fix tasks]
    I --> J[Route to Worktree -> Implement -> Integrate]
    J --> D
    H -->|re-run reviews| D
    H -->|accept and continue| PL
    H -->|stop| N
    PL --> M{CI exists?}
    M -->|no CI| O((Integration complete))
    M -->|yes| P[Push branch, trigger CI]
    P --> Q{CI passes?}
    Q -->|yes| O
    Q -->|no| R[Present CI failures to user]
    R --> S{User decision}
    S -->|dispatch fixes| T[Write fix tasks with specific CI check]
    T --> U[Route to Worktree -> Implement -> Integrate]
    U --> P
    S -->|accept| O
    S -->|stop| N
```

**Artifact:** `reviews/integration/round-NN-review.md`, `reviews/ci/round-NN-review.md`

### Step 9: Test

Acceptance testing against the original goals. A test-writer subagent maps every acceptance criterion from `goals.md` to tests (acceptance, integration, E2E, boundary). Test code goes through its own review round. The tester can only write test files -- when tests fail, it outputs fix task descriptions, not code fixes. Fixes route back through the full pipeline so all production code changes go through reviews. Every phase produces a PR after acceptance testing passes. Phase routing happens after the PR: if this is the final phase, the pipeline is complete; if more phases remain, invoke Replan.

After tests pass and the user approves, each criterion with all mapped tests passing is automatically checked off (`- [x]`) in `goals.md`. A code review checkpoint is offered before PR creation -- the user can review all changed files or the full phase diff before proceeding.

```mermaid
flowchart TD
    A[Run full existing test suite] --> B["Launch test-writer subagent\n(goals.md + criteria mapping)"]
    B --> C["Review test code (Pattern 1)"]
    C --> CV{User approves coverage?}
    CV -->|add more tests| B
    CV -->|approved| D[Run approved test suite]
    D --> E{Test failures?}
    E -->|no| G[Present pass list to user]
    E -->|yes| F[Present pass/fail list to user]
    F --> H{User decision}
    G --> G2{User decision}
    G2 -->|approved| CK
    H -->|dispatch fixes| K[Write fix tasks]
    H -->|accept| CK
    H -->|stop| L[Pipeline halted]
    K -->|full pipeline| M[Route to Worktree -> Implement -> Integrate -> Test]
    K -->|quick fix| NN[Route to Implement -> Test]
    M --> D
    NN --> D
    CK["Update goals.md checkboxes\nfor passing criteria"] --> CR[Code review checkpoint]
    CR --> Q[Prepare PR for current phase]
    Q --> R{User confirms PR?}
    R -->|yes| S[Create PR via gh pr create]
    R -->|no| S2[Skip PR]
    S --> T{Last phase?}
    S2 --> T
    T -->|yes| U((Pipeline complete))
    T -->|no| V[Invoke Replan]
```

**Artifact:** `reviews/test/round-NN-review.md`

### Step 9.5: Replan

Runs between phases only. A subagent analyzes the completed phase for patterns, framework quirks, and architectural adjustments. Each proposed change gets a severity classification: minor changes (task spec wording, LOC estimates, add/split/merge tasks) are updated in place with a lightweight re-approval cycle. Major changes (new files, interface changes, technology switches, phase boundary changes) trigger fire-and-forget backward loops to the earliest affected artifact (Goals, Design, or Structure). Scope-unknown changes default to the most stringent treatment. On the minor path, the completed phase is archived via snapshot before promoting the next phase's goals.

Amendments found during any step are classified into three tiers: clarifying (no cascade), additive (lightweight cascade), and architectural (full backward loop). The skill recommends a classification; the user always decides.

```mermaid
flowchart TD
    A[Analyze completed phase] --> B[Identify patterns, quirks, adjustments]
    B --> C[Propose updates + severity classification]
    C --> D[Review round]
    D --> E[Present changes + severity to user]
    E --> F{User approves?}
    F -->|no| G[Revise proposals]
    G --> D
    F -->|yes, minor| H[Update tasks and plan in place]
    H --> I[Present diffs for re-approval]
    I --> J{User re-approves?}
    J -->|no| G
    J -->|yes| K[Set status: approved, commit]
    K --> K2["Snapshot phase to phases/phase-NN/"]
    K2 --> K3["Promote next phase goals\nfrom future-goals.md"]
    K3 --> M((Invoke Worktree for next phase))
    F -->|yes, major| N[Identify loop-back target]
    N --> N2[Write feedback file]
    N2 --> N3[Reset target + downstream to draft]
    N3 --> O((Invoke loop-back target -- pipeline resumes))
    F -->|scope unknown| P[Treat as Major]
    P --> N
```

**Artifact:** `reviews/replan-review.md`, `feedback/replan-phase-NN-round-MM.md`

---

## Key Concepts

### Artifact Gating

Every step checks that its required input artifacts exist on disk and have `status: approved` in their YAML frontmatter before proceeding. If an artifact is missing or unapproved, the skill refuses to run and tells the user what is needed. This prevents steps from executing with incomplete or unreviewed inputs. The gating is structural -- there is no way to bypass it without manually writing approval markers.

The gating chain builds cumulatively:

| Step | Required Approved Inputs |
|------|--------------------------|
| Goals | None (first step) |
| Questions | `goals.md` |
| Research | `questions.md` |
| Design | `goals.md`, `research/summary.md` |
| Structure | `goals.md`, `research/summary.md`, `design.md` |
| Plan | All prior artifacts (quick fix: `goals.md`, `research/summary.md` only) |
| Worktree | `plan.md`, `tasks/*.md`, `design.md`, `config.md` |
| Implement | Task file + pipeline-specific inputs (see below) |
| Integrate | Task reviews, worktree branches, `design.md`, `structure.md`, `parallelization.md` |
| Test | `goals.md`, `design.md` (full) or `research/summary.md` (quick), merged code |
| Replan | Merged phase code, `fixes/`, `reviews/`, remaining `tasks/*.md`, `plan.md`, `design.md` |

### Review Patterns

Five canonical review patterns are used across the pipeline. Every review loop must use one of these -- no ad-hoc variations.

**Pattern 1: Inner Loop** -- Autonomous per-task reviews with a batch gate at the end. Used by Implement (per-task reviews) and Test (test code reviews).

```mermaid
flowchart TD
    A[Run reviewers] --> B{Issues found?}
    B -->|no| C((Task clean))
    B -->|yes| D[Converge: re-run on same code]
    D --> E{New findings?}
    E -->|yes, under 3 rounds| D
    E -->|no or 3 rounds hit| F[Complete issue list]
    F --> G[Fix all issues]
    G --> H[Re-run reviewers on fixed code]
    H --> I{Issues found?}
    I -->|no| C
    I -->|yes, under 3 fix cycles| D
    I -->|yes, 3+ fix cycles| J((Unresolved -- flag at batch gate))
```

After all tasks complete, the batch gate presents results to the user:

```mermaid
flowchart TD
    A[Present batch summary to user] --> B{User decision}
    B -->|fix remaining + re-run reviews| C[Re-run fix cycles for unresolved tasks]
    C --> A
    B -->|re-run all reviews| D[Re-run reviewers on all tasks]
    D --> A
    B -->|continue to next step| E((Proceed))
    B -->|stop| F[Pipeline halted]
```

**Pattern 2: Outer Loop** -- User-confirmed reviews for non-deterministic reviewers. Used by integration reviews.

```mermaid
flowchart TD
    A[Run reviewers] --> B{Issues found?}
    B -->|no| C[Present clean result to user]
    B -->|yes| D[Converge: re-run on same code]
    D --> E{New findings?}
    E -->|yes, under 3 rounds| D
    E -->|no or 3 rounds hit| F[Present issue list to user]
    F --> G{User decision}
    C --> C2{User decision}
    C2 -->|re-run reviews| A
    C2 -->|continue| H((Proceed))
    C2 -->|stop| I[Pipeline halted]
    G -->|dispatch fixes| J[Write fix tasks, route through pipeline]
    G -->|re-run reviews| A
    G -->|accept| H
    G -->|stop| I
    J --> K[Fixes return]
    K --> A
```

**Pattern 3: Deterministic Results** -- For tests and CI where results don't change on re-run.

```mermaid
flowchart TD
    A[Run tests/CI] --> B{Pass?}
    B -->|yes| C[Present results to user]
    B -->|no| D[Present failures to user]
    C --> C2{User decision}
    C2 -->|continue| E((Proceed))
    C2 -->|add more tests| F[Back to test writing]
    D --> G{User decision}
    G -->|dispatch fixes| H[Write fix tasks with specific check to pass]
    H --> I[Route through pipeline]
    I --> A
    G -->|add more tests| F
    G -->|accept| E
    G -->|stop| J[Pipeline halted]
```

**Pattern 4: Artifact Synthesis Review** -- Subagent produces an artifact, autonomous review loop, then human gate. Used by Goals, Questions, Research, Design, and Structure.

```mermaid
flowchart TD
    A[Subagent produces artifact] --> B["Review round: Claude + optional Codex"]
    B --> C{Issues found?}
    C -->|no| D{Ask user: Present or Loop?}
    C -->|yes| E[Fix issues]
    E --> D
    D -->|Present| F["Human gate\n(state review status)"]
    D -->|Loop until clean| G[Review round N]
    G --> H{Clean or 10 rounds?}
    H -->|clean or cap hit| F
    H -->|issues found| I[Fix and re-review]
    I --> G
    F --> J{User approves?}
    J -->|yes| K[Write status: approved, commit]
    J -->|no| L["Capture feedback\n(verbatim + rejected snapshot)"]
    L --> M["Re-generate with new subagent\n+ all prior feedback files"]
    M --> B
```

**Pattern 5: Architectural Plan Review** -- Five specialized reviewer templates run in parallel. Used by Plan to catch cross-task consistency issues.

```mermaid
flowchart TD
    A["Merged plan.md ready"] --> B["Launch review subagent\nwith 5 parallel templates"]

    subgraph reviewers["5 Reviewer Templates (parallel)"]
        R1["Spec Reviewer\n(completeness, placeholders)"]
        R2["Security Reviewer\n(fail-closed, auth, defaults)"]
        R3["Silent Failure Hunter\n(swallowed errors, fallbacks)"]
        R4["Goal Traceability\n(goals -> tasks mapping)"]
        R5["Test Coverage\n(edge cases, error conditions)"]
    end

    B --> reviewers
    reviewers --> C[Combined findings]
    C --> D{Issues found?}
    D -->|no| E{Ask user: Present or Loop?}
    D -->|yes| F[Fix issues]
    F --> E
    E -->|Present| G[Human gate]
    E -->|Loop until clean| H[Re-run all 5 reviewers]
    H --> I{Clean or 10 rounds?}
    I -->|clean or cap hit| G
    I -->|issues found| J[Fix and re-review]
    J --> H
    G --> K{User approves?}
    K -->|yes| L[Split into task files, commit]
    K -->|no| M[Re-generate with feedback]
    M --> A
```

### Route-Based Routing

The `config.md` file's `route` field is the single source of truth for pipeline progression. Each skill's terminal state reads the route list, finds the current skill, and invokes the next entry. No conditional logic, no hardcoded next-skill invocations.

Replan is deliberately absent from the route list because it only fires between phases (invoked by Test, not by route progression). The multi-phase cycle works as follows:

- **Test** checks if more phases remain: last phase creates a PR, more phases invoke `qrspi:replan`
- **Replan** always invokes `qrspi:worktree` for the next phase
- **Worktree** re-enters the implement/integrate/test portion of the route for the new phase

### Config Validation

Every skill that reads `config.md` validates its fields before proceeding. Missing or invalid fields are never silently defaulted -- the skill presents a numbered-option menu:

```
config.md has no `route` field.

1) Re-run Goals to regenerate config.md with the correct route
2) Manually add a `route:` list to config.md
3) Abort
```

This prevents silent misconfiguration from propagating through the pipeline.

### Severity Classification

Replan classifies every proposed change using a defined severity table:

| Change Type | Severity | Loop-Back Target |
|-------------|----------|------------------|
| Task spec wording, LOC estimates, test expectations | Minor | None -- update in place |
| Add/remove/split/merge tasks within existing slices | Minor | None -- update plan + tasks |
| Reorder tasks or change dependencies | Minor | None -- update plan |
| Impact unclear, cross-cutting, or ambiguous scope | **Scope Unknown** | Treat as Major -- most stringent target |
| Change file paths or add files within existing slices | **Major** | Structure |
| Change interfaces between components | **Major** | Structure |
| Change technology choice, approach, or architecture | **Major** | Design |
| Change phase boundaries or slice definitions | **Major** | Design |
| Change project goals or acceptance criteria | **Major** | Goals |

The loop-back target is always the earliest affected artifact. If file paths change, loop back to Structure (cascades to Plan). If architecture changes, loop back to Design (cascades to Structure, then Plan). Scope-unknown changes default to the most stringent treatment to prevent under-classification. This prevents architectural drift from being patched over with task-level fixes.

### Phase-Scoped Artifacts

Working artifacts (`design.md`, `structure.md`, `plan.md`) contain only current-phase content. Design entries are keyed by `### {GOAL_ID} -- {name}`. Future-phase design lives in `future-design.md`. At phase transitions, completed artifacts are archived to `phases/phase-NN/` and next-phase goals are promoted from `future-goals.md`.

The `roadmap.md` file is the single scope controller -- a pure assignment table mapping goal IDs to phases and slices. It contains no notes, no design content. Every goal ID in roadmap must exist in either `goals.md` (current phase) or `future-goals.md` (future phases).

### Amendment Classification

Changes to approved artifacts are classified into three tiers:

| Tier | Description | Cascade |
|------|-------------|---------|
| **Clarifying** | Refine wording, fix ambiguity, no intent change | No cascade -- edit in place |
| **Additive** | Add new detail that doesn't contradict existing content | No cascade -- lightweight review |
| **Architectural** | Change intent, structure, or approach | Full cascade -- route through Replan |

The skill recommends a classification with rationale. The user can escalate (clarifying -> additive, additive -> architectural) or accept. Each amendment is presented as a diff with classification before application.

### Feedback Files

When a user rejects an artifact, the feedback is captured in `feedback/{step}-round-{NN}.md` containing the user's feedback verbatim and the full content of the rejected artifact. The next subagent receives all prior feedback files (not just the latest), preserving the full history of proposals and user responses. This ensures the agent learns from the complete rejection history, not just the most recent round.

### Backward Loops

When a later step surfaces new requirements or contradictions -- for example, implementation reveals a design flaw, or wireframes reviewed during Structure reveal missing features -- the pipeline loops backward to the earliest affected artifact and cascades forward. Each artifact is updated, reviewed, and re-approved at every step until reaching the point where the new learning was discovered.

This is not optional. Skipping backward loops creates drift between artifacts: goals say one thing, design says another, structure implements a third. Each artifact is a contract that downstream steps depend on. If the contract changes, every dependent must be updated.

### Phase Learnings

At the Integrate and Test human gates, the skill asks about phase learnings and future work ideas. Current-phase items are discussed and resolved in conversation. Future work ideas are appended to `future-goals.md` under the Ideas section. This replaces separate learnings files -- learnings are either acted on now or captured for future phases.

### Compaction

Each skill's terminal state recommends compacting context before the next step (`/compact`). This is a recommendation, not a gate -- the pipeline continues regardless. Because each step runs in a fresh subagent with only declared inputs, compaction between steps is natural and safe.

### Fix Task Routing

Three outer fix loops cross skill boundaries, all following the same pattern:

| Source | Fix Tasks Written To | Routes Through |
|--------|---------------------|----------------|
| Integration review | `fixes/integration-round-NN/` | Worktree -> Implement -> Integrate |
| CI pipeline | `fixes/ci-round-NN/` | Worktree -> Implement -> Integrate |
| Acceptance tests | `fixes/test-round-NN/` | Worktree -> Implement -> Integrate -> Test |

Fix task files follow the same format as regular task files (with `pipeline` field in frontmatter) so Worktree and Implement process them identically. Every fix goes through TDD and code reviews -- no shortcuts for "small" fixes.

---

### Mid-Pipeline Entry

Users can enter the pipeline mid-stream if they already have artifacts from prior work. As long as the required input files exist with `status: approved`, any step can run. When entering mid-pipeline, the plugin scans for existing QRSPI runs (`docs/qrspi/*/goals.md`), presents matches if multiple exist, and resumes at the first incomplete step based on the `config.md` route.

---

## Installation

**From a local path:**

```bash
claude plugins add /path/to/qrspi-plus
```

**From GitHub (once published):**

```bash
claude plugins add github:dfrysinger/qrspi-plus
```

After installation, the plugin's session-start hook automatically loads the `using-qrspi` skill at the beginning of every conversation. The pipeline activates whenever the user wants to build something.

---

## Configuration

Each pipeline run creates a `config.md` file in its artifact directory during the Goals step. This is the single source of truth for pipeline configuration.

```yaml
---
created: 2026-04-06
pipeline: full
codex_reviews: false
route:
  - goals
  - questions
  - research
  - design
  - structure
  - plan
  - worktree
  - implement
  - integrate
  - test
review_depth: deep
review_mode: loop
---
```

**Field definitions:**

| Field | Set by | Description |
|-------|--------|-------------|
| `created` | Goals | ISO date the run was created. Set once, never updated. |
| `pipeline` | Goals | Human-readable label (`full` or `quick`). Informational only; `route` is authoritative. |
| `codex_reviews` | Goals | Whether to include Codex as a second reviewer in review rounds. |
| `route` | Goals | Ordered list of skill names this run will execute. |
| `review_depth` | Worktree / Implement | `quick` (4 correctness reviewers) or `deep` (all 8 reviewers). Set at phase start. |
| `review_mode` | Worktree / Implement | `single` (skip convergence) or `loop` (converge until clean). Set at phase start. |

---

## Project Structure

```
qrspi-plus/
├── .claude-plugin/
│   ├── plugin.json                 # Plugin metadata
│   └── marketplace.json            # Marketplace listing
├── hooks/
│   ├── hooks.json                  # Hook registration (SessionStart, PreToolUse, PostToolUse)
│   ├── run-hook.cmd                # Cross-platform polyglot wrapper
│   ├── session-start               # Loads using-qrspi + injects skill content at session start
│   ├── pre-tool-use                # Pipeline step ordering + L1 task boundary enforcement (blocking)
│   ├── post-tool-use               # Artifact state sync + audit logging (non-blocking)
│   ├── setup-project-hooks.sh      # Workaround for Claude Code bug #17688
│   └── lib/                        # Shared hook library modules
│       ├── artifact.sh             # Artifact path resolution, type detection, phase snapshot/promote
│       ├── artifact-map.sh         # Canonical step-to-file mapping (forward + reverse lookup)
│       ├── audit.sh                # Per-task JSONL audit logging + raw blob capture
│       ├── bash-detect.sh          # Cross-platform bash detection
│       ├── enforcement.sh          # Pipeline ordering enforcement logic
│       ├── frontmatter.sh          # Generic YAML frontmatter parser (scalars, lists, objects)
│       ├── pipeline.sh             # Pipeline step definitions, ordering, cascade reset
│       ├── protected.sh            # Protected path detection
│       ├── state.sh                # .qrspi/state.json read/write with fail-closed validation
│       ├── task.sh                 # Active task detection, allowlist resolution, runtime overrides
│       └── worktree.sh             # Worktree path resolution
├── tests/
│   ├── unit/                       # 287 unit tests (bats-core)
│   ├── acceptance/                 # 175 acceptance tests (bats-core)
│   └── fixtures/                   # Test fixtures and mock data
├── skills/
│   ├── using-qrspi/
│   │   └── SKILL.md                # Entry point -- pipeline overview, routing, validation
│   ├── goals/
│   │   └── SKILL.md                # Step 1: Capture intent, goal specificity
│   ├── questions/
│   │   └── SKILL.md                # Step 2: Research questions
│   ├── research/
│   │   └── SKILL.md                # Step 3: Parallel specialist research
│   ├── design/
│   │   └── SKILL.md                # Step 4: Architecture + vertical slices + phase scoping
│   ├── structure/
│   │   └── SKILL.md                # Step 5: File/component mapping + phase scoping
│   ├── plan/
│   │   ├── SKILL.md                # Step 6: Task specs + architectural review
│   │   └── templates/
│   │       ├── spec-reviewer.md
│   │       ├── security-reviewer.md
│   │       ├── silent-failure-hunter.md
│   │       ├── goal-traceability-reviewer.md
│   │       └── test-coverage-reviewer.md
│   ├── worktree/
│   │   └── SKILL.md                # Step 7: Parallelization + dispatch + permissions
│   ├── implement/
│   │   ├── SKILL.md                # Step 8: TDD execution + batch gate
│   │   └── templates/
│   │       ├── implementer.md      # TDD execution prompt
│   │       ├── correctness/        # Always-run reviewers (4)
│   │       └── thoroughness/       # Deep-mode reviewers (4)
│   ├── integrate/
│   │   ├── SKILL.md                # Step 8.5: Merge + cross-task review + phase learnings
│   │   └── templates/
│   │       ├── integration-reviewer.md
│   │       └── security-integration-reviewer.md
│   ├── test/
│   │   ├── SKILL.md                # Step 9: Acceptance testing + code review checkpoint
│   │   └── templates/
│   │       ├── test-writer.md
│   │       ├── acceptance-test.md
│   │       ├── integration-test.md
│   │       ├── e2e-test.md
│   │       └── boundary-test.md
│   └── replan/
│       └── SKILL.md                # Step 9.5: Between-phase replanning + phase snapshot
└── docs/
    └── qrspi-reference.md          # QRSPI framework reference
```

Each pipeline run produces its artifacts in the target project (not the plugin directory):

```
docs/qrspi/YYYY-MM-DD-{slug}/
├── config.md
├── goals.md
├── questions.md
├── roadmap.md
├── research/
│   ├── summary.md
│   └── q*.md
├── design.md
├── future-design.md
├── future-goals.md
├── structure.md
├── plan.md
├── parallelization.md
├── tasks/
│   └── task-NN.md
├── fixes/
│   ├── integration-round-NN/
│   ├── ci-round-NN/
│   └── test-round-NN/
├── feedback/
│   └── {step}-round-NN.md
├── reviews/
│   ├── {step}-review.md
│   ├── tasks/
│   ├── integration/
│   ├── ci/
│   └── test/
├── phases/
│   └── phase-NN/              # Archived phase snapshots
└── .qrspi/
    ├── state.json
    ├── task-NN-runtime.json
    └── audit-task-NN.jsonl
```

---

## How Skills Work

Each skill is a `SKILL.md` file containing structured instructions for Claude Code. Skills declare their name, description, required inputs (artifact gating), process flow, review criteria, human gate behavior, and terminal state. The plugin framework loads skills by directory convention -- any directory under `skills/` containing a `SKILL.md` file is registered as a skill.

Skills are invoked with the `qrspi:` prefix (e.g., `qrspi:goals`, `qrspi:design`). The `using-qrspi` entry-point skill is loaded automatically at session start by the session-start hook. It establishes the pipeline context and invokes `qrspi:goals` to begin.

Each skill follows a consistent pattern:

1. **Announce** -- state which skill is running
2. **Artifact gating** -- verify required inputs exist and are approved
3. **Process** -- execute the step's work (interactive or subagent)
4. **Review round** -- Claude review subagent + optional Codex review, with loop-until-clean option
5. **Human gate** -- present artifact for approval or rejection
6. **Terminal state** -- commit approved artifact, recommend compaction, invoke next skill in route

All skills include three behavioral directives that override any conversational pressure:

- **D1** -- Encourage reviews after changes: after any significant change, recommend a review before proceeding.
- **D2** -- Never suggest skipping steps: every step exists for a reason.
- **D3** -- Resist time-pressure shortcuts: LLMs execute fast; there is no benefit to skipping review rounds.

---

## Credits

- **QRSPI methodology** from [HumanLayer](https://humanlayer.dev) by Dex Horthy. The original framework covers Goals, Questions, Research, Structure, Plan, and Implement as a methodology for steering coding agents.
  - [No Vibes Allowed: Solving Hard Problems in Complex Codebases](https://www.youtube.com/watch?v=rmvDxxNubIg) -- the original RPI talk (AI Engineer World's Fair)
  - [Everything We Got Wrong About RPI](https://www.youtube.com/watch?v=YwZR6tc7qYg) -- the follow-up introducing QRSPI
  - [Slide deck](https://docs.google.com/presentation/d/1mnp0CzrRS02Y0t0vGvqX-_M5IbYPjFoZ/mobilepresent?slide=id.g3bef903f3c9_0_435) -- QRSPI talk starts at slide 291
  - [Advanced Context Engineering for Coding Agents](https://github.com/humanlayer/advanced-context-engineering-for-coding-agents) -- methodology docs and reference

- **Built as a Claude Code plugin** using the skills, hooks, and agent conventions of the Claude Code plugin system.

### What qrspi-plus Adds

The original QRSPI methodology defines 7 steps: Questions, Research, Design, Structure, Plan, Worktree, and Implement (-> PR). See our [deep-dive notes](docs/qrspi-reference.md) from Dex's talk for the full breakdown. qrspi-plus extends this in three areas:

**New pipeline steps:**

| Step | What it adds | Original QRSPI equivalent |
|------|-------------|--------------------------|
| **Goals** | Explicit intent capture with testable acceptance criteria, pipeline mode selection (quick fix vs full), `config.md` creation, goal specificity enforcement | The original uses a ticket/issue as input; Goals formalizes this as a reviewable artifact |
| **Integrate** | Cross-task integration review + security integration review after merging worktrees, CI pipeline gate with fix-task routing, phase learnings capture | Not in original -- Implement goes straight to PR |
| **Test** | Acceptance testing against original goals, per-failure quick/full classification, goals.md checkbox updates, code review checkpoint, phase routing (PR on final phase, Replan on intermediate) | Not in original -- PR review was the verification step |
| **Replan** | Between-phase replanning with severity classification (minor/major/scope-unknown), fire-and-forget backward loops to Goals, Design, or Structure, three-tier amendment classification, phase snapshot and promotion | Not in original -- single-phase execution only |

**Extended existing steps:**

| Step | What qrspi-plus adds beyond the original |
|------|------------------------------------------|
| **Design** | Vertical slice enforcement (anti-pattern examples), phase definitions with replan gates, test strategy, Mermaid system diagrams, phase-scoped content rules, roadmap maintenance |
| **Structure** | Interface definitions (function/class signatures), create vs modify tracking, CI pipeline structure for greenfield projects, phase-scoped file maps |
| **Plan** | Sub-subagent dispatch for large plans, merge/split lifecycle, quick-fix single-task mode, `pipeline` field on task files, 5 specialized reviewer templates (architectural plan review) |
| **Worktree** | Dependency graph analysis, parallel/sequential/hybrid execution modes, baseline test verification with auto-fix, batch gate after all tasks, subagent permission pre-configuration |
| **Implement** | TDD iron law (no code without failing test), 8 specialized reviewers in correctness/thoroughness tiers, configurable review depth per phase, aggressive commenting requirements, verbatim review result persistence |

**Infrastructure additions:**

| Addition | What it adds |
|----------|-------------|
| **13 specialized reviewers** | 4 implementation correctness (spec, code quality, silent failures, security) + 4 implementation thoroughness (goal traceability, test coverage, type design, simplification) + 5 plan-level (spec, security, silent failures, goal traceability, test coverage) |
| **5 canonical review patterns** | Inner Loop (autonomous per-task), Outer Loop (user-confirmed), Deterministic (run once), Artifact Synthesis (subagent produce + review loop), Architectural Plan (5 parallel templates) |
| **Route-based routing** | `config.md` with route field as single source of truth, replacing hardcoded skill-to-skill invocations |
| **Config validation** | Numbered-option menus for missing/invalid config fields -- never silent defaults |
| **Quick fix mode** | Shortened pipeline (Goals -> Questions -> Research -> Plan -> Implement -> Test) for targeted fixes |
| **Fix-task routing loops** | Three outer loops (integration, CI, test) that route failures back through the pipeline with full TDD and reviews |
| **Artifact gating** | Structural enforcement -- each step checks prerequisites exist and are approved before proceeding |
| **Phase-scoped artifacts** | Working artifacts contain current-phase only; `future-design.md`, `future-goals.md`, `roadmap.md` manage cross-phase scope; `phases/phase-NN/` archives completed phases |
| **Amendment classification** | Three-tier system (clarifying, additive, architectural) with user-confirmed classification and cascade behavior |
| **Phase learnings** | Integrate and Test gates capture future work ideas into `future-goals.md` |
| **Goal specificity** | Each goal independently scopeable; late splitting classified by impact |
| **Feedback-driven re-generation** | Rejected artifacts capture user feedback + rejected snapshot, new subagent receives full rejection history |
| **Behavioral directives** | D1 (encourage reviews), D2 (never skip steps), D3 (resist time-pressure shortcuts) enforced across all 10 skills |
| **Durable resume detection** | `replan-pending.md` marker + mid-pipeline entry via artifact scanning for crash recovery |
| **Hook-based enforcement** | PreToolUse/PostToolUse hooks enforce pipeline ordering, task boundaries, and audit logging deterministically on every tool call -- 11 library modules, fail-closed security model, `.qrspi/state.json` state tracking |
| **462 hook tests** | 287 unit + 175 acceptance tests using bats-core, covering all enforcement paths and library modules |

---

## License

MIT
