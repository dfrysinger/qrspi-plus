---
verifier_enabled: true
scored: 5
kept: 1
dropped: 4
failed: 0
clean: 10
---

<!-- @@FINDING: scope-codex.finding-F01 @@ -->
---
reviewer: codex
role: plan-scope-reviewer
round: 7
artifact: plan.md
severity: medium
change_type: correctness
finding_id: F01
referenced_files: [docs/qrspi/2026-05-30-v072-release/plan.md]
---

# Finding F01 — Overview L11 contradicts dependency graph L110 on slice 1.7 independence

## Location

- `plan.md` Overview, **L11** — claims "slice 1.7 build tooling is fully independent of slices 1.1–1.6 and can ship last in parallel"
- `plan.md` Dependency Graph narrative, **L110** — documents the exceptions: "Slice 1.7 is otherwise independent of Slices 1.1–1.6 except that T39 depends on T25 for the defensive-copy site and on T21..."
- `plan.md` task list, **L92** — T39 `deps: [Task 21, Task 25]`

## What's wrong

The plan has an internal dependency contradiction: the Overview at L11 says
"slice 1.7 build tooling is fully independent of slices 1.1–1.6," but the
dependency graph at L110 and Task 39 metadata at L92 state T39 depends on
Task 21 (slice 1.4) and Task 25 (slice 1.5). This can mislead
sequencing/parallelization decisions at plan altitude — a parallelization
reader who stops at L11's overview statement would queue slice 1.7 as
fully parallel-eligible against slices 1.4 and 1.5.

## Suggested fix

Update the L11 Overview statement to reflect the explicit T39 cross-slice
dependencies (mirror or reference L110's qualified phrasing).
<!-- @@SCORE: scope-codex.finding-F01.score @@ -->
score: 62
reason: Real internal contradiction verified — L11's unqualified "fully independent" claim conflicts with T39 deps at L92 and the qualified L110 narrative; plan-altitude relevant for parallelization but mitigated by the correct statement appearing later.
<!-- @@FINDING: security-codex.finding-F01 @@ -->
---
reviewer: codex
role: plan-security-reviewer
round: 7
artifact: plan.md
severity: medium
change_type: correctness
finding_id: F01
referenced_files: [docs/qrspi/2026-05-30-v072-release/plan.md]
---

# Finding F01 — AC #2 omits T39 absolute/path-traversal halt class

## Location

- `plan.md` Phase 1 AC #2, **L22**
- `plan.md` T39 DoD **L2246**, Test Expectations **L2261**

## What's wrong

Phase Acceptance Criteria #2 now includes the 4 added T39 halts, but it is
still not byte-aligned with T39's full fail-loud set: T39 explicitly
requires halting on **absolute-path attempts** and
**path-traversal/escaping attempts** as their own resolver failure class.
AC #2 only names `resolves outside repository` (symlink/outside-root
canonicalization), which does not fully cover the stricter "absolute
path attempt must fail" invariant.

## Evidence

- AC #2 list at L22 includes: `resolves outside repository`, include-cycle,
  malformed `!cat`, missing-target, `${CLAUDE_SKILL_DIR}`.
- T39 DoD L2246 and Test Expectations L2261 require failure on: malformed
  directives, missing targets, include cycles, **absolute/path-traversal
  attempts**, outside-root includes, `${CLAUDE_SKILL_DIR}`.

## Suggested fix

Extend AC #2 to explicitly include the absolute/path-traversal halt class
(matching T39 wording), so phase-level acceptance cannot pass while that
resolver guard regresses.

## Note

Round-06 sec-claude.F01 (kept via scope-bypass) explicitly said: "Absolute /
path-traversal includes and outside-root includes are subsumable under the
symlink-escape canonicalization halt — same boundary check — so I'm not
flagging those." Verifier should adjudicate whether absolute/path-traversal
is a distinct invariant requiring its own enumeration or subsumable under
the canonicalization halt.
<!-- @@SCORE: security-codex.finding-F01.score @@ -->
score: 25
reason: Absolute/path-traversal cases are subsumed by AC #2's already-enumerated "malformed `!cat` directive" (bare-relative grammar) and "resolves outside repository" (canonicalization) halts, so this is a wording-alignment nit rather than a coverage gap; the reviewer's own footnote concedes round-06 sec-claude classified it as subsumable.
<!-- @@FINDING: silent-failure-codex.finding-F01 @@ -->
---
reviewer: codex
role: plan-silent-failure-hunter
round: 7
artifact: plan.md
severity: high
change_type: correctness
finding_id: F01
referenced_files: [docs/qrspi/2026-05-30-v072-release/plan.md]
---

# Finding F01 — `_resolve-lib.sh` `hardcoded medium` warning-only fallback (fail-open)

## Location

- `plan.md` Task 16, **L986** and **L1013**

## What's wrong

The plan explicitly preserves a log-and-continue routing path:
`--tier-override → tier → default_tier → hardcoded medium with loud warning`,
and test expectations require that precedence. That means resolver
behavior can continue on an implicit fallback instead of halting when
routing inputs are incomplete or broken.

