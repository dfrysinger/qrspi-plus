---
name: using-qrspi
description: Use when starting any conversation — establishes the QRSPI pipeline for agentic software development, requiring structured progression through Goals, Questions, Research, Design, Phasing, Structure, Plan, Parallelize, Implement, Integrate, Test, with Replan firing between phases
---

<SUBAGENT-STOP>
If you were dispatched as a subagent to execute a specific task, skip this skill entirely. Do not start a new QRSPI pipeline — just do your assigned work.
</SUBAGENT-STOP>

# Using QRSPI

## Recommended Workspace Layout

Read on demand: `skills/using-qrspi/references/workspace-layout.md` — recommended on-disk layout for a multi-run project.

## The Pipeline

Read on demand: `skills/using-qrspi/references/pipeline-overview.md` — full + quick-fix pipeline diagrams plus the per-step what/why/artifact table.

## Route Templates

Read on demand: `skills/using-qrspi/references/route-templates.md` — `config.md.route` templates (quick / full / full-plus-UX) and the mid-pipeline route-change rules.

## When to Trigger

Any time the user wants to build something — a feature, a fix, a project. If there's intent to write code, QRSPI applies. Default is always start with Goals and proceed through every step.

## Artifact Directory

Read on demand: `skills/using-qrspi/references/artifact-directory.md` — full per-run on-disk tree (`docs/qrspi/YYYY-MM-DD-{slug}/...`) and slug-generation rule.

## Approval Markers

Read on demand: `skills/using-qrspi/references/approval-markers.md` — `status: approved` semantics, `replan-draft` transient state, and the post-approval git-commit rule.

## State and Pipeline Ordering

Pipeline state is derived from artifact frontmatter; the only piece of derived state worth persisting is `phase_start_commit` (lives in `plan.md` frontmatter, scoped by Replan and Test).

Read on demand: `skills/using-qrspi/references/state-and-pipeline-ordering.md` — predecessor-approval gating, the Implement batch trap. Orchestration-boundary enforcement lives in each phase SKILL (`implement/`, `integrate/`, `test/`).

## Rejection Behavior

When the user rejects an artifact at any human gate, the orchestrator launches a new subagent round with the original inputs plus a feedback file containing the rejected artifact and the user's feedback. Rejection re-runs the current step with feedback until approved — never skips backward.

## Backward Loops (New Learnings)

Read on demand: `skills/using-qrspi/references/backward-loops.md` — cascade-forward rule when a downstream step surfaces new learnings about an upstream artifact.

## Mid-Pipeline Entry

Users can enter mid-pipeline when required input artifacts already exist with `status: approved`; mid-pipeline resume also detects `replan-pending.md` to resume Replan when set.

Read on demand: `skills/using-qrspi/references/mid-pipeline-entry.md` — full resume contract and the existing-artifacts handshake.

## Pipeline Progress

Read on demand: `skills/using-qrspi/references/pipeline-progress.md` — diagnostic for "where am I in the pipeline" when status is unclear.

## Artifact Gating Check (Standard Pattern)


Every skill uses this standard pattern to verify its prerequisites:

1. Read the required artifact file
2. Parse YAML frontmatter (content between first two `---` markers)
3. Check that `status` field equals `approved`
4. If file missing: "Cannot proceed — {artifact} not found. Complete the {previous step} step first."
5. If file exists but not approved: "Cannot proceed — {artifact} exists but hasn't been approved yet. Review and approve it first."

## Config File (`config.md`)

`config.md` lives in the artifact directory and is written during the Goals skill (after the artifact directory is created). It is the single source of truth for pipeline configuration.

**Full format:**

```yaml
---
created: YYYY-MM-DD
pipeline: full  # or: quick
second_reviewer: true  # or false
route:
  - goals
  - questions
  - research
  - design
  - phasing
  - structure
  - plan
  - parallelize
  - implement
  - integrate
  - test
review_depth: deep  # or: quick — added by Implement at phase start
review_mode: loop   # or: single — added by Implement at phase start
verifier_enabled: true  # set at run creation; edit directly between rounds to disable for the whole run
scope_tagger_enabled: true  # set at run creation; edit directly between rounds to disable convergence narrowing for the whole run
visual_fidelity_required: false  # set at run creation; when true, activates the visual-fidelity binding chain (design → phasing → plan → implement reviewer)
question_budget: 5  # integer; written only when pipeline: quick (caps Research specialist dispatch count for the run)
---
```

