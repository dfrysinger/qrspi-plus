---
name: goals
description: Use when starting a new QRSPI pipeline run — captures user intent and constraints through interactive dialogue, then synthesizes a problem-framed goals.md
---

# Goals (QRSPI Step 1)

**PRECONDITION:** Invoke `qrspi:using-qrspi` skill to ensure global pipeline rules are in context. (Idempotent on session re-entry. Subagents are exempt — SUBAGENT-STOP in using-qrspi handles that.)

**Announce at start:** "I'm using the QRSPI Goals skill to capture what you want to build."

**If auto-mode is detected** (presence of `## Auto Mode Active` system-reminder), surface before the first interactive step: "This skill is collaborative — turn-by-turn dialogue produces better Goals quality than autonomous execution. Recommend exiting auto-mode (`Shift+Tab` to cycle modes). I'll proceed in either mode if you prefer." Do not force the user out; respect their choice.

## Overview

Capture purpose, environmental constraints, and the per-goal problem frames that downstream skills work against. Runs as an interactive conversation in the main session, then launches a subagent to synthesize the artifact.

Goals is **problem-framed**, not solution-prescribing. Each goal states a problem, why it matters, and what is known. Solution candidates surface in "What we know so far" as **possibilities for Design to weigh** — NOT commitments.

**Prohibition.** Goals does NOT author file maps, phasing decisions, or detailed solution definitions; those are owned by downstream artifacts.

## Goals OWNS / Goals DEFERS

This section is the **single source of truth** for goals.md scope boundaries. It is the locked rule set the scope-reviewer dispatch loads at review time (Read by the `qrspi-goals-scope-reviewer` agent at runtime per its rules-loading procedure). Findings cite this list directly.

### Goals OWNS

- **Project purpose.** One- or two-sentence framing of what is being built and the problem space.
- **Environmental constraints.** Tech stack, compatibility, performance budgets, deployment, timeline — the real-world conditions any solution must respect.
- **Per-goal entries.** Each goal carries:
  - a stable **goal ID** (e.g. `G1`, `G2`, …) that downstream artifacts (questions, research, design, structure, plan, roadmap, future-*) reference,
  - a **`type` field** with allowed values `known-fix | exploratory` (see "Goal Type Field" below),
  - exactly three subsections — **Problem**, **Why we care**, **What we know so far** — and no others.
- **Optional `Cross-Cutting Notes` section.** Top-level only when relationships between goals genuinely cross-cut. Omit when not needed.
- **Solution candidates as possibilities.** Solution IDEAS may appear under "What we know so far" framed as candidates Design should weigh — never as commitments.

### Goals DEFERS

- **Out-of-scope decisions** → eliminated. What isn't a goal isn't in scope. Project-level scope clarifications (if any) belong to Design's Approach where solution scope is decided.
- **Detailed solution definitions** → Design.
- **Acceptance criteria** → Design's per-goal `Acceptance` blocks + Plan's per-task expectations. Goals does NOT enumerate per-goal acceptance criteria.
- **File / component / interface mapping** → Structure.
- **Task specs, LOC estimates, dependencies** → Plan.
- **Phasing decisions, vertical slice authoring, roadmap** → Phasing.
- **Implementation logic, function signatures, assertion text** → Structure / Plan / Implement.

### Permitted Incidental References

The DEFERS list is about *ownership* of decisions, not *mention* of the deferred surface. The following incidental references are PERMITTED and MUST NOT be flagged as boundary violations by the scope-reviewer:

