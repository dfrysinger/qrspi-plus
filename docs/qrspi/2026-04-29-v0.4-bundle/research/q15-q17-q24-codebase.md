---
status: draft
question_ids: [15, 17, 24]
research_type: codebase
---

# Q15 + Q17 + Q24: TDD routing, Research→Design handoff, task-spec metadata

## Summary

**TL;DR:** Implement is a 3-layer orchestrator (Implement skill → per-task-orchestrator subagent → implementer + reviewer subagents) where TDD and reviews run only inside layer-3 subagents; Research's `research/summary.md` is the sole upstream artifact Design loads (alongside `goals.md`); task-spec frontmatter has 7 named fields (`status`, `task`, `phase`, `pipeline`, optional `sizing_exception`, optional `fix_type`, plus orphan `goal_id` referenced only in `plan/SKILL.md` prose) parsed by a generic bash YAML parser in `hooks/lib/frontmatter.sh` and consumed for routing by Implement, the per-task orchestrator, Test, Integrate, and Replan.

**Key findings:**
- Q15: TDD lives entirely inside the per-task-orchestrator subagent template (`skills/implement/templates/per-task-orchestrator.md:75-86`); the Implement skill itself never runs tests, reviewers, or fixes (`skills/implement/SKILL.md:19`, `skills/implement/templates/per-task-orchestrator.md:19-31`).
- Q15: The implementer subagent is asked for a RED-GREEN-REFACTOR cycle plus self-review and a status report (`skills/implement/templates/implementer.md:42-52`, `skills/implement/templates/implementer.md:140-152`).
- Q15: 8 reviewer templates exist split into correctness (always) + thoroughness (deep only); spec-reviewer runs first as gate (`skills/implement/templates/per-task-orchestrator.md:99-110`); each evaluates a different lens — e.g. spec-reviewer verifies completeness/scope/interpretation/test-coverage/TDD-evidence/extras/target-file deviation (`skills/implement/templates/correctness/spec-reviewer.md:37-91`).
- Q17: Research produces `research/q*.md` per-question files plus a synthesis returned as text and persisted by the orchestrator to `research/summary.md` (`skills/research/SKILL.md:53`, `skills/research/SKILL.md:85-87`); Design's required inputs are exactly `goals.md` + `research/summary.md` (`skills/design/SKILL.md:51-55`); Design's synthesis subagent reads those two files plus the discussion summary (`skills/design/SKILL.md:82-86`).
- Q17: The handoff is structurally enforced: research subagents never see `goals.md` (`skills/research/SKILL.md:25-29, 35`), and the Research skill's terminal-state pointer to "next skill (typically Design, per the Full route)" is in `skills/research/SKILL.md:153`.
- Q24: Task-spec frontmatter fields appearing in plan templates and in test/integrate writers: `status`, `task`, `phase`, `pipeline` (always); `sizing_exception` (optional); `fix_type` (only on fix tasks); only `status` is parsed by hook code — other fields are read by skill-prose contracts.
- Q24: Per-task input gating reads the task's `pipeline` field (full vs quick) to decide which upstream artifacts to load (`skills/implement/templates/per-task-orchestrator.md:55, 59-67`). Implement skill itself derives mode from `config.md.route` (`skills/implement/SKILL.md:14`), not from task frontmatter.

**Surprises:**
- The plan-defined task frontmatter explicitly comments out the legacy `enforcement` / `allowed_files` / `constraints` per-task fields ("Per-task enforcement fields removed in 2026-04-26 implement-runtime-fix" — `skills/plan/SKILL.md:280-282`), but `tests/fixtures/task-spec-full.md:5-13` still ships those fields, and `hooks/lib/task.sh` still defines `task_resolve_allowlist_paths` consuming an `allowed_files` JSON array — the fixture and hook helper are dead code relative to the current Plan template.
- `goal_id` is required by prose in `skills/plan/SKILL.md:90` ("The `goal_id` field in task frontmatter must match a goal in goals.md"), but it does not appear in the `tasks/task-NN.md` template at `skills/plan/SKILL.md:271-295` and is not parsed by any hook code.