**Field definitions:**
- `created`: ISO date the run was created (set once, never updated)
- `pipeline`: human-readable label (`full` or `quick`) — informational only; `route` is authoritative
- `second_reviewer`: include a second-model reviewer in review rounds
- `route`: ordered list of skill names this run will execute (see Route Templates above)
- `review_depth`: `quick` (4 correctness reviewers) or `deep` (all 8) — written by Implement at phase start
- `review_mode`: `single` or `loop` — written alongside `review_depth`
- `verifier_enabled` (default `true`): gates `qrspi-finding-verifier` parallel dispatch + `change_type` score filtering. `false` skips dispatch; all findings flow via "no sidecar → keep"
- `scope_tagger_enabled` (default `true`): gates `qrspi-scope-tagger` per-round dispatch and convergence narrowing
- `visual_fidelity_required` (default `false`): activates the visual-fidelity binding chain (Design → Phasing → Plan → Implement reviewer)
- `question_budget` (default `5`, range 1-50): caps Research specialist dispatch under `pipeline: quick`. Written ONLY when `pipeline: quick`; absent on full-pipeline runs

A stray legacy `codex_reviews:` field is a hard validation error — never silently aliased to `second_reviewer:`.

**Writing `config.md`:** After the user selects a pipeline mode and answers the second-reviewer question, Goals writes `created`, `pipeline`, `second_reviewer`, `route`, `verifier_enabled: true`, `scope_tagger_enabled: true`, and `visual_fidelity_required` atomically. On `pipeline: quick`, Goals additionally writes `question_budget: 5`. `review_depth` and `review_mode` are added later by Implement.

**Behavioral semantics — `pipeline: quick` (auto-approve cascade and surviving human gates):**

1. **Auto-approve cascade for Questions, Research, and Plan.** These three autonomous steps still run their full review loops (Claude reviewers, second-model reviewers, the verifier); findings still write to disk under `reviews/{step}/round-NN/`. The cascade auto-writes `status: approved` when a round produces zero kept findings AFTER verifier filtering (initial-clean OR first-fix-clean). The cascade is a single hop per step; if the fix round still carries kept findings, the step pauses via the standard Review-Loop Pause Gate. Per-skill cascade wiring lives in each skill body.

   **Trust model.** The cascade trigger reads the orchestrator's in-session "kept findings" count after fan-in; it does NOT read any on-disk `<reviewer-tag>.clean.md` sentinel. The on-disk sentinel is audit-trail, NOT trigger. The orchestrator is the EXCLUSIVE writer of the cascade clean sentinel (and of `path-filtered.md` and `bypass-attempt-NN.md` records); reviewer subagents MUST NOT write or emit the cascade clean sentinel. Pinning the trigger to the in-session count closes the clean-sentinel forgery surface.

   **Cascade audit log.** Every cascade auto-approval event MUST append-only a `cascade-auto-approve` JSON Lines entry to `<artifact_dir>/cascade-audit.log` BEFORE writing `status: approved`. The entry records the artifact name, ISO-8601 UTC timestamp, trigger round, contributing reviewer tags + sentinel file paths, and rationale (`initial-clean` or `first-fix-clean`). On audit-log write failure, HALT the cascade — same hard-stop pattern as the runtime-backfill write-back failures.
2. **Two mandatory human gates: Goals and Design (excluded from the cascade).** Goals captures user intent; Design captures the option-selection decision. The canonical Quick-Fix route omits Design; the exclusion-from-cascade contract applies whenever Design runs.
3. **Test phase: binary ship/fix gate.** Test under `pipeline: quick` presents a binary ship-or-fix decision rather than the multi-option per-failure menu. "ship" terminates; "fix" routes back to **Plan** and the fix round resumes from Plan onward.

**Second-model-reviewer detection:** Run `bash scripts/second-reviewer-available.sh`. On non-zero exit, skip the second-reviewer question and write `second_reviewer: false`. `second_reviewer: true` dispatch reuses the resolved agent `tier:` for both primary and second reviewer (no separate tier knob). If the probe exits 0, ask:

> Second-model reviews:
> 1) No second-model reviews
> 2) Use a second model for second reviews