- **User-locked decisions made during Goals dialogue.** When the user explicitly locks a direction during the Goals interactive dialogue, the artifact MAY record that lock under "What we know so far" using a provenance marker such as `Decision locked during this Goals dialogue:` or `User-locked during Goals dialogue:`. Provenance trumps the candidate-framing rule — the user is the authority, and recording the lock truthfully is more important than re-framing it as a candidate. The lock applies only to the goal's framing, not to Design's downstream decisions about how to implement it.
- **Acceptance candidates framed as candidates.** Sentences that surface possible acceptance approaches using candidate verbs (`could include`, `Design should weigh`, `candidate acceptance approach:`) are PERMITTED. Sentences that bind acceptance with imperative verbs (`Acceptance must include`, `Acceptance must measure`) are NOT — those still violate the rule.
- **Cross-goal sequencing intent in Cross-Cutting Notes.** Goals OWNS goal relationships; ordering hints between goals (e.g. "G8 lands last because trimming files G1-G7 edit creates merge churn") are part of expressing those relationships and are PERMITTED in `## Cross-Cutting Notes`. The actual phase boundaries and roadmap are still Phasing's call — Goals records the *coupling rationale*, not the phase decision.
- **One-sentence mechanism sketches in candidate-fix bullets.** A single sentence describing a candidate fix's mechanism (e.g. "validate actual merge-parent SHAs against named task-tip SHA set; halt on mismatch") is PERMITTED. Multi-line shell pseudocode with specific variable names, command flags, or assertion text is NOT — that level of specificity belongs to Structure / Plan / Implement.

The scope-reviewer evaluates the deferred surface against these carve-outs FIRST before flagging a boundary finding. A scope finding is only valid when the artifact crosses the boundary in a way the carve-outs do not permit.

## Goal Type Field

Every goal MUST carry a `type` field with value `known-fix` or `exploratory`, grounded in **Knight risk-vs-uncertainty**:

- **`known-fix`** — *risk*. Well-characterized problem; bounded solution space. Cost-benefit reasoning applies normally.
- **`exploratory`** — *uncertainty*. The problem is partly uncharted; success criteria emerge through investigation. Exploratory goals are **protected from cost-benefit reasoning that would defer them** — value comes from learning that hasn't happened yet. Do NOT drop or down-rank because it "isn't shovel-ready" or "has unclear payoff."

If neither fits, default to `exploratory` and flag the ambiguity under "What we know so far". Do NOT invent a third value.

## Artifact Gating

**Required inputs:** None (this is the first step)

**Before starting:**
1. Create the artifact directory: `docs/qrspi/YYYY-MM-DD-{slug}/` (relative to the project root, not the plugin directory)
   - **Slug generation:** Take the user's first description of what they want to build, extract 2-4 key words, convert to lowercase kebab-case. Examples: "I want to add user authentication" → `user-auth`, "Build a search API for products" → `product-search-api`. If ambiguous, ask the user to confirm.
   - If the directory already exists, ask the user if they want to continue an existing run or start fresh
2. Mark the provisional "Goals" task (created by `using-qrspi`) as `in_progress`.

### Next-Phase Restart Mode

Goals runs in three contexts:

