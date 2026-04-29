---
status: draft
question_ids: [3]
research_type: codebase
---

# Q3: Feature-branch / worktree-branch naming conventions across skill prompts

## Summary

**TL;DR:** The qrspi-plus skill prompts use a single hierarchical branch convention rooted at `qrspi/{slug}/...` — feature branch is `qrspi/{slug}/main`, task branches are `qrspi/{slug}/task-NN` (with `task-NNa`/`task-NNb` for splits and `task-00`/`task-00b`/`task-00c` for baseline-fix injections), and stage branches are `qrspi/{slug}/stage-after-G{N}`. Worktree paths mirror this under `.worktrees/{slug}/(task-NN[a-z]?|baseline)/`. Branch-string occurrences are concentrated in `parallelize/SKILL.md`, `implement/SKILL.md`, `implement/references/resume-preconditions.md`, `implement/references/fix-task-routing.md`, `integrate/SKILL.md`, `using-qrspi/SKILL.md`, and `implement/templates/per-task-orchestrator.md`.

**Key findings:**
- Feature branch pattern `qrspi/{slug}/main` defined in `parallelize/SKILL.md:86` with explicit rationale (F-14 note at line 88) for why bare `qrspi/{slug}` would deadlock git ref hierarchy.
- Task branch pattern `qrspi/{slug}/task-NN` (informational) at `parallelize/SKILL.md:102`; concrete creation command in `implement/references/resume-preconditions.md:11`.
- Stage branch pattern `qrspi/{slug}/stage-after-G{N}` defined in `parallelize/SKILL.md:93,102` and `implement/SKILL.md:125`.
- Baseline-fix branch pattern `qrspi/{slug}/task-00` (and `task-00b`, `task-00c` for repeats) at `implement/SKILL.md:181,186`.
- Concrete-slug examples consistently use `user-auth` as the placeholder slug (e.g., `qrspi/user-auth/task-01`, `qrspi/user-auth/main`, `qrspi/user-auth/stage-after-G1`) in `parallelize/SKILL.md:86,254-263` and `implement/SKILL.md:296-302`.
- Worktree path convention `.worktrees/{slug}/(task-NN[a-z]?|baseline)/` is hook-enforced; defined in `using-qrspi/SKILL.md:21,262` and `implement/SKILL.md:138`.
- The four "kinds of branches" enumerated explicitly at `parallelize/SKILL.md:88`: feature `main`, `task-NN`, `task-NNa`, `stage-after-G{N}`.
- Task split suffix convention `task-NNa`/`task-NNb` (Plan-induced — F-19) at `using-qrspi/SKILL.md:262`, `implement/SKILL.md:138`, `replan/SKILL.md:289` (`task-09a`/`task-09b`).
- Symbolic base vocabulary (used in Branch Map, never resolved by Parallelize): `feature branch tip`, `task-NN tip`, `stage-after-G{N}`, `task-00 tip` — `parallelize/SKILL.md:98-101,128,294`; `implement/SKILL.md:123-126`.
- Templates under `skills/*/templates/` are largely free of branch literals — only `per-task-orchestrator.md` references `task-NN`/`.worktrees/{slug}/...` paths; reviewer templates and test templates contain no branch strings (only task IDs like `task-04`, `task-32` as plan-task labels).

**Surprises:** The reviewer/test templates carry zero git-branch literals (branch knowledge is concentrated in the orchestrator skills); `replan/SKILL.md:48` is the only place outside Implement/Parallelize/Integrate that mentions "feature branch."

**Caveats:** Did not enumerate auto-generated artifact templates; only branch-naming patterns in prompt text were extracted, not in shell scripts or hook code under `hooks/` or `scripts/`. Some grep hits were elided where the matched line referenced "branch" in a non-naming sense (e.g., "branch entries", "no conditional branches in every skill").

## Full findings

### Inventory of branch-name occurrences

#### Feature branch — `qrspi/{slug}/main`