**Per-host second-reviewer dispatch transport.** Host detection and per-host dispatch transport (Copilot CLI task-tool vs Claude Code shell-pipeline via `scripts/dispatch-agent.sh`) are owned by `scripts/_host-detect.sh` and `scripts/detect-interaction-mode.sh`. The dispatch surface emits a single-line stderr diagnostic on host/config mismatch and continues with the configured policy.

**No silent fallback.** All skills read `config.md` for route and second-reviewer config. Missing or invalid fields go through the **Config Validation Procedure**; no field is silently defaulted, and route is never derived from `pipeline`.

### Dispatch routing blocks

Four `config.md` blocks drive dispatch: `providers:`, `model_routing:`, `trusted_path:`, `validators:`. Implementation lives in `scripts/_resolve-lib.sh` (tier resolution) and `scripts/dispatch-agent.sh` (request transport, trusted_path short-circuit, validators). `model_routing:` is required; the other three are optional. Validation rules and fail-loud diagnostics live in `skills/_shared/config-validation-procedure.md` — `!cat`-included by every skill that reads routing config.

**`providers:` block** — map of named provider entries. Each entry: `base_url` (HTTP(S) endpoint root), `api_key_env` (name of the env var holding the API key — never the key itself), `transport_type` (exactly `openai-chat-completions` or `codex-broker`), optional `default_headers` (string map merged into every request).

```yaml
providers:
  my-provider:
    base_url: https://api.example.com/v1
    api_key_env: MY_PROVIDER_API_KEY
    transport_type: openai-chat-completions
```

**`model_routing:` block (required)** — maps five vendor-neutral routing tiers to concrete `(vendor, model)` pairs. `default_tier:` supplies the tier for agents missing a `tier:` field during migration.

```yaml
model_routing:
  extra-low:  none                                              # operator opts in
  low:        { vendor: claude, model: claude-haiku-4.5 }
  medium:     { vendor: claude, model: claude-sonnet-4.6 }
  high:       { vendor: claude, model: claude-opus-4.7 }
  extra-high: { vendor: claude, model: claude-opus-4.7-high }
default_tier: medium
```

Exactly five tier rows. `extra-low` defaults to `none` (operator opt-in). `extra-high` is the high-ceiling escalation tier; operator MAY set to `none` to opt out. Missing block is a hard validation failure — no silent fallback to agent-bundled defaults (G7b/#204 silent-fallback class).

**`trusted_path:` block** — flat list of agent file paths or role names that bypass the tier chain and route to the agent-bundled default.

```yaml
trusted_path:
  - agents/qrspi-implementer.md
  - reviewer
```

**`validators:` block** — post-dispatch output gates.

```yaml
validators:
  citation_density_floor: 0.05   # default: 0.05
```

`citation_density_floor` triggers a trusted-model re-run when output falls below the floor; the re-run output replaces the original and is logged as a one-line note.

**Precedence chain** (implemented by `scripts/_resolve-lib.sh resolve_tier`): `--tier-override` > agent `tier:` frontmatter > `default_tier:` > hardcoded `medium` with a loud warning. The resolved tier is then looked up in `model_routing:`. `trusted_path:` is a short-circuit ahead of this chain — matching agents/roles bypass tier resolution entirely. Every fallback layer halts loudly on unresolved routing targets — never silently falls back through to the host CLI.

## Config Validation Procedure

Run `tests/fixtures/validate-config-field.sh <field> <artifact_dir>` before using any field. The script exits 0 on success and exits 1 with the numbered repair menu when the field is missing or invalid (artifact-dir-missing → "Re-run Goals to create config.md and set the pipeline mode"; field-specific menus follow the same shape: "Edit config.md and set `<field>` to a valid value", then "Abort"). The shared canonical rule for `model_routing:` missing/malformed lives in `skills/_shared/config-validation-procedure.md`.

### No silent defaults

Skills must not:
- Assume `pipeline: full` when `pipeline` is missing
- Assume `second_reviewer: false` when `second_reviewer` is missing
- Derive `route` from `pipeline` when `route` is missing
- Proceed with a guessed or inferred field value

### Exceptions to the no-silent-defaults rule (runtime backfill)

Three fields carve out runtime backfill: `verifier_enabled` (default `true`), `scope_tagger_enabled` (default `true`), `visual_fidelity_required` (default `false`). When any is missing on the first protocol-aware invocation, the runtime treats it as the default, surfaces a one-line stderr warning once per session (`<field> missing from config.md — backfilling default '<value>' for this run`), and writes the field back to `config.md`.

**Hard-stop on write-back failure.** The write-back is part of the carve-out contract, not a best-effort side effect. If the write fails (read-only fs, permission, lock, disk full), the runtime MUST stop issuing tool calls and present:

>   failed to write `<field>` to config.md — resolve before continuing
>
>   1) Resolve the underlying write failure (fix permissions, free disk space, release the lock) and re-invoke the current skill to retry
>   2) Abort

