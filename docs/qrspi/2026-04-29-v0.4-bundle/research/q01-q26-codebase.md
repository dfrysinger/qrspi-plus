---
status: draft
question_ids: [1, 26]
research_type: codebase
---

# Q1 + Q26: Subagent dispatch architecture in Implement chain

## Summary

**TL;DR:** The Implement chain declares a **three-layer subagent hierarchy** — Implement skill (layer 1) dispatches per-task-orchestrator subagents (layer 2), each of which dispatches one implementer subagent (layer 3) plus a fixed set of reviewer subagents (layer 3) per the templates under `skills/implement/templates/`. Roles are assigned to dispatch sites by hard-coded template paths inside SKILL.md / per-task-orchestrator.md prose; there is no dynamic role-assignment table. Tool grants are **uniform** — every subagent inherits a single tool surface walled off by a `pre-tool-use` hook to `.worktrees/{slug}/(task-NN[a-z]?|baseline)/`; the only dispatch-shape parameter named in prose is `isolation: worktree` on the per-task orchestrator dispatch.

**Key findings:**
- Three layers are explicitly named at `skills/implement/SKILL.md:19` ("The Implement skill (this file) is layer 1; it never runs TDD or reviewers itself"; layer 2 = per-task orchestrator; layer 3 = implementer + reviewers).
- Layer-1 → layer-2 dispatch sites (in order of execution): baseline-fix `task-00` (full pipeline `SKILL.md:154`; quick fix `SKILL.md:155`), main wave/batch dispatch (full pipeline `SKILL.md:163`, `SKILL.md:205`; quick fix `SKILL.md:168`), and a gate-level cross-task reviewer subagent fired only when the user picks "Re-run all reviews" at the batch gate (`SKILL.md:249`).
- Layer-2 → layer-3 dispatch sites: implementer (initial dispatch — fresh `Agent` call), implementer-fix (first fix cycle = fresh `Agent`; subsequent fix cycles = `SendMessage` to the retained agent ID; BLOCKED escape uses fresh `Agent`) (`per-task-orchestrator.md:120-122`); correctness reviewer group (4 reviewers, parallel after spec gate); thoroughness reviewer group (4 reviewers, parallel after correctness, deep mode only) (`per-task-orchestrator.md:101-110`); per-template Codex sidecar dispatched in parallel with each Claude reviewer when `codex_reviews: true` (`per-task-orchestrator.md:136-140`).
- Tool grant model: there is no per-layer tool allowlist in the prompts. Containment is hook-based — `pre-tool-use` blocks any subagent Write/Edit/Bash whose target falls outside `.worktrees/{slug}/(task-NN[a-z]?|baseline)/` (`SKILL.md:138`). Sessions are recommended to run with `--dangerously-skip-permissions` so the hook is the sole wall (`SKILL.md:140`). The only inline dispatch-shape parameter named is `isolation: worktree` on per-task-orchestrator dispatches (`SKILL.md:163, 205`).
- Role-to-dispatch-site assignment is declared statically in three places: (1) the directory layout block at `per-task-orchestrator.md:34-49` enumerates which template file plays which role; (2) the Review Groups table at `per-task-orchestrator.md:101-110` assigns each reviewer template to Quick vs Deep mode and to its execution-order slot (spec first, then parallel correctness, then parallel thoroughness); (3) Plan/Parallelize do NOT assign roles to dispatch sites — they produce content artifacts (`plan.md` + `tasks/*.md`; `parallelization.md`) that Implement consumes; the role decision lives entirely inside Implement.
- Plan and Parallelize each have their own internal subagent dispatches that are unrelated to the Implement chain's per-task subagents: Plan dispatches a "plan overview subagent" plus optional "sub-subagents" (one per task spec, for plans with 6+ tasks) (`plan/SKILL.md:114-115, 150-161`); Parallelize dispatches a Claude reviewer + a parameterized scope-reviewer + an optional Codex reviewer (`parallelize/SKILL.md:161-172`).
- The cross-task / gate-level reviewer subagent at the batch gate is described in prose only at `implement/SKILL.md:249` — its template path is not specified beyond "the cross-task reviewer subagent" embedding `skills/_shared/reviewer-boilerplate.md` verbatim; there is no template file under `skills/implement/templates/` for this role.