| file:line | string / context | section |
|---|---|---|
| parallelize/SKILL.md:86 | `qrspi/{slug}/main` (e.g., `qrspi/user-auth/main`) — definition + base-branch source | Branch Model item 1 |
| parallelize/SKILL.md:88 | F-14 rationale "Why `/main`, not bare `qrspi/{slug}`" | Branch Model item 1 (sub-paragraph) |
| parallelize/SKILL.md:98 | `feature branch tip` = tip of `qrspi/{slug}/main` at runtime | Symbolic base vocabulary |
| implement/SKILL.md:123 | `feature branch tip` = current tip of `qrspi/{slug}/main` | Resolution table |
| implement/SKILL.md:150 | "Create feature branch `qrspi/{slug}/main` from the current branch" | Process Step 3 |
| implement/SKILL.md:298 | "Resolve `feature branch tip` to the current tip of `qrspi/user-auth/main`" | Worked example (full) |

#### Task branches — `qrspi/{slug}/task-NN`

| file:line | string / context | section |
|---|---|---|
| parallelize/SKILL.md:99 | `task-NN tip` = tip of `qrspi/{slug}/task-NN` | Symbolic vocabulary |
| parallelize/SKILL.md:102 | Branch naming: `qrspi/{slug}/task-NN` | Branch Model item 2 |
| parallelize/SKILL.md:145-147 | Example map: `qrspi/{slug}/task-01`, `task-02`, `task-03` | Output-format example |
| parallelize/SKILL.md:254-257 | Example map: `qrspi/user-auth/task-01..04` with bases | "Hybrid Phase Example" Branch Map |
| parallelize/SKILL.md:281-283 | `qrspi/user-auth/task-01..03` | Second worked example |
| implement/SKILL.md:124 | `qrspi/{slug}/task-NN` resolution rule | Resolution table |
| implement/SKILL.md:150 | `qrspi/{slug}/task-NN` namespace siblings rationale | Process Step 3 |
| implement/SKILL.md:298 | `qrspi/user-auth/task-01`, `qrspi/user-auth/task-02` | Worked example wave 1 |
| implement/SKILL.md:302 | `qrspi/user-auth/task-01` (tip) | Worked example wave 2 |
| implement/references/resume-preconditions.md:3 | "branch `qrspi/{slug}/task-NN` exists" | Header trigger |
| implement/references/resume-preconditions.md:11 | `git worktree add .worktrees/{slug}/task-NN/ -b qrspi/{slug}/task-NN <resolved-base>` | Case 1 |
| implement/references/resume-preconditions.md:13 | `git worktree add ... qrspi/{slug}/task-NN` | Case 3 |
| implement/references/resume-preconditions.md:22,28,34 | `git merge-base qrspi/{slug}/task-NN`, `git rev-parse qrspi/{slug}/task-NN`, `git branch -D qrspi/{slug}/task-NN` | Inspect-and-decide procedure |

#### Baseline-fix branch — `qrspi/{slug}/task-00`

| file:line | string / context | section |
|---|---|---|
| implement/SKILL.md:126 | `task-00 tip` = current tip of `qrspi/{slug}/task-00` (only valid after baseline-fix injection) | Resolution table |
| implement/SKILL.md:181 | "Append one row to the Branch Map: `task-00 → qrspi/{slug}/task-00 (base: feature branch tip)`" | Baseline Tests § Auto-fix |
| implement/SKILL.md:186 | "Append the new task as a fresh Branch Map row (`task-00b → qrspi/{slug}/task-00b (base: task-00 tip)`)" | Repeated baseline failures |
| parallelize/SKILL.md:101 | `task-00 tip` symbolic base | Symbolic vocabulary |

#### Stage branches — `qrspi/{slug}/stage-after-G{N}`

| file:line | string / context | section |
|---|---|---|
| parallelize/SKILL.md:93 | `qrspi/{slug}/stage-after-G{N}` definition | Branch Model item 2 (Hybrid) |
| parallelize/SKILL.md:102 | "stage branches `qrspi/{slug}/stage-after-G{N}`" | Branch Model item 2 |
| parallelize/SKILL.md:263 | `qrspi/user-auth/stage-after-G1` | Stage Commits table example |
| implement/SKILL.md:125 | `qrspi/{slug}/stage-after-G{N}` creation rule | Resolution table |
| implement/SKILL.md:300 | `qrspi/user-auth/stage-after-G1` (created by merging task-01 + task-02 tips) | Worked example |
| integrate/SKILL.md:81 | "delete the stage branches (`qrspi/{slug}/stage-after-G*`)" | Merge Strategy cleanup |

