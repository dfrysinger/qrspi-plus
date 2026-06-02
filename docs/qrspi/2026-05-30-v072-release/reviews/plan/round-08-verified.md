---
verifier_enabled: true
scored: 2
kept: 1
dropped: 1
failed: 0
clean: 12
---

<!-- @@FINDING: goal-traceability-codex.finding-F01 @@ -->
---
reviewer: codex
role: plan-goal-traceability-reviewer
round: 8
artifact: plan.md
severity: high
change_type: correctness
finding_id: F01
referenced_files: [docs/qrspi/2026-05-30-v072-release/plan.md, docs/qrspi/2026-05-30-v072-release/goals.md, docs/qrspi/2026-05-30-v072-release/phasing.md]
---

# Finding F01 — G25/G29 have no forward task-to-test trace in plan

## Location

- `plan.md` L11 (overview describes them as absorbed/no standalone task)
- `plan.md` L50 (task list)
- `plan.md` L102 (dep graph narrative)

## What's wrong

The artifact claims 35 approved goals are decomposed into tasks, but
G25 and G29 are present as active goals upstream and in phasing while
no task in `plan.md` carries `Goal IDs: [G25]` or `Goal IDs: [G29]`.
That breaks the required forward trace from goal → task → task test
expectations.

## Evidence

- `goals.md` defines both goals (`goals.md:724` for G25, `goals.md:835`
  for G29).
- `phasing.md` still lists them in slice goal sets (`phasing.md:60`
  includes G29; `phasing.md:80` includes G25).
- `plan.md` has zero task `Goal IDs` lines containing G25/G29 (grep
  returns no matches), while explicitly stating they were
  "absorbed"/"no standalone task" (`plan.md:11`, `plan.md:50`,
  `plan.md:102`).

## Suggested fix

Either (a) formally remove/defer G25 and G29 from active goals/phasing
for this release, or (b) attach them to concrete task `Goal IDs` and
add explicit per-task Test Expectations proving those goal outcomes.

## Counter-context (round-02 adjudication)

