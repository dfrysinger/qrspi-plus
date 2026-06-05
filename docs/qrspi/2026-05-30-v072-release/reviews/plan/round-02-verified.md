---
verifier_enabled: true
scored: 29
kept: 11
dropped: 18
failed: 0
clean: 3
---

<!-- @@FINDING: goal-traceability-codex.finding-F01 @@ -->
---
reviewer_tag: goal-traceability-codex
change_type: correctness
severity: high
artifact: plan.md
location: "Tasks 11, 18, 41 — G25/G26/G29 absorbed-goal status"
referenced_files:
  - plan.md
  - design.md
---

# F01 — Plan creates standalone tasks for goals design marked moot/absorbed

## Defect

Design.md explicitly says no separate v0.7.2 task ships under these goal IDs:
- G25: design.md ~2110 ("no separate v0.7.2 task ships under the G25 ID")
- G26: design.md ~2151 (same wording)
- G29: design.md ~2336 (same wording)

Plan still creates standalone tasks:
- Task 18 → G25
- Task 41 → G26
- Task 11 → G29

## Impact

Plan violates design's CD-level decisions. If the goals were absorbed into other goals' work, the standalone tasks duplicate that work, create coordination overhead, and re-introduce content design explicitly retired.

## Recommended fix

Either (a) verify that T11/T18/T41 actually carry distinct work that wasn't absorbed by their merging goals (and update their goal-ID references in the spec to reflect the absorbing goal), OR (b) remove the standalone tasks and merge any residual work into the absorbing tasks. The design.md absorption language is the source of truth.

## Verification note

Need to cross-check whether T11/T18/T41 specs actually duplicate other tasks' work, OR whether they carry residual scope the absorption didn't cover. If the latter, they should be re-labeled with the absorbing goal's ID + "residual" qualifier; if the former, removed.
<!-- @@SCORE: goal-traceability-codex.finding-F01.score @@ -->
score: 70
reason: Task 18's scope ("Add a single top-level invariant paragraph at the start of the dispatch-routing section") directly does what design.md ## G25 lists as an explicit non-goal ("throwaway work" against pre-CD-1 prose CD-1 deletes); T11/T41 are partial hits where the bodies carry CD-1/G21-amendment work that design.md retargets but the plan still labels with the absorbed Goal IDs and lists them as standalone tasks.
<!-- @@FINDING: goal-traceability-codex.finding-F02 @@ -->
---
reviewer_tag: goal-traceability-codex
change_type: correctness
severity: high
artifact: plan.md
location: "Tasks 22, 23, 42, 43, 44 — G24 re-scope"
referenced_files:
  - plan.md
  - design.md
---

# F02 — G24 re-scope mismatch: design locks to F05 only, plan still schedules F01/F02/F03/F04 work

## Defect

Design re-scopes G24 to F05 only (design.md ~2045–2066): F01/F03/F04 marked moot and F02 deferred/absorbed.

Plan still includes G24 tasks beyond F05:
- Task 22 → F02
- Task 23 → F04
- Task 42 → F01
- Task 43 → F03
- Task 44 → F05 (this one matches design)

## Impact

Plan schedules four tasks (T22, T23, T42, T43) whose underlying F-scopes design has retired. Duplicates work or re-introduces retired scope.

## Recommended fix

Either (a) verify whether T22/T23/T42/T43 carry distinct value beyond G24's F-scope (and if so, re-label their goal-ID to whatever absorbing goal owns them), OR (b) remove the standalone tasks. Design's re-scope is the source of truth.

## Verification note

This is a high-severity finding because four tasks are potentially mis-scoped, which would inflate Phase 1 by ~8% (4/44 tasks) on work design retired.
<!-- @@SCORE: goal-traceability-codex.finding-F02.score @@ -->
score: 78
reason: Verified: design.md ## G24 re-scopes to F05 only (F01/F03/F04 moot, F02 deferred to G25 as side-effect), yet plan schedules T22/T23/T42/T43 as standalone G24 tasks executing the retired/reassigned F-scopes — a real plan↔design contradiction across ~4 of 44 tasks.
<!-- @@FINDING: goal-traceability-codex.finding-F03 @@ -->
---
reviewer_tag: goal-traceability-codex
change_type: correctness
severity: high
artifact: plan.md
location: "Plan Phase 1 Acceptance Criteria, first bullet"
referenced_files:
  - plan.md
  - design.md
---

# F03 — Acceptance criteria still use deprecated `codex_reviews` field

## Defect

Design locks rename `codex_reviews` → `second_reviewer` and says legacy name is deleted from prose/templates (design.md ~2178–2210).

Plan Phase 1 acceptance criteria first bullet still requires `codex_reviews: true`.

## Impact

Plan's Phase 1 gate would pass when the new field name fails. Direct violation of design's locked rename decision.

## Recommended fix