**Caveats:** I traced parsers in `hooks/lib/`; I did not exhaustively scan every reviewer template body for additional frontmatter reads. `skills/implement/templates/thoroughness/*` were not opened beyond the directory listing.

## Full findings

### Q15: Implement TDD routing

#### Per-task-orchestrator steps

The per-task orchestrator subagent template (`skills/implement/templates/per-task-orchestrator.md`) lays out the steps the layer-2 subagent runs:

- "TDD execution per task in its own worktree" (`skills/implement/templates/per-task-orchestrator.md:9`) — orchestrator dispatches an implementer subagent + reviewer subagents and returns terminal status to Implement.
- Iron Law: "NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST" (`skills/implement/templates/per-task-orchestrator.md:13-16`).
- Orchestration boundary: main chat (the orchestrator) only orchestrates — never runs tests, edits files, or commits (`skills/implement/templates/per-task-orchestrator.md:19-31`); the only file main chat authors directly is the per-task review log `reviews/tasks/task-NN-review.md` (`skills/implement/templates/per-task-orchestrator.md:24, 144`).
- Per-task TDD process (run inside the implementer subagent) — read test expectations, write failing tests, verify-fail, write minimal implementation, verify-pass, sanity check + commit (`skills/implement/templates/per-task-orchestrator.md:75-86`).
- Implementer status → orchestrator action table — DONE → dispatch reviewers; DONE_WITH_CONCERNS → log + dispatch reviewers; NEEDS_CONTEXT → re-dispatch implementer; BLOCKED → escalate (`skills/implement/templates/per-task-orchestrator.md:88-98`).
- Review groups: 4 correctness reviewers always, 4 thoroughness reviewers deep-mode only; spec-reviewer first as gate (`skills/implement/templates/per-task-orchestrator.md:99-110`).
- Review fix loop: dispatch reviewer groups → if issues, re-dispatch reviewers (up to 3 convergence rounds) → dispatch implementer-fix subagent (with `SendMessage` persistence after first cycle) → up to 3 fix cycles total (`skills/implement/templates/per-task-orchestrator.md:112-126`).
- Reviewer dispatch wraps untrusted artifacts and (if `codex_reviews: true`) launches a parallel Codex job per template (`skills/implement/templates/per-task-orchestrator.md:128-140`).
- Terminal statuses returned to Implement: DONE, DONE_WITH_CONCERNS, NEEDS_CONTEXT, BLOCKED, or unresolved-after-3-fix-cycles (`skills/implement/templates/per-task-orchestrator.md:237-239`).

#### What implementer produces

The implementer subagent prompt template (`skills/implement/templates/implementer.md`) asks for:

- Strict RED-GREEN-REFACTOR cycle with explicit verify-fail and verify-pass steps (`skills/implement/templates/implementer.md:42-52`).
- Aggressive per-function header comments and per-non-obvious-block "why" comments (`skills/implement/templates/implementer.md:62-94`).
- Self-review on completeness, quality, discipline, testing (`skills/implement/templates/implementer.md:114-137`).
- Status report with status (`DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT`), what was implemented, tests run, files changed, and self-review findings (`skills/implement/templates/implementer.md:140-152`).

#### What reviewer evaluates

Reviewer templates evaluate complementary lenses. spec-reviewer (the gate) is asked to:

- Treat the implementer report as a claim, not evidence — read files, run/read tests, look for what's missing (`skills/implement/templates/correctness/spec-reviewer.md:22-35`).
- Run a 7-item checklist: Completeness, Scope (no extras), Interpretation, Test Coverage (every spec expectation has a test), TDD Evidence (verify-fail seen), Extra Features (no feature flags/extension points), and Target files deviation (advisory) (`skills/implement/templates/correctness/spec-reviewer.md:37-91`).
- The Target-files check is explicitly "advisory, not blocking … Discipline replaces hook-layer allowlist enforcement (dropped in the 2026-04-26 implement-runtime-fix)" (`skills/implement/templates/correctness/spec-reviewer.md:91`).