## Why this matters

This is a fail-open/log-and-continue behavior in the dispatch control
plane; it can route work to unintended models while still "succeeding,"
masking configuration defects rather than forcing correction.

## Suggested fix

Replace the final `hardcoded medium` fallback with a hard failure
(non-zero exit + diagnostic), and update test expectations to require
halt-on-missing-effective-tier rather than warning-and-continue.

## Counter-context (round-07 sf-claude disposition)

Round-07 sf-claude clean explicitly addressed this same surface: "T16 L986
resolver precedence (`… → default_tier: → hardcoded medium with loud
warning`) was not flagged in round-06 by silent-failure-claude
(**goals-permitted operator-facing fallback per CD-1**) and is untouched
in round-07; no regression." The fallback is a deliberate goal/design
decision in CD-1 (operator gets the warning, dispatch proceeds with
documented default), not a plan-altitude defect. Changing it would
require backward-looping into design.md ## CD-1 and goals.md G22.
<!-- @@SCORE: silent-failure-codex.finding-F01.score @@ -->
score: 15
reason: Finding's own counter-context concedes the hardcoded-medium-with-loud-warning fallback is a deliberate design.md CD-1 / goals.md G22 decision, so this is a design-altitude objection to a captured decision rather than a plan-altitude correctness defect.
<!-- @@FINDING: test-coverage-codex.finding-F01 @@ -->
---
reviewer: codex
role: plan-test-coverage-reviewer
round: 7
artifact: plan.md
severity: medium
change_type: correctness
finding_id: F01
referenced_files: [docs/qrspi/2026-05-30-v072-release/plan.md]
---

# Finding F01 — T39 reproducibility DoD lacks build-twice determinism test

## Location

- `plan.md` Task 39 DoD, **L2242**
- `plan.md` Task 39 Test Expectations, **L2257–L2269**

## What's wrong

The DoD requires a *reproducible* build tree (L2242), but Test
Expectations only require a single successful build plus artifact audits.
There is no explicit "build twice and compare bytes/diff" check.

## Why this matters

Nondeterministic build behavior (ordering/timestamp/path traversal side
effects) can slip through and only appear as flaky CI or intermittent
build-sync failures.

## Needed coverage

Add an explicit determinism check (e.g., run `node tools/build-plugin.mjs`
twice from clean state and assert zero diff/hash change in `build/` +
relevant metadata outputs).
<!-- @@SCORE: test-coverage-codex.finding-F01.score @@ -->
score: 28
reason: The CI build-sync gate (build + git diff --exit-code against committed build/) already functions as a cross-run determinism check, and resolver idempotence is explicitly tested at L2260; an additional intra-run "build twice" test is belt-and-suspenders rather than a real coverage gap.
<!-- @@FINDING: test-coverage-codex.finding-F02 @@ -->
---
reviewer: codex
role: plan-test-coverage-reviewer
round: 7
artifact: plan.md
severity: medium
change_type: correctness
finding_id: F02
referenced_files: [docs/qrspi/2026-05-30-v072-release/plan.md]
---

# Finding F02 — T25 DoD requires zero stale refs but lacks repo-wide grep assertion

## Location

- `plan.md` Task 25 DoD, **L1400**
- `plan.md` Task 25 Test Expectations, **L1407–L1413**

## What's wrong

DoD requires zero stale references to `docs/prompt-design-guide.md`
(L1400), but Test Expectations do not include a repo-wide assertion for
that removal.

## Why this matters

The migration can be partially complete while stale references remain,
causing drift and pointing contributors to a deleted source-of-truth path.

## Needed coverage

Add a grep assertion that `docs/prompt-design-guide.md` has no remaining
live references (with any intended explicit exclusions documented).
<!-- @@SCORE: test-coverage-codex.finding-F02.score @@ -->
score: 72
reason: DoD L1400 mandates a grep-zero check for stale docs/prompt-design-guide.md references, but Test Expectations L1407–L1413 only cover deletion existence and unrelated refresh-edit anchors — a real DoD↔tests coverage gap.
<!-- @@CLEAN: goal-traceability-claude.clean @@ -->
# Goal-Traceability Review — plan.md round 07 (broaden-vs-main)

**Reviewer:** claude
**Round:** 07
**Verdict:** clean — no findings

## Scope verified

Round-07 is a broaden-vs-main review. The user identified two round-06 deltas
to confirm traceability is preserved:

1. **T19 dep edge → Task 16** — verified at three sites:
   - Slice 1.4 listing (plan.md L71): `deps: [Task 16]`
   - T19 task spec (plan.md L1103): `Dependencies: Task 16. Blocks: Task 20`
   - T19 DoD (L1129) requires `scripts/_host-detect.sh` and
     `second-reviewer-available.sh` to consume `_resolve-lib.sh` matrix
     helpers; those helpers land in T16. The dep edge is semantically
     required by T19's own contract.