Do NOT silently fall back to the in-memory default after a failed write: a mismatch with on-disk state re-fires the backfill (re-warns, re-attempts) indefinitely. Hard-stop is the only correct path.

### Fields that affect pipeline behavior (must be validated)

| Field | Skills that validate it | Valid values |
|-------|------------------------|--------------|
| `route` | Goals, Plan, Parallelize, Implement, Integrate, using-qrspi | ordered list of skill names (see Route Templates) |
| `model_routing:` | using-qrspi, Goals, Plan, Parallelize, Implement, Integrate | required top-level block; see schema above |
| `pipeline` | Goals, Plan, Parallelize | `full` or `quick` |
| `second_reviewer` | Goals, Plan, Design, Phasing, Structure, Replan, Implement, Integrate, Test | `true` or `false` |
| `review_depth` | Implement | `quick` or `deep` — set by Implement at phase start |
| `review_mode` | Implement | `single` or `loop` — set by Implement at phase start |
| `verifier_enabled` | Goals, Implement | `true` or `false` — gates per-finding verifier dispatch in apply-fix |
| `scope_tagger_enabled` | Goals, Implement | `true` or `false` — gates per-round scope-tagger dispatch and convergence narrowing |
| `visual_fidelity_required` | Goals, Design, Phasing, Plan, Implement | `true` or `false` — gates the visual-fidelity binding chain |
| `question_budget` | Goals, Plan, Parallelize (validators); Research (runtime consumer) | integer 1-50; present when `pipeline: quick`, absent when `pipeline: full`; caps Research specialist dispatch count |

### Fields that do NOT require validation (informational only)

`created` — ISO date, informational only; missing is not an error.

## Standard Review Loop

Every artifact-producing step runs the Standard Review Loop. Read on demand: `skills/_shared/review-loop.md` (canonical SSoT — checklist + reviewer dispatch shape + fix-loop convergence rule). Sweep-task findings ride the existing Plan re-spec loop (no new gate, no new runner behavior).

## Apply-Fix Protocol

After each review round, the orchestrator invokes `scripts/review-prep.sh` (per-round diff emission with anchor-SHA narrow-ref, atomic temp+rename) then `scripts/verifier-fan-in.sh` (SSoT for verifier dispatch, change_type-keyed score filters, `round-NN-verified.md` assembly). Read on demand: `skills/using-qrspi/references/apply-fix-protocol.md` for the full post-fan-in procedure (partition by change_type, scope-tagger dispatch, dispositions.md, per-round commit, convergence rule, backward-loop reset, reviewer-model audit-field, verifier-round failure menu). Read on demand: `skills/using-qrspi/references/fix-altitude-rule.md` for the F-5 "X is under-specified" rule.


## Review-Loop Pause Gate

Inside an autonomous review loop (option 2 from the Standard Review Loop), the loop **pauses** when reviewers surface findings the orchestrating skill cannot safely auto-apply. The 10-round review-loop cap **does not decrement on a paused round** — paused rounds are user-interactive, not autonomous.

Read on demand: `skills/using-qrspi/references/review-loop-pause-gate.md` — full BATCH-WITH-OVERRIDES UI contract, 3-option menu (apply / skip / loop-back to upstream), infinite-pause escape hatch, and pending-findings audit-file shape.

## Compaction Checkpoints

QRSPI skills mark transition points where main-chat context bloat degrades downstream quality. At every checkpoint and at every user-input pause, the orchestrator follows the Iron Rule below — regardless of perceived utilization, regardless of auto-mode.

**Iron Rule.** Pause and recommend `/compact` to the user before continuing. The user can decline; do not skip the recommendation.

Read on demand: `skills/using-qrspi/references/compaction-checkpoints-detail.md` — full list of checkpoint trigger points per pipeline step.

## Feedback File Format

When a user rejects an artifact, the feedback is captured in `{artifact-dir}/feedback/{step}-round-{NN}.md`:

