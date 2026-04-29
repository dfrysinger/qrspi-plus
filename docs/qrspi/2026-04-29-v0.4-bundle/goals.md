---
status: approved
---

# Goals: QRSPI v0.4 Bundle — Methodology Hardening from 2026-04-26 Empirical Run

## Purpose

The v0.4 bundle hardens the QRSPI methodology by addressing twelve issues — most surfaced empirically during the 2026-04-26 prompt-improvements (general5) run (where Integrate rounds 3-5 and Codex round-2 reviews exposed structural defects in the implementer hierarchy, branch namespace, Codex companion contract, and hook enforcement model), the rest follow-on methodology hardening prompted by that work (researcher handoff, prompt-test corpus, commenting style, ID-leakage hygiene). The bundle also treats several methodology assumptions as live hypotheses to test in-session before codifying them.

## Constraints

- Workspace is the qrspi-plus repo itself; artifacts land at `docs/qrspi/2026-04-29-v0.4-bundle/`.
- Pipeline runs in full mode (`goals → questions → research → design → phasing → structure → plan → parallelize → implement → integrate → test`) with Codex reviews enabled.
- Branch model: feature-main is `qrspi/v0.4-bundle/main`; task worktrees fork as `qrspi/v0.4-bundle/task-NN` siblings.
- Existing approved runs under `docs/qrspi/` must continue to resolve correctly during and after this run (backwards-compatible artifact layout).
- macOS sandbox enforcement (Seatbelt) ships out of the box; Linux requires `bubblewrap` + `socat`; WSL1 is unsupported — any sandbox-pivot landing must keep CI green on Linux without forcing a sandbox dependency.
- Codex integration must detect `codex-companion` availability at runtime; CI must remain green without Codex installed, with smoke tests gated on `CODEX_REAL=1`.

## Goals

### G1 — Investigate 3-level Implement subagent hierarchy collapse (#26)

- **type:** `exploratory`

#### Problem

The Implement skill's documented design is 3-level — main chat (L1) dispatches per-task orchestrators (L2), which in turn dispatch implementer + reviewer subagents (L3). Phase-4 of the 2026-04-26 run confirmed that L2 subagents do not have access to the Agent tool in their actual runtime environment and cannot dispatch L3 sub-subagents; the L2 orchestrator reported "the Agent / SendMessage tools are not available in this environment ... I performed the implementer and reviewer roles inline as a single subagent." The 3-level design as documented is uninhabitable in current Claude Code.

#### Why we care

What's lost when L2 collapses to inline single-subagent execution: parallel reviewer dispatch (4 reviewers serialize in one head's reasoning rather than running concurrently in fresh contexts), fresh-context isolation between implementer and reviewers (the same head that wrote the code reviews it — F-31 rediscovered), and Codex reviewers entirely (since `codex:rescue` requires the Agent tool, per-task Codex reviews cannot happen at all). The blast radius is the entire Implement stage: every per-task review pass currently produces architecturally-guaranteed missed defects. Codex round-2 evidence on the same diffs confirmed real, blocking issues missed by the inline pattern.

#### What we know so far

We do not yet know whether L3 dispatch is a hard architectural limit or a permissions/config issue (the Agent tool may be grantable to subagents via `tools:` in the agent definition). Investigation must answer that question first; the fix shape depends on the answer.

- Candidate A — Design should weigh: confirm the Agent tool is grantable to L2 subagents and keep the 3-level design (preferred if feasible).
- Candidate B — Design should weigh: flatten to 2-level — main chat directly dispatches the implementer subagent, then on DONE dispatches 4 correctness + 4 thoroughness reviewer subagents in parallel, aggregates findings, dispatches a separate fix subagent if needed, loops to clean (the canonical answer per F-31 rediscovery if the limit is hard).
- Candidate C — Design should weigh: hybrid — L2 keeps implementer dispatch, L1 picks up reviewer orchestration.

### G2 — Forbid implementer-as-reviewer in templates (#51)

- **type:** `known-fix`

#### Problem