This issue was investigated and resolved during round-02 of the plan
review. The plan currently documents the absorbed-by-CD-1 disposition
explicitly at L11 ("G25, absorbed by CD-1"), L50 (task-list gap),
and L102 (dep graph narrative). Design.md ## G25 / ## G29 sections
establish the consolidation rationale (both goals' surfaces folded
into CD-1's dispatch routing rewrite — no standalone task needed
because CD-1's tasks own the surface). The gtx-codex re-raise here
does not surface new evidence beyond the round-02 investigation;
the absorbed-disposition framing is the deliberate adjudicated outcome.
<!-- @@SCORE: goal-traceability-codex.finding-F01.score @@ -->
score: 15
reason: Plan explicitly documents G25/G29 absorbed-by-CD-1 disposition at L11/L50/L102 per round-02 adjudication; finding's own counter-context concedes no new evidence beyond the prior investigation.
<!-- @@FINDING: quality-codex.finding-F01 @@ -->
---
reviewer: codex
role: plan-reviewer
round: 8
artifact: plan.md
severity: high
change_type: correctness
finding_id: F01
referenced_files: [docs/qrspi/2026-05-30-v072-release/plan.md]
---

# Finding F01 — T25 includes an unfulfillable repo-wide stale-reference assertion

## Location

- `plan.md` Task 25 DoD, **L1400**
- `plan.md` Task 25 Test Expectations, **L1408** (the round-07 E1 fix)

## What's wrong

Task 25's DoD/Test Expectations require a repo-wide grep to find zero
`docs/prompt-design-guide.md` references (outside CHANGELOG), but this
repository intentionally contains many non-CHANGELOG historical/release
artifacts that still reference that path. As written, the acceptance
check can fail even when implementation is correct.

## Evidence

- Plan requirement: line 1400 (`No stale ... remain in the repo`) and
  line 1408 (repo-wide grep audit).
- Actual repo state (excluding CHANGELOG) still contains many matches
  in release artifacts, e.g. `docs/qrspi/2026-05-30-v072-release/structure.md:118`,
  `:2416`, plus other release/history files
  (`grep -R -n "docs/prompt-design-guide.md" . --exclude='*CHANGELOG*'`).

Orchestrator verification: 43 total non-CHANGELOG matches across
`docs/qrspi/` (release artifacts), `.restructure-v2/` (intermediate
structure work), `plan.md.bak-pre-merge` (planning backup), and the
v0.4 bundle's research files.

## Suggested fix

Narrow the audit scope to runtime/source surfaces that should be clean
(e.g., `skills/`, `agents/`, `scripts/`, active templates), or
explicitly exclude historical/release artifact directories and backups.
The intent of the audit is to catch live consumers still pointing at
the deleted path, not to penalize planning documents that describe the
migration.
<!-- @@SCORE: quality-codex.finding-F01.score @@ -->
score: 72
reason: Verified — T25's DoD/test-expectation grep (L1400, L1408) excludes only CHANGELOG, but plan.md/structure.md/design.md themselves reference `docs/prompt-design-guide.md` (e.g., structure.md L118, plan.md L1371/1385/1386), so the audit would fail even when T25's implementation is correct; narrowing scope to runtime surfaces is a legitimate, actionable fix.
<!-- @@CLEAN: goal-traceability-claude.clean @@ -->
# Plan goal-traceability review — round 08 (broaden vs main) — clean

**Reviewer:** claude (plan-goal-traceability-reviewer)
**Artifact:** plan.md
**Diff ref:** main (broaden round; no scope hint)
**Round-07 fix under review:** E1 — T25 added one Test Expectations bullet (plan.md L1414) elevating the existing DoD invariant at L1406 ("No stale `docs/prompt-design-guide.md` references remain in the repo") to an executable expectation.

## Verdict

No goal-traceability findings.

## Why clean

### Round-07 fix (L1414) verification

- **Forward trace (G31 → T25 → plan-authored criterion):** G31's "prompt-prose-coverage contract not yet enforceable" framing in goals.md ### G31 is the upstream problem; design.md ## G31 specifies the `git mv docs/prompt-design-guide.md → skills/_shared/prompt-design-rules.md` migration with deletion of the old path as a single-source-of-truth invariant; T25 owns the migration; the new L1414 bullet asserts the post-condition is build-enforced. Chain intact.
- **Backward trace (T25 → G31):** unchanged from round-07. T25 header at L1433 carries `Goal IDs: [G31]` only; the Overview's "Why" at L1384 cites `goals.md ### G31` and `design.md ## G31`; References at L1424 likewise.
- **DoD-to-test parity strengthening:** prior to this round, the L1406 DoD invariant lacked a paired Test Expectations bullet — the test expectations covered file existence, verbatim body match, and the 8 refresh-edit anchors, but the "no stale references" property was DoD-only. L1414 now closes that DoD-to-test asymmetry. The bullet explicitly tags itself "matches DoD invariant" to make the pairing audit-greppable.
- **No goal-coverage shift:** the bullet does not introduce new goal coverage (T25 still covers G31 only) and does not orphan any other goal (G31's other facets — Files 1-5 authoring, rule-refresh edits A-H, fast-path glob distinction — remain covered by other bullets in the same block). The strip-from-goals contract is honored: criterion authoring stays in plan.md.
- **Decomposition check:** G31's problem text in goals.md frames the migration as part of the prompt-prose coverage contract; deleting the old docs path and ensuring no stale references survive is a direct decomposition of "make the contract enforceable" (a live reference to a deleted source-of-truth file is precisely the kind of drift the contract aims to prevent).

### Surface outside the round-07 fix

No scope hint was provided (broaden round). I scanned the full diff for any other goal-trace regressions: none observed. The 38 tasks across 7 slices each carry `Goal IDs:` headers tracing to at least one approved goal, and the per-phase acceptance block at L25-L33 cross-references the cross-cutting fail-loud invariants for each major goal cluster (G3/G4/G6/G7/G8/G9/G11/G12/G13/G14/G15/G16/G18/G19/G20/G21/G22/G23/G27/G28/G31 surfaces all observable in the phase-acceptance bullets). Dropped findings (sec-codex.F01, scope-codex.F01, sf-codex.F01, tc-codex.F01) remain addressed and are not re-raised — E1 does not regress any of them.

## Dropped findings re-check

- **sec-codex.F01, scope-codex.F01, sf-codex.F01, tc-codex.F01** — not re-raised; round-07 E1 is additive at L1414 only and does not touch their respective fix surfaces.
<!-- @@CLEAN: quality-claude.clean @@ -->
---
reviewer: qrspi-plan-reviewer (quality)
artifact: plan.md
round: 08
verdict: clean
---

# Plan Quality Review — Round 08 (broaden vs main)

No findings.

## Round-07 E1 fix verification

Verified the single round-07 fix (E1) at plan.md L1414 — a new Test Expectations bullet under T25:

> "Repo-wide grep audit asserts zero remaining live references to `docs/prompt-design-guide.md` outside historical CHANGELOG entries (matches DoD invariant — fails the build on any stale source-of-truth reference)."

This bullet pins the DoD invariant at L1406:

> "No stale `docs/prompt-design-guide.md` references remain in the repo (grep returns zero matches outside historical CHANGELOG entries)."

The fix is correct:

- **Exclusion clause matches DoD verbatim** — "outside historical CHANGELOG entries" appears in both DoD and Test Expectation, so the test will not false-positive on CHANGELOG history.
- **One observable check, one grep pattern** — atomic, testable, no vague language.
- **Scope-clean** — confined to T25's Test Expectations block; no spillover into T26 (consumer include sites) or T32 (compaction-resilient prose) which carry their own G31 surfaces.
- **DoD-↔-test parity closure** — closes the previously-flagged gap where the DoD invariant had no corresponding test expectation row.
- **No interaction with dropped findings** — does not touch the surfaces of sec-codex.F01 (path-traversal halt absorbed), scope-codex.F01 (L11/L110 dep contradiction), sf-codex.F01 (T16 hardcoded fallback), or tc-codex.F01 (T39 build-twice determinism), nor with the round-06 sub-threshold clarity carry-overs (qty-claude.F02 L110 misattribution, F03 T16/T19 carve-out symmetry).

No defect introduced by E1.

## Cross-cutting plan-quality checks (full route)

- **Completeness** — every goal in goals.md (G1–G35 minus dispositioned-into-CD-1 entries G24-F01/F02/F03/F04, G25, G26-runtime, G29) is covered by at least one task with at least one Test Expectations bullet. Numbering gaps (18, 22, 23, 41, 42, 43) are explained in the Overview L17 disposition map and traced to design.md per-disposition sections.
- **Criterion authoring** — per-task `**Test expectations**` blocks plus per-phase `### Phase 1 Acceptance Criteria` block both present; goals.md carries no acceptance criteria (strip-from-goals contract honored).
- **No scope creep** — every task traces to a goal ID in goals.md or a CD-N disposition in design.md.
- **No placeholders** — spot-checked; no TBD/TODO/"similar to" patterns; file paths are exact; LOC estimates present on all 38 tasks.
- **Task sizing** — tasks ≥200 LOC carry `sizing_exception:` tags from the closed set (reusable primitives, schema-migration, CI scaffolding). T12 (~280), T16 (~320), T19 (~210), T20 (~260), T25 (~340), T29 (~150 — under threshold), T39 (~360) — all exception-tagged or under-threshold.
- **Interpretation** — plan approach aligns with goals' stated intent; no subtle misreadings detected.
- **Phase alignment** — single-phase release matches phasing.md's single-phase contract.
- **Design/structure traceability** — every task references design.md ## G<N> and structure.md per-file blocks; verified on T01–T07 spot-check and on T25 (E1 surface).

## Verdict

Clean. Recommend approval / loop convergence.
<!-- @@CLEAN: scope-claude.clean @@ -->
---
reviewer: qrspi-plan-scope-reviewer
reviewer_tag: scope-claude
artifact: plan.md
round: 8
verdict: clean
---

# Plan scope review — round 08 (broaden-vs-main)

No scope/boundary findings.

## Step 1 — OWNS/DEFERS rule loaded

`skills/plan/owns-defers.md` (single source of truth for plan.md scope).

## Step 2 — Artifact

`plan.md` (fresh introduction vs main, 2402 lines, 38 task specs across slices 1.1–1.7).

## Step 3 — 3-check procedure results

### 1. Boundary-drift detection — none

- Upstream references (`Why: see goals.md ### GNN`, `Approach: see design.md ## GNN`, `see design.md ### CD-N`) are correct consumption, not re-authoring of design/architecture content.
- Slice grouping (1.1–1.7) consumes phasing.md decisions and matches the upstream phasing artifact; Plan does not re-decide phase boundaries.
- Command-line shapes (`dispatch-agent.sh --verifier-fanout`, `JOB_ID=<id>`, `DISPATCH_FILE=<path>`), config field names (`tier:`, `change_type:`, `model_routing:`), file paths, and exit-code semantics (10/11/12) are Plan-altitude behavioral contracts — not function signatures, type definitions, or algorithm pseudocode.
- T21 L1258 / T39 L2260 reference `assert_path_under_repo_root <label> <abs-path>` using shell positional placeholders (not the parenthesized-parameter-list lexical signal). The symbol is defined upstream in structure.md; Plan is naming, not authoring.
- T39 L2260 names `fs.realpathSync` with explicit `(or equivalent)` softener, preserving Implement's negotiation room.
- T34 L1957 prescribes exact diagnostic text for the post-approval-split mismatch halt; the exact user-visible string is a load-bearing acceptance contract and is sourced from design.md ## G5, not Plan-authored.
- Several "v0.7.3+" deferrals (T07 L483, T08 L536, T16 L1002, T35 L2013, T39 L2245) are scope-out justifications that name where the current boundary stops, not Phasing-layer roadmap authoring.

### 2. Scope compliance per OWNS — complete

Each of the 38 task specs carries all four Plan OWNS surfaces:

- Ordered task spec (Target files, Scope In/Out, Definition of done).
- Test expectations as plain-language behavior bullets.
- Dependencies (`Dependencies:` line plus `Blocks:` where applicable), with cross-slice chains justified in the Overview and Dependency Graph.
- LOC estimate (`LOC estimate: ~N`), with `sizing_exception` declared and justified where applicable.

Phase-1 Acceptance Criteria appear at the phase boundary as cross-task observable behaviors, distinct from per-task Test Expectations. No OWNS gap detected.

### 3. Lexical boundary-drift signals — none

- No `expect(`, `assert.`, `assertEqual`, `toBe(` (uses of "assert" appear only as plain-language verbs: "Bats assertion verifies…", "asserts the locked extension…").
- No `if/else`, `for`, `while`, or line-numbered logic walkthroughs.
- No "trade-off", "we considered", or "alternative approach" prose.
- No "phase 2 will…" / "future phases" roadmap authoring; "v0.7.3+" mentions are scope-deferral justifications sourced from design.md.
- No parenthesized-parameter-list function signatures or return-type arrows in task specs.

## Round-07 E1 verification

L1414 added one Test Expectations bullet to T25 (repo-wide grep audit pinning zero live `docs/prompt-design-guide.md` references outside historical CHANGELOG). The bullet is plain-language test-expectation content matching T25's existing DoD invariant. No scope expansion, no boundary drift.

## Length

2402 lines for 38 task specs (~63 lines per spec; Keeplii average ~52). Modestly above the 1000–2000 soft band (~20% over) but well short of the "4000 lines signals overgrowth into design/implementation prose" guidance. Not a finding.

## Dropped findings — not re-raised

Per the round-07 disposition (verifier dropped below threshold): sec-codex.F01, scope-codex.F01 (L11 vs L110 dep contradiction — verifier scored 62, below 70 correctness floor), sf-codex.F01, tc-codex.F01. E1 introduced no defect that revives any of these.
<!-- @@CLEAN: scope-codex.clean @@ -->
---
reviewer: codex
role: plan-scope-reviewer
round: 8
artifact: plan.md
result: clean
---

# Plan-Scope Reviewer (Codex) — Round 8 — CLEAN

No significant scope issues found in the reviewed round-08 change
(including the Task 25 Test Expectations addition).

Brief return text: `Cannot write review artifacts to disk in this
environment. No significant scope issues found in the reviewed round-08
change (including the Task 25 Test Expectations addition); clean verdict.`
<!-- @@CLEAN: security-claude.clean @@ -->
# Plan Security Review — Round 08 (broaden vs main)

**Reviewer:** security-claude
**Artifact:** docs/qrspi/2026-05-30-v072-release/plan.md
**Scope:** full diff against main (broaden mode)

## Verdict

**CLEAN — no security findings.**

## Surface traced

This round is a broaden-vs-main full-diff review. I traced every task whose
spec touches a security-relevant surface (error handling, external input,
provenance, exfil boundaries, config validation, fail-loud invariants):

- T02 (verifier-fan-in.sh) — fail-closed on missing/out-of-enum `change_type`,
  missing sidecar, wrong sidecar extension, unparseable score; named audit
  halt cause per failure mode.
- T03 (reviewer disk-write contract) — wrong-channel emits
  `expected tag produced no output`; no silent acceptance of chat-only output.
- T04/T05 (`change_type` field + enum drift) — distinct `missing_change_type`
  vs `change_type_out_of_enum` halts; explicit prohibition on
  silently-default-kept / silently-kept / silently-dropped behavior.
- T11 (dispatch-manifest provenance) — records resolved
  `subagent_type/host/vendor/model/prompt_file`; atomic + append-safe under
  repeated invocations and multiple reviewer tags.
- T12 (round-prepare.sh + await-round.sh) — distinct exit codes 10/11/12 for
  SHA failures; non-git workspace returns documented no-diff status
  `without fabricating a diff path or scope hint` (callers can distinguish
  no-diff from failed-diff); `await-round.sh` never echoes captured reviewer
  payloads or prompt bodies — bounded output is a tested DoD.
- T13 (per-task review orchestration) — prior-round bookkeeping validation
  rejects missing/malformed `round-(NN-1)-commit.txt` and missing/empty
  prior scope set; reviewer dispatch cannot proceed from stale bookkeeping.
- T16 (`model_routing` schema + `_resolve-lib.sh`) — `tier: none` halts loud;
  missing/malformed `model_routing:` fails through shared
  config-validation-procedure with repair-or-abort guidance; the
  hardcoded-medium-with-loud-warning fallback is defense-in-depth behind
  the validation surface (unreachable in normal operation; warning surfaces
  the abnormal bypass — not raising as a finding).
- T19 (second-reviewer-available.sh + _host-detect.sh) — unknown host /
  missing default vendor / unknown vendor / unavailable vendor all halt with
  `[second-reviewer-unavailable]`; same-vendor collision halts with
  `[second-reviewer-same-vendor]` at matrix-lookup time.
- T20 (dispatch script rename + splitter) — `third-party-finding-splitter.sh`
  fails loud for missing flags, missing raw output, missing boundaries, or
  write errors; companion `await` writes raw output to `<round-dir>/.dispatch/`
  without echoing payload to stdout/stderr.
- T21 (G16 path-filter exfil hardening) — canonicalizes `--subject-code`,
  `--artifact-body`, `--companion`, `--diff-file` with `realpath`/`readlink -f`
  before any `cat` read or prompt emission; symlink-out-of-repo and
  readable-out-of-repo `--companion` regression tests required; implementer
  allowlist for `scripts/dispatch-agent.sh` and `scripts/dispatch-companion.sh`.
- T24 (detect-interaction-mode.sh) — invalid `QRSPI_INTERACTION_MODE` exits
  non-zero and `does not silently coerce`; stdout-only (no file writes);
  encapsulation rule restricts host literals to the script + its dedicated
  tests.
- T34 (Plan post-approval split) — hash mismatch / missing header /
  malformed header all halt with exact diagnostics; existing
  `tasks/task-NN.md` files untouched on conflict; hand-edit preservation
  when stored hash still matches current plan.md block.
- T35 (G10 reviewer-protocol anti-fabrication) — `CONTRACT-CONFLICT:` single-
  line exit routes to operator intervention; conflict-prefix path
  `does not parse findings, synthesize a clean sentinel, fire the
  schema-violation guard, auto-repair, consume a tag emission budget, or
  advance the round counter`.
- T39 (G32 plugin build pipeline) — strict whole-line bare-relative `!cat`
  grammar; cycle detection with full cycle printed; canonicalize-with-
  `fs.realpathSync`-before-byte-read symlink-escape guard mirroring T21
  shape; `${CLAUDE_SKILL_DIR}` in shipped files halts; symlink-escape
  regression fixture required with `resolves outside repository` diagnostic.
- T40 (G21 bats short-circuit) — body-assertion-guard lint with `file:line`
  diagnostics; BW02 minimum-version rule shares the corpus walk.
- T44 (G24-F05 anti-pattern pin regex hardening) — semantic regex family
  replaces brittle literal pins for silent-fallback prose; same-`@test`
  `$body` presence guard required.

## Authz scope

No endpoint, request-handling, or auth-gated resource surface in this
release. Auth/Authz category N/A.

## Defaults

No insecure defaults found. The one borderline case (T16
hardcoded-medium-with-loud-warning) is gated behind T16's shared
config-validation-procedure that fails loud on missing/malformed
`model_routing:`, making the fallback an unreachable defense-in-depth path
in normal operation rather than a primary substitution behavior.

## Round-07 E1 follow-up

Round-07's E1 fix was a test-expectations addition to T25 (one grep audit
bullet pinning that rules-file references use the exact anchor phrase
`skills/_shared/prompt-design-rules.md (resolved from the installed plugin
path per host convention)`). Pure test-coverage strengthening; introduces
no security surface change and no defect.

## Dropped-finding hygiene

Per priming, I did not re-raise sec-codex.F01 (absolute/path-traversal
halt on `!cat`). T39's DoD already requires canonicalize-before-byte-read
and an explicit symlink-escape regression with the `resolves outside
repository` diagnostic — matching my prior r7 defense that path-traversal
escaping the repo trips canonicalization before any byte enters `build/`,
and traversal that stays inside the repo is not security-relevant.

The build-time bulk copy operation (non-`!cat` file copy into `build/`) is
symmetric to the dropped finding's threat model: a malicious contributor
would have to commit a symlink in the source tree, visible in PR review.
Holding to the prior dropped-finding defense rather than re-raising.

## Net

No new security findings.
<!-- @@CLEAN: security-codex.clean @@ -->
---
reviewer: codex
role: plan-security-reviewer
round: 8
artifact: plan.md
result: clean
---

# Plan-Security Reviewer (Codex) — Round 8 — CLEAN

No significant security issues found in the reviewed changes.

Brief return text: `No significant security issues found in the reviewed
changes. I can't write review artifacts to disk in this environment, but
the round-08 outcome is clean (no security-codex.finding-FNN.md files).`
<!-- @@CLEAN: silent-failure-claude.clean @@ -->
---
reviewer: silent-failure-claude
round: 8
artifact: plan.md
verdict: clean
---

# Silent-Failure Hunter — Round 8 (broaden-vs-main)

No silent-failure defects found in the round-08 plan.md diff against main.

## Scope reviewed

Round-08 is a broaden-vs-main diff: the entire plan.md content appears as a new-file addition. Per the priming, this round's only material plan-content change since the round-07 clean is the E1 fix — one new Test Expectations bullet added to T25.

## E1 change assessment

T25 (G31 prompt-prose primitives) gained a Test Expectations bullet (plan.md line 1414 in the round-08 diff):

> "Repo-wide grep audit asserts zero remaining live references to `docs/prompt-design-guide.md` outside historical CHANGELOG entries (matches DoD invariant — fails the build on any stale source-of-truth reference)."

This bullet is fail-loud by construction:

- It pairs with the existing T25 DoD invariant ("No stale `docs/prompt-design-guide.md` references remain in the repo (grep returns zero matches outside historical CHANGELOG entries)").
- The bullet's own clause "fails the build on any stale source-of-truth reference" explicitly requires non-zero exit on the failure condition.
- It is a hardening assertion (grep audit producing a build-breaking exit on stale reference), not a fallback, swallowed error, partial-state-on-failure, or log-and-continue.

E1 introduces no silent-failure surface.

## Dropped findings — not re-raised

Per the priming, the following round-07 silent-failure finding was dropped at the round-07 verifier gate and is not re-raised in round-08:

- **sf-codex.F01** (T16 L986 resolver precedence `… → default_tier: → hardcoded medium with loud warning`) — goals-permitted operator-facing fallback per CD-1; explicitly defended in my prior round-07 clean as not a silent failure because it surfaces via a loud warning at resolve time. E1 does not touch T16 or the resolver precedence prose, so the round-07 disposition stands unchanged.

No new defect surfaces from the dropped finding's neighborhood in round-08.

## Verdict

Clean.
<!-- @@CLEAN: silent-failure-codex.clean @@ -->
---
reviewer: codex
role: plan-silent-failure-hunter
round: 8
artifact: plan.md
result: clean
---

# Plan-Silent-Failure Hunter (Codex) — Round 8 — CLEAN

No significant issues found in the reviewed changes.

Brief return text: `No significant issues found in the reviewed changes.`
<!-- @@CLEAN: spec-claude.clean @@ -->
---
reviewer: spec-claude
round: 8
verdict: clean
---

# Spec Review — Round 8 (broaden-vs-main) — Clean

Verified the round-07 E1 surgical fix (T25 L1408 added Test Expectation bullet binding the L1400 DoD invariant to an executable repo-wide grep audit for stale `docs/prompt-design-guide.md` references) and scanned the full broaden-vs-main diff for any new spec-level defects.

## E1 fix verification

**Target:** plan.md T25 (G31 prompt-prose primitives), Test Expectations block.

**Added bullet (L1408):**
> Repo-wide grep audit asserts zero remaining live references to `docs/prompt-design-guide.md` outside historical CHANGELOG entries (matches DoD invariant — fails the build on any stale source-of-truth reference).

**DoD invariant it verifies (L1400):**
> No stale `docs/prompt-design-guide.md` references remain in the repo (grep returns zero matches outside historical CHANGELOG entries).

Checks:
- Carve-out language identical on both sides (`outside historical CHANGELOG entries`).
- "Zero remaining live references" mirrors "zero matches" — equivalent semantics.
- Parenthetical correctly cites the DoD link, no ambiguity about which invariant.
- Specific, executable Test Expectation (grep → non-zero exit on stale ref), not vague.
- No duplication with other T25 test expectations (L1413 file-existence, L1415 byte-for-byte diff, L1416 frontmatter, L1417 `git log --follow`, L1418 A-H edits audit, L1419 R1-R7 meta-pass, L1420 anchor-phrase audit — none covered the "no stale refs outside CHANGELOG" surface before E1).
- No scope drift: migration + delete already in-scope at T25 Scope.In L1391–L1392 and DoD L1402.

## Full-diff sweep for new defects

1. **Completeness** — only T25 Test Expectations changed this round; full goal-coverage mapping unchanged from prior rounds where it was verified clean.
2. **Scope** — no new task or deliverable introduced; the added bullet strengthens an existing invariant.
3. **Interpretation** — E1 bullet matches the DoD invariant intent (block any post-migration stale references in source-of-truth files).
4. **Test coverage mapping** — E1 strictly improves G31 verifiability by converting a DoD assertion into an executable acceptance probe. No new gaps.
5. **Placeholder detection** — new bullet contains no TBD/TODO/"as needed"/vague phrasing.
6. **Task sizing** — T25 carries `sizing_exception: reusable primitives` (closed-set value); LOC budget ~340 unaffected by a single added bullet; no rebundling triggered.

## Dropped round-07 findings (per dispatch directive)

The four dropped findings (sec-codex F01 path-traversal halt; scope-codex F01 L11 vs L110 phrasing; silent-failure-codex F01 T16 medium fallback; test-coverage-codex F01 T39 build-twice determinism) all sit outside T25's E1 surface and are not reopened by the surgical fix. Not re-raised.

## Verdict

Clean. The round-07 E1 fix is consistent, complete, and well-bound to the DoD invariant it verifies. No new spec defects emerge across the broaden-vs-main diff.
<!-- @@CLEAN: spec-codex.clean @@ -->
---
reviewer: codex
role: plan-spec-reviewer
round: 8
artifact: plan.md
result: clean
---

# Plan-Spec Reviewer (Codex) — Round 8 — CLEAN

E1's added T25 grep-audit expectation is consistent with the task DoD and
introduces no new correctness/scope/intent issues in the broaden-vs-main
plan diff.

Brief return text: `No spec findings to report—E1's added T25 grep-audit
expectation is consistent with the task DoD and introduces no new
correctness/scope/intent issues in the broaden-vs-main plan diff.`
<!-- @@CLEAN: test-coverage-claude.clean @@ -->
---
reviewer: claude
role: plan-test-coverage-reviewer
round: 8
status: clean
artifact: plan.md
diff_ref: main (broaden — full file added vs base)
---

# Round-08 Test-Coverage Review — CLEAN

## Summary

No new test-coverage findings against the full broaden-vs-main diff.

## R7 fix verification

Round-07 kept tc-codex.F02 (T25 missing falsifiable signal for the
`docs/prompt-design-guide.md` stale-reference invariant). Round-07 fix E1
landed at plan.md L1408:

> "Repo-wide grep audit asserts zero remaining live references to
> `docs/prompt-design-guide.md` outside historical CHANGELOG entries
> (matches DoD invariant — fails the build on any stale source-of-truth
> reference)."

This sits inside the T25 `**Test expectations**` block and ties directly
to the existing DoD invariant at L1400. The expectation is specific,
observable, deterministic, and falsifiable. Fix accepted.

## Broaden-vs-main sweep

The round-08 diff is `new file mode 100644` from `/dev/null` (the artifact
does not exist on `main`), so the full plan is in scope. I sampled
T01–T08, T11–T17, T19–T21, T24–T25, T34–T40, T44 — representative across
all seven slices, both lightweight and code tasks, both fail-loud and
documentation-only surfaces.

Across every task examined, test expectations satisfy all four quality
gates:

- **Behavioral coverage**: each happy path names a specific observable
  outcome (exit code, file path, diagnostic prefix, frontmatter field).
- **Edge cases**: missing/empty/malformed/symlink-escape inputs are
  explicitly enumerated where the task processes data (T02, T12, T19,
  T21, T24, T34, T39, T44).
- **Error conditions**: every fallible operation names the specific
  exit code or diagnostic the caller receives — examples include T12
  exits 10/11/12, `[second-reviewer-unavailable]` /
  `[second-reviewer-same-vendor]` for T19, `CONTRACT-CONFLICT:` for T35,
  `resolves outside repository` for T21/T39, `HALLUCINATED: ` for T08,
  and verbatim mismatch-diagnostic strings for T34.
- **Expectation quality**: no "handles X appropriately" / "works
  correctly" / "edge cases are handled" patterns observed in any task
  reviewed.

## Design-required scenarios cross-check

The Phase 1 Acceptance Criteria fail-loud-invariant enumeration at L28
maps 1:1 to per-task test expectations:

- Splitter on adversarial Codex stdout → T20 companion/splitter fixture.
- `_resolve-lib.sh` `[second-reviewer-same-vendor]` halt → T19
  `test-routing-matrix-application.bats` assertion.
- `second-reviewer-available.sh` `[second-reviewer-unavailable]` halt →
  T19 probe behavior tests.
- `plan.md` post-approval split block-hash mismatch halt → T34 with
  exact diagnostic verbatim.
- `scripts/verifier-fan-in.sh` halt causes (missing `change_type`,
  out-of-enum, missing/wrong-extension sidecar, unparseable score) →
  T02 malformed fixture rounds.
- `tools/build-plugin.mjs` `resolves outside repository` and
  include-cycle halts → T39 symlink-escape and include-cycle fixtures.
- Path-filter exfil in `scripts/dispatch-agent.sh` → T21 four-path-family
  table-driven coverage.

No scenario named in the phase acceptance block lacks a corresponding
per-task test expectation.

## R7 drops — confirmed not regressed

- tc-codex.F01 (T39 build-twice determinism) — the existing AC #4
  `git diff --exit-code build/` bound at L30 remains intact; no new
  defect introduced by E1.
- sec-codex.F01, scope-codex.F01, sf-codex.F01 — out of test-coverage
  scope; no new test-coverage gap introduced by their disposition.

## Verdict

Clean. The plan's test expectations are complete and verifiable as a
basis for the Test phase's acceptance-test generation.
<!-- @@CLEAN: test-coverage-codex.clean @@ -->
---
reviewer: codex
role: plan-test-coverage-reviewer
round: 8
artifact: plan.md
result: clean
---

# Plan-Test-Coverage Reviewer (Codex) — Round 8 — CLEAN

Verified the T25 fix landed cleanly: plan.md L1408 now adds a repo-wide
stale-reference grep audit, and it is consistent with the DoD invariant
at L1400.

Brief return text: `No significant issues found in the reviewed changes.
Verified the T25 fix landed cleanly: plan.md L1408 now adds a repo-wide
stale-reference grep audit, and it is consistent with the DoD invariant
at L1400.`
