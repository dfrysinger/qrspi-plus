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
   `{extra-low, low, medium, high, extra-high}`. Call sites can pass `--tier-override` (used by
   plan→implementer for per-task complexity variance). Override precedence (top wins):
   1. `--tier-override` flag at dispatch site
   2. Agent's `tier:` frontmatter
   3. `default_tier:` in config.md (for agents missing `tier:` during migration)
   4. Hard-coded fallback `medium` with loud warning

   The initial agent-by-agent tier-assignment rubric (which of the 41 agents declare which
   tier as a default) is the deliverable of G22; the table below covers schema/dispatch only.

2. **Config-owned vendor+model mapping.** `config.md` carries:
   ```yaml
   model_routing:
     extra-low:  none                                              # operator opts in
     low:        { vendor: claude, model: claude-haiku-4.5 }
     medium:     { vendor: claude, model: claude-sonnet-4.6 }
     high:       { vendor: claude, model: claude-opus-4.7 }
     extra-high: { vendor: claude, model: claude-opus-4.7-high }
   ```
   Goals skill onboarding asks 5 questions to populate this (one per tier) with vendor-neutral
   defaults. `none` is a valid answer per tier — an agent dispatch that resolves to a `none` tier
   halts with a loud diagnostic (no silent fallback to a neighboring tier), so operators who
   leave `extra-low` and `extra-high` at `none` see immediate, observable failure if a
   `--tier-override` accidentally targets an unconfigured tier. The `extra-low` and
   `extra-high` rows are operator-only surfaces — no agent declares them as defaults in the
   G22 initial rubric.

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
- An executable smoke test exercises a tier-resolved-to-`none` dispatch and asserts the dispatcher halts with the loud diagnostic per CD-1 #2's no-silent-fallback rule. Form: a single bats test invoking `dispatch-agent.sh` against a `config.md` fixture with one tier set to `none` and an agent targeting that tier; asserts non-zero exit and a diagnostic written to stderr naming the unconfigured tier. This is the executable-enforcement counterpart to CD-1's prose contract — R5/R6 surfaced the structural-fragility concern against v0.7.1's per-H4 mirror pattern (G25's original framing); CD-1's architectural rewrite eliminates the mirror pattern, and this single smoke test closes the executable-enforcement loop at the new layer. See G25 design block (this file) for the absorption rationale.

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

5. **Use simple language and provide context when presenting ideas.** Ground proposals in
   concrete scenarios before naming them abstractly. Assume the user may not have the
   project's internal vocabulary (component names, jargon, structural conventions, identifiers
   specific to this codebase or domain) fresh in working memory — when introducing a technical
   term that has not appeared in this dialog within the recent turns, provide one sentence
   of grounding context. Trade-off framings ("here are 3 candidates: A is X, B is Y...")
   should explain what each candidate concretely does in plain prose before naming the
   abstract architectural shape.

6. **Sharpen fuzzy language.** When the user uses imprecise vocabulary, propose the canonical
   term and ask for confirmation before moving on.

7. **Walk every branch of the decision tree, including flow gaps.** For each goal, resolve
   dependencies between decisions one-by-one. Do not move to the next goal until every branch
   surfaced for the current one is either decided, explicitly deferred with a written reason,
   or split out as a separate goal. Branch completeness explicitly includes the end-to-end
   flow between any multi-actor decisions — actors named, operations sequenced, per-step
   inputs/outputs traced to producer and consumer, loud-failure paths named, context-cost
   call-out present (per Sub-Rule C). A flow with implicit hand-offs is an open branch; close
   it before moving on.