**Surprises:**
- The implementer-fix dispatch uses **session persistence via `SendMessage`** for fix cycles 2+ (`per-task-orchestrator.md:120-122`) — the only place in the Implement chain where a subagent is reused across cycles instead of being fresh-dispatched.
- The per-task orchestrator's dispatch shape forbids running reviewers, fixes, or "quick verifications" in main chat — even between rounds — because main chat's CWD pinning would trigger worktree-enforcement on every subsequent tool call (`per-task-orchestrator.md:28`, `per-task-orchestrator.md:264-265`).
- "Codex reviews" are dispatched as **non-Claude jobs** via `scripts/codex-companion-bg.sh launch ... await ...` — they are subagents at the role level but not at the Anthropic-Agent-tool level (`per-task-orchestrator.md:136-140`).
- Plan's "Plan OWNS / Plan DEFERS" structure (`plan/SKILL.md:24-51`) explicitly cedes implementation-logic decisions to Implement — but does not assign roles. Roles are an Implement-internal concept.

**Caveats:**
- Beyond `isolation: worktree` and the hook-based wall, the prompts do not name explicit per-tool grant lists for each layer. If "what tool grants each level receives" expects an enumerated allowlist (e.g., "implementer can use Bash + Write + Edit; reviewer can use Read only"), no such list exists in these files. The hook target-based asymmetric model is referenced (`implement/SKILL.md:138`) but its source (`hooks/`) was not opened during this survey.
- The "gate-level reviewer subagent" (`SKILL.md:249`) is referenced in prose without a corresponding template file in `skills/implement/templates/`; its prompt assembly is described only inline.
- I did not open the hook source files under `hooks/` or `scripts/codex-companion-bg.sh` — claims about the hook wall are derived from how SKILL.md and per-task-orchestrator.md describe the wall, not from hook source.

## Full findings

### Q1: dispatch levels, tool grants, where declared

**Layer naming and role enumeration** — `skills/implement/SKILL.md:19`:

> "The per-task orchestrator subagent is the layer-2 subagent that runs `templates/per-task-orchestrator.md`. It in turn dispatches the layer-3 implementer subagent (`templates/implementer.md`) and reviewer subagents (`templates/correctness/*`, `templates/thoroughness/*`). The Implement skill (this file) is layer 1; it never runs TDD or reviewers itself."

**Layer-1 dispatch sites (Implement skill → layer-2 per-task-orchestrator subagents).** All four sites read `templates/per-task-orchestrator.md` as the prompt framework:

1. Baseline-fix `task-00` isolation dispatch (full pipeline) — `skills/implement/SKILL.md:154`: "Dispatch the `task-00` per-task orchestrator subagent, wait for terminal state."
2. Baseline-fix `task-00` isolation dispatch (quick fix) — `skills/implement/SKILL.md:155`: "create the `task-00` worktree forked from feature branch tip, dispatch its per-task orchestrator subagent, wait for terminal state."
3. Main wave dispatch (full pipeline) — `skills/implement/SKILL.md:163` and `SKILL.md:205`: "Fire all tasks in the wave concurrently (one per-task orchestrator subagent per task; multiple Agent tool calls in parallel, each with `isolation: worktree`)."
4. Main batch dispatch (quick fix) — `skills/implement/SKILL.md:168`: "Fire the per-task orchestrator subagent (multiple if the batch has multiple fix tasks; they are file-disjoint by quick-fix construction)."
5. Optional gate-level cross-task reviewer dispatch (full pipeline; quick fix) — `skills/implement/SKILL.md:249`: "When the user selects 'Re-run all reviews' at the batch gate, Implement assembles the gate-level reviewer prompt and dispatches the cross-task reviewer subagent. The reviewer subagent embeds `skills/_shared/reviewer-boilerplate.md` verbatim at dispatch time." This site does NOT use `templates/per-task-orchestrator.md` — it is a directly-dispatched reviewer subagent, the only layer-1 → layer-(non-orchestrator) dispatch in the chain.

**Layer-2 dispatch sites (per-task-orchestrator → layer-3 implementer/reviewer subagents).** Roles and template paths declared at `templates/per-task-orchestrator.md:34-49`:

