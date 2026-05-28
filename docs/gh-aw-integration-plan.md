# gh-aw integration plan for qrspi-plus

Status: **in progress** (Phase 1 starting).
Working branch: `agent-hotel/gh-aw-integration` (worktree at `agent-hotel/qrspi-plus`, backing clone in `agent-delta/qrspi-plus`).
Owner: `agent-hotel`.

This document is the durable plan-of-record for two related efforts:

- **Track A:** Use [`gh-aw`](https://github.com/github/gh-aw) (GitHub Agentic Workflows) to *review qrspi-plus runs* and ship measurable quality improvements as PRs against qrspi-plus.
- **Track B:** Use `gh-aw` *as the runtime for qrspi-plus itself*, replacing the local skill-chain + `/compact` + shared-FS-worktree model with sandboxed, autonomous, label-driven workflows.

The two tracks share the same gh-aw substrate but have different cadences. Track A ships first because it produces the regression net and evidence base needed to safely restructure the pipeline in Track B.

---

## Why this plan exists

The current qrspi-plus runtime has three structural limits:

1. **Manual context management.** Skills prompt the user to run `/compact` between steps. Easy to forget; cognitive overhead.
2. **Shared-filesystem subagents.** Subagents run in git worktrees on a shared FS, inheriting the parent's environment. Isolation is by convention, not by construction.
3. **No telemetry feedback loop.** Once a run completes, the only artifacts we keep are the produced docs. We have no aggregated signal on which skills produce the most rejections, which reviewer findings recur, or where cost spikes occur.

`gh-aw` directly addresses all three:

- Each workflow run = a fresh AWF sandbox = a guaranteed compaction boundary.
- Per-task workflow runs = per-task containers with independent FS views and network egress allowlists.
- `gh aw logs` / `gh aw audit` + OpenTelemetry export give per-run cost, token, and outcome data for free.

It also enables natively what we already do via shell glue: multi-engine adversarial review (`run-codex-review.sh`, `codex-companion-bg.sh`). Each workflow's `engine:` is just a field; mixing models per role is free.

---

## Track A: gh-aw reviews qrspi-plus and ships improvements

### A0. Data sources we already have (no new instrumentation needed)

Mining these is the unlock for measurable output-quality improvements.

| Source | Where | What it tells us |
|---|---|---|
| Review corpora | `reviews/plan-NNN/round-NN-{claude,codex}.md` + `.qrspi/` sidecars | Round-to-resolution distribution; recurring finding fingerprints; inter-reviewer disagreement clusters; sticky findings |
| Artifact corpora | Per-run `goals.md`, `questions.md`, `research/summary.md`, `design.md`, `phasing.md`, `roadmap.md`, `structure.md`, `plan.md`, `tasks/task-NN.md`, `parallelization.md`, `fixes/`, plus task-branch diffs | Goal drift across rounds; acceptance criteria leakage from `goals.md`; plan-vs-structure file-list mismatch; phase boundary correctness |
| Chat transcripts | `~/.copilot/session-state/<id>/`, `~/.claude/projects/<project>/*.jsonl` | Human-intervention clusters; tool-call efficiency per skill; token cost per skill per task; backtrack-and-retry signatures |

**Convergence signal already exists:** an empty (~12 byte) terminal review file like `reviews/plan-109/round-05-claude.md` is the implicit APPROVED state. Detect this pattern; compute time-to-convergence.

### A1. Phase 1 — Corpus analyzer (this week)

**Ship:** `.github/workflows/corpus-analyzer.md` (gh-aw workflow).

**Scope:**
- Triggered weekly + on `corpus:run` label.
- Reads `reviews/**` from the qrspi-plus repo (no external corpus yet).
- `mcp-scripts` tools:
  - `analyze-rounds` (Python): per-run rounds count, reviewer set, convergence signal, file paths.
  - `cluster-findings` (JS, calls gpt-5 via the Copilot gateway per the *Gateway & secrets convention* below): cluster reviewer findings by structural type, return frequency + producer-fix suggestions.
- Designer agent (Claude Opus): cross-references each cluster against the corresponding artifact and the relevant `skills/<step>/SKILL.md` or `agents/qrspi-<step>-reviewer.md`. Categorizes each as producer / reviewer / spec problem.
- Files up to 8 issues labeled `corpus-finding` + `prompt-improvement`, each with:
  - cluster name, frequency, 3 verbatim quotes
  - inferred category (producer / reviewer / spec)
  - proposed exact diff against the relevant skill/agent file
  - back-links to source corpus files for verification

**Out of scope for Phase 1:** external corpus collection, user-submitted tarballs, smoke validation of proposed diffs.

**Success criteria:**
- Runs end-to-end against `reviews/plan-109/` only.
- Produces at least 3 issues whose proposed diffs survive human review.

### A2. Phase 2 — Dogfood smoke runs (Week 2)

**Ship:** `.github/workflows/smoke-run.md` + `tests/fixtures/scenarios/{quick-fix-typo, full-pipeline-feature}/`.

**Scope:**
- Scheduled weekly + on `workflow_dispatch`.
- Pinned engine version per scenario to detect prompt regressions vs engine regressions separately.
- Runs the actual qrspi-plus pipeline inside an AWF container against each scenario.
- Captures full `.qrspi/` directory + transcript as workflow artifacts.
- Diffs against the most-recent-accepted golden artifact set using a **semantic diff** (LLM analyzer), not `git diff` exit code. Two valid `plan.md` outputs can differ in wording but have the same tasks with the same test expectations.
- Output: issue with side-by-side diff + recommended revert PR if regression confirmed.

**Pair with Phase 1:** every `prompt-improvement` PR runs smoke before merge.

### A3. Phase 3 — Corpus submission (Week 3)

**Ship:** `qrspi corpus submit --since YYYY-MM-DD` script + analyzer extended to consume tarballs.

**Scope:**
- One-line bash script: tar `~/.copilot/session-state/<recent>/` + `./.qrspi/` + `./reviews/`, sanitize, upload to a gist, file an issue labeled `corpus:run` with the gist URL in the body.
- Sanitization on-machine before upload: strip secret-like patterns, redact `$HOME` paths, drop files referencing non-whitelisted repo names.
- `--dry-run` prints what would be uploaded.
- Analyzer workflow handles `corpus:run` label by downloading + extracting + analyzing the tarball.

**Recruit:** self first, then 1-2 friendly users.

### A4. Phase 4 — Adopt issue-autofix policy primitive (Week 4)

**Ship:** `.github/policy.yml` + one tier worker proof.

**Borrow from:** [`github/issue-autofix`](https://github.com/github/issue-autofix) (existing dfrysinger POC).

**Adapt classes for qrspi-plus:**
- `prompt-fix` → tier-trivial (gpt-5-mini, ~400K tokens, auto-merge on)
- `skill-restructure` → tier-substantial (sonnet-4.6, 2M tokens, human review)
- `agent-add` → tier-moderate (sonnet-4.5, 1.5M tokens)
- `scenario-add` → tier-small (gpt-5-mini, 1M tokens)
- `corpus-investigation` → tier-substantial (sonnet-4.6)
- `integration-bug` → tier-large (opus-4.7)

**Steal directly:**
- `policy.yml` primitive.
- Layer 1 fan-out (planner → N area workers → reconciler).
- LLM-decider / native-executor split for safe merges.
- `audit.jsonl` ledger.
- Canary harness.
- `policy:auto-merge-nudge` cron reconciler for the GHA anti-recursion glitch.

### A5. Phase 5-6 — qrspi-assist (Weeks 5-6)

**Ship:** `.github/workflows/qrspi-assist.md` — a fork of [`githubnext/agentics/repo-assist`](https://github.com/githubnext/agentics/blob/main/docs/repo-assist.md) routed through the Phase 4 policy primitive.

**Steal from repo-assist:**
- Weighted task selection driven by live repo state.
- Memory-backed oldest-first cursor (prevents re-spamming).
- "Silence is preferable to noise" baseline.
- Monthly activity issue.
- 4-open-PR cap (tuned down from repo-assist's 8 for solo maintenance).
- `/qrspi-assist <instruction>` slash command for on-demand steering.
- AGENTS.md read-first rule (already a norm).
- AI transparency disclosure.

**Custom tasks on top of repo-assist's baseline 11:**

| Task | Weighted high when | Tier hint |
|---|---|---|
| Apply corpus-finding fix | `corpus-finding` issues exist with proposed diff | small or moderate |
| Rerun smoke after skill change | recent merge touched `skills/**` | trivial |
| Investigate prompt regression | smoke failed in last 24h | substantial |
| Promote corpus finding to skill change | `corpus-finding` issue has 3+ confirming examples | moderate |
| Reconcile reviewer disagreement | analyzer flagged disagreement cluster | substantial |
| Author new test scenario | bug fixed without scenario coverage | small |

### A6. Phase 7-8 — Compound loop (Weeks 7-8)

**Ship:** end-to-end automated loop where corpus → assist → policy → smoke → auto-merge all wire together.

**Concrete first compound run:** reviewer disagreement reconciliation.
- Analyzer flags inter-reviewer disagreement cluster.
- qrspi-assist generates issue with proposed reviewer-spec clarification.
- Tier-moderate worker writes PR.
- Smoke validates against scenarios.
- Auto-merge if green and `auto-merge` label set.

---

## Track B: gh-aw as the runtime for qrspi-plus (future)

Deferred until Track A is stable. Captured here so we don't lose the structural design.

### B1. Conceptual mapping

| qrspi-plus concept | gh-aw equivalent | Win |
|---|---|---|
| Skill (a phase) | One workflow `.md` file | Compile-time validation, audit |
| Fresh subagent per step | Fresh AWF sandbox per run | True isolation; no `/compact` |
| `/compact` prompts | Deleted | Container = compaction boundary |
| Subagent worktrees | Per-task workflow runs + `push-to-pull-request-branch` | No cross-task contamination |
| Human approval gate | Label flip on tracking issue, or PR review | Visible in GitHub UI |
| Research isolation (no goals leak) | Workflow downloads only `research/*` artifacts | Structural, enforced |
| Dual reviewer (claude-opus + gpt-5.5) | Two parallel review workflows with different `engine:` | Native multi-engine |
| 7-parallel-reviewer plan-quality | 7 mcp-script tool calls in one designer session (preserved context), OR 7 parallel review workflows + fan-in | Either works |
| `parallelization.md` Branch Map | `job-discriminator` matrix + per-task dispatches | Real Actions parallelism |
| Batch gate | Integration workflow with mcp-script polling sibling labels | Same semantics |

### B2. Tracking-issue-as-state-machine pattern

One tracking issue per qrspi run. Labels = state. Comments = artifact summaries. Sub-issues = tasks. PRs = task branches + integration PR. Every workflow:
- Triggers on `issues.labeled` with the next state.
- Reads prior artifacts from linked sub-issues / attached artifacts.
- Produces its artifact (commit to repo on `qrspi/<issue-num>/<step>` branch, or attach as workflow artifact).
- Posts a summary comment with a plain-text `[handoff/<step>-v1]` first-line marker (HTML comments get stripped by gh-aw's `add-comment`).
- Flips label to advance state, or labels `needs-revision`.

### B3. Engine assignment matrix

| Step | Engine | Why |
|---|---|---|
| Goals | claude | Conversational nuance |
| Questions | gemini | Cheap, generates good lateral questions |
| Research-codebase | copilot | Tight GitHub MCP integration |
| Research-web | claude | Strong web synthesis |
| Design | claude-opus | Architectural reasoning |
| Phasing | claude | Long-context slice composition |
| Structure | gpt-5/codex | Interface design clarity |
| Plan | claude-opus | Detail discipline |
| Parallelize | gemini | Cheap, mechanical |
| Implement (worker) | copilot | TDD + repo idioms |
| Implement (reviewer A) | claude-opus | Hostile correctness |
| Implement (reviewer B) | gpt-5 (via Copilot gateway) | Adversarial diversity from another family |
| Integrate | claude-opus | Multi-branch coherence |
| Test (acceptance) | copilot | Test execution + log reading |
| Replan | claude | Strategic re-scoping |

### B4. Pilot scope: Implement step first

Don't rewrite all 17 skills at once. Start with **Implement**, because it's where parallelism + per-task isolation + dual review converge.

1. Keep pre-Implement skills as local skill-chain. User produces `plan.md` + `tasks/task-NN.md` locally, pushes to `qrspi/<issue>` branch.
2. User opens "ready-to-implement" issue, labels `qrspi:implement`.
3. `implement-dispatcher.md` reads `parallelization.md`, creates sub-issue per task labeled `qrspi:task-ready`, opens draft integration PR.
4. `worker.md` (engine: copilot, TDD-strict): triggered per `qrspi:task-ready`, pushes to `qrspi/<n>/task-NN`, labels `qrspi:ready-for-review`.
5. `reviewer-a.md` (claude-opus) and `reviewer-b.md` (gpt-5 via Copilot gateway): triggered on PR, post review comments, label `work-approved` or `work-rejected`.
6. `batch-gate.md`: on any `work-approved`, mcp-script checks siblings, if all approved labels parent `qrspi:integrate-ready`.
7. `integrate.md`: merges branches, runs integration review, updates integration PR.

### B5. Things that won't translate cleanly (track as gotchas)

1. `/compact` prompts disappear → skill prose needs rewriting.
2. Human approval cadence shifts sync → async; offer `--local` fallback.
3. `codex-companion-bg.sh` long-running pattern doesn't translate; convert to scheduled workflows or in-loop mcp-script calls.
4. Cache-probe / red-verify scripts become Actions steps within their workflows.
5. Plan-quality 7-reviewer fan-out: fan-in logic now lives in a `plan-gate.md` workflow rather than inline.
6. `qrspi-finding-verifier` per-finding 0-100 scorer is a natural mcp-script tool (not its own workflow per finding).
7. Direct local installs of gh-aw plugins are deprecated; publish qrspi-plus as marketplace gh-aw extension.

### B6. Interactive Design step

Don't async-ify. Keep Design as a local Claude/Copilot session. Hybrid pipeline: user runs `qrspi design` locally, commits approved `design.md`, applies `qrspi:phasing-ready` label, gh-aw takes over.

---

## Gateway & secrets convention

To avoid per-phase decisions about which API key to wire into which critic, all workflows in this plan follow one default:

- **Copilot-routed access via `COPILOT_GITHUB_TOKEN`** is the default gateway for every model call that is *not* the primary `engine:` of a workflow. That includes adversarial critic mcp-scripts (e.g. `cluster-findings`), tier worker secondary models, and any helper LLM invoked from a script.
- **Primary `engine:` keys** (`ANTHROPIC_API_KEY` for `engine: claude`, `OPENAI_API_KEY` for `engine: codex`, `GEMINI_API_KEY` for `engine: gemini`) are wired only when that engine is the workflow's primary agent. Workflows that use `engine: copilot` need only `COPILOT_GITHUB_TOKEN`.
- **Escape hatch:** a phase may use a direct provider API key for a critic only if it documents a specific capability gap in Copilot routing (e.g. a model version not yet routed, a feature only the native API exposes). Default answer is "no, use Copilot routing."
- **Secret inventory** for this repo today (must be confirmed before Phase 1 runs):
  - `COPILOT_GITHUB_TOKEN`: required for `engine: copilot` and for all secondary model calls per the rule above.
  - `ANTHROPIC_API_KEY`: required only for workflows with `engine: claude` (Phase 1, Phase 4 reviewer A, Phase 7 designer).
- **Why this lives in the plan, not in each workflow:** before this convention, Phase 1's workflow author (this agent) had to ask which gateway to use for `cluster-findings`. That's a spec ambiguity that propagates to every future phase. The convention removes the question; phases that genuinely need an exception state it explicitly.

## Cost guardrails (apply from day 1, both tracks)

- `max-runs: 100` per workflow (well below the 500 default).
- `max-effective-tokens` tuned per role: workers 5M, reviewers 2M, dispatchers 500K, analyzers 10M.
- `gh aw audit` reviewed weekly.
- Per-engine concurrency overrides where parallelism is needed (default `gh-aw-{engine-id}` group is one-at-a-time).
- OpenTelemetry export from day 1 so cost-per-feature is real, not estimated.
- Threat detection enabled on every safe-outputs-using workflow.

## Worktree / parallel-agent conventions

- Each agent works in `~/Library/CloudStorage/Dropbox/copilot-workspace/agent-<nato>/qrspi-plus/`.
- Worktrees fork from `agent-delta/qrspi-plus` (the canonical clone).
- Branch names follow `CONTRIBUTING.md`: `<handle>/<type>/<slug>` (e.g. `agent-hotel/feat/corpus-analyzer`). The umbrella `agent-hotel/gh-aw-integration` branch this plan was committed to predates this clarification and stays as-is; subsequent per-phase branches use the canonical form.
- Per-clone `git config --local user.name "agent-<nato>"` + dfrysinger noreply email; PRs attribute to dfrysinger's account with distinguishable author.

## Sequencing checklist

- [x] Set up `agent-hotel/qrspi-plus` worktree on `agent-hotel/gh-aw-integration` branch.
- [x] Write this plan to `docs/gh-aw-integration-plan.md`.
- [ ] **Phase 1: corpus-analyzer.md** targeting `reviews/plan-109/` only.
- [ ] Phase 2: smoke-run.md + 2 scenarios with goldens.
- [ ] Phase 3: `qrspi corpus submit` script + analyzer extended to consume tarballs.
- [ ] Phase 4: `policy.yml` + one tier worker proof (borrowed from issue-autofix).
- [ ] Phase 5-6: `qrspi-assist.md` (forked from repo-assist) routed through policy.
- [ ] Phase 7-8: compound loop (reviewer-disagreement-reconciliation as first proof).
- [ ] Track B B4 pilot: gh-aw Implement step end-to-end (deferred until Track A stable).