When L2 collapsed to inline single-subagent execution during the 2026-04-26 Wave-1 run (3 tasks, deep mode, 8 reviewers per task), every Claude reviewer approved on first pass with 0 fix cycles — yet independent Codex review on the same diffs flagged real, blocking issues on all 3 tasks (spec gaps, vacuous bats greps, contract drift, hardcoded paths, masked exit codes, broken acceptance fixtures). The "0 fix cycles, all reviewers approved" outcome is the architectural smell guaranteed by collapsing implementer and reviewer into one head; the Codex catches confirmed the smell is real and severe. Templates must explicitly forbid this pattern.

#### Why we care

Without an explicit prohibition, the inline pattern recurs as a "pragmatic shortcut" whenever L3 dispatch fails or is inconvenient, and the architectural defect-detection guarantee is silently lost. The cost is missed defects shipped through the Implement gate undetected — exactly the failure mode F-31 was originally written to prevent.

#### What we know so far

The recommended fix is to explicitly endorse F-16 fix-path (a) in `per-task-orchestrator.md` and add the directive: *"the implementer subagent must NEVER also act as a reviewer — separation of perspective is the design intent."*

- Candidate Design should weigh: a skill-verification e2e covering the dispatch pattern's review-perspective separation, so the inline-collapse failure mode is detectable in CI rather than only in retrospect.
- Note for Design: if G1 lands flatten-to-2-level (its Candidate B / F-16 fix-path (a)) or the hybrid (its Candidate C), main chat dispatches reviewers separately from the implementer and separation of perspective is structurally enforced — this goal collapses to a one-sentence affirmation in templates. If G1 lands keep-3-level (its Candidate A), this directive remains the explicit guardrail against the inline-collapse failure mode. Either way the directive must exist.

### G3 — Propagate `qrspi/{slug}/main` namespace to all skill prompts (#52)

- **type:** `known-fix`

#### Problem

The feature-branch namespace convention `qrspi/{slug}/main` (so `qrspi/{slug}/*` is free for `task-NN` and `stage-after-G{N}` siblings) was never propagated to all skill prompts. As of 2026-04-27, `parallelize/SKILL.md:62` still says `Feature branch: qrspi/{slug}` (flat). When the 2026-04-26 run reached Implement and tried to create `qrspi/prompt-improvements/task-01` as a child of the existing `qrspi/prompt-improvements` feature branch, git refused: `fatal: cannot lock ref ... 'refs/heads/qrspi/prompt-improvements' exists; cannot create 'refs/heads/qrspi/prompt-improvements/task-01'`. The documented namespace is mutually unworkable in git refs.

#### Why we care

Every full-pipeline run hits this at Implement. The current workaround (rename feature branch mid-run, recreate task worktrees) is manual, error-prone, and undocumented. Until propagated everywhere, the namespace convention is silently inconsistent across skills, breaking cross-references in the Branch Model tables and the Code Review Checkpoint diff command.

#### What we know so far

As of 2026-04-27, the `qrspi/{slug}/main` namespace is referenced inconsistently across the skill prompts: Branch Model sections, symbolic vocab tables, Worked Examples, Runtime Resolution sections, Merge Strategy guidance, and Code Review Checkpoint diff commands span `parallelize/SKILL.md`, `implement/SKILL.md`, and `integrate/SKILL.md`. Structure will identify which exact sections need updates.

- Candidate Design should weigh: a skill-verification e2e covering full Implement-with-feature-branch-creation flow on a slug containing a `task-NN` child, to surface this class of namespace-collision failure in CI instead of only in production runs.
- Note for Research: recent prompt updates may have changed the file layout. Research must verify the current state of `parallelize/SKILL.md`, `implement/SKILL.md`, and `integrate/SKILL.md` — including whether the templated branch strings still appear at the cited locations — before Structure scopes the fix.
- Process candidate Design should weigh: a `qrspi:doctor` lint that grep-checks "every F-N reference resolves to a defined F-N entry," to prevent the silent loss of cross-referenced findings that allowed this drift in the first place.