```
implement/
├── SKILL.md                    (orchestration logic only)
└── templates/
    ├── implementer.md          (TDD execution prompt)
    ├── correctness/            (always runs — quick + deep)
    │   ├── spec-reviewer.md
    │   ├── code-quality-reviewer.md
    │   ├── silent-failure-hunter.md
    │   └── security-reviewer.md
    └── thoroughness/           (deep mode only)
        ├── goal-traceability-reviewer.md
        ├── test-coverage-reviewer.md
        ├── type-design-analyzer.md
        └── code-simplifier.md
```

Confirmed by directory listing of `skills/implement/templates/` (correctness/ has 4 files; thoroughness/ has 4 files; plus `implementer.md` and `per-task-orchestrator.md`).

Specific layer-2 → layer-3 dispatch sites:
- **Initial implementer dispatch** — fresh `Agent` call with `templates/implementer.md` as prompt framework (`per-task-orchestrator.md:75-87`).
- **Implementer-fix dispatches** — `per-task-orchestrator.md:120-122`: first fix cycle = fresh `Agent`; subsequent cycles = `SendMessage` to the retained agent ID; BLOCKED escape requires a fresh `Agent` (model switch / decomposition needs clean context).
- **Reviewer group dispatches** — `per-task-orchestrator.md:99-110`: spec-reviewer first (gate), then correctness reviewers in parallel, then (deep mode only) thoroughness reviewers in parallel. Each reviewer is a fresh subagent dispatch reading its template from `templates/{group}/{reviewer}.md` (`per-task-orchestrator.md:130`).
- **Codex sidecar dispatches** — `per-task-orchestrator.md:136-140`: when `codex_reviews: true`, for every Claude reviewer dispatched, a non-blocking Codex job is launched in parallel via `scripts/codex-companion-bg.sh launch --prompt-file ...`. One launch per Claude reviewer template.

**Tool grants per layer.** The prompts do NOT enumerate per-layer tool allowlists. The grant model is:

- Hook-governed containment, not per-tool allowlists — `skills/implement/SKILL.md:136-140`: "Subagent containment is enforced by the QRSPI `pre-tool-use` hook (target-based asymmetric model... The hook blocks any subagent Write/Edit/Bash whose target falls outside `.worktrees/{slug}/(task-NN[a-z]?|baseline)/`... No per-worktree `.claude/settings.json` file is required. **Recommended:** run sessions with `--dangerously-skip-permissions` enabled — the hook is the security wall."
- Layer-1 main-chat orchestration restriction — `templates/per-task-orchestrator.md:24-30`: main chat (orchestrator) is restricted to dispatching subagents, aggregating findings, gating transitions, and writing review logs (`reviews/tasks/task-NN-review.md` is the sole file main chat authors directly). It does NOT run tests/typecheck/lint, write target-project source files, or run git operations — those are delegated to subagents.
- Layer-2 main-chat-vs-subagent split — same passage, plus `per-task-orchestrator.md:264-265`: even between review rounds, no main-chat verification; dispatch a fresh subagent.
- Layer-3 (implementer) tool footprint — `implementer.md:42-51` (TDD process: write tests, run tests, write impl, run tests, refactor, commit) and `per-task-orchestrator.md:86`: "Subagents are walled to `.worktrees/{slug}/(task-NN[a-z]?|baseline)/` by the asymmetric pre-tool-use hook, so the global CLAUDE.md 'write to `/tmp/commit-msg.txt`' guidance is BLOCKED for subagents." This implies subagents have Bash + Write + Edit, scoped to the worktree, but no explicit allowlist is named.
- Layer-3 (reviewer) tool footprint — not enumerated. The reviewer templates (e.g., `templates/correctness/spec-reviewer.md:23-50`) call for verification by reading files and tests; tool grant is implicit.
- Codex sidecar — Bash-tool only, `scripts/codex-companion-bg.sh` wrapper (`per-task-orchestrator.md:136-140`).

