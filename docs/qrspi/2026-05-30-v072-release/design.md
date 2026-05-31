---
status: draft
---

# v0.7.2 Design — Locked Decisions (working scratchpad)

This file accumulates per-goal locked decisions during Design Phase 1 (per-goal walkthrough)
as a durable backup against compaction. The eventual Design synthesis subagent should consume
this file alongside goals.md + research/summary.md.

Each entry is a final form: outcome + solution + dependencies + acceptance criteria, NOT a
full architecture/test spec (those belong to Structure and Plan respectively per CD on
Design's revised scope).

---

## Cross-Goal Decisions (CD)

### CD-1 — Universal dispatch architecture

**Scope:** Affects G3, G4, G6, G19, G20, G22, G25; informs all skill-prose dispatch sites across the 12 consumer skills (goals, questions, research, design, structure, phasing, plan, parallelize, replan, implement, integrate, test).

**Outcome.** All agent dispatches across all skills go through a single bash entry point that
handles host detection, vendor selection, tier resolution, diff/ref preparation, and dispatch
manifest persistence. Skill prose names only the agent; the script chain handles everything else.

**Solution components:**

1. **Agent-owned tier (with override).** Every agent frontmatter declares `tier:` ∈
   `{low, medium, high, extra-high}`. Call sites can pass `--tier-override` (used by
   plan→implementer for per-task complexity variance). Override precedence (top wins):
   1. `--tier-override` flag at dispatch site
   2. Agent's `tier:` frontmatter
   3. `default_tier:` in config.md (for agents missing `tier:` during migration)
   4. Hard-coded fallback `medium` with loud warning

2. **Config-owned vendor+model mapping.** `config.md` carries:
   ```yaml
   model_routing:
     low:        { vendor: claude, model: claude-haiku-4.5 }
     medium:     { vendor: claude, model: claude-sonnet-4.6 }
     high:       { vendor: claude, model: claude-opus-4.7 }
     extra-high: { vendor: claude, model: claude-opus-4.7-high }
   ```
   Goals skill onboarding asks 4 questions to populate this (one per tier) with vendor-neutral
   defaults. `none` is a valid answer per tier.

3. **`scripts/dispatch-agent.sh` — universal entry point.** Skill prose calls (batched form — N reviewers per round resolved in one invocation):
   ```sh
   scripts/dispatch-agent.sh --step <step> --round <N> --output-dir <round-dir> \
     --artifact <artifact-name> \
     --agents tag1=agent-name-1,tag2=agent-name-2,... \
     [--task-branch <worktree-path> --implementer-commit <40-char-SHA>] \
     [--tier-override tag1=high,tag2=medium,...]
   ```
   Behavior:
   - Check `<output-dir>/.round-prepare.json`; if absent, auto-invoke `round-prepare.sh` (G4), forwarding `--task-branch` and `--implementer-commit` when set (the pair is required together on per-task invocations per G4 solution step 1; rejected with diagnostic on partial use).
     Idempotent + atomic mv pattern, no flock needed.
   - **`--implementer-commit` provenance + recovery routing.** When per-task review is following an implementer dispatch, main chat sources the SHA from the implementer subagent's self-reported `commit_sha:` field (per `implementer-protocol/SKILL.md` § Report Format). The Task tool return is only visible to main chat; the script chain has no other access to that value, which is why the SHA must thread through the dispatch invocation rather than being recomputed in the script. `round-prepare.sh` owns all three SHA-correctness checks (within-round equality, across-rounds advance, missing-flag) per G4 solution step 1; dispatch-agent.sh propagates round-prepare.sh's exit code verbatim so main chat sees the script's exit code from its bash invocation. Main chat's between-rounds residual is narrow: read `commit_sha:` from the Task return (re-dispatch implementer immediately if it's missing, do not invoke dispatch-agent), invoke dispatch-agent with the SHA, branch on exit code per the recovery table in G4 solution step 1 (exit 10 → halt orchestrator bug; exit 11 → halt worktree integrity break; exit 12 → re-dispatch implementer; exit 0 → proceed). See G9 layer 3 for the full architecture.
   - For each `tag=agent` pair in `--agents`:
     - Resolve agent tier → vendor → model via `_resolve-lib.sh`.
     - Detect host via `_host-detect.sh` (COPILOT_CLI=1, CLAUDE_PROJECT_DIR, future CODEX env).
     - Look up (host, vendor) in matrix → first-party or third-party.
     - PATH A (first-party): assemble the full reviewer prompt (reviewer-protocol body + agent body + `first-party-emission.md` + dispatch params: wrapped artifact_body, round_subdir, reviewer_tag, diff_file_path, scope_hint) and write it to `PROMPT_FILE=/tmp/qrspi-dispatch-<round-id>-<tag>.prompt`. Emit a single Task-tool spec line to stdout:
       ```
       MODE=first_party TAG=<tag> SUBAGENT_TYPE=<agent-name> MODEL=<resolved-model> PROMPT_FILE=<absolute-path>
       ```
       Append entry to `.dispatch-manifest.json` with `mode: first_party`, `status: dispatched`. The prompt content is NEVER echoed to stdout — only the spec line.
     - PATH B (third-party): invoke `dispatch-companion.sh` to launch background; capture jobId; append entry to `.dispatch-manifest.json` with `mode: background`, `status: pending`, `await_cmd`, `split_cmd`. No spec line emitted on stdout (background-only — orchestrator drives third-party entirely via `await-round.sh`).
   - After all pairs processed: skill prose iterates the emitted first-party spec lines (one per first-party reviewer) and invokes the Task tool M times in parallel (M = first-party count; Task tool calls are an LLM-side tool-call boundary that cannot be moved into bash). Each Task call passes the spec's `SUBAGENT_TYPE`, `MODEL`, and a single-line `prompt` argument of the form `"DISPATCH_FILE=<absolute-path-from-PROMPT_FILE>"`. The subagent's first instruction (per the reviewer agent body) is "**Read your `DISPATCH_FILE` as your full dispatch before doing anything else**" — the subagent's own Read populates its context with the full prompt; the orchestrator's context never holds the prompt body.
   - **Iron law (orchestrator side):** invoke Task tool exactly once per emitted spec line, with `SUBAGENT_TYPE`, `MODEL`, and `PROMPT_FILE` copied verbatim. Skipping lines, deduplicating, modifying values, or reordering parameters is a contract violation that the manifest gap catches at apply-fix step 2 ("expected tag produced no output").
   - Emit a loud one-liner to stderr describing what was done across the whole batch (host-relative routing audit signal).
   - **PROMPT_FILE lifecycle:** files live under `/tmp/qrspi-dispatch-<round-id>-<tag>.prompt`. Written by dispatch-agent; cleaned by `await-round.sh` after `.round-complete.json` is written. Round-scoped, never session-scoped. Path is absolute (no relative paths that depend on the subagent's working directory).
   - **Spec line format:** shell-style `KEY=VALUE` pairs, space-separated, one line per dispatch, no quoting (values contain no spaces — paths use no-space chars; tag names are dash-separated; agent names are dot-separated). LLM-parseable, grep-friendly for the orchestrator's loud-failure debug case (`grep '^MODE=first_party' <bash-result>` yields all dispatches).
   - **Bash surface per round = 1 call** (this batched dispatch) regardless of reviewer count. Orchestrator context cost = M spec lines (small, ~150 bytes each) + the small `DISPATCH_FILE` reference passed to each Task tool. The single-reviewer form (`--agent <name> --tag <tag>`) is supported for ad-hoc invocations but the per-skill review-round prose uses the batched form.

4. **`scripts/await-round.sh` — manifest-driven async await.**
   ```sh
   scripts/await-round.sh --round-dir <reviews/{step}/round-NN/>
   ```
   Reads `.dispatch-manifest.json`; awaits all `mode: background` entries with `status: pending`;
   runs splitters; updates statuses; writes `.round-complete.json` summary. LLM only needs to
   remember step + round number; manifest path is deterministic.
   - **No-op-safe when manifest has zero background entries.** First-party-only rounds still call `await-round.sh` unconditionally; it returns immediately after reading the manifest. Orchestrator does not pre-check the manifest shape — invocation is uniform per round.
   - **Output-bound contract** (lifted from G6 to keep the calling-surface guarantees in one place): `await-round.sh` MUST NOT echo captured third-party subagent stdout (or any substring of it) to its own stdout or stderr. Its terminal output is bounded to: (a) one short status line summarizing the round (dispatches awaited / with findings / clean), (b) per-dispatch status updates already persisted to `.dispatch-manifest.json` and `.round-complete.json` on disk. Raw third-party payloads stay captured in tempfiles within the script chain and are consumed only by `third-party-finding-splitter.sh`. Any future maintainer change that adds `cat`-of-captured-tempfile or equivalent payload echo is a context-leakage violation (G3 concern). Lint candidate: a smoke test that runs `await-round.sh` against a fixture with a known-large third-party payload and asserts the script's combined stdout+stderr is under a small byte cap (~1KB).

5. **`scripts/dispatch-companion.sh`** (rename of `run-third-party-llm.sh`) — vendor-routing tier
   underneath dispatch-agent. Takes `--vendor` + resolved `--model`; routes to vendor-specific
   transport (`codex-companion-bg.sh` today; future `deepseek-companion-bg.sh`).

6. **`scripts/third-party-finding-splitter.sh`** (rename of `codex-finding-splitter.sh`) —
   splits third-party reviewer output into per-finding files. Called by `await-round.sh`.

7. **`scripts/_resolve-lib.sh`** — shared library: agent-frontmatter parsing, tier→vendor+model
   resolution, host × vendor matrix lookup. Single source of truth for resolution algorithm.

8. **`scripts/_host-detect.sh`** — shared library: host detection from environment variables.

9. **File-based dispatch manifest.** Path: `reviews/{step}/round-NN/.dispatch-manifest.json`.
   Schema: array of dispatch entries with `tag`, `agent`, `mode`, `dispatch_spec` (first-party)
   OR `job_id` + `await_cmd` + `split_cmd` (third-party), `status`. Survives compaction; serves
   as audit log and resume index.

10. **Host × vendor matrix** (lives in `_resolve-lib.sh` or sidecar data file):

    | Host          | Claude        | Codex         | DeepSeek (v0.7.3+) |
    |---------------|---------------|---------------|--------------------|
    | Claude Code   | first-party   | third-party   | third-party        |
    | Codex CLI*    | third-party   | first-party   | third-party        |
    | Copilot CLI   | first-party   | first-party   | third-party        |

    *Codex CLI host support deferred to v0.7.3+.

11. **`skills/_shared/reviewer-dispatch-prose.md` — shared orchestrator-side dispatch instructions.** Single source of truth for the per-skill review-round prose. Carries: the `dispatch-agent.sh` invocation pattern (batched form), the spec-line parse instructions, the per-line Task tool invocation contract (one Task call per spec line, verbatim values, `prompt = "DISPATCH_FILE=<path>"`), the iron law forbidding skipped/deduplicated/modified Task calls, and the `await-round.sh` follow-up. `!cat`-included into every consumer skill (precedent: `_shared/precondition-block.md`, `_shared/evergreen-output-rule.md` per CD-2).

    Each consumer skill's review-round section reduces to:
    1. A skill-specific preamble setting the dispatch parameters (`$REVIEW_STEP`, `$REVIEW_ROUND`, `$REVIEW_OUTPUT_DIR`, `$REVIEW_ARTIFACT`, `$REVIEW_AGENTS`) — varies per skill because the agent list differs (e.g., goals dispatches `quality-claude` + `scope-claude` + Codex peers when `codex_reviews: true`; design dispatches the design-reviewer + scope-reviewer set; plan dispatches the four plan-specific reviewers).
    2. The `!cat ${CLAUDE_SKILL_DIR}/../_shared/reviewer-dispatch-prose.md` include.

    The snippet itself is generic — it does NOT enumerate agent names, step names, or per-skill artifact names. Those flow in via the dispatch parameters the preamble sets.

    Consumers to update (replace existing per-reviewer Claude+Codex dispatch blocks with preamble + `!cat`):
    - `skills/goals/SKILL.md`
    - `skills/questions/SKILL.md`
    - `skills/research/SKILL.md`
    - `skills/design/SKILL.md`
    - `skills/structure/SKILL.md`
    - `skills/phasing/SKILL.md`
    - `skills/plan/SKILL.md`
    - `skills/parallelize/SKILL.md`
    - `skills/replan/SKILL.md`
    - `skills/implement/SKILL.md`
    - `skills/integrate/SKILL.md`
    - `skills/test/SKILL.md`

    Snippet body (locked prose — author this exact text into `skills/_shared/reviewer-dispatch-prose.md`; values in `$VARNAME` form are set by the per-skill preamble above the `!cat`):

    ````markdown
    # Reviewer Dispatch (shared)

    With `$REVIEW_STEP`, `$REVIEW_ROUND`, `$REVIEW_OUTPUT_DIR`, `$REVIEW_ARTIFACT`, and `$REVIEW_AGENTS` set by the per-skill preamble above, run:

    ```sh
    scripts/dispatch-agent.sh --step "$REVIEW_STEP" --round "$REVIEW_ROUND" \
      --output-dir "$REVIEW_OUTPUT_DIR" --artifact "$REVIEW_ARTIFACT" \
      --agents "$REVIEW_AGENTS"
    ```

    `dispatch-agent` emits M lines on stdout (one per first-party reviewer; zero lines for a third-party-only batch). Each line has the form:

    ```
    MODE=first_party TAG=<tag> SUBAGENT_TYPE=<agent-name> MODEL=<resolved-model> PROMPT_FILE=<absolute-path>
    ```

    **For every emitted spec line, invoke the Task tool with these arguments (parse the line as space-separated `KEY=VALUE` pairs; values contain no spaces):**

    - `subagent_type` = the `SUBAGENT_TYPE` value, verbatim
    - `model` = the `MODEL` value, verbatim
    - `prompt` = the literal string `"DISPATCH_FILE=<PROMPT_FILE-value>"` — a single-line env-var-style reference; the prompt argument has no other content

    **Invoke all M Task tool calls in parallel in one orchestrator response** (one Task call per spec line). The reviewer agent body's first instruction is to `Read` its `DISPATCH_FILE` — do not pre-Read the file yourself; the dispatch context belongs in the subagent's window, not the orchestrator's.

    **Iron law (orchestrator-side dispatch contract):** invoke the Task tool exactly once per emitted spec line, with `SUBAGENT_TYPE`, `MODEL`, and `PROMPT_FILE` copied verbatim. Skipping a line, deduplicating across lines, modifying any value, or substituting a different subagent_type is a contract violation. The dispatch manifest (`$REVIEW_OUTPUT_DIR/.dispatch-manifest.json`) records expected dispatches; the apply-fix step's "expected tag produced no output" diagnostic catches missed or mis-routed Task invocations.

    After all Task tool calls return (Task tool is synchronous; first-party subagents have written their per-finding files to disk by the time Task returns), drain any third-party background dispatches and finalize the round:

    ```sh
    scripts/await-round.sh --round-dir "$REVIEW_OUTPUT_DIR"
    ```

    `await-round` is no-op-safe — first-party-only rounds still call it; it returns immediately after reading the manifest. It writes a small `$REVIEW_OUTPUT_DIR/.round-complete.json` summary and (for third-party dispatches) materializes per-finding files via `third-party-finding-splitter.sh`. It does NOT echo captured subagent payloads (CD-1 #4 output-bound contract).

    Then read `$REVIEW_OUTPUT_DIR/.round-complete.json` and the per-finding files as needed for apply-fix. The raw per-reviewer prompt content (assembled by dispatch-agent into `PROMPT_FILE`) never enters the orchestrator's context — only the small spec lines + the small `DISPATCH_FILE` references passed to Task.
    ````

**Schema migrations (one coordinated wave per G2 task shape):**
- All 41 agent files gain `tier:` frontmatter
- All 41+ inline `model: "..."` literals removed from 12 skill files
- Plan task schema gains optional `tier:` field (override hook for implementer dispatch)
- Skill prose "Pre-dispatch diff-file emission" paragraphs removed (replaced by dispatch-agent auto-invocation)
- Reviewer dispatch prose collapses from ~40 lines per skill to ~6 lines per skill (the per-skill preamble + the `!cat` include; full instructions live in `_shared/reviewer-dispatch-prose.md`)
- Reviewer agent bodies (`agents/qrspi-*-reviewer.md`) gain a first-action instruction: "**Read your `DISPATCH_FILE` (passed in your prompt argument as `DISPATCH_FILE=<path>`) as your full dispatch before doing anything else.**" Today's agent bodies assume dispatch params arrive inline in the prompt argument; under CD-1 they arrive via the DISPATCH_FILE Read.

**Rename inventory (hard cutover, no shim):**
- `run-codex-review.sh` → `dispatch-agent.sh` (also gains universal-entry-point responsibility)
- `run-third-party-llm.sh` → `dispatch-companion.sh`
- `codex-finding-splitter.sh` → `third-party-finding-splitter.sh`
- `_shared/codex/launch-await-pattern.md` → `_shared/third-party/launch-await-pattern.md`
- `reviewer-protocol/codex-emission-override.md` → `third-party-emission-override.md`
- NOT renamed: `codex-companion-bg.sh` (legitimately Codex-specific transport)

**Acceptance criteria:**
- `skills/_shared/reviewer-dispatch-prose.md` exists and contains the locked snippet body verbatim (per component #11).
- Every skill in the 12-skill consumer list (goals, questions, research, design, structure, phasing, plan, parallelize, replan, implement, integrate, test) `!cat`-includes `_shared/reviewer-dispatch-prose.md` in its review-round section. Lint: `grep -L 'reviewer-dispatch-prose.md' skills/{goals,questions,research,design,structure,phasing,plan,parallelize,replan,implement,integrate,test}/SKILL.md` returns empty.
- Every consumer skill's review-round section has been collapsed: no per-reviewer Claude-vs-Codex dispatch blocks, no inline `<<<FINDING-BOUNDARY>>>` recipe, no per-skill duplication of the parse-spec-line + invoke-Task instructions. The per-skill preamble sets `$REVIEW_STEP`, `$REVIEW_ROUND`, `$REVIEW_OUTPUT_DIR`, `$REVIEW_ARTIFACT`, `$REVIEW_AGENTS` and nothing else.
- Every reviewer agent body (`agents/qrspi-*-reviewer.md`) carries the "**Read your `DISPATCH_FILE` as your full dispatch before doing anything else**" first-action instruction.
- A single batched `dispatch-agent.sh` call replaces the per-reviewer prose blocks in every consumer skill — bash surface per round = 1 dispatch call + 1 await-round call, regardless of reviewer count.
- Adding DeepSeek requires only: new `deepseek-companion-bg.sh` + 1 matrix row + 1 config entry (no skill prose changes, no `_shared/reviewer-dispatch-prose.md` changes).
- Changing a user's preferred model for `medium` tier requires only: 1 `config.md` edit.
- Skill prose lint: no inline `model: "..."` literals remain in any skill file.
- Agent frontmatter lint: every agent has `tier:` field.

---

### CD-2 — Evergreen-Output Rule (cross-cutting artifact-output quality)

**Scope:** Affects every artifact-producing skill (goals, questions, research, design, structure, phasing, plan, parallelize, replan) and any future skill that adopts the `status: draft → approved` lifecycle. DRY via a single shared snippet `!cat`-included into each consumer.

**Outcome.** Artifacts produced by QRSPI skills describe the **current state** of decisions, not how those decisions were reached. The reader is a downstream agent or future maintainer who needs the WHAT, not the dialogue exhaust that produced it. The pattern is enforced by a litmus test that the artifact author applies before each paragraph is written, paired with named antagonist patterns and their substitutes.

**Solution components:**

1. **Single source of truth.** Create `skills/_shared/evergreen-output-rule.md` carrying the locked rule prose (verbatim below). One file; all consumers pull via `!cat`.

2. **`!cat` include in each artifact-producing skill SKILL.md** (precedent: `skills/goals/SKILL.md` already uses this pattern for `precondition-block.md`):

   ```
   !`cat ${CLAUDE_SKILL_DIR}/../_shared/evergreen-output-rule.md`
   ```

   Consumers to update:
   - `skills/goals/SKILL.md`
   - `skills/questions/SKILL.md`
   - `skills/research/SKILL.md`
   - `skills/design/SKILL.md`
   - `skills/structure/SKILL.md`
   - `skills/phasing/SKILL.md`
   - `skills/plan/SKILL.md`
   - `skills/parallelize/SKILL.md`
   - `skills/replan/SKILL.md`

3. **Locked rule prose** (verbatim — author this exact text into `skills/_shared/evergreen-output-rule.md`):

<!-- prose-design: skills/_shared/evergreen-output-rule.md (entire file) -->

````markdown
## Evergreen-Output Rule

Any artifact in the QRSPI run directory governed by `status: draft → approved` frontmatter promotion (goals, design, structure, phasing, plan, parallelization, roadmap, future-goals, and any future artifact adopting this lifecycle) describes the **current state** of decisions. The reader is a downstream agent or future maintainer.

*(Excludes by design: `SKILL.md` files — skills carry rule rationale legitimately; `feedback/*.md` — the designated home for dialogue exhaust; `reviews/**/*.md` — finding rationale; `config.md` — non-narrative.)*

**Litmus test (apply to every paragraph before write).** Two filters, in order:

1. Is the subject the **decision** (the thing being designed / planned / scoped)? → keep.
2. Is the subject the **document itself** — its drafts, its history, the dialogue that produced it, "us"? → cut.

A sentence that only makes sense as a delta from a prior state is **dialogue exhaust** — strip it.

**Permitted substantive content** (do NOT confuse with dialogue exhaust):

- Chosen approach and its rationale (inline)
- Rejected alternatives and tradeoffs, where the artifact template asks for them (e.g., design.md's `## Trade-offs Considered` — substantive content about the decision space, not about the document's history)
- Rationale embedded inline as one parenthetical when a downstream reader needs it

**Named antagonist patterns — strip on sight, substitute as shown:**

| Antagonist pattern | Recognize by | Replace with |
|---|---|---|
| Session / drafting notes | "Rule X drafting note," "this collapsed from 3 to 1 because…" | Nothing — delete. If a fact matters, embed inline in the decision. |
| Version-history narration | "earlier draft said X," "previously," "originally," "pre-cleanup" | Nothing — git history holds versions. |
| Inside baseball | text addressed to "us" / "the author," meta-explanation of the document's own structure ("this section is split into A and B because…") | The decision the structure expresses — without the structural explanation. |
| Compaction-loss recovery notes | "this nuance was almost lost during…" | Nothing — if the nuance is needed, the rule itself carries it. |
| Failure-modes-prevented lists | bullets that justify why a rule exists rather than state what to do | Strengthen the rule's wording; delete the justification list. |

Decision-process history (drafts, review rounds, feedback applied, compaction recovery) lives in feedback files, review findings, PR descriptions, and git history — never in the artifact.
````

**Acceptance criteria:**

- `skills/_shared/evergreen-output-rule.md` exists and contains the locked prose verbatim (anchor phrases: "Litmus test (apply to every paragraph before write)", "dialogue exhaust", "Named antagonist patterns — strip on sight, substitute as shown", the two ordered filters, the exclusions parenthetical).
- Every consumer SKILL.md listed above carries a `!cat ${CLAUDE_SKILL_DIR}/../_shared/evergreen-output-rule.md` line, placed where the SKILL.md introduces its artifact-output contract (typically near the artifact template or just before it).
- Skill prose lint: no SKILL.md in the consumer list embeds a copy of the rule text — `!cat` is the only inclusion path.
- Reviewer protocol updated to surface a finding when an `status: draft → approved` artifact contains any of the named antagonist patterns. (Either fold the check into existing quality reviewers, or define a sibling check — sizing TBD in Plan.)
- Documentation: the cross-skill rule appears in `using-qrspi/SKILL.md`'s artifact-quality section by reference (one-line pointer to `_shared/evergreen-output-rule.md`), not by copy.

---

### CD-3 — Multi-Actor Flow Check (cross-cutting downstream gate)

**Scope:** Adds a hard-stop precondition to `structure/SKILL.md`, `plan/SKILL.md`, `parallelize/SKILL.md`, and `implement/SKILL.md`. Each consumer `!cat`-includes a single shared snippet that enforces the check at the point where it authors deliverables operationalizing a design decision. Layered defense — each skill catches gaps the upstream layer missed; the user receives the gap as a diagnostic instead of a silently-guessed half-feature.

**Problem the rule prevents.** Design occasionally lands a decision that names actors but under-specifies their hand-offs (the failure pattern catalogued in G1 Sub-Rule C). Downstream skills do NOT pause to ask — they silently guess the missing hand-off (or skip it entirely), and the gap only surfaces at Test or in production. CD-3 makes the guess visible: any downstream skill that recognizes a multi-actor decision missing one of the six choreography elements stops and surfaces the gap to the user.

**Self-contained.** The snippet contains its own definition of "actor," its own enumeration of the six required choreography elements, its own action protocol, and its own iron law. It MUST NOT reference Sub-Rule C, G1, or any concept that isn't loaded into the consumer skill's context — the snippet is the entire contract from the consumer's perspective.

**1. Locked snippet content** (verbatim — author this exact text into `skills/_shared/multi-actor-flow-check.md`):

<!-- prose-design: skills/_shared/multi-actor-flow-check.md (entire file) -->

````markdown
## Multi-Actor Flow Check

Before authoring any deliverable that operationalizes a design decision involving two or more actors — where "actor" means anything that performs an operation and hands off to another: scripts, subagents, orchestrators, tools, services, protocol participants, object-call participants, workflow steps, queue producers/consumers, function callers/callees — verify that the design specifies all six choreography elements:

1. **Actor inventory** — every participant named, with its role.
2. **Sequence of operations** — ordered list of who-does-what; parallelism boundaries explicit.
3. **Per-step inputs and outputs** — what each actor receives and produces at each step; where outputs are written (stdout, file path, return value, manifest entry, message).
4. **Consumer identification** — for every output, who reads it next. Outputs with no named consumer must be removed or the consumer surfaced.
5. **Loud-failure paths** — what happens when each step fails; where the failure surfaces; which actor catches it. Silent fallback is never the answer.
6. **Context-cost call-out** — for any flow that crosses a context boundary (orchestrator/subagent, process, network), explicitly state what crosses vs. what stays on disk or in the other context.

If any element is missing for an in-scope decision, **STOP** authoring against this decision and surface a concrete diagnostic to the user. Do NOT guess the missing hand-off and continue.

Diagnostic template:

> Design decision **X** enumerates actors **A, B, C** but does not specify **[missing element — e.g., "what happens if B produces no output", "how A invokes B", "who reads C's output"]**.
>
> Stopping before guessing.
>
> Recommended path: trigger the **Backward Loops** procedure (see `using-qrspi/SKILL.md` § Backward Loops) to re-open Design via its per-decision dialogue, lock the missing element, re-review + re-approve `design.md`, then cascade forward — every dependent artifact from Design onward (Phasing if phase boundaries are affected, Structure, Plan, Parallelize if task dependencies are affected) re-runs against the updated design.
>
> Alternative: provide explicit guidance to accept the gap with a documented assumption recorded against this decision in the deliverable. The assumption becomes the de-facto contract — name what you are choosing for the missing element.

**Iron law:** silently inventing a missing hand-off is a contract violation that ships half-finished features which only surface at Test or in production. Guessing-instead-of-stopping is a process failure and must be reported even if the deliverable otherwise looks complete.
````

**2. Snippet placement in each consumer SKILL.md.** Insert the `!cat` line at the start of the per-decision authoring section (the point where the skill begins translating a design decision into a deliverable — for Structure, the file-map authoring; for Plan, the task-spec authoring; for Parallelize, the parallelization-plan authoring; for Implement, the per-task implementer dispatch). Exact line:

```
!cat ${CLAUDE_SKILL_DIR}/../_shared/multi-actor-flow-check.md
```

**3. Layered-defense semantics.** Each consumer runs the check independently against the design decision currently in scope; an upstream skill's pass is not a downstream skip. The four checks are redundant by design — they catch different failure cadences (Structure runs once per file-map authoring, Plan once per task, Parallelize once per wave, Implement once per task dispatch). Redundancy is the layered defense; do NOT optimize it away.

**4. DRY note (optional follow-up).** G1 Sub-Rule C currently enumerates the same six choreography elements inline in Design's SKILL.md. Future refactor candidate: have Sub-Rule C `!cat`-include the same `_shared/multi-actor-flow-check.md` snippet so the six elements have a single source of truth across both directions (Design authoring the flow, downstream skills checking it). NOT required for v0.7.2 — the duplication is acceptable for this release; flagged here so a future audit can collapse it without re-discovering the relationship.

**Acceptance criteria:**

- `skills/_shared/multi-actor-flow-check.md` exists and contains the locked snippet verbatim (anchor phrases: "Multi-Actor Flow Check", "where \"actor\" means anything that performs an operation and hands off to another", the six numbered elements with their bolded labels, "STOP", "Iron law: silently inventing a missing hand-off is a contract violation").
- All four consumer SKILL.md files carry exactly one `!cat ${CLAUDE_SKILL_DIR}/../_shared/multi-actor-flow-check.md` line each: `skills/structure/SKILL.md`, `skills/plan/SKILL.md`, `skills/parallelize/SKILL.md`, `skills/implement/SKILL.md`. Grep-lint: `grep -rln "multi-actor-flow-check.md" skills/` returns exactly 4 SKILL.md files plus the source file (5 total).
- Snippet self-containment lint: `grep -E "Sub-Rule C|G1|G\\d+" skills/_shared/multi-actor-flow-check.md` returns zero matches. The snippet stands alone in any consumer's context.
- Snippet body lint: no consumer SKILL.md embeds a copy of the six-element list or the diagnostic template; `!cat` is the only inclusion path. Grep-lint: searching consumer files for any of the anchor phrases above (excluding the `!cat` line) returns zero matches.
- Behavioral acceptance: in a contrived design.md that names two actors but omits a per-step output's consumer, each of Structure/Plan/Parallelize/Implement, when given that design as input, halts and emits the diagnostic template with the missing element correctly identified rather than silently authoring around the gap.

---

### CD-4 — Verifier-Fan-In Pipeline (end-to-end flow specification)

**Scope:** Replaces the orchestrator's LLM-side verifier-filter-rule application with a deterministic script. Resolves five compounding goals as one coherent flow:

- **G7** — Verifier filter rule: missing at point of use + DRY drift across 5 sites
- **G8** — Reviewer subagents emit `category:` instead of schema-required `change_type:`
- **G11** — Verifier sidecar pipeline: extension drift + orchestrator bypass
- **G12** — Automated verifier-fan-in script (replace orchestrator chat-parsing)
- **G13** — `change_type` enum drift: reviewer-side emit + orchestrator-side silent fall-through

These goals are five symptoms of one broken end-to-end flow: reviewer → finding-file → verifier → sidecar → fan-in → kept-findings → apply-fix. Solving them as separate decisions invites exactly the failure pattern Sub-Rule C + CD-3 catch (components specified in isolation without the flow between them). CD-4 specifies the flow once; each goal's specific lint becomes an acceptance criterion against that flow.

**Mermaid sequence diagram** (mandatory per Sub-Rule C: flow crosses orchestrator/subagent boundary, has parallel fan-out + wait-all, has cross-actor failure detection):

```mermaid
sequenceDiagram
    autonumber
    participant O as Orchestrator
    participant R as Reviewer subagents (M parallel)
    participant V as Verifier subagent (per finding)
    participant S as scripts/verifier-fan-in.sh
    participant FS as Disk (round dir)

    O->>R: dispatch M reviewers (per CD-1)
    R->>FS: write <tag>.finding-F<NN>.md (change_type in enum)
    R-->>O: return (round complete)
    loop per finding
        O->>V: dispatch verifier (finding path)
        V->>FS: write <tag>.finding-F<NN>.score.md sidecar
        V-->>O: return (job complete)
    end
    O->>S: invoke verifier-fan-in.sh <round-dir>
    S->>FS: read each finding + paired sidecar
    alt all findings well-formed
        S->>FS: write kept-findings.txt + .verifier-fan-in-audit.json
        S-->>O: exit 0
        O->>FS: read kept-findings.txt (paths only)
        O->>O: iterate kept set for apply-fix
    else any finding malformed (missing change_type, out-of-enum, missing sidecar, wrong extension)
        S->>FS: write .verifier-fan-in-audit.json with halts[]
        S-->>O: exit non-zero with named cause
        O-->>O: surface halt to user; round fails to converge
    end
```

**Six choreography elements (Sub-Rule C compliance):**

1. **Actors** — reviewer subagents (M parallel per round), verifier subagent (per finding), `scripts/verifier-fan-in.sh`, orchestrator.
2. **Sequence** — reviewer fan-out → wait → verifier per-finding dispatch (parallel within a round) → wait → orchestrator invokes script ONCE per round → script reads finding+sidecar pairs → script writes kept-findings + audit → orchestrator reads kept-findings → apply-fix.
3. **Per-step I/O** — every output written to disk under `<round-dir>/`; specific path conventions locked below.
4. **Consumers** — every output named: finding files consumed by verifier + script; sidecars consumed by script; kept-findings.txt consumed by orchestrator; audit JSON consumed by orchestrator's round-summary prose for user visibility.
5. **Loud-failure paths** — script halts and exits non-zero on: missing `change_type:` field, out-of-enum `change_type:` value, missing sidecar for any finding, sidecar on wrong extension, unparseable score. Each halt names the specific finding ID + the specific cause in the audit JSON. Round fails to converge — no silent default-keep, no silent default-drop.
6. **Context-cost** — threshold values live as script constants and NEVER enter orchestrator context. Per-finding verifier reasoning prose stays in sidecars on disk. Orchestrator carries only `kept-findings.txt` (one path per line, tiny) + audit summary counts. Verifier's chat-side output (if any) is now telemetry, not load-bearing.

**Locked component shapes:**

**A. Finding file (reviewer-side output).** Written by reviewer subagents at `<round-dir>/<reviewer-tag>.finding-F<NN>.md`. Frontmatter MUST include:
- `change_type:` field (G8 — exact field name, not `category:`)
- value drawn from canonical enum defined in `scripts/verifier-fan-in.sh` header (G13 — enum membership enforced by script)

**B. Verifier sidecar (verifier-side output).** Written by `qrspi-finding-verifier` subagent at `<round-dir>/<reviewer-tag>.finding-F<NN>.score.md` (G11 — `.score.md` extension locked; one extension, no `.yml` alternative). Frontmatter MUST include:
- `score:` integer 0–100
- Reasoning prose in body (consumed by humans + future debug tooling, not by the fan-in script)

The verifier agent body is updated to constrain its Write tool call to the locked path/extension. Today's chat-emit-of-score-prose remains as telemetry but is no longer load-bearing.

**C. `scripts/verifier-fan-in.sh` (canonical filter).** Single invocation per round: `scripts/verifier-fan-in.sh <round-dir>`. Script:
1. Globs `<round-dir>/*.finding-F*.md` to enumerate findings.
2. For each finding: Reads frontmatter → asserts `change_type:` present (halt if missing) → asserts value in canonical enum (halt if out-of-enum) → globs paired sidecar at `<round-dir>/<reviewer-tag>.finding-F<NN>.score.md` (halt if missing or wrong extension) → reads `score:` from sidecar (halt if unparseable).
3. Applies threshold rule from script header constants (single source of truth) keyed on `change_type`. Threshold values are script constants; the exact per-enum-value floors are part of Plan-time author work (current state: style/clarity ≥80, correctness ≥70 — Plan task authors lock the full per-enum table including any values added by G13's enum lock).
4. On all-clean: writes `<round-dir>/kept-findings.txt` (one absolute finding-file path per kept finding, one per line, no other content) + `<round-dir>/.verifier-fan-in-audit.json` (counts + threshold echo + halts: []), exits 0.
5. On any halt: writes the audit JSON with populated `halts: [{finding_id, cause}, ...]`, exits non-zero with a one-line stderr message naming the first halt cause.

**D. `kept-findings.txt`.** Plain text, one absolute finding-file path per line, no header, no comments. Orchestrator reads line-by-line; each line is a Read target for apply-fix.

**E. `.verifier-fan-in-audit.json`.** JSON object:
```json
{
  "scored": 12,
  "kept": 4,
  "dropped": 8,
  "halts": [],
  "thresholds": { "style": 80, "clarity": 80, "correctness": 70 }
}
```
Orchestrator includes the count summary in the round-complete prose surfaced to the user (audit visibility — no silent filter activity).

**F. Orchestrator-side prose update.** Every SKILL.md that today references the filter rule (verified locations from G7: `using-qrspi/SKILL.md` lines 388, 661, 921, 984, 985; `implement/SKILL.md` references to "kept findings" / "findings that survived verifier filtering") changes to point to the script. Specifically:
- `using-qrspi/SKILL.md` — collapse the 5 restatements to ONE short paragraph (~2 sentences) that explains what the script does and points to its header constants for current threshold values. Remove the other 4 sites entirely.
- `implement/SKILL.md` — replace "kept findings" / "findings that survived verifier filtering" with "findings listed in `<round-dir>/kept-findings.txt`"; add a precondition that `scripts/verifier-fan-in.sh` must have exited 0 for the round before apply-fix runs.
- Reviewer-protocol `SKILL.md` — `change_type:` enum is centralized here (G8 candidate 3 + G13 — single schema source); per-reviewer agent files reference rather than duplicate.

**G. Reviewer agent updates.** Each per-reviewer agent body (`agents/qrspi-silent-failure-hunter.md`, `agents/qrspi-security-reviewer.md`, `agents/qrspi-code-quality-reviewer.md`, all other reviewer agents) carries the field name `change_type:` and the enum value enumeration explicitly (G8). The reviewer-protocol skill defines the canonical enum; per-reviewer agents inherit by reference.

**Per-goal acceptance mapping (each goal's specific lint preserved):**

- **G7 acceptance** — `grep -nE "≥\s*(70|80)" skills/` returns zero matches (threshold values live ONLY in `scripts/verifier-fan-in.sh`); `grep -rln "kept findings\|survived verifier filtering" skills/` returns matches only in the consolidated `using-qrspi/SKILL.md` paragraph and the `implement/SKILL.md` precondition; changing a threshold requires editing exactly one constant in the script.
- **G8 acceptance** — `grep -rln "^category:" reviews/` after any round returns zero matches; `grep -rln "^change_type:" reviews/` returns one match per finding file; script halts with `cause: missing_change_type` for any finding without the field.
- **G11 acceptance** — every verifier sidecar carries the `.score.md` extension; `find <round-dir> -name "*.score.yml"` returns zero results; script halts with `cause: sidecar_wrong_extension` if a `.yml` sidecar appears.
- **G12 acceptance** — `scripts/verifier-fan-in.sh` exists, exits 0 on a well-formed round, writes both `kept-findings.txt` and `.verifier-fan-in-audit.json`; orchestrator never chat-parses verifier output to compute the kept set.
- **G13 acceptance** — script halts with `cause: change_type_out_of_enum` for any finding whose value is not in the canonical enum; the canonical enum is defined ONCE in the script header and once in `reviewer-protocol/SKILL.md` (referenced from per-reviewer agents); `grep -rln "change_type.*|.*|.*|" skills/` returns matches only in `reviewer-protocol/SKILL.md` (single SKILL-side source).

**Behavioral acceptance** — provoke each halt cause in a fixture round-dir; confirm script exits non-zero with the named cause in `halts[]`; confirm orchestrator surfaces the halt to the user rather than silently proceeding.

**H. Halt-response protocol (orchestrator-side).** When the script exits non-zero, the orchestrator does NOT just escalate. It applies a layered response keyed on halt cause + retry budget + interaction mode + `orchestrator_rescue` config.

**H.1. Per-cause retry target.** Each halt cause has a specific actor whose output went wrong:

| Halt cause | Retry target | Notes |
|---|---|---|
| `missing_change_type` | offending **reviewer** | reviewer-side defect |
| `change_type_out_of_enum` | offending **reviewer** | reviewer-side defect |
| `missing_sidecar` | **verifier** (per finding) | verifier didn't write |
| `sidecar_wrong_extension` | **verifier** (per finding) | verifier wrote wrong path |
| `score_unparseable` | **verifier** (per finding) | verifier wrote malformed body |

**H.2. Retry budget.** Orchestrator re-dispatches the offending actor exactly **once** per finding, with identical inputs. After the retry, re-runs the script. If the script halts again on the SAME finding for any cause, the budget is exhausted for that finding.

**H.3. Per-finding budget exhaustion — `orchestrator_rescue` gates the rescue layer; interaction mode determines escalation shape.**

`orchestrator_rescue` is a single toggle for whether the orchestrator performs ANY silent fix (mechanical OR interpretive). When opted out, every halt escalates regardless of tier — even tier-1 mechanical drift surfaces to the user (interactive) or drops (auto). This respects the toggle's stated semantics: rescue OFF means no orchestrator-driven fixes period.

**Behavior matrix:**

- **`orchestrator_rescue: true`, any mode.** Rescue layer attempts all three tiers silently (see "Rescue layer" below). Escalation fires only on rescue failure (E1–E4) or drift-limit reached (E5).
- **`orchestrator_rescue: false`, interactive mode.** Every halt cause escalates immediately to the user with a cause-specific menu — even tier-1-shaped causes (e.g., `category:` instead of `change_type:`) surface as "orchestrator detected mechanical drift; choose: fix-and-continue / retry actor / drop / stop round." User remains the sole fixer.
- **`orchestrator_rescue: false`, auto-mode.** Every halt cause produces drop + `drift_count++`. Halt the run at `drift_count > max_drift_per_round`.

**Rescue layer (fires only when `orchestrator_rescue: true`):**

- **Tier 1 — mechanical fixes (silent, do NOT increment `drift_count`):**
  - `missing_change_type` where the file has `category:` / `type:` / `kind:` instead → rename frontmatter key to `change_type:`, preserve value, re-run script
  - `sidecar_wrong_extension` (e.g., `.score.yml` instead of `.score.md`) → rename file, re-run script
- **Tier 2 — interpretive fixes (silent, DO increment `drift_count`):**
  - `change_type_out_of_enum` → orchestrator reads finding body, maps the out-of-enum value to the nearest enum member based on explicit content cues, MUST cite a verbatim phrase from the finding body that supports the mapping. If no clean cue exists, fall through to escalation (E3) — do not guess.
- **Tier 3 — subagent-resident rescue (silent, DO increment `drift_count`):**
  - `missing_sidecar` / `score_unparseable` → orchestrator dispatches a fresh verifier subagent (extends H.2 budget by exactly +1 verifier dispatch). Orchestrator does NOT score inline — scoring stays subagent-resident per the run-wide Constraint on subagent-resident verification.

All rescue events (every tier) are logged to `orchestrator_fixes[]` with `{finding_id, cause, tier, original_value, fixed_value, fix_method, citation?}`. Round-summary prose at round end surfaces per-tier counts so persistent reviewer/verifier regression stays visible.

**Escalation triggers:**

- E1. Cause has no applicable rescue tier (e.g., a halt cause not enumerated in H.1)
- E2. `orchestrator_rescue: false` (every halt escalates regardless of tier shape)
- E3. Tier 2 fall-through (no clean content cue available for the mapping)
- E4. Tier 3 fall-through (re-dispatched verifier also failed)
- E5. `drift_count > max_drift_per_round` reached for the round

**Escalation behavior — interactive mode.** Orchestrator surfaces the specific finding + halt cause + retry trace + rescue trace (if any) to the user. Per-finding menu:

1. **Fix and continue** — apply the orchestrator's mechanical or interpretive fix (shown ONLY when a clean fix is identifiable for this cause; under rescue=off this is the user-visible equivalent of what tier 1/2 would have done silently). Drift event.
2. **Retry actor** — re-dispatch the offending reviewer or verifier once more with same inputs. Drift event only if retry succeeds (clean retry resolves with no fix; if it also halts, the new escalation increments drift).
3. **Provide value** — user types the correct `change_type` / score / etc.; orchestrator writes it to the finding frontmatter or sidecar. Drift event.
4. **Drop finding** — treat as dropped, continue round. Drift event.
5. **Enable rescue** — flip `orchestrator_rescue` on; orchestrator surfaces a sub-prompt: (a) for the rest of this round only (in-memory flip; config.md untouched), or (b) for the rest of this run (writes `orchestrator_rescue: true` to config.md). After the flip, the current halt cause is processed through the rescue layer per H.3; subsequent halts in scope also auto-resolve when applicable. Shown ONLY when `orchestrator_rescue: false`.
6. **Stop round** — halt the entire round; user investigates manually (edit reviewer agent body, etc.). Round terminates; drift_count moot.

For E5 (drift-limit escalation), the menu is round-level instead of per-finding: (a) raise `max_drift_per_round` for this round and continue, (b) accept current kept set and finish round early, (c) stop round.

**Escalation behavior — auto-mode.**

- For E1–E4 (per-finding rescue failure or rescue=off): drop the finding, `drift_count++`, continue the round.
- For E5 (drift-limit exceeded): halt the auto-mode run with explicit cause `drift threshold exceeded — manual review required`.

**Drift count semantics (friction signal, not risk signal).** `drift_count` counts events where the clean pipe broke AND someone — orchestrator OR user — had to intervene to keep the round going:

- Tier 1 silent rescue (rescue=true): does NOT count. Orchestrator absorbed the friction; the round never visibly deviated.
- Tier 2 / Tier 3 silent rescue (rescue=true): counts. Real interpretive work or extra subagent dispatch.
- Any user-resolved escalation outcome that keeps the round going (Fix / Provide value / Drop / Retry-success-after-failure) under rescue=false: counts. The user intervened; that's friction even when the cause was mechanical.
- "Stop round" is not a drift increment; it ends the round.

The asymmetry — tier 1 free under rescue=on, tier 1 counts under rescue=off — is intentional: drift_count tracks *how many times the human or orchestrator was pulled in to keep the round alive*, not abstract reviewer drift. Audit visibility of underlying reviewer drift is preserved via `orchestrator_fixes[]` and the round-summary per-tier breakdown.

**Halt rule (uniform).** Auto-mode halts at `drift_count > max_drift_per_round`. Interactive mode never auto-halts; the user decides via the E5 round-level menu.

**H.4. Config fields** (additions to `config.md` shape):

```yaml
orchestrator_rescue: false        # default; opt-in for silent orchestrator-driven fixes (all tiers). When false, every halt escalates regardless of tier shape.
max_drift_per_round: 3            # default; counts friction events (silent tier 2/3 rescues + escalated user-resolutions or auto-drops). Tier 1 silent rescues never count.
```

`max_drift_per_round` is consulted in both interactive and auto-mode — drift events accumulate uniformly. The difference is what happens at the threshold (interactive: E5 round-level menu; auto: halt).

**H.5. Iron-rule preservation check.** Orchestrator-side rescue does NOT compute the kept set, does NOT lookup thresholds inline, and does NOT chat-parse verifier output for kept-set semantics. Tier 1/2 fixes adjust the script's INPUT (finding frontmatter or filename); tier 3 extends the verifier-dispatch budget by +1. User-resolved escalations also adjust the script's INPUT only. After every rescue path and every escalation resolution, the script re-runs and applies thresholds. CD-4's iron rule holds under every interaction-mode × rescue-config combination.

**H.6. Acceptance criteria additions:**

- Fixture rounds covering each halt cause × each `orchestrator_rescue` value × each interaction mode produce the expected outcome (silent rescue + log, escalation menu + log, or auto-mode drop + halt-at-limit).
- Tier 1 mechanical rescue fires silently under rescue=true (no user prompt, not in drift_count) and is logged to `orchestrator_fixes[]`.
- Tier 1-shaped halt under rescue=false surfaces an escalation menu (interactive) or drops + drift_count++ (auto). Fixture asserts the menu fires for the trivial `category:` rename case.
- Tier 2 interpretive rescue under rescue=true fires silently in both modes and is logged with a verbatim body citation; tests fail if interpretive rescue is recorded without a citation.
- `drift_count` increments per the H.3 friction-signal rules; fixture tests assert both the inclusion direction (tier 2/3 silent + escalated user-resolutions + auto-drops) and the exclusion direction (tier 1 silent rescues + Stop-round).
- Auto-mode halt triggers exactly when `drift_count > max_drift_per_round`.
- Interactive mode at `drift_count > max_drift_per_round` surfaces the E5 round-level menu and never auto-halts.
- "Enable rescue" menu option under rescue=false interactive escalation: round-scoped variant flips the toggle in-memory only and config.md remains unchanged; run-scoped variant writes `orchestrator_rescue: true` to config.md and the post-flip halt resolves via the rescue layer. Fixture asserts both scope variants.

**H.7. Interaction-mode detection — script-encapsulated platform directory.**

`orchestrator_rescue` and the H.3 behavior matrix branch on whether the current session is auto-mode or interactive. Detection splits cleanly along two axes:

- **Which host CLI is active** — shell-detectible (env vars like `COPILOT_CLI=1`, `CODEX_*`, etc.).
- **Whether auto-mode is active on that host** — may be shell-detectible (an env var the CLI sets) OR may be context-only (an in-context system-reminder that only the LLM can observe) OR may not be documented at all (host provides no signal — fall back to user override).

Per-consumer conditional prose ("if Claude check X else if Copilot check Y …") fragments and rots. The script encapsulates the per-host knowledge and returns either a verdict directly (when shell-detectible) or an instruction the orchestrator LLM executes against its own context (when context-only) or a user-override-required signal (when no detection is possible). The orchestrator does NOT need to know which platform it's on or how detection works on that platform — it just consults the script and follows the returned protocol.

**Locked platform directory (verified at design time against host docs + direct runtime observation as of 2026-05-31):**

| Platform discriminator | Auto-mode signal | Script output shape |
|---|---|---|
| `COPILOT_CLI=1` (Copilot CLI; observed on v1.0.57-1, signal not documented in `copilot help environment` or official autopilot docs but injected at runtime) | `<autopilot_mode>` block in active context containing the literal sentence "Autopilot mode is currently active." Durable per-turn injection while autopilot is on. Verified by direct toggle-and-observe in session `fff21ea0` on 2026-05-31. | `DETECTION_TYPE=llm-context, INSTRUCTION="Inspect your active context for a block delimited by <autopilot_mode> ... </autopilot_mode> tags. If the block is present AND its body contains the literal sentence 'Autopilot mode is currently active.', the session is auto-mode; otherwise interactive."` |
| Claude Code (no `COPILOT_CLI` env, Claude Code's standard system-reminder framing present) | `## Auto Mode Active` system-reminder block in active context. Documented precedent in `qrspi/skills/goals/SKILL.md` and other plugin skills that already condition on the same signal. | `DETECTION_TYPE=llm-context, INSTRUCTION="Inspect your active context for a system-reminder block containing the literal string '## Auto Mode Active'. If present, the session is auto-mode; otherwise interactive."` |
| Unknown / unrecognized host | n/a | `DETECTION_TYPE=user-override-only` (script defers to `QRSPI_INTERACTION_MODE` override or safe-default `interactive`) |

Codex CLI support is out of scope for v0.7.2 — the project does not yet integrate Codex CLI as a host. When Codex CLI support is added (v0.7.3+), the script gains a new branch following the verification procedure below.

**Implementation-start verification procedure (Iron Law).** Before the implementer locks the Copilot-CLI / Claude-Code branches of `scripts/detect-interaction-mode.sh`, they MUST re-verify against the current host docs AND the actual installed CLI version via direct runtime observation:

- For each supported host, start an interactive session, observe the context, toggle autopilot/auto-mode (Shift+Tab cycle or `/autopilot` slash command), and observe what changed in context. Document the exact tag, marker, or sentence the host injects. **Direct runtime observation is mandatory** — host docs are unreliable (Copilot CLI v1.0.57-1 injects a documented-nowhere `<autopilot_mode>` block; future hosts likely do the same).
- Re-run `copilot help environment` and grep for any autopilot/auto/yolo env var that didn't exist at design time.
- For Claude Code, re-check `qrspi/skills/goals/SKILL.md` and any newer plugin skills for the canonical system-reminder string (verify it is still `## Auto Mode Active` and not a renamed equivalent).
- When a new host is added (Codex CLI in v0.7.3+, or any other future host): repeat the equivalent toggle-and-observe steps and add a new script branch following the same shape, with citation block in the script header.

If any new signal is discovered (or an existing one renamed), update the corresponding script branch. Document the verification timestamp, the host CLI version, and the source URL/command/observation method in the script header as a citation comment. This Iron Law exists because Design is the last research-bearing phase per G1 Sub-Rule D (external-knowledge completeness) — Structure and Plan do not re-research; they consume — AND because host runtime injections are documented-nowhere often enough that doc-only verification produces wrong answers (the Copilot CLI v1.0.57 case proves it).

**Contract:** `scripts/detect-interaction-mode.sh`

Outputs a small structured block on stdout (one key per line, `KEY=value` shape) describing how the orchestrator should determine auto vs. interactive for the active host. Exit code 0 on successful detection (including the safe-default branch); nonzero only on internal script error.

Three output shapes, distinguished by `DETECTION_TYPE`:

- **Shell-detectible verdict** — the script computed the answer directly from environment:

  ```
  PLATFORM=copilot_cli
  DETECTION_TYPE=shell-verdict
  VERDICT=auto
  EVIDENCE=COPILOT_AUTOPILOT=1   # example only; not currently set by any known host as of 2026-05-30
  ```

  Orchestrator action: use `VERDICT` as-is. Cite `EVIDENCE` in the audit log.

- **LLM-context instruction** — the host signal is context-only; the script returns prose telling the orchestrator how to inspect its own context:

  ```
  PLATFORM=claude_code
  DETECTION_TYPE=llm-context
  INSTRUCTION=Inspect your active context for a system-reminder block containing the literal string "## Auto Mode Active". If present, the session is auto-mode; otherwise interactive.
  ```

  Orchestrator action: read `INSTRUCTION`, execute the check against its own context, derive `auto` or `interactive`. The orchestrator MUST cite (in the audit log entry below) the specific context signal it observed (or its absence) so the decision is traceable post-hoc.

- **User-override-only** — the host has no documented detection signal; the script defers entirely to the override chain:

  ```
  PLATFORM=copilot_cli
  DETECTION_TYPE=user-override-only
  VERDICT=interactive          # via override chain: $QRSPI_INTERACTION_MODE absent → safe default
  EVIDENCE=no host signal; QRSPI_INTERACTION_MODE absent; safe default applied
  ```

  Orchestrator action: use `VERDICT`. If the user wants auto-mode behavior on a `user-override-only` host, they must set `QRSPI_INTERACTION_MODE=auto` in their session env before invoking the orchestrator. Cite `EVIDENCE` in the audit log.

**Override chain** (consulted by the script in this order for any `user-override-only` host, AND as a fallback for shell-verdict/llm-context hosts when the primary signal is absent):

1. `QRSPI_INTERACTION_MODE=auto|interactive` env var (highest precedence for testing and explicit user opt-in)
2. Safe-default `interactive` (never auto-halt on a misread)

**Audit-log entry.** Every round-start invocation of the detection script writes `<run-dir>/.verifier-fan-in-audit.json` → `interaction_mode_resolution: {platform, detection_type, verdict, evidence}` where `evidence` is the orchestrator-cited context signal (when `DETECTION_TYPE=llm-context`) or the script-cited env var name / "no host signal" prose (when `DETECTION_TYPE=shell-verdict` or `user-override-only`). This makes mis-detections diagnosable.

**Encapsulation rule.** No SKILL.md prose, no agent body, and no `_shared/` snippet references per-host signal names directly (env var names, system-reminder strings, etc.). They all consult `scripts/detect-interaction-mode.sh` and act on its output. The script's source is the only place where per-host detection knowledge lives. When a new host CLI is supported (or an existing host adds a shell-visible or in-context auto signal that previously was undocumented), the script gains one new branch — no consumer prose changes.

**Caching.** Orchestrator invokes the script once per round-start, caches `{platform, detection_type, verdict, evidence}` for the round, and reuses it for every subsequent consumer check in that round. Re-invocation only on round transitions or after a user-visible mode flip (Shift+Tab, `/auto`, `/autopilot`, etc.). The orchestrator's cached evidence is what gets cited in the audit log.

**Acceptance criteria:**

- Fixture: Claude Code session under simulated auto-mode → script returns `DETECTION_TYPE=llm-context` with the Claude-specific instruction → orchestrator inspects context → derives `auto` → audit shows `evidence: "## Auto Mode Active system-reminder present"`.
- Fixture: Claude Code session without auto-mode → same script output → orchestrator derives `interactive` → audit shows `evidence: "## Auto Mode Active system-reminder absent"`.
- Fixture: Copilot CLI session under simulated autopilot → script returns `DETECTION_TYPE=llm-context` with the Copilot-specific instruction → orchestrator inspects context → derives `auto` → audit shows `evidence: "<autopilot_mode> block present with 'Autopilot mode is currently active.' sentence"`.
- Fixture: Copilot CLI session without autopilot → same script output → orchestrator derives `interactive` → audit shows `evidence: "<autopilot_mode> block absent"`.
- Fixture: Copilot CLI session with `QRSPI_INTERACTION_MODE=auto` set AND no autopilot context block → override chain wins → script returns `VERDICT=auto` → orchestrator uses verdict directly → audit shows `evidence: "QRSPI_INTERACTION_MODE=auto override"`.
- Fixture: shell-detectible host (synthetic future host with `FOO_AUTO=1`) → script returns `DETECTION_TYPE=shell-verdict, VERDICT=auto` → orchestrator uses verdict directly → audit shows `evidence: "FOO_AUTO=1"`.
- Fixture: no host discriminator, no override → script returns `PLATFORM=unknown, DETECTION_TYPE=user-override-only, VERDICT=interactive` (safe default), exit 0.
- Grep lint: no occurrence of host-specific auto-mode signal names or strings (env var names, literal `## Auto Mode Active`, literal `<autopilot_mode>` tag, literal "Autopilot mode is currently active." sentence, etc.) outside `scripts/detect-interaction-mode.sh` and its dedicated test fixtures. Caught at every PR.
- Script header contains a verification-citation block listing: host CLI versions verified against, observation method (toggle-and-observe vs docs-only), `copilot help environment` snapshot date, Claude Code skill citation, observation timestamps. Updated on every Implementation-start verification per the Iron Law above.

**I. Reviewer-side hardening (defense-in-depth).** Independent of orchestrator-side response, the reviewer agents themselves are hardened to reduce the frequency of `missing_change_type` and `change_type_out_of_enum` events. Per-reviewer agent body updates (extending § G) add:

- Explicit `change_type:` field name with full enum value enumeration verbatim in agent body (e.g., "Required frontmatter field: `change_type:`. Allowed values: `style`, `clarity`, `correctness`, `security`. NO other values.")
- Self-check-before-emit instruction: "Before writing your finding file, verify your frontmatter contains exactly `change_type:` (NOT `category:`, NOT `type:`, NOT `kind:`) and the value is one of the enum members listed above."
- Worked-example finding-file showing correct frontmatter shape (full minimal example).
- Anti-example showing `category:` with explanation: "This is a contract violation. The fan-in script will discard this finding (and the orchestrator may auto-rescue or drop it depending on run config)."
- Iron-law clause: "Emitting the wrong field name or an out-of-enum value produces zero kept findings for your tag for this round when `orchestrator_rescue: false`, and an audit-trail anomaly when `orchestrator_rescue: true`. Either way, your finding is degraded — emit correctly the first time."

**Amendment seam — G19 (cross-reviewer corroboration threshold).** G19 is an exploratory goal whose candidate solutions include cross-reviewer corroboration as one threshold-adjustment mechanism. If G19's eventual lock includes corroboration-based threshold adjustment, the adjustment is implemented as an extension to `scripts/verifier-fan-in.sh` (additional script logic + per-enum threshold-table extension), NOT as orchestrator-side prose. This preserves CD-4's iron rule: threshold values live ONLY in the script.

**Iron rule (cross-goal).** The orchestrator NEVER computes the kept set from chat-parsed verifier output. The script is the only path. Any future "let me just parse this one finding's score from chat" temptation is a contract violation that re-introduces every goal CD-4 resolves. Orchestrator-side rescue (§H.3) adjusts the script's INPUTS only — the script computes the kept set on every invocation.

---

## G1 — Design phase under-describes decisions

<!-- prose-design: Design SKILL.md § "What Design produces" -->

**Outcome.** Design produces a per-goal solution definition at outcome altitude — the end-state
being targeted, the practical solution at the altitude defined by the Altitude Sub-Rules below,
and the reasoning behind it. Architecture documentation belongs in Structure. Test specification
belongs in Plan.

<!-- prose-design: Design SKILL.md § "Per-goal block template" -->

**Per-goal block template:**
- **Outcome** — the end-state being targeted
- **Solution** — the practical solution at the altitude defined by the Altitude Sub-Rules
- **Why this approach** — tradeoffs and alternatives considered
- **Dependencies + edge cases** — what the solution depends on and which corner cases it handles
- **Acceptance** — a high-level "done" signal at the outcome level

**Optional per-goal Mermaid diagram** when the solution involves flow that benefits from visualization.

**Cross-Goal Decisions section** above the per-goal blocks for decisions that span multiple goals.

<!-- prose-design: Design SKILL.md § "Dialogue Conduct" -->

**Dialogue Conduct.** When working a goal with the user, follow these rules:

1. **Open with questions.** Surface your list of open questions for the goal in chat. Work
   through them with the user one decision at a time.

2. **One question at a time, with a recommended answer.** Each question carries your proposed
   answer; the user confirms, amends, or rejects.

3. **Ground first, ask second.** Before asking the user any question — your own or one the
   user has asked back — consult, in order: the research summary, the codebase, then the web.
   When a question touches industry best practice, conventions, or external patterns, search
   the web liberally for cited evidence rather than speculating or punting the question back.
   Only escalate to the user when no source surfaces a defensible answer.

4. **When the user asks for your call, provide one.** When the user solicits your opinion,
   asks which option is best, or asks what you would recommend, give a grounded recommendation
   (sources per Rule 3) with named tradeoffs. Do not deflect with more questions or punt the
   choice back. If grounding genuinely leaves the call indeterminate, say so explicitly and
   name what additional evidence would resolve it.

5. **Sharpen fuzzy language.** When the user uses imprecise vocabulary, propose the canonical
   term and ask for confirmation before moving on.

6. **Walk every branch of the decision tree, including flow gaps.** For each goal, resolve
   dependencies between decisions one-by-one. Do not move to the next goal until every branch
   surfaced for the current one is either decided, explicitly deferred with a written reason,
   or split out as a separate goal. Branch completeness explicitly includes the end-to-end
   flow between any multi-actor decisions — actors named, operations sequenced, per-step
   inputs/outputs traced to producer and consumer, loud-failure paths named, context-cost
   call-out present (per Sub-Rule C). A flow with implicit hand-offs is an open branch; close
   it before moving on.

7. **Lock decisions as they settle.** Write each decision into the goal block under
   `status: draft` as it is confirmed. Do not accumulate decisions in chat across multiple
   goals before persisting.

<!-- prose-design: Design SKILL.md § "Altitude Sub-Rule A — Naming-vs-Layout" -->

**Altitude Sub-Rule A — Naming-vs-Layout** (applies to code, scripts, and data-contract artifacts).

Design names artifacts when naming IS the decision. Filenames, script names, contract artifact
names, and renames are in scope when they establish cross-skill vocabulary or commit to a
public-interface identity.

Design does NOT specify:
- Directory trees or where files live within the repo
- Inter-file wiring (what sources / imports / requires what)
- Function or method signatures
- Field-level schema layouts (JSON keys, table columns, struct fields)
- Code, pseudocode, or implementation outlines

**Altitude test.** After reading the design block for a goal, can Structure still author its
file map AND Plan still author its per-task API surface without contradiction? If yes → right
altitude. If no → back off.

**Worked examples:**

| Permitted (identity) | Not permitted (layout / wiring / signatures) |
|---|---|
| "Rename `foo.sh` → `bar.sh`" | "`bar.sh` lives at `scripts/bar.sh` and sources `lib/baz.sh`" |
| "`prep.sh` is auto-invoked by `bar.sh` when its outputs are absent" | "`bar.sh` calls `prep_if_needed(step, round)` returning `{ref, narrowed}`" |
| "The per-round manifest is `manifest.json`, one entry per dispatched job" | "Manifest schema: `{jobs: [{id: str, tier: str, started_at: int}]}`" |
| "Resolver and host-detect are shared infrastructure" | "`detect_host()` returns one of `claude-code\|codex-cli\|copilot-cli`" |

<!-- prose-design: Design SKILL.md § "Altitude Sub-Rule B — Prose-as-Decision" -->

**Altitude Sub-Rule B — Prose-as-Decision** (applies to prompt prose, reviewer rubrics, skill
text, agent frontmatter, dispatch payloads).

When the artifact being designed IS prompt prose, the prose-level wording IS the design.
Specifying exact words is not over-reach; it is the unit of architectural commitment. LLM
behavior is acutely sensitive to wording, and generic paraphrase is not equivalent to a
specified rule.

**Altitude test.** Ask: "if a future agent re-implemented this from my description using
different wording, would they produce equivalent LLM behavior?"
- If the artifact is code: generally YES — Sub-Rule A governs; specify what, not how.
- If the artifact is prompt prose: generally NO — Sub-Rule B governs; specify the wording
  verbatim to the extent scope allows (see Scope proportionality below).

**Scope proportionality.** Verbatim authoring is the default when the prose artifact is small
enough for design.md to carry cleanly — paragraph-scale items such as a SKILL.md rule, a
frontmatter description, a reviewer directive, or a short rubric. For larger prose artifacts
(multi-section skill bodies, multi-page reviewer protocols, lengthy agent instructions),
design.md specifies (a) the intent and required behaviors, (b) the structural skeleton, and
(c) any **anchor phrases** that MUST be exact — sentences whose wording is load-bearing for
LLM behavior (RED FLAG / STOP directives, Iron Rules, "do NOT X" prohibitions, named
antagonist behaviors). The full body is authored at Implement against that spec (Plan
packages the deferred spec into a task with test expectations that assert intent, skeleton,
and anchor-phrase presence). Err toward verbatim when in doubt — small artifacts deserve
verbatim treatment; defer only when full inclusion would balloon design.md and lose altitude.

**Default when in doubt.** If the artifact is text an LLM will read as instructions, treat
the wording as binding. For paragraph-scale items, author the literal sentence. For multi-
section bodies, author the intent + skeleton + anchor phrases per Scope proportionality
above. "The rule should say X in spirit" is insufficient at any scale — even when deferring
the body to Implement, the design.md spec must be precise enough that paraphrase risk is
constrained.

**Operational rule for design.md.** When locking a prose-design decision, write the content
inside a fenced block or blockquote, marked with a comment naming the target artifact. For
verbatim (paragraph-scale) decisions:

```
<!-- prose-design: <target file> § <section> -->
<verbatim text here>
```

For deferred (multi-section) decisions, mark the spec block with the deferral note:

```
<!-- prose-design (deferred to Implement): <target file> § <section> -->
Intent: <one-paragraph behavioral spec>
Skeleton: <ordered list of required subsections>
Anchor phrases (MUST be exact):
  - "<load-bearing sentence 1>"
  - "<load-bearing sentence 2>"
```

Downstream readers handle both:
- Verbatim blocks → exact-copy contracts; Implement copies them through without paraphrase.
- Deferred blocks → intent + skeleton + anchor-phrase contracts; Plan packages the spec
  into a task with test expectations (anchor phrases present verbatim, skeleton structure
  matches, intent satisfied); Implement authors the full body against the spec.

In both cases anchor phrases are exact-copy.

**Worked examples:**

| Artifact | Altitude content | Sub-rule | Form |
|---|---|---|---|
| Shell script identity (rename + behavior) | Name + purpose + behavior; no function signatures | A | — |
| Skill prose rule (e.g., a Dialogue Conduct rule) | Verbatim wording inside a marked block | B | Verbatim |
| Reviewer protocol rubric (e.g., change-type classifier) | Verbatim rubric text | B | Verbatim |
| Data-contract artifact identity (e.g., JSON manifest) | Name + purpose + necessary fields; no schema layout | A | — |
| Subagent frontmatter description | Verbatim description text | B | Verbatim |
| Routing matrix / lookup table | Verbatim table | B | Verbatim |
| Multi-section SKILL.md body (e.g., a new skill's full body) | Intent + section skeleton + anchor phrases | B | Deferred → Implement |
| Lengthy reviewer-protocol body (multi-section) | Intent + skeleton + anchor phrases | B | Deferred → Implement |

<!-- prose-design: Design SKILL.md § "Altitude Sub-Rule C — End-to-End Flow" -->

**Altitude Sub-Rule C — End-to-End Flow** (applies whenever a design decision introduces or modifies an interaction across two or more actors — orchestrator, script, subagent, file, manifest, external service, user).

When a decision involves multiple actors that hand off to each other, the design block MUST specify the end-to-end flow between them, not just enumerate the components in isolation. "We'll have script X and agent Y and manifest Z" is component enumeration; the design has to also say what calls what, in what order, with what inputs, producing what outputs, consumed by whom.

**Required flow elements** (for any multi-actor decision):
- **Actor inventory** — name every actor that participates in the flow (orchestrator, script, subagent, file, external service, user).
- **Sequence of operations** — ordered list of who-does-what. If parallelism matters, name the parallelism boundary (e.g., "M Task tool calls in parallel in one orchestrator response").
- **Per-step inputs and outputs** — what each actor receives at each step and what it produces. Cite where outputs are written (stdout, file path, manifest entry, Task tool return value).
- **Consumer identification** — for every output, name who reads it next. An output with no named consumer is dead and must be removed or its consumer surfaced.
- **Loud-failure paths** — what happens when each step fails (the step's failure mode, where the failure surfaces, which actor catches it). "Silent fallback" is never the answer — name the diagnostic.
- **Context-cost call-out** — for any flow that crosses the orchestrator/subagent boundary, explicitly state what enters the orchestrator's context vs. what stays in subagent context or on disk. This is the substrate for G3-class concerns; flows that bloat the orchestrator window without saying so leak prompt content silently.

**Altitude test.** Ask: "Can Structure / Plan / Implement enumerate the per-round (or per-cycle) orchestrator actions in order, naming inputs and outputs for each step, without inventing sequencing decisions the design failed to commit?"
- If yes → flow is specified at the right altitude.
- If no → back off and add the missing steps. The most common gap is the orchestrator-side instruction work: "the script returns N specs" without saying how the orchestrator parses them and what it does with each one.

**Worked example — failure pattern (components without flow).** A design names three actors — a controller, several worker subagents, a shared output directory — and a goal: collect results from all workers. The design specifies the actors and the goal but not the choreography: how the controller invokes each worker, what each worker is told about where to write, how the controller knows all workers are done, what happens if one worker writes nothing. The result is downstream guessing — Structure invents an invocation contract that doesn't match Plan's task ordering, Implement ships a polling loop the design never authorized, and a worker silently producing no output is missed entirely until Test.

**Worked example — same decision after applying Sub-Rule C.** The design specifies the choreography. The controller writes per-worker inputs to deterministic paths under the shared directory. It invokes the N workers in parallel in a single batched call, passing each worker the path it should read and the path it should write. Each worker reads its input, processes, writes its output to its assigned path. The controller waits for all worker calls to return, then enumerates the shared directory; any expected output that is missing or empty triggers a loud failure citing the missing worker by name. Every actor named, every step ordered, every input and output traced to its producer and consumer, the controller-context-cost call-out present (worker outputs stay on disk; only the consolidated summary enters the controller's window).

**Mermaid flow diagrams.** When the end-to-end flow involves three or more actors with non-trivial sequencing, the per-goal block SHOULD include a Mermaid sequence diagram (or flowchart for branch-heavy flows). The diagram is a load-bearing artifact, not decoration — readers (Structure, Plan, Implement) inspect it before reading the prose. Diagrams are mandatory when the flow:
- crosses the orchestrator/subagent boundary (LLM tool-call boundary)
- involves parallel fan-out followed by wait-all (or other non-linear control flow)
- has loud-failure paths whose detection is across-actor

Per-goal blocks with single-actor or two-actor flows MAY omit the diagram if the prose specification is unambiguous.

**Scope clarification.** Sub-Rule C does NOT push Design into pseudocode (Sub-Rule A still forbids function signatures) or into specifying the per-actor implementation (each actor's internals are owned by Structure for code or Plan for tasks). C specifies the **inter-actor contract**: the shape of each hand-off, the order of operations, the trace from input to output to consumer. Structure and Plan author the internals; Design owns the choreography.

<!-- prose-design: Design SKILL.md § "Sub-Rule D — External-Knowledge Completeness" -->

**Sub-Rule D — External-Knowledge Completeness** (applies whenever a design decision references behavior, contracts, or signals from external systems — host CLIs, vendor APIs, platform runtime injections, library protocols, third-party file formats).

Design is the LAST research-bearing phase in the QRSPI pipeline. After Design, no skill runs research or external-source verification — Structure, Plan, Parallelize, Implement, Integrate, Test all consume what Design committed. Any external-knowledge question Design defers (a "TBD per vendor docs at implementation time" footnote, a "to be verified by implementer" placeholder) becomes a downstream blocker that resolves to either a guess (silently wrong) or a halt the user has to unblock. Either outcome is a design defect.

The only external-to-codebase knowledge downstream skills are expected to bring is: (a) how existing project code works (they Read it), (b) how to generally write code in the relevant language (model weights), (c) how to use ordinary development tools (model weights). Everything else — platform behaviors, vendor contracts, host runtime injections, third-party protocols, file-format specifics — MUST be answered in the design block, with citations.

**Required completeness elements** (for any decision that references external behavior):

- **External-claim inventory** — every external-system claim the design relies on is enumerated explicitly. "We detect autopilot via a host signal" is one claim. "We dispatch with parameter Y on vendor API Z" is another. Implicit references ("the platform handles it", "see vendor docs") are forbidden — name the platform, name the mechanism, write the answer.
- **Verified answer** — each claim has the concrete answer in the design block, not deferred. "Claude Code injects `## Auto Mode Active`" is an answer. "TBD per Claude docs" is not.
- **Source citation** — each claim cites its source: docs URL + fetch date, CLI command + output snapshot, direct runtime observation + observation method + observed value. Citations are durable; the design block is the audit trail downstream skills consult.
- **Verification method label** — note whether the answer was verified by docs-only, by docs + direct observation, or by direct observation only. Docs-only is acceptable when the source is authoritative and stable. Docs + observation is preferred when feasible. **For claims about host runtime injections, direct observation is required** (doc-only is unreliable — host CLIs frequently inject undocumented signals; verified case: Copilot CLI v1.0.57 injects `<autopilot_mode>` with no mention in `copilot help environment` or official autopilot docs).
- **Unknown branches** — when verification yields "unknown" or "host-not-yet-supported", the design block MUST name the unknown explicitly AND specify the safe-default behavior downstream code applies AND specify the verification procedure the implementer follows when the host is added. "Unknown — safe default X — verify via procedure Y" is a valid design answer; "TBD figure out later" is not.

**Completeness test.** Ask: "If a fresh implementer reads only this design block plus the existing project code, can they implement the decision without consulting any external source the design didn't already cite?"
- If yes → external-knowledge completeness satisfied.
- If no → name the missing external answer, research it, write the answer + citation into the design block. If the answer is genuinely unknown at design time, add it as an explicit `unknown` branch with safe-default + verification procedure.

**Worked example — failure pattern (deferred external knowledge).** A design decision says "the orchestrator detects auto-mode via a host-specific signal (see vendor docs for the exact mechanism)." Structure maps the work to a script. Plan authors tasks that consume the detection. The implementer reads the design, finds no concrete signal name, guesses (env var name, system-reminder string), and ships a script that fails to detect anything on real sessions. The bug surfaces at Test or in production. The root cause is design-time external-knowledge deferral.

**Worked example — same decision after applying Sub-Rule D.** The design enumerates supported hosts as locked claims. For each host, the design block names the exact detection signal with citation and verification method. Example: for host A: "`## Auto Mode Active` system-reminder block; verified via plugin skill citation X (docs-only, stable source)". For host B: "`<autopilot_mode>` block containing literal sentence 'Autopilot mode is currently active.'; verified via direct toggle-and-observe on CLI version Z dated 2026-05-31 (docs would have produced the wrong answer)". Unsupported hosts get an explicit unknown branch: "host not yet supported — safe default `interactive` — verification procedure: at host-addition time, toggle the host's auto-mode CLI affordance and observe context for any new tag/marker/sentence; document observation in script header." The implementer reads the block, writes the script branches, and ships working detection on day one. No external research, no guessing, no Test-time surprises.

**Scope clarification.** Sub-Rule D does NOT require Design to restate common-knowledge programming patterns or ordinary tool usage. It targets specifically **claims about external systems whose behavior the implementer cannot verify by reading project code or relying on general programming knowledge**. "We use `git diff` to compare commits" is not a Sub-Rule D claim (basic tool usage). "Vendor X's webhook fires on event Y with payload shape Z" is a Sub-Rule D claim (external-contract specifics). When in doubt, ask: "could a competent implementer answer this from project code + their own knowledge?" If no, Sub-Rule D applies.

---

### Implementation deliverables (for the eventual Plan tasks + Implement work that ships G1)

1. New Design SKILL.md template carrying the verbatim content above
2. Dialogue Conduct section in the Design SKILL.md preamble (the 7 rules above, verbatim)
3. Remove the existing Design SKILL.md "Test Strategy" top-level section (acceptance moves
   inline to each goal block)
4. Remove the existing Design SKILL.md "System Flow" diagram section (the architecture
   diagramming role migrates to Structure)
5. Update the design reviewer agent to enforce the per-goal block structure AND the Altitude Sub-Rule C end-to-end flow requirements (actor inventory present, sequence of operations specified, per-step inputs/outputs traced, consumer identification complete, loud-failure paths named, context-cost call-out present for orchestrator/subagent boundary crossings) AND Sub-Rule D external-knowledge completeness (every external claim has a concrete answer with citation + verification-method label; no "TBD" / "see vendor docs" placeholders; unknown branches name safe-default + verification procedure)
6. Update the design scope-reviewer owns-defers to defer architecture, file maps, and test mechanics
7. Add the Sub-Rules section (Altitude A + B + C + Completeness D) to the SKILL.md, verbatim
8. Mirror the same Dialogue Conduct section into Goals SKILL.md's preamble. Rules 1, 2, 4, 5,
   6, 7 are verbatim. Rule 3 is adjusted: drop the "research summary" tier (Goals runs before
   Research, so no research artifacts exist); the tier ordering becomes codebase → web. All
   other Dialogue Conduct text is identical between the two skills. Goals keeps its existing
   per-goal template and its "Interactive Dialogue" question-topic checklist — G1 only adds
   the Dialogue Conduct rules to Goals; it does not change Goals' artifact template or the
   Pipeline Mode Selection step.

### Acceptance

A design.md produced by the new template can be skimmed in <3 minutes per goal, clearly separates
outcome from implementation, contains enough information for Phasing / Structure / Plan to operate
without backtracking to ask the user fundamental questions, every artifact name in design.md
passes Sub-Rule A's Altitude Test, every prose-design block passes Sub-Rule B (verbatim
wording for paragraph-scale items; intent + skeleton + anchor phrases for deferred items —
both inside marked blocks), and every multi-actor decision passes Sub-Rule C's Altitude Test
(Structure / Plan / Implement can enumerate the per-cycle actor sequence without inventing
hand-offs the design failed to commit). The design-reviewer agent rejects design.md drafts
that ship multi-actor decisions as component enumerations without the required flow elements.

---

## G2 — Schema-migration task shape

**Outcome.** Plan can produce a single "schema migration" task that touches N files (>10) without
running afoul of the LOC ceiling, provided the task carries explicit machinery to ensure
mechanical-only changes.

**Solution.** Codify a `sizing_exception: schema-migration` task type in plan.md. When this
exception is declared:
- Task is permitted to exceed LOC ceiling and file-count guidance
- Task MUST declare `sizing_rationale: <human-readable reason>` field
- Task MUST declare a mandatory `structural_lint:` field naming a bash check that asserts the
  mechanical-only nature of the change (e.g., "every file modified contains identical replacement
  pattern X → Y; no other diff content")
- Plan-spec reviewer EXEMPTS the LOC ceiling check only when all three fields present and the
  structural_lint command actually executes successfully on the proposed diff

**Defaults locked:**
- N-files: ungated (no upper limit when exception declared; structural lint is the real ceiling)
- Structural lint: mandatory (not optional)
- Sizing exception field, rationale field, structural_lint field: all three mandatory together

**Acceptance:**
- Plan can author a schema-migration task with sizing_exception that passes plan-spec review
- An attempted schema-migration task missing structural_lint fails plan-spec review with a clear diagnostic
- Implement can execute a schema-migration task; reviewer dispatches against the (large) diff with structural_lint already-verified status surfaced

---

## G3 — Shell-pipeline splitter collapse + third-party renaming

**Outcome.** All "third-party LLM" infrastructure is host-relative and vendor-neutral.

- **Host-relative.** Whether a given vendor is first-party or third-party depends on the host: Claude is first-party on Claude Code and third-party on Codex CLI; Codex is the symmetric inverse (first-party on Codex CLI, third-party on Claude Code). Copilot CLI uses a model gateway and treats every vendor as third-party. See CD-1 host × vendor matrix.
- **Vendor-neutral.** Claude, Codex, and DeepSeek (v0.7.3+) are all possible vendors. The dispatch infrastructure treats them uniformly via the `--vendor` argument; only the per-vendor transport companion script knows the vendor's CLI/API specifics.

**Solution.** Absorbed entirely into CD-1. The G3-specific pieces:
- Rename inventory per CD-1 § "Rename inventory"
- Hook function inside `dispatch-companion.sh` chooses which vendor-specific transport to invoke
  based on `--vendor` argument
- Q5 research undercount documented as a plugin issue (missed `implement/SKILL.md` as highest-density
  consumer with 9 invocations + 2 splitter blocks)

**Acceptance:**
- No file or shared doc contains a vendor name in its filename for content that is generically third-party (renames per CD-1 § "Rename inventory" land; legitimately vendor-specific transport scripts such as `codex-companion-bg.sh` are the only retained vendor-named files)
- Skill prose dispatching reviewers uses the `dispatch-agent.sh` entry point; no vendor-specific dispatch logic remains in skill prose (all routes through the universal entry point with `--vendor` selection)
- Adding any new vendor (e.g., DeepSeek) requires only: new `<vendor>-companion-bg.sh` + 1 host × vendor matrix row + 1 config entry; no skill prose changes
- using-qrspi/SKILL.md carries the host × vendor matrix table for future agents to consult

---

## G4 — Canonical cumulative diff helper + round preparation

**Outcome.** Diff-anchor construction and ref-selection logic that today lives as orchestrator-side
prose across 9 skills (uniform "Pre-dispatch diff-file emission" paragraph) consolidates into a
single deterministic script that the universal dispatcher auto-invokes.

**Solution.** `scripts/round-prepare.sh` script consolidates:

1. **First action when `--task-branch` is set (per-task invocation — G9 amendment).** Run all three HEAD-related correctness checks, then write the round's commit-anchor before any other work. Each failure mode exits with a distinct code that encodes the orchestrator's recovery action:

   ```sh
   # Check 1: required-flag check (exit 10 — orchestrator bug).
   if [[ -z "$IMPLEMENTER_COMMIT" ]]; then
     echo "round-prepare: --task-branch requires --implementer-commit. Recovery: orchestrator bug — main chat must read commit_sha from the implementer Task return and pass it via --implementer-commit." >&2
     exit 10
   fi

   # Check 2: across-rounds advance check (exit 12 — re-dispatch implementer).
   #   PRIOR_ANCHOR resolves to <output-dir>/../round-(NN-1)-commit.txt when NN >= 2,
   #   or to <task-base-commit> (resolved per step 6) when NN == 1.
   PRIOR=$(resolve_prior_anchor "$ROUND" "$TASK_BASE_COMMIT" "$OUTPUT_DIR")
   if [[ "$IMPLEMENTER_COMMIT" == "$PRIOR" ]]; then
     echo "round-prepare: implementer did not advance HEAD — passed SHA $IMPLEMENTER_COMMIT equals $( [[ $ROUND -eq 1 ]] && echo 'task base commit' || echo 'prior round anchor (round '$((ROUND-1))')' ). Recovery: re-dispatch the implementer subagent via SendMessage or a fresh Task tool invocation; the implementer must produce a new commit before reviewers can run." >&2
     exit 12
   fi

   # Check 3: within-round equality check (exit 11 — halt + diagnose worktree).
   ACTUAL_HEAD=$(git -C "<worktree-path>" rev-parse HEAD)
   if [[ "$ACTUAL_HEAD" != "$IMPLEMENTER_COMMIT" ]]; then
     echo "round-prepare: implementer-commit / HEAD mismatch — main chat passed $IMPLEMENTER_COMMIT, worktree HEAD is $ACTUAL_HEAD. Recovery: HALT — likely worktree corruption, wrong worktree path, concurrent commit by another process, or implementer self-report drift. Surface to user; do not auto-retry." >&2
     exit 11
   fi

   # All checks passed — write the anchor.
   printf '%s\n' "$IMPLEMENTER_COMMIT" > "<output-dir>/../round-NN-commit.txt"
   ```

   `$IMPLEMENTER_COMMIT` is the 40-char SHA passed via `--implementer-commit`, originating from the implementer subagent's self-reported `commit_sha:` field per `implementer-protocol/SKILL.md` § Report Format. Main chat is the only context that sees the Task tool's return value, so it MUST thread the SHA through the invocation chain: `dispatch-agent.sh --implementer-commit <SHA>` → `round-prepare.sh --implementer-commit <SHA>` (CD-1 component #3 documents the dispatch-agent flag surface). On `git rev-parse` failure or write failure (worktree corrupt, disk full, parent dir missing), exit non-zero with diagnostic `"round-prepare: failed to capture round-NN commit anchor at <path>: <stderr>"`.

   **Exit-code recovery table** (consumed by main chat per G9 layer 3 / checklist step 4; dispatch-agent.sh propagates the script's exit code verbatim, so main chat sees the same number from the bash-tool invocation):

   | Exit | Cause | Main chat recovery |
   |------|-------|---------------------|
   | 0    | All checks passed; anchor written | Proceed to reviewer dispatch |
   | 10   | `--task-branch` set without `--implementer-commit` | Orchestrator bug — halt + surface to user; the fix is in the orchestrator's between-rounds sequence, not the worktree |
   | 11   | Passed SHA ≠ `git rev-parse HEAD` | HALT — suspect worktree corruption, wrong worktree path, concurrent commit, or implementer self-report drift; surface to user; do NOT auto-retry the implementer (the implementer's report and the worktree disagree about what was committed, which is an integrity break) |
   | 12   | Passed SHA == prior round's anchor (or task base on round 1) | Re-dispatch the implementer subagent via SendMessage or fresh Task tool invocation; the implementer must produce a new commit before reviewers can run |
   | other | `git rev-parse` failure, write failure, generic error | Surface diagnostic to user |

   **Why the script owns all three checks.** Earlier drafts split the across-rounds advance check ("did the implementer commit something new this round?") into main chat and kept the within-round equality check ("does the passed SHA match the worktree?") in the script. The split was rationalized by recovery ownership — re-dispatching the implementer is a main-chat-only action, so the check that triggers it "belongs" in main chat. But the recovery ownership and the check ownership are independent: the script can produce a verdict (encoded as an exit code with a recovery hint in stderr) and main chat can take the recovery action based on that verdict. Consolidating all three HEAD checks in the script reduces the orchestrator's between-rounds cognitive load to "read commit_sha from Task return; invoke dispatch-agent; branch on exit code" — every SHA-related correctness rule lives in one place and is enforced by deterministic code rather than by an LLM remembering to perform the check between rounds.

   **Round-1 prior-anchor resolution.** For round 1 there is no `round-0-commit.txt`. The across-rounds advance check uses the task base SHA — the same `<task-base-commit>` resolved in step 6 below for the diff base ref. The script resolves it once at script start and uses it for both step 1 (advance check) and step 6 (diff base). When the task base SHA is also unavailable (degenerate edge case — task branch was created without a clear merge-base), the advance check is skipped with a one-line warning to stderr; the within-round equality check still runs and is sufficient by itself for round 1.

   When `--task-branch` is NOT set (artifact-level invocation), step 1 is a no-op — artifact-level review loops do not produce implementer commits today, so the SHA passthrough and all three checks are not applicable.

2. Reading `round-NN-backward-loop.flag` (read-and-delete, force-broaden if present)
3. Reading `round-(NN-1)-scope-set.txt` and `round-(NN-2)-scope-set.txt`
4. Applying step 12's deterministic set-comparison table (equal/proper-subset → narrow; superset/partial-overlap/disjoint → broaden; either empty → broaden; missing → broaden)
5. SHA safety check (`git rev-parse HEAD~1` vs `round-(NN-1)-commit.txt`) when narrowing — on mismatch, fall back to base-branch and write the mismatch reason into the sidecar's `reason` field as a warning
6. Resolving base ref (`<task-base-commit>` when `--task-branch` given; else `<base-branch>` from config/git)
7. Running `git -C <repo> diff <ref> [-- <artifact>]` redirected to `<output-dir>/round-NN.diff`
8. Writing `<output-dir>/.round-prepare.json` sidecar with `ref`, `narrowed`, `scope_hint`, `diff_file`, `reason`
9. Exit 2 for non-git workspace (dispatch-agent treats as "no diff_file, no scope_hint")
10. **Pre-dispatch presence assertion (G9 amendment).** When invoked for round NN ≥ 2 (i.e., the round being prepared is not the first), assert that the prior round's bookkeeping artifacts exist before computing this round's diff:
    - `round-(NN-1)-commit.txt` MUST exist AND match the regex `^[0-9a-f]{40}\n$` (40-char SHA + single trailing newline).
    - When `scope_tagger_enabled: true` in `config.md` AND the prior round is eligible for scope-tagger output (per `implement/SKILL.md` § Per-Task Convergence Narrowing rules — rounds 1 and 2 are always broaden-default and have no scope-set requirement, so the assertion fires only for round NN ≥ 3 on the scope-set file): `round-(NN-1)-scope-set.txt` MUST exist AND be non-empty.

    On any failure, exit non-zero with one of these diagnostics naming the missing artifact:
    - `"round-prepare: missing prior-round commit anchor at <path> — implementer commit-anchor capture failed or skipped in round NN-1"`
    - `"round-prepare: malformed prior-round commit anchor at <path> — expected 40-char SHA + newline, got <first 80 chars escaped>"`
    - `"round-prepare: missing prior-round scope-set at <path> — scope-tagger dispatch was skipped or failed in round NN-1"`
    - `"round-prepare: empty prior-round scope-set at <path> — scope-tagger emitted zero tags in round NN-1, broaden manually or re-run tagger"`

    `dispatch-agent.sh` propagates the non-zero exit per the existing failure-propagation contract (`Auto-invocation by dispatch-agent.sh` → "Clean failure propagation"). The orchestrator is forbidden by that contract from dispatching the next round when round-prepare fails. This converts the silent-drift failure mode (next round dispatched against full base-diff because prior bookkeeping was skipped) into a loud, named failure that surfaces the specific missing step. After the G9 amendment to step 1, the commit-anchor file is normally written by round-prepare.sh's own prior invocation — step 10's assertion is a paranoia check against filesystem-level deletion, race conditions, or someone running round-prepare.sh out of sequence; it should never fire in normal operation.

**Key insight:** Step 12's narrow decision is NOT LLM judgment — it's deterministic set comparison
on outputs from the already-existing `qrspi-scope-tagger` cheap subagent. No additional subagent
needed; the script can make the decision directly.

**Auto-invocation by dispatch-agent.sh:**
- Idempotent: same inputs → bit-identical JSON output
- Atomic mv pattern (write to `.tmp`, rename) — no flock needed for parallel reviewer dispatch
- Short-circuits when `.round-prepare.json` already exists
- Emits loud one-liner to stderr on auto-invocation for transcript observability
- Clean failure propagation: if `round-prepare.sh` exits non-zero, `dispatch-agent.sh` fails with the same exit code rather than dispatching with stale or missing preparation

**Backward-loop flag handling:** Skill prose still writes the flag when the user picks Pause Gate
option 3 (LLM cascade decision). Script reads-and-deletes the flag (mechanical consequence).
Clean LLM/script split.

**Acceptance:**
- 9 skill files lose the "Pre-dispatch diff-file emission" paragraph
- using-qrspi step 12 prose collapses to a description of the table (for human comprehension) plus a one-line "owned by round-prepare.sh"
- using-qrspi Standard Review Loop step 1 prose collapses (the master diff-emission template moves into `round-prepare.sh`); the 9 per-skill paragraphs in the bullet above are the copies that lose their prose, this is the master they were copied from
- Parallel reviewer dispatch (4-way) never produces a corrupted `.round-prepare.json` or `.dispatch-manifest.json`
- Backward-loop reset still survives `/compact` (file-based flag mechanism unchanged)
- A v0.7.1-style hand-computed merge-base error becomes impossible because the script always computes it correctly

---

## G30 — Compaction-resilient incremental persistence for Goals and Design

**Outcome.** Goals SKILL.md and Design SKILL.md both:
- Author directly to their final artifact (`goals.md` / `design.md`) with `status: draft` as decisions lock — no separate staging file, no end-of-phase transformation step
- Survive `/compact` mid-phase without losing per-decision content
- Run a lightweight "finalize" pass at end-of-phase that validates completeness and flips status to `approved-pending-review`

(Dialogue Conduct rules for both skills are owned by G1 — see G1's deliverables for the verbatim 7-rule section and its Goals/Design application.)

**Solution.**

After each per-decision lock signal (user says "approved" or equivalent), the orchestrator appends a structured per-decision block to the final artifact (`goals.md` or `design.md`) with `status: draft` in the frontmatter. The block uses the skill's own template (Goals' 3-field template / G1's 5-field Design template). Cross-Goal Decisions in Design (e.g., CD-1) live in a dedicated `## Cross-Goal Decisions` section at the top of `design.md`; Goals has no equivalent cross-decision section (its template is purely per-goal).

**Lock semantics — presence ≡ locked.** The artifact (`goals.md` / `design.md`) is a **keyed map of locked decisions**. A decision is locked if and only if its block appears in the file. There is no "tentative," "pending," or "placeholder" state inside the artifact; if a decision is not fully formed, it does NOT appear. This is the same rule as the Evergreen-Output Rule (CD-2) applied to incremental persistence: dialogue exhaust (TODO lists, "to be filled," "placeholder for synthesis") never enters the artifact.

**Where remaining-work tracking lives** (differs by skill):

- **Goals.** No upstream inventory exists — goals emerge from user dialogue. "Remaining work" at Goals time is *"has the user articulated everything they want?"*, answered by the user, not by a file diff. The orchestrator's only persistent state is what's already locked in `goals.md`; everything else is the live dialogue.
- **Design.** Upstream inventory is **`goals.md`'s goal list** — each goal in `goals.md` requires one per-goal solution definition in `design.md` (per G1's template). Remaining work = `goals.md` goals − decisions already present in `design.md`. The recovery diagnostic's `K remaining` is computed this way.
- **Cross-Goal Decisions in Design** are additive — they emerge during walkthrough (CD-1 emerged during G3) and are not pre-enumerable from any inventory. The orchestrator surfaces them as the per-goal walkthrough discovers cross-cutting concerns.
- **Reasoning material is NOT an inventory.** Design consults `research/summary.md`, the codebase, and the web *while* working on a given decision — this material informs *how* to decide, not *what* to decide. Do not treat it as a remaining-work source.
- **In-session working memory** (SQL `todos` table, transient orchestrator notes) MAY track pending walkthroughs for the *current session*; nothing about that working memory persists to the artifact.

**Recovery after compaction.** On phase resume after `/compact`, the skill SKILL.md instructs the orchestrator to:
1. Read the draft artifact (`goals.md` or `design.md`) to enumerate which decisions are already locked
2. Compute remaining work per the "Where remaining-work tracking lives" rule above (Goals: ask the user; Design: `goals.md` goals − locked decisions in `design.md`)
3. Surface a recovery diagnostic to the user: `"Resumed after compaction — last locked decision: GNN (M decisions locked, K remaining). Continuing from G(NN+1)."`
4. Continue dialogue from the next unlocked decision

**End-of-phase finalize.** Once the per-decision walkthrough completes, a lightweight pass:
- Validates all upstream decisions are represented (every goal in `goals.md` has a corresponding goal entry; every design goal has all 5 fields populated)
- Optionally appends an intro/overview if absent (Goals: Purpose section; Design: top-level summary)
- Validates Cross-Goal Decisions section is well-formed (Design only)
- Flips `status: draft` → `status: approved-pending-review` (or whatever the next-gate convention is)

The finalize pass can be inline skill prose OR a small subagent — it's mechanical validation, not synthesis from scratch. Recommendation: subagent for both skills to retain the qrspi end-of-phase-subagent precedent and to keep the SKILL.md prose compact.

**Idempotent revision.** Per-decision blocks are keyed by decision ID (e.g., `### G3 — ...`). Re-locking a previously-locked decision (e.g., user re-opens G3 after walking G15) overwrites that block in place. The artifact's per-decision blocks are NOT append-only; they're a keyed map persisted as ordered markdown.

**Acceptance.**
- Goals SKILL.md authors directly to `goals.md` with `status: draft` as goals lock; end-of-phase finalize flips to `approved`
- Design SKILL.md authors directly to `design.md` with `status: draft` as per-goal solutions lock; end-of-phase finalize flips to `approved`
- Resume-after-compaction in either skill produces a recovery diagnostic and continues from the correct decision
- Idempotent revisit (re-locking a previously-locked decision) overwrites the block in place, doesn't append
- A simulated compaction at G15 mid-Phase-1 followed by resume produces a final artifact identical to a no-compaction run (acceptance test for the durability contract)
- Goals SKILL.md's Pipeline Mode Selection step (config.md authoring) is preserved unchanged; G30 only changes the per-goal authoring path
- Reviewer pass: the Goals and Design quality reviewers gain a check for "draft artifact `status: draft` set during phase, flipped to `approved` only by finalize" (so a hand-edited `status: approved` mid-phase fails review)
- Reviewer pass: the Goals and Design quality reviewers flag any block in the artifact whose body is a placeholder, TODO, "to be filled," or "placeholder for synthesis" marker — only fully-formed decisions are permitted in a `status: draft` artifact (per Lock semantics above, presence ≡ locked)

**Dependencies + edge cases.**
- Depends on G1 (defines Design per-goal template that the draft mirrors)
- Edge case: artifact directory not in git. Solution: same as today's review-loop fallback — the draft file lives on disk in the artifact dir; just no automatic commit until phase finalize
- Edge case: phase aborts mid-walkthrough. The draft artifact persists with `status: draft`; a subsequent skill re-entry resumes against the draft rather than restarting Phase 1 from G1
- Edge case: user revises an earlier-locked decision mid-phase. Solution: idempotent per-decision-ID overwrite; the artifact is a keyed map, not append-only
- Edge case: Goals user picks "Approve, skip review" at human-gate. Finalize pass still runs (it validates completeness) but reviewer pass is skipped; status flips directly to `approved`
- Edge case: third-party vendor model variance in finalize subagent dispatch. Finalize subagent should use a low-tier model since the work is mechanical (consistent with G22 tier rubric)

---

## G31 — Prompt-prose review coverage

**Outcome.** Every QRSPI run that touches prompt prose has the prompt-prose subject to automated review against the canonical prompt-design rules — regardless of whether the project under development is qrspi-plus itself or any other project a user happens to author prompts for (AI agent system prompts, MCP tool descriptions, internal prompt libraries, RAG instructions, custom skill files for any platform, etc.). Two changes ship together: (1) the rules file is refreshed and relocated to `skills/_shared/prompt-design-rules.md` (renamed from the prior `docs/prompt-design-guide.md`), applying the eight audit findings (A-H) surfaced in G31's "What we know so far," and (2) the existing reviewers `qrspi-code-quality-reviewer` and `qrspi-design-reviewer` gain a step that — using their LLM content-comprehension capabilities — identifies which files (or which blocks within files) in the diff ARE prompt prose and applies the refreshed rules to those subjects. No new reviewer agent is created. No new file-path heuristic, glob pattern, or config knob is introduced; the reviewer judges content semantically.

**Solution.**

<!-- prose-design: skills/_shared/prompt-design-rules.md § (refresh in place at new location) -->

**File location and rename.** Relocate the rules file from `docs/prompt-design-guide.md` to `skills/_shared/prompt-design-rules.md` and rename to match its true nature (a contract of rules, not a tutorial guide). Implementation: `git mv docs/prompt-design-guide.md skills/_shared/prompt-design-rules.md` plus content edits (refresh per A-H below) plus reference updates in any consumers that already link to the file. The new location aligns with QRSPI's established convention — `skills/_shared/` is the canonical home for cross-skill technical content (alongside `precondition-block.md`, `tsc-probe-helper.md`, `codex/launch-await-pattern.md`); `docs/` is for human-targeted documentation (release notes, design specs, project READMEs) and is the wrong scope for a runtime contract that agents Read. The rules file travels with the plugin (resolved at runtime from the installed plugin path per host convention — e.g., on Copilot CLI: `~/.copilot/installed-plugins/qrspi-plus/qrspi/skills/_shared/prompt-design-rules.md`; analogous paths on Claude Code and Codex CLI; standard skill-directory resolution applies). The file is NOT expected to live in the user's project repo; users developing prompts for their own products get the rules enforced against their work even though their repo doesn't contain them. The rules file is a human-maintained reference reviewers Read at runtime; it is NOT `!cat`-included into any SKILL.md preamble (file is 185+ lines; inlining would balloon every authoring skill and re-create the verbosity-bias problem the rules themselves warn against).

**Rules refresh — eight specific updates.** All eight are paragraph-scale prose edits to `skills/_shared/prompt-design-rules.md`. Sub-Rule B authority: intent + anchor phrases below; Implement authors the final wording.

- **(A) Refine the "Positive framing outperforms negative framing" cross-cutting principle.** Recast as: *"Negation works in modern LLMs (Claude 4+, GPT-4+) when paired with (1) a positive substitute, (2) a named antagonist label, and (3) a decision rule. Bare 'do not X' without a substitute is the GPT-3-era anti-pattern. The Iron Laws, Red Flags, and Common Rationalizations sections in QRSPI skills demonstrate the paired pattern in practice."* Anchor phrases: "Negation works in modern LLMs," "paired with positive substitute + named antagonist + decision rule," "bare 'do not X' without substitute is the GPT-3-era anti-pattern."
- **(B) Fold CD-2's six named antagonist patterns into R1.** Under R1's "Cut these categories," add a sub-block titled "Named antagonist patterns (CD-2)" listing: dialogue exhaust, session/drafting notes, version-history narration, inside baseball, compaction-loss recovery notes, failure-modes-prevented lists. Each name carries a one-line definition + a substitute pattern (per CD-2's already-locked table). Anchor: "Named antagonist patterns (CD-2)."
- **(C) Add the Evergreen Litmus Test as a cross-cutting principle.** New principle: *"Litmus test — before writing any paragraph in an artifact governed by `status: draft → approved`, apply the two-question filter: (1) does this paragraph read true if every prior draft were deleted? (2) is the subject the WHAT being designed, or the dialogue that produced it? If either filter fails, the paragraph is dialogue exhaust — strip it."* Cite CD-2 as source. Anchor: "Evergreen Litmus Test," "two-question filter."
- **(D) Add "Anchor phrases" as a cross-cutting principle.** New principle: *"Anchor phrases — when a phrase must be preserved verbatim across edits (e.g., a verbatim Sub-Rule B prose-design block, the locked text in CD-2's Evergreen-Output Rule), call it an 'anchor phrase' in the surrounding prose. Anchor phrases are the audit handles reviewers and authors use to detect silent drift."* Cite G1 Sub-Rule B + CD-2 acceptance criteria as sources. Anchor: "Anchor phrases — verbatim audit handles."
- **(E) Vendor-neutralize R5.** Current R5 opens *"For Claude Code: spine + references saves zero tokens if the spine always instructs the read."* Rewrite to: *"For agent platforms that pre-load skill text (Claude Code, Codex CLI, Copilot CLI, and equivalent hosts): spine + references saves zero tokens if the spine always instructs the read."* G3 vendor-neutrality is the source. Anchor: "agent platforms that pre-load skill text," "Claude Code, Codex CLI, Copilot CLI, and equivalent hosts."
- **(F) Fix source-research paths.** R1's `Source research` section cites `general2/docs/superpowers/specs/2026-04-25-qrspi-skill-refactor-design.md` and `general2/docs/qrspi/2026-04-06-phase4-hooks/phases/phase-02/research/prompt-best-practices.md` — both point outside this repo. Either (a) inline-fold the load-bearing derivations into the rules file and drop the external references, or (b) replace with intra-repo references (the v0.7.2 release docs at `docs/qrspi/2026-05-30-v072-release/research/summary.md` Q1-Q5 if applicable). Implement decides between (a) and (b) based on which preserves more verifiable provenance. Anchor: no external `general2/...` paths.
- **(G) Recalibrate "Last applied" + re-test against May 2026 model landings.** Bump `Last applied:` to the date the refresh ships. Run a single-pass re-test of R1-R7 + cross-cutting principles against the current model lineup (Opus 4.7-high, GPT-5.5, GPT-5.3-Codex, Sonnet 4.6). The test is "for each rule, does the cited evidence still hold at current model capability?" If any rule's evidence has weakened, annotate inline (do NOT remove the rule — the historical evidence still applies to its model era; mark the rule with a "May 2026 status: confirmed | weakened | superseded" line).
- **(H) Add compaction-resilient prompt design as a cross-cutting principle.** New principle: *"Compaction-resilient prompt design — when an orchestrator-driven skill spans enough decisions to risk mid-phase `/compact` firing (Goals, Design at scale), the SKILL.md prose must (1) instruct incremental persistence to the final artifact under `status: draft`, (2) instruct a recovery diagnostic on resume, and (3) instruct the orchestrator to re-read the in-progress artifact to enumerate locked decisions before continuing. Presence ≡ locked (G30); no placeholder bodies (CD-2)."* Cite G30 + CD-2 as sources. Anchor: "Compaction-resilient prompt design," "presence ≡ locked," "no placeholder bodies."

<!-- prose-design: agents/qrspi-code-quality-reviewer.md — add prompt-prose content-detection + rules application -->

**`qrspi-code-quality-reviewer` amendment.** Add a step in the agent's review procedure: *"For each file in the diff, determine semantically whether the file's content (in whole or in part) is **prompt prose** — i.e., text authored to be loaded into an LLM's context as instructions, system prompts, agent definitions, skill definitions, reviewer rubrics, MCP tool descriptions, RAG instructions, or any equivalent LLM-consumable directive content. Use content semantics, not file path or extension, as the determining signal. Examples of prompt prose: a SKILL.md body that instructs an orchestrator; an `agents/*.md` file defining a subagent; a `.md` file under a project's `prompts/` directory with YAML frontmatter containing `description:` indicating LLM consumption; a verbatim system prompt embedded in any markdown file (e.g., 'You are...', 'Your role is...', `<HARD-GATE>` blocks, role + task + constraints structure); a `.txt` or `.json` file whose content is plainly an LLM instruction payload. Examples of NOT prompt prose: code documentation, README files describing features, design decisions in prose form (unless a `<!-- prose-design: ... -->` marker indicates a verbatim prompt-prose block within), research notes ABOUT prompts (the prompt-design-rules file itself is a meta-document — it IS reviewed against its own rules per the meta-acceptance below, but ordinary research/explanatory content about prompts is not), configuration files, test fixtures. Apply judgment liberally — when content semantics indicate prompt prose, treat it as in-scope regardless of where it lives in the repo. For each file or sub-block determined to be prompt prose, Read `skills/_shared/prompt-design-rules.md` (resolved from the installed plugin path per host convention) and apply R1-R7 + cross-cutting principles + finding-type gate. Emit findings using the standard reviewer schema; tag with `change_type: clarity` for verbosity/anchor-phrase findings and `change_type: correctness` for finding-type-gate violations (e.g., load-bearing rule placed at start instead of end, examples exceeding the 2-cap)."* Anchor phrases: "determine semantically whether the file's content … is prompt prose," "Use content semantics, not file path or extension," "skills/_shared/prompt-design-rules.md (resolved from the installed plugin path per host convention)."

<!-- prose-design: agents/qrspi-design-reviewer.md — add prose-design-block + content-detection rules application -->

**`qrspi-design-reviewer` amendment.** Add a step in the agent's review procedure: *"For each block within `design.md` in the diff, determine semantically whether the block is verbatim **prompt prose** destined for an LLM-consumable file (SKILL.md, agent body, reviewer rubric, etc.). A `<!-- prose-design: target -->` HTML-comment marker is one strong signal but not the only one — apply the same content-semantic judgment described in qrspi-code-quality-reviewer's amendment: if a block's text reads as direct LLM instructions or definitions (Iron Laws, role+task+constraints structure, `<HARD-GATE>` blocks, verbatim rule statements destined for an orchestrator or subagent prompt), treat it as prompt prose. For each prompt-prose block, Read `skills/_shared/prompt-design-rules.md` (resolved from the installed plugin path per host convention) and apply R1-R7 + cross-cutting principles to the block's content. Emit findings using the standard reviewer schema."* Anchor phrases: "determine semantically whether the block is verbatim prompt prose," "A `<!-- prose-design: target -->` HTML-comment marker is one strong signal but not the only one," "skills/_shared/prompt-design-rules.md (resolved from the installed plugin path per host convention)."

**Why this approach.** The decision to use **LLM content-semantic judgment** rather than path-based heuristics (file globs, extension matching, directory conventions) flows from a simple observation: the reviewers ARE LLMs that already Read every file in the diff to evaluate findings. They are fully capable of determining whether content IS prompt prose by reading it. Path-based heuristics are over-engineering for a system whose primitive is reading-and-reasoning. The path-heuristic approach was rejected because: (1) it requires hardcoding qrspi-plus's own layout (`skills/**/*.md`, `agents/**/*.md`) into a rule that is meant to be universal across any project a user develops prompts for; (2) it requires either a user-declared config field (added burden on users + an additional schema surface to maintain) or a default-globs list (which goes stale as conventions evolve and creates a maintenance treadmill); (3) it cannot catch prompt prose that lives in unconventional locations (embedded in markdown, in `.txt`, in custom directory layouts) without ever-expanding glob lists. Content-semantic detection trades a tiny additional per-file judgment cost (the reviewer already reads the file) for universal coverage with zero config. Expanding the two existing reviewers — rather than introducing a dedicated `qrspi-prompt-reviewer` agent — is consistent with the standing "expand what's there before adding new" working principle and avoids: (1) an always-on fanout slot whose cost falls on every Implement round even when zero prompt prose is touched; (2) duplicated content-detection logic across reviewer agents; (3) fragmenting prompt-quality enforcement across more agents to maintain. The hybrid architecture (existing reviewers handle easy cases, dedicated reviewer fires above a threshold) was rejected as combining the worst of both options. **Relocating the rules file from `docs/` to `skills/_shared/`** was chosen because `skills/_shared/` is QRSPI's established home for cross-skill technical content that lives close to the skills consuming it (precedent: `precondition-block.md`, `tsc-probe-helper.md`, `codex/launch-await-pattern.md`); `docs/` is the wrong scope (it is for human-targeted documentation — release notes, design specs, READMEs — not for runtime contracts that agents Read). The alternative location `skills/reviewer-protocol/` was rejected as too narrow (the rules are an authoring contract that reviewers enforce, not reviewer-only material). The **rename from "guide" to "rules"** was chosen because the file IS rules + decision gates + finding-type classifications, not a tutorial; signaling enforcement intent in the filename helps both authors and reviewers calibrate. Keeping the rules file strictly reviewer-side (rather than also `!cat`'ing into authoring-side SKILL.md preambles) was chosen because G1's Dialogue Conduct + Sub-Rules A/B already encode the load-bearing authoring guidance; reviewer-side enforcement is the more powerful gate; and SKILL.md size bloat compounds the failure mode the rules are trying to prevent.

**Dependencies + edge cases.**
- Depends on G1 (defines the `<!-- prose-design: ... -->` marker that serves as one strong signal in the design-reviewer's content-semantic detection).
- Depends on CD-2 (supplies the named antagonist patterns + litmus test for rules updates B and C).
- Depends on G30 (supplies the compaction-resilient prompt-design principle for rules update H).
- Depends on G3 (supplies the vendor-neutrality reframing for rules update E).
- Co-ships with G1, G30, CD-1, CD-2 in v0.7.2 — same release wave.
- Edge case: the reviewer's content-semantic judgment is borderline (a file mixes prose documentation ABOUT prompts with verbatim prompt-prose excerpts). Solution: judge per-block where the file's structure permits; when ambiguous, default to applying the rules and let the finding-type gate filter false positives. The cost of one extra finding-type-gate evaluation is negligible relative to the cost of missing real drift.
- Edge case: the `skills/_shared/prompt-design-rules.md` file is itself in the diff (e.g., the v0.7.2 ship of this very refresh). The reviewer's content-semantic judgment correctly identifies it as a meta-document about prompt prose; per the meta-acceptance below, the reviewer SHOULD apply the rules to it (the rules must satisfy themselves). No special-case in the reviewer instruction needed; the reviewer's semantic judgment handles it.
- Edge case: a `<!-- prose-design: ... -->` block points at a target that is NOT prompt prose (e.g., a code file like `scripts/round-prepare.sh` per G4). Solution: the marker is one signal among many; the reviewer's content-semantic judgment determines whether the block's text reads as prompt prose. If the block contains shell-script intent rather than LLM-instruction prose, the reviewer skips rules application for that block. Marker presence alone does not force application.
- Edge case: a user's project has prompt prose in a file extension or layout the reviewer has never seen (e.g., `.prompt`, `.tmpl`, an XML wrapper). Solution: the reviewer's content-semantic judgment is extension-agnostic — if the file's content reads as prompt prose, the rules apply. No extension allowlist is maintained.
- Edge case: pre-existing inbound references to `docs/prompt-design-guide.md` (e.g., from other skill files, reviewer agents, or external links). Solution: as part of the `git mv`, sweep the repo with `grep -rl "docs/prompt-design-guide.md"` and update each reference to the new path + filename. Implement is responsible for the full reference update; G31 acceptance verifies no stale references remain.
- Edge case: model-availability variance in reviewer dispatch (per G20). Content-semantic judgment is a baseline reasoning capability across all reviewer-tier models QRSPI currently dispatches; no model-specific carve-out needed. The judgment is presented as a step in the reviewer's procedure, evaluated the same way the reviewer evaluates any other finding criterion.

**Acceptance.**
- `skills/_shared/prompt-design-rules.md` exists at the new path; `docs/prompt-design-guide.md` no longer exists; `git log --follow` traces the file history through the rename.
- `skills/_shared/prompt-design-rules.md` `Last applied:` date is bumped to the refresh ship date; all eight updates (A-H) are visible in the file as inline edits (no detached changelog).
- `agents/qrspi-code-quality-reviewer.md` body contains the content-semantic detection step with anchor phrases "determine semantically whether the file's content … is prompt prose," "Use content semantics, not file path or extension," and "skills/_shared/prompt-design-rules.md (resolved from the installed plugin path per host convention)."
- `agents/qrspi-design-reviewer.md` body contains the content-semantic detection step with anchor phrases "determine semantically whether the block is verbatim prompt prose," "one strong signal but not the only one," and "skills/_shared/prompt-design-rules.md (resolved from the installed plugin path per host convention)."
- No file in the repo (skills, agents, scripts, tests, docs) contains a stale reference to `docs/prompt-design-guide.md` after the rename completes.
- Positive smoke test: a SKILL.md change (or equivalent prompt-prose change) emits at least one rules-grounded finding from `qrspi-code-quality-reviewer`; a `design.md` change containing a `<!-- prose-design: ... -->` block emits at least one such finding from `qrspi-design-reviewer`.
- Negative smoke test: a pure code-only change (e.g., a `.ts` or `.sh` file modification with no prompt-prose content) emits zero rules-grounded findings (the content-semantic step short-circuits naturally; no false positives).
- Cross-project applicability: demonstrated against a project whose layout does NOT match qrspi-plus's `skills/`+`agents/` convention — e.g., a hypothetical project with prompts under `src/llm-prompts/*.md` triggers rules application from `qrspi-code-quality-reviewer` based on content alone, with no `prompt_prose_paths:` config and no plugin-side glob update. Confirms the feature works for users developing prompts for their own products, not just for qrspi-plus self-host.
- No new agent file added under `agents/`; no `!cat` of the rules file into any SKILL.md preamble; no new config field in `config.md`; no new path-glob heuristic anywhere in the reviewer dispatch chain.
- Meta-acceptance: the refreshed `skills/_shared/prompt-design-rules.md` applied against itself (the reviewer correctly identifies it as a meta-document about prompt prose and applies R1-R7 to it) passes its own audit — the rules must satisfy themselves.

---

## G5 — Idempotent post-approval plan split

<!-- prose-design -->

**Outcome.** Plan's post-approval split step (per-task fan-out that materializes `tasks/task-NN.md` from `plan.md`'s `### Task N` blocks) is re-runnable without harm. A re-invocation after a partial crash dispatches only the missing files; a re-invocation after a fully-completed split is a near-zero-cost no-op that proceeds directly to plan.md reduction + `status: approved`. Hand-edits to per-task files made after the previous split are naturally preserved on re-run. A user amendment to `plan.md`'s `### Task N` block since the previous split fails loud with a named diagnostic rather than silently shipping a stale spec.

**Solution.**

*Decision rule (per task, computed in main-chat orchestrator before the fan-out loop, single pass):*

| Case | `tasks/task-NN.md` state | Decision |
|------|--------------------------|----------|
| 1 | Absent | dispatch sub-subagent to write |
| 2 | Present, block-hash audit matches | safe-skip (no dispatch, no write) |
| 3 | Present, block-hash audit mismatches | **HALT** with named diagnostic |

*Atomic-write premise.* Sub-subagent dispatches don't stream partial files; the Write call lands at the end of the subagent's run, and Write is OS-atomic for the file sizes in play. Therefore file existence is a faithful "previous dispatch for this task completed" signal — no `.I-wrote-this` sidecar, no divergence-vs-hand-authored distinguishability, no `.split-conflict-NN.md` machinery needed. This collapses the original 4-case strawman to the 3-case table above.

*Block-hash audit.* Each `tasks/task-NN.md` carries a single line immediately after the closing frontmatter `---` and before the first body content:

```
# block-hash: <sha256-hex>
```

The hash covers the **normalized** source `### Task N` block from `plan.md`. Normalization = strip trailing whitespace from each line, preserve all other characters and line breaks verbatim. No markdown canonicalization, no case folding, no whitespace collapse — anything that changes wording is considered a change. Algorithm = sha256, hex-encoded, no salt.

Write-time: orchestrator computes the normalized hash for each `### Task N` block before fan-out and passes it to the sub-subagent as a `block_hash:` dispatch field. Sub-subagent emits the `# block-hash:` line verbatim into the file it writes.

Skip-time: orchestrator re-computes the hash from the current `plan.md` block and compares to the line read from the existing `tasks/task-NN.md`. Match → safe-skip. Mismatch → HALT with the named diagnostic:

> `task-NN.md exists but its source block in plan.md has changed since the last split. To regenerate from the current plan.md, delete tasks/task-NN.md and re-run. To preserve the existing file, revert your plan.md edit.`

*Decision site.* Main-chat orchestrator. Two reasons not to push the existence-check into a sub-subagent: (a) `test -e` + a single sha256 compare per task is cheaper than dispatch overhead, (b) keeping the decision auditable in one place (the orchestration step) avoids fan-out-shape coupling for what is a pre-fan-out filter.

*Exact-set verification.* Existing step (skill `plan/SKILL.md` ~line 449) runs unchanged after the fan-out completes. With the idempotent decision rule, a complete-set re-run produces zero dispatches and still passes verification because all files are already present.

**Why this approach.**

- File existence is a faithful "done" signal under the atomic-write premise, so existence-only is the right primary case-split. The block-hash audit is a narrow safety net for the one case existence alone misses (user amended `plan.md`'s block since the previous split without deleting the per-task file). Fail-loud on that case beats silently feeding a stale spec to an implementer six tasks downstream.
- One-line header + one sha256 per skip is the minimum machinery that catches the silent-stale-spec failure mode. The alternative — pure existence-only ("Flavor A") — was considered defensible but loses fail-loud detection of the plan-amend-without-delete case; the cost of the audit is too small to justify accepting that risk.
- Hand-edits to `tasks/task-NN.md` post-write are naturally preserved on re-run — the per-task file's body changed, but the source block in `plan.md` did not, so the hash still matches. This is exactly the goals.md-stated requirement ("not safely re-runnable... can either silently overwrite existing per-task files (clobbering hand-edits) or fail loudly").
- Conventional idempotent-tool semantics (terraform / kubectl): if the user wants a forced regeneration, they delete the artifact and re-run. This matches existing user mental models for idempotent split steps.
- Main-chat decision keeps the existence-check and audit logic visible in the orchestration site rather than buried in sub-subagent prompts, which means the conformance contract (block-hash format + audit failure mode) is reviewable in one file.

**Dependencies + edge cases.**

- Depends on #172's sub-subagent split infrastructure (already landed; see `skills/plan/SKILL.md` lines 433-454 and `skills/plan/post-approval-split-contract.md`).
- Sub-subagent dispatch contract gains one new field: `block_hash: <sha256-hex>`. Sub-subagent prompt template gains an "emit the `# block-hash:` line verbatim immediately after frontmatter close" instruction. Contract document (`skills/plan/post-approval-split-contract.md`) documents the format, position, and conformance rule.
- **Edge case — split was complete and `plan.md` was reduced to overview-only before crash.** `### Task N` blocks no longer exist in `plan.md`; the source-of-truth has shifted to per-task files. Orchestrator detects "no Task blocks in plan.md + N task files present + status not yet approved" → skips both fan-out and audit (nothing to audit against), proceeds directly to `phase_start_commit` + `status: approved`. If `status: approved` is already on disk, the split is fully done — entire step is a no-op.
- **Edge case — quick-fix N=1 path** (`skills/plan/SKILL.md` ~line 112). Inline write path, no sub-subagent. Same idempotency rule applies: `test -e tasks/task-01.md` → if absent, write; if present, audit the block-hash. Single-task plan still emits the `# block-hash:` line.
- **Edge case — block-hash audit HALT during re-run.** Orchestrator does NOT auto-resolve. Surface the named diagnostic, halt the split step, leave the existing per-task file untouched. User decides whether to delete-and-regenerate or revert their `plan.md` edit. No `.split-conflict-NN.md` sidecar — the diagnostic + the existing files are the surface.
- **Edge case — `# block-hash:` line missing from an existing `tasks/task-NN.md`.** Pre-G5 files lack the line. Treat as audit-fail (HALT with a distinct diagnostic: `"task-NN.md is present but carries no '# block-hash:' header. This file predates the idempotent-split contract. To regenerate under the current contract, delete tasks/task-NN.md and re-run."`). Migration is a one-time per-file regeneration; no automatic backfill.
- **Edge case — `# block-hash:` line malformed.** Same fail-loud as missing line; the diagnostic names "malformed block-hash header" specifically.
- Inbound-reference sweep: Implement runs `grep -rl 'tasks/task-NN.md' skills/` to confirm no skill prose assumes "split always re-runs from scratch" — any such assumption is rewritten to reflect idempotency.

**Acceptance.**

- After a partial-split crash (M of N task files written) + re-run, exactly N-M sub-subagent dispatches fire, all task files end up present with valid `# block-hash:` headers, exact-set verification passes.
- After a complete-split re-run (all files present, all hashes match), zero sub-subagent dispatches fire, exact-set verification passes, flow proceeds to plan.md reduction + `status: approved`.
- After a hand-edit to `tasks/task-NN.md` post-write + re-run, the hand-edit is preserved (file present + hash unchanged → safe-skip).
- After a hand-edit to `plan.md`'s `### Task N` block + re-run without deleting `tasks/task-NN.md`, orchestrator HALTs with the named diagnostic and does NOT write `status: approved`. The existing per-task file is not touched.
- The `# block-hash:` line format (position, syntax, algorithm, normalization rule) is documented in `skills/plan/post-approval-split-contract.md` as the conformance contract for both write-time emission and skip-time audit.
- Quick-fix N=1 path emits the `# block-hash:` line and applies the same audit rule on re-run.

---

## G6 — Reviewer disk-write reliability across model families

<!-- prose-design -->

**Type:** `known-fix` (refined from `exploratory` after PI-010 sharpening + the third-party prompt-assembly inspection collapsed the uncertainty to a small, concrete residual).

**Outcome.** Every reviewer dispatch — regardless of (host, model, transport) — produces per-finding files on disk under `reviews/{step}/round-NN/`. The reviewer prompt for any single dispatch carries exactly one emission contract; no prompt contains both "use the Write tool" and "do not use the Write tool" simultaneously. The Claude-reviewer habit-failure profile (intermittent chat-only return on the first-party path with no contradictory instructions in context) is addressed by an explicit iron-law clause in the protocol body, surfaced again in each reviewer agent body.

**Solution.**

*Structural ownership.* CD-1 (Universal dispatch architecture) is the structural owner of this goal. Specifically: `dispatch-agent.sh` branches on `(host, vendor)` per the matrix; the first-party path emits a Task-tool spec and invokes the Task tool (which loads the agent file + auto-loads `skills: [reviewer-protocol]` naturally); the third-party path invokes `dispatch-companion.sh` (renamed from `run-third-party-llm.sh`) which assembles the broker-bound prompt. The rename of `codex-emission-override.md` → `third-party-emission-override.md` (CD-1 rename inventory) makes the override transport-conditional rather than model-conditional, removing the historical contradiction-vector where the override leaked into Copilot-CLI/task-tool/gpt-5.3-codex dispatches and caused chat-only returns.

G6 layers two additive items that CD-1 alone does not deliver:

*(G6-1) Reviewer-protocol body split — emission-agnostic core + per-transport emission siblings.* The current `skills/reviewer-protocol/SKILL.md` embeds a "Per-Finding Disk-Write Contract" section that contradicts the `codex-emission-override.md` content on every third-party assembly (override resolves the conflict by prose alone — "this overrides the above"). Split into three files:

- `skills/reviewer-protocol/SKILL.md` — emission-agnostic core only. Contains: 5-field finding schema, change-type classifier, untrusted-data handling, phase routing, dispatch contract, untrusted-scope-hint markers. Does NOT contain any "use the Write tool" or "emit to stdout" prose.
- `skills/reviewer-protocol/first-party-emission.md` — first-party emission contract: "use Write tool to write `<round_subdir>/<reviewer_tag>.finding-F<NN>.md` per finding, or `<reviewer_tag>.clean.md` sentinel when no findings exist. Chat-only return is a contract violation and produces zero findings for your tag."
- `skills/reviewer-protocol/third-party-emission.md` — third-party emission contract (replaces `codex-emission-override.md` in name and behavior, but no longer phrased as an "override" — there is nothing to override): "you are running in a read-only filesystem sandbox; the Write tool will fail. Emit `<<<FINDING-BOUNDARY>>>` blocks (or the literal `NO_FINDINGS` sentinel) to stdout. The orchestrator pipes your stdout through `third-party-finding-splitter.sh` which materializes the on-disk files."

Each dispatch path produces a single-voice prompt:

| Path | Prompt assembly | Emission section |
|------|-----------------|------------------|
| First-party | Task tool loads `agents/<name>.md` + auto-loads `skills:` references | `first-party-emission.md` (via agent's `skills:` frontmatter, OR explicit auto-load — see Dependencies) |
| Third-party | `dispatch-companion.sh` concatenates: protocol core + agent body + emission file + dispatch params, pipes to broker | `third-party-emission.md` (cat'd in last) |

After the split, no reviewer prompt — first-party or third-party — contains both emission contracts simultaneously.

*(G6-2) Iron-law clause for wrong-channel emission.* Insert a single named directive into both `first-party-emission.md` and `third-party-emission.md`, symmetric across both wrong-channel failure modes (default-to-chat AND default-to-other-transport):

- `first-party-emission.md` iron law: "**Iron law: emit findings ONLY by Write tool to `<round_subdir>/<reviewer_tag>.finding-F<NN>.md` (one file per finding) or `<round_subdir>/<reviewer_tag>.clean.md` (zero-findings sentinel). Any other channel — chat-only return, narrative reply, stdout emission, summary prose — is a contract violation and produces zero findings for your tag. The orchestrator's apply-fix step will report 'expected tag produced no output' and the round will fail to converge.**"
- `third-party-emission.md` iron law: "**Iron law: emit findings ONLY by `<<<FINDING-BOUNDARY>>>`-prefixed blocks on stdout, or the literal single-line `NO_FINDINGS` sentinel on stdout. Any other channel — chat-only return without boundary markers, narrative reply, attempts to call the Write tool (which will fail silently in this read-only sandbox), summary prose — is a contract violation and produces zero findings for your tag. The orchestrator's apply-fix step will report 'expected tag produced no output' and the round will fail to converge.**"

Each iron-law clause names the correct channel positively (Write tool / stdout boundary blocks), enumerates the wrong-channel failure modes by name (covering both the model's default-to-chat habit AND any cross-transport leakage), and ties the violation to the concrete orchestrator-visible failure surface. Reviewer agent bodies (`agents/qrspi-*-reviewer.md`) reference the directive by name in a one-line callout near the "Findings emission" section, replacing today's "per the disk-write contract above" wording with "per the emission contract from your dispatch transport (iron law: wrong-channel emission is a contract violation)".

*Agent-body wording sweep.* Across the ~9 reviewer agent files (`qrspi-spec-reviewer`, `qrspi-code-quality-reviewer`, `qrspi-security-reviewer`, `qrspi-silent-failure-hunter`, `qrspi-goal-traceability-reviewer`, `qrspi-test-coverage-reviewer`, `qrspi-type-design-analyzer`, `qrspi-code-simplifier`, `qrspi-visual-fidelity-reviewer` — Implement complementing agents in Plan/Design/etc. as inventoried), update body wording from "use the Write tool per the Per-Finding Disk-Write Contract" → "use the emission contract from your dispatch transport (iron law: wrong-channel emission is a contract violation)". One-pass sweep at G6 implementation time.

**Why this approach.**

- CD-1 already removes the structural contradiction-vector (`codex-emission-override.md` injected into first-party dispatches). G6's value is the residual: the Claude habit-failure profile (which CD-1 does not address — Claude reviewers fail intermittently even on clean dispatches) and the third-party prompt-internal contradiction (which CD-1's rename clarifies but does not eliminate — the override still concatenates after the disk-write contract on the third-party path, just with a clearer name).
- Splitting the protocol body into emission-agnostic core + per-transport emission siblings eliminates every known contradiction-vector in the reviewer prompt regardless of transport. Each dispatch path's prompt carries one coherent emission story. This is structurally cleaner than the current "later wins + explicit override prose" pattern, which functions today but re-litigates the conflict on every model reading of the prompt and is plausibly a contributor to the intermittent Claude profile.
- The iron-law clause is the lowest-leverage but cheapest lever — one named directive surfaced consistently across protocol body and agent bodies. Cheap to author, cheap to maintain, addresses the "habit / default-to-chat" failure mode the user identified for Claude.
- Both G6 items are content/wording changes that ride on CD-1's structural rework. They have no architectural surface of their own. If CD-1 is rolled back, G6 has nothing to ship.

**Dependencies + edge cases.**

- Depends on CD-1 landing first (or co-landing). G6 has no value on top of the current `codex-emission-override.md` design.
- Depends on the rename `codex-emission-override.md` → `third-party-emission-override.md` from CD-1's rename inventory, then further renames it to `third-party-emission.md` (G6-1 strips the "override" framing entirely — there is nothing to override once the disk-write section is removed from the protocol core).
- Per-agent `skills:` frontmatter auto-loads the protocol core. To deliver the first-party emission file into the agent's context, either: (a) extend the `skills:` frontmatter mechanism to auto-load the first-party emission file alongside the core, or (b) have `dispatch-agent.sh` emit the emission file path as a dispatch parameter and update the agent body to "Read your dispatch-named emission file as your first action." Open decision deferred to Plan-time — both paths satisfy the single-voice acceptance.
- **Edge case — first-party path on Codex (Copilot CLI host).** After CD-1, gpt-5.3-codex dispatched via task tool is on the first-party path. It receives `first-party-emission.md` (use Write tool). Its `tools:` frontmatter declares Write. CD-1's `.dispatch-manifest.json` audit log captures whether Write was actually used; persistent chat-only returns on this path post-CD-1 + G6 indicate either a vendor-level system-prompt suppression we cannot override from prompt content, or a regression. Detection is the manifest signal; remediation falls outside G6's scope (escalation path: re-open the `exploratory` framing as a follow-up goal).
- **Edge case — agent body cites a section name that no longer exists.** Reviewer agent bodies today reference "the Per-Finding Disk-Write Contract" by name. After the split, that section name lives only in `first-party-emission.md`. Agent-body sweep updates wording; protocol-core inbound references (`grep -rl 'Per-Finding Disk-Write Contract' skills/ agents/`) are rewritten in the same wave.
- **Edge case — third-party emission file is missing from dispatch.** `dispatch-companion.sh` asserts file existence before assembly (mirrors existing `assert_file_exists` pattern in current `run-codex-review.sh` lines 343-347). Missing file → fail loud with named diagnostic, no broker invocation. No silent fallback to "let the broker decide."
- Integration test / smoke probe (#7 from original goal candidates) deferred. CD-1's `.dispatch-manifest.json` audit log is the in-band regression signal; synthetic-prompt harness deferred to a follow-up issue if manifest data shows G6 did not converge the reliability profile.

**Acceptance.**

- `skills/reviewer-protocol/SKILL.md` post-G6 contains no "use Write tool" or "emit to stdout" prose. Body lint: `grep -E 'Write tool|stdout' skills/reviewer-protocol/SKILL.md` returns no matches in emission-contract context.
- `skills/reviewer-protocol/first-party-emission.md` exists and contains the disk-write contract + iron-law clause.
- `skills/reviewer-protocol/third-party-emission.md` exists (rename completed from `codex-emission-override.md` via the intermediate `third-party-emission-override.md`) and contains the stdout-emission contract + iron-law clause. The word "override" does not appear in its prose.
- Every reviewer agent body's "Findings emission" section cites "the emission contract from your dispatch transport" and surfaces the iron-law clause name (wrong-channel emission is a contract violation). Agent-body lint: `grep -L 'iron law' agents/qrspi-*-reviewer.md` returns empty.
- For any first-party dispatch, the assembled prompt the subagent reads contains exactly one emission contract (first-party). For any third-party dispatch, the assembled prompt contains exactly one emission contract (third-party). Verified by inspecting a captured prompt from each path.
- Claude-reviewer habit-failure profile measurably reduced post-G6: `.dispatch-manifest.json` audit log shows a lower rate of wrong-channel emission for reviewers compared to the v0.7.1 baseline. (Threshold for "measurably reduced" deferred to Plan; the manifest is the substrate that makes the measurement possible at all.)
- G6 implementation does NOT touch `dispatch-agent.sh`, the host × vendor matrix, the model-routing tier system, or the per-skill review-round prose collapse — all owned by CD-1. Calling-surface acceptance (output-bound `await-round.sh`, batched dispatch-agent, no-op-safe await on first-party-only rounds) is owned by CD-1 components #3 and #4.

**References.** CD-1 (structural owner); PI-010 (#260 sharpening that reframed root cause); plugin issues #213, #216, #245, #246.

---

## G7 — Verifier filter rule: missing at point of use and DRY drift

**Resolved by CD-4 — Verifier-Fan-In Pipeline.** The script becomes the executable source of truth for threshold values; SKILL prose collapses to a single short pointer; orchestrator never carries threshold values in context. See CD-4 § "F. Orchestrator-side prose update" + G7 acceptance row.

**Plan-time ordering.** G8 (field-name lint) + G11 (sidecar extension) must land before or with G7+G12 — the script can't filter on a field reviewers don't emit on a sidecar at the wrong extension. The five goals are reasonably implemented as a single Plan-tracked work bundle owned by CD-4.

**References.** Source: #220. Resolves alongside G8 (#221), G11 (#227), G12 (#252), G13 (#253-class enum drift).

---

## G8 — Reviewer subagents emit `category:` instead of `change_type:`

**Resolved by CD-4 — Verifier-Fan-In Pipeline.** Field name `change_type:` is centralized in `reviewer-protocol/SKILL.md`; per-reviewer agent bodies reference rather than duplicate; script halts with named cause when missing. See CD-4 § "G. Reviewer agent updates" + G8 acceptance row.

**References.** Source: #221. Compound failure with G7 / G13 / G11 / G12 — all resolved together by CD-4.

---

## G9 — Per-task review orchestration drift: scope-tagger, round-NN.diff, round-NN-commit.txt not fired

**Outcome.** The per-task review loop's between-round bookkeeping — diff emission, commit-anchor capture, scope-tagger dispatch, ref selection — fires reliably under context load. Silent drift (round NN+1 dispatching against the full base-diff because round NN's bookkeeping was skipped) becomes a loud, named failure naming which artifact is missing.

**Resolved by:** G4 solution step 1 (consolidated SHA cross-check + across-rounds advance check + missing-flag check + commit-anchor write, all in `round-prepare.sh` with exit-code-encoded recovery routing) + G4 solution step 10 (pre-dispatch presence assertion) + CD-1 component #3 (`--implementer-commit` flag surface on dispatch-agent.sh + verbatim exit-code propagation) + narrow main chat skill prose (read `commit_sha:` from Task return; invoke dispatch-agent; branch on exit code) + this goal's per-task SKILL.md authoring work below. The compound architecture replaces the v0.7.1 split-contract structure (per-task fan-out section at `implement/SKILL.md` line ~929; per-task convergence narrowing section at line ~1184 — orchestrator must context-switch between them between rounds, frequently forgets under load) with a four-layer arrangement: (1) all three SHA-correctness checks (within-round equality, across-rounds advance, missing-flag) ride on `round-prepare.sh`'s pre-flight auto-invocation as step 1, exit-code-encoded so main chat can branch on the verdict without owning the check itself, (2) the meaningful subagent dispatch (scope-tagger) stays explicit in skill prose, (3) the script's own presence assertion catches any miss loudly before the next round dispatches, (4) an in-line checklist gives the orchestrator a sequence-reminder at the per-task fan-out site itself (read commit_sha; invoke dispatch-agent; branch on exit code).

**Solution.**

The four-layer arrangement, by layer (in addition to G4's two inherited layers — diff emission and ref selection — which solve the round-NN.diff and base-ref-selection halves of the per-task review contract without any G9-specific work):

1. **`round-NN.diff` emission (already solved by G4).** `scripts/round-prepare.sh` is auto-invoked by `dispatch-agent.sh` before every reviewer fan-out per CD-1 component #3 (`Check <output-dir>/.round-prepare.json; if absent, auto-invoke round-prepare.sh`). The diff lands on disk deterministically; the orchestrator never has to remember to emit it. No new work for G9 — this layer is inherited from G4.

2. **Ref selection / step-12 narrow-vs-broaden decision (already solved by G4).** `round-prepare.sh` solution step 4 applies the set-comparison table deterministically; the result lands in the sidecar's `narrowed` and `ref` fields. Per-task gets `<ref>=<task-base-commit>` as its broaden default (per `--task-branch` flag in G4 solution step 6). No new work for G9 — this layer is inherited from G4.

3. **All SHA-correctness checks + `round-NN-commit.txt` write (new — owned by G4 solution step 1 + CD-1 component #3 flag surface).** Main chat passes the implementer's self-reported `commit_sha:` (from the Task tool return) to `dispatch-agent.sh` via `--implementer-commit <SHA>`; the flag threads through to `round-prepare.sh` as its first action when `--task-branch` is set. The script runs three checks in order before writing the anchor:

   - **Missing-flag check (exit 10).** `--task-branch` is set but `--implementer-commit` is empty/absent → orchestrator bug (main chat lost the SHA between the Task return and the dispatch invocation). Halt with a diagnostic; main chat surfaces to user.
   - **Across-rounds advance check (exit 12).** Passed SHA equals the prior round's anchor (`<output-dir>/../round-(NN-1)-commit.txt` for NN ≥ 2, or the task base SHA for NN = 1) → implementer did not advance HEAD this round. Recovery: re-dispatch the implementer subagent via `SendMessage` or a fresh Task tool invocation; only main chat can take that action, but main chat takes it in response to the script's exit code rather than computing the comparison itself.
   - **Within-round equality check (exit 11).** Passed SHA ≠ `git rev-parse HEAD` → the implementer's report and the worktree's actual state disagree. Halt; suspect worktree corruption, wrong worktree path, concurrent commit by another process, or implementer self-report drift. Do NOT auto-retry; surface to user (integrity break, not a transient failure).

   On exit 0, the script writes `round-NN-commit.txt = <passed-SHA>`. CD-1 component #3 propagates round-prepare.sh's exit code verbatim through dispatch-agent.sh; main chat sees the exit code from its bash-tool invocation and branches per the recovery table in G4 solution step 1.

   **Why all three checks live in the script.** Recovery-action ownership and check ownership are independent: the script produces a verdict (exit code + stderr recovery hint); main chat takes the recovery action based on the verdict. Consolidating all SHA-correctness rules in one place — `round-prepare.sh` step 1 — reduces the orchestrator's between-rounds cognitive load to a small fixed pattern (read field, invoke script, branch on exit code) and ensures every SHA-related rule is enforced by deterministic code rather than by an LLM remembering to perform the check between rounds. The architectural boundary holds: scripts still don't capture Task tool return values; main chat just passes the value forward as a flag.

4. **Scope-tagger dispatch (orchestrator-driven; explicit in `implement/SKILL.md` per-task review section — new authoring work owned here).** After per-round reviewer fan-in completes — host-agnostic signal: `await-round.sh` has written `<round-dir>/.round-complete.json` with all dispatches resolved (first-party Task subagents return synchronously; third-party Codex subagents resolve via `await-round.sh`'s manifest-driven redirects; first-party-only rounds still invoke `await-round.sh` as a no-op per CD-1 component #4) — main chat dispatches one `qrspi-scope-tagger` Task subagent against the kept finding-files for the round. The dispatch is a first-party Task tool invocation — owned by main chat, not the script chain (per the QRSPI architectural boundary: bash scripts dispatch third-party CLIs; first-party Task-tool subagents are dispatched only from main chat). The dispatch shape already exists in `implement/SKILL.md` § Per-Task Convergence Narrowing → "Step 6 (scope-tagger dispatch) — per-task scope-tagger dispatch" (lines 1199–1207 in v0.7.1). G9's authoring work moves the *invocation step* up into the per-task fan-out section (line ~929 in v0.7.1) so the orchestrator sees it sequentially with the reviewer dispatches, instead of having to context-switch to a separate section.

5. **Fail-loud presence assertion (new — owned by G4 amendment, solution step 10).** `round-prepare.sh` pre-dispatch presence assertion verifies `round-(NN-1)-commit.txt` and (when narrowing-eligible AND `scope_tagger_enabled: true`) `round-(NN-1)-scope-set.txt` exist and are well-formed before computing the round NN diff. Missing or malformed inputs exit non-zero with a diagnostic naming the specific missing file. `dispatch-agent.sh` propagates the non-zero exit per G4's existing failure-propagation contract; the orchestrator is forbidden from dispatching the next round. After layer 3's commit-anchor write, the assertion is a paranoia check against filesystem-level deletion or out-of-sequence invocation — it should not fire in normal operation. See G4 solution step 10 for the full assertion spec and diagnostic strings.

6. **In-line "between-round sequence" checklist (new — owned here, lives in `implement/SKILL.md`).** At the END of the per-task reviewer fan-out section (immediately after the reviewer dispatch prose, before the orchestrator's attention moves on), insert a short numbered block titled "Between rounds — required sequence":

   ```markdown
   **Between rounds — required sequence.** After this round's reviewer fan-in completes and BEFORE preparing the next round's dispatch, the orchestrator MUST perform these five steps in order:

   1. Read `<round-dir>/.round-complete.json` (written by `await-round.sh`). Confirm no `mode: background` entries are still `pending`.
   2. Dispatch `qrspi-scope-tagger` Task subagent against the round's kept finding-files (see § Per-Task Convergence Narrowing → "Step 6" for the dispatch parameters). The tagger writes `<round-dir>/../round-NN-scope-set.txt` per its agent contract.
   3. If the round just completed included an implementer dispatch (initial pass for round 1; fix-cycle implementer-fix for round NN ≥ 2), read the implementer's self-reported `commit_sha:` from the Task tool return per `implementer-protocol/SKILL.md` § Report Format. If `commit_sha:` is absent or malformed, re-dispatch the implementer immediately (do NOT invoke `dispatch-agent.sh` — the SHA-correctness checks in step 4 require a valid SHA). The all-SHA-checks rule (within-round equality, across-rounds advance, missing-flag) lives in `round-prepare.sh` step 1 and is enforced when step 4 runs; this checklist step is just the field-read.
   4. Invoke `dispatch-agent.sh --implementer-commit <SHA-from-step-3> ...` for round NN+1. `round-prepare.sh` (auto-invoked via dispatch-agent's passthrough) runs all three SHA-correctness checks and writes `<round-dir>/../round-NN+1-commit.txt = <passed-SHA>` on exit 0, then asserts prior-round artifacts per G4 solution step 10. Branch on the exit code: 0 → proceed to step 5; 10 → orchestrator bug, halt + surface to user; 11 → worktree integrity break, halt + surface to user; 12 → re-dispatch implementer subagent, then restart this checklist from step 3 with the fresh `commit_sha:`; other non-zero → surface diagnostic.
   5. After dispatch-agent.sh returns its spec lines, invoke the Task tool per spec line (per `_shared/reviewer-dispatch-prose.md` contract), then call `await-round.sh` to finalize the round.

   Steps 1, 3, 4, 5 are mechanical reads, field extractions, single-script calls, or exit-code branches; step 2 is the only one that dispatches a first-party subagent through the orchestrator. The forward-reference to § Per-Task Convergence Narrowing covers details (anchor format, scope-set format, narrow-vs-broaden semantics). The forward-reference to G4 solution step 1 covers the exit-code recovery table that step 4 branches on.
   ```

   This is the reminder the v0.7.1 orchestrator lacked — without it, the orchestrator reads the per-task fan-out prose, dispatches reviewers, and then has to remember (across `/compact`, across context saturation) to navigate to a separate section for the between-round bookkeeping. The in-line checklist puts the sequence at the orchestrator's point of attention.

**Per-task vs artifact-level scope.** The four-layer arrangement applies to per-task review loops (the v0.7.1 failure surface). Artifact-level review loops in `using-qrspi/SKILL.md` § Standard Review Loop have the same conceptual shape (commit anchor, scope-set, narrow-vs-broaden decision) but did not exhibit the same silent-drift symptom in v0.7.1 self-host runs — the artifact-level flow runs less frequently and the orchestrator's attention is less divided. Per-task is in scope for G9; artifact-level is out of scope (revisit in v0.7.3+ if drift surfaces there). G4's commit-anchor write (solution step 1) only fires when `--task-branch` is set, so artifact-level invocations skip it cleanly; G4's presence assertion (solution step 10) is also conditional on prior-round files being expected, which artifact-level invocations naturally don't produce today. G9's in-line checklist is the only piece that is specifically per-task.

**Acceptance criteria:**
- `round-prepare.sh` runs all three SHA-correctness checks in order when `--task-branch` is set, then writes `round-NN-commit.txt = <passed-SHA>` on success. Verified by five bats fixtures: (a) happy path — pre-stage worktree at SHA X with a prior anchor at distinct SHA P, invoke `round-prepare.sh --task-branch <path> --implementer-commit X --output-dir <round-dir> --round 2`, assert exit 0 AND `round-02-commit.txt` contains X + newline; (b) missing-flag — pass `--task-branch <path>` without `--implementer-commit`, assert exit 10 AND stderr matches the orchestrator-bug diagnostic regex; (c) across-rounds non-advance — pre-stage `round-01-commit.txt` containing SHA P, pass `--implementer-commit P --round 2`, assert exit 12 AND stderr matches the re-dispatch-implementer diagnostic regex; (d) within-round mismatch — pre-stage worktree at SHA X, pass `--implementer-commit Y` where Y ≠ X and Y ≠ prior anchor, assert exit 11 AND stderr matches the halt-worktree-integrity diagnostic regex; (e) round-1 across-rounds — pre-stage no prior anchor, pass `--implementer-commit <task-base-commit> --round 1`, assert exit 12 AND stderr names "task base commit" rather than "prior round anchor".
- `dispatch-agent.sh` accepts `--task-branch` + `--implementer-commit` as a pair on per-task invocations and forwards both to `round-prepare.sh` during the pre-flight auto-invocation. dispatch-agent.sh propagates round-prepare.sh's exit code verbatim (no exit-code remapping). Verified by a bats fixture that invokes `dispatch-agent.sh` with each of the round-prepare.sh exit codes 0/10/11/12 forced via a stub round-prepare.sh fixture, asserting dispatch-agent.sh exits with the matching code unmodified.
- `round-prepare.sh` exits non-zero with a named diagnostic when invoked for round NN ≥ 2 with a missing or malformed `round-(NN-1)-commit.txt`. Verified by: a bats fixture that pre-stages a round-2 invocation with the prior anchor deleted; asserts exit code is non-zero AND stderr matches the diagnostic regex.
- `round-prepare.sh` exits non-zero with a named diagnostic when invoked for round NN ≥ 3 with `scope_tagger_enabled: true` AND missing or empty `round-(NN-1)-scope-set.txt`. Verified by: a bats fixture parallel to the above for the scope-set case.
- `implement/SKILL.md` per-task reviewer fan-out section contains the "Between rounds — required sequence" checklist verbatim (locked prose above). Verified by: a grep lint asserting the checklist heading is present in the per-task section AND that the exit-code recovery branches (0/10/11/12) are enumerated in checklist step 4.
- Main chat's between-rounds residual is narrow: read `commit_sha:` from the implementer Task return, invoke `dispatch-agent.sh --implementer-commit <SHA>`, branch on exit code per the G4 step 1 recovery table. Verified by: grep lint on `implement/SKILL.md` that no main-chat-side SHA comparison code remains (the old `run git rev-parse HEAD then compare` instructions from v0.7.1 lines 1190–1195 are removed in favor of "read commit_sha; if missing re-dispatch; else invoke dispatch-agent and branch on exit code"). Companion lint: grep returns zero matches for "rev-parse HEAD" patterns in the per-task review section of `implement/SKILL.md`.
- A v0.7.1-style silent drift (per-task round dispatched against full base-diff because scope-tagger was skipped) becomes impossible because either: (a) the missing scope-set fails `round-prepare.sh`'s assertion loudly at round NN+1, or (b) the in-line checklist surfaces the missing dispatch step at the orchestrator's point of attention at round NN. Verified by: a self-host smoke run on a fresh per-task review loop confirms scope-tagger fires every round and `round-NN-scope-set.txt` lands on disk for every round NN.
- The architectural boundary holds: no first-party Task-tool subagents are dispatched from any bash script, and no script attempts to capture Task tool return values directly. The SHA passthrough is the architecturally honest seam — main chat reads the Task return, the script consumes the value as a flag. Verified by: `grep -rnE "subagent_type|Task\(|Agent\(" scripts/` returns empty (existing convention; G9 does not break it).

**References.** Source: #224. Compound architecture spans G4 (solution step 1 — consolidated SHA cross-check, across-rounds advance check, missing-flag check, commit-anchor write, exit-code recovery table; solution step 10 — presence assertion) + CD-1 component #3 (`--implementer-commit` flag surface on dispatch-agent.sh; verbatim exit-code propagation) + narrow main chat skill prose (read commit_sha from Task return; invoke dispatch-agent; branch on exit code) + this goal (in-line checklist + scope-tagger relocation in implement/SKILL.md per-task fan-out section). The four-layer arrangement converts silent drift into loud failures at the round-boundary that would have masked it in v0.7.1. Three earlier drafts of this goal were corrected before any code was written: (1) the first draft attributed the commit-anchor write to a CD-1 component #11 "post-implementer-dispatch hook in dispatch-agent.sh" — architecturally impossible (dispatch-agent.sh exits before the Task tool runs in main chat; it has no return-path access). (2) The second draft moved the write into round-prepare.sh's first action with an implicit-timing argument ("HEAD at round-prepare time naturally equals the just-committed implementer SHA because nothing else commits in that window") — technically sound but rested on an unverified invariant. (3) The third draft introduced explicit SHA passthrough but kept the across-rounds advance check in main chat, justified by "recovery action ownership" (re-dispatching the implementer is a main-chat-only action). The present design recognizes that recovery-action ownership and check ownership are independent: the script produces a verdict (exit code + stderr recovery hint), main chat takes the action. Consolidating all three checks in the script reduces the orchestrator's between-rounds cognitive load from "remember to do four SHA-comparison checks across two sites" to "read field, invoke script, branch on exit code". The architectural boundary holds throughout: scripts never capture Task tool return values; main chat passes the value forward as a flag.

---

## G11 — Verifier sidecar pipeline: extension drift + orchestrator bypass

**Resolved by CD-4 — Verifier-Fan-In Pipeline.** Sidecar extension locked to `.score.md`; verifier agent's Write tool call is constrained to that path/extension; script halts with named cause on wrong extension; orchestrator consumes sidecar via script rather than chat-parse. See CD-4 § "B. Verifier sidecar" + G11 acceptance row.

**References.** Source: #227. Tight coupling with G12 — both resolved by CD-4.

---

## G12 — Automated verifier-fan-in script (replace orchestrator chat-parsing)

**Resolved by CD-4 — Verifier-Fan-In Pipeline.** `scripts/verifier-fan-in.sh` is the canonical filter; single invocation per round; writes `kept-findings.txt` + `.verifier-fan-in-audit.json`; orchestrator never chat-parses. See CD-4 § "C. `scripts/verifier-fan-in.sh`" + Mermaid diagram (the verifier→script→orchestrator handshake) + G12 acceptance row.

**References.** Source: #252. Owns the consumer that makes G7 / G8 / G11 / G13 load-bearing.

---

## G13 — `change_type` enum drift: reviewer-side emit + orchestrator-side silent fall-through

**Resolved by CD-4 — Verifier-Fan-In Pipeline.** Canonical enum defined once in `scripts/verifier-fan-in.sh` header (DRY source) and once in `reviewer-protocol/SKILL.md` (referenced from per-reviewer agents); script halts on out-of-enum value with named cause; no silent default-keep. See CD-4 § "G. Reviewer agent updates" + G13 acceptance row.

**Future-corroboration seam.** If G19's exploratory walk lands cross-reviewer corroboration as a threshold adjustment, the adjustment is implemented as an extension to `scripts/verifier-fan-in.sh` (per the CD-4 amendment seam) — NOT as orchestrator-side prose. The script remains the only path.

**References.** Source: #253 (and same family). Three-layer compound failure with G7 (rule visibility) + G8 (field name) — all resolved together by CD-4.

---

## Plugin issues observed during this Design session

- **Q5 under-counted consumer list** — research/summary.md Q5 (line 68) said splitter is not invoked by run-codex-review.sh; missed that implement/SKILL.md is the highest-density consumer (9 invocations + 2 splitter blocks).
- **Backward-loop flag mechanism may be dead code** — never observed in any session. The Pause Gate option 3 cascade may be undiscoverable in practice. Preserved in new architecture (cost is negligible) but worth observability check post-v0.7.2.
- **Design skill encourages "synthesize at end"** with no incremental persistence — risks losing 25+ goal-walkthrough decisions if compaction fires mid-Phase 1. This file is the workaround; the fix is a new design SKILL.md instruction to persist incrementally (could fold into G1's deliverables).