### G4 — Fix Codex companion JSON contract drift in wrapper (#54)

- **type:** `known-fix`

#### Problem

Task 3 of the 2026-04-26 run implemented `scripts/codex-companion-bg.sh` against an invented Codex companion JSON shape. The wrapper and its test stubs use top-level `{ status: ... }` and `{ markdown: ... }`, but the real `codex-companion.mjs` returns `{ workspaceRoot, job: {...} }` for `status --json` (read `.job.status`, not `.status`) and `{ job, storedJob }` for `result --json` (review text at `storedJob.result.rawOutput` with `storedJob.result.codex.stdout` fallback, not top-level `.markdown` or `.text`). Codex round-2 confirmed by reading the real implementation at lines 846-856 (status) and 867-882 plus `render.mjs:401-404` (result).

#### Why we care

Against the real companion, every successful job hits the wrapper's malformed-exit path; every Codex review across QRSPI silently routes through `EXIT_MALFORMED` instead of returning markdown — appearing as "no findings" to callers. This is a critical defect, not an untested assumption: it blocks T11 (the wrapper-call-site sweep) and silently disables every real Codex review until fixed.

#### What we know so far

The wrapper has multiple separately-addressable defects: it reads JSON paths that don't exist in the real companion (`.status` vs. `.job.status`; `.markdown` vs. `storedJob.result.rawOutput`); test stubs encode the same invented shape; the `launch` path masks the real `wait` exit code via `|| true` (around line 214); non-zero `await` paths exit silently without stderr; and the existing concurrency test runs with insufficient writer contention to stress the lockfile path. The operator-specific hardcoded path is the same surface G5 addresses — so any solution to either should compose with the other.

- Candidate Design should weigh: a smoke test that exercises full launch+await against a real Codex job, gated behind a `CODEX_REAL=1` env flag to keep CI green without mandatory Codex availability.

### G5 — Make `CODEX_COMPANION` resolution portable (#55)

- **type:** `known-fix`

#### Problem

The Codex companion wrapper hardcodes `/Users/dfrysinger/.claude/plugins/cache/openai-codex/codex/1.0.4/scripts/codex-companion.mjs` as the default value of `CODEX_COMPANION`. Other operators have a different `${HOME}` and possibly a different version pin. The wrapper works when callers set `CODEX_COMPANION` explicitly, but the default leaks one operator's setup into a shared skill artifact.

#### Why we care

Any operator who runs qrspi-plus without setting `CODEX_COMPANION` explicitly silently fails Codex review setup; this is a cross-operator portability bug in a shared methodology artifact. T11 (the M47 wrapper sweep) cannot wire any skill site into this wrapper until the default path is portable.

#### What we know so far

Three resolution strategies have been identified, with different tradeoffs.

- Candidate A — Design should weigh: `${HOME}/.claude/plugins/cache/openai-codex/codex/*/scripts/codex-companion.mjs` with glob-resolution at call time (latest wins) — most user-friendly.
- Candidate B — Design should weigh: require callers to set `CODEX_COMPANION`, exit nonzero on missing env, no default — most defensive (fail loud).
- Candidate C — Design should weigh: discover via `claude-code` plugin manifest if accessible — most integrated but most coupled.

### G6 — Evaluate whether `state.sh` is justified at all (#56)

- **type:** `exploratory`

#### Problem

`state.sh`'s complexity may not be justified at all — the F-35 duplication surfaced during the 2026-04-26 run is one piece of evidence that the surface drives recurring infrastructure-tax findings. The visible defect: Codex round-2 confirmed two copies of the same "first non-approved step" computation at `state.sh:28` (a helper a task-4 spec invented and the implementer pragmatically created when the spec's named function turned out not to exist) and `state.sh:126` (the inline copy inside `state_init_or_reconcile` that was never refactored). The duplication contradicts task-04's "three tightly interdependent infrastructure files must agree" constraint and creates step-order-drift risk. The original issue framed the fix as deduplication of one helper; this goal broadens the question to whether the file's complexity is needed at all.

