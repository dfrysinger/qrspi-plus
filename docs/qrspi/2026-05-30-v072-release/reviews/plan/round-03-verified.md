---
verifier_enabled: true
scored: 26
kept: 9
dropped: 17
failed: 0
clean: 4
---

<!-- @@FINDING: goal-traceability-codex.finding-F01 @@ -->
---
reviewer_tag: goal-traceability-codex
change_type: correctness
severity: medium
artifact: plan.md
location: Phase 1 Acceptance Criteria → "Full bats suite is green against deduplicated helpers..."
referenced_files: [plan.md, goals.md, design.md]
---

# F01 — Phase-level acceptance still requires a moot G24-F03 deliverable with no backing task

`plan.md:25` requires "the consolidated H4-extraction helper passes its tests."  
But the task set no longer contains any G24-F03 helper-consolidation task (`plan.md:93-95` shows only T40 [G21,G26] and T44 [G24] in this slice), and T44 explicitly marks helper promotion as out-of-scope/moot (`plan.md:2370-2371`).  
Design also locks F03 as moot because cross-file duplication does not exist (`design.md:2063`), so this acceptance criterion is no longer traceable to planned implementation work.
<!-- @@SCORE: goal-traceability-codex.finding-F01.score @@ -->
score: 75
reason: Phase 1 acceptance criterion at plan.md:25 cites "the consolidated H4-extraction helper" (G24-F03) and "parameterized dispatch-routing assertion callers" (G24-F01) as observable phase-end behavior, but design.md:2062-2063 mark F01/F03 as moot and the only G24 task (T44) at plan.md:2370 explicitly lists them as out-of-scope, so the criterion is untraceable to planned work and Test cannot verify it.
<!-- @@FINDING: goal-traceability-codex.finding-F02 @@ -->
---
reviewer_tag: goal-traceability-codex
change_type: correctness
severity: low
artifact: plan.md
location: Task 44 → Scope → Out bullet enumerating G24-F01/F02/F03/F04 dispositions
referenced_files: [plan.md, goals.md, design.md]
---

# F02 — T44 moot-status rationale for G24-F04 does not match the cited design anchor

`plan.md:2370` says G24-F04 is "absorbed into the G3/CD-1 dispatch rewrite" and cites `design.md ## G24`.  
In the cited design section, F04 is marked moot because the old regex pattern is no longer present at meaningful volume (`design.md:2064`), not absorbed into CD-1/G3.  
That makes the citation rationale inaccurate for F04 in this bullet, even though the "no standalone task" outcome is correct.
<!-- @@SCORE: goal-traceability-codex.finding-F02.score @@ -->
score: 40
reason: Verified mismatch — plan.md:2370 says F04 was "absorbed into the G3/CD-1 dispatch rewrite" while design.md:2064 actually moots F04 because the old regex is no longer present at meaningful volume; real but minor rationale-citation drift with no implementation impact.
<!-- @@FINDING: quality-claude.finding-F01 @@ -->
---
finding_id: F01
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/plan.md
  - docs/qrspi/2026-05-30-v072-release/design.md
artifact: docs/qrspi/2026-05-30-v072-release/plan.md
---

## Plan overview misattributes G24 and G26 dispositions as "absorbed-by-CD-1"

**Location.** `plan.md` line 11, in the Overview paragraph:

> "...into 38 tasks (task numbers 1–44 with gaps at 18, 22, 23, 41, 42, 43 — those goal IDs are moot/absorbed-by-CD-1 per design.md ## G24/G25/G26/G29 and ship no standalone v0.7.2 task; numbering preserved for stable cross-references)."

**Problem.** The single umbrella phrase "moot/absorbed-by-CD-1 per design.md ## G24/G25/G26/G29" is correct for G25 and G29, but inaccurate for G24 and G26 — and the inaccuracy obscures the actual reason each gap-task ID exists.

Cross-checking design.md:

- **G25** (design.md L2084–2119, title "Per-H4 fail-loud mirror pattern: moot / absorbed by CD-1"). ✓ Correctly "absorbed by CD-1".
- **G29** (design.md L2308–2347, title "Reviewer dispatch artifact escape hatch: moot / absorbed by CD-1"). ✓ Correctly "absorbed by CD-1".
- **G24** (design.md L2045–2080, title "R4 simplify-claude advisories: re-scoped to F05 after tree audit (F01/F03/F04 moot; F02 defers to G25)"). ✗ G24 is NOT uniformly "absorbed by CD-1" — F01/F03/F04 are "moot after tree audit" (the target helpers/regex never materialized in the current tree), F02 defers to G25 (which is then absorbed by CD-1), and F05 ships as standalone T44.
- **G26** (design.md L2123–2162, title "BW02 deprecation warnings: moot / already fixed (regression-prevention rides on G21)"; also cited at plan.md L2339 in Task 40 References). ✗ G26 is NOT absorbed by CD-1 — design.md explicitly says G26's runtime concern is moot ("already-fixed" / premise inverted vs. bats-core upstream) and the regression-prevention BW02 lint rule is consolidated into G21's lint file via the G21 Amendment block (T40, plan.md L2284–2344). T40 itself carries `goals: [G21, G26]`.

The plan's own Task 40 references at L2339 quote design.md ## G26 accurately ("G26's runtime concern is moot (splitter already fixed pre-v0.7.2) and remaining work is the BW02 lint rule consolidated into G21's lint file"), so the Overview's umbrella framing actively contradicts the per-task framing later in the same plan.