```markdown
---
step: {step name}
round: {rejection round number}
rejected_artifact: {path to rejected artifact}
---

## User Feedback
{The user's rejection feedback, verbatim}

## Previous Artifact
{The full content of the rejected artifact}
```

The new subagent receives the original inputs + this feedback file.

## Common Rationalizations — STOP


These thoughts mean the pipeline is being bypassed. Stop and follow the process:

| Rationalization | Reality |
|----------------|---------|
| "This is too simple for the full pipeline" | Quick-fix mode exists for simple changes. Use it — don't skip the pipeline entirely. |
| "I already know the answer, skip Research" | Research prevents confirmation bias. What you "know" may be outdated or incomplete. |
| "The goals are obvious, skip Goals" | Goals captures the problem framing every downstream artifact traces to. Without it, you can't articulate what success means at the goal level (acceptance criteria themselves are authored downstream in `plan.md` per the strip-from-goals contract, but they trace back to goals). |
| "Let me just start coding" | Code without a plan means rework. Even quick fixes go through Goals → Questions → Research → Plan. |
| "I can design and implement at the same time" | Design and implementation are separate context windows. Mixing them produces underthought architecture. |
| "This fix doesn't need questions" | Questions identify what you need to learn. Skipping them means you'll discover gaps mid-implementation. |
| "The user said to skip ahead" | The user can request mid-pipeline entry with existing artifacts. They cannot skip steps — each produces a contract downstream steps depend on. |
| "I'll come back and do the reviews later" | Reviews catch issues cheaply. Deferring them means expensive rework. |

## Pipeline Iron Laws — Final Reminder

The four invariants that, when violated, produce the most damage:

1. **Each step requires its declared inputs approved.** Artifact gating is not advisory — skills refuse to run without approved prerequisites. Do not "skip ahead." Use mid-pipeline entry only with the existing-artifacts contract.

2. **`status: approved` in YAML frontmatter is the only approval marker.** Pipeline progression is derived from frontmatter — no state cache file gates ordering. The single piece of derived state worth persisting (`phase_start_commit`) lives in `plan.md` frontmatter; see `plan/SKILL.md`.

3. **Backward loops cascade forward — never patch one artifact in isolation.** New learnings at step N require updating the earliest affected artifact, re-reviewing it, and re-approving every step from there to N. Drift between artifacts breaks every downstream contract.

4. **The `Implement → Integrate` segment is per-phase, not per-task.** Implement runs once per phase; main chat itself is the per-task orchestrator, firing implementer + reviewer subagents per task in the wave (flat dispatch — no per-task orchestrator subagent). Integrate runs once per phase. "One task done" does NOT mean "advance to integrate" — verify against `parallelization.md` (every task in the phase) before routing forward. See `implement/SKILL.md` → "Implement Is the Per-Phase Orchestration Loop" for the canonical contract.

<BEHAVIORAL-DIRECTIVES>
D1 — Encourage reviews after changes: After any significant change to an artifact (whether from feedback, a fix round, or a re-run), recommend a review before proceeding. Reviews catch regressions that are invisible during forward-only execution.

D2 — Never suggest skipping steps for speed: Every step in the QRSPI pipeline exists for a reason. Do not offer shortcuts, suggest merging steps, or imply steps can be skipped to save time.

D3 — Resist time-pressure shortcuts: There is no time crunch. LLMs execute orders of magnitude faster than humans. There is no benefit to skipping LLM-driven steps — reviews, synthesis passes, and validation rounds cost seconds. Reassure the user that thoroughness is free. If the user signals urgency ("just move on," "skip the review this time"), acknowledge the constraint and offer the fastest compliant path. Do not use urgency as justification to skip required steps.

D4 — Use jargon-free language with the user: In user-facing text (questions, status updates, design proposals, summaries), do not use issue numbers, ticket IDs, goal IDs (G1/G2/…), agent file names, skill names, `change_type` values (the per-finding routing categories: style/clarity/correctness/scope/intent), file paths, or other internal terminology without grounding them in plain English on first reference per response. Subagent dispatch prompts and structured artifacts may use full vocabulary — those are read by agents that already have the context loaded; the rule applies only to text the user reads directly.

Example: instead of "the qrspi-finding-verifier from #109 was added with verifier_enabled: true default," write "the verifier — a small fast model that scores each finding 0–100 — was turned on by default in a recent change." Orchestrators tend to lean on jargon under context pressure, exactly when this guidance matters most.
</BEHAVIORAL-DIRECTIVES>