Other reviewer templates exist at `skills/implement/templates/correctness/code-quality-reviewer.md`, `silent-failure-hunter.md`, `security-reviewer.md`; thoroughness templates at `skills/implement/templates/thoroughness/goal-traceability-reviewer.md`, `test-coverage-reviewer.md`, `type-design-analyzer.md`, `code-simplifier.md`.

Reviewer dispatch contract: each reviewer must embed `skills/_shared/reviewer-boilerplate.md` verbatim, returns the 5-field schema (`finding_id`, `severity`, `change_type`, `message`, `referenced_files`); untrusted artifacts wrapped between `<<<UNTRUSTED-ARTIFACT-START id={artifact_name}>>>` and `<<<UNTRUSTED-ARTIFACT-END id={artifact_name}>>>` (`skills/implement/templates/per-task-orchestrator.md:134-135`).

#### Documentation in implement/SKILL.md

- Layered orchestration is described in `skills/implement/SKILL.md:19`: "Implement skill (this file) is layer 1; it never runs TDD or reviewers itself." Layer-2 = per-task orchestrator subagent (`templates/per-task-orchestrator.md`); layer-3 = implementer + reviewer subagents.
- Iron Law for Implement is "NO TASK DISPATCH WITHOUT APPROVED INPUTS" (`skills/implement/SKILL.md:22-32`).
- Process Steps 1–8 enumerate read inputs, ask phase config, create feature branch, baseline tests, dispatch tasks (per-wave full / per-batch quick), batch gate, route to next step (`skills/implement/SKILL.md:144-171`).
- Phase-Level Configuration (review_depth quick/deep, review_mode single/loop) is asked at the start of each Implement run and written to `config.md` (`skills/implement/SKILL.md:108-115`).
- Wave dispatch flow: verify base resolved, mark in_progress, fire tasks concurrently, wait for terminal status, build stage commit if next wave needs one (`skills/implement/SKILL.md:198-211`).
- Batch gate definition (a) clean / (b) accepted-with-issues / (c) skipped-by-user (`skills/implement/SKILL.md:41-49`); only the user's explicit "continue" releases the loop and routes to the next step (`skills/implement/SKILL.md:218-249`).
- Terminal-state routing reads `config.md.route` and invokes `route[index+1]` (typically `integrate` in full pipeline; `test` in quick fix) (`skills/implement/SKILL.md:257-268`).

### Q17: Research → Design handoff

#### What research/ produces

- Per-question files written by per-researcher subagents to `research/q{NN}-{type}.md` (`skills/research/SKILL.md:53`).
- A synthesis subagent reads all `research/q*.md` files and **returns text** (does not Write directly because of a CC 2.1.x guardrail blocking subagent writes to `^(REPORT|SUMMARY|FINDINGS|ANALYSIS).*\.md$`); the orchestrating skill writes the returned content to `research/summary.md` (`skills/research/SKILL.md:79-87`).
- The summary's frontmatter is `status: draft` initially; on user approval the orchestrator writes `status: approved` (`skills/research/SKILL.md:89-108, 143`).
- A reviewer log `reviews/research-review.md` is also produced (`skills/research/SKILL.md:120, 147`).
- Iron law: research subagents NEVER receive `goals.md` (`skills/research/SKILL.md:25-29, 35-36`).

#### What design/SKILL.md reads

- Design's required inputs: `goals.md` + `research/summary.md`, both with `status: approved` (`skills/design/SKILL.md:51-55`).
- The design synthesis subagent's inputs: `goals.md`, `research/summary.md`, the design discussion summary, prior feedback files (`skills/design/SKILL.md:82-86`).
- Reviewer round inputs: `design.md`, `goals.md`, `research/summary.md` (`skills/design/SKILL.md:140`).
- The per-question `research/q*.md` files are NOT in Design's inputs — only the synthesized `research/summary.md`.

#### Where the handoff is described in prompts