#### Worktree paths — `.worktrees/{slug}/(task-NN[a-z]?|baseline)/`

| file:line | string / context | section |
|---|---|---|
| using-qrspi/SKILL.md:21 | `.worktrees/{slug}/task-NN/` (canonical layout) | Architecture overview |
| using-qrspi/SKILL.md:262 | `.worktrees/{slug}/(task-NN[a-z]?|baseline)/...` BLOCKED outside | Hook subagent containment |
| using-qrspi/SKILL.md:267,269 | `.worktrees/` (subagent loose pinning, F-8 limitation) | How worktree enforcement works |
| implement/SKILL.md:138 | `.worktrees/{slug}/(task-NN[a-z]?|baseline)/` walling pattern | Subagent containment |
| implement/SKILL.md:151,153,154,160,167,175,193,194,195 | `.worktrees/{slug}/baseline/`, `.worktrees/{slug}/task-00/`, `.worktrees/{slug}/task-NN/` | Process Steps 4-6 + Baseline Tests |
| implement/SKILL.md:296,298,310,312 | `.worktrees/user-auth/baseline/`, `.worktrees/user-auth/task-01/`, `.worktrees/user-auth/task-02/`, `.worktrees/{slug}/task-01/` | Worked examples |
| implement/references/resume-preconditions.md:3,11,13,28,34 | `.worktrees/{slug}/task-NN/` paths in case table + git commands | Case classification |
| implement/templates/per-task-orchestrator.md:28 | `{target_project}/.worktrees/{slug}/task-NN/` (CWD rationale) | Why-this-rule note |
| implement/templates/per-task-orchestrator.md:86 | `.worktrees/{slug}/(task-NN[a-z]?|baseline)/`; `git -C .worktrees/{slug}/task-NN/ commit -F ...` | Multi-line commit messages F-17 |
| implement/templates/per-task-orchestrator.md:137 | `.worktrees/{slug}/task-NN/.codex-prompts/...` | Dispatching Reviewers |

#### Symbolic base names (used in Branch Map "Base" column)

Vocabulary defined at `parallelize/SKILL.md:98-101` and `parallelize/SKILL.md:128,294`; mirrored at `implement/SKILL.md:123-126`. Tokens:
- `feature branch tip`
- `task-NN tip` (e.g., `task-01 tip` at `parallelize/SKILL.md:257`)
- `stage-after-G{N}` (e.g., `stage-after-G1` at `parallelize/SKILL.md:147,256,300`; `implement/SKILL.md:300,302`)
- `task-00 tip`

#### Task IDs as plan/review labels (not git branches)

Plan-task labels (`task-NN.md`, `task-NN-review.md`) appear without the `qrspi/{slug}/` prefix in:
- using-qrspi/SKILL.md:149 (`task-01.md`)
- plan/SKILL.md:146,303 (`tasks/task-01.md`, `task-00.md`)
- replan/SKILL.md:277,283,289,341 (`tasks/task-07.md`, `task-08.md`, `task-09.md`, `task-09a.md`, `task-09b.md`)
- test/SKILL.md:297,302,307 (e.g., `plan.md task-04 / TE-1`)
- implement/templates/per-task-orchestrator.md:24,61,86,137,144,148 (`reviews/tasks/task-NN-review.md`, `task-NN.md`)
- _shared/reviewer-boilerplate.md:93 (`task-32-code-changes`, `test-results-task-32` — illustrative IDs)
- test/templates/test-writer.md:52,57 (`task-04 / TE-1`, `fixes/test-round-01`)

#### Fix-task and base-branch mentions

