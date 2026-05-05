# Task Frontmatter Bundle (#94 + #117) — Design Spec

**Date:** 2026-05-05
**Issues:** #94 (lightweight non-TDD path), #117 (Sonnet-default audit + implementer Opus/Sonnet rule)
**Milestone:** v0.5
**Sequencing:** Tier 1 unit 2 of the v0.5 sequencing plan (`docs/superpowers/specs/2026-05-03-v05-sequencing-design.md`).
**Branch:** `qrspi-echo/issues-94-117-task-frontmatter-bundle` off `main` at `eea2c6e`.

---

## 1. Why this is one PR

Both issues add frontmatter fields to `tasks/task-NN.md`, both are written by the Plan skill, and both are consumed by the Implement skill at the same dispatch sites. They share one schema-edit, one Plan-skill heuristic surface, and one Implement-skill routing change. Splitting them would force the second PR to re-touch every file the first touched.

#117 Part 1 (Sonnet-default audit on non-implementer dispatches) is mechanical and adjacent — it ships as the lead commit so the schema work lands on a clean dispatch surface.

## 2. Goals

- A single `task_type` flag on `tasks/task-NN.md` distinguishes runtime-behavior changes (TDD + full reviewer suite) from prose/prompt-shape changes (no TDD, claude-only correctness, capped fix loop).
- A single `model` flag on `tasks/task-NN.md` lets the Plan skill route Opus to high-uncertainty implementer dispatches and Sonnet to everything else, consumed by the existing per-invocation `model` override in the implementer dispatch.
- Existing non-implementer Agent dispatches in `skills/**/SKILL.md` are pinned to Sonnet where they currently inherit, so default-model drift stops being a silent cost lever.
- Implementer agent file boilerplate is split into a shared `implementer-protocol` skill + two thin agent variants — the same pattern we just shipped for the 14 reviewer agents.

## 3. Non-goals