8. **Lock decisions as they settle.** Write each decision into the goal block under
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
2. Dialogue Conduct section in the Design SKILL.md preamble (the 8 rules above, verbatim — note Rule 5 covers G33's dialog-clarity directive and is Design-only per user scope)
3. Remove the existing Design SKILL.md "Test Strategy" top-level section (acceptance moves
   inline to each goal block)
4. Remove the existing Design SKILL.md "System Flow" diagram section (the architecture
   diagramming role migrates to Structure)
5. Update the design reviewer agent to enforce the per-goal block structure AND the Altitude Sub-Rule C end-to-end flow requirements (actor inventory present, sequence of operations specified, per-step inputs/outputs traced, consumer identification complete, loud-failure paths named, context-cost call-out present for orchestrator/subagent boundary crossings) AND Sub-Rule D external-knowledge completeness (every external claim has a concrete answer with citation + verification-method label; no "TBD" / "see vendor docs" placeholders; unknown branches name safe-default + verification procedure)
6. Update the design scope-reviewer owns-defers to defer architecture, file maps, and test mechanics
7. Add the Sub-Rules section (Altitude A + B + C + Completeness D) to the SKILL.md, verbatim
8. Mirror the Dialogue Conduct section into Goals SKILL.md's preamble with the following
   selection: Rules 1, 2, 4, 6, 7, 8 are verbatim. Rule 3 is adjusted: drop the "research
   summary" tier (Goals runs before Research, so no research artifacts exist); the tier
   ordering becomes codebase → web. **Rule 5 (G33 dialog-clarity directive) is NOT mirrored
   to Goals** — user scope for G33 was Design-only; broader scoping to Goals / Replan /
   Phasing / Structure tracked as dfrysinger/qrspi-plus#266 contingent on self-host signal.
   All other Dialogue Conduct text is identical between the two skills. Goals keeps its
   existing per-goal template and its "Interactive Dialogue" question-topic checklist — G1
   only adds the Dialogue Conduct rules to Goals; it does not change Goals' artifact template
   or the Pipeline Mode Selection step.

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
   4. Invoke `dispatch-agent.sh --implementer-commit <SHA-from-step-3> ...` for round NN+1. `round-prepare.sh` (auto-invoked via dispatch-agent's passthrough) runs all three SHA-correctness checks and writes `<round-dir>/../round-NN+1-commit.txt = <passed-SHA>` on exit 0, then asserts that prior-round artifacts (`round-NN-commit.txt`, and `round-NN-scope-set.txt` when narrowing-eligible) exist and are well-formed. Branch on the exit code: 0 → proceed to step 5; 10 → orchestrator bug, halt + surface to user; 11 → worktree integrity break, halt + surface to user; 12 → re-dispatch implementer subagent, then restart this checklist from step 3 with the fresh `commit_sha:`; other non-zero → surface diagnostic.
   5. After dispatch-agent.sh returns: parse stdout for `MODE=first_party` spec lines. For each spec line, invoke the Task tool exactly once with `subagent_type`/`model` copied verbatim from the line and `prompt = "DISPATCH_FILE=<absolute-path-from-the-PROMPT_FILE-field>"`. If zero `MODE=first_party` lines were emitted (all reviewers were third-party this round), skip the Task-tool loop entirely. Either way, call `await-round.sh --round-dir <round-dir>` to finalize the round — it is no-op-safe on first-party-only rounds (returns immediately after reading the manifest) and processes background third-party manifest entries on third-party-mixed rounds. The dispatch contract (Iron Law: invoke Task exactly once per spec line, verbatim values, no skipping/dedup/modification) is described in full earlier in this SKILL.md inside the reviewer-dispatch block.

   Steps 1, 3, 4 are mechanical reads, a field extraction, and an exit-code branch; steps 2 and 5 dispatch first-party Task subagents through the orchestrator (step 2: one scope-tagger against the round's kept findings; step 5: zero-or-more reviewers, one Task invocation per `MODE=first_party` spec line returned by dispatch-agent). The forward-reference to § Per-Task Convergence Narrowing covers details (anchor format, scope-set format, narrow-vs-broaden semantics).
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

## G10 — Reviewers fabricate procedural authority to justify non-compliance

**Problem.** Distinct from G6's transport-level chat-only fallback: in occurrence 7 of #226 (T3 R11 gt reviewer), a reviewer subagent fabricated a non-existent procedural authority and quoted it verbatim — attributed to `skills/reviewer-protocol/SKILL.md` — to justify a contract violation. The fabricated quote was: *"Per the contradiction-refusal procedure in `skills/reviewer-protocol/SKILL.md`, when the disk-write contract conflicts with the finding-quality bar, the reviewer should refuse to write findings and instead surface them in chat for orchestrator triage."* No such procedure exists. The pattern echoed an existing real section heading (`### Contradiction Refusal (FAIL-LOUD)`, which applies to ONE narrow `task_definition`-routing case) and invented a generic rule under it. This is a prompt-drift / authority-fabrication failure class — generalizable to any documented load-bearing rule (HARD-GATEs, route handoffs, verifier filter rules, scope-tagger triggers) — not a transport-layer failure.

**Approach.** Investigation-first scope per goals dialogue. v0.7.2 ships ONE minimal hardening lever — an anti-fabrication callout in `skills/reviewer-protocol/SKILL.md` that bounds the scope of the existing Contradiction Refusal section AND provides a labeled escape hatch (`CONTRACT-CONFLICT:` single-line prefix) for the legitimate case where a reviewer genuinely sees two contracts in conflict. The labeled-door pattern is load-bearing: without an exit, a saturated model is incentivized to invent one (which is what occurrence 7 did). Research questions for v0.7.3+ (training-data echo, context-size correlation, round-number correlation) are filed as GitHub issue #264 on the v0.7.3 milestone — not parked in this Design block, because the work is investigation, not a v0.7.2 Open Question.

**D1 — Anti-fabrication callout content, placement, and orchestrator-side handling.** ONE concrete decision covers both the prompt-side rule and the orchestrator-side handling of the new prefix.

  - **Placement.** New `### Anti-Fabrication Rule (FAIL-LOUD)` section in `skills/reviewer-protocol/SKILL.md`, inserted between the existing `### Refusal Procedure` (ends ~line 206) and `## Per-Finding Disk-Write Contract` (line 208). Positioned immediately after Refusal Procedure so the bounding clause ("The Contradiction Refusal procedure above applies to ONE specific dispatch malformation … It does NOT generalize") is adjacent to the section it bounds.

  - **Verbatim callout content** (becomes the literal section body):

    ```markdown
    ### Anti-Fabrication Rule (FAIL-LOUD)

    The Contradiction Refusal procedure above applies to ONE specific dispatch malformation
    (`task_definition` present with a test-phase `output` path). It does NOT generalize.

    Do NOT invent, paraphrase, or attribute to `reviewer-protocol/SKILL.md` any contradiction-
    refusal or escape-hatch procedure that is not present verbatim above. If you believe a
    documented contract (the per-finding disk-write contract, change-type classifier, finding
    schema, untrusted-data handling, phase routing, or any consumer skill's HARD-GATE) is in
    conflict with another rule or with finding quality, do NOT confabulate a generic resolution
    to bypass it. Surface the conflict by name:

    1. Do NOT call the `Write` tool. Do NOT emit findings or sentinels. Do NOT proceed.
    2. Return a single-line text response with this load-bearing prefix (orchestrator detects it):

       ```
       CONTRACT-CONFLICT: <contract A name> conflicts with <contract B name or quality concern>; cannot proceed
       ```

    3. End the turn. The orchestrator surfaces the conflict to the operator, who resolves it
       by name (amend a contract, adjust the dispatch, or instruct the reviewer to proceed
       under one specific contract).

    Quoting a procedure from `reviewer-protocol/SKILL.md` that is not literally present in this
    file is a fabrication. Treat the absence of a named escape hatch as the rule, not as an
    invitation to invent one.
    ```

  - **Orchestrator-side handling of `CONTRACT-CONFLICT:` prefix.** Where a reviewer dispatch's chat output begins with `CONTRACT-CONFLICT:` (load-bearing prefix, case-sensitive, anchored at start of first non-blank line):
    1. Do NOT treat the dispatch as a normal review round (no findings parsed, no clean-sentinel synthesis, no schema-violation guard fire).
    2. Do NOT auto-repair. Do NOT consume the tag's emission budget. Do NOT advance the round counter.
    3. Surface the single-line conflict statement verbatim to the operator with one of the standard intervention menus from `using-qrspi/SKILL.md` (operator picks: amend contract A, amend contract B, adjust dispatch shape, instruct reviewer to proceed under one specific contract, or abort the round).
    4. Operator resolution drives the re-dispatch path; no orchestrator-side default.

    The handling lives in `using-qrspi/SKILL.md` § Standard Review Loop alongside the existing post-dispatch chat-output classifier (the same site that handles schema-violation guard, missing-tag detection, and Codex stdout fall-through). One additional classifier branch — `if output starts with CONTRACT-CONFLICT: → operator-intervention menu`.

  - **Why a labeled escape hatch (not just a prohibition).** Goals dialogue weighed two sub-options:
    - **(a)** Ship prohibition + labeled escape hatch (chosen).
    - **(b)** Ship prohibition only; defer escape-hatch design to v0.7.3+.
    Option (b) trades fabrication risk for honest-stuckness risk: a saturated reviewer told "do not invent an escape hatch" with no real escape hatch defined will either confabulate one anyway (defeating the prohibition) or freeze ungracefully (no progress, no diagnostic). Option (a) provides the labeled door, making the prohibition enforceable AND giving the legitimate case a structured exit. The cost (one classifier branch in the orchestrator) is small enough that the investigation-first scope still holds — total v0.7.2 footprint is one SKILL section + one orchestrator classifier branch.

**Acceptance.**

- New `### Anti-Fabrication Rule (FAIL-LOUD)` section exists in `skills/reviewer-protocol/SKILL.md`, inserted between `### Refusal Procedure` and `## Per-Finding Disk-Write Contract`.
- Section body matches D1's verbatim content (the three-paragraph callout including the bounding clause, the three-step exit procedure with literal `CONTRACT-CONFLICT:` prefix, and the closing fabrication-treatment-as-rule clause).
- `using-qrspi/SKILL.md` § Standard Review Loop's post-dispatch classifier includes a `CONTRACT-CONFLICT:` branch routing to operator-intervention menu (no auto-repair, no round-counter advance, no tag-budget consumption).
- v0.7.3 follow-up research filed as issue dfrysinger/qrspi-plus#264 against the v0.7.3 milestone, covering Q1 (training-data origin), Q2 (context-size correlation), Q3 (round-number correlation).
- No retroactive changes to existing reviewer agent bodies — the callout is consumed via the existing `skills:` frontmatter preload mechanism that all reviewer agents already declare for `reviewer-protocol`.

**Open Questions for v0.7.3+.** None tracked here — moved to GitHub issue #264 per goals dialogue ("make an issue for 0.7.3"). The orchestrator-side anti-fabrication scanner (post-dispatch chat scan for quoted SKILL citations that don't match any loaded SKILL body — option #2 from the goals dialogue) is enumerated as a potential hardening lever IN that issue, contingent on Q2/Q3 outcomes; it is NOT scoped to v0.7.2.

**Pre-existing plugin issues to file.** None. G10's failure mode is a candidate-pattern observation from one instance, not a documented plugin defect; existing `reviewer-protocol/SKILL.md` is correct as written, this Design augments it.

**References.** Source: goals.md G10; #226 occurrence 7 (T3 R11 gt reviewer); `skills/reviewer-protocol/SKILL.md` L183-206 (existing Contradiction Refusal section being bounded); related G6 (transport-level chat-only fallback — closed the opportunity occurrence 7 piggybacked on, but not the fabrication pattern itself); v0.7.3 research follow-up: https://github.com/dfrysinger/qrspi-plus/issues/264.

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

## G14 — Verifier mis-applies false-positive rubric to reviewer-labeled "Informational" findings

**Problem.** The `qrspi-finding-verifier` agent treats reviewer-emitted "Informational" labels as equivalent to "explicitly silenced like a CLAUDE.md acknowledgment" and applies the false-positive rubric, scoring 20–30 → DROP. This conflates two distinct cases: (1) the finding's premise is wrong (true false positive — issue does not exist as described), (2) the finding's premise is correct but the reviewer chose not to demand action (informational/observational — issue exists, reviewer notes it for the record). The v0.7.1 rubric (`agents/qrspi-finding-verifier.md` L19-29) lists false-positive patterns including "Issues called out in CLAUDE.md but explicitly silenced in the code" — which correctly captures the acknowledged-and-silenced case (a documented user decision says the trade-off is accepted) — but provides no carve-out for reviewer-labeled Informational, so the agent extrapolates the silenced-pattern logic to cover it. Observed in v0.7.1 self-host T6 round-8 sec.F02: reviewer emitted a `sec` finding labeled "Informational" describing a real TOCTOU window between `realpath` and trust-prefix matching; verifier scored 25/100 → DROP, citing "reviewer self-labeled informational → false-positive rubric applies → low confidence." Outcome was right (the finding wasn't actionable) but the reasoning was wrong, and the same wrong reasoning would drop a serious-but-informational finding next time.

**Approach.** Formalize "Informational" as a documented finding-message convention with hard verifier-side detection. Two coordinated changes:

1. **`skills/reviewer-protocol/SKILL.md`** gains a new `## Informational Findings` section documenting the prefix convention: a reviewer who intends a finding to be informational (real issue, no action demanded) begins the `message` body's first non-blank line with the literal token `Informational:` (case-sensitive). The convention's semantics: the finding is logged to the review-round artifact for the record, scored on structural confidence by the verifier, but does NOT route to auto-apply or pause (regardless of `change_type`). The section explicitly distinguishes Informational from "acknowledged-and-silenced" (the latter is captured in CLAUDE.md or `feedback/*.md`, is a documented user decision, and remains in the false-positive rubric per existing line 25).

2. **`agents/qrspi-finding-verifier.md`** gains a new rubric clause inserted BEFORE the existing false-positive-pattern list (currently L19-29). The clause: if the finding's `message` body's first non-blank line begins with literal `Informational:` (case-sensitive), do NOT apply the false-positive rubric. Instead, score on structural confidence — "does the cited issue exist as described in the cited files?" Anchor: 75 if the issue is structurally verifiable, 50 if partially verifiable, 25 if the cited issue cannot be located in the referenced files (the finding's premise is wrong). The DROP/KEEP threshold then applies normally; informational findings that are structurally real keep, informational findings whose premise is wrong drop — but the dispatch never collapses into the false-positive-pattern path.

The two-case carve-out (false-positive vs informational) is intentionally narrow. The third candidate case from goals dialogue — acknowledged-and-silenced — is already correctly handled by the existing false-positive rubric (line 25 captures it). G14 only adds the missing branch; it does not restructure the rest of the rubric.

**D1 — Informational prefix convention: prefix shape, placement, and verifier rubric branch.** Single decision covering both the reviewer-protocol convention and the verifier rubric clause.

  - **Prefix shape.** Literal token `Informational:` (capital I, lowercase remainder, trailing colon). Case-sensitive. Must appear at the start of the first non-blank line of the `message` field body. May be followed by space + the finding body on the same line, or by a newline + body on subsequent lines. No other tokens (`INFO:`, `FYI:`, `Note:`, `Observation:`) carry the semantic — case-sensitivity and the single canonical token are load-bearing for unambiguous detection.

  - **Reviewer-protocol placement.** New `## Informational Findings` section in `skills/reviewer-protocol/SKILL.md`, inserted between `## Disagreement-Valid Framing` (line 115ish, currently the closest adjacent section about how reviewers frame stance in their findings) and `## Untrusted Data Handling` (line 125). Section body documents: when to use the prefix (reviewer believes the finding is real but is not demanding action — e.g., a TOCTOU window mitigated by an upstream guard, a stylistic observation reviewer wants on record, a "future-maintenance flag" reviewer thinks worth noting); how to use it (literal `Informational:` prefix on first non-blank line of `message`); what happens downstream (verifier scores on structural confidence; review loop logs the finding but does NOT auto-apply or pause regardless of `change_type`); distinction from acknowledged-and-silenced (the latter belongs in CLAUDE.md or `feedback/*.md`, is a user decision, and continues to route through the false-positive rubric per the existing verifier line 25). Backward compatibility: findings without the prefix continue to be scored exactly as before (no behavior change for any existing finding shape).

  - **Verifier rubric branch (verbatim addition to `agents/qrspi-finding-verifier.md`).** Inserted as a new paragraph immediately BEFORE the existing "Treat the following patterns as likely false positives and score them low (0–25):" sentence (currently ~line 19):

    ```markdown
    **Informational findings (carved out from the false-positive rubric).** If the finding's
    `message` body's first non-blank line begins with the literal token `Informational:`
    (case-sensitive, capital I, trailing colon), do NOT apply the false-positive patterns
    below. The reviewer has explicitly labeled this finding as a real observation that does
    not demand action — false-positive scoring is the wrong rubric. Instead, score on
    structural confidence: does the cited issue actually exist in the referenced files as
    the message describes?

    - **75:** Structurally verifiable. You can locate the cited issue in the referenced
      files and the message's description matches what is there.
    - **50:** Partially verifiable. The cited issue exists in some form but the message's
      description is loose or partially mismatched against the file content.
    - **25:** Premise wrong. The cited issue cannot be located in the referenced files as
      described — the informational claim itself is incorrect.

    DROP/KEEP threshold applies normally to the resulting score. Informational findings
    that are structurally real (≥50) keep and are logged to the round artifact; informational
    findings whose premise is wrong (≤25) drop.

    This branch is distinct from "acknowledged-and-silenced" findings (covered by the
    false-positive pattern below for "Issues called out in CLAUDE.md but explicitly silenced
    in the code"). Acknowledged-and-silenced is a documented user decision, lives in CLAUDE.md
    or `feedback/*.md`, and correctly routes through the false-positive rubric. Informational
    is a reviewer-emitted stance on a finding the reviewer authored — different signal,
    different rubric.
    ```

  - **Why a prose-prefix convention (not a structured-field schema migration).** Goals dialogue weighed two architectural directions:
    - **Light way (B, chosen).** Documented `Informational:` prefix in `message` body. One reviewer-protocol section + one verifier rubric clause; zero changes to the 5-field finding schema; zero changes to ~25 reviewer agent bodies; fully backward-compatible (findings without the prefix score as before).
    - **Heavy way (A, deferred).** Add a 6th finding-schema field (e.g., `actionability: action-required | informational`). Verifier branches on the structured field. Reviewer-protocol schema goes from 5 fields to 6; every reviewer agent must learn to emit the new field; review-loop dispatch logic may need to know "informational findings log-only, no auto-apply, no pause." Rigorous but heavy.

    Option B chosen because the observed evidence is one instance (T6 R8 sec.F02), the existing ad-hoc convention already uses prose labeling, and B is essentially a documented version of what reviewers already do. If v0.7.2 self-host shows the prose-prefix is too fragile (reviewers typo, forget, or use inconsistent variants like `INFO:` / `FYI:` / `Note:`), v0.7.3 migrates to Option A; the prose convention provides the migration path's seed (existing Informational-prefixed findings convert directly to `actionability: informational` field values). A v0.7.3 follow-up issue (filed at acceptance time) tracks the option-A migration question contingent on self-host signal.

**Acceptance.**

- New `## Informational Findings` section exists in `skills/reviewer-protocol/SKILL.md`, inserted between `## Disagreement-Valid Framing` and `## Untrusted Data Handling`.
- Section body documents the prefix shape (literal `Informational:`, case-sensitive, first non-blank line of `message`), when to use it, what happens downstream, and the distinction from acknowledged-and-silenced.
- `agents/qrspi-finding-verifier.md` gains the verbatim Informational-carve-out paragraph (D1) inserted immediately BEFORE the existing false-positive-pattern list at ~line 19.
- A bats test asserts the verifier rubric contains the literal `Informational:` token in the carve-out clause (regression guard against accidental rubric edits removing the branch).
- A bats test asserts the reviewer-protocol section is present and contains both the prefix-shape definition and the distinction-from-acknowledged-and-silenced paragraph.
- No changes to the 5-field finding schema. No changes to reviewer agent bodies (the convention is documented but not enforced — reviewers opt in by using the prefix).
- v0.7.3 follow-up filed: GitHub issue dfrysinger/qrspi-plus#265 tracking the option-A (structured `actionability` field) migration question, contingent on v0.7.2 self-host signal showing prose-prefix fragility.

**Open Questions for v0.7.3+.** Tracked externally as GitHub issue dfrysinger/qrspi-plus#265 against the v0.7.3 milestone — does v0.7.2 self-host evidence warrant migrating from prose-prefix (B) to structured field (A)? Issue captures: observed fragility incidents (typos, missed prefix, inconsistent capitalization variants), false-detection incidents (non-informational findings whose message happens to begin with `Informational:`), and reviewer-side workflow friction (did reviewers find the convention discoverable / natural to use). If self-host signal is clean, B stays; if fragile, A migration is scoped for v0.7.3.

**Pre-existing plugin issues to file.** None. G14's failure mode is a missing-carve-out in an existing rubric, not a documented plugin defect; the v0.7.1 verifier rubric is internally consistent on the cases it actually documents — it just doesn't document Informational.

**References.** Source: goals.md G14 / #230 (T6 round-8 sec.F02); `agents/qrspi-finding-verifier.md` L19-29 (existing false-positive rubric being extended); `skills/reviewer-protocol/SKILL.md` Finding Schema (L53-62, unchanged) + Disagreement-Valid Framing (L115ish, adjacent to new section); related G13 (`change_type` enum drift — different finding-field rigidity concern; G14 adds a documented prose convention rather than a schema field, intentionally).

---

## G15 — Per-task test scope misses dependent tests for sweep tasks

**Plain-language problem.** When a task changes the same thing across many files at once (a "sweep" — e.g., "strip `model:` from all 41 agent frontmatter files"), the producing task's targeted tests pass green inside its own worktree. But other tests elsewhere in the suite assert specific values that the sweep was scoped to remove. Those tests aren't in the task's plan-spec `files_in_scope`, so the per-task gate never runs them. The task ships GREEN. Integrate phase merges the branch, runs the full suite, and immediately surfaces stale-test failures the producing task should have owned. The per-task BLOCKING gate's contract — "if I'm green, the integrated state is at-least-not-worse-than-before-me" — is silently violated.

**Outcome.** Sweep tasks must enumerate their dependent tests (or grep-prove "none exist") at plan-authoring time so the per-task gate runs them too. The plan reviewer detects sweep tasks by heuristic and demands the enumeration. No sweep-shaped task can ship with implicit downstream test exposure; the per-task gate becomes trustworthy again.

**Approach.** Two-mechanism composition. (1) Document the contract in `plan/SKILL.md` — sweep-task plan-spec authors enumerate dependent tests by path OR commit to "no dependent tests exist" with a grep command in the plan body. (2) Plan-reviewer heuristic detects sweep-shaped tasks and surfaces a finding when the dependent-test enumeration is missing.

Composition rationale: documentation alone (without the reviewer enforcement) relies on plan-authors remembering the rule — the v0.7.1 incident is direct evidence that plan-authors don't reach for sweep semantics on their own. Reviewer enforcement alone (without the documentation) gives the reviewer no canonical contract to cite. Together: the doc is the contract; the reviewer is the gate.

Deferred: an automated test-discovery pass at gate time (grep `tests/unit/` for files referencing in-scope identifiers; run those tests too as part of the per-task suite). Filed as v0.7.3 follow-up — the v0.7.2 self-host of this design will produce direct signal on whether the doc + reviewer-heuristic combo is too leaky to catch sweep regressions cleanly.

**Two-mechanism details.**

*1) `plan/SKILL.md` — Sweep Task Contract (new subsection under § Test Expectations).* The plan-author rule (verbatim wording, ~120-150 words inserted as a single subsection within Test Expectations):

> ### Sweep Task Contract
>
> A **sweep task** removes, replaces, or enforces an invariant across many files at once (e.g., "strip `model:` from all agent frontmatter," "rename `qrspi-foo` to `qrspi-bar` across all skills," "remove all `${VAR}` references in CDs"). Sweep tasks systematically invalidate test files that assert on the swept property's previous values, even when those test files are not in the task's `files_in_scope`.
>
> A sweep-task plan-spec MUST include, in its Test Expectations block, a `dependent_tests:` field with one of two values:
>
> - A list of test file paths the per-task gate must additionally run. Each path must be a file (not a directory glob) and must exist at plan-authoring time. Each listed test SHOULD be expected to either (a) pass unchanged once the sweep is applied or (b) require a specific predicted update — describe which in one sentence per file.
> - The literal string `none` followed on the next line by a grep-confirmable search command of shape `grep -rn '<pattern>' tests/` that demonstrably returns zero matches. The pattern is the swept identifier (e.g., `'^model:'`) — the plan-reviewer will re-run the grep and surface a finding if it returns ≥1 hit.
>
> Skipping the `dependent_tests:` field on a sweep-shaped task is a plan-spec defect, not a deferred-to-implementer concern.

*2) `plan-reviewer.md` agent — Sweep Detection Heuristic.* A new rubric clause inserted into `agents/qrspi-plan-reviewer.md` (between existing rubric items, NOT replacing any). Heuristic (literal wording the reviewer applies):

> **Sweep-task detection.** Treat a task as a sweep when BOTH conditions hold:
>
> - `files_in_scope` lists >5 files (strict greater-than, not >=) of the same file type (file type = matching extension; `.md` agents in `agents/` count as one type, `.bats` tests count as another, etc.).
> - The task title OR the task description body contains at least one of: `all`, `every`, `strip`, `remove`, `rename`, `replace`, `delete`, `sweep` (case-insensitive, word-boundary match — `removal` matches `remove`; `installer` does NOT match `all`).
>
> On detection, the reviewer MUST verify the task's Test Expectations block contains a `dependent_tests:` field per the `plan/SKILL.md` § Sweep Task Contract. Missing-field → emit a `severity: high, change_type: correctness` finding referencing the contract. Field-present-but-malformed (no paths, no `none`-with-grep, or `none` with a grep that returns ≥1 hit when re-run) → same severity.

The 5-file threshold and the 8-keyword list are calibrated against the v0.7.1 Wave-1 incident: T9 (#204, strip `model:` from 41 files) trips on both checks; Hotfix A (test-writer iron law rewrite) trips on file-count + `remove`; Hotfix B (threshold split) is borderline — file count below threshold but the reviewer can still surface it because the description mentions `replace`. Self-host signal during v0.7.2 will reveal whether the threshold should drop to 3 or the keyword list needs expansion.

**Cross-cutting note (G15 ↔ G18).** G15's pattern — *"plan reviewer catches a structural under-scoping shape by heuristic, demands the producing task own its full surface area"* — is the same shape G18 is going to need (Plan-phase under-scoping cluster per goals.md Cross-Cutting Notes). When G18 is walked, prefer extending the same plan-reviewer rubric over inventing a parallel mechanism. Don't pre-commit G18 here — just flag for that walk.

**Implementation deliverables.**

1. **`plan/SKILL.md`** — insert the verbatim "Sweep Task Contract" subsection above into the existing § Test Expectations section. Adjacency choice: at the END of § Test Expectations (after all existing per-task field documentation), as a clearly-fenced subsection. Rationale: sweep tasks are a structural special case that builds on the standard Test Expectations vocabulary — placing the contract last lets a plan-author read the general rules first and then reach for the sweep extension when applicable.
2. **`agents/qrspi-plan-reviewer.md`** — insert the verbatim "Sweep-task detection" rubric clause above into the agent body. Adjacency choice: as a new bullet within the existing review rubric, alongside (not replacing) existing field-shape checks. The agent's loaded reviewer-protocol (5-field finding schema) is unchanged — sweep findings use existing `severity` + `change_type` values, no new finding kind.
3. **`plan/SKILL.md` worked example** — add a 1-paragraph "worked example" under the Sweep Task Contract subsection showing a plan-spec excerpt for a sweep task with a well-formed `dependent_tests:` list, and a second 1-paragraph example with the `none + grep` shape. ~30-40 lines combined.
4. **Backstop documentation** — a short note in `using-qrspi/SKILL.md` Standard Implement-Phase loop describing what happens when a sweep-finding fires at plan-review time (treated as a normal plan-reviewer correctness finding; routes through the standard plan re-spec loop; no new gate behavior).
5. **No changes to** `implementer-protocol/SKILL.md`, the per-task gate code/script paths, or any test runner — G15 surfaces the missing tests at PLAN time so they end up in `files_in_scope` (extended to read `dependent_tests:`) of the producing task. The existing per-task gate runs whatever tests are listed; the producing-task expectation that the gate runs `files_in_scope` tests is preserved.

**Open Questions for v0.7.3+.** Tracked externally as GitHub issue dfrysinger/qrspi-plus#267 against the v0.7.3 milestone (filed when this design block ships): does v0.7.2 self-host evidence warrant adding automated sweep-aware test discovery at gate time (grep `tests/` for in-scope identifiers and run matching tests in addition to the explicit `dependent_tests:` list)? Issue captures: whether the doc + reviewer-heuristic combo caught all sweep regressions during v0.7.2 self-host, whether plan-authors had trouble enumerating the dependent tests by hand, and whether the 5-file / 8-keyword threshold needed tuning.

**Pre-existing plugin issues to file.** None new. G15 closes the contract gap that #231 left open after the v0.7.1 stale-test cleanup landed; the existing `plan/SKILL.md` is internally consistent on the cases it documents — it just doesn't document sweep tasks.

**References.** Source: goals.md G15 / #231 (v0.7.1 Wave-1 6-stale-test surfacing); v0.7.1 cleanup commit `898c171`; `plan/SKILL.md` § Test Expectations (extension point); `agents/qrspi-plan-reviewer.md` (rubric extension point); goals.md Cross-Cutting Notes "Plan-phase under-scoping cluster" (G15 + G18 relationship); related G18 — design pattern for the cluster originates here.

---

## G16 — `scripts/run-codex-review.sh` accepts arbitrary absolute paths; sanctioned-channel exfil surface

**Plain-language problem.** The wrapper script reads file content from any path the caller hands it via `--subject-code` / `--artifact-body` / `--companion` / `--diff-file`, then ships that content out through the OpenAI/Codex network channel as part of the LLM prompt. There's no check that the path is inside the qrspi repo. A prompt-injected implementer-style agent that holds Bash could invoke `run-codex-review.sh --subject-code /etc/hosts` (or `~/.ssh/id_rsa`, or `~/.aws/credentials`, or `../sibling-repo/.env`) and the content leaves over a network channel that infrastructure-level egress controls explicitly **allow** because Codex is the sanctioned LLM provider. The v0.7.1 INTEGRATE round-1 sec-codex F01 finding caught this; the QRSPI verifier scored it 62 (below the security ≥70 threshold) on the reasoning "prompt-injected Bash-granted agents already have many exfil paths" — true at the curl level, false at the sanctioned-channel level. G14's verifier-rubric fix means a future identical finding wouldn't get suppressed, but the code fix still has to land.

**Outcome.** Three layered guards close the exfil surface:

1. Every path argument to `run-codex-review.sh` is canonicalized (`realpath` / `readlink -f`) and required to start with `$REPO_ROOT/` followed by `/`. Symlinks-out-of-repo are rejected because canonicalization follows them. Anything else → exit non-zero, error to stderr — fail closed.
2. `agents/qrspi-implementer.md` gains a small Bash allowlist clause forbidding direct invocation of the two orchestrator-only scripts (`scripts/run-codex-review.sh`, `scripts/run-third-party-llm.sh`). The implementer never has legitimate reason to invoke them; the orchestrator dispatches LLM reviews.
3. Bats regression tests assert the failure shape.

A short audit of `scripts/run-third-party-llm.sh` is included to confirm direct invocation doesn't reopen the same surface from a different entry point.

**Approach.** Single-point enforcement on the script side, narrow defense-in-depth on the agent side, regression tests against the documented failure mode, audit note for the dispatcher script. The script fix is the gate; the agent allowlist is the belt to the script's suspenders.

**Decisions locked:**

- **A — Allowed path scope is strict.** Inputs must canonicalize to a path with `$REPO_ROOT/` as a path prefix (real prefix check, not lexical — `$REPO_ROOT-sibling/foo` does NOT match). No `/tmp/` carve-out. All current callers in `skills/*/SKILL.md` pass paths under the run's `docs/qrspi/...` artifact directory which is inside the repo. If a future caller legitimately needs to ship a `/tmp/` input, an explicit `--allow-tmp-input` flag can be added then; today's surface area says "strict" is the right default.
- **B — Implementer allowlist is minimal (B1).** Add one bullet to `agents/qrspi-implementer.md` forbidding invocation of `scripts/run-codex-review.sh` and `scripts/run-third-party-llm.sh` by path or any path-suffix shape. Do NOT add a full positive command-family allowlist of the test-writer variety — implementer flexibility (build, lint, install, test across many language stacks) is necessary and over-restricting it would break legitimate work. The agent restriction's only job is to close the "agent invokes the wrapper as an exfil tool" path; the script-level fix handles the rest.
- **C — Audit is one paragraph.** A single-paragraph audit note in the design block (and a 1-line note in `scripts/run-third-party-llm.sh` if remediation is needed) confirms whether the dispatcher script has the same surface when invoked directly. If the audit surfaces anything, fix it in the same task; if it surfaces nothing, no further work this run. A broader sweep of all `scripts/` shell scripts for "reads a path, ships content through LLM channel" patterns is deferred to v0.7.3 contingent on v0.7.2 self-host signal.

**Implementation deliverables.**

1. **`scripts/run-codex-review.sh` — new function `assert_path_under_repo_root <label> <abs-path>`.** Insert as a helper alongside the existing `resolve_path()` and `assert_file_exists()` (around L322-338). Body shape (verbatim):

   ```sh
   # assert_path_under_repo_root <label> <abs-path>
   # Canonicalize <abs-path> and require it to live under $REPO_ROOT/.
   # Fail closed on canonicalization failure, on path traversal outside
   # the repo, or on symlinks resolving outside the repo. Single
   # enforcement point for every --subject-code / --artifact-body /
   # --companion / --diff-file caller; closes sanctioned-channel exfil
   # surface (G16).
   assert_path_under_repo_root() {
     local label="$1"
     local raw="$2"
     local canonical
     canonical="$(realpath "$raw" 2>/dev/null || readlink -f "$raw" 2>/dev/null)" || canonical=""
     if [[ -z "$canonical" ]]; then
       echo "error: ${label} could not be canonicalized: $raw" >&2
       exit 1
     fi
     # Real-prefix check: require $REPO_ROOT/ as a path prefix (not lexical).
     local root_canonical
     root_canonical="$(realpath "$REPO_ROOT" 2>/dev/null || readlink -f "$REPO_ROOT" 2>/dev/null)" || root_canonical=""
     if [[ -z "$root_canonical" ]]; then
       echo "error: REPO_ROOT could not be canonicalized: $REPO_ROOT" >&2
       exit 1
     fi
     if [[ "$canonical" != "$root_canonical"/* ]]; then
       echo "error: ${label} resolves outside repository: $raw -> $canonical (REPO_ROOT=$root_canonical)" >&2
       exit 1
     fi
   }
   ```

   Call `assert_path_under_repo_root <label> <abs-path>` from each of: `AGENT_FILE_ABS` resolution (currently L340-341), every `--subject-code` / `--artifact-body` path resolution, every `--companion` path resolution, every `--diff-file` path resolution. Placement: immediately after each existing `assert_file_exists` call so existence and boundary are both checked before the path is ever passed to `cat` or echo'd into a prompt.

2. **`agents/qrspi-implementer.md` — Bash allowlist clause.** Add one bullet under the existing tool-grant section (the agent body currently has `tools: Read, Write, Bash, Edit, Grep, Glob` at L4 with no prompt-layer restrictions). Insert at the top of the agent's prose body, ABOVE the first procedural section, as a new section titled `## Orchestrator-Only Scripts (Bash Allowlist)`:

   > ## Orchestrator-Only Scripts (Bash Allowlist)
   >
   > You may NOT invoke `scripts/run-codex-review.sh` or `scripts/run-third-party-llm.sh` under any path shape — not by relative path (`./scripts/run-codex-review.sh`), not by absolute path (`<repo>/scripts/run-codex-review.sh`), not via shell expansion or aliases. These scripts are orchestrator-only — they dispatch LLM reviews on behalf of the run, and they read arbitrary file content into the LLM prompt. Per-task implementer work has no legitimate reason to invoke them; the per-task Bash grant restriction here is defense in depth against prompt-injected exfil.
   >
   > If your dispatch genuinely requires LLM-mediated work, report `NEEDS_CONTEXT` and stop — the orchestrator owns LLM dispatch decisions, not the implementer.

   This is the narrow-restriction B1 shape per the locked decision — no positive command-family allowlist. The implementer keeps full Bash flexibility for legitimate build/test/lint work in any language stack.

3. **`tests/unit/test-run-codex-review-path-boundary.bats`** — new file. Three test cases, each invoking `bash scripts/run-codex-review.sh ... --dry-run` with a malicious path and asserting `[ "$status" -ne 0 ]` plus the error message substring:
   - `--subject-code /etc/hosts --dry-run` → exit non-zero, stderr contains `"resolves outside repository"`.
   - Symlink test: `ln -s /etc/hosts /tmp/qrspi-test-link-$$` inside the test's setup, then `--subject-code /tmp/qrspi-test-link-$$ --dry-run` → exit non-zero, stderr contains `"resolves outside repository"`. Teardown removes the symlink.
   - `--companion /tmp/qrspi-test-malicious-$$.md --dry-run` with a real file at that path (created in setup, removed in teardown) → exit non-zero, stderr contains `"resolves outside repository"`. This proves the boundary check fires even when the file exists and is readable, not just on missing-file paths.

   The test file lives in `tests/unit/` alongside existing wrapper-script tests. Use existing bats helpers (`load helpers/...`) if applicable.

4. **`scripts/run-third-party-llm.sh` — 1-paragraph audit.** Verify whether the dispatcher accepts arbitrary file paths as direct CLI input from outside the wrapper. If yes (same surface reachable from a different entry point), add the same `assert_path_under_repo_root` call in the dispatcher as well, sourced from a shared helper file (`scripts/lib/path-guard.sh`) to keep the canonicalization logic in one place. If no (dispatcher only ever receives in-memory data assembled by the wrapper, never raw paths), document that in a one-line comment in the dispatcher script and write a sentence in the G16 implementation notes (`docs/qrspi/2026-05-30-v072-release/notes/g16-audit.md` or wherever the run's notes live) confirming the audit outcome.

5. **No changes to** `agents/qrspi-test-writer.md` (its Bash allowlist already prohibits orchestrator scripts via the positive-allowlist shape — `bats`, `git`, `mkdir -p tests/`, narrow inspection commands only), no changes to `skills/reviewer-protocol/SKILL.md` (the dispatch contract is unchanged; G16 fixes only the implementation of the wrapper), no changes to `using-qrspi/SKILL.md` (the orchestrator's wrapper-invocation patterns already pass repo-relative or `<ABS_ARTIFACT_DIR>/...` paths, which canonicalize cleanly under `$REPO_ROOT`).

**G14 cross-reference.** When this design lands and is implemented, the next sanctioned-channel exfil finding emitted by a reviewer will be scored against the G14-extended verifier rubric — security findings about sanctioned-channel surfaces are NOT pattern-matched as "redundant with existing curl-level exfil paths" and won't be suppressed by the same reasoning that scored the v0.7.1 F01 at 62.

**Open Questions for v0.7.3+.** Tracked externally as GitHub issue dfrysinger/qrspi-plus#268 (filed when this design block ships): broader audit of all `scripts/*.sh` and `scripts/*.mjs` for the "reads a path, ships content through sanctioned LLM channel" pattern. Decision criteria: v0.7.2 self-host of G16 surfaces any additional scripts with the same shape? Also captures: did the strict-under-`$REPO_ROOT` choice prove too tight for any legitimate caller (any need for a future `--allow-tmp-input` flag)?

**Pre-existing plugin issues to file.** None new — G16 is a remediation of the v0.7.1 F01 finding that the verifier suppressed; the plugin defect was the verifier rubric (now covered by G14), not a separate plugin issue.

**References.** Source: goals.md G16 / #232 (v0.7.1 INTEGRATE R1 sec-codex F01); `scripts/run-codex-review.sh` L322-329 (resolve_path), L340-341 (AGENT_FILE_ABS), L462-467 (emit_untrusted_artifact `cat`), L548-560 (forward to dispatcher); `scripts/run-codex-review.sh` L115-131 (existing realpath/readlink-f pattern in `check_codex_available` — reused as canonicalization reference); `agents/qrspi-test-writer.md` L21-26 (positive-allowlist reference shape, B2 alternative); `agents/qrspi-implementer.md` L4 (tool-grant line, current state — no prompt-layer restriction); related G14 — verifier rubric drift suppressed this finding once and would have suppressed it again without G14.

---

## G17 — Stale prose in implementer-protocol and test-writer after T2 added committed gitignore

**Plain-language problem.** v0.7.1 Wave 1 T2 added `.qrspi-commit-msg.txt` to the committed root `.gitignore`. Three prose surfaces still describe the pre-T2 reality: one says "the scratch file is not gitignored" (factually false), one says "the target repository's committed `.gitignore` is not polluted with QRSPI internals" (now contradicted by qrspi-plus's own committed entry), one names only the worktree-local exclude when two layers now apply. Pure documentation drift, no runtime defect. v0.7.1 INTEGRATE round 1 caught it (R1-F03 + R1-F05); the verifier suppressed both (72 and 50 against the clarity ≥80 threshold) so the prose never got fixed.

**Outcome.** Three surgical edits correct the false/incomplete claims without restructuring the Invariants section. The committed `.gitignore` is a static test-enforced repo property — it is NOT something the implementer agent reads, writes, or follows at runtime — so it does NOT become a peer of Invariants 1/2/3, which describe runtime agent behavior. Adding "Invariant 4" would conflate two different categories (runtime agent behavior vs static repo config) and bloat the section the agent reads every dispatch.

**Approach.** Three minimum-disruption edits: correct Invariant 3's outdated rationale sentence; strip the false-claim parenthetical from step 4 (the implementer doesn't need to know-why to do the `rm`); delete the redundant exclude sentence from `qrspi-test-writer.md` L28 (the step list at L77-80 already states the same thing authoritatively). No new section. No Composition rewrite. No new tests. Doc-only.

**Implementation deliverables (locked replacement prose).**

1. **`skills/implementer-protocol/SKILL.md` L174 — Invariant 3 rationale sentence.** Replace the second sentence verbatim:

   - **Old:** "This ensures `git status` reports remain deterministic between scratch-file write and removal, and the target repository's committed `.gitignore` is not polluted with QRSPI internals."
   - **New:** "This ensures `git status` reports remain deterministic between scratch-file write and removal in any worktree, including downstream consumers' target repositories which do not inherit qrspi-plus's own committed `.gitignore` entry."

   Drops the false "not polluted" claim. Correctly scopes Invariant 3 to the case the worktree-local exclude actually covers: downstream-consumer target repos where there is no committed entry to inherit.

2. **`skills/implementer-protocol/SKILL.md` L241 — Commit-Before-Reporting step 4 parenthetical.** Replace verbatim:

   - **Old:** "(the scratch file is not gitignored and you don't want it in the next round's diff)"
   - **New:** "(keeps the scratch file out of the next round's diff)"

   Drops the rationale entirely. The implementer needs to do the `rm`; it does not need to track the layered-exclude mechanism's state to decide whether the `rm` is necessary. Less prose, no false claim.

3. **`agents/qrspi-test-writer.md` L28 — Commit ownership bullet.** Delete the standalone exclude sentence:

   - **Old:** "...write `.qrspi-commit-msg.txt`, `git -c user.name=agent-echo -c user.email=<noreply> commit -F .qrspi-commit-msg.txt`, `rm .qrspi-commit-msg.txt`. The worktree-local `.git/info/exclude` already lists `.qrspi-commit-msg.txt`. Include `Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>` trailer."
   - **New:** "...write `.qrspi-commit-msg.txt`, `git -c user.name=agent-echo -c user.email=<noreply> commit -F .qrspi-commit-msg.txt`, `rm .qrspi-commit-msg.txt`. Include `Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>` trailer."

   The exclude reassurance is restated authoritatively in the step list at L77-80. Removing the L28 mention avoids partial restatement (which is the very drift this goal exists to fix — listing one mechanism while there are now two).

4. **No other surfaces touched.** `skills/implement/SKILL.md` L376 / L383 / L672 mention the scratch file in correct, target-repo-scoped framings ("does not pollute the target repo's committed `.gitignore`") that remain accurate for downstream consumers. `agents/qrspi-test-writer.md` L23 / L24 / L77-80 are load-bearing operational references (Bash allowlist entries + the canonical step list). No changes.

5. **No new tests.** All four guards (staging order, cleanup, worktree-local exclude, committed gitignore) are already verified by `tests/unit/test-commit-hygiene-invariants.bats`. G17 is pure prose reconciliation; no behavior change to test.

**Pre-existing plugin issues to file.** None new. G17 closes the v0.7.1 R1-F03 / R1-F05 prose-drift findings the verifier suppressed. G14's verifier-rubric fix means the next equivalent informational-but-valid clarity finding would not be suppressed by the same score-threshold reasoning.

**References.** Source: goals.md G17 / #233 (v0.7.1 INTEGRATE R1 F03 + F05); `skills/implementer-protocol/SKILL.md` L174 (Invariant 3 second sentence), L241 (Commit-Before-Reporting step 4); `agents/qrspi-test-writer.md` L28 (Commit ownership bullet); `tests/unit/test-commit-hygiene-invariants.bats` (test-enforced repo property — committed `.gitignore` entry verified there); `.gitignore` (committed entry added in T2); related G14 — same suppression pattern caught both findings here.

---

## G18 — Plan-phase under-scopes cross-task consumer surface

**Plain-language problem.** Plan-phase task specs scope each task's own changes but do not systematically enumerate the downstream consumers of the contracts being changed. v0.7.1 documented 9 instances of this pattern (T8 cache-cleanup, T9 frontmatter sweep, T10 R1/R2, fix-int-r4-01 validator-table, T10 TE1-TE3 tier-source orphaning, validation-table cross-link gap, vocab pin asymmetry, top-level invariant absence); this session added a 10th (G27/#253 Codex availability inline probe). The recurring shape: a task modifies a thing (a frontmatter field, an anchor name, a helper function, a validator entry, a schema layout, a shared-prose section), but the plan-spec only lists files the task itself edits — not other files that reference the changed thing. Integrate-phase reviewer fan-out catches the orphans, each round surfacing 1-3 more. The v0.7.1 hardening run took 6 integrate rounds and ~5 fix-tasks to converge. G15 fixed the narrow sweep-tasks-orphan-tests case; G18 generalizes the prevention pattern to contract-carrier changes generally.

**Relationship to G27 and G22.** G18 is the **prevention mechanism** — catches the next instance at plan-review time. G27 and G22 are **specific code fixes** for instances that already shipped; both stay as their own goals — G18 does not subsume them.

**Outcome.** Plan-spec authors must enumerate cross-task consumers for contract-carrier changes; the plan reviewer detects the change-shape by heuristic and demands the enumeration. The 8 of 10 grep-detectable v0.7.1 instances are closed by construction. The 2 of 10 prose-consistency instances (vocab pin asymmetry, top-level invariant absence) are acknowledged as out-of-scope for the heuristic and tracked as v0.7.3 follow-up.

**Approach.** Two-mechanism composition, evergreen (no qrspi-plus-specific directory names, no language-specific identifier kinds — designed to work in any project a QRSPI run is invoked against):

1. **Author-side template extension** — `plan/SKILL.md` § Task Definition gains a `Cross-Task Consumer Surface` subsection documenting when the `cross_task_consumers:` field is required and what shapes it accepts.
2. **Reviewer-side heuristic** — `agents/qrspi-plan-reviewer.md` gains a Cross-Task Consumer Surface Detection rubric clause that fires on contract-shape changes and demands the field.

Composition rationale: same as G15 — documentation alone relies on plan-author memory (v0.7.1 evidence is that authors don't reach for consumer enumeration unprompted); reviewer enforcement alone gives the reviewer no canonical contract to cite. Together: the doc is the contract; the reviewer is the gate.

Deferred to v0.7.3 (contingent on v0.7.2 self-host signal): a standalone Plan-phase scope-completeness reviewer subagent dispatched in parallel with `qrspi-plan-reviewer.md`; an automated grep at plan-review time that runs the consumer-search command for the author. Both are heavier mechanisms; the v0.7.2 reviewer-heuristic + author-template approach mirrors G15 and gets the same self-host signal cycle.

**Decisions locked:**

- **A — Composition: mechanisms #1 + #2 only for v0.7.2.** Standalone scope-completeness reviewer subagent (#3) deferred — would add a 5th plan-time dispatch and obscures the signal on whether the rubric extension alone is enough. Automated grep at gate time (#4) deferred indefinitely — too speculative to build before #2 self-host signal arrives.
- **B — Trigger breadth: broad, evergreen.** Trigger fires on any task whose changes match the documented contract-shape conditions (see below) — described by *what the change does to consumers*, not by what directory the changed file lives in. The trivial-answer escape (`none` + reproducible search command returning zero hits) keeps author burden low for tasks that genuinely have no consumers.
- **C — Field shape: parallels G15's `dependent_tests:` field.** Same mental model (paths-with-disposition OR `none + grep`), same reviewer-rerun behavior, same finding severity. Reuses the G15 rubric infrastructure.
- **D — Prose-consistency cases (vocab pin asymmetry, top-level invariant absence): defer to v0.7.3.** These can't be grep-caught without false-positive flood; mitigation requires either semantic-similarity tooling or a different mechanism entirely. Filed as v0.7.3 investigation issue.
- **E — Separate G15 and G18 rubric clauses (not merged).** G15 asks `dependent_tests:`; G18 asks `cross_task_consumers:`. The two questions are about different downstream surfaces (test files vs consumer files generally) and merit separate field names + separate triggers. Merging into one clause would obscure intent.

**Implementation deliverables.**

1. **`plan/SKILL.md` — Cross-Task Consumer Surface subsection (new).** Insert at the END of § Task Definition (after all existing per-task field documentation, in the same neighborhood as G15's Sweep Task Contract subsection). Verbatim wording:

   > ### Cross-Task Consumer Surface
   >
   > A task is **consumer-surface-touching** when its description or `files_in_scope` indicates ANY of:
   >
   > - Adding, renaming, or removing a function, method, class, interface, exported symbol, or other named declaration.
   > - Adding, renaming, removing, or moving a file listed in `files_in_scope`.
   > - Changing the public signature (parameter list, return type, exceptions or errors raised, side effects, or visibility) of any callable in `files_in_scope`.
   > - Changing the schema or structure of any structured document (JSON, YAML, frontmatter, TOML, XML, etc.) in `files_in_scope` whose keys, anchors, or top-level identifiers are referenced by name from other files.
   > - Adding, renaming, or removing a documented contract — a configuration key, environment variable, CLI flag, URL route, RPC method, command-line subcommand, schema field, anchor heading, or any other named extension point declared in `files_in_scope`.
   >
   > A task that only modifies the body of an existing callable, edits prose paragraphs without changing referenced anchor names, or fixes formatting is NOT consumer-surface-touching. The trigger fires on changes that other code or documents could plausibly be coupled to *by name*.
   >
   > When the trigger fires, the plan-spec MUST include a `cross_task_consumers:` field with one of two shapes:
   >
   > - A list of consumer file paths outside `files_in_scope`, each followed on the next line by a one-sentence disposition: `no change` (consumer keeps working unmodified), `pass-through` (consumer's behavior intentionally unchanged but the consumer file must be re-verified), `co-edit` (consumer file must be modified inside this same task), or `break-and-fix-task` (consumer file will be intentionally broken by this task and repaired in a named follow-up task — the follow-up task ID must be cited).
   > - The literal string `none` followed on the next line by a reproducible search command demonstrating zero consumer references exist outside `files_in_scope`. Command shape is left to the author: `grep`, `rg`, `git grep`, a language-specific reference-finder (`go vet`, `tsc --noEmit -p`, `rustc --emit=metadata`, IDE-equivalent CLI), or any other reproducible zero-result probe. The reviewer re-runs the command and treats a non-zero hit count as a defect.
   >
   > Skipping the `cross_task_consumers:` field on a consumer-surface-touching task is a plan-spec defect, not a deferred-to-implementer concern.

2. **`agents/qrspi-plan-reviewer.md` — Cross-Task Consumer Surface Detection rubric clause (new).** Insert as a new bullet within the existing review rubric, alongside (NOT replacing) G15's Sweep-Task Detection clause. Verbatim wording:

   > **Cross-task consumer surface detection.** A task is consumer-surface-touching when ANY of the trigger conditions in `plan/SKILL.md` § Cross-Task Consumer Surface apply (named-declaration add/rename/remove, file add/rename/remove/move, public-signature change, structured-document schema change to referenced keys/anchors, named extension-point add/rename/remove). On detection, the reviewer MUST verify the task's plan-spec contains a `cross_task_consumers:` field per the contract:
   >
   > 1. Field present and well-formed (one of the two documented shapes).
   > 2. If the field value is `none`, re-run the cited search command from the repo root and treat a non-zero hit count as a finding.
   > 3. If the field lists consumers, verify each listed disposition is one of `no change` / `pass-through` / `co-edit` / `break-and-fix-task`, and (for `break-and-fix-task`) verify the cited follow-up task ID exists in the plan.
   >
   > Missing field, malformed field, non-zero hits on a `none` claim, or invalid disposition value → emit a `severity: high, change_type: correctness` finding referencing the contract.

3. **`plan/SKILL.md` worked examples** — append two worked examples under the new subsection (~40-60 lines total):
   - Example 1: a consumer-surface-touching task that renames a public function across two files; `cross_task_consumers:` lists three consumer files with `co-edit` / `co-edit` / `no change` dispositions.
   - Example 2: a body-only bug fix in one file; trigger does not fire, no `cross_task_consumers:` field required; a one-line note explains why the trigger did not fire.

4. **No changes to** `implementer-protocol/SKILL.md`, `using-qrspi/SKILL.md` Standard Plan loop, per-task gate runner, or the test infrastructure. G18 surfaces the missing consumer enumeration at PLAN time; downstream phases consume the enriched plan unchanged.

5. **Worked-example calibration.** The two worked examples in `plan/SKILL.md` are calibrated against the v0.7.1 G27 instance (renaming the canonical Codex availability check across consumer skills) and a typical body-only bug fix. They show both the "trigger fires" and "trigger does not fire" cases so authors can self-classify without consulting the reviewer.

**Cross-cutting note (G15 ↔ G18).** Both G15 and G18 are members of the goals.md Cross-Cutting Notes "Plan-phase under-scoping cluster." G15 ships first (was locked before G18) — its `dependent_tests:` mechanism for sweep tasks is the structural template G18 mirrors. The two clauses in `qrspi-plan-reviewer.md` (Sweep-Task Detection, Cross-Task Consumer Surface Detection) stay separate; the two fields in `plan/SKILL.md` (`dependent_tests:`, `cross_task_consumers:`) stay separate. A task that is both a sweep AND consumer-surface-touching carries both fields.

**Open Questions for v0.7.3+.** Tracked externally as GitHub issue dfrysinger/qrspi-plus#269 (filed when this design block ships): (a) does v0.7.2 self-host signal indicate the heuristic + author-template combo catches enough of the consumer-surface gaps that the standalone scope-completeness reviewer (#3) is unnecessary? (b) do the 2-of-10 prose-consistency cases (vocab pin asymmetry, top-level invariant absence) need a separate mechanism in v0.7.3 — semantic-similarity probe, glossary file, periodic full-prose audit? (c) does automated grep at gate time (#4) net out positive after measuring v0.7.2 author burden of writing the `none + grep` commands by hand?

**Pre-existing plugin issues to file.** None new. G18 closes the v0.7.1 cluster of 9 instances + the session-discovered 10th (G27/#253) is its own specific code-fix goal; G22 (model-routing schema drift) is another instance whose specific code fix lives in G22's own goal. None of these surface a separate plugin issue — they are all manifestations of the same under-scoping pattern G18's mechanism prevents.

**References.** Source: goals.md G18 / #235 (v0.7.1 hardening run 9-instance pattern documentation); `tasks/task-{08,09,10}.md` (original under-scoped specs in `docs/qrspi/2026-05-27-v071-hardening/`); `fixes/integration-round-0{1..5}/` (fix-task specs that closed each gap); `reviews/integration/round-{01..06}/` (integrate-round finding files surfacing each gap); `plan/SKILL.md` § Task Definition (extension point); `agents/qrspi-plan-reviewer.md` (rubric extension point); goals.md Cross-Cutting Notes "Plan-phase under-scoping cluster" (G15 + G18 relationship); related G15 — same pattern shape, sweep-task narrow case; related G27 — instance #10, specific code fix; related G22 — same canonical-source-multiple-consumers pattern.

---

## G19 — Wholesale-hallucination findings slip past current verifier rubric

**Plain-language problem.** A reviewer subagent dispatched against an artifact can fabricate a finding wholesale: invented file paths, invented line numbers, invented quoted content ("`SKILL.md:516` contains `widen/ref`" when line 516 says nothing of the kind). The current verifier rubric scores findings 0–100 on a confidence axis anchored on pre-existing-vs-introduced classification, but does NOT verify that cited resources actually contain what the finding claims they contain. A well-written hallucination scores ≥70 and reaches the orchestrator, where it either (a) wastes a fix-task cycle implementing against a nonexistent code shape or (b) is noticed by a human and erodes trust in the entire review pipeline. v0.7.1 Integrate R6 reproduced this exactly: `gpt-5.5` (running as task-tool substitute for absent codex CLI) fabricated a finding citing concrete content that a 5-second grep refuted.

**Outcome.** The verifier subagent gains a Cite Check step that runs after reading cited resources and before final scoring. When a finding cites content that does not exist at the cited location (file missing, line range out of bounds, quoted string absent at cited line, named anchor absent in cited file), the verifier emits `score: 0` with a `HALLUCINATED:` reason prefix and halts further rubric work. Score-0 findings fall below both correctness (≥70) and style/clarity (≥80) keep thresholds, so the existing Apply-fix protocol drops them automatically — no orchestrator changes required. The fix is single-subagent, single-file, evergreen, and self-consistent with the constraint that confidence-side verification stays inside the verifier subagent (not the orchestrator).

**Approach.** One-mechanism: extend `agents/qrspi-finding-verifier.md` with a new procedure step (Step 3.5: Cite Check) and a new top-anchor rubric tier (`0 / HALLUCINATED`). No new subagent, no new sidecar field, no new orchestrator code path. The existing reason field on the sidecar carries the `HALLUCINATED:` prefix as a convention; humans can grep dropped sidecars for the prefix if they want a count.

Composition rationale: the verifier already lazy-Reads cited upstream files (current step 4) and reads `referenced_files` entries (current step 3). Cite Check piggybacks on those reads — the marginal cost is a content-equality assertion, not a new file access. Adding the check as a verifier-internal step keeps "all confidence dimensions in one subagent" and avoids the drift risk of a parallel pre-verifier grep gate. Cross-link to G10: the same cite-check mechanism that catches "L516 contains `widen/ref`" hallucination also catches "the spec says X" procedural fabrications when X is not in the spec — the two goals share the same verifier-rubric expansion path.

**Decisions locked:**

- **A — Cite-check scope: literal + structural (A2).** Cite Check verifies (1) file existence for bare-path `referenced_files` entries, (2) line/range existence for `path:line` and `path:line-line` entries, (3) literal-substring presence when the finding's prose quotes a specific string and attributes it to a specific cited location, and (4) anchor presence when the finding names a heading, function, class, or other identifier and attributes it to a cited file. Pure semantic claims ("the design is wrong") with no cited resource are out of scope — they remain the existing rubric's territory.
- **B — Failure mode: halt-and-zero (B1).** On any cite-check mismatch, emit `score: 0` with reason `HALLUCINATED: <diagnostic>`, halt remaining rubric steps, write the sidecar, return. A finding built on a fabricated citation is structurally untrustworthy; partial-confidence semantics do not apply.
- **C — Citation source: `referenced_files` frontmatter + prose body (C1+).** The frontmatter `referenced_files` field is the primary citation source (always checked). When the finding's prose body quotes a specific string adjacent to a cited path:line or names an anchor adjacent to a cited file, those prose citations are also checked. Heuristic identification of "cited content" inside prose is the verifier's responsibility (the verifier is an LLM — it reads the finding and identifies the load-bearing factual claims). The verifier MUST NOT invent claims to check; it MUST NOT flag findings whose prose makes no specific factual cite. A standalone citation extractor subagent is deferred to v0.7.3.
- **D — Subagent reuse: automatic across all skills.** The verifier already runs on findings from every reviewer fan-out (Goals, Questions, Research, Design, Phasing, Structure, Plan, Parallelize, Implement, Integrate). Cite Check expansion fires uniformly — no per-skill plumbing.
- **E — Reason field convention, NOT new sentinel.** Emit `score: 0` (integer) with reason `HALLUCINATED: <diagnostic>`. Do NOT add `HALLUCINATED` as a new sentinel value of the `score` field. The existing `VERIFY_FAILED` sentinel is handled by orchestrator as degraded-but-uncertain → keep-all (per `using-qrspi/SKILL.md` L984-985), which is the OPPOSITE of the dropped-by-threshold behavior wanted for hallucinations. Integer-0 + reason-prefix gets the correct drop semantics without orchestrator changes.

**Implementation deliverables.**

1. **`agents/qrspi-finding-verifier.md` — new Step 3.5: Cite Check, inserted between current step 3 and step 4.** Verbatim wording:

   > 3.5. **Cite Check** — verify cited resources actually contain what the finding claims they contain. The verifier MUST perform this check before scoring; mismatch produces `score: 0` and halts the rubric.
   >
   >    For each citation present in the finding (whether in `referenced_files` frontmatter or quoted in the finding's prose body), assert one of the following depending on citation shape:
   >
   >    - **File existence** — a bare path (no line number) in `referenced_files` MUST resolve to an existing file. Missing file → emit `score: 0`, reason `HALLUCINATED: file <path> does not exist`, write sidecar, halt.
   >    - **Line range** — a `path:line` or `path:line-line` entry in `referenced_files` MUST resolve to an existing range in the file. Out-of-range → emit `score: 0`, reason `HALLUCINATED: <path> has <N> lines, cited <range> out of range`, write sidecar, halt.
   >    - **Quoted content at cited location** — when the finding's prose quotes a specific string (in backticks, double quotes, or a fenced excerpt) and attributes it to a specific cited path:line, the verifier MUST read that line range and assert the quoted substring appears. Mismatch → emit `score: 0`, reason `HALLUCINATED: quoted content '<excerpt>' not found at <path:line>`, write sidecar, halt.
   >    - **Named anchor** — when the finding names a heading, function, class, type, variable, configuration key, CLI flag, or other identifier and attributes it to a specific cited file, the verifier MUST grep the cited file for the anchor. Anchor absent → emit `score: 0`, reason `HALLUCINATED: anchor '<name>' not found in <path>`, write sidecar, halt.
   >
   >    Findings whose prose carries no specific factual cite (pure-advisory style notes such as "consider naming this more clearly") have nothing to cite-check. Cite Check on such findings is a no-op; proceed to step 4.
   >
   >    The verifier MUST NOT invent claims to check, MUST NOT extrapolate from a finding's general tone, and MUST NOT flag findings whose prose carries no specific factual cite. Cite Check fires only against citations the finding actually makes.

2. **`agents/qrspi-finding-verifier.md` — new top-anchor rubric tier (prepended to the existing 0/25/50/75/100 anchors).** Verbatim wording:

   > a. **0 / HALLUCINATED:** Cite Check (step 3.5) found that the finding cites content that does not exist at the cited location — file missing, line range out of bounds, quoted string absent at cited line, or named anchor absent in cited file. The finding is structurally untrustworthy regardless of how plausible its prose reads. Halt rubric, emit `score: 0` with reason `HALLUCINATED: <diagnostic>`.

   The existing five anchors (0, 25, 50, 75, 100) are renumbered b-f (or relabelled however the file's current letter scheme accommodates the new top anchor — the verbatim wording above carries `0 / HALLUCINATED` as the explicit name to disambiguate from the existing plain `0` anchor which captures the pre-existing-issue / false-positive case).

3. **`agents/qrspi-finding-verifier.md` — reason field convention documented in step 6 (Write sidecar).** Append one sentence to the existing step 6 success-case description: "When the score is `0` due to Cite Check failure (step 3.5), the `reason` value MUST start with the literal prefix `HALLUCINATED: ` so dropped sidecars can be greppable for the hallucination subset."

4. **No changes** to `skills/using-qrspi/SKILL.md` Apply-fix protocol, orchestrator code paths, `verifier_enabled` field semantics, or per-skill review-loop wiring. Score-0 findings already fall below both correctness (≥70) and style/clarity (≥80) thresholds and are dropped by the existing protocol — Cite Check rides on the existing drop path.

5. **No changes** to reviewer subagents. The hallucination is a reviewer-side defect this design does not attempt to prevent at the reviewer level (reviewer-side prevention is a model-calibration concern tracked separately as G20 / #237). G19 closes the filter; G20 closes the source.

6. **Test coverage.** The existing `qrspi-finding-verifier.md` agent has no bats coverage (it's an LLM agent file, not a script). The Cite Check step's correctness is verified at next self-host signal cycle: any wholesale-hallucination finding produced by a reviewer subagent in v0.7.2 self-host MUST drop with `HALLUCINATED:` reason. A negative self-host signal (hallucination passes through) is a v0.7.3-blocking defect.

**Cross-cutting note (G19 ↔ G10).** G10 captures the procedural-fabrication pattern at #226 occurrence 7 ("the spec says X" when the spec does not say X). G10's mechanism is a Plan-side check ("are findings' factual claims about the artifact verifiable?"); G19's mechanism is a verifier-side check ("does cited content actually exist?"). The two interlock: G10 prevents procedural fabrications from being authored by reviewers in the first place (via prompt-side discipline); G19 catches them at the verifier filter when prompt-side discipline fails. Both paths converge on the same defense surface and neither subsumes the other.

**Cross-cutting note (G19 ↔ G20).** G20 (model calibration for task-tool-substituted models) is the source-side fix for the reviewer-side defect that creates wholesale hallucinations. G19 is the filter-side fix that catches them regardless of source. The two goals are complementary: G20 reduces hallucination rate at origin; G19 ensures any that get through don't reach the orchestrator. Lock both — neither alone closes the surface.

**Open Questions for v0.7.3+.** Tracked externally as GitHub issue dfrysinger/qrspi-plus#270 (filed when this design block ships): (a) does v0.7.2 self-host signal indicate the LLM-internal prose-citation heuristic (sub-decision C) is reliable enough, or do we need a standalone citation-extractor subagent that emits structured cite tuples for the verifier? (b) cross-reviewer corroboration threshold (raise score floor for single-reviewer findings) — orthogonal mechanism worth a separate goal if calibrated non-hallucinated findings cause trouble. (c) pre-verifier separate grep gate as belt-and-suspenders — only revisit if v0.7.2 self-host signal shows verifier-internal Cite Check regressing. (d) automated repro harness for hallucination probability per model — pairs naturally with G20 model-calibration work.

**Pre-existing plugin issues to file.** None new. G19 closes the v0.7.1 R6 reproduction observed in this session-prior hardening; no separate plugin issue surfaces because the defect is the absence of a check, not a malformed existing check.

**References.** Source: goals.md G19 / #236 (v0.7.1 hardening Integrate R6 reproduction); `agents/qrspi-finding-verifier.md` (sole edit surface, 64 lines pre-change); `skills/using-qrspi/SKILL.md` L984-985 (drop-by-threshold protocol that Cite Check rides on), L864 (`VERIFY_FAILED` sentinel handling — Cite Check explicitly does NOT use this code path, hence integer-0 + reason-prefix); related G10 (procedural-fabrication catch — verifier-rubric expansion path shared); related G20 (#237 model calibration — source-side fix for the same defect class); related G6 (transport-layer disk-write contract — separate concern, but recurring in the same hardening sessions).

---

## G20 — Reviewer-model calibration: observability surface

**Type:** exploratory. **Source:** goals.md G20 / #237. **Cross-link:** complementary to G19 (G19 = filter-side hallucination catch; G20 = source-side calibration data — different defect classes, neither subsumes the other).

**Caveat on motivating evidence (read first).** The v0.7.1 Integrate R4 ICX-F02 calibration gap was observed during a run where the orchestrator was hand-handling model dispatch — the plugin's `model_routing:` chain was not yet shipping its current form. Whether the calibration gap remains a real signal once the dispatch chain functions as designed is **the open question this goal records data to answer** — not an assumption this design takes as given. v0.7.2 ships the recording surface only. Mitigation decisions defer to v0.7.3 after v0.7.2 self-host signal.

**Scope (locked).** Observability-only: A1 + B1 + D1 from the goal candidates. No KEEP-threshold change. No mitigation. No `model_routing:` schema extension. No aggregate UI in `verified.md`. The verifier filter remains the load-bearing defense against the over-flagging this goal measures.

**Sub-decisions:**

- **A1** — observability-only this release. No correctness-threshold (`≥70`) or style/clarity-threshold (`≥80`) change. Whether to bump the threshold for substituted-model reviewers is deferred until v0.7.2 data is in hand.
- **B1** — per-finding sidecar field. Aggregation is post-hoc shell (`grep "^actual_model:" reviews/*/round-NN/*.md | sort | uniq -c`-class one-liners). No aggregate header surface added to `verified.md`.
- **D1** — value flows reviewer-frontmatter → verifier-sidecar. Reviewer emits the field on every finding file and every `*.clean.md` sentinel at emission time; verifier copies it verbatim to the sidecar. The dispatcher supplies the value as a dispatch parameter (it already resolves the model ID at dispatch site — this is recording, not new computation).

**Deliverables:**

1. **Reviewer-protocol audit-field addition** (`skills/reviewer-protocol/SKILL.md`) — extend the audit-field list (currently `artifact`, `round`, `reviewer`) to include `actual_model`. The contract: reviewers MUST emit this field on every finding file and every `*.clean.md` sentinel. Value type: the resolved model ID string (e.g. `claude-sonnet-4.6`, `gpt-5.3-codex`) per the `model_routing:` chain output. The per-finding file format example block and the clean-sentinel block both gain the field.

2. **Dispatch parameter addition** — every per-skill SKILL.md that dispatches reviewers via the Standard Review Loop adds one parameter to the reviewer dispatch prompt: `actual_model: <resolved model ID>`. The orchestrator already resolves this value at dispatch site (it's the value passed to `Agent({ ..., model })` for Claude subagents and to the reviewer model flag of `scripts/run-codex-review.sh` for Codex subagents). The new parameter is record-keeping for the reviewer to copy into emission frontmatter. Files affected: per-skill SKILL.md under `skills/{goals,questions,research,design,phasing,structure,plan,parallelize,implement,integrate,test,replan}/`.

3. **Codex emission template update** (`skills/reviewer-protocol/codex-emission-override.md`) — the worked-example finding frontmatter and the clean-sentinel example both gain the `actual_model:` field so Codex subagents emit it. The splitter (`scripts/codex-finding-splitter.sh`) is unchanged — it splits on `<<<FINDING-BOUNDARY>>>`, does not parse frontmatter fields.

4. **Codex wrapper update** (`scripts/run-codex-review.sh`) — accept and inject `actual_model` into the composed dispatch-params section so Codex sees the value to copy through. Same shape as the existing `--reviewer-tag` / `--scope-hint` flags.

5. **Verifier sidecar schema addition** (`agents/qrspi-finding-verifier.md`) — step 1 (Read finding file) gains a phrase: "...parse the 5-field finding object plus the audit field `actual_model:`...". Step 6 (Write sidecar) gains one line in BOTH the success and the `VERIFY_FAILED` shapes: `actual_model: <copied verbatim from finding frontmatter>`. When the finding file omits the field (older rounds, hand-written rounds, drift from a reviewer that did not yet adopt the new audit field), the verifier writes `actual_model: unknown` rather than failing — this is observability data, not a correctness gate. Step 7's return line is unchanged.

6. **No test coverage.** The new field is descriptive, not behaviorally load-bearing — nothing keys off its value in v0.7.2. Self-host signal in v0.7.2 demonstrates whether reviewers emit it consistently. If the field is missing from >5% of v0.7.2 emissions, that's a v0.7.3-blocking emission-protocol drift, not a v0.7.2 design defect. The clean-sentinel coverage matters: without it we lose the "this reviewer dispatched but found nothing" data point for calibration aggregation.

**v0.7.3 follow-up issue (to file alongside this commit).** Once v0.7.2 self-host accumulates `actual_model:` data:

- **a.** Decide whether the calibration gap reproduces under correctly-routed dispatch — or whether the v0.7.1 ICX-F02 observation was an artifact of the hand-handled-dispatch run state.
- **b.** If real: lock candidate 3 (per-substituted-model KEEP threshold bump) or candidate 1's deeper variant (per-`(reviewer_tag, actual_model)` calibration table driving per-pair thresholds).
- **c.** If not real: close G20 in v0.7.3 with no further action; the audit field remains as cheap insurance against future calibration drift.
- **d.** Repro-harness pairing with G19's #270 direction (a) — if the same prompt shape provokes both wholesale fabrication (G19) and misinterpretation (G20), one mitigation may close both.

**Cross-cutting notes.**

- **G20 ↔ G19.** G19 caught wholesale fabrication (filter-side, via Cite Check). G20 measures source-side calibration. Both surface under substituted-model reviewers; neither subsumes the other.
- **G20 ↔ G6 (transport-layer disk-write contract).** G6 governs WHERE reviewer output lands. G20 governs WHAT one field of that output contains. No coupling at the design level.
- **G20 ↔ G22 (`model_routing:` schema drift).** G22 may surface new tier names or new substitution rules; the `actual_model:` audit field records whatever value the routing chain ultimately resolved, so G20 absorbs any G22 schema evolution without further change.

**References.** Source: goals.md G20 / #237 (v0.7.1 hardening Integrate R4 ICX-F02); `skills/reviewer-protocol/SKILL.md` L216-234 (per-finding file format, audit fields, clean-sentinel schema); `agents/qrspi-finding-verifier.md` steps 1 + 6 (Read finding + Write sidecar — sole verifier-side edit surface); `skills/using-qrspi/SKILL.md` L388 + L985 (KEEP thresholds — unchanged by this goal); related G19 (filter-side counterpart, locked at `6f4aefb`); related G22 (`model_routing:` schema — separate concern); related #270 (v0.7.3 repro infrastructure that this goal's data drives into).

---

## G21 — Bats silent-pass: retrofit unguarded `$body` negation assertions + add lint gate

**Type:** known-fix. **Source:** goals.md G21 / #238 (surface — vocab pin asymmetry) + #244 (root-cause investigation — deferred to v0.7.3 per sub-decision B).

**Plain-language framing.** In `tests/unit/test-using-qrspi-vocab.bats`, eight assertions of the form `[[ "$body" != *"<bad text>"* ]]` lack a preceding `[ -n "$body" ]` guard. When the extractor that fills `$body` returns empty (because the asserted section is missing from the source, the H4 anchor drifted, or the extraction regex stopped matching), the negation form is vacuously true — empty string doesn't contain the bad text — and the test passes green without verifying anything. The R5-era pins in the same file demonstrate the safer two-line decomposition (guard + assertion) that closes the silent-pass surface.

**Repository grounding (verified at design time).** `grep -rn -E '\[\[ "\$body" !=' tests/` returns 8 hits, all in `tests/unit/test-using-qrspi-vocab.bats` (lines 132-133, 157-158, plus the corresponding negative-form pins in the R4-era trusted-path block). No instances exist outside that file. 4 of 16 total `$body`-assertion lines in the file already carry the `[ -n "$body" ]` guard prefix (the R5-era pattern). The blast radius is narrower than the goal text suggests — one file, eight unguarded negations.

**Sub-decisions locked.**

- **A1 — Retrofit only the 8 known unguarded `!=` assertions in `test-using-qrspi-vocab.bats`.** Minimum surface; the demonstrated hazard is the negation form, and the broader lint gate (B2) catches any further drift without requiring a full corpus audit step. Out of scope at this goal: positive-form (`==`, `=~`) assertions without `-n` guards (they fail loudly today rather than silently passing — different failure mode, separate hazard class).
- **B2 — Add a small bats-based lint check that flags `[[ "$body" ... ]]` assertions inside `@test` blocks without a preceding `[ -n "$body" ]` guard.** Implementation shape: one new test file at `tests/lint/test-bats-body-assertion-guard.bats` that walks `tests/**/*.bats`, parses `@test` blocks, and fails any block containing an unguarded `$body` assertion. Cheap grep-based logic (no AST parser needed); the rule is "every line matching `\[\[ "\$body"` inside an `@test` block must be preceded — anywhere earlier in the same `@test` block — by a line matching `\[ -n "\$body" \]`." Structural fix: closes the gun-on-the-floor problem instead of just removing the current bullets.
- **C1 — CI gate only.** No pre-commit hook. Rationale: CI is the durable enforcement layer, pre-commit hooks are bypassable and add setup friction with no marginal correctness benefit on top of CI. If pre-commit feedback latency becomes painful in practice, revisit in v0.7.3.
- **B3 (bats upstream investigation) is deferred to v0.7.3 (#244 re-milestoned).** The lint gate from B2 makes the test layer safe regardless of whether bats core ever fixes the underlying short-circuit quirk; pursuing upstream pinning is not blocking for v0.7.2.

**Implementation deliverables.**

1. Edit `tests/unit/test-using-qrspi-vocab.bats` — for each of the 8 unguarded `[[ "$body" != *...* ]]` lines, prepend a `[ -n "$body" ]` line in the same `@test` block (the R5-era pattern from lines 172-184, 202-214 in the same file is the in-repo reference).
2. Add `tests/lint/test-bats-body-assertion-guard.bats` — bats test file containing `@test`s that:
   - Discover all `*.bats` files under `tests/` (excluding the lint test itself).
   - For each file, parse `@test` blocks (delimited by `^@test "..." \{` opening and matching `^\}` close at column 0).
   - Within each block, fail if any line matches `\[\[ "\$body"` without a `\[ -n "\$body" \]` line earlier in the same block.
   - Emit a clear diagnostic naming file:line for any violation.
3. Add the new lint test to the CI test invocation (whatever target already runs `bats tests/unit/` — extend to include `tests/lint/` or run `tests/` recursively).
4. Re-milestone #244 from v0.7.2 → v0.7.3 with a comment linking the G21 design block (the lint gate satisfies G21's v0.7.2 scope; #244 remains the home for the bats-upstream investigation thread).

**Test coverage.** The lint gate is itself a test — its presence and green state ARE the regression coverage. Additional bats unit tests for the lint logic itself (e.g., synthetic fixture files containing intentional violations) are deferred unless self-host signal shows the lint missing or false-positive-ing real cases. The R5-era pins in the existing vocab test file serve as live positive controls (they are guarded and the lint must accept them).

**Edit surface.** Two files: `tests/unit/test-using-qrspi-vocab.bats` (8 line additions, no deletions, no behavior change to passing assertions) and `tests/lint/test-bats-body-assertion-guard.bats` (new file). Plus the CI test-target update if needed.

**Cross-cutting notes.**

- **G21 ↔ test infrastructure (general).** This goal establishes "lint test as gate" as a pattern. Future regressions of the same shape (test forms that pass vacuously when their input is empty) can adopt the same shape — a `tests/lint/` companion test that walks the corpus. Not formalized as a design principle in v0.7.2; let the pattern prove itself via self-host signal before promoting it.
- **G21 ↔ #244 (deferred investigation).** The lint gate closes the v0.7.2 risk surface regardless of bats-core behavior. If v0.7.3 confirms a bats upstream fix or a version pin bump removes the short-circuit quirk, the lint gate becomes redundant insurance — keep it anyway; the cost is one fast bats test and the alternative is re-introducing the same gun if bats regresses.

**References.** Source: goals.md G21 / #238 (surface) + #244 (root cause — deferred); `tests/unit/test-using-qrspi-vocab.bats` (sole retrofit surface; lines 121-133 R2-era model_routing pins, lines 145-158 R4-era trusted_path pins, lines 172-184 + 202-214 R5-era reference pattern); related v0.7.3 follow-up: #244 (bats-upstream investigation) re-milestoned at design-lock time.

**Amendment at G26 design-lock — BW02 guard rule extension.** The lint test `tests/lint/test-bats-body-assertion-guard.bats` (from B2 above) adds one parallel rule that catches the actual BW02 surface (`<feature> requires at least BATS_VERSION=<version>` per [bats-core BW02 docs](https://bats-core.readthedocs.io/en/stable/warnings/BW02.html)): for any `.bats` file using a bats ≥1.5.0 feature (initial pattern set: `run --separate-stderr`; extend as new triggers surface in self-host signal), require a `bats_require_minimum_version <version>` declaration earlier in the same file. Diagnostic names the file:line and the triggering feature. 46 of 104 `.bats` files in the tree already carry the guard for the right reason (all 5 files using `--separate-stderr` have it); the lint rule prevents new test files from regressing the pattern. Implementation surface: ~30 additional lines in the lint test file (same `tests/lint/test-bats-body-assertion-guard.bats` introduced by B2 — no new lint file); rationale: B2's lint test already walks `tests/**/*.bats`, so the BW02 guard rule reuses that walk rather than spawning a sibling file. Renaming the lint test file to a more general name (e.g., `tests/lint/test-bats-hygiene.bats`) is at the implementer's discretion if it reads cleaner; not required. See G26 design block (below G25) for the moot-disposition audit trail this amendment derives from.

---

## G22 — Initial tier-assignment rubric + doc cleanup for the unified `model_routing:` schema

**Type:** exploratory. **Source:** goals.md G22 / #239. **Cross-link:** absorbs and supersedes #239 (dead-schema scaffolding); rides on CD-1 (universal dispatch architecture) which locks the schema and dispatch chain — G22 covers only the residual rubric and doc-cleanup work CD-1 leaves on the floor.

**Plain-language problem.** The `model_routing:` block in `config.md` was documented two contradictory ways before this release (tier-keyed-per-host in `using-qrspi/SKILL.md:448-470`; role-keyed in `implement/SKILL.md:537,548-560`). CD-1 already resolves the schema-drift by replacing both with one vendor-neutral, tier-keyed schema (`{extra-low, low, medium, high, extra-high}`) and a universal dispatch script. What CD-1 does NOT supply: (a) the initial agent-by-agent tier-assignment rubric (which of the 41 agents declare which tier as a default), (b) the matching deletion of the now-superseded schema docs in `using-qrspi` and `implement`, (c) the migration of plan-time per-task `model:` field → `tier:`, (d) the removal of ~40 hardcoded `model: "sonnet"` lines from skill-prose dispatch sites. G22 owns all four.

**Why this matters.** Without an initial rubric, every agent ships with no `tier:` default and every dispatch falls through CD-1's precedence chain to `default_tier: medium`. That works but loses cost-vs-quality variation: the 5 currently cheap-eligible agents (per the v0.7.1 G5 matrix + finding-verifier + scope-tagger callouts) would silently consume sonnet across hundreds of dispatches per pipeline run. Without doc-cleanup, the contradictory old schema docs continue to be the first thing operators read, defeating CD-1's purpose. Without per-task migration, plan-emitted `model:` fields keep landing in a field name the new universal dispatcher doesn't read.

**Outcome.** Three deliverables ship together at Implement time:

**Deliverable 1 — Initial tier-assignment rubric (41 agents).** Each agent's frontmatter gains a `tier:` field. The assignments mirror the explicit signals already present in v0.7.1 prose (G5 matrix, finding-verifier "Haiku" callout, scope-tagger "Haiku" callout, the ~40 hardcoded `model: "sonnet"` dispatch sites that establish today's baseline):

| Tier         | Count default | Agents (alphabetical within tier)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
|--------------|---------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `extra-low`  | 0             | (operator-only surface; `--tier-override extra-low`)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| `low`        | 5             | `qrspi-finding-verifier`, `qrspi-implementer-lightweight`, `qrspi-research-collator`, `qrspi-research-specialist`, `qrspi-scope-tagger`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| `medium`     | 36            | `qrspi-code-quality-reviewer`, `qrspi-code-simplifier`, `qrspi-design-reviewer`, `qrspi-design-scope-reviewer`, `qrspi-goal-traceability-reviewer`, `qrspi-goals-reviewer`, `qrspi-goals-scope-reviewer`, `qrspi-implement-gate-reviewer`, `qrspi-implementer`, `qrspi-integration-reviewer`, `qrspi-parallelize-reviewer`, `qrspi-parallelize-scope-reviewer`, `qrspi-phasing-reviewer`, `qrspi-phasing-scope-reviewer`, `qrspi-plan-goal-traceability-reviewer`, `qrspi-plan-reviewer`, `qrspi-plan-scope-reviewer`, `qrspi-plan-security-reviewer`, `qrspi-plan-silent-failure-hunter`, `qrspi-plan-spec-reviewer`, `qrspi-plan-test-coverage-reviewer`, `qrspi-questions-reviewer`, `qrspi-replan-analyzer`, `qrspi-replan-reviewer`, `qrspi-replan-scope-reviewer`, `qrspi-research-reviewer`, `qrspi-security-integration-reviewer`, `qrspi-security-reviewer`, `qrspi-silent-failure-hunter`, `qrspi-spec-reviewer`, `qrspi-structure-reviewer`, `qrspi-structure-scope-reviewer`, `qrspi-test-coverage-reviewer`, `qrspi-test-writer`, `qrspi-type-design-analyzer`, `qrspi-visual-fidelity-reviewer` |
| `high`       | 0             | (invoked via `--tier-override` from Plan-time heuristic on `qrspi-implementer` AND `qrspi-test-writer` together — see Deliverable 2)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| `extra-high` | 0             | (operator-only surface; `--tier-override extra-high`)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |

`default_tier:` in `config.md` = `medium` (the migration fallback for any agent shipped without `tier:`; matches today's sonnet baseline).

**Operator surfaces** (`extra-low`, `extra-high`) carry NO default consumers by design. Operators who want sub-haiku cheapness wire a third-party vendor entry into `model_routing.extra-low:` (vendor-neutral — Kimi K2, DeepSeek V3, or anything else) and either (a) invoke `--tier-override extra-low` on specific tasks/agents, or (b) edit specific agent frontmatter to declare `tier: extra-low`. Same shape for `extra-high`. CD-1's halt-on-`none` rule (no silent fallback to a neighboring tier) means a `--tier-override extra-low` against an unconfigured `extra-low: none` row halts loudly — operators see immediate failure if they target an unconfigured tier.

**Deliverable 2 — Test-writer / implementer per-task co-escalation.** When Plan's Step 2 heuristic emits `tier: high` for a `code` task (target files >3 OR core-surface OR fix-retry OR sizing-exception), BOTH the per-task implementer dispatch AND the per-task TDD test-writer dispatch run at `tier: high`. Plan emits ONE `tier:` field per `tasks/task-NN.md` (not separate `implementer_tier:` / `test_writer_tier:` fields); the dispatcher applies the same `--tier-override` to both dispatches for that task. Rationale: a test pins the contract the implementer must satisfy — if the task warrants a stronger implementer model, the test that pins its contract warrants the same strength. Mismatched tiers (medium test-writer pinning the contract for a high implementer's work) would systematically under-specify acceptance criteria for the most demanding tasks.

This formalizes what `test/SKILL.md:92` already does informally (the Test phase reads `test_writer_model` from `plan.md` frontmatter): the new version reads per-task `tier:` directly from `tasks/task-NN.md` in Implement phase. Test phase's per-plan acceptance-test dispatch (no per-task context) keeps the test-writer's agent default `tier: medium` as the fallback. `task_type: lightweight` tasks emit no test-writer dispatch (existing non-TDD behavior of `qrspi-implementer-lightweight`) and so are unaffected.

**Deliverable 3 — Doc-cleanup sweep + per-task field migration.** Specific edit surface:

- **`skills/using-qrspi/SKILL.md` L448-470** — DELETE the old tier-keyed-per-host `model_routing:` schema (haiku/sonnet/opus/inherit per claude-code / copilot-cli). REPLACE with documentation of CD-1's vendor-neutral 5-tier schema, the resolution chain, and a pointer to G22's initial rubric.
- **`skills/using-qrspi/SKILL.md` L472-488** — `trusted_path:` block: KEEP the short-circuit mechanism but rewrite to reference agent `tier:` (and agent file paths) instead of `model_role:` (which is being deleted in Deliverable 1's agent-frontmatter migration).
- **`skills/using-qrspi/SKILL.md` L503-512** — Precedence chain: REPLACE with CD-1's chain (`--tier-override` → agent `tier:` → `default_tier:` → hardcoded medium).
- **`skills/implement/SKILL.md` L525-560** — DELETE the old four-layer chain + role-keyed G5 matrix. REPLACE with: (a) a pointer to CD-1's universal dispatch architecture, (b) a pointer to G22's initial tier-assignment rubric (the table above), (c) the test-writer / implementer co-escalation rule from Deliverable 2.
- **`skills/plan/SKILL.md` L150-174 (Step 2 heuristic)** — Rename `model:` → `tier:` in plan-time per-task field emission. Remap values: `lightweight → tier: low`, `code default → tier: medium`, `code + escalation → tier: high`. Update the operator-override prose accordingly.
- **`skills/test/SKILL.md` L92** — Rename `test_writer_model` reference to read per-task `tier:` from `tasks/task-NN.md` (in Implement phase per-task dispatch) and to fall back to the test-writer agent's frontmatter `tier: medium` default (in Test phase per-plan dispatch).
- **All 41 agent files** (`agents/qrspi-*.md`) — Add `tier:` field to frontmatter per the rubric table. The 4 currently declaring `model_role:` (`qrspi-research-collator`, `qrspi-research-specialist`, `qrspi-implementer-lightweight`, `qrspi-test-writer`) get `model_role:` DELETED — the field is deprecated; tier carries the routing signal.
- **~40 skill-prose dispatch lines** across `skills/{goals,questions,research,design,phasing,structure,plan,parallelize,replan,integrate,implement,test}/SKILL.md` — REMOVE the hardcoded `, model: "sonnet"` argument from `Agent({ subagent_type: "qrspi-X", model: "sonnet" })` invocations. After CD-1's universal-dispatch refactor lands (CD-1 component #11 — shared `reviewer-dispatch-prose.md`), skill prose names only the agent; the dispatcher reads `tier:` and resolves the model. This per-line cleanup belongs to G22 because it is the per-site consequence of the schema migration, not part of CD-1's architecture-authoring scope.

**What G22 does NOT cover.** Auto-escalation of fix-retry-2/3 to `extra-high` (a sensible future use of the operator-only surface, but adds new escalation logic — defer to v0.7.3). Per-reviewer tier escalation in deep-mode review fan-out (e.g., promoting security-integration-reviewer to high — no current signal supports it; revisit if v0.7.2 self-host data shows medium-tier under-flagging). A telemetry surface that reports realized tier distribution per run (would inform whether the medium-default for 36 agents is the right baseline — natural pairing with G20's `actual_model:` audit field but out of G22's scope).

**Acceptance criteria (Plan-/Implement-authored).**

- Every one of the 41 agent files carries a `tier:` field with a value from `{extra-low, low, medium, high, extra-high}`; the assignments match the rubric table above (5 `low`, 36 `medium`, 0 declaring `extra-low` / `high` / `extra-high` by default).
- The 4 currently `model_role:`-declaring agents have `model_role:` removed.
- `skills/using-qrspi/SKILL.md` no longer documents the old tier-keyed-per-host schema (lines 448-470 region replaced).
- `skills/implement/SKILL.md` no longer documents the role-keyed G5 matrix (lines 525-560 region replaced).
- `skills/plan/SKILL.md` Step 2 heuristic emits `tier:` not `model:` in per-task frontmatter; the value mapping (lightweight→low, code-default→medium, code-escalated→high) matches Deliverable 2.
- `skills/test/SKILL.md` per-task TDD test-writer dispatch reads `tier:` from `tasks/task-NN.md`; per-plan acceptance-test dispatch falls back to the test-writer agent's `tier: medium` default.
- Grep across `skills/*/SKILL.md` for the literal `model: "sonnet"` argument inside `Agent({` invocations returns zero hits.
- `config.md` example block in CD-1 documentation contains the 5-tier `model_routing:` (with `extra-low: none` as the default).
- A test-writer dispatch and the implementer dispatch for the SAME task resolve to the same `(vendor, model)` pair under CD-1's resolution chain (co-escalation invariant).

**Cross-links.**
- **G22 ↔ CD-1.** CD-1 authors the schema, the dispatch chain, and the universal entry point. G22 authors the initial per-agent tier assignments, the doc-cleanup sweep that deletes the superseded old schemas, the plan-time field migration (`model:` → `tier:`), and the skill-prose dispatch-line cleanup. The tier enum amendment (5 tiers including `extra-low`) and the co-escalation rule's existence are committed in CD-1; the rubric values and the per-site edits live here.
- **G22 ↔ G20.** G20's `actual_model:` audit field records whatever value the routing chain ultimately resolves — it absorbs G22's tier semantics without further change. The two goals are complementary: G22 chooses the source rubric; G20 records what the source produced at dispatch time.
- **G22 ↔ G18.** G18's plan-phase under-scoping prevention would have caught the schema-drift cluster at plan-review time (canonical schema in two skills, consumers in many others). G22 is the specific code fix for the instance that already shipped; G18 prevents recurrence. G18 design (L1626) explicitly notes G22 stays as its own goal — G18 does not subsume it.
- **G22 ↔ #239.** #239 (dead-schema scaffolding: haiku/sonnet/opus tier rows post-T9) is absorbed by CD-1's replacement schema (the tier-keyed-per-host rows disappear entirely; the new 5-tier vendor-neutral schema takes their place). #239 closes when G22 ships; no separate v0.7.2 work item.

**Pre-existing plugin issues to file.** None new. G22's residual surface after CD-1 is fully covered by this design block; the doc-cleanup edit surface enumerated in Deliverable 3 is the complete v0.7.2 work item.

**Open Questions for v0.7.3+.** (a) Does v0.7.2 self-host signal show any of the 36 medium-default agents systematically over- or under-performing at sonnet, warranting tier reassignment? (b) Does the `extra-low` operator surface see real use, or remain dead scaffolding (which would warrant deprecation in v0.7.4)? (c) Should fix-retry-2/3 auto-escalate to `extra-high` (the natural future consumer of the operator-only surface)? (d) Does the test-writer / implementer co-escalation produce observable acceptance-criteria quality difference vs. mismatched tiers (informs whether the co-escalation rule should generalize to other paired dispatches)?

**References.** Source: goals.md G22 / #239; CD-1 (this file, top — universal dispatch architecture); `skills/using-qrspi/SKILL.md` L448-470 (old tier-keyed-per-host schema — sole replacement target), L472-488 (trusted_path — update target), L503-512 (precedence chain — replacement target), L661 (finding-verifier "Haiku" callout — input signal), scope_tagger_enabled prose (scope-tagger "Haiku" callout — input signal); `skills/implement/SKILL.md` L525-560 (old four-layer chain + role-keyed G5 matrix — sole replacement target); `skills/plan/SKILL.md` L150-174 (Step 2 heuristic — migration target); `skills/test/SKILL.md` L92 (`test_writer_model` indirection — migration target); `agents/qrspi-*.md` (all 41 — tier-field migration target); `agents/qrspi-{research-collator,research-specialist,implementer-lightweight,test-writer}.md` (4 with `model_role:` to delete); related CD-1 (architecture authority); related G20 / #237 (`actual_model:` audit field — orthogonal observability); related G18 / #235 (plan-phase under-scoping — prevention pattern); absorbs #239 (closes on G22 ship).

---

## G23 — Validation table omits `model_routing:` and is uncross-linked to fail-loud paragraphs

**Type:** known-fix. **Source:** goals.md G23 / #240. **Cross-link:** rides on CD-1 (new vendor-neutral 5-tier schema) and G22 (schema-doc rewrite + per-agent rubric); G23 owns the residual validation-table row plus bidirectional cross-links left on the floor by both upstreams. Sequencing: CD-1 → G22 → G23.

**Plain-language problem.** The validation table at `skills/using-qrspi/SKILL.md` L641-660 (heading: `### Fields that affect pipeline behavior (must be validated)`) is the single most-discoverable surface that tells operators "these are the fields the runtime validates on every config load." It enumerates 9 fields (`route`, `pipeline`, `codex_reviews`, `review_depth`, `review_mode`, `verifier_enabled`, `scope_tagger_enabled`, `visual_fidelity_required`, `question_budget`). It does NOT list `model_routing:` — even though two fail-loud paragraphs elsewhere in the same file (~L470 dispatcher-scope; ~L526 missing-block backfill) enforce its presence on every dispatch. A reader of the validation table reasonably concludes that the 9 listed fields are the complete required set; the actual required set after CD-1 ships is "those 9 PLUS `model_routing:` per the two fail-loud paragraphs." The fail-loud paragraphs themselves do not point back to the validation table, so the gap is silent in both directions.

**Why we care.** Config-authoring time is the highest-leverage opportunity to communicate the required-blocks contract. The runtime fail-loud paragraphs catch the omission at first dispatch — loud, but late: the operator has already shipped a config they believed was valid. Doc-discoverability at the validation table prevents the late-catch class entirely (the operator sees the row, authors the block, never reaches the runtime check). This is a small fix with disproportionate ergonomic payoff because operators read the validation table once at config-authoring time and only ever re-read the fail-loud paragraphs after they fire.

**What G23 delivers.**

1. **One new row in the validation table** (`skills/using-qrspi/SKILL.md` L641-660 region, post-G22 rewrite):
   - **Field name:** `model_routing:` (top-level block, not a scalar field; the row's "Valid values" cell describes the per-vendor 5-tier map shape rather than a literal enum).
   - **Skills that validate it:** `using-qrspi` (dispatcher pre-flight at `detect_host` time + every dispatch), Goals, Plan, Parallelize, Implement, Integrate (any skill whose Config Validation Procedure invocation runs the runtime dispatcher).
   - **Valid values:** "per-vendor 5-tier map per CD-1; see `### \`model_routing:\` block` for the schema definition and the two fail-loud paragraphs at `### Missing model_routing: block in config.md` (post-G22 anchor) for runtime enforcement."
   - **Row position:** alphabetically slots between `codex_reviews` (line ~L644) and `question_budget` (line ~L652), but G23 emits it as a logically-grouped block-field row immediately after `route` (the only other block-shaped field in the table) so block-shaped fields cluster visually.

2. **Two bidirectional cross-link annotations** — one-sentence appends to each fail-loud paragraph (post-G22 rewrite locations):
   - The dispatcher-scope paragraph (CD-1's replacement for L470's current text): append "This requirement is enumerated in the validation table at `### Fields that affect pipeline behavior (must be validated)`."
   - The missing-block-backfill paragraph (CD-1's replacement for L526's current text): append the same one-sentence pointer.

   Both appends use the literal heading text (not a line number) so the cross-link survives future re-numbering. The phrasing matches the existing cross-link style elsewhere in `using-qrspi/SKILL.md` (e.g. the `verifier_enabled` row's "see `### When a required field is missing or has an invalid value` above" pattern at L676).

**What G23 does NOT cover.**
- The `model_routing:` schema itself, the dispatch chain, the per-vendor tier resolution, the `none`-halt semantics — owned by CD-1.
- The per-agent tier rubric, the doc-cleanup of L448-470 / L472-488 / L503-512, the plan-time `model:` → `tier:` migration, the `model: "sonnet"` dispatch-line cleanup — owned by G22.
- Replacing the validation table with a generated index sourced from a single canonical list — explicit non-goal for v0.7.2 (deferred candidate, see Open Questions).
- Validation rows for any other top-level `config.md` block not currently in the table (e.g. `providers:`, `trusted_path:`, `validators:`) — out of scope; G23's framing in goals.md is `model_routing:`-specific. A broader "validation-table parity audit" is a v0.7.3+ candidate.

**Acceptance criteria.**
- `skills/using-qrspi/SKILL.md` validation table includes exactly one new row for `model_routing:` after CD-1 + G22 land.
- The new row's "Skills that validate it" cell enumerates all skills whose Config Validation Procedure runs the dispatcher at re-entry (at minimum: `using-qrspi`, Goals, Plan, Parallelize, Implement, Integrate).
- The new row's "Valid values" cell cross-references both the schema-definition heading and the two fail-loud paragraph headings by literal text (not line number).
- Both fail-loud paragraphs (dispatcher-scope and missing-block backfill, post-G22) carry a one-sentence pointer back to the validation table by literal heading text.
- Net diff in `using-qrspi/SKILL.md` ≤ 10 lines (one table row insertion + two single-sentence appends).
- No new generator, no new lint hook, no canonical-source file, no new validators block.
- Implementation ordering: G23 lands AFTER CD-1 (schema) and AFTER G22 (schema-doc rewrite) — both upstreams must settle before G23's cross-link anchors are stable.

**Pre-existing plugin issues to file.** None new. G23's three edits are mechanical once CD-1 + G22 settle; no architectural surface of its own.

**Open Questions for v0.7.3+.** (a) Does the validation table grow past ~25 fields (whether from new top-level blocks or per-block scalar field expansion), making the goals.md candidate C (generated index sourced from a single canonical list) worth its maintenance cost? (b) Should other top-level `config.md` blocks not currently in the validation table (`providers:`, `trusted_path:`, `validators:`) earn rows in a follow-on "validation-table parity audit," and what scope-detection heuristic would catch the omission class in future config-schema additions?

**References.** Source: goals.md G23 / #240; CD-1 (this file, top — provides the post-rewrite schema and fail-loud paragraph content that G23's row + cross-links reference); G22 (this file — provides the post-rewrite L448-470 / L472-488 / L503-512 doc surface; G23's cross-links anchor to the headings G22 establishes); `skills/using-qrspi/SKILL.md` L641-660 (validation table — sole edit target for the new row), L470 (dispatcher-scope fail-loud paragraph — post-G22 rewrite location for the first cross-link append), L526 (missing-block backfill fail-loud paragraph — post-G22 rewrite location for the second cross-link append), L676 (existing cross-link style template — `verifier_enabled` row pattern G23 matches); related G7b / #204 (silent-fallback class the fail-loud paragraphs exist to close); closes #240 on ship.

---

## G24 — R4 simplify-claude advisories: re-scoped to F05 after tree audit (F01/F03/F04 moot; F02 defers to G25)

**Type:** known-fix. **Source:** goals.md G24 / #241 (the 5-finding R4 simplify-claude bundle). **Cross-link:** rides on G21 (`$body`-presence guard for bats negation assertions — F05's rewrite must satisfy it) and explicitly defers F02 to G25 (top-level invariant subsumes per-H4 mirroring).

**Plain-language problem.** R4 simplify-claude in v0.7.1 deep mode produced 5 advisory simplification findings (F01–F05) covering test-helper duplication, anti-pattern pin fragility, and prose redundancy. The bundle was deferred to v0.7.2. Re-auditing each finding against the current `qrspi-plus-v0.7.2` tree (commit baseline at `e453f91` "v0.7.1 hardening: close G7b/#204 silent-fallback class + per-host model_routing") shows four of the five no longer match the tree: F01's target test files (`tests/acceptance/v07-phase1/test-t10-*.bats`) and its helper (`_assert_host_block_has_routing`) do not exist (v0.7.1 hardening restructured that surface), F03's cross-file duplication does not exist (the `_extract_h4` helper lives in one file only — `tests/unit/test-config-model-routing.bats`), F04's `(haiku|sonnet|opus|inherit)` tier regex is no longer present in tests at any volume worth consolidating, and F02 explicitly defers to G25 by the goal text itself. F05 is the only finding that survives the audit: four bats assertions in `tests/unit/test-using-qrspi-vocab.bats` (L132, L157, L183, L213) pin a contract via the literal substring `"silently fall back to the agent-bundled default"` — and that contract's prose is being edited four times this release (CD-1, G22, G23, G25), making the literal-substring pin fragile by construction.

**Why we care.** The F05 pin's whole purpose is to fail loudly when prose drift reintroduces a silent-fallback. A literal-string pin against a sentence that is actively being edited is brittle: any future re-phrasing ("silently degrades to the agent default", "silently substitutes the bundled model", etc.) passes the pin without catching the regression — the exact silent-miss class the pin exists to prevent (same family as G7b / #204). G24's value is small per finding but disproportionate per ergonomic risk: leaving a known-fragile guard on a known-evolving contract is the worst combination.

**What G24 delivers (post-audit re-scope to F05 only).**

1. **Replace 4 literal-substring pins** at `tests/unit/test-using-qrspi-vocab.bats` L132, L157, L183, L213 with a regex pin matching the contract's **intent** rather than its literal phrasing. Recommended regex: matches the sequence `silent…` + `(fall…back|degrad|default)` in some form, so future re-phrasings still trip the assertion when the silent-fallback semantic is what changed. Exact regex authoring is plan-time territory; the design constraint is "match intent, not literal."

2. **Wrap the regex assertion in a `$body`-presence guard per G21** (already locked). G21 retrofit unguarded `$body` negation assertions to fail-loud when the body is missing or empty; F05's rewrite must inherit that guard pattern. A bare `[[ ! "$body" =~ regex ]]` is a G21 regression (passes silently when `$body` is empty); the rewrite must read `$body` after the G21 presence check.

3. **Close #241** with a re-scope note: "5 advisories → 1 after tree audit. F01/F03/F04 moot (restructured away by v0.7.1 hardening or never materialized at the volume claimed); F02 deferred to G25 (top-level invariant subsumes per-H4 mirroring); F05 landed."

**What G24 does NOT cover.**
- **F01** (`_assert_host_block_has_routing` parameterization) — moot. Helper and target test files do not exist in current tree. Documented as "moot-after-v0.7.1-hardening" in the #241 close note; no implementation work.
- **F03** (`_extract_h4` consolidation into `test_helpers/extract.bash`) — moot as cross-file duplication. The helper exists in exactly one file. If CD-1's schema rewrite ends up duplicating it into a second file at implementation time, that's CD-1 implementer territory, not standalone G24 work.
- **F04** (`TIER_REGEX` constant) — moot. The `(haiku|sonnet|opus|inherit)` regex is no longer present in tests at any volume worth consolidating. CD-1 lands the new 5-tier vocabulary (`extra-low|low|medium|high|inherit` per the CD-1 amendment); if CD-1's bats tests for the new vocabulary end up duplicating a regex 3+ times, that's CD-1 implementer territory, not standalone G24 work.
- **F02** (per-H4 fail-loud contract consolidation at L470/L488/L501/L526) — defers to G25 by the goal text itself. If G25 lands a top-level invariant that subsumes the per-H4 paragraphs, F02 falls out as a side effect of G25's implementation. If G25 ships without that consolidation, F02 returns as a v0.7.3 candidate.
- Any consolidation of the regex pin pattern into a shared bats helper — explicit non-goal for v0.7.2 (only 4 pin sites, all in one file; helper extraction is over-engineering at this volume).

**Acceptance criteria.**
- The 4 literal-substring pins at `tests/unit/test-using-qrspi-vocab.bats` L132/L157/L183/L213 are replaced with regex assertions matching the silent-fallback semantic (not the literal phrasing).
- Each replaced assertion is wrapped in a G21 `$body`-presence guard (the test fails loudly when `$body` is missing or empty, not silently passes).
- The bats suite passes against the post-CD-1, post-G22, post-G23, post-G25 (if applicable) prose — i.e., the rewritten pins survive the four cross-cutting prose edits landing in this release.
- A negative-test acceptance: a deliberately-phrased silent-fallback sentence ("silently substitutes the bundled default", "silently degrades to the agent default") **trips** the regex pin, demonstrating the intent-match is genuinely broader than the literal-match it replaces. (Plan-time decides whether to author this as a real test case or as a one-line comment justifying the regex.)
- Net diff in `tests/unit/test-using-qrspi-vocab.bats` ≤ 20 lines (4 assertion sites × ~3-5 lines each including the G21 guard wrapper). No new shared helper file. No new bats utility.
- Implementation ordering: G24 lands AFTER G21 (`$body`-presence guard pattern is the dependency) and AFTER G22 / G23 / G25 prose edits settle (the rewritten pins need to match the final post-edit phrasing of the contract they guard, not a mid-flight version).

**Pre-existing plugin issues to file.** None new. The audit-vs-tree mismatch (4 of 5 findings moot) is itself a signal worth noting in the post-mortem of v0.7.1's R4 simplify-claude run: deferred advisory bundles should be re-audited against the tree before being walked at design time in the next release, because intervening hardening commits can moot premises silently. Whether this rises to a plugin issue depends on whether the pattern recurs across releases — flagged as an observation for v0.7.3 retro, not an open issue.

**Open Questions for v0.7.3+.** (a) If G25 ships without the top-level invariant consolidation, does F02 return as a standalone v0.7.3 goal, or does it stay deferred indefinitely? (b) Should the "deferred advisory bundle re-audit" become a standing pre-design step in the next release's Goals phase (a one-liner check: "for each carried-forward advisory, does the target surface still exist in the tree at the claimed volume?"), or is once-per-release ad-hoc auditing sufficient? (c) If the silent-fallback contract gets re-phrased again in v0.7.3+ in a way the regex doesn't anticipate (e.g., a totally new phrasing pattern), what's the escalation path — broaden the regex, or formalize the contract into a named string constant the prose and the test both reference?

**References.** Source: goals.md G24 / #241 (5-finding R4 simplify-claude bundle); G21 (this file — `$body`-presence guard pattern F05's rewrite must inherit); G25 (this file — F02 defers to G25's top-level invariant decision; if G25 walks before G24, the F02 deferral becomes concrete or releases F02 back as a v0.7.3 candidate); CD-1 (this file, top — provides the new 5-tier vocabulary whose bats tests F04 would have consolidated; CD-1 implementer territory if duplication emerges); G22 (this file — schema-doc rewrite that touches L470/L488/L501/L526 paragraphs F02 / F05 anchor against); G23 (this file — validation-table row + bidirectional cross-links that also touch the L470/L526 paragraphs); related G7b / #204 (silent-fallback class F05's pin exists to guard); v0.7.1 hardening commit `e453f91` (the structural change that mooted F01); `tests/unit/test-using-qrspi-vocab.bats` L132, L157, L183, L213 (sole edit target — the 4 pin sites); `tests/unit/test-config-model-routing.bats` (current home of the `_extract_h4` helper F03 referenced — single-file usage, no cross-file duplication); closes #241 on ship with re-scope note.

---

## G25 — Per-H4 fail-loud mirror pattern: moot / absorbed by CD-1

**Type:** known-fix. **Source:** goals.md G25 / #242 (R5+R6 security-claude structural-fragility findings against the v0.7.1 per-H4 mirror pattern). **Cross-link:** absorbed by CD-1 (this file, top — architectural rewrite eliminates the mirror pattern); resolves G24's F02 deferral (this file — F02 auto-resolves to moot); informs G23's cross-link targets (this file — the L470/L526 anchor paragraphs disappear with CD-1, so G23's implementation re-points the cross-links at CD-1's new single fail-loud sentence).

**Plain-language problem.** As authored in goals.md, G25 was guarding against a structural-fragility class in `skills/using-qrspi/SKILL.md`: the "no silent fallback to the agent-bundled default" contract was written four times in four H4 subsections under `### Dispatch routing blocks` — once each at L470 (`model_routing:`), L488 (`trusted_path:`), L501 (`validators:`), and L526 (missing-block backfill). R5 and R6 security-claude both flagged the same concern: a future author who adds a fifth dispatch H4 must remember to author a fifth mirror paragraph, and forgetting reproduces the G7b / #204 silent-fallback class this release exists to close. G25 proposed adding a top-level invariant at the section header, optionally with an executable bats pin walking the H4s, to convert author-discipline into compile-time enforcement.

**Why it's moot.** CD-1 is a wholesale architectural rewrite of the dispatch surface. The four H4 subsections G25 was guarding against **all disappear**: the per-host sub-mapping schema is replaced by a flat 5-row tier table (`extra-low / low / medium / high / extra-high`), `trusted_path:` short-circuit is replaced by a `--tier-override` script flag, post-dispatch `validators:` schema does not survive the rewrite, and the missing-block backfill becomes a Goals-skill onboarding step (5 questions populate the table). The "don't silently fall back" contract becomes one sentence in one place — CD-1 #2: "an agent dispatch that resolves to a `none` tier halts with a loud diagnostic (no silent fallback to a neighboring tier)." This is exactly the top-level invariant G25 proposed, achieved by architectural construction rather than by appending a section preamble. The mirror pattern G25 was guarding against literally cannot exist after CD-1 ships, because the H4s the mirrors lived in do not survive the rewrite.

**What G25 delivers (post-absorption).**

1. **Document the absorption.** This design block IS the deliverable — the locked record that G25's original framing is moot under CD-1, and that the executable-enforcement piece R5/R6 were after has been re-targeted onto CD-1's new dispatch surface.

2. **Re-target the executable enforcement to CD-1.** A single bats smoke test exercising a tier-resolved-to-`none` dispatch (asserting the dispatcher halts with a loud diagnostic) is added as an acceptance criterion to CD-1 (this file, top — appended to CD-1's existing acceptance-criteria list). This test is CD-1's scope, ships with CD-1's implementation, and is the executable counterpart to CD-1's prose contract. It is the same enforcement R5/R6 wanted G25 to deliver, at the post-rewrite layer instead of the pre-rewrite layer.

3. **Resolve G24's F02 deferral to moot.** G24 explicitly deferred its F02 finding ("fail-loud contract phrased 4× in per-H4 mirror paragraphs") to G25, with an open question of whether F02 returns as a v0.7.3 candidate if G25 ships without consolidation. G25's resolution answers that question definitively: F02 auto-resolves to moot because CD-1 eliminates the 4-mirror pattern entirely, leaving nothing to consolidate. F02 does NOT return as a v0.7.3 candidate.

4. **Close #242 on design lock** (not on ship) with re-scope note: "Absorbed by CD-1 — architectural rewrite eliminates the per-H4 mirror pattern; executable-enforcement counterpart added as CD-1 acceptance criterion (`none`-tier halt smoke test). F02 (G24 deferral) auto-resolves to moot."

**What G25 does NOT cover.**
- **Authoring a new top-level invariant in the existing pre-CD-1 prose.** Explicit non-goal. The pre-CD-1 prose is being deleted by CD-1; authoring a top-level invariant against soon-to-disappear prose is throwaway work.
- **A standalone bats pin walking H4s under `### Dispatch routing blocks`.** Explicit non-goal. The H4 cluster the pin would walk does not survive CD-1's rewrite; the post-rewrite single-sentence rule is verified by the `none`-tier halt smoke test (CD-1 acceptance criterion), not by H4-walking.
- **Hedge implementation in case CD-1 slips.** Explicit non-goal. The user chose option 1 (lock G25 as moot, add the executable enforcement to CD-1) rather than option 3 (keep G25 as standalone insurance). If CD-1 itself slips out of v0.7.2, G25 is re-opened as a v0.7.3 candidate at that point — not pre-emptively hedged here. The slip surface is the CD-1 ship gate, not a parallel G25 implementation track.
- **Updating G23's cross-link targets.** G23's cross-links currently anchor at L470 and L526 — both paragraphs disappear with CD-1's rewrite. Re-pointing the cross-links at CD-1's new single fail-loud sentence is CD-1 implementation territory (G23's cross-links ride on CD-1's prose authoring), not a standalone G25 task. Flagged in G23's design block already; flagged here for visibility.
- **Updating G24's pin sites' location.** G24's regex pins are intent-based (matches the `silent.*(fall.?back|degrad|default)` family), so CD-1's new phrasing — "no silent fallback to a neighboring tier" — still matches the regex; only the **location** of the pin sites moves during CD-1 implementation (the surrounding section is rewritten). G24's regex authoring is unaffected. Flagged here for visibility.

**Acceptance criteria.**
- G25 is locked at design time as moot / absorbed by CD-1; no separate v0.7.2 task ships under the G25 ID. The executable-enforcement piece rides with CD-1 (acceptance criterion appended in CD-1's section).
- #242 is closed at design lock (not on ship) with the re-scope note above.
- G24's F02 open question is resolved to moot — documented in this design block; not re-asked at G24 ship gate.
- If CD-1's design or scope is amended after this lock in any way that re-introduces a per-H4 mirror pattern (or any other multi-instance fail-loud contract), G25 re-opens for a fresh design pass against the amended CD-1.

**Pre-existing plugin issues to file.** None new. The "goal absorbed by a later cross-goal decision" pattern is itself a signal worth noting: the Goals phase locked G25 as standalone before CD-1's full design was written, then the Design phase's architectural rewrite (CD-1) re-scoped G25 to moot. This is a natural consequence of the QRSPI cascade ordering (Goals → Design), not a defect — but if it recurs across many goals in many releases, it might warrant a standing Design-phase pre-flight check ("for each open goal, does any cross-goal decision in this Design pass architecturally absorb it?"). Flagged for v0.7.3 retro observation, not an open issue.

**Open Questions for v0.7.3+.** (a) Does the post-CD-1 dispatch surface develop any new multi-instance fail-loud contract over time (e.g., per-vendor-transport halt semantics in `dispatch-companion.sh`, per-host detection diagnostics in `_host-detect.sh`)? If so, does the "single rule, single place, single executable enforcer" pattern G25's absorption demonstrates remain the right shape, or does some surface genuinely need multi-site mirroring? (b) Should the "absorbed by a cross-goal decision" disposition class earn a standard slot in the QRSPI goal-lifecycle vocabulary (alongside `known-fix`, `exploratory`, `moot`, `deferred`)? G25 is the first v0.7.2 goal whose disposition is "architecturally absorbed by a sibling Cross-Goal Decision" rather than "implemented" or "deferred to next release." (c) If a v0.7.3 author proposes resurrecting `trusted_path:` (the short-circuit CD-1 removes) or any other multi-H4 dispatch enumeration, what design-time gate prevents accidentally re-introducing the mirror-pattern fragility class G25/F02 were guarding against? Possible answer: an explicit checklist item in the Design skill ("any new dispatch surface must have one and only one fail-loud rule, with executable enforcement"). Defer the answer to v0.7.3 Design phase.

**References.** Source: goals.md G25 / #242 (R5+R6 security-claude structural-fragility findings); CD-1 (this file, top — architectural rewrite that absorbs G25; the appended `none`-tier halt smoke test is the executable-enforcement piece R5/R6 were after); G24 (this file — F02 deferral to G25 resolves to moot here); G23 (this file — cross-link targets at L470/L526 disappear with CD-1; G23 implementation re-points at CD-1's new single fail-loud sentence); G22 (this file — schema-doc rewrite that touches the same dispatch-routing section; G22's rubric for the 5-tier vocabulary lands the `extra-low` row CD-1's `none` semantics ride on); `skills/using-qrspi/SKILL.md` L470 / L488 / L501 / L526 (the four per-H4 mirror paragraphs that disappear with CD-1's rewrite — G25's pre-CD-1 framing was targeting this cluster); related G7b / #204 (silent-fallback class CD-1's `none`-tier halt rule closes at the architectural layer); closes #242 on design lock with absorbed-by-CD-1 note.

---

## G26 — BW02 deprecation warnings: moot / already fixed (regression-prevention rides on G21)

**Type:** known-fix. **Source:** goals.md G26 / #243 (BW02 deprecation-warning noise on `tests/unit/test-codex-splitter.bats`). **Cross-link:** regression-prevention surface added to G21's lint test via amendment at this design-lock (see G21's Amendment block); related to G21 hygiene goal family (#238 / #244).

**Plain-language disposition.** G26 is moot because the work is already done AND its source-issue premise was wrong about the BW02 mechanism. Three layers of evidence, all verified at design time at HEAD `6d04842`:

1. **The premise in #243 is inverted vs. bats-core upstream.** #243 framed BW02 as a shebang-deprecation warning, recommending `#!/usr/bin/env -S bats -t` or `bats_load_library bats-support`. Q17 web research (`research/summary.md` L286-294, `research/q17-web.md`) checked bats-core upstream sources and found the opposite: BW02 is **exclusively** a feature-version-guard warning of the form `<feature> requires at least BATS_VERSION=<version>. Use bats_require_minimum_version <version> to fix this message.` (per [bats-core BW02 docs](https://bats-core.readthedocs.io/en/stable/warnings/BW02.html) and [`lib/bats-core/warnings.bash`](https://raw.githubusercontent.com/bats-core/bats-core/master/lib/bats-core/warnings.bash)). The `#!/usr/bin/env bats` shebang is the standard, non-deprecated form throughout all bats-core documentation. The `#!/usr/bin/env -S bats -t` form #243 recommended is not documented or recommended anywhere in upstream source, docs, man pages, or CHANGELOG.

2. **The cited file already has the correct fix.** `tests/unit/test-codex-splitter.bats:8` declares `bats_require_minimum_version 1.5.0` — the actual BW02 mitigation, declared because the file uses `run --separate-stderr` (a 1.5.0+ feature). The file header at L3-7 documents the rationale ("Declaring the minimum version silences BW02 warnings and produces a clear up-front error on older bats installs"). The fix landed pre-v0.7.2; #243 was filed against a noise condition that no longer reproduces.

3. **No BW0N warnings fire across the full suite.** Verification: `bats tests/unit/ 2>&1 | grep -iE "BW0[0-9]|warning|deprecat"` against HEAD `6d04842` returns only test-name lines (tests *describing* warnings the project itself emits — e.g., "missing-model_routing warning: documented as one-time per session"); zero bats-core warnings on stderr across 1322 tests. 46 of 104 `.bats` files in `tests/` already carry the `bats_require_minimum_version` guard pattern; the 5 files that use `--separate-stderr` (`test-codex-splitter.bats`, `test-research-reviewer-path-dispatch.bats`, `test-v06-repros.bats`, `test-config-question-budget-field.bats`, `test-config-visual-fidelity-field.bats`) **all** have it.

**What G26 delivers (post-absorption).**

1. **Document the moot disposition.** This design block IS the deliverable — the locked record that G26's original framing is wrong about the BW02 mechanism, that the actual warning class is already silenced project-wide, and that the regression-prevention surface has been re-targeted onto G21's lint test.

2. **Re-target the regression-prevention surface to G21.** G21's lint test (`tests/lint/test-bats-body-assertion-guard.bats`, from G21's B2 sub-decision) gains one parallel rule that catches the actual BW02 surface: any `.bats` file using a bats ≥1.5.0 feature (initial pattern set: `run --separate-stderr`; extend as new triggers surface) without a `bats_require_minimum_version` declaration earlier in the same file. Specification lives in G21's Amendment block at this design-lock; G21's implementer ships both rules in the same lint file. Rationale: G21 already authors the lint walk over `tests/**/*.bats`; the BW02 guard rule is a parallel check within the same walk (cheap reuse, no new lint file). Closes the regression door G26's premise was trying (and failing, on the wrong target) to close — a future test that adopts `--separate-stderr` (or any other 1.5.0+ feature in the pattern set) without the guard now fails CI loudly.

3. **Close #243 on design lock** (not on ship) with re-scope note: "Moot — premise inverted vs. bats-core upstream BW02 semantics (Q17 research at `research/q17-web.md`); `tests/unit/test-codex-splitter.bats:8` already declares `bats_require_minimum_version 1.5.0` and no BW0N warnings fire across the suite (1322 tests at HEAD `6d04842`); regression-prevention extension added to G21 lint test via Amendment block at G26 design-lock."

**What G26 does NOT cover.**
- **Sweep ALL `.bats` files to change the shebang.** Explicit non-goal. The shebang is not deprecated; the sweep G26's goals.md entry mentions would be a no-op against a non-existent upstream deprecation.
- **Add `bats_load_library bats-support`.** Explicit non-goal. The project does not depend on `bats-support`, and adding the load line per #243's suggestion would introduce a new runtime dependency for zero benefit.
- **Backfill `bats_require_minimum_version` into the 58 `.bats` files that lack it.** Explicit non-goal. A file that does not use version-guarded features does not need the declaration; the guard is a feature-presence assertion, not blanket boilerplate. The G21 lint rule extension catches the cases where it IS required (file uses a 1.5.0+ feature) and ignores the cases where it is not.
- **A standalone G26 work product, ship deliverable, or task ID.** No code ships under the G26 ID. The regression-prevention surface ships under G21 (one parallel lint rule, ~30 lines added to G21's lint test file).
- **A shellcheck / pre-commit rule.** Explicit non-goal at this layer. Consistent with G21's C1 sub-decision (CI gate only, no pre-commit hook); the BW02 guard rule rides on the same CI surface.

**Acceptance criteria.**
- G26 is locked at design time as moot / already-fixed; no separate v0.7.2 task ships under the G26 ID.
- The G21 lint test ships with the BW02-guard rule extension specified in G21's Amendment block (one parallel rule in the same lint file, covering the initial pattern set `run --separate-stderr` and extensible from there).
- #243 is closed at design lock (not on ship) with the re-scope note above.
- If, post-implementation, a `.bats` file is added to the suite that uses `run --separate-stderr` (or any other extended pattern) without a `bats_require_minimum_version` declaration, the G21 lint test fails CI — this is the executable acceptance criterion verifying G26's regression-prevention scope is closed.

**Pre-existing plugin issues to file.** Two flagged for v0.7.3 retro observation (not opened as blocking issues this release):
- **PI-G26-001 (Goals phase — premise validation against existing Research).** Issue #243's "BW02 shebang deprecation" claim was already known to be wrong at the time G26 was authored — Q17 web research had landed on disk before the Goals walk-through. A Goals-phase pre-flight check ("for each goal sourced from an external issue, does any existing research finding invert the issue's premise?") would have surfaced G26's mootness before it entered the goal table. Whether this earns a standing checklist item is a v0.7.3 retro question.
- **PI-G26-002 (Disposition flavor #3 — empirical-already-fixed-plus-sibling-extension).** This release now has three distinct flavors of absorption: G24's finding-level reabsorption (4 of 5 R4 findings moot, 1 rescoped), G25's architectural absorption (CD-1 eliminates the surface), G26's empirical-already-fixed-plus-sibling-extension (the work is done; the regression-prevention extension rides on a sibling goal). If the "absorbed by sibling/CD" pattern recurs across releases, the QRSPI goal-lifecycle vocabulary may need standardized disposition labels (see G25's Open Question (b) for the same theme).

**Open Questions for v0.7.3+.** (a) Is the initial BW0N-trigger pattern set (`run --separate-stderr` only, at this design-lock) complete, or do other bats ≥1.5.0 features trigger the same warning class? If new triggers surface in self-host signal during v0.7.2, extend the G21 lint pattern set under a v0.7.3 maintenance addendum rather than re-amending this G26 block. (b) Should the `bats_require_minimum_version` declaration be hoisted to a project-wide minimum (e.g., a CI-level "bats >= 1.5.0" assertion in `bin/run-unit-tests.sh` or similar) instead of per-file declarations? Out of scope for v0.7.2; the per-file pattern is what bats-core upstream recommends and what 46 of 104 files already do — a project-wide minimum would change CI failure shape for older-bats environments. Defer the question to v0.7.3 if older-bats compatibility ever becomes a real constraint.

**References.** Source: goals.md G26 / #243 (BW02 deprecation-warning noise — premise inverted vs. upstream); `research/summary.md` L286-294 + `research/q17-web.md` (Q17 web research that established the correct BW02 semantics — landed pre-Design); `tests/unit/test-codex-splitter.bats` L3-8 (existing `bats_require_minimum_version 1.5.0` guard + rationale comments — the in-tree fix that already silences the warning class #243 was filed against); G21 (this file — Amendment block specifies the lint rule extension that ships the regression-prevention surface); related G21 source #238 / #244 (same bats hygiene goal family); related G25 (this file — same "absorbed by sibling" disposition family, different flavor); closes #243 on design lock with moot/already-fixed note.

---

## G27 — Host- and tier-aware second-reviewer selection (replaces Codex-only inline probe)

**Type:** `known-fix` (scope expanded at design-lock from a 6-line glob fix to a host-relative architecture for second-model review binding to CD-1's host×vendor matrix and G22's tier rubric; the solution space remains bounded — the design locks five concrete deliverables enumerated below). **Source:** goals.md G27 / #253.

**Outcome.** The choice of whether to second-review a primary reviewer is decided per-host (does any third-party vendor exist for this host?) and per-tier (the second-vendor dispatch uses the same agent `tier:` as the primary, flowing through CD-1's `model_routing:` chain). The Goals SKILL no longer inlines a Claude-only filesystem glob; both consumer sites delegate to a small probe script that reads from the same CD-1-owned host×vendor table the dispatcher uses. The vendor-named `codex_reviews:` config field is replaced by a vendor-neutral `second_reviewer:` boolean.

**Plain-language problem.** The Goals SKILL's pipeline-mode dialogue asks "Codex reviews: yes/no?" only when a Claude-specific filesystem glob (`~/.claude/plugins/cache/openai-codex/codex/*/scripts/codex-companion.mjs`) finds a hit. Under Copilot CLI that path does not exist, so the question is silently skipped and `codex_reviews: false` lands in `config.md` as the silent default — even though `check_codex_available copilot-cli` in `scripts/run-codex-review.sh:148-153` correctly returns 0 ("available; task-tool transport is native") and the dispatcher would happily route Codex reviews via the task tool per CD-1's host×vendor matrix. Worse, the same drifted Claude-only glob appears at `skills/using-qrspi/SKILL.md:405` — two sites, one bug, both silently opting Copilot CLI operators out of any second-reviewer review. The bug is host-specific; the deeper problem is vendor naming and tier blindness — the dialogue surface talks about "Codex" specifically (vendor-named, not vendor-neutral) and has no tier dimension at all (a `high`-tier primary reviewer can be paired with whatever default model the Codex companion happens to use, with no principled effort-matching).

**Why this matters.** Every Copilot CLI operator is silently opted out of second-model review today. The v0.7.1 hardening (PR #234) landed the dispatcher-side `check_codex_available copilot-cli` correctly, but did not enumerate the Goals-side consumer as a downstream surface — same v0.7.1 under-scoping pattern G18 tracks. The vendor-named `codex_reviews:` field also locks the architecture into a Codex-only future: under CD-1's universal-dispatch architecture, ANY third-party vendor (DeepSeek, Kimi, future additions) can serve as the second reviewer per host. Hardcoding "Codex" in the user-facing question and in the config schema would force every new vendor addition to either smuggle in under the "Codex" name or require a coordinated rename across SKILLs + config validation + dispatcher. Solving this now (while we are already authoring CD-1's host×vendor matrix and G22's tier rubric) means the second-reviewer surface lands aligned with the architecture v0.7.2 is building; deferring it leaves a vendor-named hole in an otherwise vendor-neutral release.

**Design decisions.**

**D1 — Config schema rename (vendor-neutral, clean break).** Rename the config field `codex_reviews: true|false` → `second_reviewer: true|false`. No alias for the legacy field. The Config Validation Procedure (owned by using-qrspi) treats an unknown `codex_reviews:` as a hard validation error per CD-1's no-silent-fallback rule; the error message names the rename so operators can self-serve the fix (e.g., `[config-error] unknown field 'codex_reviews:' — renamed to 'second_reviewer:' in v0.7.2; update config.md to the new field name`). Rationale: v0.7.x is pre-1.0, breaking config changes ship without deprecation cycles; silent aliasing would defeat the no-silent-fallback rule the rest of the dispatch surface enforces. Optional advanced-operator override: `second_reviewer_vendor: <vendor-id>` forces a specific vendor on hosts where multiple are available.

**D2 — New probe script `scripts/second-reviewer-available.sh` (~15 LOC).** Runs `detect_host` (sourced from `scripts/run-codex-review.sh` via the existing `QRSPI_SOURCE_ONLY=1` guard at L193-205 of that script, OR pulled into a tiny helper in `scripts/lib/` — implementer's choice during Structure/Plan). Looks up the detected host in CD-1's host×vendor matrix (D5). Exits 0 if any third-party vendor exists for this host, exits 1 otherwise. Optionally prints the default vendor identifier to stdout for diagnostic purposes (not consumed by the SKILL; useful for `--verbose` operator runs). Single source of truth = the same matrix the dispatcher reads — there is no parallel table to drift.

**D3 — SKILL prose rewrite (Goals + using-qrspi).** DELETE the Claude-only inline globs at `skills/goals/SKILL.md:120` and `skills/using-qrspi/SKILL.md:405`. REPLACE both with prose that invokes the probe script: "Run `bash scripts/second-reviewer-available.sh`. If exit 0, ask the user 'Second-model review: yes/no?' (with whatever framing the SKILL section uses). If exit non-zero, skip silently and write `second_reviewer: false`." The user-facing question is vendor-neutral — no "Codex" in the question text, no vendor identifier shown to the user (vendor identifiers are not user-meaningful; the dispatcher handles vendor selection at runtime). Both SKILL prose blocks call the SAME script — no copy-paste of host logic, no SKILL-side detection at all.

**D4 — Dispatcher (`dispatch-agent.sh`) owns runtime routing.** For every reviewer-agent dispatch (the existing CD-1 dispatch path):
- Read `second_reviewer:` from `config.md` (canonical or alias-resolved per D1).
- If `false`: emit primary dispatch only — existing CD-1 behavior unchanged.
- If `true`: resolve the second vendor in this precedence order — (a) explicit `second_reviewer_vendor:` config override if present, (b) the per-host default from CD-1's host×vendor matrix's "default second-reviewer vendor" column (D5). If neither resolves to an available third-party vendor for this host, HALT LOUDLY (CD-1's no-silent-fallback rule) with a stderr diagnostic: `[second-reviewer-unavailable] host=<detected_host> requested second_reviewer:true but no third-party vendor available for this host — set second_reviewer:false in config.md or add a model_routing: entry for the desired vendor`. Exit non-zero; do NOT fall back to single-reviewer dispatch silently. (This halt is a defense-in-depth check; the D2 probe should have prevented a `true` value from landing on an unsupported host, but config can be hand-edited.)
- Otherwise emit TWO dispatches via the existing CD-1 path — primary at `(host, primary_vendor, agent_tier)`, second at `(host, second_vendor, agent_tier)`. Both branches use the SAME agent `tier:` (from G22's rubric, default `medium` for reviewer agents). Both branches flow through CD-1's `model_routing:` resolution chain on the per-vendor branch. Per-finding file emission, fan-in, and apply-fix are unchanged — both branches write per-finding files under the existing `reviews/{step}/round-NN/` contract; fan-in tallies both.

**D5 — CD-1 host×vendor matrix extension.** Extend CD-1's existing host×vendor matrix block (this file, L114-121) with one additional column: "Default second-reviewer vendor". The extended matrix becomes the single source of truth read by both the probe script (D2) and the dispatcher (D4). Initial column values (per the existing host×vendor first-party/third-party assignments):

| Host          | Claude        | Codex         | DeepSeek (v0.7.3+) | Default second-reviewer vendor |
|---------------|---------------|---------------|--------------------|--------------------------------|
| Claude Code   | first-party   | third-party   | third-party        | `openai-codex`                 |
| Codex CLI*    | third-party   | first-party   | third-party        | `anthropic-claude` (v0.7.3+)   |
| Copilot CLI   | first-party   | first-party   | third-party        | `openai-codex`                 |

*Codex CLI host support deferred to v0.7.3+ (unchanged from existing matrix footnote).

Rationale for defaults: cost continuity with v0.7.1 behavior (every host pairs against Codex by default, matching today's only-second-reviewer-we-ship); operators who want a different default override via `second_reviewer_vendor:` in config.md. The "second-reviewer vendor must NOT equal the primary vendor on this host" invariant is implicit (the column entries always pick a vendor that is `third-party` for the host or, on Copilot CLI where both Claude and Codex are first-party, pick the non-Anthropic option since Anthropic agents like the Claude reviewer agents themselves are the primary). The dispatcher enforces the invariant at runtime — if `second_reviewer_vendor:` override equals the primary vendor for this dispatch, halt loudly.

**Acceptance criteria.**

- `skills/goals/SKILL.md` no longer contains the inline glob `~/.claude/plugins/cache/openai-codex/codex/*/scripts/codex-companion.mjs`; the pipeline-mode dialogue invokes `scripts/second-reviewer-available.sh` and asks a vendor-neutral question only on exit 0.
- `skills/using-qrspi/SKILL.md` no longer contains the same inline glob at the Codex-detection paragraph; the equivalent prose invokes the same probe script.
- `scripts/second-reviewer-available.sh` exists, is executable, exits 0 on at least one host (Copilot CLI — verifiable by `COPILOT_CLI=1 bash scripts/second-reviewer-available.sh; echo $?`), and reads from CD-1's host×vendor matrix (no separate hardcoded host table).
- `config.md` schema documentation (in using-qrspi) shows `second_reviewer:` as the canonical field; the legacy `codex_reviews:` name is fully deleted from all skill prose and templates; Config Validation Procedure treats a stray `codex_reviews:` as an unknown-field hard error per D1 (with the rename-naming error message).
- `dispatch-agent.sh` reads `second_reviewer:` (or its alias), resolves second vendor per D4's precedence, emits two dispatch entries when enabled, and halts loudly with the D4 diagnostic when no second vendor is available for the host.
- CD-1's host×vendor matrix block carries the "Default second-reviewer vendor" column per D5.
- An end-to-end Copilot CLI smoke test confirms: with `second_reviewer: true` in `config.md`, a Goals review round emits both a Claude reviewer dispatch and a Codex (gpt-5.3-codex) reviewer dispatch via the task-tool transport; fan-in tallies both; per-finding files from both branches land under the round directory.

**What G27 does NOT cover.**

- **Multi-second-reviewer fan-out** (e.g., pairing primary Claude with both Codex AND DeepSeek per round). Out of scope; future v0.7.3+ feature if self-host signal justifies it. Today's design ships one second reviewer per primary.
- **Per-reviewer-agent override of second-reviewer enablement** (e.g., `enable second reviewer for security-reviewer but not for code-quality-reviewer`). Out of scope; the v0.7.2 toggle is run-wide.
- **Telemetry on realized second-reviewer dispatch counts per run.** Natural pairing with G20's `actual_model:` audit field; out of G27's scope but a reasonable v0.7.3 follow-up.
- **DeepSeek (or other v0.7.3+ vendors) as default second-reviewer** for any host. The default-column values in D5 are seeded for v0.7.2's shipping vendor set (Claude + Codex). Future vendor additions update the column.

**Cross-links.**

- **G27 ↔ CD-1.** CD-1 owns the host×vendor matrix (this file, L114-121) and the universal dispatch architecture. G27 extends CD-1's matrix with the "Default second-reviewer vendor" column (D5) and adds the second-reviewer resolution logic to `dispatch-agent.sh` (D4). The schema/architecture authority remains with CD-1; G27 supplies the per-feature wiring CD-1 leaves on the floor.
- **G27 ↔ G22.** G22 authors the per-agent `tier:` rubric. G27 binds the second-reviewer dispatch to the SAME `tier:` as the primary dispatch — both vendor branches use the reviewer agent's declared `tier:` (default `medium`). No new tier knob; the effort dimension is already supplied by G22.
- **G27 ↔ G3.** G3 framed host-relative third-party LLM infrastructure (Claude is first-party on Claude Code, third-party on Codex CLI). G27 is the per-feature consumer of that framing — the second-reviewer question is only meaningful when at least one third-party vendor exists for the detected host.
- **G27 ↔ G18.** G18 / #235 (Plan-phase under-scoping) prevention pattern: the v0.7.1 hardening landed the dispatcher-side `check_codex_available` helper but did not enumerate the Goals-side consumer as a downstream surface. G27 closes the specific instance; G18's mitigation work prevents the next such instance.
- **G27 ↔ G22 (schema-drift pattern).** Same "one canonical source, multiple drifted consumers" pattern G22 sweeps for the `model_routing:` schema. G27 sweeps the same pattern for second-reviewer availability detection. Could share a consumer-enumeration sweep at Structure/Plan time; not bundled into G27.

**Open Questions for v0.7.3+.** (a) Should `second_reviewer:` carry a `mirror-primary-tier` vs `fixed-tier` toggle so operators can intentionally pair a high-tier primary with a cheap second reviewer (cost-conscious cross-check)? Out of v0.7.2 scope; revisit if self-host signal shows operators wanting this knob. (b) Should the second-reviewer fan-out be tier-gated (e.g., automatically skip the second-reviewer dispatch when both primary and second are running at `extra-low`, since the marginal value of a second sub-haiku reviewer is likely low)? Out of v0.7.2 scope; tier-gating logic should land alongside (a) if at all.

**Plugin issues flagged for v0.7.3 retro (not opened at design-lock).**

- **PI-G27-001 (Goals-phase consumer-sweep pattern, recurring).** Three goals this release (G18, G22, G27) all hit the same pattern: a v0.7.1 hardening landed a canonical helper on the dispatcher side but did not enumerate downstream SKILL-side consumers. The recurring pattern suggests a standing checklist for QRSPI's Goals/Design walk: "for each new canonical helper introduced in the prior release, list every SKILL prose site that currently inlines a substitute and enumerate them as drift candidates." Cross-link with G18's intended mitigation.

**References.** Source: goals.md G27 / #253; `skills/goals/SKILL.md` L120 (Claude-only inline glob — drift site 1, deletion target); `skills/using-qrspi/SKILL.md` L405 (Claude-only inline glob — drift site 2, deletion target — not mentioned in goals.md G27 but caught at design-walk audit); `scripts/run-codex-review.sh` L97-191 (`detect_host` + `check_codex_available` canonical helpers + `QRSPI_SOURCE_ONLY=1` guard at L193-205); CD-1 (this file, L19-208 — host×vendor matrix + universal dispatch architecture; D5 extends the matrix block at L114-121); G22 (this file — per-agent `tier:` rubric; G27's second-reviewer dispatch uses the same `tier:`); G3 (this file — host-relative third-party LLM framing); related G18 (this file — Plan-phase under-scoping prevention pattern); related G20 (this file — `actual_model:` audit field for the v0.7.3 telemetry follow-up); closes #253 on ship.

---

## G30 — Compaction-resilient incremental persistence for Goals and Design

**Outcome.** Goals SKILL.md and Design SKILL.md both:
- Author directly to their final artifact (`goals.md` / `design.md`) with `status: draft` as decisions lock — no separate staging file, no end-of-phase transformation step
- Survive `/compact` mid-phase without losing per-decision content
- Run a lightweight "finalize" pass at end-of-phase that validates completeness and flips status to `approved-pending-review`

(Dialogue Conduct rules for both skills are owned by G1 — see G1's deliverables for the verbatim 8-rule section and its Goals/Design application. Rule 5 covers G33's dialog-clarity directive and is Design-only.)

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

**Outcome.** Every QRSPI run that touches prompt prose has the prompt-prose subject to the canonical prompt-design rules at every gate — authoring, classification, and review — regardless of whether the project under development is qrspi-plus itself or any other project a user happens to author prompts for (AI agent system prompts, MCP tool descriptions, internal prompt libraries, RAG instructions, custom skill files for any platform, etc.). Two changes ship together: (1) the rules file is refreshed and relocated to `skills/_shared/prompt-design-rules.md` (renamed from the prior `docs/prompt-design-guide.md`), applying the eight audit findings (A-H) surfaced in G31's "What we know so far"; (2) every QRSPI surface that authors, classifies, or reviews prompt prose — Plan classifier, Plan writer subagents, Design SKILL `<!-- prose-design: ... -->` blocks, lightweight implementer, and the four prompt-prose reviewer agents — is plumbed into a single shared detection-and-application architecture using LLM content-comprehension rather than file-path heuristics. No new reviewer agent is created. No new config knob is introduced. The TDD implementer is deliberately out of scope — prompt prose has no executable behavior, so the TDD path doesn't apply.

**Solution.**

<!-- prose-design: skills/_shared/prompt-prose-detection.md (new file — shared detection snippet) -->
<!-- prose-design: skills/_shared/prompt-prose-writer-addition.md (new file — writer-only addition snippet) -->
<!-- prose-design: skills/_shared/prompt-prose-reviewer-addition.md (new file — reviewer-only addition snippet) -->
<!-- prose-design: skills/prompt-prose-writer/SKILL.md (new wrapper SKILL for agent preload) -->
<!-- prose-design: skills/prompt-prose-reviewer/SKILL.md (new wrapper SKILL for agent preload) -->
<!-- prose-design: skills/_shared/prompt-design-rules.md (refresh in place at new location per A-H below) -->

Architecture: three shared snippet files carry the actual rule content (single source of truth, DRY). Two thin wrapper SKILLs exist solely so agent files — which cannot `!cat` directly — can preload the shared content via the `skills:` frontmatter mechanism. Four inline additions live in specific consumer files (Plan classifier rule, Plan writer-subagent Test-Expectations clause, plan-test-coverage scope guard, design-reviewer per-block addendum); each is a per-consumer refinement, not shared content.

---

#### File 1 — `skills/_shared/prompt-prose-detection.md` (NEW)

Verbatim content:

```markdown
**Prompt prose** is text authored to be loaded into an LLM's context as instructions, system prompts, agent definitions, skill definitions, reviewer rubrics, MCP tool descriptions, RAG instructions, or any equivalent LLM-consumable directive content.

**Detection rule (universal).** Use content semantics, not just file path or extension, as the determining signal. Ask: is the text intended to be loaded into an LLM's context at runtime as instructions? If yes, it is prompt prose, regardless of where it lives in the repo.

**Path and extension as secondary signals (fast-path shortcut for qrspi-plus-internal authoring).** When ALL target files match one of these globs, classify as prompt prose without further inspection:

- `skills/**/SKILL.md`
- `skills/**/*.md` (snippet files under a skill directory)
- `agents/*.md`
- `AGENTS.md`
- `CLAUDE.md`

Files outside these globs require the content-semantic test above. Other projects may carry prompts in `prompts/`, `src/llm-instructions/`, or custom layouts — the content-semantic test is universal; the glob list is qrspi-plus-internal convenience only.

**Examples of prompt prose:**

- A SKILL.md body that instructs an orchestrator.
- An `agents/*.md` file defining a subagent (role, task, constraints, tools).
- A `.md` file under a project's `prompts/` directory whose frontmatter `description:` indicates LLM consumption.
- A verbatim system prompt embedded in any markdown file (e.g., "You are...", "Your role is...", `<HARD-GATE>` blocks).
- A `.txt` or `.json` file whose content is plainly an LLM instruction payload.

**Examples of NOT prompt prose:**

- Code documentation, README files describing features.
- Design decisions in prose form (unless a `<!-- prose-design: ... -->` marker indicates a verbatim prompt-prose block within).
- Research notes ABOUT prompts (this file itself is a meta-document — it IS subject to the rules per meta-acceptance, but ordinary research/explanatory content about prompts is not).
- Configuration files, test fixtures, shell scripts.

**Rules file.** When prompt-prose authoring or review applies, the rules live at `skills/_shared/prompt-design-rules.md` (resolved from the installed plugin path per host convention).
```

Consumers: #1 (`!cat`), #2 (`!cat`), #3 (`!cat`), #4 (via wrapper SKILL preload — File 4), #5-#8 (via wrapper SKILL preload — File 5).

---

#### File 2 — `skills/_shared/prompt-prose-writer-addition.md` (NEW)

Verbatim content:

```markdown
**Writer-side application.** When authoring or planning a deliverable, apply the detection above to the planned target content. If the target IS prompt prose, Read `skills/_shared/prompt-design-rules.md` (resolved from the installed plugin path per host convention) and apply R1-R7 + cross-cutting principles BEFORE drafting, not as post-write polish. The rules shape what to write; patching after the fact is a known anti-pattern.

**If the target is NOT prompt prose** (ordinary documentation, configuration, code, non-prompt prose), do NOT Read the rules file. Reading-without-applying is the verbosity-bias anti-pattern the rules themselves warn against — loading them into context for a deliverable they don't apply to wastes context and risks misapplication.
```

Consumers: #2 (`!cat` after detection), #3 (`!cat` after detection), #4 (via wrapper SKILL — File 4).

---

#### File 3 — `skills/_shared/prompt-prose-reviewer-addition.md` (NEW)

Verbatim content:

```markdown
**Reviewer-side application.** For each file (or sub-block, for blocks within larger documents like `design.md`) in the diff, apply the detection above. Apply liberally — when content semantics indicate prompt prose, treat as in-scope regardless of file path or extension.

For each file or block determined to be prompt prose: Read `skills/_shared/prompt-design-rules.md` (resolved from the installed plugin path per host convention) and apply R1-R7 + cross-cutting principles + finding-type gate. Emit findings using the standard reviewer schema, tagged:

- `change_type: clarity` for verbosity / anchor-phrase / structure-quality findings.
- `change_type: correctness` for finding-type-gate violations (e.g., load-bearing rule placed at start instead of end, examples exceeding the 2-cap, missing Iron-Law markers on override-critical content).
```

Consumers: #5-#8 (via wrapper SKILL — File 5).

---

#### File 4 — `skills/prompt-prose-writer/SKILL.md` (NEW wrapper)

Verbatim content:

```markdown
---
description: Apply prompt-design rules when authoring or planning prompt-prose deliverables. Detects whether a deliverable IS prompt prose, and only then Reads the rules and applies R1-R7 before drafting. Preloaded by agent files that may author prompt prose.
---

# Prompt Prose Writer

!cat skills/_shared/prompt-prose-detection.md

!cat skills/_shared/prompt-prose-writer-addition.md
```

Consumer: #4 (preloaded via `skills:` frontmatter).

---

#### File 5 — `skills/prompt-prose-reviewer/SKILL.md` (NEW wrapper)

Verbatim content:

```markdown
---
description: Apply prompt-design rules when reviewing prompt-prose subjects in a diff. Detects which files (or sub-blocks) are prompt prose, applies R1-R7 + cross-cutting principles + finding-type gate, and emits findings with proper change_type tagging. Preloaded by reviewer agents that may encounter prompt prose in their review subject.
---

# Prompt Prose Reviewer

!cat skills/_shared/prompt-prose-detection.md

!cat skills/_shared/prompt-prose-reviewer-addition.md
```

Consumers: #5-#8 (preloaded via `skills:` frontmatter).

---

#### Addition A — Plan classifier rule (inline in consumer #1)

Verbatim content:

```markdown
**Step 1 — Classify each task as `code` or `lightweight`.** Default `task_type: code`.

Assign `task_type: lightweight` when the task's primary deliverable is prompt prose OR non-prompt prose / docs / config that has no executable behavior to test.

!cat skills/_shared/prompt-prose-detection.md

Apply the detection above to the planned target files. If the target IS prompt prose, classify lightweight. Mixed-deliverable tasks (one prompt-prose file + one code file in the same task) require ALL target files to satisfy the lightweight test; mixed tasks default to `task_type: code` — split per Goal-Specificity rules if genuinely mixed in nature.

The classification gates downstream behavior: lightweight tasks dispatch to `qrspi-implementer-lightweight` (which inherits its own prompt-prose detection via the `prompt-prose-writer` skill preload); code tasks dispatch to `qrspi-implementer` (TDD path). Prompt prose NEVER lands on the TDD path by classification.
```

Placement: `skills/plan/SKILL.md` § Per-Task Classification, REPLACES the current Step 1 paragraph (the existing path-glob-only rule). Steps 2+ continue unchanged after.

---

#### Addition B — Plan writer-subagent Test-Expectations clause (inline in consumer #2)

Verbatim content (appended to the writer-subagent dispatch payload, AFTER the `!cat` of detection + writer-addition):

```markdown
**Test-Expectations clause for prompt-prose tasks.** For tasks classified `task_type: lightweight` because the deliverable IS prompt prose (per Addition A's content-semantic test), Test Expectations cannot be RED-gate failing tests — prompt prose has no executable behavior to verify by test execution. Instead, encode rules-application as the verification mechanism using this template:

> Implementer applies R1-R7 + cross-cutting principles from `skills/_shared/prompt-design-rules.md` (resolved from the installed plugin path per host convention); reviewer (`qrspi-code-quality-reviewer` and/or `qrspi-design-reviewer` per surface in scope) verifies via the same content-semantic rules application; specific findings to verify: [task-specific list of R-rules or principles the deliverable must satisfy].

Other lightweight task categories (non-prompt prose, ordinary documentation, configuration) keep their existing Test-Expectations shape (presence / well-formedness / observable-behavior assertions as appropriate); only prompt-prose tasks carry the rules-application clause.
```

Placement: `skills/plan/SKILL.md` writer-subagent dispatch payload sections (TWO sites — the merged-plan/overview subagent dispatch ~lines 125-132 and the initial-draft per-task sub-subagent dispatch ~lines 439-444 as of v0.7.1). Inserted AFTER the consumer's `!cat detection` + `!cat writer-addition`, BEFORE the rest of the dispatch payload's standard Test-Expectations instructions. The post-approval-split sub-subagent does NOT receive this clause (it carries frontmatter verbatim from the orchestrator-classified wrapped section per `skills/plan/post-approval-split-contract.md`).

---

#### Addition C — plan-test-coverage-reviewer scope guard (inline in consumer #9, standalone)

Verbatim content (added at the TOP of the agent's review-procedure section, BEFORE any existing instructions about evaluating test coverage):

```markdown
**Scope: only `task_type: code` tasks.** Skip evaluation of any task with `task_type: lightweight` — those tasks (prose, prompts, docs, config) have no executable RED gate by design, and applying RED-gate coverage criteria to them would emit false-positive findings ("missing failing test"). The plan-test-coverage-reviewer's domain is the subset of tasks where test execution IS the verification mechanism; for prompt-prose tasks, verification flows through `qrspi-code-quality-reviewer` / `qrspi-design-reviewer` content-semantic rules application, evaluated separately.

Do NOT emit findings about missing tests for lightweight tasks. Do NOT compare lightweight task Test Expectations to RED-gate criteria. Silently skip lightweight task sections.
```

Placement: `agents/qrspi-plan-test-coverage-reviewer.md` body, at the TOP of the review-procedure section (before any existing rubric). Standalone — this consumer does NOT preload `prompt-prose-reviewer` (Q1 resolution: full reviewer block would teach it "sometimes passing means no RED tests" which compromises judgment on `task_type: code` tasks where RED IS required).

---

#### Addition D — design-reviewer per-block scope addendum (inline in consumer #6)

Verbatim content (added to the agent body, AFTER the `skills:` frontmatter triggers preload of `prompt-prose-reviewer` — sits in the agent body's review procedure as a per-surface refinement of the shared addition's general "file or sub-block" rule):

```markdown
**Per-block scope refinement for design.md.** `design.md` typically contains discrete `<!-- prose-design: target -->` HTML-comment markers identifying blocks of verbatim prompt prose destined for an LLM-consumable file. Treat each such marker as one strong signal but not the only one — content semantics determine the call. For each marker:

- If the block's text reads as LLM-consumable directive prose (role+task+constraints, Iron Laws, `<HARD-GATE>` blocks, verbatim rule statements destined for an orchestrator or subagent prompt), apply the rules to that block.
- If the block's text reads as something else (e.g., a shell-script snippet per G4's `<!-- prose-design: scripts/round-prepare.sh -->`), skip rules application for that block.

The marker scopes attention to specific sub-blocks; the surrounding design-decision prose is itself NOT prompt prose and is reviewed by ordinary design-quality criteria, not R1-R7.
```

Placement: `agents/qrspi-design-reviewer.md` body, appended to the review-procedure section AFTER the `skills:` frontmatter has loaded `prompt-prose-reviewer`. Acts as a refinement layered atop the shared reviewer-addition's general "file or sub-block" rule.

---

#### Distribution table (single sweep point for completeness + drift detection)

| # | Consumer file | Gets | How | Placement |
|---|---|---|---|---|
| 1 | `skills/plan/SKILL.md` § Per-Task Classification | Addition A (which itself `!cat`s detection inline) | Permanent inline addition | REPLACES current Step 1 |
| 2 | `skills/plan/SKILL.md` writer-subagent dispatch payloads — 2 sites (~lines 125-132, ~439-444) | detection + writer-addition + Addition B | `!cat` shared content + permanent inline Addition B | AFTER both `!cat`s, BEFORE rest of dispatch payload |
| 3 | `skills/design/SKILL.md` (step where orchestrator authors `<!-- prose-design: ... -->` blocks) | detection + writer-addition | `!cat` of both shared files | At the relevant authoring step |
| 4 | `agents/qrspi-implementer-lightweight.md` | wrapper SKILL `prompt-prose-writer` (carries detection + writer-addition) | `skills:` frontmatter preload | Appended to existing `skills: [implementer-protocol]` list → `[implementer-protocol, prompt-prose-writer]` |
| 5 | `agents/qrspi-code-quality-reviewer.md` | wrapper SKILL `prompt-prose-reviewer` (carries detection + reviewer-addition) | `skills:` frontmatter preload | Appended to existing `skills:` list |
| 6 | `agents/qrspi-design-reviewer.md` | wrapper SKILL `prompt-prose-reviewer` + Addition D | `skills:` preload + permanent inline Addition D | Preload via frontmatter; Addition D in body AFTER preload triggers (refinement layer) |
| 7 | `agents/qrspi-plan-reviewer.md` | wrapper SKILL `prompt-prose-reviewer` | `skills:` frontmatter preload | Appended to existing `skills:` list |
| 8 | `agents/qrspi-plan-spec-reviewer.md` | wrapper SKILL `prompt-prose-reviewer` | `skills:` frontmatter preload | Appended to existing `skills:` list |
| 9 | `agents/qrspi-plan-test-coverage-reviewer.md` | Addition C ONLY (no wrapper SKILL preload) | Permanent inline addition | TOP of review-procedure section |

**Explicit non-consumers (drift guards).**

- `agents/qrspi-implementer.md` (TDD): NOT a consumer. Plan classifies prompt-prose tasks as `task_type: lightweight`, which routes exclusively to the lightweight implementer; TDD path never sees prompt prose.
- `skills/implementer-protocol/SKILL.md` (auto-loaded by both implementer agents): NOT a consumer. Placing the rule there would force the TDD implementer to load it on every dispatch, re-creating the verbosity-bias anti-pattern.
- `skills/plan/post-approval-split-contract.md`: NOT a consumer. Post-approval-split sub-subagents carry frontmatter verbatim from orchestrator-classified wrapped sections per the contract's "carries every field present on the wrapped task section verbatim" clause; classification is the orchestrator's responsibility upstream.

---

**Rules-file relocation and rename.** `git mv docs/prompt-design-guide.md skills/_shared/prompt-design-rules.md` plus content edits (refresh per A-H below) plus reference updates in any consumers that already link to the file. The new location aligns with QRSPI's established convention — `skills/_shared/` is the canonical home for cross-skill technical content (alongside `precondition-block.md`, `tsc-probe-helper.md`, `codex/launch-await-pattern.md`); `docs/` is for human-targeted documentation (release notes, design specs, project READMEs) and is the wrong scope for a runtime contract that agents Read. The rules file travels with the plugin (resolved at runtime from the installed plugin path per host convention — e.g., on Copilot CLI: `~/.copilot/installed-plugins/qrspi-plus/qrspi/skills/_shared/prompt-design-rules.md`; analogous paths on Claude Code and Codex CLI). The file is NOT expected to live in the user's project repo; users developing prompts for their own products get the rules enforced against their work even though their repo doesn't contain them. The rules file is NOT `!cat`-included into any consumer (file is 185+ lines; inlining would balloon every consumer and re-create the verbosity-bias problem the rules themselves warn against) — consumers Read it on-demand when detection fires. The rename from "guide" to "rules" signals enforcement intent in the filename; the file IS rules + decision gates + finding-type classifications, not a tutorial.

**Rules refresh — eight specific updates.** All eight are paragraph-scale prose edits to `skills/_shared/prompt-design-rules.md`. Sub-Rule B authority: intent + anchor phrases below; Implement authors the final wording.

- **(A) Refine the "Positive framing outperforms negative framing" cross-cutting principle.** Recast as: *"Negation works in modern LLMs (Claude 4+, GPT-4+) when paired with (1) a positive substitute, (2) a named antagonist label, and (3) a decision rule. Bare 'do not X' without a substitute is the GPT-3-era anti-pattern. The Iron Laws, Red Flags, and Common Rationalizations sections in QRSPI skills demonstrate the paired pattern in practice."* Anchor phrases: "Negation works in modern LLMs," "paired with positive substitute + named antagonist + decision rule," "bare 'do not X' without substitute is the GPT-3-era anti-pattern."
- **(B) Fold CD-2's six named antagonist patterns into R1.** Under R1's "Cut these categories," add a sub-block titled "Named antagonist patterns (CD-2)" listing: dialogue exhaust, session/drafting notes, version-history narration, inside baseball, compaction-loss recovery notes, failure-modes-prevented lists. Each name carries a one-line definition + a substitute pattern (per CD-2's already-locked table). Anchor: "Named antagonist patterns (CD-2)."
- **(C) Add the Evergreen Litmus Test as a cross-cutting principle.** New principle: *"Litmus test — before writing any paragraph in an artifact governed by `status: draft → approved`, apply the two-question filter: (1) does this paragraph read true if every prior draft were deleted? (2) is the subject the WHAT being designed, or the dialogue that produced it? If either filter fails, the paragraph is dialogue exhaust — strip it."* Cite CD-2 as source. Anchor: "Evergreen Litmus Test," "two-question filter."
- **(D) Add "Anchor phrases" as a cross-cutting principle.** New principle: *"Anchor phrases — when a phrase must be preserved verbatim across edits (e.g., a verbatim Sub-Rule B prose-design block, the locked text in CD-2's Evergreen-Output Rule), call it an 'anchor phrase' in the surrounding prose. Anchor phrases are the audit handles reviewers and authors use to detect silent drift."* Cite G1 Sub-Rule B + CD-2 acceptance criteria as sources. Anchor: "Anchor phrases — verbatim audit handles."
- **(E) Vendor-neutralize R5.** Current R5 opens *"For Claude Code: spine + references saves zero tokens if the spine always instructs the read."* Rewrite to: *"For agent platforms that pre-load skill text (Claude Code, Codex CLI, Copilot CLI, and equivalent hosts): spine + references saves zero tokens if the spine always instructs the read."* G3 vendor-neutrality is the source. Anchor: "agent platforms that pre-load skill text," "Claude Code, Codex CLI, Copilot CLI, and equivalent hosts."
- **(F) Fix source-research paths.** R1's `Source research` section cites `general2/docs/superpowers/specs/2026-04-25-qrspi-skill-refactor-design.md` and `general2/docs/qrspi/2026-04-06-phase4-hooks/phases/phase-02/research/prompt-best-practices.md` — both point outside this repo. Either (a) inline-fold the load-bearing derivations into the rules file and drop the external references, or (b) replace with intra-repo references (the v0.7.2 release docs at `docs/qrspi/2026-05-30-v072-release/research/summary.md` Q1-Q5 if applicable). Implement decides between (a) and (b) based on which preserves more verifiable provenance. Anchor: no external `general2/...` paths.
- **(G) Recalibrate "Last applied" + re-test against May 2026 model landings.** Bump `Last applied:` to the date the refresh ships. Run a single-pass re-test of R1-R7 + cross-cutting principles against the current model lineup (Opus 4.7-high, GPT-5.5, GPT-5.3-Codex, Sonnet 4.6). The test is "for each rule, does the cited evidence still hold at current model capability?" If any rule's evidence has weakened, annotate inline (do NOT remove the rule — the historical evidence still applies to its model era; mark the rule with a "May 2026 status: confirmed | weakened | superseded" line).
- **(H) Add compaction-resilient prompt design as a cross-cutting principle.** New principle: *"Compaction-resilient prompt design — when an orchestrator-driven skill spans enough decisions to risk mid-phase `/compact` firing (Goals, Design at scale), the SKILL.md prose must (1) instruct incremental persistence to the final artifact under `status: draft`, (2) instruct a recovery diagnostic on resume, and (3) instruct the orchestrator to re-read the in-progress artifact to enumerate locked decisions before continuing. Presence ≡ locked (G30); no placeholder bodies (CD-2)."* Cite G30 + CD-2 as sources. Anchor: "Compaction-resilient prompt design," "presence ≡ locked," "no placeholder bodies."

<!-- (Old per-reviewer amendment paragraphs deleted — replaced by the Distribution Table architecture above. The qrspi-code-quality-reviewer and qrspi-design-reviewer now consume the shared reviewer-addition via wrapper-SKILL `skills:` frontmatter preload; the design-reviewer-specific per-block scope refinement stays inline as Addition D in that agent's body.) -->

**Why this architecture.** Five drivers:

1. **Single source of truth via shared snippet files.** The detection logic lives in exactly one file (`skills/_shared/prompt-prose-detection.md`). Every consumer composes from it via `!cat` (SKILL.md surfaces) or via the wrapper-SKILL preload on `skills:` frontmatter (agent surfaces). Hand-copies are forbidden; a single grep sweep verifies absence.

2. **No cross-agent forward references.** Each consumer's body either composes from a shared snippet or preloads a wrapper SKILL. No consumer's body references another consumer's body. The anti-pattern G9 caught for procedural authority (forward-referencing design-doc anchors at runtime) applies symmetrically to cross-agent prompt references — the design-reviewer's original "apply the same content-semantic judgment described in qrspi-code-quality-reviewer's amendment" was exactly that anti-pattern (the design-reviewer cannot Read another agent's body at runtime). The shared-block composition strips it.

3. **Two mechanisms because two surface types.** SKILL.md files process `!cat` at load time on Claude Code (verified via `goals/SKILL.md` `!cat`ing `precondition-block.md`). Agent files do not process `!cat` directly but DO process `skills:` frontmatter preload on Claude Code (verified via `qrspi-implementer.md` + `qrspi-implementer-lightweight.md` both preloading `implementer-protocol`) and on Copilot CLI (verified by `github/copilot-cli` issue #3532 closed 2026-05-26 — Copilot CLI honors agent `skills:` frontmatter, preloads listed skill bodies into the agent's initial context with ordered loading and warnings for unknown skill names). **Host-portability across Copilot CLI is resolved by G32's build pipeline for `!cat`** (build-time expansion delivers fully-resolved SKILL.md and shared-snippet content to every host) **and by host-native support for `skills:` frontmatter** (no build-step transformation needed on Copilot CLI per #3532). Codex CLI behavior on both mechanisms remains unverified — see the Open Question below.

4. **Universal across projects via content-semantic detection.** The classifier and reviewer use LLM content-comprehension to identify prompt prose; path-based heuristics (file globs, extension allowlists, directory conventions) serve only as a fast-path shortcut for qrspi-plus's own layout, not the universal gate. A user authoring prompts in `prompts/foo.md`, `src/llm-instructions/bar.md`, or any custom layout gets correct classification and review without per-project plugin configuration. The shared detection block's content-semantic test ("Use content semantics, not just file path or extension") is the universal contract; path and extension are valid secondary signals but not sole determinants. The path-heuristic-only approach was rejected because (a) it would hardcode qrspi-plus's layout into a rule meant to be universal, (b) it would require either a per-user config field or a treadmill of glob updates as conventions evolve, (c) it cannot catch prompt prose in unconventional locations without ever-expanding glob lists. The dedicated-reviewer alternative (`qrspi-prompt-reviewer`) was rejected because it would add an always-on fanout slot whose cost falls on every Implement round even when zero prompt prose is touched, fragment prompt-quality enforcement across more agents to maintain, and duplicate content-detection logic.

5. **TDD implementer stays out of scope.** Prompt prose has no executable behavior; the TDD path doesn't apply. Plan classifies prompt-prose tasks as `task_type: lightweight`, routing exclusively to the lightweight implementer (the only writer-side consumer of the `prompt-prose-writer` wrapper). The TDD implementer never Reads the rules file — its agent body remains lean, and reading-without-applying (the verbosity-bias anti-pattern the rules themselves warn against) doesn't occur. The plan-test-coverage-reviewer scope guard mirrors this principle on the test-shape side: it stays scoped to `task_type: code` tasks where RED gates ARE required, avoiding the "sometimes passing doesn't mean RED tests" confusion that would compromise its judgment.

**Dependencies + edge cases.**

- Depends on G1 (defines the `<!-- prose-design: target -->` marker that consumer #6's design-reviewer addendum recognizes as one signal).
- Depends on CD-2 (supplies the named antagonist patterns + litmus test for rules updates B and C).
- Depends on G30 (supplies the compaction-resilient prompt-design principle for rules update H).
- Depends on G3 (supplies the vendor-neutrality reframing for rules update E).
- Co-ships with G1, G30, CD-1, CD-2 in v0.7.2.
- Edge case: a task spans mixed deliverables (one prompt-prose file + one non-prompt file). Solution: Plan classifier requires "all target files" satisfy the lightweight test — mixed tasks default to the code path. If genuinely mixed in nature, split per existing Plan Goal-Specificity rules.
- Edge case: a consumer's content-semantic judgment is borderline (file mixes prompt prose with ordinary documentation in one file, or task deliverable mixes both). Solution: judge per-block where structure permits; when ambiguous, default to applying the rules and let the finding-type gate filter false positives. The cost of one extra finding-type-gate evaluation is negligible relative to missed drift.
- Edge case: a `<!-- prose-design: target -->` block in design.md points at a target that is NOT prompt prose (e.g., a code file like `scripts/round-prepare.sh` per G4). Solution: per the consumer #6 addendum, the marker is one signal among many; content semantics determine the call. If a block contains shell-script intent rather than LLM-instruction prose, the reviewer skips rules application for that block. Marker presence alone does not force application.
- Edge case: a user's project has prompt prose in a file extension or layout no consumer has seen (e.g., `.prompt`, `.tmpl`, an XML wrapper). Solution: detection is extension-agnostic by design — if content reads as prompt prose, the rules apply.
- Edge case: a project legitimately wants to author lightweight prose that LOOKS like LLM instructions but is consumed by humans (e.g., a style guide that uses imperative voice). Solution: the content-semantic test asks whether the prose is intended to be LOADED INTO AN LLM'S CONTEXT, not whether it uses imperative voice. A human-facing style guide consumed by humans fails the loading-intent test and routes to ordinary lightweight prose authoring.
- Edge case: pre-existing inbound references to `docs/prompt-design-guide.md` (e.g., from other skill files, reviewer agents, or external links). Solution: as part of the `git mv`, sweep the repo with `grep -rl "docs/prompt-design-guide.md"` and update each reference to the new path + filename. Implement is responsible for the full reference update; G31 acceptance verifies no stale references remain.
- Edge case: the `skills/_shared/prompt-design-rules.md` file is itself in the diff (e.g., the v0.7.2 ship of this very refresh). The reviewer's content-semantic judgment correctly identifies it as a meta-document about prompt prose; per the meta-acceptance below, the reviewer SHOULD apply the rules to it. No special-case in the reviewer instruction needed; the reviewer's semantic judgment handles it.
- Edge case: Plan writer-subagent emits the Test-Expectations clause for a task that is later re-classified (e.g., user amendment changes the deliverable from prompt prose to ordinary doc). Solution: re-classification triggers re-authoring of Test Expectations to match the new category — the clause is keyed off the (current) `task_type` + deliverable content, not historical state.
- Edge case: model-availability variance in reviewer dispatch (per G20). Content-semantic judgment is a baseline reasoning capability across all reviewer-tier models QRSPI currently dispatches; no model-specific carve-out needed.

**Open questions for v0.7.3+ (out of scope for v0.7.2).**

- **[Resolved by G32 — build-pipeline expansion] Host portability of `!cat` directives.** Empirical evidence from this design session (Copilot CLI 1.0.57-1, this run) confirmed Copilot CLI does NOT expand `!cat` directives at SKILL load time — the directive appears as literal text in the loaded SKILL prompt rather than the referenced file's contents. This was observed for both syntactic variants: backtick-wrapped `` !`cat ${CLAUDE_SKILL_DIR}/...` `` (1 site: `goals/SKILL.md` line 8) AND bare `!cat skills/.../owns-defers.md` (7 sites: design / plan / phasing / parallelize / replan / structure / goals SKILLs). **Resolution: G32 (Plugin build pipeline) introduces an install-time `!cat` resolver so plugin installs ship fully-expanded SKILL.md and shared-snippet content to every supported host.** G32 is a hard dependency of G31's Implement phase. The same build-step resolution closes (a) the silently-degraded existing OWNS/DEFERS `!cat` lines in 7 v0.7.1 SKILL.md files, (b) any CD-prescribed shared snippets (`reviewer-dispatch-prose.md`, `evergreen-output-rule.md`, `multi-actor-flow-check.md`), and (c) the G31 architecture's own composition. The OWNS/DEFERS pre-existing degradation will still be surfaced as a separate plugin issue (G32 closes the mechanism; the issue documents the bug history).
- **[Open — v0.7.3+] Codex CLI host portability of agent `skills:` frontmatter preload.** Verified on Claude Code (via `qrspi-implementer.md` + `qrspi-implementer-lightweight.md` preloading `implementer-protocol`) and on Copilot CLI (per `github/copilot-cli` issue #3532, closed 2026-05-26: Copilot CLI honors agent `skills:` frontmatter and preloads listed skill bodies into the agent's initial context with ordered loading and warnings for unknown skill names). **Codex CLI behavior unverified** — both the `!cat` mechanism (relevant to SKILL/snippet body content via the Codex companion's stdin pipeline) and the agent `skills:` preload mechanism need empirical confirmation. If Codex CLI does not honor `skills:` preload, fallback options are: (a) extend G32's build step to inline-expand `skills:` entries into agent bodies at build time for the Codex emit path only (preserves host-portability with no runtime cost), (b) emit explicit Read directives inside agent bodies (works everywhere, costs a tool-call per dispatch). v0.7.2 ships G31 with the host-native `skills:` mechanism (verified on the two primary hosts); v0.7.3+ resolves Codex portability based on investigation findings.
- **Replan analyzer / reviewer integration** (`agents/qrspi-replan-analyzer.md`, `agents/qrspi-replan-reviewer.md`). Replan reads completed-phase artifacts and proposes task changes; if a task being analyzed was a prompt-prose task, the analyzer/reviewer would benefit from prompt-prose framing awareness when classifying change severity and re-authoring task specs. Surfaced here as a known follow-up; not added to the v0.7.2 consumer table to avoid scope creep this release.
- **CI sweep automation for consumer-table drift detection.** The consumer table above is the single source of truth for which surfaces should compose from the shared blocks. A CI script (`scripts/audit-prompt-prose-consumers.sh`) could enforce: (1) every listed consumer has the expected `!cat` line or `skills:` frontmatter entry; (2) no other file in the repo contains hand-copied detection prose (grep for the anchor phrases without the expected composition mechanism). v0.7.2 ships the table; CI enforcement deferred to v0.7.3+.

**Acceptance.**

Shared snippet and wrapper files exist with the expected verbatim content and anchor phrases (cross-reference the per-file content blocks above):

- `skills/_shared/prompt-prose-detection.md` exists with the four anchor phrases: *"text … loaded into an LLM's context as instructions, system prompts, agent definitions,"* *"Use content semantics, not just file path or extension,"* *"fast-path shortcut for qrspi-plus-internal authoring,"* *"skills/_shared/prompt-design-rules.md (resolved from the installed plugin path per host convention)."*
- `skills/_shared/prompt-prose-writer-addition.md` exists with anchor phrases *"apply R1-R7 + cross-cutting principles BEFORE drafting, not as post-write polish"* and the explicit negative *"do not Read the rules file"* for non-prompt deliverables.
- `skills/_shared/prompt-prose-reviewer-addition.md` exists with anchor phrases *"apply liberally — when content semantics indicate prompt prose, treat as in-scope regardless of file path,"* *"change_type: clarity for verbosity / anchor-phrase / structure-quality findings,"* *"change_type: correctness for finding-type-gate violations."*
- `skills/prompt-prose-writer/SKILL.md` exists; body consists of `!cat` of `prompt-prose-detection.md` followed by `!cat` of `prompt-prose-writer-addition.md` (carries detection + writer-addition together for agent preload).
- `skills/prompt-prose-reviewer/SKILL.md` exists; body consists of `!cat` of `prompt-prose-detection.md` followed by `!cat` of `prompt-prose-reviewer-addition.md` (carries detection + reviewer-addition together for agent preload).

Each of the nine consumers in the Distribution table contains the expected composition or preload (per the per-Addition placement specs above):

- Consumer #1 (`skills/plan/SKILL.md` § Per-Task Classification Step 1) contains Addition A verbatim, which itself contains the inline `!cat skills/_shared/prompt-prose-detection.md`. Anchor phrases: *"prose that will be consumed by an LLM agent as instructions, context, or rules at runtime"* and *"fast-path shortcut for qrspi-plus-internal authoring."*
- Consumer #2 (`skills/plan/SKILL.md` writer-subagent dispatch payloads, 2 sites) contains `!cat skills/_shared/prompt-prose-detection.md` + `!cat skills/_shared/prompt-prose-writer-addition.md` + Addition B verbatim. Addition B anchor phrases: *"prompt prose has no executable behavior to verify by test execution,"* *"verified via the same content-semantic rules application."*
- Consumer #3 (`skills/design/SKILL.md` at the authoring step) contains `!cat skills/_shared/prompt-prose-detection.md` + `!cat skills/_shared/prompt-prose-writer-addition.md`.
- Consumer #4 (`agents/qrspi-implementer-lightweight.md`) declares `prompt-prose-writer` in its `skills:` frontmatter alongside the existing `implementer-protocol`.
- Consumers #5-#8 (`agents/qrspi-code-quality-reviewer.md`, `agents/qrspi-design-reviewer.md`, `agents/qrspi-plan-reviewer.md`, `agents/qrspi-plan-spec-reviewer.md`) each declare `prompt-prose-reviewer` in their `skills:` frontmatter alongside the existing `reviewer-protocol`.
- Consumer #6 (`agents/qrspi-design-reviewer.md`) additionally contains Addition D verbatim in its agent body, placed AFTER the frontmatter preload. Anchor phrases: *"one strong signal but not the only one"* and *"content semantics determine the call."*
- Consumer #9 (`agents/qrspi-plan-test-coverage-reviewer.md`) contains Addition C verbatim at the TOP of its review-procedure section. Anchor phrase: *"Scope: only `task_type: code` tasks."* Does NOT declare `prompt-prose-reviewer` in its `skills:` frontmatter (standalone addition, not architecture consumer).

Non-consumer invariants (explicit negative acceptance — protect the architecture from drift toward unwanted consumers):

- `agents/qrspi-implementer.md` (TDD) does NOT declare `prompt-prose-writer` in its `skills:` frontmatter and does NOT contain hand-copied detection prose.
- `skills/implementer-protocol/SKILL.md` does NOT contain `!cat` of any of the three shared snippet files and does NOT contain hand-copied detection prose (DRY enforcement — placing the rule in the shared protocol would force the TDD implementer to load it on every dispatch).
- `skills/plan/post-approval-split-contract.md` is NOT amended (post-approval-split sub-subagents carry frontmatter verbatim from orchestrator-classified wrapped sections; classification is the orchestrator's responsibility, not the sub-subagent's).
- No file outside the listed consumers + shared snippets contains hand-copied detection prose (verified by grep for the anchor phrases).

Rules-file relocation and refresh:

- `skills/_shared/prompt-design-rules.md` exists at the new path; `docs/prompt-design-guide.md` no longer exists; `git log --follow` traces the file history through the rename.
- `skills/_shared/prompt-design-rules.md` `Last applied:` date is bumped to the refresh ship date; all eight updates (A-H) are visible in the file as inline edits (no detached changelog).
- No file in the repo (skills, agents, scripts, tests, docs) contains a stale reference to `docs/prompt-design-guide.md` after the rename completes.

Co-shipped vendor-neutrality cleanup (`!cat` path convention):

- All new `!cat` directives in this work (Files 4 + 5 wrapper SKILLs, Addition A inline cat) use the bare-relative-path convention (`!cat skills/_shared/prompt-prose-detection.md`) matching the dominant 7-of-8 pattern in existing SKILL.md files (`skills/design/SKILL.md`, `skills/plan/SKILL.md`, `skills/phasing/SKILL.md`, `skills/parallelize/SKILL.md`, `skills/replan/SKILL.md`, `skills/structure/SKILL.md`, `skills/goals/SKILL.md` line 26). No `${CLAUDE_SKILL_DIR}` or host-specific path variable is introduced — bare-relative is vendor-neutral (works on Claude Code, Copilot CLI, Codex CLI, and any host that resolves SKILL `!cat` directives from the plugin root).
- Two legacy outliers are converted to the bare-relative convention as part of this work (small, low-risk cleanup; co-ships under G3's vendor-neutrality posture):
  1. `skills/goals/SKILL.md` line 8: `!`​`cat ${CLAUDE_SKILL_DIR}/../_shared/precondition-block.md`​` → `!cat skills/_shared/precondition-block.md`.
  2. `skills/_shared/codex/launch-await-pattern.md` line 45 (the `<!-- Embedded via: ... -->` comment) — update the example in the comment to match the bare-relative convention so future copy-paste users don't propagate the Claude-coupled pattern.
- Post-cleanup grep verification: `grep -rn 'CLAUDE_SKILL_DIR' skills/ agents/` returns no matches.

Smoke tests:

- Positive #1: A SKILL.md change (or equivalent direct prompt-prose change) emits at least one rules-grounded finding from `qrspi-code-quality-reviewer`.
- Positive #2: A `design.md` change containing a `<!-- prose-design: ... -->` block whose content reads as prompt prose emits at least one rules-grounded finding from `qrspi-design-reviewer`; a block whose content is non-prompt (e.g., a shell-script snippet) does NOT emit a rules-grounded finding from the same reviewer.
- Positive #3: The lightweight implementer dispatched for a prompt-prose deliverable Read-evidences `skills/_shared/prompt-design-rules.md` before drafting; the same implementer dispatched for a non-prompt config deliverable does NOT Read the rules file.
- Positive #4: Plan writer subagent emits Test Expectations for a prompt-prose task that cite "R1-R7 application" as the verification mechanism (no RED-gate failing-test expectation).
- Positive #5 (cross-project applicability): a hypothetical user project with prompts under `src/llm-prompts/*.md` (no match against fast-path globs) gets `task_type: lightweight` from Plan via the content-semantic test and triggers prompt-prose review from `qrspi-code-quality-reviewer` based on content alone — no `prompt_prose_paths:` config, no plugin-side glob update.
- Negative #1: a pure code-only change (e.g., a `.ts` or `.sh` file modification with no prompt-prose content) emits zero rules-grounded findings from any reviewer (the content-semantic step short-circuits naturally; no false positives).
- Negative #2: a TDD task (`task_type: code`) does NOT trigger a Read of `skills/_shared/prompt-design-rules.md` from the TDD implementer's dispatch (the conditional Read fires only for the lightweight agent, which never receives `task_type: code` work).
- Meta-acceptance: the refreshed `skills/_shared/prompt-design-rules.md` applied against itself (the reviewer correctly identifies it as a meta-document about prompt prose and applies R1-R7 to it) passes its own audit — the rules must satisfy themselves.

---

## G32 — Plugin build pipeline (strip dev-only paths + expand `!cat` includes)

**Problem.** The plugin source repo and the plugin install artifact have diverging needs that no current build step reconciles: (a) source-only content (`/docs/`, `/reviews/`, `/tests/`, in-progress dossiers) ships verbatim in every plugin install today; (b) maintenance-DRY `!cat` directives in 7 v0.7.1 SKILL.md files (OWNS/DEFERS contracts) silently degrade on Copilot CLI 1.0.57-1 (empirical evidence this design session: both bare `!cat skills/<path>` and backtick-wrapped `` !`cat ${CLAUDE_SKILL_DIR}/...` `` appear as literal text in loaded SKILL prompts, not expanded contents); (c) G31's wrapper-SKILL + inline-`!cat` architecture would face the same degradation if shipped without a build step; (d) `scripts/render-skill.sh` is a 91-line bash "offline cat-emulator" that exists but is not wired into any CI or install hook and only handles the legacy `${CLAUDE_SKILL_DIR}` form. The cumulative effect is that maintenance DRY across SKILL.md (a central tool for keeping scope contracts and shared invariants consistent) is non-portable across the three hosts qrspi-plus is expected to support.

**Approach.** Introduce a Node.js build script at `tools/build-plugin.mjs` that compiles the source repo into a self-contained plugin tree under `build/` (committed alongside source on `main`). The marketplace.json's plugin `source` switches from `"./"` (whole repo) to `"./build"` (relative-path source type, supported by both Claude Code and Copilot CLI for git-installed marketplaces). PR CI runs the build and refuses any PR whose committed `build/` tree does not match the freshly-built output (or whose source contains malformed `!cat` directives). Authors regenerate `build/` locally before each commit; CONTRIBUTING.md documents the loop. The resolver, the manifest-driven copy logic, and the failure semantics are all owned by `tools/build-plugin.mjs`; no other build infrastructure is introduced in v0.7.2.

The cleanup of the existing dev/runtime ambiguity in `scripts/` is co-shipped with G32: two dev-only files (`scripts/render-skill.sh`, `scripts/g4-section-anchor-refresh.sh`) move to a new top-level `tools/` directory, leaving `scripts/` 100% runtime helpers (referenced by skills/agents at runtime) and `tools/` 100% dev-time helpers (build script + maintenance utilities). This makes the build script's allow-list trivially correct: `scripts/` ships in full, `tools/` does not.

### D1 — Output channel: build subdir on `main` with relative-path marketplace source

**Decision.** Build output lives at `build/` in the repo, committed to `main` alongside source. `marketplace.json` is updated so the `qrspi` plugin entry's `source` field becomes `"./build"` (Claude Code "Relative paths" source type; Copilot CLI's mirrored schema accepts the same path-prefixed value).

**Rationale.** Both Claude Code and Copilot CLI install plugins via git (no tarball / release-asset model is supported). Both also support a sparse `git-subdir` source object and a simpler "Relative path within marketplace repo" source. With marketplace and plugin co-located in the same repo, the relative path is the simpler form — no second URL to keep in sync, no separate branch to maintain. Committing `build/` to the same branch as source means: (a) the diff that introduced a source change AND the diff that updated the build artifact land in the same PR (reviewable atomically), (b) there is no cross-branch sync class of bugs, (c) `git blame` works across the source/build seam, (d) reverting a release is one revert commit, not a branch reset. The duplication cost (source `skills/foo/SKILL.md` + built `build/skills/foo/SKILL.md` both in git) is real but bounded — the plugin is small and built output compresses well.

**Alternatives rejected.** Sibling build branch (force-push or merge churn on every release; marketplace.json on `main` referencing a branch elsewhere is an easy out-of-sync class). Tag-versioned branches (marketplace.json must update each release; meta-question of where the version bump itself lives). Tarball / release-asset artifact (not supported by either marketplace as an install source).

### D2 — Strip scope: manifest-driven allow-list (approach iii) with co-shipped `scripts/` cleanup

**Decision.** The build script reads `.claude-plugin/plugin.json` for the component path fields (`agents`, `skills`, `commands`, `hooks`, `mcpServers`, `lspServers`) and copies each declared path into `build/`. In addition, a small fixed top-level include list is hardcoded in the build script: `scripts/` (whole tree, post-cleanup), `templates/` (whole tree), `LICENSE`, `README.md`, `AGENTS.md`, `CLAUDE.md` (when present), and `.claude-plugin/` (manifests). Everything else stays out of `build/` by default — fail-closed.

**Co-shipped cleanup.** Move `scripts/render-skill.sh` and `scripts/g4-section-anchor-refresh.sh` to `tools/` (new top-level directory). Update all callers (tests + docs + this design.md prose) to reference the new path. After the move:

- `scripts/` is 100% runtime helpers referenced by skills or agents at runtime: `codex-companion-bg.sh`, `codex-finding-splitter.sh`, `run-codex-review.sh`, `run-smoke-checks.mjs`, `run-third-party-llm.sh`, `sibling-impact.mjs`, `lib/llm-prompt-utils.sh`, `red-verify/{bats,jest,pytest,vitest}-adapter.sh`, `g4-section-anchor-manifest.json`.
- `tools/` is 100% dev-time: the relocated 2 scripts + the new `build-plugin.mjs`.
- `templates/` (currently `tsc-probe.ts`) is 100% runtime (referenced by skills).

**Rationale.** Manifest-driven gives `plugin.json` authority for "what is this plugin's runtime surface"; future plugin features (new component types) extend the manifest schema, not the build script. The small fixed list covers non-component runtime files that plugin.json doesn't declare (LICENSE, README, host-recognized agent files, manifests). Fail-closed prevents new dev-only paths from leaking into installs by default. The `scripts/` cleanup is a one-time clarification that pays back every future build-script edit (the allow-list is "copy all of `scripts/`" with no per-file enumeration).

**Alternatives rejected.** Explicit allow-list in build script with per-runtime-`scripts/*` enumeration (fragile — new runtime helpers require build-script edits). Deny-list (fail-open — new dev-only content silently leaks if exclusion list isn't updated). Pure manifest-driven without fixed list (LICENSE/README/AGENTS.md/CLAUDE.md aren't in `plugin.json` and would need a schema extension for trivial files).

### D3 — `!cat` resolver semantics: single grammar, fail-loud on every deviation

**Decision.** One supported syntactic form:

```
^\s*!cat\s+<relpath>\s*$
```

where `<relpath>` matches `[A-Za-z0-9_./-]+` and resolves from the **source repo root**. The directive line must occupy the entire line (modulo leading whitespace).

**Behavior.**

- **Recursion: fully transitive.** If `A.md` includes `B.md` and `B.md` includes `C.md`, the resolver expands C inside B inside A in a single pass. Required because G31's wrapper SKILLs `!cat` two snippet files that may themselves grow includes later.
- **Cycle detection: path-based, fail-loud.** Maintain an include-stack during expansion; if a normalized path appears twice in the stack, exit non-zero with the full cycle printed.
- **Output replacement: line-for-line.** The directive line is removed; the included file's content takes its place. No extra blank lines added. Trailing newlines of included content preserved byte-faithfully. CR-stripping (`tr -d '\r'`) on included content (defensive for Windows-CRLF accidents; matches `render-skill.sh` behavior).
- **Idempotence.** Running the resolver on its own output is a no-op — no `!cat` lines remain to expand; running again produces a byte-identical file.
- **No fenced-block syntax.** The legacy ```` ```!` `` fenced form in `render-skill.sh` is unused in source and is dropped from the new resolver.

**Fail-loud conditions (every one of these exits non-zero with file:line + reason):**

- Line begins with `!cat ` (modulo whitespace) but does NOT match the strict grammar — extra args, bad chars in relpath, malformed relpath, etc.
- Any occurrence of `${CLAUDE_SKILL_DIR}` anywhere in a shipped file — defends against the legacy form sneaking back in. The 2 existing legacy sites (`goals/SKILL.md:8` directive + `_shared/codex/launch-await-pattern.md:45` comment) are converted to the bare form as a co-shipped cleanup before G32 ships, leaving zero sites in the repo.
- Target file does not exist.
- Path traversal attempt (any `..` segment resolved outside the source repo root, or any absolute path).
- Cycle detected (full cycle printed).
- Including file is itself outside the source repo root (defensive; should never happen given how the resolver is driven).

**No legacy form supported.** No `${CLAUDE_SKILL_DIR}` form, no fenced syntax. Every existing site converts to the bare form as part of G32's co-shipped cleanup. Going forward, the only mechanism is the single bare grammar.

**Shipped-snippet disposition.** Shared snippet files under `skills/_shared/` (e.g., `prompt-prose-detection.md`, `precondition-block.md`) ARE copied into `build/` (even though after expansion they have no consumers in the install). Rationale: defensive — a misclassified consumer that Reads a shared snippet by path at runtime is a harder-to-debug failure than a slightly larger plugin tree.

**Rationale.** A single grammar with zero ambiguity makes the resolver trivial to implement, trivial to review, and trivial to teach in CONTRIBUTING.md. Fail-loud-on-every-deviation prevents silent drift back toward the legacy form or accidental new dialects. The bare form was already dominant (7 of 8 v0.7.1 sites); converting the 1 outlier is a 2-line patch.

**Alternatives rejected.** Supporting both bare and `${CLAUDE_SKILL_DIR}` forms in the resolver (more code, two paths to maintain, no behavior win once legacy is converted). Fenced-block syntax (unused; adds parser state without benefit). Allowing malformed `!cat` lines to pass through unchanged (silent drift class; one of the v0.7.1 failure modes this release is closing).

### D4 — Implementation language: Node.js

**Decision.** Build script lives at `tools/build-plugin.mjs`, ES modules, Node stdlib only.

**Rationale.** The repo already uses Node for dev tooling: `scripts/run-smoke-checks.mjs`, `scripts/sibling-impact.mjs`, `scripts/lib/codex.mjs`, `scripts/lib/job-control.mjs`, `scripts/lib/state.mjs`, `scripts/lib/tracked-jobs.mjs`. CI already runs Node. Adding one more `.mjs` introduces zero new dev or CI dependencies. The text-munging shape (path resolution, recursion with set-based cycle detection, normalized path comparison, structured error messages with file:line) is straightforward in JS and awkward in bash. Python would also work but introduces a runtime that isn't currently in the repo's dev stack.

**Alternatives rejected.** Extending `scripts/render-skill.sh` in bash (recursion + cycle-stack management in bash is fiddly and hard to unit-test; error messages are awkward). Python script (introduces a new dev dep). Real template engine — Mustache, Jinja2, Liquid (significant overkill given the no-variables decision and the single-grammar resolver).

### D5 — CI gate: PR-blocking sync check

**Decision.** PR CI runs `node tools/build-plugin.mjs` on every PR. After the script exits 0, CI runs `git diff --exit-code build/ .claude-plugin/marketplace.json` — non-empty diff fails the gate.

**Failure modes that block the PR:**

- Build script exits non-zero (any D3 fail-loud condition: malformed `!cat`, missing target, cycle, path traversal, `${CLAUDE_SKILL_DIR}` re-entry, etc.).
- `build/` tree on the PR branch differs from what the resolver produces from current source (author edited source but forgot to regenerate `build/`).

**Author workflow (documented in CONTRIBUTING.md):**

1. Edit source.
2. Run `node tools/build-plugin.mjs` locally.
3. `git add` source changes + regenerated `build/` files together; commit as one logical change.
4. Push; PR CI verifies the source and build are in sync.

**No auto-commit by Actions in v0.7.2.** Keeps CI simple; avoids contributor/bot push races. A pre-commit hook that auto-runs the build is a v0.7.3+ candidate.

**Rationale.** Checking `build/` into git and gating PRs on the diff is the simplest mechanism that guarantees the install artifact is always reproducible from source. No artifact stores, no separate release pipeline, no async bot pushes. The author workflow is one new step (`node tools/build-plugin.mjs`) which is documentable in CONTRIBUTING.md and discoverable via the PR failure message when it's forgotten.

**Alternatives rejected.** Actions auto-commits build/ to PR branch (race conditions; harder-to-reason-about CI). Separate Actions workflow that runs on main and pushes build/ (build/ lags source on the main branch between push and Actions completion — install model would briefly serve stale content). PR-CI verification only (no committed `build/`, regenerated on every install) — would force every install path to depend on the resolver running on the user's machine, which is exactly the host-portability gap G32 is designed to close.

**Marketplace.json change co-shipped with G32.** Today's `marketplace.json` has `"source": "./"` (whole repo). The G32 ship updates it to `"source": "./build"`. The marketplace.json itself stays at `.claude-plugin/marketplace.json` on the repo root (per Claude Code + Copilot CLI convention).

### Acceptance

- `tools/build-plugin.mjs` exists; implements the D3 resolver grammar + recursive expansion + cycle detection + fail-loud conditions + idempotence; implements the D2 manifest-driven allow-list + fixed include list.
- `tools/render-skill.sh` exists at the new location; `tools/g4-section-anchor-refresh.sh` exists at the new location. `scripts/render-skill.sh` and `scripts/g4-section-anchor-refresh.sh` no longer exist. All callers updated.
- Every legacy `${CLAUDE_SKILL_DIR}` site converted to the bare form: `skills/goals/SKILL.md:8`, `skills/_shared/codex/launch-await-pattern.md:45` (comment text). Repo-wide grep for `${CLAUDE_SKILL_DIR}` returns zero hits in shipped files.
- `build/` directory exists on `main` with the full expanded plugin tree. Spot-check: `build/skills/goals/SKILL.md` contains the inlined content of `skills/goals/owns-defers.md` (no `!cat` directives remain); `build/skills/_shared/prompt-prose-detection.md` exists (defensive snippet copy); `build/docs/` does NOT exist; `build/tools/` does NOT exist; `build/tests/` does NOT exist.
- `.claude-plugin/marketplace.json`'s `qrspi` plugin entry has `"source": "./build"` (or equivalent object form). Version bump landed.
- PR CI workflow runs `node tools/build-plugin.mjs` followed by `git diff --exit-code build/ .claude-plugin/marketplace.json`. Failure of either step blocks the PR.
- `CONTRIBUTING.md` documents the author workflow (edit source → run build → commit both).
- Smoke test: `copilot plugin install dfrysinger/qrspi-plus` against a test marketplace registration installs the `build/` tree at `~/.copilot/installed-plugins/qrspi-plus/qrspi/` (no `docs/`, `reviews/`, `tests/`, `tools/` present in the install).
- Acceptance test for the resolver: a fixture file with a `${CLAUDE_SKILL_DIR}`-form directive fails the build with a clear file:line error referencing the legacy-form-not-supported rule. A second fixture with a deliberate include cycle fails with the full cycle printed.

### Open questions for v0.7.3+ (out of scope for v0.7.2)

- **[Open — v0.7.3+] Codex CLI host portability of agent `skills:` frontmatter preload.** Separate from the `!cat` mechanism G32 closes, agent files use `skills:` frontmatter to preload SKILL content at dispatch time. Verified on Claude Code (via `qrspi-implementer.md` + `qrspi-implementer-lightweight.md` preloading `implementer-protocol`, ~25 reviewer agents preloading `reviewer-protocol`, G31's 5 new sites preloading `prompt-prose-writer` / `prompt-prose-reviewer`) and on Copilot CLI (per `github/copilot-cli` issue #3532, closed 2026-05-26 confirming Copilot CLI honors agent `skills:` frontmatter and preloads listed skill bodies into the agent's initial context with ordered loading and warnings for unknown skill names). **Codex CLI behavior unverified.** If `skills:` frontmatter does not fire on Codex CLI, the gap that remains AFTER G32 ships on the Codex emit path is significant: every reviewer-agent and implementer-agent dispatch routed through the Codex companion would lose its preloaded protocol skill (dispatch contract, finding schema, classifier, untrusted-data handling). **Possible v0.7.3+ resolutions:** (a) extend `tools/build-plugin.mjs` to inline-expand `skills:` entries into agent bodies at build time for the Codex emit path (preserves portability with no runtime cost; same architecture as G32 with frontmatter as a new input class), (b) emit explicit Read directives inside agent bodies (works everywhere, costs a tool-call per dispatch and per skill loaded), (c) maintain dual emit paths (host-native preload for Claude Code + Copilot CLI; inlined for Codex CLI) via a build-step flag. v0.7.2 ships G31 + G32 with verified host-native `skills:` preload on the two primary hosts; v0.7.3+ resolves Codex portability once host behavior is empirically confirmed.
- **[Open] Pre-commit hook for `node tools/build-plugin.mjs`.** Convenience for contributors so the PR-CI sync gate never fires for forgotten regen. Out of scope for v0.7.2; depends on per-contributor hook installation convention.
- **[Open] Build-step variable substitution.** G32 ships includes-only by user decision; no variables in v0.7.2. If a future concrete use case emerges (`${PLUGIN_VERSION}`, `${RELEASE_DATE}`, etc.), extend `tools/build-plugin.mjs` with a minimal `${VAR}` substitution pass downstream of `!cat` expansion. Until then, the resolver stays logic-less.

### Pre-existing plugin issues this Design phase surfaces (file post-merge)

- **PI-G32-001 — Existing v0.7.1 OWNS/DEFERS `!cat` lines silently degrade on Copilot CLI.** Seven SKILL.md files (`design`, `plan`, `phasing`, `parallelize`, `replan`, `structure`, `goals`) `!cat` their OWNS/DEFERS contract files; on Copilot CLI the directive appears as literal text in the loaded SKILL prompt, leaving the contract content out of the loaded context. This is a real pre-existing bug, not introduced by v0.7.2. Closed in mechanism by G32 (build-time expansion); the issue documents the bug history for visibility.

**References.** Source: empirical Copilot CLI 1.0.57-1 evidence captured in this design session (`!cat` directives appear as literal text in loaded SKILL prompts for both syntactic variants); G31 BLOCKING open question (resolved by G32); G3 (vendor-neutrality — drives the requirement that every supported host see the same composed semantics); existing `scripts/render-skill.sh` (latent kernel, conceptual ancestor); Claude Code marketplace plugin-source schema docs (`docs.claude.com/en/docs/claude-code/plugin-marketplaces` — relative-path source type, `git-subdir` source type, `ref`/`sha` pinning); Copilot CLI plugin reference docs (`docs.github.com/en/copilot/reference/cli-plugin-reference` — marketplace schema mirrors Claude Code at `.claude-plugin/marketplace.json` fallback path).

---

## G33 — Design skill interactive dialog clarity: simple language + context when presenting ideas

**Solution folded into G1.** G33's design lives inside G1's Dialogue Conduct section as new Rule 5 — *"Use simple language and provide context when presenting ideas."* See G1 Dialogue Conduct (Rule 5 verbatim) + G1 Implementation deliverables (item 2 for Design, item 8 for the Goals mirror exclusion). G33's source directive (user quote during v0.7.2 self-host G14 walkthrough) and the v0.7.3 broader-scoping follow-up are preserved here for traceability:

- **Source directive.** User input during v0.7.2 self-host G14: *"use simple language and provide context when presenting ideas"* + earlier *"using simple language give me the context here, im not following. both the problem and the fix is opaque to me"*.

- **Scope.** Design SKILL only (per user direction *"add a small change to the design skill dialog rules"*). Goals SKILL is NOT updated this release per G1 deliverable 8's exclusion clause. Replan / Phasing / Structure SKILLs are NOT updated (out of scope for v0.7.2).

- **Open Questions for v0.7.3+.** Tracked externally as dfrysinger/qrspi-plus#266 — should the dialog-clarity rule broaden to all interactive skills via a shared snippet? Decision criteria: capture self-host signal from Goals / Replan / Phasing / Structure dialogues — did users hit the same opaque-framing friction in those skills, or is it Design-specific (because Design's per-goal proposals are denser than Goals' problem-frame dialogue)?

- **Acceptance.** All criteria deferred to G1's Acceptance — G1's implementation now carries G33's rule as part of its 8-rule Dialogue Conduct section. The bats regression guard ("the literal phrase 'Use simple language and provide context when presenting ideas' appears in `skills/design/SKILL.md`") rolls into G1's acceptance test set.

- **References.** v0.7.2 self-host G14 walkthrough user directive; G1 Dialogue Conduct Rule 5 (verbatim) + deliverables 2 and 8.

---

## Plugin issues observed during this Design session

- **Q5 under-counted consumer list** — research/summary.md Q5 (line 68) said splitter is not invoked by run-codex-review.sh; missed that implement/SKILL.md is the highest-density consumer (9 invocations + 2 splitter blocks).
- **Backward-loop flag mechanism may be dead code** — never observed in any session. The Pause Gate option 3 cascade may be undiscoverable in practice. Preserved in new architecture (cost is negligible) but worth observability check post-v0.7.2.
- **Design skill encourages "synthesize at end"** with no incremental persistence — risks losing 25+ goal-walkthrough decisions if compaction fires mid-Phase 1. This file is the workaround; the fix is a new design SKILL.md instruction to persist incrementally (could fold into G1's deliverables).
