---
status: approved
---

# Goals: qrspi-plus v0.7.1 hardening

## Purpose

Close the 6 genuine post-v0.7-release gaps surfaced by the v0.7 bookkeeping audit. The release is correctness, portability, and presentation hardening on top of the v0.7 protocol — no new pipeline mechanisms.

## Constraints

- **Target repo:** `dfrysinger/qrspi-plus@main` at HEAD `b977466` (post-#200 generalize-contributor-protocol + post-#203 manifest 0.7.0 bump). Feature-main branch `qrspi/v0.7.1-hardening/main` rebased onto that commit during the goals-draft dual-review pass; baseline measurements below were taken at run start against the pre-rebase fork point `542023e` and the rebase picked up only the contributor-doc and manifest-version commits (no test infrastructure changed), so the baseline still holds.
- **CI must stay green** under both the Lint (`shellcheck` + bash-3.2 ban-list grep) job and the `BATS-under-bash:3.2` job defined in `.github/workflows/ci.yml`. Baseline at run start: Unit 1188 ok / 1 fail (test 325 evergreen-markdown, tracked separately under the closed #179); Acceptance 41 ok / 0 fail.
- **bash 3.2 portability** is a hard requirement for any shell-script touch. macOS system bash + the CI `bash:3.2` alpine image both lack GNU bash 4+ features (no `${var,,}`, no associative arrays declared with bare `declare -A` outside funcs, etc.) and macOS system `grep` lacks PCRE.
- **No new external dependencies.** All fixes must land using tools already in the qrspi-plus runtime (node stdlib, POSIX shell, bats-core, gawk where the CI install step provides it). New `npm` or Homebrew dependencies are out.
- **Evergreen-prose enforcement.** `tests/unit/test-evergreen-markdown.bats` bans release-version tokens, half-step labels, B-codes, mechanism codenames, and bare-paren PR refs in `skills/**` + `agents/**` (per PR #195 + PR #198 carve-outs). Any new prose lands inside those rules unless the path is in an existing exemption.
- **Workspace + identity per CONTRIBUTING.md § Parallel agents.** Fresh clone at `~/code/qrspi-plus-v0.7.1/` outside Dropbox eliminates the Dropbox-sync file-replacement failure mode that surfaced during the v0.7 run. The clone sets `user.name = agent-echo` for visual distinguishability in `git log` per the section's per-clone git-author pattern; cross-session coordination uses `STATUS.md`. The release feature-main `qrspi/v0.7.1-hardening/main` is a multi-issue release-branch namespace; it is distinct from CONTRIBUTING.md's per-handle `<handle>/<type>/<slug>` pattern that applies to standalone issue work. Implement will fork task worktrees as `qrspi/v0.7.1-hardening/task-NN` siblings off the release feature-main rather than per-handle branches. Orchestrator should treat unexpected working-tree changes on this clone as a stop-and-investigate signal and assume other agent handles may be operating concurrently against their own clones.

## Goals

> **Note for Research:** G1 through G5 originated from the v0.7 bookkeeping audit weeks before this run started; intervening work on `main` may have partially or fully closed any of them. Research must verify the current applicability of each G1-G5 entry against `main` HEAD (`b977466`) before Design opens, and flag any that are already resolved, partially resolved, or have shifted scope. G6 and G7 were authored against current state in this run and do not need the same status check.

### G1 — Portable control-character detection in third-party LLM dispatcher (#185)

- **type:** `known-fix`

#### Problem

`scripts/run-third-party-llm.sh` line 563 detects control characters using `printf | grep -P`. PCRE (`-P`) is a GNU grep extension; macOS system grep does not support it. The script silently fails — control-character detection becomes a no-op — when run on a bare macOS without Homebrew grep on `$PATH`.

#### Why we care

The dispatcher is the universal entry point for non-Anthropic LLM dispatches (T03/T04 from v0.7). Silent failure of its control-character detection allows prompt-injection vectors (CR/LF/NUL in user-supplied content) to reach downstream providers undetected. CI doesn't surface the gap because the runner is Ubuntu with GNU grep. Anyone using qrspi-plus on macOS without `brew install grep` is exposed.

#### What we know so far

- Issue #185 enumerates three candidate fixes Design should weigh:
  - Candidate A — `tr -d '[:cntrl:]'` followed by a length comparison
  - Candidate B — `awk` with character-class matching
  - Candidate C — `grep -E` with explicit hex escapes (no PCRE backreferences needed for this use case)
- Surfaced from v0.7 implement-summary known-issue #4.
- Existing BATS coverage: `tests/unit/test-run-third-party-llm.bats` is the natural home for a control-character detection pin.
- All three candidates are bash-3.2-portable and POSIX-clean.

### G2 — Scratch commit-message file no longer staged by `git add -A` (#175)

- **type:** `known-fix`

#### Problem

The implementer-protocol commit procedure writes commit messages to `<worktree>/.qrspi-commit-msg.txt` and then runs `git commit -F <path>`. The current ordering runs `git add -A` while the scratch file is on disk, so the scratch file is staged into the commit unless the implementer explicitly removes it first.

#### Why we care

Observed twice in v0.6-release Implement (T18 round-03 needed a cleanup commit; T04 round-02 only avoided it because the dispatch prompt explicitly reminded the agent). The snag survives across runs and burns review-cycle budget every time it's caught downstream. It also leaks per-task message text into commit history, which downstream tools (`git log --grep`, integration-summary collation) then have to filter around.

#### What we know so far

- Issue #175 enumerates two candidate remedies Design should weigh; both can ship together but only one is required:
  - Candidate A — Gitignore the scratch path. Add `.qrspi-commit-msg.txt` to `.gitignore` shipped with qrspi-plus (or move the scratch to a path already gitignored such as under `.qrspi/`).
  - Candidate B — Reorder the protocol step. In `skills/implementer-protocol/SKILL.md` / `skills/implement/SKILL.md`, swap the commit-procedure ordering so the scratch file is created AFTER `git add -A` or removed BEFORE it.
- The implementer-protocol skill already auto-loads via both implementer-agent `skills:` frontmatter; one prose change reaches both TDD + lightweight paths.
- No existing BATS coverage asserts the scratch file is absent from commits — Plan should add one.

### G3 — Reusable fence-tracking helper migrated into shared skill-markdown library (#187)

- **type:** `known-fix`

#### Problem

T22 in v0.7 migrated three pre-existing BATS files to the new shared `tests/helpers/skill-markdown.bash` helper but explicitly left the `extract_review_round` fence-tracking helper inline because the generic `extract_section` could not handle it. The fence-tracking helper remains duplicated and the migration is incomplete.

#### Why we care

Inline duplication of structural-lint extraction patterns was exactly the rationale for T13/T22 (issue #176, now closed). Leaving `extract_review_round` inline reintroduces the duplication-drift risk T22 was meant to eliminate. Any future consumer that needs fence-tracking will either re-implement it locally or reach across files for a copy — the same pattern that produced three rounds of reviewer findings on T09/T14 during v0.6.

#### What we know so far

- The existing helper at `tests/helpers/skill-markdown.bash` exposes `extract_section`, `extract_and_grep`, named-diagnostic empty-extract guards, and structural exit anchors. Its abstraction is heading-anchored.
- `extract_review_round` is fence-anchored (start anchor = round-header line, exit anchor = next ` ``` ` code fence or next `### Round NN` heading) — different structural shape from heading-anchored extraction.
- Candidate refactors Design should weigh:
  - Candidate A — extend `extract_section` to accept pluggable exit-anchor predicates (callback or regex parameter), then express `extract_review_round` as a thin wrapper.
  - Candidate B — add a separate `extract_between_fences` family to the helper, keep `extract_section` heading-only, share the empty-extract guards and `REPO_ROOT` setup_file plumbing.
- Either candidate must preserve bash-3.2 portability (no nameref `declare -n`, no `$'...'` ANSI-C strings in load-bearing places).

### G4 — Wave-grouped task presentation in `parallelization.md` (#42)

- **type:** `known-fix`

#### Problem

`parallelization.md` currently presents a flat Branch Map (Task / Branch / Base columns) plus a separate narrative "Execution Order" section describing waves. Readers cross-reference the two manually to see which tasks fire together at each Wave. The presentation is harder to scan than the underlying dependency structure permits.

#### Why we care

Readability of parallelization.md is the difference between a reviewer catching a base-mismatch finding before Implement dispatches (cheap) and catching it after a worktree fork went wrong (expensive). The flat Branch Map also produced two false-positive style findings during the v0.6 Parallelize review round (since fixed in T21 / closed in #173), and a wave-grouped presentation would have made the actual base-vocabulary errors more visible.

#### What we know so far

- Issue #42 proposes a nested presentation that shows dispatch ordering, task identity, base, and primary owned files in one Wave-grouped glance.
- F-22 (Wave/Group vocabulary collapse) is a prerequisite per the original finding and was completed in v0.7 — so #42 is now unblocked.
- The mermaid Wave graph and Stage Commits table can stay separate; the change is scoped to the Branch Map presentation.
- Test debt: the Plan-reviewer template that lints Branch Map shape needs an update; the Parallelize "Worked Example — Good" / "— Bad" examples need to be re-rendered in the new shape.

### G5 — Repo-wide TBD/TODO/"we'll see" cleanup in AGENTS.md / README.md / skills (#186)

- **type:** `known-fix`

#### Problem

T17 in v0.7 added a repo-wide evergreen-markdown BATS scan that bans release-version tokens, half-step labels, B-codes, mechanism codenames, and bare-paren PR refs. The scan was carved-out for pre-existing TBD/TODO/"we'll see" violations in AGENTS.md, README.md, and several `skills/` and `docs/` files so v0.7 could ship; those carve-outs are still in place and the violations remain.

#### Why we care

The carve-outs are a quiet form of technical debt: the lint is in place but blind to a class of forward-looking prose the rules are explicitly designed to forbid. Every new prose touch that lands inside a carve-out is one more reviewer round that has to remember the carve-out exists. Closing the violations lets the lint cover its intended surface unconditionally.

#### What we know so far

- Per PR #195 + PR #198, the canonical evergreen rules live in `tests/unit/test-evergreen-markdown.bats` and the protocol carve-outs in `skills/implementer-protocol/SKILL.md` (path-shaped table + inline `<!-- evergreen-exempt -->` markers).
- The violation set spans documentation (AGENTS.md, README.md), skill SKILL.md files, and possibly `docs/permission-friction-notes.md`. Exact paths must be enumerated by running the scan with the carve-outs disabled.
- Each violation is per-line and can be one of: (a) rewritten to forward-functional framing (most likely), (b) deleted as historical noise, or (c) preserved with an inline `<!-- evergreen-exempt -->` marker if the prose is load-bearing example content. Plan must classify each.
- The post-#199 AGENTS.md split (slim auto-load pointer + CONTRIBUTING.md) materially reshaped the file; the violation list must be re-enumerated against the current `main` rather than the pre-split snapshot.
- Status-check priority: of the G1-G5 set, this one is the most likely to be partially or fully closed by intervening work, because evergreen-prose hardening has continued on `main` since the audit. Research should re-run the carve-out-disabled scan first and report the current violation count before Design opens.

#### Status: closed by intervening work (2026-05-28)

G5 is closed without code change in v0.7.1. Evidence and rationale:

- `bats tests/unit/test-evergreen-markdown.bats` reports `21 ok / 0 fail` against the active surface (`AGENTS.md`, `README.md`, `skills/**`, `agents/**`) at HEAD `9cc284b`. Captured at `docs/qrspi/2026-05-27-v071-hardening/evidence/g5-status/evergreen-scan-pass.txt`.
- The five remaining path-shaped carve-outs in `_is_path_exempt()` (dated `docs/qrspi/YYYY-MM-DD-*/`, `CHANGELOG.md`, `tests/fixtures/`, `docs/superpowers/plans|specs/`, `reviews/`) do not hide active-surface violations. They preserve archived planning prose and reviewer-finding artifacts whose versioned references are correct for the moment the document was written. Removing those carve-outs would surface ~20 hits in archival prose that legitimately quotes prior-release version strings and PR refs, none of which represent forward-looking tech debt of the kind G5 was framed to close.
- Discovery point: Task 5 reached RED in the Implement phase. The RED proof revealed that the scan-pass acceptance criterion is structurally unreachable without rewording archived planning documents whose references are correct as written. Plan author missed the Research status-check directive recorded at the bullet above; the directive should have been honored at the Research stage, not at Implement RED.

Closure action: Task 5 is withdrawn (see plan.md `### Task 5: WITHDRAWN`). No code change for G5 in v0.7.1.

### G6 — Cross-CLI Codex auto-detection for the qrspi-plus skill (#202)

- **type:** `known-fix`

#### Problem

`skills/using-qrspi/SKILL.md` § codex_reviews detects Codex availability by globbing `~/.claude/plugins/cache/openai-codex/codex/*/scripts/codex-companion.mjs`. The path is Claude-Code-specific. Under GitHub Copilot CLI, Codex is a first-class model (`gpt-5.3-codex`, `gpt-5.2-codex`) accessible via the `task` tool's `model:` override — but the current detection returns `false` and the operator has to manually flip the config flag (as this very run did). On Codex CLI, neither path applies. The detection is silently single-host.

#### Why we care

QRSPI's review-quality story rests on dual-vendor reviewer panels (Claude + Codex), and the fanout is the single most expensive lever in the protocol's defect-catch rate. A misdetection that silently downgrades every Copilot/Codex-CLI run from dual-vendor to Claude-only erases that lever without telling the operator. The v0.7 release shipped the dual-vendor mechanism but only validated it on Claude Code, leaving the largest cross-CLI portability gap in the v0.6 → v0.7 → port-to-Copilot chain unclosed.

#### What we know so far

- Host detection signals available today (verified 2026-05-27 against Copilot CLI 1.0.55-3):
  - Env vars set deterministically by Copilot CLI at process spawn: `COPILOT_CLI=1`, `COPILOT_CLI_BINARY_VERSION=<ver>`, `COPILOT_AGENT_SESSION_ID=<uuid>`, `COPILOT_LOADER_PID=<pid>`, `COPILOT_RUN_APP=1`. Cleanest signal for shell scripts; no FS access required; cannot be spoofed by file-system layout drift.
  - Agents implicitly know which host they run in via tool registry shape (Copilot's `task` tool with `model:` override vs Claude's `Agent({ subagent_type: ... })` syntax) and via the subagent-name prefix conventions. This knowledge is available in prompt context but not addressable from shell scripts.
  - The gap the operator's "still would be nice to have a way of deterministically knowing" instinct picks up: skill prose and shell-script transports run identically on both hosts, so they need a single deterministic switch point. Agent self-awareness alone isn't enough.
- Detection signal candidates Design should weigh:
  - Candidate A — Probe environment variables / well-known binaries to identify host CLI (e.g., `COPILOT_CLI`, `CODEX_*` envs, `which copilot` / `which codex`), then per-host check the right path for Codex availability.
  - Candidate B — Treat Codex availability as a config-only flag (no auto-detect); ship per-host preset config snippets (`config-copilot.md`, `config-claude-code.md`, `config-codex-cli.md`) the operator copies in. Removes brittleness at the cost of one extra setup step.
  - Candidate C — Hybrid: auto-detect host CLI via env-var probe, then auto-detect Codex availability within that host's conventions, and emit a one-line diagnostic at goals-time if Codex is detected but the config has it off, or vice versa.
- Copilot CLI dispatch transport: Codex reviewer slot must dispatch via the `task` tool with `agent_type: code-review` and `model: gpt-5.3-codex` (or `gpt-5.2-codex`). The current skill's dispatch helper assumes a companion-script transport; the per-host abstraction must accept either.
- Codex CLI's own Codex-reviewer dispatch transport is out of scope for v0.7.1 unless trivial — Design can scope this goal Copilot-only and leave Codex-CLI to a follow-up.
- The fix is contained to `skills/using-qrspi/SKILL.md` + whichever dispatch helper file the `codex_reviews: true` branch invokes; no agent-file or per-reviewer-skill change is needed if the dispatch is single-point.
- An upstream feature request will be filed against `github/copilot-cli` to expose a stable detection signal regardless of which candidate ships here. The current `COPILOT_*` env-var surface looks intentional and stable in 1.0.55, but is not documented as a public API in the README; the FR would ask for that documentation guarantee.

### G7 — Retire Claude-era cross-host assumptions (#205 cache mechanism + #204 agent `model:` field)

- **type:** `known-fix`

#### Problem

Two design decisions from the Claude Code era no longer hold under the new GitHub Copilot CLI port (and Cursor / future hosts):

**G7a — G4 cache-control mechanism is unreachable from the plugin under Copilot.** The mechanism's stub spike (`scripts/g4-cache-probe.sh`, the dual-flag gate in `skills/using-qrspi/SKILL.md` § providers, the cache_control marker emission branch in `scripts/run-third-party-llm.sh`, and the two BATS suites pinning the gate) was designed against Anthropic's prompt-caching at the SDK boundary. Under Copilot CLI, the plugin does not control that boundary — the host CLI does. The mechanism is dead infrastructure that confuses operators and consumes review surface area.

**G7b — Agent `model:` field declarations silently fall back under Copilot CLI.** All 41 files in `agents/*.md` declare Claude short model names in YAML frontmatter (33 `sonnet`, 5 `inherit`, 1 `opus`, 2 `haiku` = 41 sites across 41 files; verified via `grep -h '^model:' agents/*.md | sort | uniq -c` against `HEAD`). Copilot CLI 1.0.55 does not recognize any of them. On every dispatch it emits `Warning: Custom agent "X" specifies model "Y" which is not available; using "<parent-session-model>" instead` and runs the agent on whatever model the operator's session has selected. Probed 2026-05-27 against `qrspi-finding-verifier` (declared `haiku`), `qrspi-spec-reviewer` (declared `sonnet`), and `qrspi-implementer` (declared `inherit`); all three fell back to `claude-opus-4.7-high` (the probe session's selected model).

#### Why we care

**G7a:** The cache mechanism shipped behind a dual-flag gate the operator must opt into, but the spike that was supposed to ground the on/off recommendation never executed. Carrying the dead mechanism into v0.7.1 keeps a Claude-only knob in `using-qrspi/SKILL.md` § providers that no Copilot operator can validate, plus four script/test/spike artifacts that misdirect new contributors into thinking the gate is wired through. Cleaner to retire it now and let host CLIs own their own provider-level prompt-caching.

**G7b:** This is an active cost regression in every current Copilot install of qrspi-plus. The Haiku-tier verifier (called per-finding, dozens to hundreds per wave) and the Sonnet-tier gate reviewers (called per task, dozens per release) are silently running on whatever the operator's session model is. For operators on Opus, that is roughly 50–100× the intended per-call cost for the verifier slot alone. The warning is emitted but easy to miss in fan-out logs, and the behavior change is invisible in the run report. The same defect applies to Cursor and any future host that does not natively alias Claude's short names.

#### What we know so far

G7 ships as one goal with two sub-deliverables (separate issues, separate PRs, independent execution) so the smaller deletion is not blocked behind the larger migration's design pass.

**G7a — cache mechanism retirement (#205) (mechanical deletion, no design surface):**

- Delete `scripts/g4-cache-probe.sh` (16KB, fully implemented but unrun).
- Delete `docs/qrspi/2026-05-17-v07-release/spikes/g4-cache-probe.md` (stub spike report).
- Delete `tests/unit/test-cache-control-capability-gate.bats` and `tests/unit/test-cache-hit-rate.bats`.
- Remove `supports_prompt_cache` + `emit_cache_control_markers` from all occurrences in the `skills/using-qrspi/SKILL.md` providers block (both the YAML example values currently at lines 427-428 and the description bullets currently at lines 441-442; phrasing left intentionally line-drift-tolerant).
- Remove the cache_control marker emission branch from `scripts/run-third-party-llm.sh`.
- Trim cache_control assertions only from `tests/unit/test-run-third-party-llm.bats`.
- Update `tests/acceptance/v07-phase1/test-phase1-acceptance.bats` to drop the `SPIKE` export pointing at the deleted spike (currently line 25) and the two `run run_pin` invocations for the deleted unit suites (currently lines 208 and 210). The acceptance suite must stay green per the CI constraint.
- Historical run records under `docs/qrspi/2026-04-29-v0.4-bundle/` and `docs/superpowers/` stay untouched.
- ~500 lines deleted, mechanical except for the acceptance-suite restructuring around the dropped Slice 7 / C-5 assertions.

**G7b — agent `model:` field migration (#204) (real design surface):**

- Pattern reference Design should weigh: `Raishin/vanguard-frontier-agentic` omits `model:` from all Markdown-family agent adapters (Claude, Copilot, Cursor, Gemini, Kiro IDE) and only carries explicit model IDs in the TOML-syntax Codex adapter. Lets each host pick its default, no portability brittleness, no version slip.
- Candidate framings Design should weigh:
  - Candidate A — Delete `model:` from all 41 agent frontmatters; author model-tier intent in dispatching skill prose using transport-agnostic vocabulary ("dispatch with a low-tier model" / "dispatch with a frontier reasoning model"). Each host resolves the tier via its native conventions.
  - Candidate B — Install-time alias-map build pipeline (rewrites `haiku → claude-haiku-4.5` etc. for the Copilot install). Reintroduces the build step v0.7.1 just decided not to add, and is version-brittle as Anthropic versions slip.
  - Candidate C — Upstream FR to Copilot CLI to alias Claude short names. Lowest effort from the plugin side but unbounded timeline and doesn't help Cursor / future hosts.
- Open design questions:
  - Where does per-agent model-tier preference live under Candidate A — single dispatcher-prose section per skill, per-dispatch inline, or a config knob in `config.md`?
  - How is "low-tier" mapped per host — inline conditional in skill prose, an aliased identifier the dispatcher emits, or a config table?
  - Do we expose a config-driven escape hatch so operators can override tier per agent without editing prose?
- Acceptance under Candidate A:
  - Fresh `copilot plugin install` of the resulting branch shows zero "model not available" warnings across a full pipeline run.
  - Claude Code install picks reasonable defaults for each agent without `model:` (Claude's resolver chooses Sonnet by default for custom agents without explicit `model:`).
  - BATS regression: existing model-related tests (if any reference the deleted field) updated; new tests pin the dispatcher-prose contract.
- Out of scope: skill body `model:` (skills don't have one), the cache_control mechanism (handled in G7a), Codex / third-party LLM dispatch transport (handled in G6).
- Verified by direct probe 2026-05-27:
  ```
  Warning: Custom agent "qrspi:qrspi-finding-verifier" specifies model "haiku" which is not available; using "claude-opus-4.7-high" instead
  Warning: Custom agent "qrspi:qrspi-spec-reviewer" specifies model "sonnet" which is not available; using "claude-opus-4.7-high" instead
  Warning: Custom agent "qrspi:qrspi-implementer" specifies model "inherit" which is not available; using "claude-opus-4.7-high" instead
  ```

## Cross-Cutting Notes

G2 (scratch commit-msg) and G3 (fence-tracking helper) both touch `tests/helpers/` and `skills/implementer-protocol/SKILL.md`. If both land in the same Wave they will conflict at the helper file; Parallelize should schedule them to disjoint Waves or pin them to a sequential stage.

G4 (parallelization.md presentation) and G3 (fence-tracking helper) both expand the surface area of structural-lint extraction patterns the BATS suite asserts against. Plan should consider whether G3's refactor lands first so G4's new Branch Map shape can be linted using the cleaned helper.

G5 (TBD/TODO cleanup) is enforced by `tests/unit/test-evergreen-markdown.bats`. If any other goal's new prose uses forbidden tokens, G5 must either land first (so the scan catches the new prose before merge) or the new prose must be path-exempted.

G6 (Codex auto-detection) materially affects this very QRSPI run: the Codex reviewer dispatches firing during Implement and Test will use the same Copilot-task-tool transport G6 is supposed to make first-class. The run is therefore both the consumer and the validation surface for G6's chosen detection candidate. Phasing should land G6 early enough that subsequent slices' reviewer dispatches exercise the patched detection path under realistic load.

G7a (cache deletion) and G7b (model field migration) ship as separate PRs under one goal narrative. G7a has no design surface and no dependencies on other goals; Phasing can schedule it in any Wave. G7b touches every `agents/*.md` file plus dispatching skill prose in `skills/implement/SKILL.md`, `skills/plan/SKILL.md`, `skills/test/SKILL.md`, `skills/replan/SKILL.md`, `skills/integrate/SKILL.md`, and the `_shared/` reviewer-protocol area; it conflicts with anything else that edits agent frontmatter. Plan must coordinate G7b with G6 if G6's chosen candidate also touches agent files.

G7b's dispatcher-prose vocabulary decision (Candidate A) interacts with G6's Codex-dispatch prose: both ultimately specify "what model the dispatched agent should run on" but at different scopes (per-agent tier vs per-reviewer-slot vendor). Design must pick a single convention so the two goals don't ship two competing model-selection idioms.

A potential G8 placeholder remains open for the broader subagent-dispatch port question (whether `scripts/run-third-party-llm.sh`, `scripts/codex-companion-bg.sh`, `scripts/run-codex-review.sh`, and the fan-out reviewer dispatch contracts that assume `Agent({})` semantics are partially dead under Copilot CLI). G1 (#185 grep-P in `run-third-party-llm.sh`) may collapse into G8 if that script is unreachable under Copilot. The walkthrough at the top of Questions / Design should re-shape G1 and decide whether G8 fits v0.7.1 or earns its own release.