Replace `codex_reviews: true` with `second_reviewer: true` (or whatever the new schema's truthy value is) in the Phase 1 Acceptance Criteria. Sweep the rest of the plan document for other surviving `codex_reviews` references and normalize.

## Severity rationale

High because the acceptance criteria is the phase-completion gate. A gate that checks the wrong field name passes the wrong work and silently misses the rename's enforcement.
<!-- @@SCORE: goal-traceability-codex.finding-F03.score @@ -->
score: 80
reason: Verified — plan.md L21 still uses `codex_reviews: true` though design D1/D6 (L2178, L2209) lock the rename to `second_reviewer:` with the legacy name treated as a hard validation error; the phase-completion gate as written tests an invalid field.
<!-- @@FINDING: quality-claude.finding-F01 @@ -->
---
reviewer_tag: quality-claude
change_type: correctness
severity: high
artifact: plan.md
location: "Task 37 (G35 Structure SKILL absorbs unified architecture content)"
---

# F01 — T37 Target list contradicts its own Scope-Out, Definition of Done, and Test expectations after round-01 added the lint test

## Defect

The round-01 fix added a fourth Target file to T37 — `tests/lint/test-structure-altitude-boundary-include.bats (create)` — but the rest of the task body still says "no test code." Three separate places in the spec now contradict the Target list:

1. **Out** (line 2285):
   > "Test-code or lint-test additions for the include guard — explicitly out of this prompt-prose task."

   This explicitly excludes the very file the Target list now tells the implementer to create.

2. **Definition of done** (line 2296):
   > "The task does not edit reviewer agents, add test code, assume unresolved runtime `!cat` expansion beyond the primitive's intended source form, introduce implementation-level test assertions, or rewrite unrelated Structure procedures."

   "Does not … add test code" is a direct contradiction with creating `tests/lint/test-structure-altitude-boundary-include.bats`.

3. **Test expectations** (line 2304):
   > "Scope audit confirms no reviewer-agent edits, no test-code additions, no implementation-level test assertions, and no unrelated Structure procedure rewrites were introduced by this task."

   The acceptance check itself would fail the task for creating the file the Target list requires.

The **In** section (lines 2276–2280) also has no bullet authoring the lint test's contents, so even if the implementer believes the Target list, they have no guidance for what the file must contain or assert.

## Impact

The implementer running T37 cannot satisfy both Target and Out/DoD/Test simultaneously. Either:
- they create the lint file as Target says → the post-implementation scope audit (Test expectations line 2304) fails the task, and the DoD "does not add test code" clause is violated; or
- they skip the lint file to honor Out/DoD/Test → the Target list is unsatisfied, and the structure-altitude-boundary include guard ships untested.

This is the classic round-01 patch-collision pattern: the Target list was updated without sweeping the Scope/DoD/Test prose, leaving the spec self-contradictory.

## Recommended fix

Pick one resolution and apply it through the whole task body:

**Option A — keep the lint test in scope (preferred, matches T29's symmetric round-01 fix):**
- Add an explicit In bullet authoring the lint test's contents (e.g., "Create `tests/lint/test-structure-altitude-boundary-include.bats` asserting that `agents/qrspi-structure-scope-reviewer.md` contains the literal `!cat skills/_shared/structure-altitude-boundary.md` directive on the line immediately after the introducer prose, and that `skills/structure/owns-defers.md` contains the same directive in place of the previous inline body").
- Delete the Out bullet at line 2285 ("Test-code or lint-test additions for the include guard").
- Delete or rewrite the DoD clause at line 2296 to drop "add test code" from the negative list (the include-guard lint is the one exception).
- Delete or rewrite the Test-expectations scope-audit clause at line 2304 to allow the named lint file under `tests/lint/`.
- Add a DoD line and a Test-expectations line that pin the lint test's required assertions.

**Option B — keep the lint test out of scope:**
- Remove `tests/lint/test-structure-altitude-boundary-include.bats (create)` from Target files at line 2266.
- Defer the include-guard lint to a follow-up task (or absorb it into T38, the reviewer-enforcement sibling).

Apply the same resolution direction to T29 (see F02) so the two sibling altitude-boundary tasks stay symmetric.
<!-- @@SCORE: quality-claude.finding-F01.score @@ -->
score: 85
reason: Verified — Target list line 2266 adds the bats lint file while Out (2285), DoD (2296), and Test-expectations scope audit (2304) all explicitly forbid test-code additions, leaving the task spec internally unsatisfiable.
<!-- @@FINDING: quality-claude.finding-F02 @@ -->
---
reviewer_tag: quality-claude
change_type: correctness
severity: medium
artifact: plan.md
location: "Task 29 (G34 Design scope-reviewer alignment with detailed-solution boundary)"
---

# F02 — T29 Out/DoD still say "three target files" after round-01 expanded the Target list to four, and the lint test has no In/DoD/Test coverage

## Defect

The round-01 fix expanded T29's Target list from three files to four — adding `tests/lint/test-design-altitude-boundary-include.bats (create)` — but the rest of the task body was not swept to match. Three problems remain:

1. **Out section literal mismatch** (line 1819):
   > "Adding or modifying files outside the three target files, unless a directly coupled include-resolution break prevents those files from being valid."

   This still says "three target files" while the Target list at line 1797 names four. The implementer cannot tell whether the lint test is in scope (Target says yes; Out's "three target files" formulation implies the lint file *is* one of the "outside the three" cases this very clause prohibits).

2. **DoD literal mismatch** (line 1838):
   > "Diff audit confirms only the three target files changed, unless the implementer documents a directly coupled include-resolution break."

   The post-implementation diff will show four changed files (or three modified + one created), which causes this check to fail on its face.

3. **In bullets and Test expectations never mention the lint test** (lines 1807–1811 and 1833–1839). There is no In bullet authoring the file's required assertions and no Test-expectations bullet validating its behavior. The implementer who creates the file from the Target list alone has no spec for what the file must contain; the reviewer has no acceptance check to run on it.

## Impact

Less severe than the T37 sibling defect (F01) because T29's Scope/DoD does not include an *explicit prohibition* against test code — but the numeric "three target files" wording in Out and DoD still actively rejects the very file the Target list adds, and the absence of any In/DoD/Test bullet for the lint test means it would either ship empty/trivial or be skipped silently.

## Recommended fix

Apply the same resolution direction chosen for T37/F01 so the two sibling altitude-boundary tasks stay symmetric. For Option A (keep lint test in scope, preferred):

- Replace "three target files" with "four target files" (or just "target files") at line 1819 (Out) and line 1838 (DoD).
- Add an In bullet authoring the lint test contents — e.g., "Create `tests/lint/test-design-altitude-boundary-include.bats` asserting that `agents/qrspi-design-scope-reviewer.md` contains the literal `!cat skills/_shared/design-altitude-boundary.md` directive on the line immediately after the Step 1 Read citation introducer prose, and that `skills/design/owns-defers.md` contains the same directive in place of the previous inline contract body."
- Add a DoD bullet pinning the lint test's required assertions.
- Add a Test-expectations bullet running/inspecting the lint test.

For Option B (remove lint test):
- Delete `tests/lint/test-design-altitude-boundary-include.bats (create)` from Target files at line 1797 and leave "three target files" wording in place.

Either way, T29 and T37 should resolve in the same direction so the two altitude-boundary tasks remain structurally symmetric.
<!-- @@SCORE: quality-claude.finding-F02.score @@ -->
score: 78
reason: Verified all three sub-claims in plan.md — Target list at line 1797 names four files while Out (1819) and DoD (1838) still say "three target files", and no In/Test bullet authors or validates the new lint .bats file; this is a concrete correctness inconsistency the implementer/reviewer will hit.
<!-- @@FINDING: quality-codex.finding-F01 @@ -->
---
reviewer_tag: quality-codex
change_type: correctness
severity: medium
artifact: plan.md
location: "Task 42 — Target files"
referenced_files:
  - plan.md
---

# F01 — Task 42 uses non-deterministic target-file selector instead of exact paths

## Defect

T42's Target files row at plan.md:2577 uses placeholder/selector language:

> `tests/unit/test-agent-frontmatter-no-model.bats` **or** `tests/acceptance/v07-phase1/test-t10-*.bats` successor

The "**or**" plus the `*` glob means the spec doesn't pin which file the implementer is expected to create/edit, and the auto-applied check "No placeholders / exact file paths" cannot pass deterministically.

## Impact

Implementer ambiguity — two implementers would defensibly produce two different file layouts. Downstream test selectors (acceptance harnesses, lint harnesses) cannot be wired against an unknown path.

## Recommended fix

Pick one exact path. If the choice is genuinely conditional on T40's outcome, document the resolution rule in the Dependencies section ("If T40 produced X, target is Y; otherwise target is Z") and pin both candidates as explicit conditional targets, not an `or`.
<!-- @@SCORE: quality-codex.finding-F01.score @@ -->
score: 55
reason: Target files row genuinely uses "or" + glob (placeholder-like, violates plan overview's "exact file paths" promise), though the Scope "In" bullet does provide a deterministic resolution rule (start with the unit file, only fall back if historical file still exists), partially mitigating implementer ambiguity.
<!-- @@FINDING: quality-codex.finding-F02 @@ -->
---
reviewer_tag: quality-codex
change_type: correctness
severity: medium
artifact: plan.md
location: "Task 43 — Target files"
referenced_files:
  - plan.md
---

# F02 — Task 43 target-file list contains conditional/optional path language

## Defect

T43's Target files row at plan.md:2635 contains:

> `tests/unit/test-using-qrspi-routing-block.bats` **if present after Task 42**

The "**if present after Task 42**" clause makes the file's existence conditional on a sibling task's deliverable, but the Dependencies row doesn't pin T42 as a hard dep, and the conditional logic isn't reflected in the DoD or Test expectations.

## Impact

Spec is not implementable as written: if T42 chooses the other branch from its F01 ambiguity, T43's target doesn't exist and the spec has no fallback. Implementer must make scope decisions the planner should have made.

## Recommended fix

Either (a) make T43 unconditionally responsible for creating the file and add T42 as a hard Dependencies entry, or (b) split T43 into two variants keyed off T42's resolution and make the variant selection explicit. Same pattern as F01.
<!-- @@SCORE: quality-codex.finding-F02.score @@ -->
score: 18
reason: Finding's core factual claims are wrong — Dependencies pins T42 as a hard dep, and the conditional is explicitly reflected in DoD, Test expectations, and Out-scope; spec IS implementable as written.
<!-- @@FINDING: scope-codex.finding-F01 @@ -->
---
reviewer_tag: scope-codex
change_type: scope
severity: medium
artifact: plan.md
location: "Multiple tasks (T21, T34, T39)"
referenced_files:
  - plan.md
---

# F01 — Implementation-detail drift from Plan into Structure/Implement altitude

## Defect

Several task specs encode implementation contracts that belong at Structure or Implement altitude:

- T21 specifies `assert_path_under_repo_root <label> <abs-path>` — a function signature, which is Structure's domain.
- T34 specifies hash/normalization mechanics — algorithm detail, which is Implement's domain.
- T39 specifies resolver grammar and fail paths — implementation logic, which is Implement's domain.

## Impact

Plan-altitude tasks should specify observable behavior, not function shapes or algorithm internals. Drift downward over-constrains the implementer, replicates content in Structure/Implement, and creates drift risk between Plan and Structure on the same surface.

## Recommended fix

Per the F-5 fix-altitude rule in using-qrspi: minimal additions. Restate these as observable-behavior bullets ("path-validation helper rejects paths outside the repo root with diagnostic `<exact-string>`") and let Structure/Implement own the function shape and algorithm grammar.

## Counter-argument to consider

Several of these specifications were intentional during the v0.7.2 round-01 fixes (e.g., T39's symlink canonicalization clause is a security regression fence). Declining this finding for tasks where the implementation detail is load-bearing for the security invariant may be defensible per the fix-altitude rule's "decline scope-extension findings" guidance.
<!-- @@SCORE: scope-codex.finding-F01.score @@ -->
score: 55
reason: T21 plainly carries a function signature, which violates Plan SKILL's explicit "no function signatures (→ Structure)" rule at template line 222; T34/T39 cites are borderline (contract vs. algorithm/grammar) and the finding's own counter-argument concedes some are intentional fences, so the finding is real but mixed in scope.
<!-- @@FINDING: scope-codex.finding-F02 @@ -->
---
reviewer_tag: scope-codex
change_type: scope
severity: low
artifact: plan.md
location: "Multiple tasks — Test expectations sections"
referenced_files:
  - plan.md
---

# F02 — Test-code assertion leakage in Plan-level Test Expectations

## Defect

Many tasks' Test Expectations include test-code and assertion specifics: exact grep commands, exact stderr strings, exact fixture mechanics. This exceeds Plan's plain-language test-expectation boundary per `skills/plan/owns-defers.md`.

## Impact

Drift downward from Plan into the test-writer's territory. Replicates content the implementer's test-writer subagent will produce, and creates drift risk between Plan's pinned strings and the actual implementation's emitted strings.

## Recommended fix

Restate as plain-language behavior bullets ("verifier exits non-zero with a diagnostic that mentions the missing field") rather than literal command snippets. Reserve literal-string expectations for cases where the exact wire format is part of the public contract (e.g., diagnostic strings users grep for in CI).

## Counter-argument to consider

Some literal-string expectations are intentional: the diagnostic strings ARE the public contract (operators grep for them). The F-5 fix-altitude rule's "decline scope-extension findings" guidance may apply for those bullets; restrict the fix to the genuinely-internal mechanics.
<!-- @@SCORE: scope-codex.finding-F02.score @@ -->
score: 25
reason: Test Expectations describe behaviors in plain language and only quote public-contract identifiers (file paths, halt-cause names, enum values, sentinel strings) — none of the documented lexical-leakage signals (`expect(`, `assert.`, `toBe(`, etc.) appear, the finding cites no specific offending task, is self-rated low, and its own counter-argument concedes most quoted strings are intentional public contract.
<!-- @@FINDING: scope-codex.finding-F03 @@ -->
---
reviewer_tag: scope-codex
change_type: scope
severity: low
artifact: plan.md
location: "Plan-wide — Phase 1 Acceptance Criteria + cross-slice narrative"
referenced_files:
  - plan.md
---

# F03 — Phasing/design boundary drift

## Defect

The plan document includes substantial phasing/roadmap and architecture-style content beyond Plan OWNS:
- Phase-wide release governance criteria
- Slice authoring/orchestration narrative
- Cross-slice release management details

These belong to Phasing (phase boundaries, replan-gate criteria) and Design (architecture trade-offs) respectively.

## Impact

Plan's role is decomposition of approved upstream artifacts into task specs, not re-derivation of phase or architecture content.

## Recommended fix

Move phasing/release-governance content into `phasing.md` (already approved) and architecture narrative into `design.md` (already approved). Replace in-plan with one-line references ("Phase 1 acceptance criteria: see phasing.md § Phase 1 Replan Gate").

## Counter-argument to consider

The Phase 1 Acceptance Criteria block aggregates per-task observable behaviors at the phase boundary — scope-claude's round-02 review explicitly cleared this as "a natural extension of Plan's per-task Test Expectations OWNS rather than Phasing's replan-gate-criteria DEFERS." Codex's call may be the false positive of the two.
<!-- @@SCORE: scope-codex.finding-F03.score @@ -->
score: 30
reason: Low-severity boundary judgement call — items #6/#7 of plan.md's Phase 1 Acceptance Criteria do duplicate phasing.md's Acceptance gate items 2/3, but the block as a whole is defensible as cross-task aggregation of Plan's "Test expectations" OWNS; the author self-flags it as likely the false positive and scope-claude cleared it.
<!-- @@FINDING: scope-codex.finding-F04 @@ -->
---
reviewer_tag: scope-codex
change_type: scope
severity: low
artifact: plan.md
location: "Plan-wide — artifact length"
referenced_files:
  - plan.md
---

# F04 — Plan length over-expansion vs OWNS concision target

## Defect

Artifact length (2742 lines / 44 tasks, ~62 lines/task) is materially beyond the Plan soft top band (~2000 lines per `skills/plan/owns-defers.md` guidance, ~52 lines/task baseline). Repeated rationale/reference prose reads like downstream design/implementation contract text rather than negotiable plan scope.

## Impact

Plan-altitude artifacts that grow too large dilute the per-task spec signal and increase main-chat context cost during Implement dispatch.

## Recommended fix

Compress per-task References sections — replace verbose citation prose with anchor-only references (e.g., "See design.md §G31" instead of paragraphs of paraphrased design content).

## Counter-argument to consider

Scope-claude round-02 explicitly cleared this dimension: "Length: 2742 lines / 44 tasks ≈ 62 lines/task — close to Keeplii ~52 baseline; aggregate ~37% over the 2000-line soft top but accounted for by per-task References overhead; not 'well outside' the band." The per-task overhead is intentional (the v0.7.3 enhanced shape from issue #292 we authored mid-pipeline).
<!-- @@SCORE: scope-codex.finding-F04.score @@ -->
score: 25
reason: Length (2742 lines) does exceed the 1000-2000 soft band per owns-defers.md, but the band is explicitly "soft target, not a ceiling," the per-task Overview/References overhead is intentional v0.7.3 shape (issue #292), and the finding's own counter-argument shows scope-claude cleared this same dimension in the same round — making this a low-severity stylistic nit rather than a real boundary-drift defect.
<!-- @@FINDING: security-claude.finding-F01 @@ -->
---
reviewer: security-claude
round: 2
artifact: plan.md
severity: medium
change_type: correctness
finding_id: F01
task: T39
goal: G32
---

# F01 — T39 symlink canonicalization covers only `!cat` targets; tree-copy phase still follows checked-in symlinks out of repo

## Where

- `plan.md` Task 39 (G32 plugin build pipeline), **Definition of done** line 2420 and **Test expectations** line 2435 (the round-01 symlink-escape clauses).
- Adjacent T39 lines 2389, 2392, 2409 (tree-copy / runtime-include-list behavior).

## What the plan requires

The round-01 hardening (DoD bullet 2420 + Test bullet 2435) says:

> `tools/build-plugin.mjs` canonicalizes **every `!cat` target path** with `fs.realpathSync` (or equivalent) BEFORE reading the target's bytes, and fails non-zero with a `resolves outside repository` diagnostic when the canonical path is not lexically prefixed by the canonical `$REPO_ROOT/`.

> **Symlink-escape regression**: a fixture commits a **`!cat`-targeted file** that is itself a symlink whose canonical target is outside `$REPO_ROOT` …

Both clauses scope the canonicalization to the `!cat` *resolver* (the directive-expansion code path). The build script also performs a **separate** tree-copy operation per DoD line 2409 and Scope-In bullets at lines 2389/2392:

> `node tools/build-plugin.mjs` creates a reproducible `build/` tree … using `.claude-plugin/plugin.json` component paths plus the fixed runtime include list: **`scripts/`, `templates/`, `LICENSE`, `README.md`, optional `AGENTS.md`/`CLAUDE.md`, and `.claude-plugin/`**.

> Copy runtime plugin content and defensive shared snippets into `build/`, while omitting dev-only paths …

This is a distinct code path from the `!cat` resolver. The plan never requires that the **copy** phase canonicalize each source path under `$REPO_ROOT/` before reading bytes into `build/`.

## Risk (fail-open / exfil class)

This leaves the same symlink-escape exfil surface open via the tree-copy path that round-01 just closed for `!cat`:

1. A checked-in symlink at e.g. `scripts/foo.sh → /etc/passwd`, `templates/x.md → ../../../private-key`, or `skills/_shared/foo.md → /var/log/secret` is followed by Node's standard file-copy primitives (`fs.copyFileSync` and `fs.cpSync` follow source symlinks by default; only the rarely-used `verbatimSymlinks: true` option preserves them).
2. The build script copies that source path into the corresponding `build/...` location, **inlining the referent's bytes** into a shipped artifact.
3. The shipped plugin (`build/` is committed and `marketplace.json` points install at `./build` per DoD 2416) carries the exfiltrated content.

The threat model is identical to the `!cat` symlink-escape class round-01 patched: a single malicious commit (or a compromised developer machine that creates the symlink before staging) escalates into shipped exfil content, with the build pipeline as the only effective guardrail. PR review can miss a symlink stat (`git diff` shows the symlink target as a text line but reviewers may not recognize the escape). The shipped `${CLAUDE_SKILL_DIR}` grep (DoD 2414) does **not** catch this — leaked secrets don't contain that token.

The same defensive primitive (`realpath` / `fs.realpathSync` + canonical-prefix check + `resolves outside repository` diagnostic) already named in the round-01 clause is the correct fix; the round-01 clause just needs to bind it to the broader file-read surface, not only the `!cat` resolver.

## What's missing (concrete clauses to add to T39)

1. **DoD addition** — pair with line 2420:
   > `tools/build-plugin.mjs` canonicalizes every source path it reads or copies into `build/` (runtime include list members `scripts/`, `templates/`, `LICENSE`, `README.md`, `AGENTS.md`/`CLAUDE.md`, `.claude-plugin/`, and the `skills/` source tree — every regular file enumerated by recursive directory walks, not only `!cat` targets) with `fs.realpathSync` (or equivalent) BEFORE reading the file's bytes, and fails non-zero with a `resolves outside repository` diagnostic when the canonical path is not lexically prefixed by the canonical `$REPO_ROOT/`. The copy operation uses `fs.lstatSync` + `fs.realpathSync` instead of symlink-following copies so that source symlinks whose canonical targets lie outside `$REPO_ROOT/` cannot inline out-of-repo bytes into the shipped tree.

2. **Test-expectations addition** — pair with line 2435:
   > **Tree-copy symlink-escape regression**: a fixture commits a regular file *under one of the copied runtime paths* (e.g. `scripts/<name>.sh`, `templates/<name>.md`, or `skills/_shared/<name>.md`) that is itself a symlink whose canonical target is outside `$REPO_ROOT/` (e.g. `/etc/passwd` or `/tmp/secret-fixture`); the build fails non-zero before any byte of the symlink's referent enters the `build/` tree, with a stderr diagnostic containing `resolves outside repository`. Distinct regression from the `!cat`-target symlink fixture in line 2435; both fixtures must pass for the build to be considered hardened.

## Why this matters at plan level

An implementer building exactly what the plan currently says will (correctly) harden the `!cat` resolver path and leave the tree-copy path open, because the DoD literally scopes canonicalization to `!cat` targets ("canonicalizes every `!cat` target path"). Without the additions above, the residual symlink-escape exfil channel ships with v0.7.2, and the round-01 patch reads as a complete fix when it is in fact only half of the surface. Adding the clauses now keeps the symlink-canonicalization story coherent (one defensive primitive applied uniformly to every source path the build pipeline reads).
<!-- @@SCORE: security-claude.finding-F01.score @@ -->
score: 58
reason: Verified — T39 DoD line 2420 and Test bullet 2435 do scope symlink canonicalization to `!cat` targets only, leaving the D2 tree-copy phase (lines 2409/2389/2392) unguarded; the same exfil threat-model the round-01 patch closes for `!cat` (committed symlink → /etc/passwd inlined into shipped `build/`) applies to recursive copies of `scripts/`, `templates/`, etc. when `fs.copyFileSync` or `fs.cpSync` with `dereference: true` follows source symlinks, so the proposed symmetric DoD + test clauses are a coherent plan-altitude defense-in-depth ask — but the residual surface is narrower than round-01's (requires a committed malicious symlink, more visible to PR review) and Node's default `cpSync` behavior preserves symlinks rather than inlining bytes, so this reads as a meaningful-but-not-critical hardening rather than a smoking-gun exfil bypass.
<!-- @@FINDING: security-codex.finding-F01 @@ -->
---
reviewer_tag: security-codex
change_type: correctness
severity: medium
artifact: plan.md
location: "Task 16 — G22 model_routing schema and resolver"
referenced_files:
  - plan.md
---

# F01 — Invalid config can silently degrade to default routing (fail-open / insecure default)

## Defect

T16 spec preserves resolver precedence ending in a hardcoded `medium` fallback with warning. Test expectations also pin this behavior.

## Impact

Default substitution on invalid/incomplete config rather than hard failure routes work with unintended model/vendor settings when config is broken, reducing operator control and making failures non-obvious. This is the silent-fallback-to-hardcoded-model class G22 sets out to eliminate.

## Recommended fix

Replace the hardcoded `medium` fallback with a hard halt and non-zero exit when config is incomplete. The "loud warning" path is exactly the silent-failure pattern the v0.7.2 release is trying to close.

## Duplicate-of note

Same root issue as silent-failure-codex.F01 and silent-failure-claude.F01. Verifier/scope-tagger should dedupe via H2/file grouping.
<!-- @@SCORE: security-codex.finding-F01.score @@ -->
score: 15
reason: Re-litigates a locked Design decision (CD-1 precedence chain ends with `medium` + loud warning as a migration-window layer-4 fallback); the spec separately fails loud on invalid/missing `model_routing:` via `config-validation-procedure.md` and on a `none` tier, so the framing as silent-fallback-on-invalid-config misreads the precedence chain.
<!-- @@FINDING: security-codex.finding-F02 @@ -->
---
reviewer_tag: security-codex
change_type: correctness
severity: medium
artifact: plan.md
location: "Tasks 14 and 15 — sweep-task contract + cross-task consumers"
referenced_files:
  - plan.md
---

# F02 — Missing injection-safety requirements for user-supplied search commands

## Defect

T14/T15 specify plan-reviewer behavior that reruns author-provided grep/search proof commands from repo root, but test expectations do not require command-shape sanitization/restriction (metacharacters, command chaining, subshells, path escapes).

## Impact

Injection-prone input can execute unintended shell operations during review checks. A malicious or compromised task spec could include `proof_cmd: grep foo; rm -rf $HOME` and the plan-reviewer would execute it.

## Recommended fix

Add a constraint that the proof-command surface MUST be either (a) a closed allowlist of command shapes (e.g., `grep`, `rg`, `cat`, `find` with arg-pattern restrictions) or (b) executed in a no-shell-interpolation mode (argv array, not shell string). Add explicit rejection test fixtures for malicious command forms (`;`, `&&`, `|`, `$()`, backticks, redirect operators, parent-directory `..` traversal).

## Severity rationale

Medium not high because the threat model is "compromised task spec inside the QRSPI run directory" — the attacker already has artifact-write access, so the injection adds limited new capability. Still worth closing.
<!-- @@SCORE: security-codex.finding-F02.score @@ -->
score: 35
reason: Real gap — T14/T15 do specify rerunning author-supplied grep/none commands without restriction or argv-mode execution — but the reviewer itself notes the threat model already requires artifact-write access, no upstream SKILL/CLAUDE.md mandates command-shape sanitization, and the recommended allowlist meaningfully constrains legitimate author flexibility, so this reads as iterative hardening rather than a load-bearing Plan defect.
<!-- @@FINDING: silent-failure-claude.finding-F01 @@ -->
---
finding_id: F01
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/plan.md
artifact: docs/qrspi/2026-05-30-v072-release/plan.md
---

# Task 16 `_resolve-lib.sh` precedence ends in "hardcoded `medium` with loud warning" — log-and-continue instead of halt

## Where

Task 16 (G22 `model_routing` config schema and agent-sweep migration), `**In:**` bullet for `_resolve-lib.sh`, and the matching DoD bullet:

> Create/update `scripts/_resolve-lib.sh` as the shared routing resolver for agent-frontmatter `tier:` parsing, precedence (`--tier-override` / per-dispatch override → agent `tier:` → `default_tier:` → **hardcoded `medium` with loud warning**), tier-to-`(vendor, model)` lookup, …

> `_resolve-lib.sh` resolves tiers in the specified precedence order and halts loudly when the selected tier is configured as `none`; it never silently falls back to a neighboring tier or agent-bundled model.

The "hardcoded `medium` with loud warning" precedence step contradicts the "never silently falls back … to an agent-bundled model" promise immediately below it: emitting a warning and proceeding at `medium` is exactly a silent fallback to a hard-coded model identifier (just with a log line).

## Why this matters

`goals.md ### G22` frames the problem this release is fixing as exactly this class:

> "silently falls through to stale hardcoded model defaults"

The plan removes the old `model_role:` schema and adds loud halt for missing/malformed `model_routing:` (Task 17) and for `none`-tier selection. But the final precedence step in Task 16 reintroduces a defensive hardcoded-`medium` path. A misconfigured deployment where the override is unrecognized, the agent has no `tier:`, and `default_tier:` is absent/malformed will:

1. Emit one warning line to stderr.
2. Resolve `medium` from the hardcoded constant.
3. Dispatch the reviewer/implementer at whatever vendor/model `medium` maps to in the partially-valid `model_routing:` block.

The caller (orchestrator main chat) cannot distinguish "intentional medium" from "fallback medium" without parsing stderr. The dispatched subagent runs at a tier the operator did not authorise, and the round completes "successfully." This is the LOG_AND_CONTINUE pattern: a critical configuration resolution failure produces telemetry instead of a halt.

It also conflicts with Task 18's class-level invariant paragraph (G25), which the plan says must:

> require a loud halt with a named diagnostic for unresolved routing, model, provider, tier, trusted-path, validator-rerun, or fallback target cases

— "fallback target" specifically. A hardcoded-medium-with-warning final step IS a fallback target.

## What the plan should require instead

The precedence chain should end in **halt** when no resolved tier is available:

`--tier-override` → agent `tier:` → `default_tier:` → **halt with named diagnostic** ("no tier resolved; configure `default_tier:` or pass `--tier-override`").

If a defensive "last-resort default" is genuinely desired for development ergonomics, it should be opt-in via an explicit `QRSPI_ALLOW_TIER_FALLBACK=1` envvar that the validation procedure (and CI) treats as a misconfig signal, not as a normal-runtime branch.

Suggested edit to Task 16's `**In:**` bullet and matching DoD bullet: replace "→ hardcoded `medium` with loud warning" with "→ halt with named diagnostic when no tier is resolved (no silent hardcoded fallback)" and add a Test Expectations row: "A dispatch with no override, no agent `tier:`, and no `default_tier:` exits non-zero with a diagnostic naming the unresolved tier and does not dispatch at a hardcoded default."
<!-- @@SCORE: silent-failure-claude.finding-F01.score @@ -->
score: 18
reason: Altitude mismatch — the "hardcoded medium with loud warning" precedence step is an explicit decision in approved design.md ### CD-1 step 1.4 (migration safety net for agents missing `tier:`), and the alleged in-task contradiction doesn't hold (the DoD's halt clause covers `none`-configured tiers, not the migration fallback; a loud warning is not "silent").
<!-- @@FINDING: silent-failure-claude.finding-F02 @@ -->
---
finding_id: F02
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/plan.md
artifact: docs/qrspi/2026-05-30-v072-release/plan.md
---

# Task 12 backward-loop flag deletion failure is "surfaces a diagnostic" — log-and-continue on state-bookkeeping failure

## Where

Task 12 (G4 canonical cumulative diff helper), Definition of done:

> Backward-loop flag handling is consume-once: a present flag forces base-branch preparation for the next round, deletes the flag when possible, and **surfaces a diagnostic if deletion fails**.

And the matching Test expectations row:

> Exercise backward-loop flag handling and verify the next round is forced to base-branch preparation, the flag is consumed once, and **deletion failure is diagnosed**.

Neither bullet states that the round-prepare invocation **exits non-zero** when flag deletion fails. The plan only requires "surfaces a diagnostic" and "deletion failure is diagnosed." This is the log-and-continue pattern: a state-management failure produces a stderr line but the script returns success.

## Why this matters

The backward-loop flag is consume-once state: round N reads the flag, forces base-branch preparation, deletes the flag, so round N+1 returns to normal narrow/broaden convergence. If deletion fails (FS permissions, read-only mount, concurrent run, partial filesystem corruption) but the script proceeds:

1. Round N still produces the correct base-branch diff and exits 0.
2. The orchestrator continues with reviewer dispatch.
3. Round N+1 re-reads the still-present flag, forces base-branch preparation again, and again fails to delete it.
4. Every subsequent round is silently stuck in "forced base-branch" mode until a human notices the diagnostic line in scrollback.

This defeats the convergence-rule's narrowing optimisation indefinitely. More importantly, **deletion failure is almost always a signal of a real filesystem problem** (permissions drift on the artifact directory, read-only remount, full disk, host-tooling sandbox change) — the operator needs to know NOW, not after N rounds of "why is review never narrowing?". A diagnostic line buried in stderr is not loud-failure; an exit-non-zero is.

This is structurally identical to the silent-fallback pattern Task 18 explicitly prohibits at the class level:

> require a loud halt with a named diagnostic for unresolved routing, model, provider, tier, trusted-path, validator-rerun, or fallback target cases

— state-bookkeeping failure during round preparation belongs in the same loud-halt category.

## What the plan should require instead

Specify that `round-prepare.sh` **exits non-zero** with a documented recovery code (e.g., exit 13) when the backward-loop flag deletion fails after the flag has been consumed semantically. The plan already has a clean precedent for this (exit 10 / 11 / 12 with documented recovery paths); add exit 13 for "backward-loop flag consumed but file deletion failed; check artifact-directory permissions and retry."

Suggested DoD edit: "…deletes the flag when possible, and **exits non-zero (exit 13) with a diagnostic naming the artifact-directory permission/IO failure** if deletion fails."

Suggested Test expectations edit: "…the flag is consumed once, and deletion failure produces a non-zero exit with the documented recovery code."
<!-- @@SCORE: silent-failure-claude.finding-F02.score @@ -->
score: 32
reason: Plan faithfully reflects design.md's "read-and-delete (mechanical consequence)" altitude with an added diagnostic; the proposed exit-13 escalation is a defensible improvement but not mandated by design and the failure mode degrades narrowing performance rather than breaking correctness.
<!-- @@FINDING: silent-failure-claude.finding-F03 @@ -->
---
finding_id: F03
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/plan.md
artifact: docs/qrspi/2026-05-30-v072-release/plan.md
---

# Task 02 verifier-fan-in does not validate that expected reviewer tags emitted output — empty round-dir silently produces empty kept-findings + exit 0

## Where

Task 02 (G12 verifier-fan-in script with dispatch-prose include), Scope `**In:**`:

> Create `scripts/verifier-fan-in.sh` to enumerate `<round-dir>/*.finding-F*.md`, validate each finding's `change_type:`, locate the paired `<reviewer-tag>.finding-F<NN>.score.md` sidecar, …

Definition of done:

> A well-formed round exits 0, writes `kept-findings.txt` containing only absolute paths for kept finding files, and writes `.verifier-fan-in-audit.json` with scored, kept, dropped, empty `halts`, and threshold data.

Enumerated halt causes are limited to **per-finding** contract violations:

> Missing `change_type`, out-of-enum `change_type`, missing sidecar, wrong sidecar extension, and unparseable score each exit non-zero and record the matching halt cause in `.verifier-fan-in-audit.json`.

The script glob `<round-dir>/*.finding-F*.md` returns the empty set when no finding files exist, and the plan does not list "no finding files for an expected reviewer tag" as a halt cause. An empty round directory (because every reviewer subagent silently failed to emit *anything* — no finding file, no `<reviewer-tag>.clean.md` sentinel either) produces:

- `kept-findings.txt`: empty file
- `.verifier-fan-in-audit.json`: `scored: 0, kept: 0, dropped: 0, halts: []`
- exit code: 0

…which is byte-identical to a legitimate "every reviewer ran and found nothing" round.

## Why this matters

Task 03 (G6) establishes the reviewer disk-write contract:

> The first-party contract requires `<round_subdir>/<reviewer_tag>.finding-F<NN>.md` per finding or `<round_subdir>/<reviewer_tag>.clean.md` for zero findings, and states that any other channel produces zero findings for that tag with the expected loud failure surface.

Task 03 also pins the failure surface in unit tests:

> wrong-channel output reporting `expected tag produced no output` rather than silently passing.

But that test is the *unit test for the protocol contract*. At runtime, **no script in the v0.7.2 pipeline is specified to check** "every dispatched reviewer tag produced at least one finding file OR a clean sentinel." The plan dispatches reviewers via `dispatch-agent.sh` (Task 20), drains background entries via `await-round.sh` (Task 12 / Task 20), then runs `verifier-fan-in.sh` (Task 02) — none of these scripts cross-references the dispatch manifest's expected reviewer tags against the actual files on disk.

This means: under the post-T20 task-tool transport, if a reviewer subagent returns chat-only text (the v0.7.1 G6 failure mode this release is fixing) AND chat text contains no `<<<FINDING-BOUNDARY>>>` markers AND the third-party splitter therefore produces no files AND the reviewer was supposed to be a "no findings → clean.md" reviewer, the fan-in sees zero files and concludes the round is clean. The orchestrator advances to apply-fix with `kept-findings.txt` empty and ships unreviewed code.

This is the SILENT_FALLBACK class: callers cannot distinguish "empty because every reviewer found nothing and emitted clean sentinels" from "empty because every reviewer's output was lost." Goals G6 frames exactly this:

> chat-only reviewer output under task-tool transport

…as the regression to fix. The fan-in script is the most natural runtime enforcement point for "every expected tag produced *something* on disk."

## What the plan should require instead

Add to Task 02 (or to Task 12's `await-round.sh`, whichever owns the final gate before fan-in proceeds):

1. The fan-in script (or `await-round.sh`) reads the dispatch manifest's expected reviewer-tag list for the round and **asserts that each expected tag produced either ≥1 `<tag>.finding-F*.md` file OR exactly one `<tag>.clean.md` sentinel**.

2. A tag with neither produces a non-zero exit and a `.verifier-fan-in-audit.json` halt entry with `cause: reviewer_tag_produced_no_output` (or equivalent), naming the offending tag.

3. Test expectations add a fixture round where the dispatch manifest lists tag `claude-quality` but the round directory contains no `claude-quality.*` files at all; the fixture must exit non-zero with the named halt cause.

This closes the round-level silent-failure surface that Task 03's protocol contract documents but no runtime script currently enforces.
<!-- @@SCORE: silent-failure-claude.finding-F03.score @@ -->
score: 68
reason: Real plan gap — empty round-dir is byte-identical to all-clean per Task 02 DoD/halts list, and neither await-round.sh (drains only background entries) nor any other named script cross-checks expected reviewer tags vs disk output, directly leaving open the G6 chat-only-return failure surface this release exists to close.
<!-- @@FINDING: silent-failure-claude.finding-F04 @@ -->
---
finding_id: F04
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/plan.md
artifact: docs/qrspi/2026-05-30-v072-release/plan.md
---

# Task 32 incremental in-place rewrites of `design.md` / `goals.md` lack atomicity spec — partial-state risk on mid-write interruption

## Where

Task 32 (G30 Goals and Design dialogue authoring quality and compaction-resilient incremental persistence), Scope `**In:**`:

> Update `skills/design/SKILL.md` so each per-decision lock writes directly to `design.md` with `status: draft`, using the Task 30 five-field per-goal template and a dedicated `## Cross-Goal Decisions` section for cross-goal locks.

> Update `skills/goals/SKILL.md` so each locked goal writes directly to `goals.md` with `status: draft`, while preserving the existing per-goal template, Interactive Dialogue question-topic checklist, and Pipeline Mode Selection step.

> Document presence-as-locked semantics in both skills: tentative, placeholder, `to be filled`, TODO, or similar incomplete decision bodies never enter draft artifacts; **re-locking an existing decision overwrites that keyed block in place** instead of appending a duplicate.

Definition of done and Test expectations both pin the *content* of incremental writes ("presence-as-locked," "keyed in-place overwrite," "Resumed after compaction…" diagnostic), but **neither requires the write to be atomic** (write-to-temp + rename) or specifies what happens when the write is interrupted mid-rewrite.

The only durability assertion is:

> Simulated-compaction coverage uses a mid-phase decision such as G15 and verifies resume produces the same final artifact content as a no-compaction run.

…where "compaction" means the LLM-context-window compaction the skill is designed to survive — i.e., the assistant process restarts cleanly between turns, with `design.md` on disk in a complete state. This test does not cover the case where the assistant is interrupted (host kill, network drop on a hosted CLI, terminal SIGINT, OS-level OOM) *during* the in-place rewrite of `design.md`.

## Why this matters

This is the PARTIAL_STATE_ON_FAILURE pattern: a multi-step write operation (read existing artifact → splice in updated keyed block → write back the whole file) with no atomicity spec. If the assistant is interrupted between the truncate-and-open-for-write and the final flush:

- `design.md` on disk is partially rewritten — possibly missing the trailing locked decisions, possibly containing a partial keyed block.
- Resume-after-compaction reads the partial artifact and enumerates "locked decisions" from a corrupt snapshot.
- The "M decisions locked, K remaining" diagnostic prints wrong counts.
- The skill silently continues from `G(NN+1)` based on the corrupt snapshot, potentially overwriting valid locked decisions or skipping ones that were already locked.

Worse: the user's verification surface for this is "does the final `design.md` look right?" — which is exactly what a partial write makes hard to spot, because the file *looks* well-formed up to the truncation point.

The contrast with Task 11 (G29) is instructive — Task 11 explicitly requires:

> Make manifest writes atomic and append-safe for repeated invocations and multiple reviewer tags in the same round.

…for the dispatch manifest. The dispatch manifest is *machine-readable bookkeeping*; `design.md` and `goals.md` are *the load-bearing draft artifacts of the whole pipeline.* If anything in the v0.7.2 release deserves atomic-write semantics, the incremental-persistence target files do.

## What the plan should require instead

Add to Task 32's Scope `**In:**` and Definition of done:

- "Each incremental write to `design.md` / `goals.md` is atomic on the operator's filesystem: the skill writes the updated artifact body to a sibling tempfile in the same directory, fsyncs (when the host shell supports it), then `mv`s the tempfile over the target. A failed/interrupted write leaves the prior on-disk artifact intact."
- "Resume-after-compaction begins by validating that the on-disk `design.md` / `goals.md` parses cleanly under the Task-30 / existing per-goal template; if validation fails, the skill emits a loud diagnostic and refuses to enumerate locked decisions from a corrupted snapshot rather than silently continuing from a partial read."

Add to Test expectations:

- "Simulate a mid-write interruption (kill the rewrite step before completion); verify the on-disk artifact is byte-identical to the pre-rewrite state and the resume diagnostic correctly reports the pre-rewrite locked-decision count."
- "Simulate a corrupted on-disk `design.md` (truncated mid-block, malformed frontmatter); verify resume exits with a loud diagnostic rather than silently re-locking decisions."
<!-- @@SCORE: silent-failure-claude.finding-F04.score @@ -->
score: 28
reason: The atomic-write concern is theoretically real but largely an implementation/Design-altitude concern that the LLM-driven SKILL workflow doesn't trigger in practice — Claude's Write tool is invoked once per rewrite and either completes (full new contents on disk) or fails (no partial write the next compaction-resume turn would observe), making the host-kill/SIGINT mid-write scenario much narrower than for a long-running shell script; Plan already specifies presence-as-locked semantics, keyed in-place overwrite, and the compaction-resume diagnostic, and the design.md ## G30 source doesn't lock atomic-write semantics for Plan to refine, so this reads as Plan-reviewer altitude bleed asking for an Implementation-level durability spec that Design didn't decide.
<!-- @@FINDING: silent-failure-codex.finding-F01 @@ -->
---
reviewer_tag: silent-failure-codex
change_type: correctness
severity: medium
artifact: plan.md
location: "Task 16 — G22 model_routing resolver"
referenced_files:
  - plan.md
---

# F01 — Hardcoded model fallback on config defect

## Defect

T16 `_resolve-lib.sh` precedence explicitly allows falling back to a hardcoded `medium` tier with only a warning when config/default tier is missing. The "warning" is log-and-continue.

## Impact

This is the log-and-continue fallback pattern for misconfiguration. Routing proceeds with possibly wrong model selection instead of failing loudly. Contradicts T18's class-level "no fallback target" invariant.

## Recommended fix

Halt on incomplete/missing tier config; exit non-zero with a diagnostic naming the missing tier. Remove the hardcoded `medium` fallback.

## Duplicate-of note

Same finding as silent-failure-claude.F01 and security-codex.F01. Scope-tagger dedupe expected.
<!-- @@SCORE: silent-failure-codex.finding-F01.score @@ -->
score: 38
reason: Real internal tension between T16's hardcoded-medium fallback and T18's class-level fail-loud invariant, but the fallback is explicitly captured in design.md CD-1 step 1 ("Hard-coded fallback `medium` with loud warning"), so Plan is faithfully transcribing a Design decision; the "log-and-continue" framing is also softened by the explicit loud warning, putting this partially in altitude-mismatch territory.
<!-- @@FINDING: silent-failure-codex.finding-F02 @@ -->
---
reviewer_tag: silent-failure-codex
change_type: correctness
severity: medium
artifact: plan.md
location: "Task 19 — G27 second-reviewer probe"
referenced_files:
  - plan.md
---

# F02 — Probe-failure path still defaults to `second_reviewer: false`

## Defect

T19 spec says Goals/using-qrspi migration sets `second_reviewer: false` on probe failure.

## Impact

This recreates the original silent opt-out class: second-reviewer capability failure can be converted into config defaulting rather than a caller-visible hard failure or explicit operator decision. The whole point of G27 is to surface this state to the operator.

## Recommended fix

On probe failure, halt and prompt the user with the two explicit options ("skip second reviewer" vs "abort"); do not silently default. The default `false` on failure IS the silent failure pattern this goal exists to eliminate.

## Counter-argument to consider

If the run is fully autonomous (no human in the loop), `false` may be the safest default. The fix may need to distinguish interactive vs autonomous modes rather than blanket-halt.
<!-- @@SCORE: silent-failure-codex.finding-F02.score @@ -->
score: 18
reason: Misreads G27's silent-failure class — probe-time `false` when no second reviewer exists for the host is the correct config-detection outcome (explicitly locked in design.md G27 D2/D3); the runtime-halt fail-loud requirement is satisfied by D4's `[second-reviewer-unavailable]` halt in `dispatch-agent.sh` (mirrored in plan T19 DoD), and the finding's recommendation contradicts an approved design decision.
<!-- @@FINDING: silent-failure-codex.finding-F03 @@ -->
---
reviewer_tag: silent-failure-codex
change_type: correctness
severity: medium
artifact: plan.md
location: "Task 09 — G20 verifier actual_model field"
referenced_files:
  - plan.md
---

# F03 — Missing `actual_model` silently normalized to `unknown`

## Defect

T09 verifier is specified to accept missing `actual_model` and write `actual_model: unknown` instead of failing.

## Impact

Silent fallback on missing audit input: schema drift/omission is masked as a normal value, reducing detectability of upstream contract breaks. If a future runtime change drops the `actual_model` field, the verifier would silently produce `unknown` records and the regression wouldn't surface.

## Recommended fix

Fail loud on missing `actual_model`: exit non-zero with diagnostic `actual_model field missing — upstream dispatch transport did not record model identity`. Reserve `unknown` for legitimate runtime states where the model genuinely cannot be identified (e.g., raw HTTP transport without model echo).

## Counter-argument to consider

If `unknown` is the legitimate value for transports that don't echo model identity, then accepting missing-field-as-unknown is correct. The fix may need to distinguish "field absent" (hard fail) from "field present with value `unknown`" (accept).
<!-- @@SCORE: silent-failure-codex.finding-F03.score @@ -->
score: 12
reason: Plan faithfully encodes the explicit locked design.md G20 decision (line 1871) that `actual_model: unknown` fallback is intentional observability behavior, not a correctness gate — finding relitigates an upstream Design lock at Plan altitude.
<!-- @@FINDING: spec-codex.finding-F01 @@ -->
---
reviewer_tag: spec-codex
change_type: correctness
severity: high
artifact: plan.md
location: "Tasks 19 and 20 — G27 second-reviewer migration"
referenced_files:
  - plan.md
  - goals.md
---

# F01 — Plan breaks stated backward-compat + canonical-helper constraints

## Defect

Per goals.md constraints (lines 14–16) and G27 framing (lines 788–793): "do not change established contract"; `run-codex-review.sh` `detect_host()` + `check_codex_available()` are named as canonical helpers Goals should call.

Plan conflicts:

- **Task 20** hard-renames `run-codex-review.sh` away with explicit "no compatibility shim" (plan.md lines 1225–1251, 1260).
- **Task 19** introduces new host-detection primitives (`_host-detect.sh`, `second-reviewer-available.sh`) instead of consuming the stated canonical helpers (lines 1176–1181).

## Impact

Violates explicit goals constraints. Existing call sites (in user repos that already invoke `run-codex-review.sh` directly) will break. Parallel canonical-helper lineages diverge over time.

## Recommended fix

Either (a) keep `run-codex-review.sh` as a backward-compatible entrypoint that sources the new shared code (canonical shim), or (b) make the rename explicit in goals.md by relaxing the constraint AND document an explicit deprecation path with a migration guide. Plan as-written violates the goals contract.

## Counter-argument to consider

The constraint may have been relaxed during the Goals walk-through cycle — verify against the final approved goals.md. If the constraint genuinely IS still in force, this finding is high-severity; if relaxed but the goals text wasn't updated, this is a goals-doc bug, not a plan defect.
<!-- @@SCORE: spec-codex.finding-F01.score @@ -->
score: 20
reason: Altitude mismatch — the hard-rename and "no shim" decision is locked in approved design.md CD-1 (rename inventory, hard cutover) and the new canonical-helper relocation to `_host-detect.sh`/`_resolve-lib.sh` is the design-level resolution of the goals constraint's "single source of truth" spirit; goals' backward-compat clause names artifact directories + per-host dispatch conventions, not script filenames, and Plan is faithfully executing the approved design.
<!-- @@FINDING: spec-codex.finding-F02 @@ -->
---
reviewer_tag: spec-codex
change_type: correctness
severity: high
artifact: plan.md
location: "Task 37 — Target files vs Scope-Out vs DoD"
referenced_files:
  - plan.md
---

# F02 — Task 37 self-contradiction (Target adds lint test; Scope/DoD ban it)

## Defect

T37 Target files (line 2266) lists creating `tests/lint/test-structure-altitude-boundary-include.bats`.

Conflicts:
- Scope Out (line 2285): "Test-code or lint-test additions for the include guard — explicitly out of this prompt-prose task."
- DoD (line 2297): "The task does not edit reviewer agents, add test code, ..."

## Impact

Task is not implementable as written. Acceptance audit fails the task either way.

## Recommended fix

Pick one: either keep the lint test in-scope (and update Out/DoD/Test-expectations to allow it; add an In bullet specifying contents), or remove the file from Target files and defer to a follow-up task.

## Duplicate-of note

This is the same defect quality-claude.F01 reported. Verifier should dedupe via scope-tagger H2 grouping.
<!-- @@SCORE: spec-codex.finding-F02.score @@ -->
score: 90
reason: Verified self-contradiction — Target files (L2266) lists creating the lint-test file while Scope Out (L2285) and DoD (L2296) explicitly forbid test-code/lint-test additions, making the task unimplementable as written.
<!-- @@FINDING: spec-codex.finding-F03 @@ -->
---
reviewer_tag: spec-codex
change_type: correctness
severity: low
artifact: plan.md
location: "Task 16 — sizing_exception value"
referenced_files:
  - plan.md
---

# F03 — Sizing-exception token mismatch (`schema-migration` vs `schema migration`)

## Defect

T16 (and possibly other tasks) uses `sizing_exception: schema-migration` (hyphenated). The checklist allowed-set may be `schema migration` (space-separated).

## Impact

If the validator enforces an exact closed-set match, the validation fails. If the validator is lenient, the values drift across the plan.

## Recommended fix

Verify the canonical form in the plan-reviewer enforcement spec (T15 or T18) and normalize all sites to match. Round-01 already normalized 4 sites to `schema-migration` (hyphenated) per the round-01 dispositions; if THAT is the canonical form, this finding is a false positive.

## Counter-argument to consider

Round-01's normalization landed on `schema-migration` (hyphenated) as canonical. Codex may be referencing an outdated plan-reviewer spec. Likely a verifier-droppable finding.
<!-- @@SCORE: spec-codex.finding-F03.score @@ -->
score: 35
reason: Real inconsistency exists — plan SKILL.md template (lines 169, 221) lists canonical enum as space-separated `schema migration`, while plan.md uses hyphenated `schema-migration`; however round-01 dispositions explicitly chose hyphenated as canonical (a user-recorded decision the finding itself flags as likely droppable), severity is correctly low, and the finding lacks evidence of any actual programmatic validator enforcing the enum.
<!-- @@FINDING: test-coverage-claude.finding-F01 @@ -->
---
reviewer: test-coverage-claude
round: 2
artifact: plan.md
task: T27
severity: high
change_type: correctness
---

# F01 — T27 reviewer-protocol antagonist-pattern enforcement clause: test expectations cannot be deterministically verified

## What

T27's round-01 extension added two new Scope-In and DoD requirements covering
`skills/reviewer-protocol/SKILL.md`:

1. The reviewer-protocol clause "requires reviewer subagents to surface a
   finding when an artifact carries any CD-2 named antagonist pattern."
2. "The clause is inserted alongside (NOT replacing) existing
   finding-schema/`change_type` requirements and uses the canonical
   `change_type: style` or `change_type: clarity` enum value per the locked
   snippet's filter taxonomy."

The matching test expectation reads:

> Grep audit of `skills/reviewer-protocol/SKILL.md` confirms the antagonist-
> pattern enforcement clause is present and references the CD-2 named patterns
> vocabulary from the locked `skills/_shared/evergreen-output-rule.md` snippet
> (no duplicated antagonist-pattern list — the reviewer clause cites the
> snippet rather than copying it).

This is unverifiable as written:

- **"Clause is present"** — no literal anchor phrase, heading, or sentence the
  grep must find. Test cannot fail deterministically.
- **"References the CD-2 named patterns vocabulary"** — the locked CD-2
  snippet body is not yet authored at plan-write time, so the test author has
  no concrete anchor strings to assert on. What greppable token proves
  "references"? A path string? A specific antagonist-pattern name?
- **"No duplicated antagonist-pattern list"** — no rule for what counts as
  duplication. If the clause names 2 of the 6 antagonist patterns by name,
  does it duplicate? What is the threshold?
- **`change_type: style` / `change_type: clarity` requirement is in DoD/Scope
  but completely absent from test expectations.** A correct implementation
  that uses `change_type: correctness` (wrong taxonomy) would pass the tests.
- **"Alongside (NOT replacing) existing finding-schema/`change_type`
  requirements"** is in DoD but no test expectation verifies the pre-existing
  finding-schema sections remain present after the edit. A regression that
  deletes the original requirements while adding the new clause would pass.

## Why this matters

The test author for T27 cannot generate a deterministic acceptance check from
these expectations. The most likely outcome is one of:

1. The test author invents anchor strings, which then don't match the actual
   implementer-written prose, producing brittle pass/fail noise.
2. The test author writes a vacuous existence assertion that any non-empty
   edit to `reviewer-protocol/SKILL.md` would satisfy.
3. The implementer ships a clause that violates the `change_type` taxonomy
   constraint or quietly deletes existing finding-schema text, and tests
   accept it.

## Recommended fix

Add concrete, greppable anchors to the test expectations:

- Name a literal heading or anchor phrase the reviewer-protocol clause must
  introduce (e.g., `### Evergreen-Output Rule Enforcement` or a specific
  sentence like "surface a finding for any CD-2 named antagonist pattern").
- Add a test expectation that asserts the clause text contains `change_type:
  style` or `change_type: clarity` (and contains neither `change_type:
  correctness` nor `change_type: scope` in that paragraph).
- Add a "no removal" assertion: name the literal heading(s) of the existing
  finding-schema / `change_type` sections that must still be present after
  the edit (regression guard for the "alongside (NOT replacing)" DoD bullet).
- Specify how "references the snippet" is greppable — e.g., the clause must
  contain the literal path string `skills/_shared/evergreen-output-rule.md`
  exactly once.
- Specify the "no duplicated antagonist-pattern list" check by literal
  pattern: e.g., the clause body MUST NOT contain more than N of the
  antagonist-pattern category names (`session/drafting notes`,
  `version-history narration`, `inside baseball`, etc.) that appear in the
  locked snippet.
<!-- @@SCORE: test-coverage-claude.finding-F01.score @@ -->
score: 65
reason: Real test-coverage gap — T27 DoD requires `change_type: style|clarity` enum and "alongside (NOT replacing)" semantics, but the single line-1716 test expectation verifies neither (no enum-value assertion, no no-removal regression guard); the vague "references CD-2 vocabulary" phrasing also lacks a greppable anchor, though plan-level test expectations have some latitude.
<!-- @@FINDING: test-coverage-claude.finding-F02 @@ -->
---
reviewer: test-coverage-claude
round: 2
artifact: plan.md
task: T27
severity: medium
change_type: clarity
---

# F02 — T27 using-qrspi pointer site: "artifact-quality section" anchor is unspecified

## What

T27's round-01 extension added a new DoD bullet:

> `skills/using-qrspi/SKILL.md` carries exactly one by-reference pointer line
> to `skills/_shared/evergreen-output-rule.md` at the artifact-quality
> section, with no `!cat` include of the snippet body (per CD-2 acceptance #5).

And matching test expectation:

> Grep audit of `skills/using-qrspi/SKILL.md` confirms exactly one pointer
> line to `skills/_shared/evergreen-output-rule.md` at the artifact-quality
> section and zero occurrences of `!cat skills/_shared/evergreen-output-rule.md`
> (pointer-only contract per CD-2 acceptance #5).

The "exactly one pointer line" count and "zero `!cat`" occurrence count are
both deterministic and good.

But **"at the artifact-quality section"** has no literal heading text or
greppable anchor. `skills/using-qrspi/SKILL.md` is a large file with many
sections; there is no current heading literally named "artifact-quality" (the
phrase only appears in plan/design narrative). The test cannot deterministically
verify that the pointer landed at the intended location vs. somewhere else.

## Why this matters

An implementer could place the pointer line at the top of the file, in the
dispatch-routing section, or in the schema-validation table — all of which
satisfy "exactly one pointer line" and "zero `!cat`" but none of which match
CD-2's intent that operators discover the rule near artifact-quality guidance.

Tests would pass even though the discoverability goal (the whole reason
for the pointer per CD-2 acceptance #5) is missed.

## Recommended fix

Either:

1. Name the literal H2 / H3 heading text the pointer must appear under
   (e.g., "Artifact-quality guidance" or whatever the locked CD-2 / structure
   heading actually is — design.md ### CD-2 and structure.md ###
   `skills/using-qrspi/SKILL.md` should carry an authoritative phrase), and
   make the test expectation say "pointer line appears within N lines after
   the literal heading `## <Heading>`".
2. Or, name a stable anchor sentence the pointer text must contain or be
   adjacent to (e.g., the pointer must include the phrase "artifact-output
   quality contract" so a positional grep can confirm it).

Whichever wording the design/structure documents already lock as canonical
should be carried into both the DoD anchor and the test expectation
verbatim — that is the standard greppable-anchor pattern used by other T27
expectations (e.g., the "named antagonist patterns" anchor phrase for the
snippet body itself).
<!-- @@SCORE: test-coverage-claude.finding-F02.score @@ -->
score: 38
reason: Real test-determinism gap on placement (grep audit only enforces cardinality, not location) but the "artifact-quality section" wording is inherited verbatim from upstream design.md CD-2 #5 and structure.md's per-file block — Plan did not introduce the looseness, and the proposed fix would have Plan lock heading text upstream artifacts deliberately left to the implementer.
<!-- @@FINDING: test-coverage-claude.finding-F03 @@ -->
---
reviewer: test-coverage-claude
round: 2
artifact: plan.md
task: T29
severity: medium
change_type: correctness
---

# F03 — T29 references a lint-test target file that has no creation responsibility, DoD, or test expectations

## What

T29's `**Target files:**` line includes:

> create `tests/lint/test-design-altitude-boundary-include.bats`

But T29's body — Scope-In, Definition of done, and Test expectations sections
— never mentions this file again. There are no DoD bullets describing what the
lint test must assert, and no Test-expectations bullets describing what
acceptance checks to run against it. The same omission appears at T37 (Target
files lists `tests/lint/test-structure-altitude-boundary-include.bats` for
creation but Scope-In / DoD / Test-expectations are silent on it).

Out-of-scope bullet at T29 says:

> Test-code or lint-test additions for the include guard — explicitly out of
> this prompt-prose task.

This directly contradicts the Target-files row that says the lint test file
must be created.

## Why this matters

For T29: the test-writer phase cannot generate acceptance checks for the lint
file because there is no requirement to test. The implementer either:

1. Creates an empty/stub `.bats` file (satisfies Target files; satisfies the
   Out-of-scope "no lint-test additions" by being empty; fails to provide any
   actual lint coverage).
2. Authors a non-trivial lint test (violates the Out-of-scope ban), with no
   acceptance criteria for what assertions it must contain.
3. Does not create the file at all (fails the Target-files requirement).

All three outcomes are defensible against this plan, and none are testable.

For T37: same shape. The `tests/lint/test-structure-altitude-boundary-include.bats`
file is in Target files with no DoD or test-expectation coverage.

## Recommended fix

Pick one resolution per task:

- **If lint coverage is required**: remove the contradictory Out-of-scope ban
  in T29; add DoD bullets describing what the lint must assert (e.g., "lint
  fails when either consumer file lacks the literal `!cat
  skills/_shared/design-altitude-boundary.md` directive"); add matching
  test expectations.
- **If lint coverage is out of scope for v0.7.2**: remove the lint file from
  Target files in T29 and T37; let a future task own it.

The Target-files row, Out-of-scope ban, and silence in DoD/Test expectations
cannot coexist; one of them is wrong.
<!-- @@SCORE: test-coverage-claude.finding-F03.score @@ -->
score: 65
reason: T37 has a direct, verified contradiction (Target files creates the lint .bats while Out-of-scope explicitly bans lint-test additions; DoD/Test expectations silent); T29 has an analogous gap (Target files lists 4 files but Out-of-scope and silence cover only 3, and the lint file has no DoD/test-expectations coverage), though the finding misattributed T37's "Test-code or lint-test additions" Out-of-scope quote to T29.
<!-- @@FINDING: test-coverage-codex.finding-F01 @@ -->
---
reviewer_tag: test-coverage-codex
change_type: correctness
severity: medium
artifact: plan.md
location: "Multiple tasks (T22, T26, T27, T28, T30, T31, T33, T36, T37, T38)"
referenced_files:
  - plan.md
---

# F01 — Non-deterministic "R1-R7 / content-semantic review" expectations

## Defect

Several tasks use test expectations like "apply R1-R7 + cross-cutting principles" / "content-semantic review" without concrete pass/fail signals.

## Impact

These are not reliably falsifiable for acceptance-test generation. Two reviewers could disagree while both claim R1-R7 was satisfied. Same defect class as the round-01 fixes addressed in other tasks.

## Recommended fix

For each "R1-R7 / content-semantic" test expectation, replace with specific observable assertions: required strings present, forbidden strings absent, structural assertions (heading present, section ordering), and the specific R-rule each assertion maps to.

## Counter-argument to consider

The R1-R7 framework IS the testable contract — if R1-R7 are precisely-defined elsewhere (a reviewer spec doc), then "apply R1-R7" is a deterministic shorthand. The fix is to either pin the R-rule definitions or expand them inline; both options have trade-offs (DRY vs locality).
<!-- @@SCORE: test-coverage-codex.finding-F01.score @@ -->
score: 30
reason: Pattern exists as alleged (T22/T26/T27/T28/T30 etc. each carry an "Apply R1-R7 + cross-cutting principles" line), but R1-R7 are externalized in `skills/_shared/prompt-design-rules.md` and the R1-R7 check is always layered on top of concrete grep/diff audits — so the test expectations are not actually non-deterministic in isolation, and the finding's own counter-argument largely concedes this.
<!-- @@FINDING: test-coverage-codex.finding-F02 @@ -->
---
reviewer_tag: test-coverage-codex
change_type: correctness
severity: medium
artifact: plan.md
location: "Tasks 29 and 37 — Target files vs Test expectations"
referenced_files:
  - plan.md
---

# F02 — Declared deliverables not verified in test expectations

## Defect

- **T29** target files include `tests/lint/test-design-altitude-boundary-include.bats`, but test expectations do not verify that file exists or what it asserts.
- **T37** target files include `skills/structure/owns-defers.md` and `tests/lint/test-structure-altitude-boundary-include.bats`, but test expectations largely verify only the shared boundary file + `skills/structure/SKILL.md`.

## Impact

Parts of each task's intended output go untested. Completion is unverifiable for those declared artifacts.

## Recommended fix

Add explicit test-expectation bullets that pin the existence and required content of each Target file. This is the same defect class quality-claude.F01/F02 flagged from a different angle — they pointed at the contradiction between Target and Out/DoD; this finding points at the contradiction between Target and Test expectations.

## Duplicate-of note

Overlaps with quality-claude.F01 (T37), quality-claude.F02 (T29), and test-coverage-claude.F03. Scope-tagger H2 grouping should collapse.
<!-- @@SCORE: test-coverage-codex.finding-F02.score @@ -->
score: 70
reason: Verified in plan.md — T29 test expectations omit the lint bats file in its Target files, and T37 test expectations explicitly contradict its own Target files ("only modified existing target file" and "no test-code additions" vs Target listing owns-defers.md modify + lint bats create); convergent with quality-claude F01/F02 and test-coverage-claude F03.
<!-- @@CLEAN: goal-traceability-claude.clean @@ -->
---
artifact: plan.md
round: 2
reviewer: goal-traceability-claude
actual_model: claude-sonnet-4.5
---

# Goal-Traceability Review — Clean Sentinel (Round 2)

No findings. Forward and backward goal-traceability continue to hold; the round-01 dispositions made only surgical refinements that do not perturb the traceability matrix verified clean in round 01.

## Round-01 dispositions impact on traceability

Round 01 was clean for goal-traceability-claude (`reviews/plan/round-01/goal-traceability-claude.clean.md`). The seven auto-applied correctness fixes documented in `round-01-dispositions.md` were inspected for goal-coverage impact:

| Disposition | Surface | Trace impact |
|-------------|---------|--------------|
| T05 `verifier-fan-in.sh (create)` → `(modify)` | File-ownership clarification (T02 owns create) | None — G13 still covered by T05, G12 still covered by T02. |
| T25 Blocks line corrected to name T26 + T39 | Cross-reference text | None — G31 still covered by T25 + T26; G32's defensive-copy site dependency reflected. |
| T29 add `tests/lint/test-design-altitude-boundary-include.bats` | Test-file ownership | Strengthens G34 coverage; does not move ownership off G34. |
| T37 add `skills/structure/owns-defers.md` + `tests/lint/test-structure-altitude-boundary-include.bats` | File ownership | Strengthens G35 coverage; G35 still owned by T37 + T38. |
| T16/T33 `sizing_exception` enum normalized to `schema-migration` | Lexical normalization | No semantic change. |
| T39 symlink canonicalization added to DoD + Test expectations | Adds an in-scope clause under G32 | Strengthens G32 / G16-companion exfil-surface coverage; does not introduce new goal scope. |
| T20 deps expanded to `[Task 09, Task 11, Task 12, Task 13, Task 19]` + new Dependency Graph cluster #4 | Sequencing | Pure ordering; G3 still owned by T20. |
| T27 expanded with `skills/reviewer-protocol/SKILL.md` + `skills/using-qrspi/SKILL.md` Target files + matching DoD/Test bullets | CD-2 consumer-site coverage | Strengthens CD-2 → G3/G4/G22/G27 trace; no new goal introduced. |

None of these edits reassign goal ownership, drop a goal from coverage, introduce a task without an upstream goal/research-finding justification, or alter the design-to-plan fidelity verified in round 01.

## Coverage summary (unchanged from round 01)

### Forward trace (goals.md → tasks → plan-authored criteria)

All 35 goals (G1–G35) remain covered by at least one task. The Task List by Slice block (plan.md L31–101) preserves the same per-task goal-ID mapping recorded in the round-01 matrix. The per-phase `### Phase 1 Acceptance Criteria` block (plan.md L17–29) carries the same seven cross-task observable behaviors; the strengthening edits to T05/T20/T27/T29/T37/T39 are absorbed within already-existing phase criteria (per-task sidecars on disk; fail-loud invariants; build pipeline reproducibility; full bats suite green).

### Backward trace (tasks → goals/research)

All 44 task headers in the Task List by Slice block still carry exactly the same `goals: [G<N>]` (or `[CD-<N> → ...]`) attribution verified clean in round 01. The three cross-cutting tasks (T24=CD-4, T27=CD-2, T28=CD-3) continue to carry their secondary goal IDs (T24=[G6, G11, G12]; T27=[G3, G4, G22, G27]; T28=[G1, G30, G33]) — the round-01 T27 expansion stays inside the CD-2 → upstream-goals trace, not outside it.

### Spec-to-design fidelity (full pipeline)

Plan's seven vertical slices (1.1–1.7) and the single cross-slice forward dep (Slice 1.4 G4 → Slice 1.3 G9) remain consistent with design.md, structure.md, and phasing.md. The new Dependency Graph cluster #4 (T09 + T11 + T13 → T20) introduced by the round-01 spec-claude.F01 disposition adds finer-grained sequencing information without changing slice partitioning or task scope.

### Decomposition check

G24's F-bundle (F01–F05) and G31's primitives/consumer split (T25→T26) decompose unchanged from the round-01 verification. T37's added `owns-defers.md` work and T29's added test file both fall within the design.md framing for G35 / G34 respectively (the `*-altitude-boundary` primitive pattern is the design's stated approach for both goals).

## Conclusion

Plan.md remains clean for goal-traceability in round 2. The round-01 dispositions strengthened coverage where they edited at all and did not introduce traceability defects. No new findings to file.
<!-- @@CLEAN: scope-claude.clean @@ -->
---
reviewer_tag: scope-claude
round: 2
artifact: plan.md
verdict: clean
---

# scope-claude — round 02 — clean

Scope/boundary review of `docs/qrspi/2026-05-30-v072-release/plan.md` against `skills/plan/owns-defers.md`. The diff under review is the full new-file plan.md (2742 lines, 44 tasks across 7 slices). No companion artifacts loaded (per scope-reviewer protocol).

## 3-check results

**1. Boundary-drift detection (Plan DEFERS).** No violations.

- **Function signatures / type definitions / parameter shapes → structure.md.** No parenthesized parameter lists or return-type arrows found. Where Plan names observable output fields (e.g., `dispatch_spec.subagent_type`/`host`/`vendor`/`model`/`prompt_file` in T11 DoD, `actual_model:` in T09, `defect_class:` in T10, `KEY=VALUE` shape in T24, exit codes 10/11/12 in T12) the bullets cite `structure.md ### 10. Dispatch manifest schema` / `structure.md ### scripts/...` as the authoritative per-file schema source. Plan is naming testable observable surfaces, not authoring shapes — defensibly inside the "conversation, not contract" framing.
- **Full assertion text / `expect(...)` / test code → Implement-TDD.** No `expect(`, `assert.`, `assertEqual`, or `toBe(` patterns in Test Expectations. Every task's Test Expectations uses plain language verbs (grep, inspect, exercise, run, audit, confirm). Literal anchor phrases pinned for assertion (e.g., T31's `"Use simple language and provide context when presenting ideas"`, T32's `"Resumed after compaction — last locked decision: ..."` diagnostic, T21's `resolves outside repository`) are behavior-pin specifications, not assertion code.
- **Line-by-line logic / control-flow / pseudocode → Implement.** No `if/else`, `for`, `while`, switch, or numbered-step algorithmic walkthroughs in task bodies. Where ordering or branching is named (e.g., T12 convergence "broadens on missing/empty/full-artifact/superset/overlap/disjoint; narrows only for equal or proper-subset"), the wording describes decision-table outputs / observable behaviors rather than control flow.
- **Architecture decisions / trade-offs / system diagrams → design.md.** No "trade-off", "we considered", or "alternative approach" prose authoring. Rationale framings consistently cite `design.md ## GNN` / `design.md ### CD-N` as the upstream source. Where Plan acknowledges non-goals (e.g., T11 "G29 is moot / absorbed by CD-1, with no threshold rule"), it consumes a locked Design disposition rather than re-deciding.
- **Phasing / vertical slice authoring / roadmap / replan-gate criteria → phasing.md.** Borderline area surveyed:
  - The Phase 1 boundary ("Phase 1 is the whole release: all 35 goals, all seven slices") is consumed from phasing.md, not re-authored.
  - Slice headings (1.1–1.7) organize tasks under the already-decided phasing slices; no new slice rationale or replan trigger is authored.
  - The seven-bullet **Phase 1 Acceptance Criteria** block describes cross-task observable behavior at phase end — a natural aggregation of Plan-owned per-task Test Expectations, not replan-gate criteria. Defensible inside the OWNS surface.
  - "v0.7.3+ deferral" mentions appear as task **Out:** scope-bounding markers, not as forward-phase plan authoring.

**2. Scope compliance (Plan OWNS).** All four OWNS items covered for all 44 tasks.

- Ordered task specs: T01–T44 globally sequential; the one cross-slice reorder (T12 sequenced into Slice 1.4 ahead of Slice 1.3 G9 consumers) is called out explicitly with the rationale.
- Test expectations: every task carries a `**Test expectations**` block in plain language.
- Dependencies: every task lists `**Dependencies:**` (explicit "none" where applicable); many also list `**Blocks:**`. No forward dependencies observed in spot-check across slices.
- LOC estimates: every task carries `**LOC estimate:** ~N`; six oversized tasks (T12 ~280, T16 ~320, T19 ~210, T20 ~260, T25 ~340, T39 ~360) carry explicit `**Sizing exception:**` labels (`reusable primitives`, `schema-migration`, `CI scaffolding`).

**3. Lexical boundary-drift signals.** No leakage patterns triggered:

- No Structure-layer signature leaks (no parenthesized parameter lists with return types).
- No Implement-TDD assertion strings (no `expect(`, `assert.`, `toBe(`, `assertEqual`).
- No Implement-layer logic walkthroughs (no `if/else`, `for`, `while`, line-numbered logic).
- No Design-layer authoring vocabulary in task bodies ("trade-off", "we considered", "alternative approach").
- No Phasing-layer forward-plan prose ("phase 2 will…", "future phases…", roadmap-style references); future-version mentions are scope-out markers only.

## Length check

2742 lines / 44 tasks ≈ **62 lines per task** vs. Keeplii baseline ~52 lines/task. The per-task density is near baseline; the aggregate sits ~37% above the 2000-line soft top, but the elevation is accounted for by per-task **References** blocks (typically 5–8 lines × 44 = ~250 lines of pure pointer overhead) plus the Phase 1 acceptance / dependency-graph framing. Not "well outside" the soft band; no length finding.

## Verdict

Zero scope/boundary findings. Plan stays inside its OWNS surface and defers correctly to `design.md`, `structure.md`, and `phasing.md` throughout. The "conversation, not contract" framing is honored: tasks pin observable behaviors and acceptance pins without foreclosing Structure/Implement negotiation room.
<!-- @@CLEAN: spec-claude.clean @@ -->
---
reviewer: spec-claude
round: 2
artifact: plan.md
status: clean
---

# Spec-Claude Round 2 — Clean

Verification checklist passed against `docs/qrspi/2026-05-30-v072-release/plan.md` (full route, round 2).

## 1. Completeness — every goal carries a task with test expectations
All 35 goals (G1–G35) have explicit primary-task coverage with concrete `## Test Expectations` blocks. Mapping:

G1→T30, G2→T33, G3→T20, G4→T12, G5→T34, G6→T03, G7→T01, G8→T04, G9→T13, G10→T35, G11→T06, G12→T02, G13→T05, G14→T07, G15→T14, G16→T21, G17→T36, G18→T15, G19→T08, G20→T09, G21→T40, G22→T16, G23→T17, G24→{T22,T23,T42,T43,T44}, G25→T18, G26→T41, G27→T19, G28→T10, G29→T11, G30→T32, G31→{T25,T26}, G32→T39, G33→T31, G34→T29, G35→{T37,T38}.

Cross-cutting decision tasks (T24 CD-4 interaction-mode helper, T27 CD-2 evergreen-output rule, T28 CD-3 multi-actor-flow-check) provide additional reinforcement at surfaces those CDs span; they do not substitute for primary goal coverage.

Phase 1 Acceptance Criteria (7 bullets in `### Phase 1 Acceptance Criteria`) name cross-task observable behaviors at phase boundary — end-to-end pipeline run, fail-loud invariant firing, sub-threshold instrumentation, build-pipeline reproducibility, full bats green, GitHub-issue closure, release-PR readiness. Each criterion is testable and traces to specific backing tasks (e.g., fail-loud invariants → T03/T16/T17/T18/T20/T21/T35; build pipeline → T39; etc.).

## 2. Scope — nothing outside the goals
Every task and target file traces to a goal or to one of the three approved CDs. The seven-slice decomposition (apply-fix/verifier backbone, rubric calibration, per-task review pipeline, dispatch infrastructure, skill-prose, structure-absorbs-architecture, build/release tooling) maps cleanly to the four coherent surfaces named in the Overview. No "nice-to-have" or premature-optimization tasks observed.

## 3. Interpretation — goal intent preserved or correctly remapped
G29's original "canonize `artifact_path`" framing is correctly remapped via T11 to the design-locked disposition "absorbed by CD-1, no parser contract, manifest provenance only" — matching design.md ## G29's locked outcome. Test expectations verify the chosen design (large-artifact dispatch auditable via `.dispatch-manifest.json`; no threshold rule introduced) rather than the obsolete original framing. All other goals' tasks match their stated intent.

## 4. Test Coverage Mapping
Every goal's success condition has at least one verifiable test expectation. Test expectations are specific (bats fixtures with named files, grep audits with literal anchor phrases, R1–R7 content-semantic reviews, acceptance fixtures with named round-directory artifacts) rather than vague.

Edge cases and error conditions are covered: T03 wrong-channel diagnostic, T04 missing-`change_type` diagnostic, T05 out-of-enum halt, T06 wrong-extension rejection, T08 cite-check fixtures (missing files, out-of-range lines, quoted-content mismatch, missing anchors), T12 commit-anchor recovery codes (10/11/12), T21 symlink-escape and out-of-repo `--companion` regressions, T34 mismatch/missing-header/malformed-header halt diagnostics, T35 fabricated-citation rejection, T39 symlink-escape regression mirroring T21.

T18 (G25) is the lightest test surface — explicit DoD non-goal of "no bats test introduced" because the section-level invariant is prose-only. However, downstream T22 (depends on T18) requires the class-level invariant remain present, and T44's regex-pin tests transitively guard the silent-fallback contract the paragraph establishes. Not a coverage gap.

## 5. Placeholder Detection
Scanned task specs for TBD/TODO/"similar to Task N"/"appropriate handling"/"as needed". None found. File paths are exact (target-file lists name specific paths). LOC estimates present on every task. T42's target-file conditional ("…or the current `…test-t10-*.bats` successor that owns the T10 `model_routing:` host/tier assertions") is deliberate audit-aware behavior per design.md ## G24's note that historical F01 files may be moot — the spec provides explicit locate-then-parameterize guidance rather than leaving the implementer to guess.

## 6. Task Sizing
Each of the six tasks above the 200 LOC ceiling carries a `Sizing exception` field from the closed set:
- T12 (~280, reusable primitives) — `round-prepare.sh` + `await-round.sh` + manifest/anchors JSON. Components are coupled (scripts consume manifest data); no individual sub-task would produce observable behavior change.
- T16 (~320, schema-migration) — agent-frontmatter sweep across 41 agent files plus the schema-defining config/skills edits.
- T19 (~210, reusable primitives) — `second-reviewer-available.sh` + `_host-detect.sh` + `_resolve-lib.sh` matrix + consumer migration.
- T20 (~260, reusable primitives) — three-script rename + shared snippet + 12-skill migration; atomic to avoid mixed old/new dispatch paths.
- T25 (~340, reusable primitives) — six new G31 primitive files; T26 depends on T25 producing them all at once.
- T39 (~360, CI scaffolding) — build pipeline + CI workflow + CONTRIBUTING + four bats files.

Each exception value is in the documented closed set (`schema-migration`, `CI scaffolding`, `reusable primitives`). No task title uses "+ joining" to bundle distinct feature names without an exception. The three cross-cutting CD tasks (T24, T27, T28) list multiple goal IDs because they implement CDs that span those goals, but each task delivers a single coherent CD component (interaction-mode helper / evergreen-output snippet+includes / multi-actor-flow snippet+includes) — not feature-bundling.

No tasks identified that fail the floor: each task in the surveyed set traverses the layers needed for its behavior and produces observable behavior change when merged alone.

## Result
No findings. Plan artifact is approved by spec-claude for round 2.