**Inline dispatch-shape declaration.** The only explicit dispatch parameter named in prose is `isolation: worktree` on the layer-1 → layer-2 wave dispatch:
- `skills/implement/SKILL.md:163`: "multiple Agent tool calls in parallel, each with `isolation: worktree`"
- `skills/implement/SKILL.md:205`: same wording, in the Wave Dispatch section.

No `isolation:` parameter is declared on the layer-2 → layer-3 dispatches in `per-task-orchestrator.md` prose.

**Where dispatch shape is declared.**
- Top-level dispatch (layer-1 → layer-2): `skills/implement/SKILL.md:142-170` (Process Steps 5-6) and `skills/implement/SKILL.md:197-211` (Wave Dispatch section).
- Per-task orchestrator dispatch (layer-2 → layer-3): `skills/implement/templates/per-task-orchestrator.md:34-49` (template paths), `:99-110` (review group / mode / execution-order assignment), `:112-126` (Review Fix Loop including `Agent` vs `SendMessage` choice), `:128-140` (Dispatching Reviewers including Codex sidecar).
- Hook wall (governs all subagent tool grants): `skills/implement/SKILL.md:136-140` references `using-qrspi/SKILL.md` § "How worktree enforcement works".

### Q26: role-to-dispatch-site assignment

**Plan does not assign roles to dispatch sites.** Plan produces content artifacts only:
- `plan/SKILL.md:24-32` (Plan OWNS): ordered task specs, test expectations, dependencies, LOC estimates. No role assignment.
- `plan/SKILL.md:84-86` (Execution Model): Plan dispatches its own subagents — a "plan overview subagent" and, for plans with 6+ tasks, "sub-subagents" (one per task spec). These are Plan-internal dispatches; the resulting `tasks/task-NN.md` files do not carry any role pointer.
- `plan/SKILL.md:269-296` (Split task file format): the `tasks/task-NN.md` frontmatter has `status`, `task`, `phase`, `pipeline`, optional `sizing_exception`, optional `fix_type`. **No `role` or `dispatch` field.** The `pipeline` field controls per-task input gating only (`plan/SKILL.md:297`), not role.

**Parallelize does not assign roles to dispatch sites.** Parallelize produces a symbolic Branch Map:
- `parallelize/SKILL.md:34-50` (Parallelize OWNS / DEFERS): dependency graph, file-overlap analysis, parallel groups, Branch Map, Mermaid graph, execution mode. DEFERS list explicitly cedes "per-task implementation logic" to Implement (`parallelize/SKILL.md:45`). No role decision.
- `parallelize/SKILL.md:122-131` (Artifact section): `parallelization.md` required sections — Execution Mode, Dependency Analysis, Branch Map, Stage Commits, Execution Order, Mermaid graph. No role-assignment column.
- `parallelize/SKILL.md:128`: "The `Base` column uses *only* the symbolic vocabulary defined in the Branch Model (`feature branch tip`, `task-NN tip`, `stage-after-G{N}`, `task-00 tip`)." — symbolic, not role-assigning.
- `parallelize/SKILL.md:14`: "Parallelize never creates branches, never runs baseline tests, never dispatches per-task subagents."

**Implement is the sole site that assigns roles to dispatch sites.** The assignment is hard-coded in two locations, both inside Implement:

1. **Layer-1 role assignment** — `skills/implement/SKILL.md:19` declares the per-task-orchestrator template as the layer-2 role. The Process Steps section (`SKILL.md:142-170`) names "per-task orchestrator subagent" at every dispatch site (`SKILL.md:154, 155, 163, 168, 205`). The gate-level reviewer is the only other layer-1 dispatch role, named only at `SKILL.md:249`.
2. **Layer-2 role assignment** — `templates/per-task-orchestrator.md:34-49` (the directory tree) and `per-task-orchestrator.md:101-110` (the Review Groups table) hard-code which template path plays which role:

| Group | Reviewer | Quick | Deep | Execution slot |
|-------|----------|-------|------|-----------------|
| Correctness | spec-reviewer | Yes | Yes | First (gate for the rest) |
| Correctness | code-quality-reviewer | Yes | Yes | Parallel after spec |
| Correctness | silent-failure-hunter | Yes | Yes | Parallel after spec |
| Correctness | security-reviewer | Yes | Yes | Parallel after spec |
| Thoroughness | goal-traceability-reviewer | No | Yes | Parallel after correctness |
| Thoroughness | test-coverage-reviewer | No | Yes | Parallel after correctness |
| Thoroughness | type-design-analyzer (only when new types) | No | Yes | Parallel after correctness |
| Thoroughness | code-simplifier | No | Yes | Parallel after correctness |