- No change to reviewer model pinning (#101 already locks Sonnet on reviewers).
- No change to `task_type` semantics outside the Implement stage. Other pipeline stages (Research, Design, Plan, etc.) have their own reviewers and do not run a TDD loop, so the field has no meaning there.
- No new value beyond `code | lightweight`. A four-value schema (`code | prompt | prose | config`) was considered and rejected — the four values produced identical Implement-skill behavior.
- No content-aware reviewer subset for lightweight (Option C from the design discussion). All four correctness reviewers fire on lightweight; the marginal token cost of `silent-failure-hunter` and `security-reviewer` running on prose is accepted in exchange for catching prose edits that weaken security/fail-closed invariants.
- No deterministic Plan-skill function for the heuristic — it lives as a prompt section, same as Plan's other classification prompts.

## 4. Schema additions

Two fields added to the `tasks/task-NN.md` frontmatter (split task file format, currently defined at `skills/plan/SKILL.md:336-352`). Both are operator-editable before Implement dispatches.

```yaml
---
status: approved
task: NN
phase: {phase number}
pipeline: full
goal_ids: [G1, G2]
task_type: code        # NEW. one of: code | lightweight. default: code.
model: sonnet          # NEW. one of: sonnet | opus. default: sonnet.
# sizing_exception: <reason>   # existing optional field
---
```

**Defaults.** When the Plan skill omits a field (e.g. legacy plan files predating this schema), Implement reads the missing field as `code` / `sonnet` and logs a warning. No hard failure — backwards compatibility for in-flight plans.

**Override path.** Same as `goal_ids` and `sizing_exception`: the operator edits the file before approving the plan. No dedicated UI.

## 5. `task_type` semantics

| Value | When Plan assigns it | Implement-skill behavior |
|---|---|---|
| `code` (default) | Anything that adds or modifies executable code, tests, schemas, or build/CI config | Full TDD path. Quick or Deep mode per `config.md`. Codex companion per `config.md`. Dispatches `qrspi-implementer`. |
| `lightweight` | All target files match prose/prompt globs (see §6) | No TDD. **Quick mode forced** (4 correctness reviewers). **Codex companion skipped** unconditionally. Dispatches `qrspi-implementer-lightweight`. |

**What lightweight does NOT change.** The per-task fix-loop semantics are inherited unchanged from the existing flow at `implement/SKILL.md:340,541,682`: up to 3 fix cycles (already hardcoded), then unresolved tasks are presented as "accepted-with-issues at the batch gate" (`:541`); the BLOCKED escape hatch (`:319,344` — model switch, task decomposition, or fresh `Agent` dispatch) is available throughout. No new escalation path, no new cap, no new gate. Lightweight is two flag-flips on the existing orchestration shape: skip codex, force Quick.

**Why force Quick + skip codex on lightweight.** The motivation behind #94 is wall-time, not correctness. The lightweight path is for tasks where the artifact has no executable behavior to test and no security/code-quality surface to review against — running thoroughness reviewers or codex companion on prose burns tokens for clean.md sentinels. Forcing Quick + claude-only is the largest wall-time saving available without dropping reviewer coverage on the things that *can* go wrong (spec drift, weakened safety language).

**Why keep all four correctness reviewers on lightweight.** `qrspi-spec-reviewer` and `qrspi-code-quality-reviewer` are obviously load-bearing for prose. `qrspi-security-reviewer` and `qrspi-silent-failure-hunter` will emit `clean.md` sentinels on most prose edits, but the cases where they don't — a prompt edit that weakens a fail-closed rule, a doc edit that exposes a credential location, removal of a security warning from a skill — are exactly the cases where a missing reviewer would be a regression. They run in parallel; wall-time cost is `max(reviewers)`, not `sum(reviewers)`.

## 6. Plan-skill heuristic

A new prompt section in `skills/plan/SKILL.md` instructs the per-task spec-generation sub-subagent to assign `task_type` and `model` together, in that order, per task.

### 6a. `task_type` heuristic

Assign `task_type: lightweight` if **all** target files match one of these globs:
- `skills/**/SKILL.md`
- `skills/**/templates/*.md`
- `agents/qrspi-*.md`
- `docs/**/*.md` (excluding `docs/qrspi/**` — those are pipeline artifacts, not docs)
- `*.md` at repo root (CHANGELOG, AGENTS, README)

Otherwise `task_type: code`.

**Edge cases.**
- Mixed target file lists (one prose file + one code file) → `code`. Lightweight is "all-or-nothing"; any executable surface in the diff promotes the whole task to `code`.
- Frontmatter-only edits to `agents/*.md` (e.g. flipping a `model:` value) → `lightweight` per the glob — this is intentional; that change has no runtime behavior to TDD against.
- New file creation → use the planned final path against the same globs. The path is determined by the task spec, not by `git status`.

### 6b. `model` heuristic

Run after `task_type` is set.

If `task_type == lightweight` → `model: sonnet`. No exception.

If `task_type == code` → `model: opus` if **any** of:
- `Target files` count > 3 (multi-file architectural touch)
- Any target file matches a "core surface" glob: `skills/**/SKILL.md`, `skills/_shared/**`, `agents/qrspi-implementer*.md`, `agents/qrspi-implementer-lightweight*.md`, `skills/reviewer-protocol/**`, `skills/implementer-protocol/**`
- The task is a fix-task spawned by Replan after an earlier fix-round failure (signal: Replan tags it `fix_task_retry: true` in the spec frontmatter)
- The task carries `sizing_exception` (i.e. it's a deliberately-bundled task in the closed exception set — schema migration, CI scaffolding, reusable primitives — and is by construction higher-uncertainty)

Otherwise `model: sonnet`.

**Operator override.** Either field is editable by the operator before plan approval. The Plan skill's heuristic is a default, not a contract. A user who knows a single-file task is actually high-stakes can flip `model: opus` manually; a user who knows a 4-file task is mechanical can flip it back to `sonnet`.

## 7. Implement-skill routing

Implement reads `task_type` and `model` from each `tasks/task-NN.md` at dispatch time. Behavior summary:

```
if task_type == "lightweight":
    review_depth = "quick"               # 4 correctness reviewers, no thoroughness
    codex_enabled = false                # skip all scripts/codex-companion-bg.sh launch sites
    implementer_subagent = "qrspi-implementer-lightweight"
else:
    review_depth = config.review_depth   # quick or deep per config.md
    codex_enabled = config.codex_enabled
    implementer_subagent = "qrspi-implementer"

dispatch: Agent({ subagent_type: implementer_subagent, model: task.model })
```

**Inherited unchanged.** Fix-loop round count (3 cycles, hardcoded), accepted-with-issues batch-gate behavior, and the BLOCKED escape hatch all carry over without modification. Lightweight reuses the existing per-task orchestration loop — only the flags listed above flip.

The codex-launch sites at `implement/SKILL.md:387,395,403,411,419,427,435,443` (per-task reviewer parallel launches) and `:616` (gate-level launch) become conditional on `codex_enabled`. The thoroughness-reviewer dispatch becomes conditional on `review_depth == "deep"`.

The `model:` override on the implementer dispatch already exists at `implement/SKILL.md:284,342,344,346` — this PR populates it from `task.model` instead of defaulting to inherit.

## 8. Implementer refactor — `implementer-protocol` shared skill

The current `agents/qrspi-implementer.md` is split along the same axis we used for #109's reviewer dedupe: shared mechanics in a skill, behavior-specific instructions in the agent files.

```
skills/implementer-protocol/SKILL.md       NEW — shared boilerplate
agents/qrspi-implementer.md                REWRITE — TDD path only, skills: [implementer-protocol]
agents/qrspi-implementer-lightweight.md    NEW — lightweight path only, skills: [implementer-protocol]
```

### 8a. What the shared skill carries

- **Allowed-files contract** (worktree boundary, no edits outside `allowed_files`)
- **Status reporting** (DONE / DONE_WITH_CONCERNS / NEEDS_CONTEXT / BLOCKED — including the BLOCKED escape hatch shape)
- **Mode handling** (`mode: implement` vs `mode: fix` payload shape, including the `companion_review_findings` envelope)
- **SendMessage continuity** rules across fix cycles (one retained agent ID per task; first fix is fresh `Agent`, subsequent are `SendMessage`)
- **ID-Hygiene Contract** (canonical surface list — currently lives in `qrspi-implementer.md` § ID Hygiene; the Plan-skill `ID-Hygiene Contract` section already references this site as single-source-of-truth, so the move just relocates the truth)
- **Dispatch-prompt input contract** (what fields the implementer can expect)
- **Common anti-patterns** (no scope-creep, no out-of-band edits)

### 8b. What `qrspi-implementer.md` keeps (TDD path)

- TDD Process (RED → GREEN → REFACTOR cycle, currently `qrspi-implementer.md:52-138`)
- TDD self-review checklist (currently `:139` — "every test failed before it passed?")
- TDD anti-patterns (currently `:163,169` — "writing production code before a failing test", "weakening assertions to make tests pass")
- Description line: "Per-task TDD implementation subagent."

Frontmatter:
```yaml
---
name: qrspi-implementer
description: Per-task TDD implementation subagent. Handles initial implementation (mode: implement) and fix cycles (mode: fix). Per-task model selection via per-invocation override.
model: inherit
tools: Read, Write, Edit, Bash, Grep, Glob
skills: [implementer-protocol]
---
```

### 8c. What `qrspi-implementer-lightweight.md` carries (new file)

- Single-pass implement instructions (no test-first; just produce the artifact)
- Lightweight self-review checklist:
  - Did I touch only files in `allowed_files`?
  - Does the artifact say what the task spec says it should say?
  - Did I avoid adding tests that don't apply (no scaffolds for prose-only changes)?
  - Did I avoid introducing abstractions or mechanisms beyond the task scope?
- Lightweight anti-patterns:
  - "Don't add a test scaffold just because the implementer agent default expects one"
  - "Don't restructure surrounding prose beyond what the task asks for"
  - "Don't fabricate behavior that doesn't exist in the artifact yet"

Frontmatter:
```yaml
---
name: qrspi-implementer-lightweight
description: Per-task non-TDD implementation subagent for prose / prompt / doc / config tasks (task_type=lightweight). Single-pass implement, no test scaffolding. Per-task model selection via per-invocation override.
model: inherit
tools: Read, Write, Edit, Bash, Grep, Glob
skills: [implementer-protocol]
---
```

## 9. Sonnet-default audit (#117 Part 1)

Inventory every `Agent({ subagent_type: ... })` and `subagent_type:` mention in `skills/**/SKILL.md`. For each dispatch site:

1. If the subagent is a **reviewer** (matches `qrspi-*-reviewer`, `qrspi-silent-failure-hunter`, `qrspi-type-design-analyzer`, `qrspi-code-simplifier`, `qrspi-implement-gate-reviewer`) → already pinned per #101; verify `model: "sonnet"` is explicit; add if inherit.
2. If the subagent is the **implementer** (`qrspi-implementer`, `qrspi-implementer-lightweight`) → leave as `model: "<per-task override>"` per §7 — Part 2 owns this surface.
3. **Everything else** (researchers, scope-tagger if present, synthesis subagents, Goals/Design subagents, replan-analyzer, etc.) → if `model:` is missing, add `model: "sonnet"` explicitly.

This commit produces no behavioral change for sites that were already inheriting Sonnet, and pins the surface so future model-default drift cannot silently move them.

## 10. Sequencing

One PR, one branch, six commits.

| # | Commit | Scope |
|---|---|---|
| 1 | `chore(audit): #117 Part 1 — pin Sonnet on non-reviewer Agent dispatches` | Mechanical; no schema change. |
| 2 | `feat(plan): #94 #117 — add task_type and model to tasks/task-NN.md schema` | Plan-skill template update + Plan-skill heuristic prompt section + plan.md frontmatter validators. |
| 3 | `refactor(implementer): split implementer boilerplate into shared implementer-protocol skill` | New `skills/implementer-protocol/SKILL.md` + slimmed `qrspi-implementer.md` (TDD-only). No behavior change yet. |
| 4 | `feat(implementer): #94 — add qrspi-implementer-lightweight agent` | New `agents/qrspi-implementer-lightweight.md`. Not yet dispatched. |
| 5 | `feat(implement): #94 #117 — route by task_type and model` | Implement-skill routing change at the dispatch sites in §7. Cuts the codex-launch and thoroughness-reviewer gates over to `task_type`-driven flags. |
| 6 | `test(implement): #94 #117 — frontmatter routing + agent split coverage; update CHANGELOG` | New unit tests (per §11) + CHANGELOG.md entry under v0.5. |

Commit 1 is independent and revertible; commits 2–5 form the schema cutover; commit 6 closes out.

## 11. Test plan

Added under `tests/unit/`:

1. **`test-task-frontmatter-schema.bats`** — every `tasks/task-NN.md` template fixture parses with `task_type` and `model` fields; both fields accept their value sets; missing-field defaults are `code`/`sonnet`.
2. **`test-plan-task-type-heuristic.bats`** — fixture-based: a task whose `Target files` are all under `skills/**/SKILL.md` resolves to `lightweight`; a task with one code file mixed in resolves to `code`; root README task resolves to `lightweight`; `docs/qrspi/**` tasks (artifacts, not docs) resolve to `code`.
3. **`test-plan-model-heuristic.bats`** — fixture cases covering: 4-file code task → `opus`; 1-file core-surface code task → `opus`; 1-file non-core code task → `sonnet`; lightweight task → `sonnet` regardless of file count; `sizing_exception` set → `opus`.
4. **`test-implementer-protocol-skill-shared.bats`** — analog of `test-per-finding-file-emission.bats`. Asserts `qrspi-implementer.md` and `qrspi-implementer-lightweight.md` both load `implementer-protocol` via `skills:` frontmatter, and both reference the shared contract by name in their bodies. Asserts `skills/implementer-protocol/SKILL.md` carries the allowed-files / status-reporting / SendMessage-continuity / ID-Hygiene patterns.
5. **`test-implement-routing-by-task-type.bats`** — fixture-based dry-run check: a `tasks/task-NN.md` with `task_type: lightweight` causes Implement to (a) select `qrspi-implementer-lightweight`, (b) skip codex-launch sites, (c) force quick mode, (d) cap fix rounds at 3. A `task_type: code` task takes the existing path.
6. **`test-sonnet-default-audit.bats`** — every `Agent({ subagent_type: "qrspi-*" })` invocation in `skills/**/SKILL.md` either pins `model: "sonnet"` or pins `model: "<per-task override>"`. No bare `Agent({ subagent_type: ... })` without an explicit model on non-implementer subagents. This test is the regression guard for #117 Part 1.

Pre-existing tests touched:
- `test-per-finding-file-emission.bats` — unchanged (this PR doesn't touch reviewer agents).
- Any test that grep'd `qrspi-implementer.md` for the moved boilerplate patterns retargets to `skills/implementer-protocol/SKILL.md` (same retargeting we did for the #109 reviewer protocol move).

## 12. Migration / backward compatibility

- Plan files written before this PR have neither `task_type` nor `model`. Implement reads missing as `code`/`sonnet` (§4) and continues. No forced rewrite.
- `qrspi-implementer.md` retains the same `subagent_type` name. Existing dispatch sites that hardcode `qrspi-implementer` continue to work; the lightweight branch only fires when `task_type: lightweight` is explicitly set.
- The `implementer-protocol` skill move is internal; no external skill or agent refers to the moved sections by file path other than the implementer agents themselves.

## 13. Risks and mitigations

- **Plan-skill misclassifies a task as `lightweight` when it has executable behavior.** Mitigation: glob is conservative (any non-prose target file → `code`). Override is a one-line edit by the operator before approving the plan. `tests/unit/test-plan-task-type-heuristic.bats` pins the boundary.
- **Lightweight path lets a security regression slip through because security-reviewer emits a `clean.md` on prose where it shouldn't.** Mitigation: §5 keeps all four correctness reviewers on lightweight precisely to catch this. The risk is non-zero (clean.md is the default sentinel) but the four-reviewer policy is the deliberate floor.
- **Implementer split causes drift between `qrspi-implementer.md` and `qrspi-implementer-lightweight.md` over time** (the same risk we mitigated for reviewers via `reviewer-protocol`). Mitigation: the shared content lives in `implementer-protocol`; the only divergent surface is the TDD vs lightweight section in each agent file, which is by design.
- **`model: opus` heuristic over-fires on routine multi-file tasks.** Mitigation: the heuristic is editable; the bar for the `> 3 files` rule was set by the issue body, but operators can lower it before approving.
- **Sonnet-default audit accidentally pins a dispatch that should run on Opus.** Mitigation: audit excludes implementer dispatches by name (§9). Reviewers are already Sonnet per #101. No other dispatch in the pipeline is currently expected to run on Opus.

## 14. Open questions (none load-bearing)

- Should `task_type: lightweight` also disable the per-task `goal-traceability-reviewer` and `test-coverage-reviewer` runs? They're in the thoroughness group (already off in Quick mode), so this is moot — flagged here only because the goal-traceability check is conceptually meaningful for prose edits too. Treating as out-of-scope; revisit in #115 if it surfaces.
- Should `implementer-protocol` ship in the same commit as the `qrspi-implementer-lightweight` agent? Sequencing in §10 splits them (commit 3 = move boilerplate, commit 4 = add lightweight agent) so the boilerplate move is reviewable on its own. Not load-bearing — could collapse to one commit if it's smaller in practice.

## 15. Acceptance

This PR ships when:
- Both fields are in the task spec template, defaults documented.
- Plan skill emits both fields on every task it generates.
- Implement skill routes correctly per §7 in the unit tests.
- The `qrspi-implementer.md` body, post-slimming, contains TDD-only content; the `implementer-protocol` skill contains the shared mechanics; `qrspi-implementer-lightweight.md` exists and reads cleanly against a fixture lightweight task.
- `tests/unit/test-sonnet-default-audit.bats` passes.
- CHANGELOG entry under v0.5 names both issues.