- **Fresh run** — no artifact directory, no `config.md`, no `goals.md`. Run the full Interactive Dialogue + Pipeline Mode Selection.
- **Mid-run resume** — artifact directory exists; `goals.md` may already be `approved`. Validate `config.md` and continue from where the user left off.
- **Next-phase restart (invoked by Replan's minor path)** — a prior phase completed. **Replan auto-populates the draft `goals.md` from `roadmap.md` + `future-goals.md`**: Replan reads `roadmap.md` for the next phase's goal IDs, extracts matching entries from `future-goals.md`, and writes them as the new draft `goals.md` (`status: draft`). `artifact_promote_next_phase` has reset goals/research/design frontmatter to `draft` and deleted phase-scoped files (`structure.md`, `plan.md`, `tasks/`). The `phases/phase-NN/` snapshot exists; `config.md` carries the original route and pipeline.

**Detecting next-phase restart:** all three hold:
- `phases/phase-*/` snapshot directory exists
- `goals.md` exists with `status: draft`
- `config.md` exists with valid `route` and `pipeline`

**Behavior on next-phase restart:**

0. **Fail-closed precondition.** STOP on any failure — do NOT silently dialogue against an empty/partial draft (silent goal loss is the failure mode this guards):
   1. `roadmap.md` exists in the artifact directory.
   2. `future-goals.md` exists.
   3. The auto-populated draft `goals.md` is non-empty and well-formed.
   4. The draft contains ≥1 goal whose ID matches an entry in `roadmap.md`'s next-phase row.

   On failure, surface a concrete diagnostic and ask the user how to proceed (re-run Replan, hand-fix, abort).
1. Skip artifact-directory creation.
2. Skip the Pipeline Mode Selection questions (the existing `config.md` carries `pipeline` and `route`). Still run Config Validation to catch hand-edits.
3. Run a focused Interactive Dialogue against the auto-populated draft: confirm promoted goals match the user's next-phase expectation; capture new constraints (the Replan feedback file `feedback/replan-phase-NN-round-MM.md` is one input).
4. Re-synthesize `goals.md` (subagent) with the auto-populated content + new constraints. Preserve goal IDs from `roadmap.md` so downstream references stay valid.
5. Run the standard Review Round + Human Gate; on approval, write `status: approved` and let the pipeline cascade.

<HARD-GATE>
Do NOT synthesize goals.md until the pipeline mode is selected and config.md is written.
The user must explicitly choose quick fix or full pipeline before synthesis begins.
</HARD-GATE>

### Config Validation (when config.md exists)

If `config.md` already exists (resuming a run), apply the **Config Validation Procedure** in `using-qrspi/SKILL.md`. Goals validates `route`, `pipeline`, `second_reviewer`, `verifier_enabled`, `scope_tagger_enabled`, `visual_fidelity_required`, and (when `pipeline: quick`) `question_budget`.

## Process

### Interactive Dialogue

- **One question at a time** — don't overwhelm
- **Prefer multiple choice** when possible
- Focus on purpose, constraints, the per-goal problem frames
- **Scope check:** If the request describes multiple independent subsystems, flag immediately. Help decompose into sub-projects — each gets its own QRSPI run.

Questions to cover (order follows the conversation):
1. **What are you building?** Core purpose / problem space.
2. **Who is it for?** End users, internal team, API consumers?
3. **What constraints exist?** Tech stack, timeline, compatibility, performance.
4. **What problems are in play, and why do they matter?** Probe each goal's **Problem** and **Why we care** — capture the pain, not the proposed fix.
5. **What is currently known?** Prior attempts, partial diagnoses, candidate solutions — populated under "What we know so far" as **possibilities Design will evaluate**, not commitments.
6. **For each goal, `known-fix` (risk — solution space bounded) or `exploratory` (uncertainty)?** Default `exploratory` when uncertain; flag the ambiguity.
7. **Greenfield or modifying existing code?**

Do NOT ask for per-goal acceptance criteria, file maps, phasing, or "what's out of scope" — those are owned by downstream artifacts.

### Dialogue Conduct

When working a goal with the user, follow these rules.

1. **Open with questions.** Surface your list of open questions for the goal in chat. Work through them with the user one decision at a time.

2. **One question at a time, with a recommended answer.** Each question carries your proposed answer; the user confirms, amends, or rejects.

3. **Ground first, ask second.** Before asking the user any question — your own or one the user has asked back — consult the codebase, then the web. When a question touches industry best practice or external patterns, search the web for cited evidence rather than speculating or punting back. Escalate to the user only when no source surfaces a defensible answer.

4. **When the user asks for your call, provide one.** Give a grounded recommendation (sources per Rule 3) with named tradeoffs. Do not deflect with more questions. If grounding leaves the call indeterminate, say so and name what additional evidence would resolve it.

6. **Sharpen fuzzy language.** When the user uses imprecise vocabulary, propose the canonical term and ask for confirmation before moving on.

7. **Walk every branch of the decision tree, including flow gaps.** For each goal, resolve dependencies one-by-one. Do not move to the next goal until every branch surfaced is decided, explicitly deferred with a written reason, or split out as a separate goal. Branch completeness includes the end-to-end flow between any multi-actor decisions — actors named, operations sequenced, per-step inputs/outputs traced to producer and consumer, loud-failure paths named, context-cost call-out present. A flow with implicit hand-offs is an open branch; close it before moving on.

8. **Lock decisions as they settle.** Write each decision into the goal block under `status: draft` as it is confirmed. Do not accumulate decisions in chat across multiple goals before persisting.

### Incremental Persistence (Direct-to-Artifact Drafting)

Per Rule 8, write each locked goal **directly to `goals.md`** with `status: draft` as confirmed. The draft on disk is the durable record; the chat transcript is not.

**Presence ≡ locked.** The draft is a keyed map. A goal is locked iff its block appears. Tentative bodies, placeholder bodies, `to be filled` markers, TODO markers NEVER enter the draft. If a goal is not fully formed (Problem, Why we care, What we know so far all populated; concrete `type` value), it does not appear. This is the Evergreen-Output Rule applied to incremental persistence.

**Keyed in-place overwrite on re-lock.** Per-goal blocks are keyed by ID (`### G1 — ...`). On re-lock, overwrite in place — do NOT append a duplicate.

**Resume after compaction.** If `/compact` fires mid-phase, on resume:

1. Read the draft `goals.md` from disk and enumerate locked goals.
2. Ask the user whether all desired goals have been articulated. Goals runs before Research and has no upstream inventory to diff against — the user is the only authority on what work remains (the remaining-work computation is a user-driven question at Goals stage, not an inventory diff).
3. Surface the recovery diagnostic verbatim:

   `"Resumed after compaction — last locked decision: GNN (M decisions locked, K remaining). Continuing from G(NN+1)."`

4. Continue from the next unlocked goal.

**End-of-phase finalize pass.** After the walkthrough completes:

- Validate that every locked goal carries the three subsections and a concrete `type` value.
- Optionally append a Purpose section if absent.
- **Only flip status if all validations pass.** On failure, halt, surface, re-enter dialogue.
- Flip frontmatter `status: draft` to `status: approved`. Only the finalize pass writes `approved`; hand-edits mid-phase are forbidden. When the user picks "Approve, skip review", the finalize pass still runs and the reviewer round is skipped.

**Simulated-compaction durability contract.** A simulated compaction at a mid-phase decision (e.g., G15) followed by resume MUST produce a final artifact identical to a no-compaction run. The on-disk draft is the single source of truth for locked decisions; nothing about the chat transcript or in-session working memory is load-bearing across the compaction boundary.

### Pipeline Mode Selection

After intent capture but before synthesizing `goals.md`, ask these questions one at a time:

**Pipeline mode:**
1. Quick fix (goals → questions → research → plan → implement → test)
2. Full pipeline (goals → questions → research → design → structure → plan → parallelize → implement → integrate → test)

**UX step** (only ask if `qrspi:ux` skill exists — glob `~/.claude/plugins/cache/*/qrspi/*/skills/ux/`; skip silently if not found):
1. No UX step
2. Include UX/wireframing step after Design

**Review depth** (only ask when full pipeline is selected):
1. Quick (4 correctness reviewers)
2. Deep (correctness + thoroughness, all 8 reviewers)

**Second-model review** (only ask if a second-reviewer vendor is available — run `bash scripts/second-reviewer-available.sh`; on non-zero exit, skip silently and write `second_reviewer: false`):
1. No second-model reviews
2. Use a second model for second reviews this run

Write `config.md`. The fence below is the **quick-pipeline** writer output. For `pipeline: full`, use the same shape but (a) substitute the full route, (b) substitute `pipeline: full`, and (c) **omit `question_budget` entirely** — that field is `pipeline: quick`-only (caps Research specialist dispatch). Route templates live in `using-qrspi/SKILL.md` → "Route Templates"; UX does not apply to quick-fix. After writing, rewrite the Level 1 pipeline tasks to match.

```yaml
---
created: YYYY-MM-DD
pipeline: quick
second_reviewer: true  # or false
route:
  - goals
  - questions
  - research
  - plan  # quick stops here before implement
  - implement
  - test
verifier_enabled: true  # edit between rounds to disable for the whole run
scope_tagger_enabled: true  # edit between rounds to disable convergence narrowing
visual_fidelity_required: false  # default false unless opted into visual-fidelity binding chain
question_budget: 5
---
```

### Artifact Synthesis

Launch a **subagent** to synthesize `goals.md`.

**Subagent inputs:**
- The existing incremental draft `goals.md` on disk (REQUIRED — source of truth for pre-compaction locked decisions; the subagent MUST merge this draft with new conversation content rather than re-synthesize from conversation alone)
- The conversation content
- This skill's "Goals OWNS / Goals DEFERS" section

**Subagent task:** Produce `goals.md` per the conformance template in `skills/goals/references/goals-md-template.md` (required sections and per-goal subsections, claim-before-evidence ordering, scannable bullets, no "be concise"). Pass the template path to the subagent and instruct it to read the file before drafting.

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

**Iron Rule (template).** No top-level `Out of Scope`, `Success Criteria`, or `Acceptance Criteria` section. What isn't a goal isn't in scope; acceptance is owned by Design's per-goal `Acceptance` blocks and Plan's per-task expectations. Capture user-volunteered exclusions as constraints (when they shape the solution space) or omit them.

**Iron Rule (three subsections — emit all three).** Every goal MUST carry exactly the three subsections `Problem`, `Why we care`, `What we know so far`. Omitting one is a synthesis defect. If the user did not articulate one during dialogue, re-enter dialogue to obtain it — do NOT write a placeholder, partial, or tentative body (presence ≡ locked). Do NOT add a fourth subsection — additional content belongs in `What we know so far` or in a Constraint.

**Iron Rule (type field — concrete value).** Emit ONE concrete value for each goal's `type` — either `known-fix` OR `exploratory`. NEVER emit the alternation literal `known-fix | exploratory` (template placeholder, not valid output). If uncertain, default to `exploratory` and explain under `What we know so far`.

**Solutions-as-possibilities framing.** When the user mentions a candidate fix, transcribe it under "What we know so far" with explicit framing ("candidate Design should weigh" / "possibility for Design to evaluate"). Do NOT promote it to Purpose, Constraints, or a `Solution` subsection.

### Review Round

**Compaction checkpoint: pre-fanout.** Parallel reviewer dispatch (up to four) reads `goals.md` + the agent-embedded reviewer protocol; saturated context multiplies bloat across the parallel set. See using-qrspi `## Compaction Checkpoints`.

Call `TaskCreate({ subject: "Recommend /compact (pre-fanout) — goals", description: "pre-fanout: parallel reviewer dispatch (up to four) reads goals.md. User decides whether to /compact." })`.

Apply the **Standard Review Loop** from `using-qrspi/SKILL.md`. Four reviewer dispatches run in parallel on Goals (two Claude + two Codex when `second_reviewer: true`; two Claude when disabled).

**Dispatch the round through dispatch-agent's high-level entry.** Run `scripts/dispatch-agent.sh --step goals --round ${ROUND} --artifact-dir <ABS_ARTIFACT_DIR>` (plus the per-skill `--output-dir`/`--artifact`/`--agents` flags below). High-level mode invokes `scripts/review-prep.sh` to emit `<ABS_ARTIFACT_DIR>/reviews/goals/round-${ROUND}.diff` and threads `diff_file_path:` into each reviewer prompt; the orchestrator runs no `git diff` Bash redirect of its own. When the artifact directory is not inside a git repository, review-prep skips diff emission and `diff_file_path:` is omitted — reviewers fall back to the wrapped artifact body. When using-qrspi step 12 (ref selection) narrows the base ref, pass `--base-ref "$(cat reviews/goals/round-$((ROUND-1))-commit.txt)"` so review-prep narrows against the prior round's per-round commit SHA (using-qrspi step 12 owns the SHA-format validation and the `anchor-file-missing:`/`sha-format-invalid:` halt directions before the SHA reaches `git diff`); otherwise the dispatch-agent default applies. Scope-tag narrowing (when active) reaches reviewers as `scope_hint:` wrapped between `<<<UNTRUSTED-SCOPE-HINT-START id=scope_hint>>>` / `<<<UNTRUSTED-SCOPE-HINT-END id=scope_hint>>>` markers per the reviewer-protocol Reviewer Dispatch Contract.

Set the per-skill dispatch parameters below, then include the shared reviewer-dispatch prose. Include `*-codex` peer tags in `REVIEW_AGENTS` only when `second_reviewer: true`.

```sh
REVIEW_STEP="goals"
REVIEW_ROUND="${ROUND}"                                  # current review round (NN)
REVIEW_OUTPUT_DIR="<ABS_ARTIFACT_DIR>/reviews/goals/round-${ROUND}/"
REVIEW_ARTIFACT="goals.md"
REVIEW_AGENTS="quality-claude=qrspi-goals-reviewer,scope-claude=qrspi-goals-scope-reviewer,quality-codex=qrspi-goals-reviewer,scope-codex=qrspi-goals-scope-reviewer"
```

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

**Capture each Task return value to disk before draining.** After each Task call returns, write the subagent's reply text (the full Task return string) to `$REVIEW_OUTPUT_DIR/.dispatch/<TAG>.raw` using the `create` tool, where `<TAG>` is the `TAG` value from the corresponding spec line. This is mandatory regardless of whether the subagent appeared to write per-finding files itself. Rationale: when a subagent cannot use the Write tool (read-only sandbox; missing `allowed-tools` entry; tool denial at runtime) it emits findings via the `<<<FINDING-BOUNDARY>>>` stdout contract instead. `await-round.sh` recovers those findings via a universal stdout-fallback that reads `.dispatch/<TAG>.raw` and pipes it through `third-party-finding-splitter.sh`; without the captured `.raw` file the fallback has nothing to work with and the round looks (incorrectly) clean.

After all Task tool calls return AND all `.raw` captures are written (Task tool is synchronous; first-party subagents with working Write tools have already written their per-finding files by this point), drain any third-party background dispatches and finalize the round:

```sh
scripts/await-round.sh --round-dir "$REVIEW_OUTPUT_DIR"
```

`await-round` is no-op-safe — first-party-only rounds still call it; it returns immediately after reading the manifest. It writes a small `$REVIEW_OUTPUT_DIR/.round-complete.json` summary and (for third-party dispatches OR any entry that produced no per-finding files but has a `.dispatch/<TAG>.raw` capture) materializes per-finding files via `third-party-finding-splitter.sh`. It does NOT echo captured subagent payloads (CD-1 #4 output-bound contract).

Then read `$REVIEW_OUTPUT_DIR/.round-complete.json` and the per-finding files as needed for apply-fix. The raw per-reviewer prompt content (assembled by dispatch-agent into `PROMPT_FILE`) never enters the orchestrator's context — only the small spec lines + the small `DISPATCH_FILE` references passed to Task.

### Human Gate

Present the synthesized `goals.md` to the user. **Always state the review status:** "Reviews passed clean in round N" or "Reviews found issues in round N which were fixed but not re-verified."

They can:
- **Approve** → if reviews have not passed clean, note this and ask if they'd like a review loop before finalizing. Then write `status: approved` in frontmatter.
- **Request changes** → write feedback to `feedback/goals-round-{NN}.md` (see using-qrspi Feedback File Format), continue the conversation, and re-synthesize with a new subagent that receives the original inputs + **all** prior feedback files. After re-generation and the review cycle, present:

  > Feedback applied. How would you like to proceed?
  > 1. More feedback (I have additional changes)
  > 2. Single review round (run Claude + Codex once, see findings)
  > 3. Loop until clean (autonomous review cycles)
  > 4. Approve (I'm satisfied, skip reviews)
  >
  > Before responding, consider running `/compact` — context may be saturated.

  Omit option 2 if Codex is disabled in config.md. Omit the "fix issues" options (2 and 3) if there are no issues to fix.

### Terminal State

If the artifact directory is inside a git repository, commit the approved `goals.md`, `config.md`, and `reviews/goals/` (per-round per-reviewer files; see `using-qrspi` → "Commit after approval (when applicable)"). Otherwise skip — the approved frontmatter on disk is the durable record.

**Compaction checkpoint: pre-handoff.** Goals approved; the dialogue transcript and review-loop context are no longer load-bearing — the next skill reads `goals.md` on a fresh context. See using-qrspi `## Compaction Checkpoints`.

Call `TaskCreate({ subject: "Recommend /compact (pre-handoff) — goals", description: "pre-handoff: next skill reads goals.md on a fresh context; dialogue transcript no longer load-bearing. User decides whether to /compact." })`.

**IRON RULE — REQUIRED:** Invoke the next skill in the `config.md` route after `goals` (typically `qrspi:questions`). Do NOT skip the handoff or invoke out of order. The route is locked at run start and the cross-skill transition is where downstream isolation begins (Questions must not see this conversation beyond `goals.md`).

## Red Flags — STOP

- User describes multiple independent subsystems but you're proceeding without decomposition
- Constraints section is empty — every project has environmental constraints (tech stack, timeline, compatibility)
- A goal is missing the `type` field, or carries a value other than `known-fix` / `exploratory`
- A goal carries fewer or more than the three required subsections (Problem / Why we care / What we know so far)
- The draft is being shaped to include a top-level `Out of Scope` or `Success Criteria` / `Acceptance Criteria` section — those concerns are deferred (see Goals OWNS / Goals DEFERS)
- A solution candidate has been promoted from "What we know so far" into Purpose or Constraints (commitment leakage)
- "Similar to what we did before" without specifying what exactly
- Pipeline mode selected without discussing the work's scope (quick fix for something that needs design, or full pipeline for a one-line change)
- Synthesizing goals.md before capturing the per-goal Problem / Why we care / What we know so far frames

## Common Rationalizations — STOP

| Rationalization | Reality |
|----------------|---------|
| "The user already described what they want clearly" | Clear description ≠ complete goals. The per-goal Problem / Why we care / What we know so far frames still need explicit capture. |
| "This is a quick fix, goals are overkill" | Quick-fix mode exists — use it. Even quick fixes need a captured Problem and Why we care. |
| "I should add acceptance criteria so downstream knows when it's done" | Goals does NOT own acceptance criteria — Design's per-goal `Acceptance` blocks and Plan's per-task expectations do. Adding them here pre-commits Design. |
| "I should add an Out of Scope section to prevent creep" | Goals does NOT own out-of-scope decisions. What isn't a goal isn't in scope; project-level scope clarifications belong in Design's Approach. |
| "The scope is obvious" | Obvious scope is where scope creep hides. Write the per-goal Problem clearly so Design can scope its solution against it. |
| "This goal feels exploratory but I can't justify the cost so I'll mark it known-fix" | Cost-benefit reasoning is exactly what the `exploratory` tag protects against. Mark it `exploratory` honestly. |
| "Let me just start the research first" | Research without approved goals means you don't know what you're looking for. |

## Goal Specificity

**Rule:** Each goal must be independently scopeable — moveable between phases without surgery. Bundled goals must be split with their own IDs. **Red flag:** a goal whose **Problem** bundles 3+ distinct problems that could be independently phased. **Late splitting:** classify per amendment severity (Minor / Major / Scope Unknown) — see `replan/SKILL.md`. Present each split as a before/after diff; user decides; update `roadmap.md` with new IDs. **Common rationalization:** "These items are related so they should be one goal" — Related ≠ coupled.

## Worked Example

See `references/worked-example.md` for a good `goals.md` (Rate Limiter for Public API) and a contrastive bad `goals.md` with failure-mode analysis.

## Iron Laws — Final Reminder

The override-critical rules for Goals, restated at end:

1. **Do NOT synthesize `goals.md` until pipeline mode is selected and `config.md` is written.** The user must explicitly choose `quick` or `full`. Synthesis without explicit choice locks the run into a default the user never agreed to.

2. **Each goal must be independently scopeable.** Bundled goals must be split into separate goals with their own IDs — they break Replan's roadmap-driven phase promotion.

3. **Goals is problem-framed, not solution-prescribing.** Each goal carries `type` (`known-fix | exploratory`) and exactly the three subsections — Problem, Why we care, What we know so far. No top-level `Out of Scope` or acceptance-criteria sections. Solution candidates are framed as **possibilities for Design to weigh**. The "Goals OWNS / Goals DEFERS" section is the locked scope contract.

Behavioral directives D1-D4 (encourage reviews after changes, no shortcuts for speed, no time-pressure skips, jargon-free user-facing text) apply — see `using-qrspi/SKILL.md` → "BEHAVIORAL-DIRECTIVES".