The implementer role is assigned to `templates/implementer.md` at `per-task-orchestrator.md:38`. The implementer-fix role reuses `templates/implementer.md` per `per-task-orchestrator.md:120` ("Orchestrator dispatches an implementer-fix subagent via fresh `Agent` call with the consolidated issue list").

**The role decision is mode-dependent in only one place** — review depth (`config.md.review_depth = quick | deep`) selects whether thoroughness reviewers fire, per `per-task-orchestrator.md:101-110`. `review_depth` is asked at the start of each Implement run (`skills/implement/SKILL.md:108-115`) and stored in `config.md`.

**Inputs the per-task orchestrator loads are mode-dependent**, gated by the task file's `pipeline` field (not by role) — `templates/per-task-orchestrator.md:55, 59-66`:

| Input | `pipeline: quick` | `pipeline: full` |
|-------|-------------------|-------------------|
| `task-NN.md` (full text) | Yes | Yes |
| `goals.md` (approved) | Yes | Yes |
| `research/summary.md` (approved) | Yes | No |
| `design.md` (approved) | No | Yes |
| `structure.md` (approved) | No | Yes |
| `parallelization.md` (approved) | No | Yes |

The `pipeline` field on each `tasks/task-NN.md` is written by Plan from `config.md` (`plan/SKILL.md:297-303`), with explicit overrides: Test/Integrate write `pipeline` per fix-task class; Implement copies the run's mode onto runtime-injected `task-00`.

## Files surveyed

- `skills/implement/SKILL.md` — layer naming (`:19`), HARD-GATE rules (`:101-106`), subagent permissions / hook wall (`:136-140`), Process Steps (`:142-170`), Wave Dispatch (`:197-211`), gate-level reviewer dispatch (`:249`), TodoWrite mapping (`:280-290`).
- `skills/implement/templates/per-task-orchestrator.md` — orchestration boundary (`:17-30`), template directory tree assigning roles to template files (`:34-49`), artifact gating by `pipeline` field (`:53-67`), TDD process (`:75-87`), implementer status table (`:88-98`), Review Groups table (`:99-110`), Review Fix Loop with `Agent` vs `SendMessage` (`:112-126`), reviewer dispatch + Codex sidecar (`:128-140`).
- `skills/implement/templates/implementer.md` — implementer subagent prompt (TDD process, status reporting); confirmed implementer is layer-3 work, not layer-2.
- `skills/implement/templates/correctness/spec-reviewer.md` (first 50 lines), `code-quality-reviewer.md` (first 30 lines) — confirmed each reviewer is a standalone prompt template addressed by template path; no role-assignment frontmatter.
- `skills/implement/references/fix-task-routing.md` — fix-task batch reading rules; confirms fix-task dispatches reuse the same role assignments and `review_depth`/`review_mode` from `config.md`.
- `skills/plan/SKILL.md` — Plan OWNS/DEFERS (`:24-51`), Execution Model with overview-subagent + per-task sub-subagents (`:84-86, 114-161`), task file format (`:269-296`), `pipeline` field semantics (`:297-303`).
- `skills/parallelize/SKILL.md` — Parallelize OWNS/DEFERS (`:30-49`) confirming no role assignment, Branch Model (`:82-106`), required artifact sections (`:122-131`), reviewer dispatches (`:161-172`).
- `skills/_shared/reviewer-boilerplate.md` (first 60 lines) — finding schema embedded by every reviewer subagent dispatched in the chain.
- `skills/using-qrspi/SKILL.md` (first 80 lines) — pipeline overview confirming Implement runs once per phase and "fires N per-task subagents".
- Directory listings of `skills/implement/`, `skills/implement/templates/`, `skills/implement/templates/correctness/`, `skills/implement/templates/thoroughness/`, `skills/plan/`, `skills/parallelize/`, `skills/_shared/`.