#### Why we care

The duplication is the visible symptom; the broader question is whether the complexity that drives it — `state.sh` itself — is justified at all. State manipulation in a shell helper is the source of recurring infrastructure-tax findings (F-35 here, plus hook-layer brittleness more generally). If the answer is "minimum landing = dedupe per #56," we close one defect; if the answer is "maximum landing = remove `state.sh` entirely," we eliminate an entire surface of recurring defects. Investigation reveals which.

#### What we know so far

We have one concrete fix path (dedupe) and one broader hypothesis (removability). Both are on the table.

- Candidate A — Design should weigh: minimum landing — refactor `state_init_or_reconcile` to call `state_compute_current_step`, add unit tests asserting the delegation. Closes the F-35 defect at minimum cost.
- Candidate B — Design should weigh: maximum landing — investigate whether `state.sh` is needed at all (what computations require it that can't be derived from the filesystem layout or `state.json` directly), and remove it if the answer is "none." Eliminates the entire complexity surface.
- Process candidate Design should weigh: a Plan/Structure check that every named function in a task spec exists in the target module or is explicitly in the "Create" set — would have caught the `state_compute_current_step` discrepancy before implementation.

### G7 — Pivot Bash containment to native Claude Code sandbox (#91)

- **type:** `exploratory`

#### Problem

The hook-based subagent wall in `hooks/lib/bash-detect.sh` parses arbitrary shell commands with regex/cursor scanning to detect cd-before-relative-write escapes. Integrate rounds 3-5 of the 2026-04-26 run revealed this is structurally unwinnable: each fix-cycle round closed the residual class visible *that round*, and the next round found another evaluation channel (R3 → literal targets only; R4 → $VAR / pushd / wrapped compounds; R5 → `eval` / `.`/`source` / ANSI-C / quote-blind splitter). Three consecutive MAJOR residuals of the same class. Both Claude security and Codex security independently flagged R5's `eval`-wrapped cd as the next un-closable surface. R6 would patch that and find R7's class.

#### Why we care

Anthropic shipped Claude Code native sandboxing (Seatbelt on macOS, bubblewrap on Linux) in early 2026 — the per-platform integration complexity that originally punted #58 to Icebox is gone. The kernel can enforce what regex cannot enumerate. If the hypothesis "native sandbox covers all hook enforcement (Bash + Edit/Write)" holds, the entire Bash-detection layer collapses to audit-only logging, ~200 LOC of `bash-detect.sh` plus most of pre-tool-use parsing deletes, and issue #24 (Edit/Write role-aware enforcement, currently labeled `blocked` pending this outcome) becomes unnecessary. If the hypothesis only partially holds (sandbox covers Bash but not Edit/Write), #24 remains required for the uncovered tools.

#### What we know so far

The platform's per-tool sandbox coverage is the load-bearing question and is not yet empirically confirmed. Public docs as of round-5 state sandbox covers Bash and child processes; Edit / Write / NotebookEdit still flow through the permission system. This must be verified in-session before commitment.

- Candidate A — Design should weigh: replace `bash-detect.sh` cd-escape detection with sandbox-driven enforcement; configure `sandbox.filesystem.allowWrite` per subagent dispatch to scope writes to `.worktrees/{slug}/{this-task}/`; set `sandbox.allowUnsandboxedCommands: false` to close the auto-disable bypass; keep audit logging; keep the Write/Edit hook (sandbox doesn't cover those tools); drop opaque-interpreter detection.
- Candidate B — Design should weigh: if empirical verification shows sandbox covers Edit/Write as well, collapse the entire hook layer to audit-only and close #24 as obsolete (the broader hypothesis owner wants tested).
- Coverage gaps to plan around: default sandbox boundary is CWD (worktree pattern is a sub-tree); auto-mode known gap where subagents can self-set `dangerouslyDisableSandbox: true` ([anthropic-experimental/sandbox-runtime#97](https://github.com/anthropic-experimental/sandbox-runtime/issues/97)); Linux requires `bubblewrap` + `socat`; WSL1 unsupported.
- The 2026-04-26 run's round-5 review left several residual bypass classes unaddressed (eval/source/ANSI-C splitter handling, opaque-cd `.qrspi/` protection bypasses, `cd \-` escapes, audit-log forensic drift in `head -n1` truncation, orphan-path symlink gaps, sentinel-as-filename collisions). The chosen sandbox candidate moots some of these mechanically (the kernel doesn't care which evaluation channel produced a write target) but not all (audit-log forensics, sentinel collisions live above the kernel boundary) — Design should inventory which residuals each candidate moots versus which remain as separate concerns.

### G8 — Stop leaking internal reference IDs into shipped artifacts (#93)

- **type:** `exploratory`

#### Problem

Implementer subagent prompts and the per-task-orchestrator template reference two distinct classes of identifier when describing what a task is meant to satisfy, and both leak into shipped artifacts:

1. **QRSPI-internal IDs** — goal IDs (e.g., `**G07**`, `**M24**`, `U\d+`), goal names, F-numbers from findings logs (e.g., `F-16`, `F-31`, `F-46`), and task IDs (e.g., `T11`, `M47`). These have no lifecycle outside the QRSPI run that produced them and no meaning to anyone reading the codebase later — they renumber across runs and point at findings docs the consumer can't access.
2. **External task-tracker IDs** — GitHub issue numbers (e.g., `#93`, `#56`), JIRA-style tickets, etc. These have a real external lifecycle, but their appropriate appearance surface is contested by industry best practice: standard in commit messages and PR `Closes #` lines, sometimes useful in code comments as "see #X for context on this workaround" or in test names as regression markers, but generally inappropriate in code identifiers, log strings, error messages, or prompts.

Both classes leak into the codebase today via implementer-prompt language that quotes the identifier directly when describing the work.

#### Why we care

QRSPI-internal IDs rot the fastest — they're scaffolding for one run, useless to readers afterward, and accumulate as silent technical debt. External task-tracker IDs survive longer but still create unwanted coupling between the codebase and a tracker the runtime consumer doesn't have access to. Either class showing up in code identifiers, log/error strings, or prompts is unambiguous noise; the harder calls are comments and test names, where the right policy depends on whether the ID adds meaningful context (rare) or just signals "AI-written / lazy commenting" (common).

#### What we know so far

Likely audit sites: `implement/templates/implementer.md`, `implement/templates/per-task-orchestrator.md`, per-task spec scaffolding, reviewer templates that quote IDs back at the implementer, commit-message guidance and examples in `implement/SKILL.md`, and any "describe what you implemented" prompt that mentions linking back to `goals.md` or upstream issues.

- Candidate A — Design should weigh (strict surfaces): forbid both classes outright in code identifiers, code-level string literals consumed at runtime (logs / error messages / user-facing text), and prompts (`skills/**/SKILL.md`, templates). These surfaces have no defensible reason to carry either class.
- Candidate B — Design should weigh (QRSPI-internal IDs only, broader surface): forbid the QRSPI-internal class everywhere outside `docs/qrspi/` — including comments and test names — since they have zero lifecycle outside the run.
- Candidate C — Design should weigh (external task-tracker IDs in comments/tests): the open question. Best-practice research is needed before commitment. Possibilities to evaluate: (i) forbid entirely (strictest, mirrors the QRSPI-internal class); (ii) allow only as "see #X for context" comments with a stated reason, never as bare references; (iii) allow in test names only when the test is a named regression for a specific incident; (iv) allow freely (loosest). Research should consult mainstream style guides (Google, Microsoft, Linux kernel, language-community guides) for what they actually prescribe.
- Candidate D — Design should weigh (template metadata): move existing `Target satisfies:` / `Goals addressed:` / `Closes #` fields into a task-spec metadata block the implementer reads but does not echo into the diff. PR-level `Closes #` lines remain valid in the PR description; the prohibition is about the *diff*, not the PR body.
- Candidate E — Design should weigh (reviewer check / lint): grep the diff for the union of patterns — `\*\*G\d{2}\*\*`, `\*\*M\d{2}\*\*`, `\*\*U\d+\*\*`, `F-\d+`, `T\d+`, and (if Candidate C lands strict) `#\d+` — flagging occurrences in surfaces that violate the chosen policy. The grep needs careful scoping: `#\d+` has false positives (CSS hex codes, anchor links, user-facing display text); the QRSPI-internal patterns rarely false-positive but `T\d+` may collide with type variables in some languages.

### G9 — Lightweight non-TDD path for prompt/comment/doc-only tasks (#94)

- **type:** `exploratory`

#### Problem

QRSPI's Implement step prescribes a full TDD loop (failing tests → implement → run tests → fix → review rounds) for every task, regardless of what's being changed. For changes without runtime behavior — prompt-only edits to skill SKILL.md text, comment-only edits, documentation prose, config-text — writing a "failing test" is a grep, not a test, and the TDD ceremony around it is pure overhead. A 3-line prompt edit through the full pipeline burns 50k+ tokens for ~30 tokens of actual change.

#### Why we care

Every task spec, implementer dispatch, reviewer round, and fix loop costs context and dollars. Wall time on prompt-only fixes that should take 2 minutes stretches to 20+ when routed through the full pipeline. TDD reviewers asked to evaluate "is the test sufficient?" against a grep assertion either rubber-stamp (review value = 0) or invent objections (review value < 0). This compounds across every prompt-tuning run.

#### What we know so far

A `task_type` field in `tasks/task-NN.md` frontmatter has been proposed with values `code` (default — full TDD), `prompt` (skip TDD; single-pass implementer + single "does this say what it should say" reviewer), `prose` (skip TDD; single-pass; optional human-only review), `config` (skip TDD; schema-validation-only). Plan skill assigns `task_type` from path heuristics; Implement routes per `task_type`. Open design questions remain: should `prompt` tasks get a Claude review pass; how does `task_type` interact with multi-reviewer × N; what's the comment-only diff detection heuristic; what's the override path when Plan misclassifies.

- In-session validation: this run will apply lightweight handling to prompt edits done HERE (G2, G3, G8, G11, parts of G7) before codifying it. The empirical signal from those edits feeds the eventual Design proposal.
- Candidate A — Design should weigh: add `task_type` per the proposal above.
- Candidate B — Design should weigh: a simpler binary `lightweight: true|false` flag without per-type routing, derived solely from path heuristics.

### G10 — Researchers self-summarize; audit Research → Design handoff (#95)

- **type:** `exploratory`

#### Problem

Today's Research stage produces N research reports (`research/q*.md`), and main chat reads each one and writes its own summary to feed downstream stages. Two costs: (1) context burn — main chat ingests the full body of every report just to produce a summary, with 5-10 reports of 2-4k tokens each, that's 10-40k tokens of read-once context that compresses poorly and degrades reasoning for the rest of the pipeline; (2) summary quality drift — main chat hasn't done the research, so it compresses artifacts it just met, missing load-bearing details, over-weighting whatever appears near the top of each report, silently dropping methodology context.

#### Why we care

Design quality depends on whether the designer has access to load-bearing details, not on whether main chat has compressed them well. Two-stage compression (researcher → main chat summary → Design's interpretation) is where the most expensive-to-recover information loss happens. Pushing summary authorship to the source and read-on-demand to the consumer is the cleanest information-flow shape, and the failure mode compounds across every QRSPI run that does research.

#### What we know so far

A two-part proposal exists. Part 1: researcher subagents emit a structured summary block at the top of each `research/q*.md` (TL;DR, key findings, what surprised me, caveats), and main chat's job becomes mechanical aggregation rather than semantic compression. Part 2: audit what currently reaches Design (likely just `research/summary.md`, a summary-of-summaries two layers of compression away from the investigation) and update Design skill text to encourage reading the full relevant reports on demand.

- In-session validation: research subagents in THIS run produce summary blocks → quality is verified empirically → only then is the format codified into the Research skill.
- Candidate A — Design should weigh: the structured summary block shape proposed in the issue (frontmatter + TL;DR + key findings + surprises + caveats + full report).
- Candidate B — Design should weigh: read-on-demand pattern for Design — summary tells you what's there, full report read when a decision depends on details. Surface this to design subagents (architecture-reviewer, etc.) too.

### G11 — Replace "comment aggressively" with WHY-not-WHAT guidance (#96)

- **type:** `known-fix`

#### Problem

Implementer prompts and templates push for "aggressive commenting" with a technical, line-by-line bias. The result is comments that narrate *what the code does* (which the code already says) rather than *why it exists* or *what intent it serves*: `// loop through users` above `for user in users`, `// returns the result` above `return result`, multi-line block comments restating function bodies in English, inline `// increment counter` next to `i += 1`. This produces code that reads slower (eyes filter narration), is harder to maintain (comments rot when code changes), and signals "AI-written" in a way that erodes trust.

#### Why we care

This compounds across every implemented task and affects code quality and reviewability. The bar should be: would a competent reader of this code learn something from this comment that they couldn't get by reading the code itself? If no, the comment shouldn't exist. The current prompt language drives the wrong answer to that question by default.

#### What we know so far

The proposal is to replace the "comment aggressively" language with WHY-not-WHAT guidance (intent / non-obvious constraints / tradeoffs taken / pointers to context / surprises) and pair it with concrete good/bad examples in the prompt. The current directive lives in implementer-prompt and reviewer-prompt surfaces; function-header guidance and at least one acceptance-test fixture would also need to track the new directive's shape. Structure will identify exact edit sites.

- Candidate A — Design should weigh: the exact phrasing proposed in the issue body (intent, constraints, tradeoffs, pointers, surprises).
- Candidate B — Design should weigh: pair with G8's directive style — both are "implementer prompts produce wrong output shape" and may share template surgery.
- Candidate C — Design should weigh: a reviewer-prompt addition like "are comments adding context, or restating the code?" as the enforcement check — composes with G8's grep-based ID-leakage check.

### G12 — Cleanup of brittle prompt-focused unit-test corpus (#98)

- **type:** `exploratory`

#### Problem

qrspi-plus has ~1000 unit tests, many of them prompt-focused (asserting specific wording in skill SKILL.md files, reviewer templates, agent templates). When prompts change — which happens often as the methodology evolves — these tests break, catching wording drift more than real regressions. The brittleness pulls reviewers and TDD ceremony into changes that have no runtime behavior to test, multiplying overhead per prompt edit.

#### Why we care

Prompt changes should be fast. The test-update overhead per prompt edit is large in tokens and wall time. This compounds across every prompt-tuning run. The right disposition depends on (i) how much of the corpus is genuinely useful regression protection vs. wording-drift catchers, (ii) how reliable a lightweight lint can be made, and (iii) whether G9's lightweight path lands strongly enough to make existing tests redundant. Investigation reveals the answer.

#### What we know so far

This is the existing-corpus companion to G9 (G9 builds the new infrastructure; G12 handles the legacy). Four disposition strategies have been identified.

- Candidate A — Design should weigh: bulk delete — remove the entire prompt-focused test corpus, betting that G9's `task_type: prompt` lightweight path is sufficient regression protection going forward.
- Candidate B — Design should weigh: replace with lightweight lint — keep regression protection in the form of grep/AST-like assertions ("this directive phrase still exists somewhere in the skill prose") rather than exact-string matching.
- Candidate C — Design should weigh: leave as-is — accept brittle tests as legacy noise; prompt edits in this run break what they break.
- Candidate D — Design should weigh: hybrid — delete the most brittle (exact-string) tests, keep coarser structural ones.

### G13 — Researcher subagents write their own per-question reports directly

- **type:** `known-fix`

#### Problem

The Research SKILL prescribes per-question researcher subagents writing their own `research/q*.md` files directly to disk; only the synthesis subagent uses the text-return-then-orchestrator-writes pattern (because of the CC 2.1.x guardrail blocking subagent writes to filenames matching `^(REPORT|SUMMARY|FINDINGS|ANALYSIS).*\.md$`). In practice during this run's Research stage, the text-return pattern was over-applied to the per-question files as well — likely as a defensive fallback against the F-8 binary subagent worktree wall — and routed ~200KB of research output back through main chat that then had to re-emit each file via the Write tool. The user observed this on 2026-04-29 ("very slow and context heavy") and asked to revert.

#### Why we care

Research is the highest fan-out subagent stage in QRSPI (typically 10–20 parallel researchers). Text-return compounds cost at the worst time: just before the synthesis subagent needs a clean context to compress everything into `summary.md`, and just before the cross-skill transition to Design. Direct writes by per-question researchers reduce token burn, wall time, and compression-cascade quality loss on every full-pipeline run that does Research.

#### What we know so far

The Research SKILL already prescribes direct writes for `research/q*.md` files; the issue is at the per-researcher dispatch-prompt level (defensive over-fencing) and in operator habits formed around the F-8 subagent wall. The fix is small.

- Candidate A — Design should weigh: tighten per-researcher dispatch language in `skills/research/SKILL.md` (and any explicit fan-out subagent dispatch templates) to make the direct-write path the unambiguous default; reserve text-return for `summary.md` only and call out the CC 2.1.x guardrail as the sole reason that file is special.
- Candidate B — Design should weigh: audit any other fan-out subagent stages where the same defensive over-fencing might have crept in (e.g., per-task implementer batch reporting). Out of scope unless an audit reveals systemic drift.
- Candidate C — Design should weigh: how to interact with G7's sandbox-replaces-hooks outcome — if the F-8 binary wall is replaced by per-tool-grant sandboxing, the defensive fallback rationale weakens further and direct-writes become the obvious default everywhere.

## Cross-Cutting Notes

- **Four hypotheses validated in-session before codification.** This run treats four claims as live hypotheses, tested against actual evidence rather than baked-in commitments: (i) G7 — the native Claude Code sandbox may cover all hook enforcement (Bash plus Edit/Write), not just Bash; (ii) G6 — `state.sh`'s complexity may not be justified, with deletion as the maximum landing; (iii) G10 — researcher subagents emitting their own summary blocks may produce better Design inputs than main-chat compression; (iv) G1 — the 3-level Implement hierarchy may collapse to 2-level via fix-path (a). Each hypothesis's outcome shapes its goal's solution space; Replan or in-flight amendments propagate the outcome to dependent goals.
- **G1 ↔ G2.** G2's scope is contingent on G1's outcome. If G1 confirms 3-level dispatch is feasible (Candidate A), G2 collapses to a one-sentence directive in templates. If G1 lands Candidate B (flatten to 2-level), G2 becomes a structural guarantee that the flattened design enforces. Either way G2's directive must exist as insurance against the inline collapse pattern recurring.
- **G6 ↔ G7.** Both touch hook/state infrastructure. If G7's hypothesis holds and the hook layer collapses to audit-only, the surface that `state.sh` was complicating shrinks correspondingly. If G6 also lands its maximum case (remove `state.sh`), the cascade is significant: most of `hooks/lib/` plus `state.sh` deletes together. Design should evaluate these as a coupled pair rather than independently — landing G7-max without G6-max (or vice versa) leaves the remaining piece without its dependency.
- **G7 ↔ #24.** Issue #24 (Edit/Write role-aware enforcement) is currently labeled `blocked` pending G7's hypothesis outcome. If G7 empirically confirms native sandbox covers Edit/Write in addition to Bash, #24 becomes unnecessary and should close. If G7 confirms sandbox covers Bash only, #24 remains required for Edit/Write and is unblocked from G7's outcome.
- **G9 ↔ G12.** Companion goals. G9 builds the new `task_type` infrastructure; G12 handles the existing brittle prompt-focused test corpus. G12's chosen strategy depends on how strong G9's lightweight path is. Plan/parallelize should not order G12 before G9.
