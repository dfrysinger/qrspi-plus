---
status: approved
---

# Goals: qrspi-plus v0.7.3 — pipeline correctness + prompt-footprint reduction

## Purpose

Close the eight P0 defects surfaced by the v0.7.2 self-host run — verifier mis-grounding, ID-hygiene leakage, plan-author over-scoping, orchestration-boundary drift, stage-commit parent drift, narrow-contract breakage, and the active-skill-prompt footprint that consumes ~25% of the context budget before the orchestrator does anything.

## Constraints

- Bash-only orchestration scripts (no Python in the dispatch chain); macOS + Linux portable.
- Plugin manager reads `.github/plugin/plugin.json` and `.github/plugin/marketplace.json` for version + install metadata; both must stay in lockstep with `.claude-plugin/*` (issue #277 consolidation deferred).
- Universal dispatch chain (v0.7.2) is the load-bearing entry: `dispatch-agent.sh` → Task fan-out → `await-round.sh` → `verifier-fan-in.sh`. Any new mechanism must compose with this chain rather than parallel it.
- All correctness changes must self-host on this same QRSPI run (the run's own pipeline executes the fixes against itself).
- No regressions to the v0.7.2 phase-1 acceptance test suite (`tests/acceptance/v07-phase1/`).

## Goals

### G1 — Verifier rubric grounded in canonical ID-hygiene authority

- **type:** `exploratory`

#### Problem

`qrspi-finding-verifier` grounds ID-hygiene change_type findings in `CONTRIBUTING.md` (which scopes only SKILL.md / `_shared` runtime prose and the pre-push lint), but no single authoritative document currently owns the ID-hygiene forbidden-token table for implementer/test contexts. The table is referenced from `skills/implementer-protocol/SKILL.md` § ID Hygiene today, but whether that is the right canonical home is itself an open question. Result: the verifier has been observed declaring real ID-hygiene rules "do not exist" because it consulted the wrong source, false-negativing reviewer findings about `[Tnn]` and `R\d+-F\d+` tokens in test names.

#### Why we care

The verifier is the gate that decides whether a reviewer finding survives or is suppressed. If it grounds in the wrong authority, real correctness findings get scored low and discarded — the v0.7.2 self-host T24/T16 ID-hygiene cycles produced exactly this failure. Until G1 lands, G2's sweep cannot be enforced (the verifier will keep killing the findings that drive the sweep). Picking the wrong canonical home compounds the problem — every future ID-hygiene rule lands in the wrong place.

#### What we know so far

- Repro path: reviewer flags an `R\d+-F\d+` or `[Tnn]` token in a bats test name; verifier scores low because CONTRIBUTING.md's pre-push lint does not cover test names.
- The forbidden-token table currently lives in `skills/implementer-protocol/SKILL.md` § ID Hygiene, but that placement is not authoritative — Design should weigh where the table belongs as a first-class question, not assume the current location is correct.
- Candidate homes Design should weigh: (a) `skills/implementer-protocol/SKILL.md` § ID Hygiene (current location); (b) `CONTRIBUTING.md` (current verifier-grounding source — would unify rather than split); (c) `skills/_shared/` runtime prose (canonical location for cross-skill ground rules); (d) a new dedicated authority document explicitly scoped to ID hygiene across the whole codebase. Each has tradeoffs around discoverability, ownership, and the surface area each consuming agent already loads.
- Candidate verifier-rubric fix Design should weigh: extend the rubric to require consulting whichever canonical home is chosen, and encode the canonical rule path in the agent body so the verifier loads it directly.
- Surfaced from v0.7.2 self-host implement phase (T24/T16 ID-hygiene cycles); related backlog `pi-bats-instruction-absent-assertion` (p3), `pi-bats-negation-not-enforced` (p3).

### G2 — Sweep `[Tnn]` task-ID markers from test names + prevent reintroduction

- **type:** `known-fix`

#### Problem

The codified ID-hygiene rule forbids `[Tnn]` prefixes in test names and commit messages, yet ~5514 instances are present across the v0.7.2 codebase. The pre-DONE implementer self-check is advisory and the per-task reviewer fan-out did not catch systematic introduction across all tasks. T numbers are reused across phases, so they become meaningless noise the moment a round ships — they are not stable cross-references and have no sanctioned downstream use.

#### Why we care

Test names are the durable interface to the test suite. Embedding ephemeral phase-local task IDs into them creates 5514 dead references that mislead future readers, break grep workflows, and visually anchor reviewers on noise rather than behavior. Left unfixed, every future phase compounds the leak because the verifier still false-negatives the finding (G1) and reviewers stop flagging.

#### What we know so far

- The direction to sweep all `[Tnn]` prefixes rather than blessing them is the candidate Design should confirm; rationale: T numbers are reused each phase, so a `[T24]` from v0.7.2 collides with a different `[T24]` in v0.7.3 — they are noise, not traceability. Provenance: the user reached this conclusion during Goals dialogue.
- G1 (verifier rubric correctness) is a hard prerequisite — sweep findings must survive the verifier or the sweep cannot be enforced going forward.
- Candidates Design should weigh for prevention: (a) promote the implementer self-check from advisory to blocking; (b) add a release-wide bats-name lint as a structural-lint rule (per the v0.7.2 T33 `structural_lint:` schema); (c) reviewer fan-out for cross-task ID-hygiene at integration time.
- Related backlog: `pi-bats-instruction-absent-assertion` (p3), `pi-bats-negation-not-enforced` (p3).
- Surfaced from v0.7.2 self-host implement phase (T24 round-07 surfaced as systemic when grep showed 5514 hits release-wide).

### G3 — Plan-author respects design-absorption markers (no manufactured-cleanup tasks)

- **type:** `exploratory`

#### Problem

During v0.7.2 self-host Plan-step round-01, the plan-author drafted 44 tasks covering all 33 approved goals + 4 CDs. Seven of those tasks were over-scoped from absorbed/moot goal IDs — design.md explicitly stated "no separate v0.7.2 task ships under the G\d+ ID" / "absorbed by CD-N" / "Explicit non-goal" / "moot", and the plan-author manufactured "post-CD-N cleanup" / "regression-prevention" framings to give each absorbed goal a standalone home anyway. A downstream dependency cascade (T18 → T22 → T23 → T42 → T43 → T44) hid the over-scoping in a coherent-looking cluster.

#### Why we care

Only `qrspi-goal-traceability-reviewer` (Codex) caught it (gtx-F01/gtx-F02 at scores 70 and 78, barely above the 70 correctness floor); `qrspi-plan-spec-reviewer` and `qrspi-plan-scope-reviewer` both ran clean. The round-02 surgery deleted 6 task bodies, re-labeled 1, and cleaned 8 cross-reference sites — plan.md shrank 2742 → 2403 lines, 44 → 38 tasks. This is precisely the failure mode QRSPI's reviewer fan-out is supposed to catch, and three of four reviewers missed it. Without a structural fix, every future run that has design absorptions will hit the same pattern.

#### What we know so far

- Contributing factors: (1) goal-ID completeness bias — implicit "every approved goal needs a task" rule applied even when design said no; (2) design absorption language was not load-bearing on the plan-author authoring loop; (3) real residual work bled into wrong IDs (T11's `dispatch_spec` provenance was genuinely needed CD-1 work but got labeled G29); (4) no plan-scope reviewer fired; (5) the dep cascade hid the over-scoping in coherent-looking "post-X" wording.
- Candidates Design should weigh (compound, not exclusive):
  - **(a) plan-spec-reviewer hardening** — grep design.md for absorption markers (`no separate v0.7.2 task ships under the G\d+ ID`, `absorbed by CD-\d+`, `Explicit non-goal`, `moot`) and assert no plan task carries that goal ID. Cheap, mechanical, hard pass-fail.
  - **(b) plan-author pre-fanout step** — before per-task fan-out in the Plan skill, scan design.md for absorption markers and produce a redirect map (absorbed-ID → absorbing-ID or CD-N); per-task author consults it before drafting any task labeled with a redirected ID. Most preventive.
  - **(c) goal-traceability-reviewer threshold/escalation** — either lower the correctness floor for goal-traceability findings, OR escalate "design says no task but a task exists" findings to a hard pause regardless of score. Safety net.
- Surfaced during qrspi-plus v0.7.2 self-host Plan step round-02; surgery committed `4bfc327` + SHA anchor `05809e6`.

### G4 — Apply-fix protocol carries a `plan`-step upstream-artifact entry

- **type:** `known-fix`

#### Problem

The Apply-fix protocol's step 4 (parallel verifier dispatch) documents per-step `upstream_paths` lists for the verifier dispatch prompt: Goals, Questions, Research, Design, Phasing, Structure, Parallelize, Replan all have entries. The `plan` step is missing. When the orchestrator runs the Plan-step Apply-fix protocol, it has to invent the upstream list ad-hoc.

#### Why we care

If the orchestrator picks the wrong upstream set (e.g. omits `phasing.md`), the verifier scores plan-level findings without phase-boundary context and may misclassify scope-extension findings as legitimate correctness gaps. Different orchestrator instances pick different lists, producing non-reproducible verifier behavior across runs. The whole point of the upstream-artifact list is reproducibility.

#### What we know so far

- The list lives in `skills/using-qrspi/SKILL.md` → "Per-step upstream-artifact lists" and jumps from Parallelize to Replan with no Plan entry.
- Candidate fix Design should weigh: add the canonical Plan-step entry, with two variants because Plan's artifact gating differs by pipeline mode:
  - `Plan (full pipeline): goals.md, research/summary.md, design.md, phasing.md, structure.md`
  - `Plan (quick fix): goals.md, research/summary.md`
- For v0.7.2 the orchestrator improvised `goals.md, research/summary.md, design.md, phasing.md, structure.md` (the full pipeline prerequisites per Plan skill's artifact gating).
- Surfaced from qrspi-plus v0.7.2 self-host Plan step rounds 1 and 2.

### G5 — Orchestration Boundary HARD-RULE observable beyond Implement

- **type:** `exploratory`

#### Problem

During v0.7.2 Integrate R1, the main-chat orchestrator edited test files and skill prose directly to fix reviewer findings, instead of dispatching `qrspi-implementer` (mode: fix) subagents per the Implement skill's `### Orchestration Boundary` HARD-RULE ("MAIN CHAT ONLY ORCHESTRATES. ALL CODE EXECUTION, FILE CHANGES, AND GIT OPERATIONS ARE DELEGATED TO SUBAGENTS."). The user caught it mid-flight. The HARD-RULE prose lives only in `implement/SKILL.md`; Integrate's fix-loop inherits the discipline by reference but does not restate it inline. When fix counts are small, main chat rationalizes "this is too small to dispatch a subagent for."

#### Why we care

The boundary HARD-RULE exists because main chat retains conversational context across the entire phase, while subagents fork into clean contexts per task. Direct main-chat edits skip the per-task TDD + reviewer fan-out, eroding the per-task quality gate. v0.7, v0.7.1, and v0.7.2 all rely on this discipline; cumulative drift is the real risk. The discipline must be observable, not just prose-vigilant.

#### What we know so far

- Candidates Design should weigh (the issue calls them complementary; one or both):
  - **(1) Inline the Orchestration Boundary HARD-RULE in `integrate/SKILL.md` and `test/SKILL.md`** — currently only `implement/SKILL.md` carries the full prose. Cheapest.
  - **(2) Runtime observability hook** — at the end of each phase, the orchestrator writes `reviews/{phase}/main-chat-edits.md` listing every Edit/Write tool call main chat issued during the phase against `<workspace>/scripts|tests|skills|agents|docs`. Empty file = clean discipline; populated = red flag for the batch gate. Highest leverage because it makes discipline observable rather than relying on prose vigilance.
  - **(3) Soft-gate in batch-gate menu** — detect main-chat Edits in the phase transcript and surface "main chat made N direct edits — review or escalate?" before continuing.
- Documented in `using-qrspi/SKILL.md` would also be required for cross-phase discipline.
- Source: v0.7.2 self-host Phase 1 Integrate R1 (PR #299).

### G6 — Stage-commit parent SHAs validated against named task tips

- **type:** `known-fix`

#### Problem

During v0.7.2 self-host Test phase R1, a phase-level acceptance test surfaced that **Task 21 (G16 path-filter exfil guard) was lost at integration** despite Integrate R1 reporting CLEAN. Diagnosis: commit `b4e3074 stage-after-W16: merge(task-21, task-26)` is mislabeled — its actual parents are `064bede` (stage-after-W4) and `5823302` (task-26 R2 fix-cycle 3 tip); task-21's tip `843c951` was never integrated. None of T21's 8 fix-cycle commits or feature commit `55a27c0` are ancestors of main. A 3,254-file PR shipped with a missing security-relevant guard until phase-level acceptance happened to author a pin for it.

#### Why we care

Named-vs-actual parent drift is precisely the class of bug per-task and integration review cannot catch — both review the diff against the **claimed** base, not the actual stage-commit parent set. This is a silent integration-time failure that bypasses every review gate and only surfaces if a downstream test happens to exercise the missing surface area. Test came up green for the wrong reason.

#### What we know so far

- Candidate fix Design should weigh: validate actual merge-parent SHAs against the named task-tip SHA set at stage-commit creation time (Implement skill § Wave Dispatch step 6 / Branch Model — Runtime Resolution); halt with a named diagnostic on mismatch and do not advance the wave.
- Bats coverage at the right granularity (rejecting a fixture stage-commit with mismatched parents) is a candidate acceptance approach Design should weigh.
- Documented in `parallelize/SKILL.md` § Branch Map and `implement/SKILL.md` § Wave Dispatch.
- Surfaced from v0.7.2 self-host Phase 1 Test R1 by `tests/acceptance/v07-phase1/test-g16-path-filter-exfil-guard.bats` round 1.

### G7 — Narrow-round ref selection robust under multi-commit-per-round patterns

- **type:** `exploratory`

#### Problem

The Apply-fix protocol step 12 ("Ref selection for round NN+1") uses `HEAD~1` to mean "the prior round's per-round commit" when narrowing. Step 11 generates **two** commits per round (the fix commit, then the anchor-capture commit for `round-NN-commit.txt`). After round N+1's anchor commit lands as HEAD, `HEAD~1` resolves to round N+1's fix commit, not round N's commit. Live repro from v0.7.2 self-host phasing: HEAD=c2acbae (R3 anchor), `HEAD~1`=48da62c (R3 fix), expected d32fc50 (R2 fix); `git diff HEAD~1 -- phasing.md` produced 0 lines, so the next dispatch would have run against an empty diff and silently terminated clean for the wrong reason.

#### Why we care

Silent empty-diff termination is the same shape of failure as G6 — a gate reports clean for the wrong reason and the round advances without verifying its actual content. Without a fix, every multi-commit-per-round phase rolls dice on whether the narrow ref points at the right commit.

#### What we know so far

- Workaround used during v0.7.2: read SHA from `reviews/{step}/round-(NN-1)-commit.txt` and pass as `<ref>` explicitly.
- Candidates Design should weigh:
  - **(1) Single commit per round** — capture commit SHA inline in the fix commit by writing a placeholder, committing, then `git commit --amend` after computing the SHA. Drop the separate anchor-capture commit. Cleanest; `HEAD~1` becomes correct by construction. Touches the round-prepare/round-anchor mechanics.
  - **(2) Replace `HEAD~1` with explicit anchor-file lookup** — step 12's narrow branch reads `reviews/{step}/round-(NN-1)-commit.txt` and uses that SHA as `<ref>`. Keep divergence assertion as a sanity check. Lower-blast-radius patch.
- G6 (parent-SHA validation) and G7 share the round-mechanics surface; Design should weigh them together for coherence.
- Source: `skills/using-qrspi/SKILL.md` § Apply-fix protocol step 12; v0.7.2-release branch commits d32fc50, 48da62c, c2acbae.

### G8 — Active-skill-prompt footprint reduction across all 14 skills

- **type:** `exploratory`

#### Problem

Active SKILL.md bodies are re-injected verbatim into the system prompt every turn. Current footprint: implement/SKILL.md ~45-50K tokens (1,451 lines), using-qrspi/SKILL.md ~33K (1,262), plan/SKILL.md ~18K (726), all 14 skills together ~190K tokens. Active implement skill alone eats ~25% of the context budget before the orchestrator does anything; after `/compact` at v0.7.2 close, context was still at 41% with implement pinned active. Skills carry duplicated dispatch templates, restated HARD-GATE blocks, repeated verifier wiring sections (4× in implement alone), near-duplicate visual-fidelity dispatch sections (2× in implement), and prose that restates script exit codes the scripts themselves enforce.

#### Why we care

Every token spent on dispatch boilerplate is a token the orchestrator does not have for the actual task. Context saturation at 41% post-compact directly causes the orchestration drift G5 surfaces, the rationalization patterns G3 surfaces, and the silent-failure modes G6/G7 surface — context-starved orchestrators take shortcuts. Trimming the active footprint is an enabling fix for the rest of the v0.7.3 work.

#### What we know so far

- The v0.7.2 universal-dispatcher refactor extracted the actual orchestration logic into scripts: `dispatch-agent.sh`, `dispatch-companion.sh`, `round-prepare.sh`, `await-round.sh`, `third-party-finding-splitter.sh`, `verifier-fan-in.sh`. The orchestrator's residual job is small: prepare → dispatch (one Agent call per spec line) → await → fan-in → decide → loop or gate. Most of the prose in implement/SKILL.md restates what the scripts already enforce.
- Candidate inclusion list (what skills SHOULD carry, per #310): Iron Law + scope (OWNS / DEFERS); required artifact inputs + gating; the loop shape (read → prepare → dispatch → await → fan-in → decide → loop or gate); terminal state + handoff to next route step; mode branching at the orchestration level; Red Flags (human-readable STOP list).
- Candidate exclusion list (what skills SHOULD NOT carry): Codex/third-party dispatch shell pipelines; jobId await + tmpfile + redirect patterns; convergence narrow/broaden rule tables; HEAD~1 safety check prose (script exit code 12 is the gate); verifier sidecar schema, bypass marker schema, path validation rubrics (lives in scripts + agent bodies).
- Per-skill targets and trim depth are Design's call. Candidate strategies Design should weigh: (a) move dispatch templates out to supporting `.md` files referenced via `!cat`; (b) extract repeated wiring into shared snippets; (c) trim restated HARD-GATE prose where the script enforces the gate; (d) consolidate near-duplicate sections.
- Candidate acceptance approach Design should weigh: measure post-trim active footprint and confirm no regression on the v0.7.2 phase-1 acceptance suite (regression guard already captured under `## Constraints`).

## Cross-Cutting Notes

- **G1 → G2 prerequisite chain.** G2's sweep cannot be enforced until G1's verifier rubric is correct; otherwise reviewers re-flag and the verifier re-suppresses indefinitely.
- **G6 / G7 share round-mechanics surface.** Both touch stage-commit creation and round-anchor mechanics; G7's "single commit per round" candidate would simplify G6's parent-validation diff. Design should weigh them coherently.
- **G8 lands last.** Trimming skill bodies while G1-G7 are editing them creates merge churn; phasing should sequence G8 after the correctness goals settle.