**Impact.** A reader using the plan Overview to understand why six task slots are gaps will form an incorrect mental model of *why* each gap exists — and will not know to look for the G26 BW02 work inside T40, or for G24-F02's resolution chain through G25→CD-1, or for G24-F01/F03/F04's "moot after tree audit" disposition (a distinct disposition class from CD-1 absorption). The mis-attribution also hides the fact that not every gap has the same root cause, which matters when later QRSPI runs revisit the "gap-task ID" pattern to extract reusable disposition vocabulary (design.md ## G29 Open Question (c) explicitly calls out three distinct absorption flavors in this release).

**Suggested edit.** Replace the umbrella "moot/absorbed-by-CD-1 per design.md ## G24/G25/G26/G29" wording with per-gap dispositions matching design.md:

> "...into 38 tasks (task numbers 1–44 with gaps at 18 (G25, absorbed by CD-1), 22 (G24-F02, defers to G25 → CD-1), 23 (G24-F04, moot after tree audit), 41 (G26, runtime concern already fixed; BW02 regression-prevention rides on G21 in T40), 42 (G24-F01, moot after tree audit), 43 (G24-F03, moot after tree audit); G29 is also absorbed by CD-1 and ships no standalone task — T11 was repurposed to a CD-1 dispatch-manifest-provenance task under G3 rather than being deleted. See design.md ## G24/G25/G26/G29 for per-disposition rationales; numbering preserved for stable cross-references)."

Or, if a shorter overview is preferred, at minimum drop G24/G26 from the "absorbed-by-CD-1" framing and replace with the broader "moot/absorbed/already-fixed per design.md ## G24/G25/G26/G29" so the umbrella is technically defensible against all four references.
<!-- @@SCORE: quality-claude.finding-F01.score @@ -->
score: 70
reason: Verified — plan.md L11 umbrella "moot/absorbed-by-CD-1 per design.md ## G24/G25/G26/G29" is inaccurate for G24 (re-scoped to F05, not absorbed by CD-1) and G26 (already fixed; BW02 lint rides on G21, not CD-1) per design.md section titles at L2045 and L2123; T40 itself carries goals:[G21,G26]. Real correctness defect in Overview prose that contradicts the plan's own per-task references; medium-impact since it misleads readers about gap-task rationales but is fixable with a one-paragraph edit.
<!-- @@FINDING: quality-claude.finding-F02 @@ -->
---
finding_id: F02
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/plan.md
  - docs/qrspi/2026-05-30-v072-release/phasing.md
artifact: docs/qrspi/2026-05-30-v072-release/plan.md
---

## Task 11 (now [G3]) listed under Slice 1.2 but G3 belongs to Slice 1.4 per phasing.md — unexplained slice/goal mismatch

**Location.** `plan.md` lines 45–50 (Slice 1.2 task listing) and L675–727 (Task 11 spec body).

The Slice 1.2 task list reads:

> ### Slice 1.2 — Verifier rubric calibration + instrumentation
>
> - **Task 08 — G19 verifier wholesale-hallucination rubric class** — goals: [G19] ...
> - **Task 09 — G20 reviewer-model calibration for task-tool-substituted Codex model** — goals: [G20] ...
> - **Task 10 — G28 verifier convergent-evidence exception and sub-threshold-observations instrumentation** — goals: [G28] ...
> - **Task 11 — G3 dispatch-manifest provenance fields (`subagent_type`/`host`/`vendor`/`model`/`prompt_file` in `.dispatch-manifest.json`)** — goals: [G3] ...

**Problem.** Per `phasing.md` (the authoritative slice decomposition):

- Slice 1.2 surface (phasing.md L58–67): "verifier scoring rubric (hallucination class detection, model calibration), and the dispositions + sub-threshold-observations instrumentation formalized in G28." Slice 1.2 goals are **G19, G20, G28, G29**.
- Slice 1.4 surface (phasing.md L78–92): "shell-pipeline splitter, canonical cumulative diff helper, path-filter exfil surface in the Codex review dispatch wrapper, unified dispatch-routing config schema, validation table cross-linking, top-level fail-loud invariant for the dispatch-routing section (G25), per-H4 prose redundancy consolidation..., and the Goals skill's Codex-availability helper." Slice 1.4 goals are **G3, G4, G16, G22, G23, G24 (F02, F04), G25, G27**.

T11's now-relabeled work — `G3 dispatch-manifest provenance fields in .dispatch-manifest.json` — is a CD-1 dispatch-infrastructure deliverable (Slice 1.4 surface), not verifier-rubric-or-instrumentation work (Slice 1.2 surface). The round-02 surgery relabeled T11 from `[G29]` to `[G3]` (per round-context: "T11 RE-LABELED from `[G29]` to `[G3]` (CD-1 dispatch-manifest provenance, full body rewrite)") but kept T11 in its original Slice 1.2 numbered position for task-number stability, without moving it to Slice 1.4 or annotating the mismatch.

The plan's own Dependency Graph item 4 (L106) confirms T11 is dispatch work, grouping it with T09 / T13 / T20 as the dispatch-surface pre-rename chain. T11's body Overview (L687–689) opens with "CD-1's universal dispatch architecture needs the `.dispatch-manifest.json` schema extended with resolved per-dispatch provenance" — pure Slice 1.4 framing.

**Why this matters.**

1. A maintainer reading "Task List by Slice" sees a [G3] task sitting under "Slice 1.2 — Verifier rubric calibration + instrumentation" and reasonably concludes either (a) the slice grouping is incoherent, (b) the task is mis-labeled, or (c) some hidden coupling between G3 and verifier rubric exists. None of these is true; the actual cause (round-02 relabel preserved numbering at the cost of slice coherence) is captured nowhere in the plan body.

2. The plan overview's "all 35 goals decomposed across seven vertical slices" claim implies a clean goal-to-slice mapping. With T11 in Slice 1.2 but its goal in Slice 1.4 per phasing, the mapping is not clean.

3. The Plan-quality "Phase alignment" check expects task slice/phase assignments to match phasing.md's slice definitions. This one violates that alignment without justification.

**Suggested fix (pick one).**

**Option A (preferred — move task):** Renumber the Slice 1.2 list to T08/T09/T10 only, and move T11's entry into the Slice 1.4 task list (immediately before T16, or wherever its dependency ordering with T09 places it cleanly). Update any "Task 11" cross-references in dep-graph item 4 and in T20's `Dependencies:` line (L1171) to track the new number — or keep T11's number and only move the *display position* between slices, leaving the number stable.

**Option B (minimal — annotate in place):** Keep T11 numerically in Slice 1.2, but add a one-line note under the Slice 1.2 heading or after T11's bullet that records the divergence, e.g.:

> *(Task 11's goal is [G3] dispatch-manifest provenance, which is Slice 1.4 surface per phasing.md. The task remains parked under Slice 1.2 by number for cross-reference stability after the round-02 relabel of T11 from `[G29]` (absorbed by CD-1) to `[G3]`; its dependency ordering with T09 also keeps the dispatch-surface pre-rename chain tight.)*

Option A produces the cleanest reader experience; Option B is the smaller diff. Either resolves the silent slice/goal mismatch.
<!-- @@SCORE: quality-claude.finding-F02.score @@ -->
score: 70
reason: Verified — T11 carries [G3] (a Slice 1.4 dispatch-surface goal per phasing.md L80) but is listed under the "Slice 1.2 — Verifier rubric calibration + instrumentation" heading at plan.md L45–50, and T11's own body (L687–689) frames it as CD-1 dispatch work; the divergence is real and unannotated in the plan body, fitting the Plan-quality phase-alignment check.
<!-- @@FINDING: quality-codex.finding-F01 @@ -->
---
reviewer_tag: quality-codex
change_type: correctness
severity: high
artifact: plan.md
location: Phase 1 Acceptance Criteria
referenced_files: [plan.md]
---

# F01 — Phase acceptance still requires outcomes from deleted/moot tasks

`Phase 1 Acceptance Criteria` still mandates three outcomes that were removed by the round-02 surgery: "parameterized dispatch-routing assertion callers," "consolidated H4-extraction helper," and "bats-deprecation warnings on test-codex-splitter.bats are gone" (plan.md:25). Those map to the deleted/moot G24-F01/G24-F03/G26 standalone work.

The task specs now explicitly mark those surfaces as moot/non-shipping in v0.7.2: Task 44 excludes G24-F01/F03 as moot (plan.md:2370), and Task 40 excludes broader deprecation sweep beyond BW02 rule delivery (plan.md:2309). This creates a release-gate contradiction where acceptance requires work the task plan no longer performs.

**Suggested fix:** rewrite the Phase 1 criterion to match surviving deliverables (T40 + T44), removing F01/F03 standalone-helper/caller requirements and the obsolete `test-codex-splitter.bats` deprecation requirement unless a task is reintroduced to deliver it.
<!-- @@SCORE: quality-codex.finding-F01.score @@ -->
score: 85
reason: Verified — Phase 1 Acceptance Criteria (plan.md:25) requires three bats outcomes (parameterized dispatch-routing callers, consolidated H4-extraction helper, test-codex-splitter.bats deprecation) that T44 (line 2370) and T40 (line 2309) explicitly declare moot/out-of-scope, creating a real release-gate contradiction.
<!-- @@FINDING: quality-codex.finding-F02 @@ -->
---
reviewer_tag: quality-codex
change_type: correctness
severity: medium
artifact: plan.md
location: Overview paragraph vs Dependency Graph / Task List by Slice
referenced_files: [plan.md]
---

# F02 — "Only cross-slice prerequisite is G4→G9" is contradicted by later dependencies

The Overview claims G4→G9 is "the only cross-slice prerequisite" and that "otherwise each slice's tasks chain only within-slice" (plan.md:11). But the same document later defines another cross-slice chain: T09 (Slice 1.2) + T11 (Slice 1.2) + T13 (Slice 1.3) feeding T20 (Slice 1.4) (plan.md:50, 56, 62, 66, 72, 106–112).

This is an internal planning contradiction that can mislead sequencing/parallelization decisions for round ordering and merge planning.

**Suggested fix:** update the Overview claim to acknowledge the T09/T11/T13→T20 cross-slice prerequisite (or re-slice/re-home T11 if the intent was to keep cross-slice prerequisites singular).
<!-- @@SCORE: quality-codex.finding-F02.score @@ -->
score: 72
reason: Verified internal contradiction — Overview's "only cross-slice prerequisite is G4→G9" is directly contradicted by Dependency Graph cluster #4 (T09/T11/T13→T20) and by several other task-level cross-slice deps (T24→T02, T35→T03, T37→T29, T39→T25, T44→T17).
<!-- @@FINDING: scope-codex.finding-F01 @@ -->
---
reviewer_tag: scope-codex
change_type: scope
severity: medium
artifact: plan.md
location: Task 39 → Definition of done
referenced_files: [plan.md]
---

# F01 — Plan embeds implementation helper signature/parameter shape

`plan.md` specifies an implementation-level helper-call shape in the task spec: `assert_path_under_repo_root <label> <abs-path>` (plan.md:2252), alongside concrete canonicalization API guidance (`fs.realpathSync`/`readlink -f`) and guard mechanics. That is a Structure/Implement altitude detail, not Plan task-spec altitude.

This conflicts with the Plan DEFERS contract: function signatures and parameter shapes are explicitly deferred to Structure (`skills/plan/owns-defers.md:20`), and line-by-line implementation logic is deferred to Implement (`skills/plan/owns-defers.md:22`).
<!-- @@SCORE: scope-codex.finding-F01.score @@ -->
score: 72
reason: Plan.md line 2252 names a helper-call parameter shape (`assert_path_under_repo_root <label> <abs-path>`) and specific implementation APIs (`fs.realpathSync`, `readlink -f`), which directly violates the documented Plan DEFERS rule and boundary-drift signal in plan/owns-defers.md (signatures/parameter shapes belong in structure.md).
<!-- @@FINDING: scope-codex.finding-F02 @@ -->
---
reviewer_tag: scope-codex
change_type: scope
severity: medium
artifact: plan.md
location: Task 40 → Scope / Definition of done / Test expectations
referenced_files: [plan.md]
---

# F02 — Plan includes concrete test-assertion code and parser mechanics

Task 40 includes explicit assertion/code forms and parser-level mechanics in Plan: e.g., `[[ "$body" != *...* ]]`, `[ -n "$body" ]`, `^@test "..." \{`, and column-0 `}` parsing requirements (plan.md:2302-2304, 2316-2319, 2327-2330). These are not plain-language expectations; they are concrete assertion syntax and implementation mechanics.

This crosses Plan boundaries defined in owns-defers: full assertion text/test code belongs to Implement-TDD (`skills/plan/owns-defers.md:21`), and algorithm/control-flow details belong to Implement (`skills/plan/owns-defers.md:22`).
<!-- @@SCORE: scope-codex.finding-F02.score @@ -->
score: 35
reason: Real boundary-drift signal under a strict reading of owns-defers (concrete shell assertion syntax `[ -n "$body" ]` and parser mechanics like `^@test "..." \{` and column-0 `}` appear in Scope/DoD/Test prose), but the cited tokens are largely the syntactic pattern that *is* the lint's behavior — and an equivalent scope-codex.F02 was already declined in round 02 under F-5 with scope-claude clearing it, making this a contested, low-stakes nitpick rather than a load-bearing leak.
<!-- @@FINDING: security-claude.finding-F01 @@ -->
---
finding_id: F01
reviewer: security-claude
round: 3
artifact: plan.md
change_type: correctness
severity: high
task_refs: [T11]
---

# F01 — T11 dispatch-manifest provenance has no spoofing-resistance test expectations

## Summary

Task 11 introduces `dispatch_spec.{subagent_type,host,vendor,model,prompt_file}` in
`.dispatch-manifest.json` so reviewer dispatch is "auditable end-to-end." That framing
is **load-bearing for security** — downstream verifier and post-hoc auditors will rely on
these fields to decide which model produced which finding. But the task's Test
Expectations cover only **presence**, **append-safety**, and **well-formedness of JSON**.
They do not require that the values be authentic, trusted-sourced, or
unspoofable by the very dispatch input the manifest is supposed to audit.

## Specific gaps in T11 Test Expectations (lines 713–718)

1. **No "trusted-source" test.** The four expectations exercise dispatch and inspect
   the manifest. None pins where each field MUST be sourced from (e.g. resolver
   output / process-controlled environment) vs where it MAY come from caller-supplied
   CLI flags or prompt-file content. If `--vendor=foo` (or any analogous flag) is
   accepted from the dispatch caller and written straight into the manifest, a hostile
   prompt or upstream agent can label its own dispatch as a different vendor/model in
   the audit log. The plan never says "values must come from the same resolver that
   actually selected the dispatch" or "values are validated against the
   `model_routing:` resolved tuple."

2. **No enum / format validation.** `vendor` and `host` have a known closed set
   (Copilot CLI / Claude Code / future Codex CLI / `openai-codex` / `anthropic` / etc.
   per T19 and T16). The DoD does not require rejecting out-of-enum values, nor does
   the test list a malformed-host/vendor rejection case. An attacker who controls any
   input that flows into these fields can write arbitrary strings (`"unknown"`,
   `"trusted-source"`, `"approved"`) into the audit trail.

3. **No JSON-injection / control-character test.** Manifest writes are required to be
   "atomic and append-safe," but the task does not pin escape semantics. If
   `subagent_type` or `prompt_file` can carry a quote, backslash, or newline (path with
   `"` or `\n` in it is unusual but possible on some filesystems and trivially possible
   in a deliberate fixture), the implementer's first instinct may be string
   concatenation rather than a JSON encoder. There is no fixture that includes
   metacharacter-bearing values and verifies the resulting manifest still parses as a
   single well-formed JSON document with the literal value preserved. Without this
   test, the implementation can silently produce invalid JSON or fields that escape
   their own context.

4. **No `prompt_file` canonicalization gate.** T21 adds canonicalization
   (`assert_path_under_repo_root`) **only** to `dispatch-agent.sh`. T11 modifies
   `scripts/run-codex-review.sh` (the pre-rename script) and writes `prompt_file`
   into the manifest. The plan's dependency chain is T11 → T20 (rename) → T21
   (hardening); after T21 lands, the path that the dispatch script accepts will be
   canonicalized. But T11's DoD/Test Expectations should still pin that the value
   written into `dispatch_spec.prompt_file` is the **canonicalized** path (the one
   the script will actually read), not the raw caller-supplied lexical path. Today,
   the only assertion is "manifest contains a `prompt_file` field" — a path
   that's been rejected by T21's guard or a symlink that was rewritten to its
   realpath could still appear in the manifest under whatever string the caller
   passed, making the audit trail unreliable.

## Why this matters at plan level

The release Phase 1 Acceptance Criteria block (line 22) commits to fail-loud
behavior on "misrouted `model_routing` entries" and "the path-filter exfil guard."
The dispatch manifest is the only after-the-fact instrument the verifier and human
auditors have for spotting that an entry **did** route correctly. If a reviewer
agent (especially a third-party one) can rewrite its own `dispatch_spec` block, the
release's audit story collapses silently — no fail-loud surface fires. The
implementer will build exactly what T11 specifies; today T11 specifies "field
appears" and nothing about authenticity.

## Recommended remediation (do not require any specific wording)

Add to T11 Test Expectations:

- A fixture proving each `dispatch_spec` field is read from the resolver / locked
  environment, not from a flag the dispatch caller controls — or, if any field is
  caller-controlled by design, a fixture proving that field is validated against
  the resolved-tuple before write and rejected (non-zero exit, no manifest
  append) on mismatch.
- A vendor/host enum-validation fixture rejecting out-of-set values with a
  diagnostic.
- A metacharacter-bearing-value fixture verifying the manifest remains valid JSON
  and the literal value round-trips through a JSON parser.
- A `prompt_file` fixture proving the manifest records the canonical (post-realpath)
  path, not the raw caller string, when those differ.

## Files / sections to update

- `plan.md` Task 11 → **Test expectations** block (currently lines 713–718).
- `plan.md` Task 11 → **Definition of done** (currently lines 707–711) — add
  explicit "values are sourced from <resolver/locked-env>" and "JSON escape
  invariant" bullets so the implementer knows the intent.
<!-- @@SCORE: security-claude.finding-F01.score @@ -->
score: 22
reason: Spoofing premise contradicted by design.md CD-1 (dispatch-agent.sh takes only --agents tag=agent-name; host/vendor/model come from _resolve-lib.sh + _host-detect.sh, never caller flags); fail-loud on misrouted model_routing is already a Phase 1 Acceptance Criterion (line 22) plus CD-1 has a locked smoke-test for the none-tier halt; JSON-escape concern is subsumed by the "well-formed JSON" expectation (line 717); prompt_file canonicalization is explicitly T21's deliverable per the cited dependency chain so requiring it in T11 is dependency-inverted.
<!-- @@FINDING: security-claude.finding-F02 @@ -->
---
finding_id: F02
reviewer: security-claude
round: 3
artifact: plan.md
change_type: correctness
severity: medium
task_refs: [T21]
---

# F02 — T21 companion-dispatcher audit is fail-OPEN; no regression test pins the path-input invariant

## Summary

Task 21 (G16 path-filter exfil hardening) installs a hard
`assert_path_under_repo_root` guard in `scripts/dispatch-agent.sh` for the four
known path-family flags (`--subject-code`, `--artifact-body`, `--companion`,
`--diff-file`). For `scripts/dispatch-companion.sh` — the SECOND sanctioned-channel
entry point — the task takes a different shape:

> "Audit `scripts/dispatch-companion.sh`: if it accepts raw file paths directly,
> share the same repo-boundary guard; otherwise document that it receives
> assembled prompt data rather than arbitrary file paths." (plan.md line 1256)

> DoD: "`scripts/dispatch-companion.sh` is audited for direct raw-file-path
> inputs and either shares the guard for any such inputs or documents that it
> receives assembled prompt data rather than arbitrary file paths." (line 1272)

> Test expectations: "Audit inspection confirms `scripts/dispatch-companion.sh`
> either uses the shared boundary guard for direct raw-file-path inputs or
> carries the documented no-raw-path comment." (line 1283)

This is **fail-open against future regression**:

1. If the audit's conclusion is "no raw paths today, ship a documentation
   comment," nothing in v0.7.2 enforces that the invariant **stays true** under
   future edits. A v0.7.3+ change adding a `--companion-input` or `--prompt-from`
   flag to `dispatch-companion.sh` will pass the test (the doc comment is still
   present), pass G16's existing tests (which only exercise `dispatch-agent.sh`),
   and silently re-open the exfil surface.

2. The "audit inspection" test expectation is satisfied by **finding a comment
   string** — it does not actually verify the runtime behavior. A
   string-presence test on a doc comment is a weak proxy for "no raw-file-path
   inputs are accepted" and will not catch a new flag that was added without
   updating the comment.

3. The two reviewer-relevant exfil dispatchers (`dispatch-agent.sh` and
   `dispatch-companion.sh`) end up with **two different security postures**:
   one with executable guards plus regression tests, one with at most a doc
   comment. Operators relying on the G16 invariant cannot distinguish from the
   outside which dispatcher carries which posture.

## Why this matters at plan level

The Phase 1 Acceptance Criteria block calls out "the path-filter exfil guard in
`scripts/dispatch-agent.sh`" as one of the seeded fail-loud invariants
(line 22). The same surface in `dispatch-companion.sh` is conspicuously absent
from that release-level criterion. The G16 deferral note (line 1260) accepts
that "broader all-`scripts/` sanctioned-channel exfil sweeps... [are] deferred
to v0.7.3+", but the **companion script is not one of the deferred ones** —
T21 explicitly puts it in scope and then degrades the contract into a
doc-comment check.

The implementer will read T21 as written and (rightly) conclude that emitting a
"this dispatcher receives assembled prompt data" comment satisfies the
contract. The next round of changes loses the invariant silently.

## Recommended remediation (do not require any specific wording)

Either:

- **Symmetrize.** Require `scripts/dispatch-companion.sh` to install the same
  `assert_path_under_repo_root` guard on **every** path-shaped argument it
  accepts now or in the future, with the same fail-closed semantics. The DoD
  then becomes "no raw-file-path argument is accepted without canonicalization"
  rather than "a comment is present."

- **Or pin the invariant executably.** Replace the doc-comment audit with a
  unit-test fixture that drives `dispatch-companion.sh` with every known
  argument family and asserts: either (a) the flag is rejected as unknown, or
  (b) the flag's value goes through the shared
  `assert_path_under_repo_root` guard. Future additions of path-shaped flags
  then have to extend the fixture to land, which prevents silent
  re-introduction of the exfil surface.

## Files / sections to update

- `plan.md` Task 21 → **Definition of done** bullet on `dispatch-companion.sh`
  (line 1272).
- `plan.md` Task 21 → **Test expectations** bullet on `dispatch-companion.sh`
  audit (line 1283).
- Consider adding `dispatch-companion.sh` to the Phase 1 Acceptance fail-loud
  list (line 22) so it gets release-level coverage.
<!-- @@SCORE: security-claude.finding-F02.score @@ -->
score: 22
reason: Design G16 § C and deliverable 4 explicitly lock the "1-paragraph audit; if no raw paths, document with a one-line comment" option and defer broader scripts/ sweeps to v0.7.3 (#268); Plan's T21 faithfully transcribes that locked design decision, so the finding re-litigates a Design-altitude choice rather than identifying a Plan-altitude defect.
<!-- @@FINDING: security-claude.finding-F03 @@ -->
---
finding_id: F03
reviewer: security-claude
round: 3
artifact: plan.md
change_type: correctness
severity: medium
task_refs: [T39]
---

# F03 — T39 `!cat` resolver can inline dev-only / unshipped content into shipped build files; strip-list invariant is not pinned

## Summary

Task 39's build pipeline strips dev-only directories (`docs/`, `tools/`,
`tests/`) from the shipped `build/` tree (DoD line 2242:
"excludes dev-only `build/docs/`, `build/tools/`, and `build/tests/`"). The
`!cat` resolver enforces two path-shape invariants for include targets:

1. Strict whole-line bare-relative grammar (DoD line 2244).
2. Canonical-target-under-`$REPO_ROOT/` symlink-escape rejection (DoD line 2252).

Neither invariant prevents a SHIPPED runtime file (say
`skills/foo/SKILL.md`) from carrying `!cat tests/secret.md` or
`!cat docs/internal-only-design-notes.md`. Both are inside `$REPO_ROOT`, both
have valid bare-relative paths, neither symlink-escapes. The resolver would
happily inline that content into the shipped `build/skills/foo/SKILL.md`, even
though `tests/` and `docs/` themselves never appear in the build tree.

This breaks the dev-only/runtime separation that DoD line 2242 commits to:
"excludes dev-only `build/docs/`, `build/tools/`, and `build/tests/`." The
file-tree level strip-list is bypassable at the **content level** by any
`!cat` directive in a shipped file. The Test Expectations (lines 2256–2267) do
not include a fixture exercising this case.

## Concrete leakage scenarios this enables

1. **Unintentional content leak.** Test fixtures, internal-only docs,
   maintainer-only notes, and any other file deliberately excluded from the
   shipped plugin can be silently embedded into the user-facing skill prose
   via an authoring oversight (`!cat tests/fixtures/sample-prompts/...md`).
   The build succeeds, the diff-gate passes (because `build/` is regenerated
   consistently), and the leak ships.

2. **Future-secret leak.** If `tools/` ever contains a developer
   credential file, generated key material, or vendor-bundled config that the
   strip-list is the only protection against, a single shipped file with
   `!cat tools/<file>` would inline it. Today there's no rule preventing it
   from being added.

3. **Surface for future supply-chain attacks.** A malicious PR can
   add `!cat tests/secret-payload.md` to a shipped SKILL.md as a one-line
   change. Reviewers checking the SKILL.md diff see only a tiny include
   directive; the actual embedded payload lives in `tests/`, which most
   reviewers will treat as not-shipped. The build does what it's told. The
   adversary's payload reaches every end user via the marketplace `./build`
   tarball.

## Why the existing T39 guards don't catch this

- **Outside-root check** (DoD line 2245): `tests/` IS inside the repo root.
  The guard fires only for `/etc/passwd`-shaped targets.
- **Symlink-escape check** (DoD line 2252): `tests/secret.md` is not a
  symlink; it's a regular file inside the repo. The realpath guard passes.
- **Strip-list** (DoD line 2242): operates on whole-tree copy/exclude, not on
  resolver-time `!cat` resolution. By the time `!cat` runs, the resolver
  already has bytes from the unshipped path in memory and writes them into a
  shipped file.

## Recommended remediation (do not require any specific wording)

Add to T39 a **build-set membership invariant** on the resolver:

- A `!cat` target's canonical path MUST be lexically inside one of the
  runtime-include directories (the same allow-list that already drives the
  copy step), not just inside `$REPO_ROOT`. Targets in `docs/`, `tools/`,
  `tests/`, or any path otherwise excluded from `build/` fail non-zero with a
  diagnostic naming the violating include and the unshipped directory.

Add the matching test expectation:

- A fixture commits a shipped runtime file containing
  `!cat tests/fixtures/sample.md` (and the same against `docs/`, `tools/`).
  The build fails non-zero with a diagnostic identifying the dev-only target.
  Without this fixture, the strip-list invariant the DoD claims is not
  actually enforced at content level.

## Files / sections to update

- `plan.md` Task 39 → **Scope: In** (lines 2220–2231) or **Definition of done**
  (around line 2244) — add the build-set membership invariant.
- `plan.md` Task 39 → **Test expectations** (lines 2256–2267) — add a
  dev-only-inline fixture alongside the existing symlink-escape and
  path-traversal fixtures.
<!-- @@SCORE: security-claude.finding-F03.score @@ -->
score: 58
reason: Real invariant-pinning gap — T39 strips build/tests, build/tools, build/docs at file-tree level but resolver guards (within-repo + symlink-escape + grammar) don't prevent a shipped file from `!cat`-inlining dev-only content; defense-in-depth/consistency fix is small but practical occurrence rate from authoring oversight is modest.
<!-- @@FINDING: security-claude.finding-F04 @@ -->
---
finding_id: F04
reviewer: security-claude
round: 3
artifact: plan.md
change_type: correctness
severity: medium
task_refs: [T20]
---

# F04 — T20 `third-party-finding-splitter.sh` test expectations omit adversarial reviewer-controlled boundary inputs

## Summary

Task 20 collapses the third-party reviewer pipeline into
`dispatch-companion.sh` (capture raw output to `<round-dir>/.dispatch/<tag>.raw`)
plus `third-party-finding-splitter.sh` (materialize stable per-finding files
`F01`, `F02`, ... or a `NO_FINDINGS` sentinel). The splitter consumes
reviewer-produced raw text — **fully untrusted, third-party LLM output** — and
writes filesystem artifacts that downstream verifier and apply-fix steps
trust by path.

The DoD (line 1201) says the splitter "fails loudly for missing flags, missing
raw output, missing boundaries, or write errors." The Test Expectations
(line 1212) exercise stable `F01, F02, ...` materialization, the
`NO_FINDINGS` sentinel, and loud failure for missing flags/raw output/boundaries
/write errors.

What's missing: any **adversarial-content** test for reviewer-controlled
content that **is well-formed enough to parse** but contains payloads
designed to subvert the splitter's filesystem semantics. The splitter walks
untrusted text and produces filesystem paths; that boundary deserves explicit
hostile-input fixtures.

## Specific gaps

1. **No fixture for an injected per-finding identifier.** The splitter
   produces `F<NN>` files. If the splitter computes the `<NN>` from a
   reviewer-controlled header (e.g., `## Finding F01`) rather than from its
   own monotonic counter, a hostile reviewer could emit
   `## Finding F../../etc/passwd` or `## Finding F01.md\0extra` and trick the
   splitter into writing outside the round directory or overwriting an
   adjacent finding's score sidecar. The plan does not pin
   "identifier is splitter-assigned, not reviewer-supplied" and the tests do
   not include any path-traversal-via-finding-id fixture.

2. **No fixture for boundary tokens embedded in finding bodies.** If a
   reviewer emits a finding body containing the splitter's section-boundary
   sentinel (e.g., a finding whose text contains the literal start-of-next-finding
   marker), the splitter may split mid-content, producing F01 with truncated
   body and F02 with reviewer-controlled prefix. The verifier then scores
   these as if they were authentic separate findings. Test expectations cover
   "missing boundaries" but not "extra/injected boundaries."

3. **No fixture for a forged `NO_FINDINGS` sentinel inside a finding body.**
   A reviewer that emits both real findings and a body containing the literal
   `NO_FINDINGS` string can produce a state where the splitter writes both a
   findings set AND a clean sentinel (or chooses the sentinel and drops the
   findings). The downstream consumer cannot tell. Plan DoD does not pin
   "sentinel detection is whole-document, not substring, and is mutually
   exclusive with finding emission."

4. **No fixture for control characters / NUL bytes in finding text.** Bash
   string handling and many splitter implementations mishandle NUL or CR
   silently. The splitter writes files whose contents become "untrusted data"
   read by other agents; if the reviewer can embed terminator bytes, the
   downstream wrapper-based protections may be bypassed at consumption time.

## Why this matters at plan level

The whole T20 contract is "reviewer output persistence stays inside the
script chain instead of repeated orchestrator-side prose" (line 1177). The
script chain is now the **trust boundary** between third-party LLM output and
the verifier. The plan correctly puts payloads into files (good — wrapper
markers can be applied by readers) but treats the splitter's parsing of
those payloads as a structural problem (missing/unmatched boundaries) rather
than as a hostile-input problem.

Without these fixtures, the implementer will build a splitter that handles
well-formed and structurally-broken input but is silently unsafe against any
adversarial reviewer payload that lands within the structural envelope.

## Recommended remediation (do not require any specific wording)

Add to T20 Test Expectations:

- A fixture proving `F<NN>` identifiers are splitter-assigned
  (monotonic counter), and that any reviewer-emitted `F<...>`-shaped token
  in section headers is treated as content, not as a write-path component.
- A fixture proving boundary-token injection within a finding body does not
  cause mid-content split or per-finding-file boundary confusion.
- A fixture proving `NO_FINDINGS` sentinel detection requires the canonical
  whole-document shape and is mutually exclusive with per-finding emission
  (presence of both fails loud).
- A fixture proving NUL / CR / other control bytes in reviewer text are
  either stripped pre-write or fail the splitter loudly — and that whatever
  the chosen policy is, it is uniform.

## Files / sections to update

- `plan.md` Task 20 → **Definition of done** for splitter behavior
  (line 1201).
- `plan.md` Task 20 → **Test expectations** for splitter coverage
  (line 1212).
<!-- @@SCORE: security-claude.finding-F04.score @@ -->
score: 45
reason: T20 owns the splitter that consumes untrusted third-party LLM output and Phase 1 acceptance already lists "splitter on adversarial Codex stdout" as a fail-loud invariant, yet T20's DoD/Test Expectations only cover structural failure modes (missing flags/raw/boundaries/write errors), not content-injection fixtures (path-traversal IDs, embedded boundary tokens, forged NO_FINDINGS, control bytes) — a real but partially speculative gap that some reviewers would treat as implementation-altitude detail rather than plan-altitude pin.
<!-- @@FINDING: security-claude.finding-F05 @@ -->
---
finding_id: F05
reviewer: security-claude
round: 3
artifact: plan.md
change_type: clarity
severity: low
task_refs: [T19]
---

# F05 — T19 `second-reviewer-available.sh` vendor override accepts unvalidated CLI input

## Summary

Task 19 creates `scripts/second-reviewer-available.sh` with "no-arg default-vendor
lookup, optional diagnostic vendor override" (line 1115). The override is
explicitly bounded ("does not read `model_routing:` or enforce primary/second
vendor distinctness" — line 1142) and unavailable paths fail loud with one
`[second-reviewer-unavailable]` diagnostic. So far so good.

What's not pinned: any input-validation contract on the override string itself.
The probe consumes the value, looks it up in the shared matrix in
`_resolve-lib.sh`, and either succeeds, exits non-zero with `unknown vendor`, or
exits non-zero with `unavailable vendor`. The Test Expectations
(lines 1140–1147) cover known-vendor success, unknown-vendor failure, and
matrix shared-source enforcement — but no fixture covers what happens when
the override is hostile-formatted (path traversal, shell metacharacters,
embedded newlines, control bytes, very long strings).

## Concrete concerns

1. **The override value will appear in error messages.** Line 1132 requires
   the diagnostic to "name... the detected host plus requested/default
   vendor." If the vendor string contains control bytes or terminal escape
   sequences, the diagnostic written to stderr can corrupt terminal state for
   the operator or hide adjacent diagnostic lines. The plan does not pin a
   sanitization rule for diagnostic interpolation.

2. **`_resolve-lib.sh` lookup contract is opaque to T19.** If
   `_resolve-lib.sh`'s vendor-lookup helpers use the value as part of a
   filesystem path, an array index, or a `case` glob pattern, an override
   like `'*'` or `'../codex'` may match unintended entries or escape the
   intended lookup table. T19's tests assert "shared-source tests fail if
   the probe carries a parallel hardcoded host table" (line 1143), but no
   test asserts the matrix lookup treats the override as opaque-data rather
   than as a pattern/path.

3. **Override is mentioned as "diagnostic" only, but exit code is
   load-bearing.** Callers that script around this probe (the Goals SKILL
   migration the same task lands, line 1117) will likely use exit code to
   decide whether to set `second_reviewer: false`. If a hostile or malformed
   override can swing the exit code in an unintended direction (e.g., a value
   that happens to match a wildcard and return 0 when no real second reviewer
   exists), Goals proceeds with `second_reviewer: true` against a vendor
   that isn't actually available. Tests don't include this case.

## Why this matters at plan level

This is **low severity** because the probe is intended to be operator-invoked
or invoked from another script under operator control, not from network input.
The attack surface is shallow. But the plan is otherwise careful about
fail-loud invariants in this area, and the lack of any input-shape rule on the
override stands out as an inconsistent gap that a future change could widen
(e.g., if the probe ever gets called from a SKILL that interpolates a
user-typed value).

## Recommended remediation (do not require any specific wording)

Add to T19 Test Expectations one of:

- A bounded-charset fixture asserting that override values matching the
  documented vendor-token shape (e.g., lowercase alphanumeric + hyphen) are
  accepted, and anything else (path components, metacharacters, control bytes)
  is rejected pre-lookup with the same `[second-reviewer-unavailable]`
  diagnostic — or with a distinct `[second-reviewer-invalid]` diagnostic so
  callers can distinguish "no matching vendor" from "you passed garbage."

- A "matrix-lookup is opaque-data" fixture passing `*`, `?`, `../`, and similar
  shell-glob / path-shape values and asserting the lookup neither matches a
  real vendor by coincidence nor escapes the intended lookup table.

Either remediation is small (probably <10 lines of test fixture) and prevents
a class of latent regressions as the probe acquires more callers.

## Files / sections to update

- `plan.md` Task 19 → **Definition of done** (lines 1129–1136) — add an
  override-shape constraint.
- `plan.md` Task 19 → **Test expectations** (lines 1140–1147) — add a
  malformed-override fixture.
<!-- @@SCORE: security-claude.finding-F05.score @@ -->
score: 18
reason: Self-acknowledged low-severity speculative hardening for an operator-invoked probe with no real adversarial surface; concerns are conditional on unimplemented `_resolve-lib.sh` behaviors and not required by any upstream artifact.
<!-- @@FINDING: security-codex.finding-F01 @@ -->
---
reviewer_tag: security-codex
change_type: correctness
severity: high
artifact: plan.md
location: Task 11 + Task 20 test/DoD contracts
referenced_files: [plan.md]
---

# F01 — Dispatch manifest is treated as trusted input without a fail-closed validation contract

Task 11 requires writing `dispatch_spec` fields and only tests for field presence/well-formed JSON (`plan.md` lines 707–719), but does not require rejecting malformed or forged manifest entries.  
Task 20/await-round behavior consumes manifest entries to drive background completion/splitting (`plan.md` lines 1185, 1202, 1213), and structure/design explicitly model command-bearing manifest fields (`await_cmd`, `split_cmd`) as execution inputs.  
That creates a fail-open path: a tampered `.dispatch-manifest.json` can spoof provenance (`host/vendor/model/subagent_type/prompt_file`) and potentially steer round processing, while still satisfying current acceptance checks that only assert presence/shape.  
A security-hardening plan should explicitly add schema + semantic validation (required keys, allowed enums/hosts/vendors, path constraints, command template constraints, and reject-on-invalid before execution).
<!-- @@SCORE: security-codex.finding-F01.score @@ -->
score: 20
reason: Altitude mismatch and weak threat model — the manifest is a script-chain-local file inside the repo (an attacker with write access there already has code execution), no upstream goal/design calls for manifest schema validation, and the finding asks Plan to invent new hardening requirements rather than refine task decomposition; G16 already covers the realistic sanctioned-channel exfil surface.
<!-- @@FINDING: security-codex.finding-F02 @@ -->
---
reviewer_tag: security-codex
change_type: correctness
severity: medium
artifact: plan.md
location: Task 40 BW02 minimum-version rule Test expectations
referenced_files: [plan.md]
---

# F02 — BW02 minimum-version hardening lacks explicit bypass/regression tests

Task 40 defines a BW02 lint "surface" with initial trigger `run --separate-stderr` and asks reviewers to confirm the rule exists (`plan.md` lines 2305, 2320, 2330), but does not require adversarial tests that the version-check cannot be bypassed.  
As written, an implementation could pass by matching trigger text while still missing fail-closed behavior for common bypasses (e.g., non-effective/minplaced guard, commented guard, malformed guard, or parser edge cases), and the plan's acceptance contract would not catch it.  
Given this task is now the canonical G26 deliverable, the test contract should require seeded bypass fixtures that must fail, not just presence/review of the rule surface.
<!-- @@SCORE: security-codex.finding-F02.score @@ -->
score: 30
reason: Real but minor gap — Plan relies on reviewer inspection rather than an executable positive-fixture for BW02 trigger detection, but the cited bypass examples (commented/malformed guards) describe G21 $body-guard concerns, not the BW02 minimum-version rule (which simply pattern-matches one trigger string), and adversarial-fixture rigor at this altitude is more an implementation choice than a Plan defect.
<!-- @@FINDING: silent-failure-claude.finding-F01 @@ -->
---
reviewer_tag: silent-failure-claude
round: 3
artifact: plan.md
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/plan.md
  - docs/qrspi/2026-05-30-v072-release/design.md
---

# F01 — Phase 1 acceptance criterion names a fail-loud surface no task is required to deliver ("dispatch-routing top-level fail-loud paragraph")

## What is wrong

The second Phase 1 acceptance criterion (plan.md `## Phase 1: v0.7.2 release` → `### Phase 1 Acceptance Criteria`, bullet 2) enumerates six fail-loud invariants that must each "produce non-zero exit with a diagnostic, never silent fallback" on seeded regression input. The fourth named surface is **"the dispatch-routing top-level fail-loud paragraph"**.

No v0.7.2 task is required to ship that paragraph or its seeded-regression test:

- T17 (`G23 validation table covers model_routing and cross-links fail-loud paragraphs`) **explicitly disclaims** authoring it in its **Out** scope: *"Adding the top-level dispatch-routing fail-loud invariant paragraph — dropped per design.md ## G25 (absorbed by CD-1; no separate v0.7.2 task ships under G25)."*
- design.md ## G25 confirms the disposition: *"G25 is locked at design time as moot / absorbed by CD-1; no separate v0.7.2 task ships under the G25 ID. The executable-enforcement piece rides with CD-1 (acceptance criterion appended in CD-1's section)."* Per the same block, "Authoring a new top-level invariant in the existing pre-CD-1 prose" and "A standalone bats pin walking H4s under `### Dispatch routing blocks`" are explicit **non-goals**.
- The closest surviving artifact is T16's `_resolve-lib.sh` `none`-tier halt smoke test (`Definition of done`: *"halts loudly when the selected tier is configured as `none`; it never silently falls back to a neighboring tier or agent-bundled model"*). Per design.md G25 this is what the "single sentence" of CD-1's post-rewrite rule is verified by. But the AC bullet still names a `paragraph`, not a `_resolve-lib.sh` halt.

This is exactly the round-03 "surgery silently dropped a load-bearing guard" hazard called out in the dispatch prompt: when T18 (the formerly-planned G25 paragraph carrier per the deleted-task-bodies note) was excised in round-02, the Phase 1 AC bullet that depended on it was not updated.

## Why this is a silent-failure class

At Test phase, the seeded-regression check for invariant #4 has two possible silent-failure outcomes, both of which weaken the release's whole purpose:

1. **Silent aliasing.** The Test agent treats T16's `_resolve-lib.sh` `none`-tier halt unit test as satisfying the named bullet. Phase 1 acceptance passes with less surface coverage than the AC text implies — the operator who reads `## Phase 1 Acceptance Criteria` later believes a top-level invariant paragraph was test-exercised when in fact only the unit-level resolver halt was.
2. **Loud-but-misdirected failure with no owner.** The Test agent grep-checks plan/design/SKILL prose for a paragraph that does not exist, fails the AC, and has no task spec to assign the fix to. The release stalls on a phantom requirement.

Either outcome is the SILENT_FALLBACK family this release is meant to close — at the planning layer rather than at runtime, but the consequence is the same: a fail-loud guarantee the operator believes is in place is in fact narrower than its description, or undeliverable.

## Where this is in the artifact

- plan.md `## Phase 1: v0.7.2 release` → `### Phase 1 Acceptance Criteria` → bullet 2 ("Every fail-loud invariant in the release fires loud on a seeded regression input ... the dispatch-routing top-level fail-loud paragraph ...")
- plan.md `### Task 17: G23 validation table covers model_routing and cross-links fail-loud paragraphs` → `**Scope** → **Out:**` (third bullet — explicit disclaimer)
- plan.md `### Slice 1.4 — Dispatch infrastructure` (T18 numbering preserved as a gap; the deleted body was the carrier)

## What a fix looks like

Replace the offending phrase in the AC bullet with a name that matches what tasks actually ship. Two reasonable shapes:

**Option A — remove the named surface.** The AC bullet already covers dispatch-routing fail-loud via "dispatch on misrouted `model_routing` entries" (T16) and "validation table on missing `model_routing:`" (T17). Strike "the dispatch-routing top-level fail-loud paragraph" entirely.

**Option B — re-point to the canonical executable enforcer.** Replace "the dispatch-routing top-level fail-loud paragraph" with the post-CD-1 wording, e.g., *"the `_resolve-lib.sh` halt on a `none`-resolved tier (CD-1's single-sentence dispatch-routing fail-loud rule, executable-enforced per design.md ## G25)"*. This keeps the AC explicit about which artifact the seeded-regression test exercises.

Either fix is single-paragraph, no ripple to task bodies. The choice depends on whether the AC bullet should retain a distinct fourth item or collapse it into the second/third.

## Confidence

high — the AC text and the T17 Out scope literally contradict; design.md G25 acceptance criteria confirm no separate paragraph artifact is authored under v0.7.2.
<!-- @@SCORE: silent-failure-claude.finding-F01.score @@ -->
score: 72
reason: Verified contradiction — plan.md AC bullet #2 names a "dispatch-routing top-level fail-loud paragraph" that T17 Out scope and design.md G25 both confirm is not delivered by any v0.7.2 task; real correctness defect with a concrete single-paragraph fix.
<!-- @@FINDING: silent-failure-claude.finding-F02 @@ -->
---
reviewer_tag: silent-failure-claude
round: 3
artifact: plan.md
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/plan.md
---

# F02 — T11 dispatch-manifest provenance has no fail-loud requirement when a resolved field is missing/unknown

## What is wrong

T11 (`G3 dispatch-manifest provenance fields ... in .dispatch-manifest.json`) requires the dispatch script to persist five provenance fields in every manifest entry — `dispatch_spec.subagent_type`, `dispatch_spec.host`, `dispatch_spec.vendor`, `dispatch_spec.model`, and `dispatch_spec.prompt_file` (DoD bullets 1–2). The DoD also requires append behavior to be "atomic and append-safe across multiple reviewer tags ... no entries are lost or malformed."

What the DoD and Test Expectations are **silent on**: what happens when one of those resolved fields cannot be determined at dispatch time. There is no requirement that the script halt loud if:

- `host` cannot be detected (`_host-detect.sh` returns `unknown`),
- `vendor` resolves to nothing (no matrix entry for this host),
- `model` resolves to `none` (the `extra-low: none` operator-only surface — or any other tier configured as `none`), or
- the resolver chain falls through to `default_tier: medium` without a `model_routing.medium:` value being present.

The Test Expectations only inspect that the keys **exist** in the JSON:
> *"Exercise a first-party reviewer dispatch and inspect `.dispatch-manifest.json` for a `dispatch_spec` object containing `subagent_type`, `host`, `vendor`, `model`, and `prompt_file`."*

A manifest entry like `{"dispatch_spec": {"host": "unknown", "vendor": null, "model": null, ...}}` would satisfy every assertion in T11's Test Expectations block, yet would silently record a dispatch that proceeded without resolved provenance.

## Why this is a silent-failure class

The round-03 dispatch prompt called this concern out by name:

> *"T11's dispatch-manifest provenance fields — if any are missing or malformed at dispatch time, does Test Expectations require fail-loud or does it allow log-and-continue?"*

The answer is: Test Expectations **allow log-and-continue by silence**. T11 specifies write semantics but not value-quality preconditions.

This matters because the dispatch-manifest is the audit trail that downstream calibration consumers (T09 `actual_model:` flow), the security exfil guard (T21), and Test-phase acceptance checks all rely on. A manifest that records `host: "unknown"` instead of halting on unknown host is the SILENT_FALLBACK class — readers cannot distinguish "dispatch happened with degraded provenance" from "dispatch happened with full provenance and the calibration data is real."

Worse, T11 sits **before** T20's rename and per-skill prose migration in the dependency graph. If T11 ships permissive write semantics, every later consumer (T20's `await-round.sh` drain, T09's `actual_model:` cross-check, T21's path-filter audit) inherits the same permissive provenance and may make decisions on `null`/`unknown` values without halting.

CD-1 explicitly forbids silent fallback at the `_resolve-lib.sh` layer ("halts loudly when the selected tier is configured as `none`; it never silently falls back to a neighboring tier or agent-bundled model" — T16 DoD). The dispatch-manifest writer is the consumer of that resolution; it should mirror the same fail-loud posture rather than persist whatever the resolver returned.

## Where this is in the artifact

- plan.md `### Task 11: G3 dispatch-manifest provenance fields (subagent_type / host / vendor / model / prompt_file in .dispatch-manifest.json)` →
  - `**Definition of done**` bullets 1–5 (specifies field presence and atomicity, not value-resolution preconditions)
  - `**Test expectations**` bullets 1–4 (only checks key presence, not value quality)

## What a fix looks like

Add one DoD bullet and one Test Expectations bullet:

**DoD addition:** *"If any of `host`, `vendor`, or `model` cannot be resolved at dispatch time (unknown host, no matrix entry, tier configured as `none`, or fallback default unconfigured), the dispatch script exits non-zero with a diagnostic naming the unresolved field and the resolution path that failed; no manifest entry is appended with `null`, `unknown`, or other placeholder values for these three fields. `subagent_type` and `prompt_file` are call-site inputs and must be validated before any resolution begins."*

**Test Expectations addition:** *"Exercise four halt fixtures — unknown host, vendor-not-in-matrix, tier resolved to `none`, and resolver fall-through to an unconfigured `default_tier:` — each exits non-zero with a diagnostic naming the unresolved field and produces no new manifest entry."*

The implementation cost is small (the resolver already has fail-loud semantics per T16; T11 needs to propagate them past the resolver boundary). The plan-level cost is zero ripple — no other task spec changes.

## Confidence

high — the round-03 dispatch prompt explicitly asked the question; the DoD and Test Expectations literally do not answer it.
<!-- @@SCORE: silent-failure-claude.finding-F02.score @@ -->
score: 50
reason: Real ambiguity — T11's DoD/Test Expectations only assert field presence and never specify behavior when host/vendor/model resolve to placeholder/unknown values, but the gap is partially covered upstream by T16's resolver fail-loud (CD-1) which T11 inherits transitively when it shells out; the residual "host: unknown" / vendor-not-in-matrix surface is a legitimate but secondary concern, and the fix is small and well-scoped.
<!-- @@FINDING: silent-failure-claude.finding-F03 @@ -->
---
reviewer_tag: silent-failure-claude
round: 3
artifact: plan.md
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/plan.md
---

# F03 — T12 `await-round.sh` zero-background-entries success path conflates "manifest empty by design" with "manifest missing or unreadable"

## What is wrong

T12 (`G4 canonical cumulative diff helper`) creates `scripts/await-round.sh` as the manifest-driven drain step. Its DoD includes:

> *"`scripts/await-round.sh` exists and performs the manifest-driven drain, split, status-update, `.round-complete.json` write, dispatch-prompt cleanup, and zero-background-entry success behavior."*

The Test Expectations exercise the success cases:

> *"Exercise `await-round.sh` against pending background entries and zero-entry manifests; verify awaited entries are split, manifest statuses update, `.round-complete.json` is written, round-scoped dispatch prompt files are removed after completion, and zero-entry rounds exit successfully."*

What is **not** specified anywhere in T12's DoD or Test Expectations: what happens when `.dispatch-manifest.json` is **missing entirely** in the round directory (e.g., dispatcher crashed before manifest creation, the directory was cleaned between dispatch and await, or a parallel orchestration step removed it).

T20's DoD echoes the same gap: *"`await-round.sh` resolves all pending background manifest entries ... and is safe to call when the round is first-party-only."* — but "safe to call when first-party-only" can be read two ways: (a) "the dispatcher wrote a manifest with zero background entries → drain succeeds" or (b) "no manifest exists because no background dispatch happened → also succeeds."

If reading (b) is the implementation, then a silently aborted dispatch round is indistinguishable from a legitimate first-party-only round. Both result in `await-round.sh` exiting 0 and writing `.round-complete.json` — but the first case represents a lost round whose findings were never collected.

## Why this is a silent-failure class

This is the textbook SILENT_FALLBACK shape:

- **Empty manifest content** (manifest exists, has `[]` or only resolved first-party entries) → legitimate success.
- **Missing manifest input** (manifest file does not exist) → error condition (dispatcher should always write the manifest, even with zero background entries, per T11's atomic-append contract).

Treating them identically means callers cannot distinguish "the round had no background work" from "the round's bookkeeping was lost." Downstream orchestration (Implement's per-task review loop → integrate → release-PR gate) will accept the empty `.round-complete.json` as a clean signal and advance to the next round, silently skipping the failed dispatch's findings.

The hazard is amplified by T11 sitting upstream of T20 in the dependency graph: T11 writes the manifest, T20's `await-round.sh` reads it, and the two contracts must agree on "manifest always present" as an invariant. If T11's write fails silently (see F02 — no fail-loud requirement on unresolved fields) AND T12's read silently treats a missing manifest as zero entries, the failure mode becomes invisible end-to-end.

design.md ## G7b / #204 (referenced in the round-03 dispatch prompt as the historical anti-pattern this release exists to close) is exactly this shape: an upstream silent miss + a downstream "absence-treated-as-success" reader.

## Where this is in the artifact

- plan.md `### Task 12: G4 canonical cumulative diff helper ...` →
  - `**Definition of done**` bullet *"`scripts/await-round.sh` exists and performs the manifest-driven drain, split, status-update, `.round-complete.json` write, dispatch-prompt cleanup, and zero-background-entry success behavior."*
  - `**Test expectations**` bullet *"Exercise `await-round.sh` against pending background entries and zero-entry manifests; ... zero-entry rounds exit successfully."*
- plan.md `### Task 20: G3 dispatch-script rename collapse ...` → `**Definition of done**` *"`await-round.sh` ... is safe to call when the round is first-party-only."*

## What a fix looks like

Add one DoD bullet and one Test Expectations bullet to T12 (and an aligned tweak to T20's wording):

**T12 DoD addition:** *"If `.dispatch-manifest.json` does not exist in the round directory passed to `await-round.sh`, the script exits non-zero with a diagnostic naming the missing manifest path; the script never treats a missing manifest as an empty-manifest success. Zero-background-entry success requires the manifest to exist with a parseable (possibly empty) entries array."*

**T12 Test Expectations addition:** *"Exercise a missing-manifest fixture (no `.dispatch-manifest.json` in the round directory) and verify `await-round.sh` exits non-zero with the missing-manifest diagnostic and does not write `.round-complete.json`."*

**T20 DoD wording tweak:** Replace *"is safe to call when the round is first-party-only"* with *"is safe to call when the manifest exists and contains zero background entries; missing manifest is a halt condition, not a success path."*

## Confidence

high — DoD and Test Expectations cover the empty-content path but are silent on the missing-input path; T20 reinforces the ambiguity. The G7b/#204 anti-pattern lineage explicitly motivates fail-loud on absence-as-input.
<!-- @@SCORE: silent-failure-claude.finding-F03.score @@ -->
score: 42
reason: Real but moderate silent-failure-class ambiguity in T12 DoD ("zero-background-entry success") + T20's "safe to call when the round is first-party-only" wording — design.md G4/CD-1 implies dispatch-agent.sh always writes the manifest so missing-manifest is unlikely in practice, and the finding asks for fail-loud-on-absence at implementation altitude which is plausibly an implementation detail the implementer would handle correctly given the script-owner contract.
<!-- @@FINDING: silent-failure-codex.finding-F01 @@ -->
---
reviewer_tag: silent-failure-codex
change_type: correctness
severity: high
artifact: plan.md
location: Task 40 — Scope + Definition of done + Test expectations; BW02 rule bullets
referenced_files: [plan.md]
---

# F01 — BW02 lint rule is specified as diagnostic-only, not guaranteed fail-closed

Task 40's BW02 language consistently requires diagnostics (`file:line`, triggering feature) but never explicitly requires a non-zero test failure when a violation is found (`plan.md` lines 2305, 2320, 2330).  
That creates a log-and-continue interpretation for version-guard regressions (`run --separate-stderr` without `bats_require_minimum_version`), which is exactly the silent-pass class this release is trying to eliminate.  
This conflicts with the locked design requirement that this condition fail CI loudly (design.md G26 acceptance: post-implementation violating file must fail CI), so the plan currently under-specifies fail-loud behavior for BW02.
<!-- @@SCORE: silent-failure-codex.finding-F01.score @@ -->
score: 50
reason: Real asymmetry — Task 40 DoD line 2319 says G21 rule "fails loudly" while BW02 lines 2305/2320/2330 only say "report" diagnostics, and design.md G26 acceptance (line 2154) explicitly requires the lint test to fail CI on BW02 violations; however, structuring BW02 as a separate `@test` block (mandated by line 2305) and the line 2321 requirement that the lint test runs on the blocking CI path make a log-and-pass implementation unlikely in practice, so the spec gap is moderate rather than load-bearing.
<!-- @@FINDING: silent-failure-codex.finding-F02 @@ -->
---
reviewer_tag: silent-failure-codex
change_type: correctness
severity: medium
artifact: plan.md
location: Task 11 — Definition of done + Test expectations for .dispatch-manifest.json provenance
referenced_files: [plan.md]
---

# F02 — Dispatch-manifest provenance lacks explicit fail-loud contract for missing/malformed required fields

Task 11 requires provenance fields to be present and says the manifest should remain well-formed (`plan.md` lines 707–717), but it does not specify fail-loud behavior when required `dispatch_spec` fields are missing/malformed at write/read time, nor does it require a negative test that seeds malformed/missing provenance and asserts halt.  
Given this manifest is the audit surface used to detect missed/mis-routed dispatches, permitting parse/shape drift without an explicit abort path can silently degrade detection (i.e., skip expected-tag integrity checks rather than fail fast).  
As written, the task is mostly positive-path validation and can pass while still allowing log-and-continue behavior on provenance corruption.
<!-- @@SCORE: silent-failure-codex.finding-F02.score @@ -->
score: 30
reason: Task 11 is a write-side schema/provenance task where the script controls manifest content; the requested fail-loud-on-malformed-read contract belongs to consumers (e.g., await-round.sh in T12) and the phase-1 fail-loud acceptance list does not enumerate dispatch-manifest parsing, making this a speculative planning nit rather than a clear gap.
<!-- @@FINDING: test-coverage-claude.finding-F01 @@ -->
---
reviewer: test-coverage-claude
round: 3
artifact: plan.md
task: T11
severity: high
change_type: correctness
---

# F01 — T11 dispatch-manifest provenance: no test expectations for missing-field fail-loud or malformed-field schema-strict paths

## What

T11 was fully rewritten in round-02/03 (formerly [G29], now [G3]) to land the
five `dispatch_spec` provenance fields (`subagent_type`, `host`, `vendor`,
`model`, `prompt_file`) on the pre-rename `scripts/run-codex-review.sh`. The
Test Expectations block (plan.md task 11, lines under "**Test expectations**")
contains four bullets:

1. First-party dispatch → inspect `.dispatch-manifest.json` for `dispatch_spec`
   object containing all five fields.
2. Third-party/background dispatch → inspect for `host`/`vendor`/`model` plus
   job metadata.
3. Repeated invocations against the same round dir → manifest remains
   well-formed JSON with all expected entries.
4. Acceptance coverage → orchestrator-facing payload remains a prompt-file
   reference.

What is **missing**:

- **(b) Fail-loud path when a field is missing.** No test expectation
  describes what the dispatcher does when one of `subagent_type`, `host`,
  `vendor`, `model`, or `prompt_file` cannot be resolved (no host signal,
  unresolved tier→vendor lookup, missing prompt-file path). The DoD says
  manifest writes must be "atomic and append-safe" with "no entries... lost
  or malformed", but a manifest entry that contains five empty-string fields
  is well-formed JSON and would satisfy bullets #1 and #3 vacuously.

- **(c) Schema-strict path when a field is malformed.** No test expectation
  describes the behavior when a passed value is the wrong shape — e.g., a
  non-string `subagent_type`, a `vendor` that is not in the resolver's
  vendor enum, a `prompt_file` that is not an absolute path, a `host` value
  the matrix does not recognize. The current expectations would pass even
  if every value were stringified and written verbatim with no validation.

## Why this matters

The round-03 dispatch prompt for this reviewer explicitly named these two
paths as required coverage: "verify Test Expectations cover (a) all 5
dispatch_spec provenance fields populated correctly, (b) the fail-loud path
when a field is missing, (c) the schema-strict path when a field is
malformed."

If the test author writes only the four listed expectations, the resulting
acceptance test will accept an implementation that silently writes empty or
junk values into `dispatch_spec` — defeating the auditability property the
task exists to deliver. The Phase 1 Acceptance Criterion #2 reference to
"dispatch on misrouted `model_routing` entries" assumes a fail-loud manifest
write, but no test pins that behavior at T11's level.

## Recommended fix

Add two test expectations to T11:

- **Missing-field fail-loud:** "Exercise a first-party dispatch with the
  `prompt_file` argument (or `subagent_type`, or any of the other four
  fields) deliberately omitted/empty; verify the dispatch script exits
  non-zero before writing a manifest entry, and verify stderr contains a
  diagnostic naming the missing field." (Or, if the locked design is that
  the script writes `unknown` / a sentinel value, pin that sentinel
  literally — the silent-empty-string outcome must be made impossible.)

- **Malformed-field schema-strict:** "Exercise a dispatch with a `vendor`
  value outside the resolver's vendor enum and a non-absolute `prompt_file`
  path; verify each case exits non-zero with a diagnostic naming the
  rejected field and value." If T11's design intentionally accepts opaque
  strings (no schema validation), add a positive expectation pinning that
  decision so the Test author does not invent rejection behavior the
  implementation does not provide.

Also tighten bullet #1 to assert each of the five fields is non-empty (not
just present as a JSON key), so an all-empty-strings implementation cannot
pass vacuously.
<!-- @@SCORE: test-coverage-claude.finding-F01.score @@ -->
score: 42
reason: Real but modest test-hygiene gap (bullets/DoD assert presence, not non-emptiness, so empty-string dispatch_spec values would pass); however, resolver fail-loud paths are explicitly scoped out of T11 to T19/T20 and "malformed schema-strict" coverage is not a documented design requirement at T11's layer.
<!-- @@FINDING: test-coverage-claude.finding-F02 @@ -->
---
reviewer: test-coverage-claude
round: 3
artifact: plan.md
task: T20
severity: medium
change_type: correctness
---

# F02 — T20 dispatch-script rename: no test expectation verifies T11's `dispatch_spec` provenance survives the rename

## What

T20 (G3 dispatch-script rename collapse) lists T11 in its dep chain (so the
new round-03 T11 framing is upstream). T20 hard-renames
`scripts/run-codex-review.sh` → `scripts/dispatch-agent.sh` and renames the
matching test file `tests/unit/test-run-codex-review.bats` →
`tests/unit/test-dispatch-agent.bats`. T11 added the
`dispatch_spec.{subagent_type, host, vendor, model, prompt_file}` provenance
write-side to the pre-rename script.

T20's Test Expectations bullet on dispatch-agent unit coverage says:

> Dispatch-agent unit coverage verifies renamed entry-point invocation,
> first-party spec-line parsing, `.dispatch-manifest.json` entries,
> `PROMPT_FILE=<absolute-path>` emission, and no dependency on
> `run-codex-review.sh`.

The phrase ".dispatch-manifest.json entries" is generic. It does not pin that
the T11 `dispatch_spec` object — with all five named provenance fields — is
still written by the renamed `dispatch-agent.sh`. The Test author for T20
could satisfy this expectation with an assertion that the manifest contains
at least one entry of any shape, even if the rename refactor accidentally
dropped the `dispatch_spec` writer (e.g., by editing the wrong helper
function during the rename diff).

No other T20 bullet covers provenance survival either. The third-party
companion/splitter bullets cover the new dispatch chain but not the
manifest-write shape inherited from T11.

## Why this matters

Round-02 surgery deliberately re-pointed T20's dep list to include T11
specifically so the rename would happen after the provenance edits land. The
correctness story is: T11 writes the provenance into the pre-rename script,
then T20 renames the script and the consumer skills, and the provenance must
still flow through to the manifest under the new script name. Without a
T20-level test expectation pinning the dispatch_spec object survives the
rename, the round-03 dispatch prompt's order-of-operations concern ("verify
Test Expectations exercise the order-of-operations correctly under the new
T11 framing") is not met.

The T11 acceptance tests originally written against
`scripts/run-codex-review.sh` would either need to be updated by T20 to
target the renamed script — in which case T20 owns the update and should
have a test expectation that those provenance assertions are retargeted and
still pass — or they would silently break/skip.

## Recommended fix

Add one explicit T20 test expectation:

> After rename, `tests/unit/test-dispatch-agent.bats` (renamed from
> `test-run-codex-review.bats`) contains all of T11's `dispatch_spec`
> provenance assertions retargeted to `scripts/dispatch-agent.sh`: the
> first-party manifest entry written by the renamed script carries a
> `dispatch_spec` object with non-empty `subagent_type`, `host`, `vendor`,
> `model`, and `prompt_file` fields, and the third-party manifest entry
> carries `host`/`vendor`/`model` plus job metadata.

Optionally pair with: "Acceptance suite from T11 runs green against the
renamed `dispatch-agent.sh` without any unmigrated references to
`run-codex-review.sh`."
<!-- @@SCORE: test-coverage-claude.finding-F02.score @@ -->
score: 42
reason: Real but marginal gap — T20's "manifest entries" phrasing is generic and doesn't explicitly pin dispatch_spec field survival, but the T11 dep, the unit test rename inheriting T11 assertions, and a competent Test author following the dep chain together provide reasonable coverage; the finding's fix is a small clarity improvement, not a load-bearing correctness issue.
<!-- @@FINDING: test-coverage-claude.finding-F03 @@ -->
---
reviewer: test-coverage-claude
round: 3
artifact: plan.md
task: T40
severity: high
change_type: correctness
---

# F03 — T40 body-assertion-guard lint: no negative-fixture RED test pinning the lint actually fails on a seed violation (G21 or BW02)

## What

T40 (G21 bats short-circuit hardening, with G26 BW02 absorbed) creates
`tests/lint/test-bats-body-assertion-guard.bats` carrying both:

- The G21 rule: every `[[ "$body" ... ]]` assertion must have an earlier
  `[ -n "$body" ]` guard in the same `@test` block.
- The G26 BW02 rule: detect `run --separate-stderr` (and future BW02
  patterns), reporting the triggering feature plus `file:line`.

T40's Test Expectations are six bullets that:

- Grep `test-using-qrspi-vocab.bats` for the retrofit guards (bullet 1).
- Run the new lint and confirm it accepts existing guarded R5-era pins as
  **positive controls** (bullet 2).
- Review the lint implementation for discovery, exclusion, and diagnostic
  shape (bullet 3).
- Review the BW02 surface for separate @test coverage and `file:line`
  diagnostic (bullet 4).
- Confirm CI wires the lint on the blocking path (bullet 5).
- Run a targeted BATS invocation of the touched files (bullet 6).

**Nothing in this list exercises the lint against a synthetic violation and
asserts the lint exits non-zero with the expected `file:line` diagnostic.**

Bullet 2 is positive-control only (the lint must not falsely flag valid
guarded prose). Bullets 3 and 4 are code-review of the lint source, not
behavioral exercise. The G21 lint could be implemented as `exit 0` (a
no-op) and bullets 2–4 would still pass: the source review confirms the
shape exists, the positive controls pass because nothing fires. The same
hole exists for BW02 — the lint could detect `run --separate-stderr` only
in dead code and bullet 4 would still pass on inspection.

## Why this matters

Phase 1 Acceptance Criterion #5 in plan.md states:

> `tests/lint/test-bats-body-assertion-guard.bats` catches body-less
> assertions on its seed regression

That phase-level criterion requires a seed regression fixture. But the
per-task T40 Test Expectations contain no such fixture. The round-03
dispatch prompt explicitly named the requirement: "verify Test Expectations
cover both G21 (the `$body` guard rule) AND G26 (BW02 minimum-version rule
with `run --separate-stderr` trigger)." Coverage of "the rule" means coverage
that the rule actually fires when violated, not just that the lint file
contains a paragraph mentioning the rule.

Without a RED-fixture expectation, the Test phase generator may write only
positive controls. A regression that silently breaks the lint's failure path
(e.g., a refactor that swaps `return 1` for `return 0` in the rule body)
would not be caught by any T40-level test.

## Recommended fix

Add two explicit T40 test expectations:

- **G21 seed regression:** "The lint test includes (or runs against) a
  fixture bats file containing an unguarded `[[ "$body" != *foo* ]]`
  assertion; the lint fails non-zero and stderr contains a `file:line`
  diagnostic naming the fixture path and the line of the unguarded
  assertion." (If the fixture is checked-in as a `.bats.fixture` to avoid
  contaminating real bats discovery, name the file pattern.)

- **G26/BW02 seed regression:** "The lint test includes (or runs against) a
  fixture bats file containing a `run --separate-stderr` invocation; the
  lint fails non-zero and stderr names both `run --separate-stderr` (the
  triggering feature) and the fixture's `file:line`."

Optionally pair with a "negative-cleanup" assertion that removing the
fixture violation makes the lint exit 0 again, to prove the diagnostic is
not stuck-on.
<!-- @@SCORE: test-coverage-claude.finding-F03.score @@ -->
finding_id: test-coverage-claude.F03
score: 28
change_type: correctness
verifier_note: |
  Haiku 0-turn empty-response flake (per PI-V073-001 / issue #293). Score
  captured from agent's brief-return chat output: "test-coverage-claude.F03: 28"
  (vfy-tc-claude-03, elapsed 135s, total_turns 0). Sidecar written manually
  by orchestrator since the verifier subagent did not Write to disk.
<!-- @@FINDING: test-coverage-claude.finding-F04 @@ -->
---
reviewer: test-coverage-claude
round: 3
artifact: plan.md
task: Phase 1 Acceptance Criteria
severity: high
change_type: correctness
---

# F04 — Phase 1 Acceptance Criteria reference deliverables of deleted tasks (T18, T22, T23) with no surviving owner

## What

Round-02 surgery deleted six task bodies (T18, T22, T23, T41, T42, T43)
because their goals were absorbed by CD-1, are moot, or auto-resolve via the
G3/CD-1 dispatch rewrite. The plan.md Overview explicitly preserves the
numbering gaps and notes the absorbed dispositions.

However, the **Phase 1 Acceptance Criteria block** (plan.md ## Phase 1
Acceptance Criteria) still names deliverables that were owned by those
deleted tasks. Three concrete orphaned references:

1. **Criterion #2** — "Every fail-loud invariant in the release fires loud
   on a seeded regression input — splitter on adversarial Codex stdout,
   dispatch on misrouted `model_routing` entries, validation table on
   missing `model_routing:`, **the dispatch-routing top-level fail-loud
   paragraph**, reviewer-protocol against fabricated procedural-authority
   outputs, and the path-filter exfil guard in `scripts/dispatch-agent.sh`
   each produce non-zero exit with a diagnostic, never silent fallback."

   The "dispatch-routing top-level fail-loud paragraph" was the deliverable
   of the deleted T18 (G25). Plan.md task 17 explicitly states under "Out":
   "Adding the top-level dispatch-routing fail-loud invariant paragraph —
   dropped per design.md ## G25 (absorbed by CD-1; no separate v0.7.2 task
   ships under G25)." No surviving task authors this paragraph, but the
   acceptance criterion still requires verifying it.

2. **Criterion #5** — "Full bats suite is green against deduplicated helpers
   and hardened anti-pattern pins — `tests/lint/test-bats-body-assertion-
   guard.bats` catches body-less assertions on its seed regression, **the
   parameterized dispatch-routing assertion callers exercise every routed
   path**, **the consolidated H4-extraction helper passes its tests**, and
   the bats-deprecation warnings on `test-codex-splitter.bats` are gone."

   - "Parameterized dispatch-routing assertion callers" was the G24-F03
     deliverable owned by deleted T23.
   - "Consolidated H4-extraction helper" was the G24-F02 deliverable owned
     by deleted T22.
   - "Bats-deprecation warnings on `test-codex-splitter.bats` are gone" —
     T20 renames `codex-finding-splitter.sh` but does NOT rename
     `tests/unit/test-codex-splitter.bats`, and no surviving task lists this
     test file in Target files. The deprecation-warning cleanup has no owner.

T44 (the renumbered survivor in the G24 chain) covers only G24-F05 regex
hardening; its Test Expectations do not produce the parameterized callers or
the H4 helper, and its scope explicitly says: "Consolidating repeated
`using-qrspi` per-H4 fail-loud prose, centralizing tier vocabulary regexes,
parameterizing dispatch-routing assertion callers, or promoting H4
extraction into shared bats helpers — all four of these G24-F01/F02/F03/F04
surfaces are moot in v0.7.2."

## Why this matters

Phase 1 Acceptance Criteria are exactly what the Test phase verifies before
the release PR opens. The Test author reading criteria #2 and #5 will try to
locate:

- A "dispatch-routing top-level fail-loud paragraph" that no task creates.
- "Parameterized dispatch-routing assertion callers" that no task creates.
- A "consolidated H4-extraction helper" file that no task creates.
- A `test-codex-splitter.bats` deprecation-warning cleanup that no task owns.

The verifier-side outcome is either (a) the Test phase fabricates assertions
against artifacts that do not exist (false-positive failures), (b) the Test
phase silently skips the criteria, leaving the release un-gated on what
plan.md says are load-bearing invariants, or (c) Implement-phase scope
creep when implementers discover the orphan and add un-planned work.

The round-03 dispatch prompt explicitly named this concern: "Across
surviving tasks: verify the deletion of T18/T22/T23/T41/T42/T43 didn't
orphan a test expectation that was their sole verifier of some behavior."
The orphan is at the phase-acceptance level, which is broader than any
single task.

## Recommended fix

Reconcile the Phase 1 Acceptance Criteria block against the surviving task
set. For each orphaned reference, do one of:

- **Delete the reference** if the deliverable is genuinely moot under CD-1
  (likely correct for "parameterized dispatch-routing assertion callers"
  and "consolidated H4-extraction helper" — design.md ## G24 says CD-1
  auto-resolves these surfaces).

- **Restate the reference in surviving-artifact terms** if the underlying
  invariant still holds but is now enforced by a different surface. Example
  for the "dispatch-routing top-level fail-loud paragraph": replace with
  "the CD-1 dispatch chain halts loudly when `model_routing:` resolves to
  `none` or to an unknown vendor (T16's resolver `none`-halt behavior)" or
  similar pointer to the surviving owner.

- **Add an owning task** if the deliverable is still required (only if it
  genuinely is — round-02 deletion was deliberate, so this should be rare).

For the `test-codex-splitter.bats` deprecation-warning cleanup, either add
it to T20's Target files (T20 already owns the rename of the script under
test, so renaming the matching test file is in-scope) or to T40 (which
already touches bats lint surface) — and update the Phase 1 criterion to
name the owner.
<!-- @@SCORE: test-coverage-claude.finding-F04.score @@ -->
score: 80
reason: Verified — Phase 1 Acceptance Criteria #2 names the "dispatch-routing top-level fail-loud paragraph" that T17's Out explicitly drops (no surviving owner), and #5 names the "parameterized dispatch-routing assertion callers" and "consolidated H4-extraction helper" that T44's Out explicitly declares moot; the phase-acceptance block will misdirect the Test phase against artifacts no task creates.
<!-- @@FINDING: test-coverage-codex.finding-F01 @@ -->
---
reviewer_tag: test-coverage-codex
change_type: correctness
severity: high
artifact: plan.md
location: Task 11 → Test expectations
referenced_files: [plan.md]
---

# F01 — Task 11 coverage only checks happy-path presence, not fail-loud/schema-strict behavior

Task 11's Test Expectations (bullets under "### Task 11") verify that `dispatch_spec` fields are present and that manifest JSON remains well-formed, but they do not require tests that fail when a required provenance field is missing, nor tests that reject malformed field values/types.  
Given this task is defining manifest schema contract (`dispatch_spec.subagent_type/host/vendor/model/prompt_file`), absence of negative-path expectations leaves a coverage hole where regressions can pass by emitting partial or malformed `dispatch_spec` objects without detection.
<!-- @@SCORE: test-coverage-codex.finding-F01.score @@ -->
score: 22
reason: Test bullet 1's "containing X/Y/Z/Q/R" presence check already fails on missing-field regressions, and value-type validation belongs to consumer/validator code that is not in this emit-side task's scope.
<!-- @@FINDING: test-coverage-codex.finding-F02 @@ -->
---
reviewer_tag: test-coverage-codex
change_type: correctness
severity: medium
artifact: plan.md
location: Task 20 → Test expectations
referenced_files: [plan.md]
---

# F02 — Task 20 does not explicitly verify Task-11 provenance contract survives the rename flow

Task 20 depends on Task 11, but Task 20 Test Expectations focus on rename/migration mechanics and generic manifest/spec-line behavior; they do not explicitly assert that the full Task-11 provenance contract remains intact after `run-codex-review.sh` → `dispatch-agent.sh` cutover.  
Specifically, there is no expectation that exercises post-rename dispatch and validates required `dispatch_spec` contract continuity (including failure behavior if provenance fields are absent/malformed), so dependency order is declared but not verifiably exercised by tests.
<!-- @@SCORE: test-coverage-codex.finding-F02.score @@ -->
score: 28
reason: Task 20's expectations already pin `.dispatch-manifest.json` entries and depend on Task 11 (whose own tests own the subagent_type/host/vendor/model/prompt_file provenance contract and survive the rename); asking Task 20 to re-assert Task 11's contract is a soft refinement/overspecification rather than a real coverage gap.
<!-- @@CLEAN: goal-traceability-claude.clean @@ -->
---
reviewer: goal-traceability-claude
round: 03
status: clean
artifact: plan.md
---

# Clean sentinel — goal-traceability reviewer (round-03)

No findings.

## Verification summary

Round-03 verifies the round-02 surgery (6 task-body deletions, T11 re-label,
G26 absorption into T40, T44 dep re-point) is complete and clean from a
goal-traceability standpoint. All required checks pass:

### 1. Bidirectional traceability — clean

**Forward trace (goal → task).** All 32 active approved goals are covered by
at least one task with plan-authored test expectations. The 3 fully-absorbed
goals (G25, G26, G29) and 4 moot G24 finding-IDs (G24-F01/F02/F03/F04) are
correctly absent from task Goal IDs lists per the design.md disposition
records.

| Active Goal | Covering Task(s)           |
|-------------|----------------------------|
| G1          | T28, T30                   |
| G2          | T33                        |
| G3          | T11 (re-labeled), T20, T27 |
| G4          | T12, T27                   |
| G5          | T34                        |
| G6          | T03, T24                   |
| G7          | T01                        |
| G8          | T04                        |
| G9          | T13                        |
| G10         | T35                        |
| G11         | T06, T24                   |
| G12         | T02, T24                   |
| G13         | T05                        |
| G14         | T07                        |
| G15         | T14                        |
| G16         | T21                        |
| G17         | T36                        |
| G18         | T15                        |
| G19         | T08                        |
| G20         | T09                        |
| G21         | T40                        |
| G22         | T16, T27                   |
| G23         | T17                        |
| G24 (F05)   | T44                        |
| G27         | T19, T27                   |
| G28         | T10                        |
| G30         | T28, T32                   |
| G31         | T25, T26                   |
| G32         | T39                        |
| G33         | T28, T31                   |
| G34         | T29                        |
| G35         | T37, T38                   |

**Backward trace (task → goal/CD).** All 38 tasks carry Goal IDs that trace
to an active approved goal (29 tasks) or to a design.md Cross-Goal Decision
naming sponsoring goal IDs (T24=CD-4 [G6,G11,G12]; T27=CD-2 [G3,G4,G22,G27];
T28=CD-3 [G1,G30,G33]). No untraceable tasks; no scope creep.

### 2. Absorbed-goal compliance — clean (no regressions)

- **G29** — verified NO task carries `[G29]` in Goal IDs. T11 carries `[G3]`
  per the round-02 re-label (plan.md L679); T11 Overview at L689 correctly
  cites `design.md ## G29 (absorbed by CD-1, no separate task ships)`.
  Design anchor confirmed at design.md L2308.
- **G25** — verified NO task carries `[G25]` in Goal IDs. Dep-graph narrative
  at plan.md L108 correctly cites `design.md ## G25 absorbing those goals
  into CD-1 with no separate v0.7.2 task`. Design anchor confirmed at
  design.md L2084.
- **G26** — verified ONLY T40 carries G26, as part of `[G21, G26]` (plan.md
  L2288). T40 References correctly cite `design.md ## G26` (L2123) and the
  G21 Amendment block (`Amendment at G26 design-lock` confirmed at design.md
  L1929 — riding in the G21 lint file as specified by design).
- **G24-F01/F02/F03/F04** — verified NO task carries any G24-FNN ID in Goal
  IDs. T44 Goal IDs is `[G24]` (plan.md L2350); T44 Out bullet at L2370
  enumerates all four moot F-IDs and cites `design.md ## G24`. Design anchor
  confirmed at design.md L2045. T44 heading mentions "G24-F05"
  descriptively, which is the only active F-finding and correctly traces to
  the design.md "post-audit re-scope to F05 only" disposition.

### 3. Citation correctness for absorbed-goal references — clean

All intentional narrative references to absorbed goal IDs and deleted task
numbers cite real design.md anchors:

| Citation site                               | Anchor cited                          | Verified |
|---------------------------------------------|---------------------------------------|----------|
| Phase 1 Overview L17                        | `## G24/G25/G26/G29`                  | ✓        |
| Dep Graph L108 (T22/T18 deletion narrative) | `## G24 and ## G25`                   | ✓        |
| T11 Overview L689 (G29 absorption)          | `## G29`                              | ✓        |
| T40 Out L2309 + References L2338-2339       | `## G26` + `## G21 Amendment`         | ✓        |
| T44 Out L2370 (G24-F01..F04 moot)           | `## G24`                              | ✓        |

### 4. Task-count consistency — clean

- Phase 1 Overview L17 states 38 tasks (1–44 with gaps at 18/22/23/41/42/43).
- Slice listings produce exactly 38 task entries with the correct gap
  pattern.
- Dep-graph narrative explicitly references deleted T22/T18 chain.
- Phase 1 Acceptance Criteria (L26–33) trace cleanly to goals: G3/G6/G9
  (end-to-end pipeline), G3/G10/G16/G22 (fail-loud), G19/G28 (verifier +
  apply-fix), G32 (build), G21/G24 (bats), and release/issue surface.

### 5. Plan-authored test expectations — clean

Every task spec carries a `**Test expectations**` block with concrete
grep/fixture/acceptance assertions tying back to goals.md problem framing
through design.md decisions. Spot-checked T01-T17, T19-T21, T24-T40, T44.

## Conclusion

Round-02 surgery is correctly applied with no traceability regressions and no
new orphaned goals or untraceable tasks. The plan is ready to ship from a
goal-traceability standpoint.
<!-- @@CLEAN: scope-claude.clean @@ -->
---
reviewer_tag: scope-claude
artifact: plan.md
round: 3
ref: main (broaden)
---

# Scope review — clean

Plan.md passes the 3-check scope procedure against `skills/plan/owns-defers.md`.

## Plan OWNS coverage
- **Ordered task specs:** T01–T44 with documented gaps at T18/T22/T23/T41/T42/T43, all gaps explained as moot/absorbed (Overview line 17; Cross-slice notes line 102).
- **Test expectations:** every task carries a `**Test expectations**` block in plain language; no `expect(...)` / `assert.` / `assertEqual` / `toBe(` code.
- **Dependencies:** each task block carries explicit `Dependencies:` and `Blocks:` declarations; no forward dependencies (all `Dependencies:` reference earlier-numbered tasks).
- **LOC estimates:** every task has `~N` LOC; oversized tasks (T12 ~280, T16 ~320, T19 ~210, T20 ~260, T25 ~340, T39 ~360) all carry explicit `sizing_exception:` markers (`reusable primitives`, `schema-migration`, `CI scaffolding`).

## Plan DEFERS — respected
- No function signatures with typed parameter lists or return-type arrows authored in task specs.
- No line-by-line algorithm pseudocode, control-flow walkthroughs, or `if/else/for/while` constructs.
- No design-altitude trade-off prose in task descriptions; "Why: see design.md ## GNN" pointer pattern keeps rationale in design.md.
- No phasing/roadmap re-authoring; `v0.7.3+` references appear only in `Out:` bullets as deferral markers, which is correct DEFERS bookkeeping.
- Structure-altitude file-responsibility detail is consistently pointed to via `structure.md ###` references rather than re-authored in plan.

## Borderline items conservatively cleared (per user F-5 guidance)
- T11 lines 694–696 name JSON manifest field shape (`dispatch_spec.subagent_type/host/vendor/model/prompt_file`). The schema is already locked in `design.md ## CD-1 → "Dispatch manifest schema"` and authored canonically in `structure.md ### 10. Dispatch manifest schema`; plan is consuming the locked schema to scope the task, not re-authoring it.
- T21 line 1251 + T39 line 2252 mirror reference the helper `assert_path_under_repo_root <label> <abs-path>`. The helper name is an established CD-1 vocabulary anchor (already pinned in `structure.md ### scripts/run-codex-review.sh` G16 responsibility), and the `<label> <abs-path>` placeholder syntax is usage-shape rather than a typed function signature.
- T39 line 2252 references `fs.realpathSync` but explicitly hedges with `(or equivalent)`, preserving Implement-altitude negotiation room as the INVEST Negotiable framing requires.
- T40 / T44 cite literal bash test patterns (`[ -n "$body" ]`, `[[ "$body" != *...* ]]`, `^@test "..." \{`, `run --separate-stderr`). These are the central subject of the lint/regex-hardening contract — naming the patterns is unavoidable to make the contract testable, not gratuitous Implement-TDD code leakage.
- T12 / T13 pin exit codes 10/11/12 in DoD and Test Expectations — observable contract values appropriate for plan ownership.
- Exact diagnostic strings in T32 (line 1817), T34 (lines 1949–1950), T36 (line 2055) — user-visible observable behavior, plan-owned.

Each borderline item is anchored to already-locked design.md / structure.md content rather than pre-empting downstream skill choice, so none rise to a Structure-layer or Implement-layer DEFERS violation under the user-supplied conservative F-5 reading.

## Round-03 specific verification — post-moot-goals surgery cross-references clean

The round-03 broaden focus was verifying that round-02's moot-goals surgery left no stale cross-references. Verified clean:

- **T11 [G29]→[G3] re-label:** header line 679 and body line 689 both carry `[G3]`; Overview at line 689 explicitly explains "G29 — the formerly-planned large-artifact escape-hatch goal — is moot per design.md ## G29 (absorbed by CD-1, no separate task ships)". `Out:` bullets at 702–703 also acknowledge the G29 absorption. References block (line 724) names "design.md ## G29 — locked disposition that G29 is moot/absorbed by CD-1".
- **T40 absorbs G26:** header line 2288 `[G21, G26]`; body line 2297 "incl. G26 BW02/minimum-version rule"; `Out:` line 2309 explains the G26 absorption; References line 2337 carries "goals.md ### G26 — problem framing for the BW02/minimum-version regression class (absorbed into this task's lint surface)".
- **T44 dep re-pointing:** header line 2354 `Dependencies: [Task 17, Task 40]` matches round-02 brief; `Out:` line 2370 documents F01/F02/F03/F04 as moot with disposition rationale.
- **Dropped task slots:** Slice 1.4 listing (lines 67–74) shows T18/T22/T23 gaps; Slice 1.7 listing (lines 96–100) shows T41/T42/T43 gaps; Slice 1.3 note (line 60) explains T12 placement under Slice 1.4. Overview line 17 enumerates all six gaps with rationale.
- **No live dependency edges** in any remaining task point at dropped T18/T22/T23/T41/T42/T43. Cross-slice notes line 102 explicitly documents that "G24-F02 prose consolidation and G25 top-level invariant — originally planned as T22 / T18 in this chain — were dropped per design.md ## G24 and ## G25 absorbing those goals into CD-1 with no separate v0.7.2 task".
- **T17 (G23) Out: bullet** at line 1068 explicitly explains the dropped top-level dispatch-routing invariant: "dropped per design.md ## G25 (absorbed by CD-1; no separate v0.7.2 task ships under G25)".

No stale cross-references to deleted tasks or absorbed goals remain in any live dependency edge, body bullet, or References block.

## Result

No scope findings. Plan.md scope and OWNS/DEFERS boundary are clean for round-03 broaden review.
<!-- @@CLEAN: spec-claude.clean @@ -->
---
reviewer: spec-claude
round: 3
findings: 0
verdict: clean
---

# Spec Review Round 03 — Clean

No findings. The plan correctly reflects the round-02 surgery and continues to cover every goal with verifiable per-task Test Expectations.

## Verification highlights

### Goal coverage (35 goals → 38 tasks)

All 35 approved goals (G1–G35) trace to at least one task, with absorbed goals correctly attributed:

| Absorbed goal | Disposition | Task(s) covering residual work |
|---|---|---|
| G24-F01/F02/F03/F04 | Absorbed into CD-1 per design.md ## G24 | T44 covers only G24-F05; absorption documented in T44 Out-of-scope |
| G25 | Absorbed into CD-1 per design.md ## G25 | T17 Out-of-scope explicitly cites the absorption |
| G26 standalone | Folded into T40's lint surface per design.md ## G26 | T40 `Goal IDs: [G21, G26]` with dedicated BW02 Test Expectations |
| G29 | Absorbed into CD-1 per design.md ## G29 | T11 carries the CD-1 dispatch-manifest schema fields that obviate G29's escape-hatch framing |

### Round-03 spec-reviewer focus checks

1. **T11 re-label [G29]→[G3].** Goal IDs frontmatter reads `[G3]`. Test Expectations exercise first-party `dispatch_spec.{subagent_type, host, vendor, model, prompt_file}`, third-party provenance + job metadata, atomic append behavior, and orchestrator-facing payload remaining a prompt-file reference. No `artifact_path` / large-artifact-threshold / reviewer-side parser obligations from the prior G29 framing leak into Test Expectations. Overview's mention of G29 is correctly framed as historical absorption context.

2. **T40 absorbing G26.** Goal IDs reads `[G21, G26]`. Test Expectations include both the G21 `[ -n "$body" ]` guard retrofit + body-assertion-guard lint coverage AND a structurally separate G26 BW02 rule surface (initial trigger `run --separate-stderr`, diagnostics naming both triggering feature and `file:line`). Title flags the G26 inclusion explicitly.

3. **T44 re-deps [Task 17, Task 40].** Test Expectations align with both new dependencies: the `[ -n "$body" ]` guard requirement inherits T40's G21 pattern (explicit grep assertion: "each rewritten pin has `[ -n \"$body\" ]` earlier in the same `@test` block"); the regex-pin acceptance asserts the unit test stays green "against the post-dispatch-routing prose produced by the earlier schema, validation, and fail-loud-invariant edits" (which is T16 + T17's surface). No Test Expectation references behavior that the deleted T43 (G24-F03 H4-extraction helper) would have provided — T44 Out-of-scope explicitly disclaims that helper.

4. **Phase 1 acceptance criteria reflect 38-task plan.** Overview states "38 tasks (task numbers 1–44 with gaps at 18, 22, 23, 41, 42, 43)". Per-slice tallies (1.1=7, 1.2=4, 1.3=3, 1.4=7, 1.5=12, 1.6=2, 1.7=3) sum to 38. Each acceptance criterion maps to landed tasks: end-to-end review (T03/T04/T05/T13/T16/T19/T20), fail-loud invariants (T20 splitter, T16 model_routing dispatch halt, T17 validation table, T35 reviewer-protocol, T21 path-filter exfil), apply-fix instrumentation (T10 sub-threshold observations + T08 wholesale-hallucination calibration), build pipeline (T39), BATS hardening (T40 body-assertion lint + parameterized dispatch-routing assertions in T16/T17), goal-issue closure, release PR.

### Absorbed-goal-ID hygiene check

Slice-listing scan confirms NO task carries an inappropriate absorbed ID:
- G24-F01/F02/F03/F04: not on any task (T44 carries parent `[G24]` for F05 work only)
- G25: not on any task (would appear nowhere in the plan; confirmed absent from all task headers)
- G26 on non-T40 task: confirmed absent — only T40 carries G26
- G29 on non-T11 task: confirmed absent — T11 itself no longer carries G29 (was the re-label target, now `[G3]`)

### Cross-cutting CD coverage

- **CD-1 (universal dispatch architecture):** T11 (manifest provenance schema) + T20 (rename collapse + per-skill prose migration) + supporting T19 (host-detect / second-reviewer probe)
- **CD-2 (Evergreen-Output Rule):** T27 with the nine artifact-producing consumers + reviewer-protocol enforcement clause + using-qrspi pointer
- **CD-3 (Multi-Actor Flow Check):** T28 with the four downstream-consumer SKILL include sites
- **CD-4 (Verifier-Fan-In Pipeline):** distributed across T01 (filter-rule snippet), T02 (fan-in script), T05 (enum hardening), T06 (sidecar lock), T07 (Informational rubric), T24 (detect-interaction-mode helper)

### Task sizing

All tasks >200 LOC carry an explicit `sizing_exception:` from the closed set (`reusable primitives` / `schema-migration` / `CI scaffolding`):
- T12 (~280, reusable primitives), T16 (~320, schema-migration), T19 (~210, reusable primitives), T20 (~260, reusable primitives), T25 (~340, reusable primitives), T39 (~360, CI scaffolding)

Task titles that use `+` joining (T12, T19, T20, T25, T39) all bundle reusable primitives or CI scaffolding that meet the closed-set exception criteria; the exceptions are stated in-plan and the bundling is load-bearing for the primitive/scaffolding shape.

### Test Expectations specificity

Per-task Test Expectations across the sampled tasks (T01, T02, T06, T07, T08, T09, T10, T11, T12, T15, T16, T17, T19, T20, T27, T28, T29, T30, T31, T32, T37, T38, T39, T40, T44) are specific behaviors (greppable anchors, fixture-backed unit/acceptance coverage, RED checks, file-existence checks, audit diagnostics with named exit codes). No vague "works correctly" / "appropriate handling" / "as needed" placeholders observed. No "see Task N" cross-references in lieu of repeated detail.

## Verdict

Round-03 surgery integrated cleanly. No spec-level findings.
<!-- @@CLEAN: spec-codex.clean @@ -->
---
reviewer_tag: spec-codex
artifact: plan.md
round: 3
---

All seven requested round-03 spec checks pass: non-absorbed goal coverage is complete, absorbed goals are absent from Goal IDs, G26 appears only on T40, T11/T40/T44 Test Expectations align with the rewritten behavior/dependencies, Phase 1 narrative reflects 38 tasks with the specified gaps, and every task retains the full 5-section spec structure.