| file:line | string / context |
|---|---|
| test/SKILL.md:202 | `git diff main...HEAD` — uses bare `main` as base branch for "Full phase diff" |
| test/SKILL.md:227 | "code stays on the feature branch" — generic reference |
| parallelize/SKILL.md:86 | "Created by Implement from the current branch (typically `main`)" |
| parallelize/SKILL.md:104 | "Test creates the PR from the feature branch to the base branch" |
| replan/SKILL.md:48 | "Completed phase code (merged on feature branch)" |
| integrate/SKILL.md:74-105 | Multiple references to "feature branch", "task branches", "stage branches" (see also line 202: "Merge task branches") |
| implement/SKILL.md:104,320 | "creating worktrees on main/master without a feature branch" (anti-pattern) |
| plan/SKILL.md:108 | "Cannot be merged to main alone (must batch with peers to ship)" |
| implement/references/fix-task-routing.md:8,9 | "append new branch entries directly to the Branch Map" / "fork directly from the feature-branch tip" |

### Naming conventions in use

1. **Hierarchical namespace `qrspi/{slug}/...`** — every QRSPI-managed branch lives under this prefix. The slug comes from `config.md`'s project slug.
2. **Feature branch `qrspi/{slug}/main`** — single feature branch per run, created at first phase from the current/base branch (typically bare `main`). The trailing `/main` segment is mandatory (F-14) so feature and task branches can coexist as namespace siblings.
3. **Task branches `qrspi/{slug}/task-NN`** — zero-padded two-digit task number. Plan-induced splits use suffix letters: `task-NNa`, `task-NNb` (F-19). One worktree per task at `.worktrees/{slug}/task-NN/`.
4. **Baseline-fix branches `qrspi/{slug}/task-00`** — runtime-injected when baseline tests fail. Repeated failures append letter suffixes: `task-00b`, `task-00c`.
5. **Stage branches `qrspi/{slug}/stage-after-G{N}`** — scratch branches for hybrid phases with multi-parent dependencies; created on demand by Implement, deleted by Integrate.
6. **Worktree directory mirror** — `.worktrees/{slug}/(task-NN[a-z]?|baseline)/`. Hook-enforced subagent containment depends on this regex.
7. **Symbolic base vocabulary in `parallelization.md` Branch Map** — Parallelize never embeds concrete commit hashes; only the four tokens `feature branch tip`, `task-NN tip`, `stage-after-G{N}`, `task-00 tip` are allowed in the `Base` column.
8. **Slug placeholder convention** — placeholder syntax is `{slug}` in spec text; concrete worked examples use `user-auth` as the canonical slug.
9. **Plan-task IDs (separate convention)** — `task-NN` (and `task-NNa`/`task-NNb`) is also used as a non-git plan-artifact label in filenames like `tasks/task-NN.md` and `reviews/tasks/task-NN-review.md`.
10. **Fix-task batches** — stored under `fixes/{type}-round-NN/` where `{type}` ∈ {`integration`, `ci`, `test`} (test/SKILL.md:152, integrate/SKILL.md:97,108, test/templates/test-writer.md:57); these are file-path namespaces, not git branches.

## Files surveyed

- skills/research/SKILL.md
- skills/design/SKILL.md
- skills/parallelize/SKILL.md
- skills/using-qrspi/SKILL.md
- skills/test/SKILL.md
- skills/goals/SKILL.md
- skills/integrate/SKILL.md
- skills/plan/SKILL.md
- skills/phasing/SKILL.md
- skills/replan/SKILL.md
- skills/implement/SKILL.md
- skills/structure/SKILL.md
- skills/questions/SKILL.md
- skills/_shared/reviewer-boilerplate.md
- skills/_shared/templates/scope-reviewer.md
- skills/test/templates/{integration-test,acceptance-test,boundary-test,test-writer,e2e-test}.md
- skills/integrate/templates/{security-integration-reviewer,integration-reviewer}.md
- skills/plan/templates/{goal-traceability-reviewer,silent-failure-hunter,security-reviewer,spec-reviewer,test-coverage-reviewer}.md
- skills/implement/references/{fix-task-routing,resume-preconditions}.md
- skills/implement/templates/per-task-orchestrator.md
- skills/implement/templates/implementer.md
- skills/implement/templates/thoroughness/{goal-traceability-reviewer,code-simplifier,test-coverage-reviewer,type-design-analyzer}.md
- skills/implement/templates/correctness/{silent-failure-hunter,security-reviewer,spec-reviewer,code-quality-reviewer}.md