2. **Phase 1 Acceptance Criterion #2 — T39 enumeration** — verified all four
   `tools/build-plugin.mjs` halts named in AC #2 (plan.md L22) trace to T39
   DoD bullets and matched test expectations:
   - `resolves outside repository` halt → T39 DoD L2253 + test L2268
     (symlink-escape regression with `resolves outside repository`
     diagnostic, mirrors T21's `assert_path_under_repo_root` shape).
   - Include-cycle halt with full cycle printed → T39 DoD L2246 + test L2261.
   - Malformed `!cat` directive and missing-target halts with `file:line`
     diagnostics → T39 DoD L2246 + test L2261.
   - `${CLAUDE_SKILL_DIR}` shipped-file halt → T39 DoD L2246-2247 + test
     L2262.

   Every AC #2 build-plugin halt now has a named, observable T39-level test
   expectation backing it. The criterion no longer relies on generic
   "fail-loud" phrasing for the build pipeline surface.

3. **G25/G29 absorbed-disposition framing (Overview L11)** — unchanged from
   round-06; absorption-by-CD-1 rationale documented with pointer to
   design.md ## G24/G25/G26/G29, and T11's [G29] → [G3] relabel preserves
   dispatch-manifest provenance trace continuity.

## Forward trace (goals → tasks → plan-authored criteria)

No regressions detected. All 35 approved goals continue to have at least one
covering task and at least one plan-authored test expectation (per-task or
per-phase). Sparse-numbering gaps (T18, T22, T23, T41, T42, T43) and the T11
relabel are documented in the Overview with disposition pointers to
design.md.

## Backward trace (tasks → goals/research)

No regressions detected. Every task in the plan continues to cite a
`goals: [...]` line and references both goals.md and design.md in its
References block. No scope-creep tasks introduced by the round-06 fixes.

## Gap analysis (design → plan)

The round-06 AC #2 enumeration closes the prior gap where design.md ## G32's
fail-loud commitments (D3 resolver halts) were only partially named in the
phase acceptance block. All four design-named halt classes now appear in
both AC #2 and T39's per-task test expectations.

## Spec-to-design fidelity

Phase/slice structure unchanged from prior rounds. T19 dep edge addition
aligns with design.md ## G27's documented dependence on the CD-1 routing
schema landing first.

## Decomposition check

No new amendment items introduced this round; existing G34/G35
decomposition mappings from prior rounds remain undisturbed.

## Bottom line

Round-07 broaden-vs-main is clean from a goal-traceability perspective. The
two round-06 surgical fixes (T19 dep edge, AC #2 T39 enumeration) preserve
forward/backward trace integrity and close the design.md ## G32 → AC #2
gap. No findings.
<!-- @@CLEAN: goal-traceability-codex.clean @@ -->
---
reviewer: codex
role: plan-goal-traceability-reviewer
round: 7
artifact: plan.md
result: clean
---

# Plan-Goal-Traceability Reviewer (Codex) — Round 7 — CLEAN

Reviewed broaden-vs-main diff. No traceability gaps.

Round-06 deltas (T19 dep edge, AC #2 T39 enumeration) trace cleanly from
goals → tasks → test expectations. No orphaned goals; no fabricated
test expectations.

Brief return text: `CLEAN`
<!-- @@CLEAN: quality-claude.clean @@ -->
---
reviewer: qrspi-plan-reviewer
artifact: plan.md
round: 7
route: full
result: clean
---

# Quality review — plan.md round 7 (broaden-vs-main)

No artifact-quality findings.

## Round-06 fix verification

**E1 — T19 dep edge on T16 (verified consistent across 3 surfaces):**
- L65 task list: `Task 19 — ... deps: [Task 16] — LOC: ~210 — sizing_exception: reusable primitives` ✓
- L1103 task spec: `Dependencies: Task 16. **Blocks:** Task 20.` ✓
- L974 T16 Blocks: enumerates `T17` and `T19 (extends scripts/_resolve-lib.sh with the host × vendor matrix and default-second-reviewer lookup helpers and the matrix-lookup-time [second-reviewer-same-vendor] halt)` ✓
- T20 deps at L66 still list `Task 19` (T19→T20 chain preserved) ✓
- T19's owned halt at L1136 DoD and the T16 Blocks paraphrase agree byte-for-byte on the diagnostic phrase
- Dependency-cause linkage is sound: T16 creates `scripts/_resolve-lib.sh`, T19 extends it with host × vendor matrix and the `[second-reviewer-same-vendor]` lookup-time halt

**E2 — AC #2 T39 halt enumeration (verified backed by T39 contract):**
- L22 AC #2 now appends 4 T39 halt classes after the pre-existing `tools/build-plugin.mjs resolves outside repository`:
  1. include-cycle halt with the full cycle printed → T39 L2224, L2261
  2. malformed `!cat` directive halt with `file:line` → T39 L2224, L2246, L2261
  3. missing-target halt with `file:line` → T39 L2224, L2246, L2261
  4. `${CLAUDE_SKILL_DIR}` shipped-file halt → T39 L2224, L2246, L2247, L2262
- All four halts are present in T39's DoD and Test expectations; no fabricated AC content
- Trailing clause `each produce non-zero exit with a diagnostic, never silent fallback` binds correctly across the full enumerated list

## Adjacent-surface scan

Re-read T16 (L966–1009), T17 (L1045–1093), T19 (L1095–1162), T20 (L1164+), and T39 (L2202–2283) for ripples from the round-06 edits. Found:
- T17 still claims `Dependencies: Task 16. Blocks: none.` — consistent with T16's Blocks list at L974 (T16 blocks T17 and T19; T17 blocks nothing further)
- T19 In/DoD/Test sections at L1113–1148 still correctly describe the work T16's Blocks-narrative attributes to T19
- T20 dep list `[Task 09, Task 11, Task 12, Task 13, Task 19]` unchanged and still satisfied
- T39 DoD (L2253) `resolves outside repository` halt language matches AC #2 verbatim; symlink-escape regression test at L2268 still references the matching diagnostic phrase

No new defects introduced by the round-06 edits.

## Previously-dropped findings — not re-raised

Per convergence rule, I considered but did not re-file:
- Dep-graph item 4 (L106) narrates T09/T11/T13 → T20 but omits T12 and T19 as T20 predecessors; the new T16→T19 edge is also not narrated in dep-graph items 1-4. This extends the qty-claude.F02 family (L110 dep-graph narrative misattribution, score 60 clarity) that round-06 verifier dropped. The round-06 fix scope was the edge itself, not narrative coverage; the verifier already adjudicated this issue class and no NEW defect was introduced by the round-06 fix.

## Sub-threshold observations (informational, not findings)

- AC #2 sentence at L22 now contains two `and` connectives in one giant comma-separated list (`...path-filter exfil guard in scripts/dispatch-agent.sh, and tools/build-plugin.mjs resolves outside repository... halts with file:line diagnostics, and tools/build-plugin.mjs ${CLAUDE_SKILL_DIR}...`). Mildly awkward but parseable; sub-threshold style.
<!-- @@CLEAN: quality-codex.clean @@ -->
---
reviewer: codex
role: plan-reviewer
round: 7
artifact: plan.md
result: clean
---

# Plan-Reviewer (Codex) — Round 7 — CLEAN

Reviewed broaden-vs-main diff. No artifact-quality findings.

Round-06 surgical fixes verified clean against quality criteria.

Brief return text: `CLEAN`
<!-- @@CLEAN: scope-claude.clean @@ -->
---
reviewer: scope-claude
artifact: docs/qrspi/2026-05-30-v072-release/plan.md
round: 07
verdict: clean
---

# Plan scope/boundary review — clean

Broaden-vs-main diff (round 07, full file). All 38 task specs evaluated against `skills/plan/owns-defers.md`.

## OWNS coverage (complete)

- **Ordered task specs.** 38 tasks in nine slice headings (1.1–1.7), sparse numbering (1–44 with documented gaps 18/22/23/41/42/43) and per-gap disposition rationales in Overview (L17). Cross-slice ordering perturbations (G4→G9, T11/T13/T09→T20) explicitly enumerated in Dependency Graph (L104–116).
- **Test expectations.** Plain-language behavioral bullets per task. No assertion code (`expect(...)`, `assert.*`, `toBe(...)`) encountered.
- **Dependencies.** Each task declares `Dependencies:` plus a reverse-edge `Blocks:` annotation; no forward dependencies detected.
- **LOC estimates.** Present on every task. Sizing exceptions declared and named (`reusable primitives`, `schema-migration`, `CI scaffolding`) — T12/T16/T19/T20/T25/T39 all carry the named exception per the closed exception set.

## DEFERS compliance (no leakage)

| DEFERS class | Lexical scan | Result |
| --- | --- | --- |
| Function signatures / parameter lists → structure.md | `fn(`, `=>`, parenthesized param lists | clean |
| `expect(`, `assert.`, `toBe(`, `assertEqual` → Implement-TDD | grep in Test Expectations | clean |
| `if/else`, `for`, `while`, line-numbered logic walkthroughs → Implement | scan of all Scope/Definition-of-done bullets | clean |
| "trade-off", "we considered", "alternative approach" → design.md | scan | clean (Out-of-scope deferrals point at design.md, do not re-argue) |
| "phase 2 will", "future phases", forward roadmap refs → phasing.md | scan | clean (forward deferrals named as design.md disposition pointers, not roadmap-style speculation) |

## Round-06 fix surfaces verified clean

- **T19 dep edge (L65 / L980 / L1109).** T19 declares `Dependencies: Task 16` at task header (L1109); T16 `Blocks:` line names T19 with rationale for the `_resolve-lib.sh` matrix extension (L980); dep-graph item 4 narrative is consistent (L65 region). No new drift.
- **AC #2 T39 enumeration extension (L22 = diff L28).** Fail-loud-invariant list extended with four build-pipeline halts: `tools/build-plugin.mjs` `resolves outside repository` (symlink-escape), include-cycle, malformed `!cat` / missing-target, and `${CLAUDE_SKILL_DIR}` shipped-file. Each is an observable halt with named diagnostic surface — appropriate cross-task acceptance behavior, not function signature or algorithm prose.

## Borderline cases (intentionally not flagged)

- **T39 DoD bullet on `fs.realpathSync` (L2259).** Names a Node stdlib facility with the `(or equivalent)` qualifier and frames the rule as "canonicalize BEFORE reading bytes." This is a behavioral ordering constraint plus a defensive-implementation pointer, not a function signature. Matches T21's parallel `assert_path_under_repo_root <label> <abs-path>` mention from prior rounds.
- **T40 lint detection patterns (L2310–2312).** The `[[ "$body" ... ]]` / `[ -n "$body" ]` / `^@test "..." \{` strings are the *content the lint detects*, i.e., the contract surface this task lands. Not pseudocode of the lint walker.
- **T34 sha256 normalization wording (L1953–1956).** Block-hash header format, position, and normalization rule are the contract Plan is documenting (post-approval-split-contract.md), surfaced as observable test expectations. Not Implement-layer logic.

## Length

2401 lines for 38 tasks (~63 lines/task aggregate). At the upper edge of the 1000–2000 soft band but not "well outside" (the rule's drift threshold is 4000 lines for over-spec). Proportional to a 35-goal release; acceptable for a single-phase hardening drop with cross-cutting CD-1/CD-4 anchors.

## Verdict

No scope/boundary findings. Round-06 fixes integrate cleanly without introducing drift into Structure, Implement, Implement-TDD, Design, or Phasing territory.
<!-- @@CLEAN: security-claude.clean @@ -->
---
reviewer: security-claude
artifact: plan.md
round: 7
verdict: clean
---

# Security Review — plan.md round 7 — clean

## Scope of this review

Broaden-vs-main review of `docs/qrspi/2026-05-30-v072-release/plan.md` round 7. Round 6 applied the AC #2 extension at L22 covering T39's four additional build-pipeline release-integrity halts (include-cycle, malformed `!cat`, missing-target, `${CLAUDE_SKILL_DIR}` shipped-file), addressing the prior round-06 finding `sec-claude.F01`. This review verifies byte-alignment with T39's DoD/Test and checks for any remaining release-integrity halts omitted from the AC.

## Verification

The four newly-enumerated build halts in AC #2 are byte-aligned with T39's DoD (L2240–2253) and Test Expectations (L2255–2268):

| AC #2 (L22) | T39 DoD/Test source | Alignment |
|---|---|---|
| `tools/build-plugin.mjs` include-cycle halt with the full cycle printed | T39 Scope L2224, DoD L2246, Test L2261, Test L2267 ("deliberate include-cycle failure with the required diagnostics") | ✅ byte-aligned including "full cycle printed" clause |
| `tools/build-plugin.mjs` malformed `!cat` directive and missing-target halts with `file:line` diagnostics | T39 Scope L2224, DoD L2246, Test L2261 | ✅ byte-aligned including `file:line` diagnostic surface |
| `tools/build-plugin.mjs` `${CLAUDE_SKILL_DIR}` shipped-file halt when any built file under `build/` still contains the legacy resolver token | T39 Scope L2224, DoD L2247, Test L2262/L2267 | ✅ byte-aligned |
| `tools/build-plugin.mjs` `resolves outside repository` halt (symlink-escape, carried over) | T39 DoD L2253 + Test L2268 | ✅ byte-aligned (verified in prior rounds) |

## Completeness — release-integrity halts not enumerated in AC #2

T39 DoD L2246 lists two additional D3 fail-loud conditions that AC #2 does not name explicitly:

- Absolute-path attempts (e.g., `!cat /any/path`)
- Path-traversal attempts (e.g., `!cat ../../foo`)

These are strict-grammar / portability enforcement halts. Their security-relevant failure mode — inlining content sourced from outside the repository — is fully captured by the already-enumerated `resolves outside repository` canonicalization halt at L22:

- An absolute path or traversal that escapes the repo canonicalizes outside `$REPO_ROOT/` and triggers the canonicalization halt before any byte enters `build/`.
- An absolute path or traversal that stays inside the repo is a portability/style defect, not a security exfil surface.

The AC #2 fail-loud-invariant clause therefore preserves the security property (no shipped content sourced from outside `$REPO_ROOT`) without separately enumerating these defense-in-depth grammar halts. This is not a security gap.

## Other categories

- **Fail-closed requirements** — Apply-fix sub-threshold instrumentation (AC #3) and verifier fan-in halt enumeration (AC #2, T02, T05, T06, T07) remain fail-loud across rounds 1–7; no regressions introduced by the round-07 diff.
- **Input validation** — T16 model_routing schema, T17 validation table, T20 splitter rename, T21 path-filter exfil guard, T34 plan post-approval split block-hash audit, and T39 resolver grammar all carry malformed-input rejection in DoD and Test Expectations. No new external-input surface introduced.
- **Auth/authz** — T19 second-reviewer-available check and T20 splitter rename collapse continue to gate dispatch on `_resolve-lib.sh` halts (`tier: none`, second-reviewer-same-vendor, second-reviewer-unavailable). All paths require explicit configuration; no permissive defaults.
- **No insecure defaults** — T22/T23 require explicit `model_routing:` (no silent default), T19 fails loud when second reviewer is requested but unavailable (no silent fallback to single reviewer), T39 fails loud on missing/malformed `!cat` includes (no silent skip). Round-07 introduces no new defaults.

## Verdict

Clean. The round-06 AC #2 extension is byte-aligned with T39's DoD and Test Expectations, and the security-relevant property of the build pipeline (no shipped content from outside `$REPO_ROOT`, no silent legacy-token leakage) is fully enumerated as an end-to-end-observable fail-loud invariant at phase boundary. Prior finding `sec-claude.F01` is resolved.
<!-- @@CLEAN: silent-failure-claude.clean @@ -->
---
reviewer: silent-failure-claude
round: 7
artifact: plan.md
status: clean
---

# Silent-failure review — round 7 (broaden-vs-main)

No silent-failure findings.

## Scope

Round-07 dispatch is broaden-vs-main (no `scope_hint` narrowing), so the
full plan.md surface was in scope. The round-06 surgical fixes that
triggered round-07 are:

1. **T19 dep edge** (L65 task list + L1103 T19 spec + L974 T16 spec) —
   `Dependencies: none` → `Dependencies: Task 16` plus a corresponding
   `Blocks:` extension on T16. This closes a fail-open scheduling gap
   where T19's matrix-lookup `[second-reviewer-same-vendor]` halt could
   land before its T16 foundation. The edit strengthens an AC #2
   fail-loud invariant by enforcing ownership ordering; it adds no new
   swallow/fallback/partial-state/log-continue surface.

2. **AC #2 T39 enumeration extension** (L22) — extended the master
   fail-loud bill-of-materials to enumerate four additional T39 build
   halts (`include-cycle` with full cycle printed, malformed `!cat`
   directive with `file:line`, missing `!cat` target with `file:line`,
   and `${CLAUDE_SKILL_DIR}` shipped-file halt). All four are
   anti-silent-failure additions: each ends with "produce non-zero exit
   with a diagnostic, never silent fallback" carried by AC #2's
   trailing clause. The Test phase reads AC #2 to construct seeded
   regressions, so naming the four halts in the AC blocks Test from
   marking AC #2 green without the seeds firing.

Both edits either tighten fail-loud posture or are structurally neutral
with respect to error visibility. No regression in silent-failure
posture, no newly introduced swallow/fallback/partial-state/
log-continue patterns.

## Pre-existing surfaces re-checked

- T16 L986 resolver precedence chain
  (`--tier-override → agent tier: → default_tier: → hardcoded medium
  with loud warning`) — pre-existing across all prior rounds, not
  flagged in round-06 by silent-failure-claude, and not touched in
  round-07. Treated as goals-permitted operator-facing fallback per
  CD-1; the "loud warning" is the operator-visible signal and the
  fallback target (`medium`) is a safe default. No regression.

- AC #2 master fail-loud bill — every enumerated halt continues to
  carry "produce non-zero exit with a diagnostic, never silent
  fallback" framing across the round-06 enumeration extension.

- Task DoD/Test Expectations surveyed for the round-06 edited tasks
  (T16, T19, T39) and their immediate dep neighbors (T17, T20, T21):
  every failure mode is paired with a non-zero exit + diagnostic
  artifact (audit JSON, `file:line`, or halt cause string). No new
  "log and continue" or "return empty on error" framings.

## Categories evaluated (all clean for round-07 delta)

1. **Swallowed errors** — none introduced or exposed by the
   round-06 edits.
2. **Silent fallbacks** — the enumeration extension explicitly
   adds "never silent fallback" framing to the four new T39 halts;
   no new silent-fallback surface.
3. **Partial state on failure** — T19 dep edge prevents a
   partial-resolver-state scenario where T19 helpers would extend a
   not-yet-created `scripts/_resolve-lib.sh` foundation. Improvement.
4. **Log-and-continue** — none introduced.

Continuing clean from round-06.
<!-- @@CLEAN: spec-claude.clean @@ -->
---
reviewer: spec-claude
round: 7
artifact: plan.md
diff_ref: main
status: clean
---

# Spec reviewer — no findings (round 7, broaden-vs-main)

## What I reviewed

Full plan.md broaden-vs-main diff (whole file, since main has no plan.md).
Focused on round-06's two surgical fixes and their spec-altitude coherence
across the artifact:

1. **T19 dep edge fix** — L65 (task list), L1103 (T19 spec), L974 (T16 Blocks).
2. **AC #2 T39 enumeration extension** — L22 (Phase 1 Acceptance Criteria).

## Verification results

### Fix 1: T19 → T16 dep edge

| Surface | Location | Status |
|---|---|---|
| Task list dep field | L65 | ✓ `deps: [Task 16]` |
| T19 per-task spec Dependencies | L1103 | ✓ `**Dependencies:** Task 16.` |
| T16 per-task spec Blocks | L974 | ✓ Enumerates T17 + T19 with structural reason ("extends `scripts/_resolve-lib.sh` ... matrix-lookup-time `[second-reviewer-same-vendor]` halt") |
| T19 DoD ownership of halt | L1136 | ✓ `_resolve-lib.sh`'s host × vendor matrix lookup halts loudly with `[second-reviewer-same-vendor]` |
| T19 test expectation for halt | L1148 | ✓ `test-routing-matrix-application.bats` proves halt behavior |
| T20 deps preserve chain | L1172 | ✓ `Task 09, Task 11, Task 12, Task 13, Task 19` — T16→T19→T20 chain intact |
| AC #2 still names halt | L22 | ✓ `_resolve-lib.sh` `[second-reviewer-same-vendor]` halt invariant present |

The structural ownership relocation from round-05 (T16→T19) is now backed
by an explicit dep edge. Parallel-execution schedulers cannot land T19
before T16 creates `_resolve-lib.sh`.

### Fix 2: AC #2 T39 halt enumeration extension

All four newly-enumerated T39 halts have matching backing in T39's task
spec:

| AC #2 enumeration item | T39 backing |
|---|---|
| `resolves outside repository` halt (symlink-escape) | Scope L2224 (outside-root); DoD L2253 (realpath canonicalization, `resolves outside repository` diagnostic); test L2268 (symlink-escape regression with matching diagnostic phrase) |
| include-cycle halt with the full cycle printed | Scope L2223-L2224 (cycle detection, full cycle printed); test L2261 (cycle failure case); acceptance fixture L2267 (deliberate include-cycle failure with required diagnostics) |
| malformed `!cat` directive and missing-target halts with `file:line` diagnostics | Scope L2224 (file:line plus reason for malformed lines and missing targets); test L2261 (malformed + missing-target failure cases) |
| `${CLAUDE_SKILL_DIR}` shipped-file halt | Scope L2224; DoD L2247 (shipped-file grep proves zero remaining); test L2262 (grep audit); acceptance fixture L2267 (legacy `${CLAUDE_SKILL_DIR}` directive failure) |

AC #2 is now bill-of-materials complete for T39's documented fail-loud
surface. Test phase can construct seeded regressions for all four halts.

## What I deliberately did not refile

The following surfaces were dropped in round-06 below threshold and the
underlying conditions are unchanged in round-07; re-filing would be noise:

- **L110 narrative description of dep ordering** (round-06 F02, clarity 60).
  Dep graph item 2 still mentions only T16→T17 (G22→G23) and not T16→T19,
  but per the section's own framing ("Three cross-slice dependency clusters
  dominate; everything else within-slice"), within-slice T16→T19 is
  correctly not enumerated. The dep edges themselves (L65/L1103) are the
  authoritative ordering signal.
- **T16/T19 carve-out symmetry stale wording** (round-06 F03, clarity 45).
  T16 scope L986 mentions "host/vendor routing lookup" and T19 scope L1116
  mentions "host × vendor matrix and default-second-reviewer lookup
  helpers". On careful reading these are non-overlapping (T16: tier→vendor
  base routing; T19: second-reviewer slot matrix extension), but the
  vocabulary overlap remains presentationally suboptimal. Below clarity
  threshold and acknowledged in disposition.

## Spec coverage check (random spot-check of 35 goals)

Confirmed goal→task→test-expectation traceability remains intact post-fix
for the surfaces touched by the round-06 edits:

- **G27** (T19) — problem framing (Claude-only Codex glob → silent Copilot
  opt-out) → T19 scope L1117 (Goals/using-qrspi migration) → T19 DoD L1130-L1136
  (probe behavior, halt diagnostics, same-vendor halt) → test expectations
  L1141-L1148 (executability, override boundary, shared-source, halt
  behaviors). Covered.
- **G22** (T16) — T19 dep addition does not change G22 surface coverage.
  T16's blocks line update is structural, not functional. Covered.
- **G32** (T39) — AC #2 extension brings master fail-loud enumeration into
  alignment with T39's own DoD/test expectations. No goal coverage change;
  the gap was that AC #2 omitted halts T39 already specified. Closed.

## Conclusion

Round-06's two surgical fixes are spec-coherent across all touch surfaces
(task list, per-task specs, AC #2, dep graph implications, T20 chain
preservation). No new spec-altitude defects introduced; no prior-round
findings re-surface above threshold. **Clean.**
<!-- @@CLEAN: spec-codex.clean @@ -->
---
reviewer: codex
role: plan-spec-reviewer
round: 7
artifact: plan.md
result: clean
---

# Plan-Spec Reviewer (Codex) — Round 7 — CLEAN

Reviewed broaden-vs-main diff (2401 lines, 38 tasks).

Round-06 fixes (T19 dep edge; AC #2 T39 enumeration) verified consistent
across all cited surfaces. No new spec-altitude defects. No re-raises
from dropped round-06 findings.

Brief return text: `CLEAN`
<!-- @@CLEAN: test-coverage-claude.clean @@ -->
# Test-coverage review — plan.md round 7 (broaden vs main)

**Reviewer:** claude (test-coverage)
**Artifact:** `docs/qrspi/2026-05-30-v072-release/plan.md`
**Round:** 7
**Diff ref:** `<base-branch>` (broaden — full plan.md vs main)
**Disposition:** **CLEAN — no new test-coverage findings**

## Round-06 changes reviewed

Two surgical fixes landed in round-06; both stay within the existing test-coverage
envelope:

### 1. T19 dep edge addition (L65 / L974 / L1103)

Added Task 16 as a `Dependencies:` entry for Task 19, and the symmetric
`Blocks: T19` entry on Task 16. Pure sequencing change.

T19's test expectations (L1140–L1148) already cover:
- `_host-detect.sh` source-safety + four host signals
- `second-reviewer-available.sh` exit 0 on Copilot/Claude defaults
- Override-boundary tests for `<vendor>` arg
- Shared-source assertion against parallel hardcoded host tables
- Grep audits for Codex-glob removal across Goals/using-qrspi/reviewer-protocol
- Routing-matrix same-tier fan-out + `[second-reviewer-unavailable]` halt
- `[second-reviewer-same-vendor]` halt at matrix-lookup time

All of the above functionally depend on T16's `_resolve-lib.sh` schema. The
round-06 dep edge merely ensures the schema lands first so T19's tests can
execute against it; it does not change what T19 verifies. No new edge cases,
error conditions, or behavioral coverage gaps introduced. ✓

### 2. AC #2 T39 fail-loud enumeration extension (L28)

Added four `tools/build-plugin.mjs` fail-loud invariants to the cross-task
Phase 1 AC #2 enumeration. Each traces to a specific, falsifiable T39 test
expectation:

| AC #2 invariant | T39 test expectation trace |
|---|---|
| `resolves outside repository` halt (symlink-escape exfil) | L2268 — explicit stderr diagnostic containing `resolves outside repository`, fixture commits a `!cat`-targeted symlink whose canonical target is outside `$REPO_ROOT` |
| Include-cycle halt with full cycle printed | L2261 — "include cycles with full cycle printed" listed as a unit-test resolver failure case |
| Malformed `!cat` directive and missing-target halts with `file:line` diagnostics | L2261 — both failure cases listed; AC #2 itself names `file:line` as the falsifiable signal, so the Test phase generates a phase-level assertion against the diagnostic shape |
| `${CLAUDE_SKILL_DIR}` shipped-file halt | L2261 — "`${CLAUDE_SKILL_DIR}` in shipped files" listed as a resolver failure case; L2262 — grep audit confirms no shipped file contains the token |

The AC #2 enumeration extension actually **improves** test verifiability by
elevating these four invariants from T39-only DoD/test-expectation scope into
the cross-task phase-level acceptance enumeration. The Test phase will now
generate dedicated phase-level acceptance tests for each invariant, in
addition to T39's per-task tests. ✓

## Cross-checking all five criteria against the round-06 surface

1. **Behavioral coverage** — T19 happy path (probe exit 0 for Copilot/Claude
   defaults) and T39 happy path (exit 0 + reproducible `build/` tree) both
   pinned with observable, deterministic expectations.

2. **Edge cases** — T19 covers unknown host, missing default vendor, unknown
   vendor, unavailable vendor, and same-vendor primary/second-reviewer
   collision. T39 covers idempotent re-run, transitive nested includes, CR
   stripping, absolute paths, path traversal, symlink-escape.

3. **Error conditions** — T19 names two specific stderr prefixes
   (`[second-reviewer-unavailable]`, `[second-reviewer-same-vendor]`) plus
   non-zero exit. T39 names specific diagnostic phrases (`resolves outside
   repository`, "full cycle printed", `file:line`) plus non-zero exit. All
   error paths supply the falsifiable signal the Test phase needs.

4. **Test expectation quality** — Every test expectation added or implied by
   the round-06 changes is specific (names exact diagnostic strings, exact
   exit codes, exact field names), observable (stderr, exit code, file
   contents, grep), deterministic, and falsifiable.

5. **Missing scenarios from design** — None introduced. The round-06 AC #2
   enumeration extension closes a prior gap by ensuring design.md ## G32's
   D3 fail-loud conditions are mirrored at the phase-level acceptance layer,
   not just per-task DoD.

## Scope-hint compliance

No `scope_hint` provided this round (broaden); reviewed the full diff against
main. The two round-06 changes are the only surfaces with new test-coverage
implications; everything else in the diff is the existing plan body already
reviewed in rounds 1–6.

## Verdict

CLEAN. The round-06 dep-edge and AC #2 enumeration fixes both land cleanly
against existing test expectations and introduce no new vague, missing, or
unfalsifiable test scenarios. Plan is ready for downstream Test-phase
acceptance-test generation from the test-expectation surface as-is.