- Research's terminal cross-skill compaction note names the next consumer: "The next skill (typically Design, per the Full route) reads `research/summary.md` + every prior approved artifact" (`skills/research/SKILL.md:153`).
- Design's frontmatter description: "Use when research/summary.md is approved" (`skills/design/SKILL.md:3`).
- Design HARD-GATE: "Do NOT synthesize design.md without approved goals.md AND research/summary.md" (`skills/design/SKILL.md:59-62`).
- using-qrspi documents the handoff at `skills/using-qrspi/SKILL.md:192`: "Design: Requires `goals.md` and `research/summary.md` with `status: approved`."

### Q24: Task-spec frontmatter and metadata fields

#### Schema (every field that appears in any tasks/task-NN.md or template)

| field | type | source (template path) | consumers (file:line) |
|---|---|---|---|
| `status` | string (`draft`/`approved`) | `skills/plan/SKILL.md:273` | `hooks/lib/frontmatter.sh:189-200` (`frontmatter_get_status`); `hooks/lib/pipeline.sh:121-127`; `hooks/lib/state.sh:199, 241`; `hooks/lib/artifact.sh:79`; Iron-Law dispatch gate at `skills/implement/SKILL.md:24-32` |
| `task` | integer (numeric, no padding) | `skills/plan/SKILL.md:274` | per-task review log frontmatter (`skills/implement/templates/per-task-orchestrator.md:154, 232`); also written by Test (`skills/test/SKILL.md:163`) and Integrate (`skills/integrate/SKILL.md:117, 140`) |
| `phase` | integer | `skills/plan/SKILL.md:275` | written by Test (`skills/test/SKILL.md:164`) and Integrate (`skills/integrate/SKILL.md:118, 141`); referenced by Replan reset cascade (`skills/replan/SKILL.md:158`) |
| `pipeline` | enum (`full`/`quick`) | `skills/plan/SKILL.md:276` | per-task orchestrator gates inputs on it (`skills/implement/templates/per-task-orchestrator.md:55, 59-67`); Plan describes who writes it (`skills/plan/SKILL.md:299-303`); Test classifies per-failure (`skills/test/SKILL.md:138-149, 165`); Integrate sets to `full` (`skills/integrate/SKILL.md:99, 119, 142`); Implement baseline-fix inherits run mode (`skills/implement/SKILL.md:179`) |
| `sizing_exception` | optional one-line string | `skills/plan/SKILL.md:277-279` (commented in template) | spec-reviewer flags absence on >200-LOC tasks (`skills/plan/templates/spec-reviewer.md:95, 102, 131`); reduced-rule reminder at `skills/plan/SKILL.md:355, 374, 423` |
| `fix_type` | enum (`integration`/`ci`/`test`) | not in regular task template; written by writers | Plan documents the three values (`skills/plan/SKILL.md:305-310`); Integrate writes `integration` and `ci` (`skills/integrate/SKILL.md:120, 143`); Test writes `test` (`skills/test/SKILL.md:166`); routing reference (`skills/implement/references/fix-task-routing.md:5-11`) |
| `goal_id` | string (matches a goal in goals.md) | NOT in template at `skills/plan/SKILL.md:271-295` | required by prose only at `skills/plan/SKILL.md:90`; no parser reads this field |

Legacy fields present in `tests/fixtures/task-spec-full.md` but removed from the active template:

- `enforcement`, `allowed_files` (list of `{action, path}` objects), `constraints` (`tests/fixtures/task-spec-full.md:5-13`). Plan template explicitly notes these were "removed in 2026-04-26 implement-runtime-fix" (`skills/plan/SKILL.md:280-282`). `hooks/lib/task.sh:62-122` still defines `task_resolve_allowlist_paths` consuming an `allowed_files` JSON array; using-qrspi at `skills/using-qrspi/SKILL.md:336` still describes an advisory scan for `enforcement`, `allowed_files`, `constraints` warnings.

#### How each field is parsed

- Generic YAML-frontmatter parser: `hooks/lib/frontmatter.sh:20-184` `frontmatter_get(file_path, field_name)` — handles scalars, simple lists, nested-list-of-objects (e.g. `allowed_files`), returns JSON. Supports key-pattern `^[a-z_][a-z0-9_]*` (`hooks/lib/frontmatter.sh:103, 127, 151`).
- Status-only convenience wrapper: `hooks/lib/frontmatter.sh:189-200` `frontmatter_get_status` — used by state and pipeline gating.
- Task-spec-specific helpers: `hooks/lib/task.sh:7-32` `task_get_spec_path` (zero-pad task ID); `hooks/lib/task.sh:34-60` `task_read_runtime_overrides` (reads `.qrspi/task-{NN}-runtime.json` runtime sidecar, not frontmatter); `hooks/lib/task.sh:62-122` `task_resolve_allowlist_paths` (consumes the legacy `allowed_files` JSON array).
- `wireframe_requested` is the only artifact-frontmatter field besides `status` parsed in hooks (`hooks/lib/artifact.sh:122-129`); it lives on `design.md`, not on task specs.
- Other task-spec frontmatter fields (`task`, `phase`, `pipeline`, `sizing_exception`, `fix_type`, `goal_id`) are not parsed by any code in `hooks/lib/`; they are consumed via skill prose contracts (LLM reads the file and routes per the documented behavior).

#### How downstream skills route on values

- `status: approved` is the universal gate — Iron Law gates in every skill ("If any required artifact is missing or not approved, refuse to run"), e.g. Implement at `skills/implement/SKILL.md:79-95`, Design at `skills/design/SKILL.md:55`, Plan at `skills/plan/SKILL.md:78-82`.
- `pipeline: full|quick` on a task drives per-task input gating in the per-task orchestrator subagent (`skills/implement/templates/per-task-orchestrator.md:55, 59-67`): full loads `goals.md` + `design.md` + `structure.md` + `parallelization.md`; quick loads `goals.md` + `research/summary.md`. The Implement skill itself does NOT read this — it derives run mode from `config.md.route` (`skills/implement/SKILL.md:14`, `skills/plan/SKILL.md:297-303`).
- `fix_type` selects the `fixes/{type}-round-NN/` directory for fix-task dispatch (`skills/implement/references/fix-task-routing.md:5-11`); routing rules per type:
  - `integration` (Integrate): full-pipeline only; appended to Branch Map (`skills/implement/references/fix-task-routing.md:8`).
  - `ci` (Integrate): same handling as integration (`skills/integrate/SKILL.md:140-143`).
  - `test` (Test): per-failure classification picks `pipeline: quick` or `pipeline: full` for the fix task (`skills/test/SKILL.md:138-149, 163-166`).
- `phase` is informational; Replan cascades reset all `tasks/task-NN.md` plus `parallelization.md` regardless of phase (`skills/replan/SKILL.md:158`).
- `task` is required for the per-task review log frontmatter and must match the numeric task ID (`skills/implement/templates/per-task-orchestrator.md:232`).
- `sizing_exception` is checked by the plan spec-reviewer template against a closed-set of three acceptable reasons (`skills/plan/templates/spec-reviewer.md:95-131`).
- `goal_id` has prose-only enforcement at `skills/plan/SKILL.md:90`; no automated check.
- The pipeline's run mode flows from `config.md` (`route` field is authoritative; `pipeline` field informational), validated by Goals/Plan/Parallelize (`skills/using-qrspi/SKILL.md:475-481`); `config.md` is the "single source of truth for pipeline configuration" (`skills/using-qrspi/SKILL.md:391`).

## Files surveyed

- skills/implement/SKILL.md
- skills/implement/templates/per-task-orchestrator.md
- skills/implement/templates/implementer.md
- skills/implement/templates/correctness/spec-reviewer.md
- skills/implement/references/fix-task-routing.md
- skills/research/SKILL.md
- skills/design/SKILL.md
- skills/plan/SKILL.md
- skills/parallelize/SKILL.md
- skills/test/SKILL.md (referenced)
- skills/integrate/SKILL.md (referenced)
- skills/replan/SKILL.md (referenced)
- skills/using-qrspi/SKILL.md
- hooks/lib/frontmatter.sh
- hooks/lib/task.sh
- hooks/lib/artifact.sh (referenced)
- tests/fixtures/task-spec-full.md
