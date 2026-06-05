---
verifier_enabled: true
scored: 11
kept: 3
dropped: 8
failed: 0
clean: 6
---

<!-- @@FINDING: goal-traceability-codex.finding-F01 @@ -->
---
finding_id: R6-F01
severity: high
change_type: correctness
referenced_files: [docs/qrspi/2026-05-30-v072-release/plan.md]
---

Forward goal→task traceability is not 100% complete: goals G25 and G29 have no Task-spec Goal ID mapping in this artifact.

Evidence:
- The plan claims "**35 approved goals decomposed ... into 38 tasks**" (plan.md:11), which implies full forward goal coverage.
- The same line also states "**G25 ... absorbed by CD-1**" and "**G29 ... ships no standalone task**" (plan.md:11).
- Across all 38 Task Specs (`### Task XX` blocks), Goal ID lines map tasks to goals, but no Task-spec `Goal IDs` entry includes G25 or G29; e.g. T11 is explicitly relabeled to G3 (`Goal IDs: [G3]`, plan.md:679) and T40 maps `[G21, G26]` (plan.md:2289), leaving G25/G29 without any task row.

This breaks the stated "35-goal forward" completeness condition unless the matrix explicitly represents absorbed goals with a non-task disposition row.
<!-- @@SCORE: goal-traceability-codex.finding-F01.score @@ -->
score: 20
reason: G25 and G29 absorbed-by-CD-1 dispositions are explicitly documented in the Plan Overview, in T11's spec prose, and in T11's References (design.md ## G29); the SKILL.md template does not mandate matrix-form traceability for absorbed goals, so this is a stylistic preference rather than a correctness gap.
<!-- @@FINDING: quality-claude.finding-F01 @@ -->
---
reviewer: claude
role: plan-quality-reviewer
round: 6
artifact: plan.md
severity: medium
change_type: correctness
finding_id: F01
---

# Finding F01 — T19 missing `Dependencies: Task 16` after round-05 halt-move

## Location

- `plan.md` task list, **L65** — `Task 19 — G27 ... — deps: none`
- `plan.md` per-task spec, **L1103** — `**Dependencies:** none. **Blocks:** Task 20.`
- (symmetric) `plan.md` per-task spec, **L974** — `Task 16 ... **Blocks:** T17 (...)` (does not list T19)

## What's wrong

T19 declares `Dependencies: none`, but T19 cannot start independently of T16:

1. **File-creation ordering.** T16's target files include `create/modify scripts/_resolve-lib.sh` (L973) and T16's In-scope language is "Create/update `scripts/_resolve-lib.sh`" (L986). T19's target files include `scripts/_resolve-lib.sh` (L1102) and T19's In-scope language is "**Extend** `scripts/_resolve-lib.sh` with the host × vendor matrix and default-second-reviewer lookup helpers" (L1116). T19 cannot extend a file that T16 hasn't created yet. If an implementer picks up T19 before T16 lands, T19 either stubs `_resolve-lib.sh` (conflicting with T16's later creation) or fails entirely.

2. **Same-file-edit merge-conflict trap on the test surface.** Both T16 and T19 modify `tests/unit/test-routing-matrix-application.bats` (T16 L973; T19 L1102). T16's test coverage pins "per-tag tier overrides, `none`-tier halt behavior, and implementer/test-writer co-escalation" (L991). T19's test coverage at L1147–L1148 pins same-tier primary + second-reviewer dispatch coverage and the new `[second-reviewer-same-vendor]` halt — both in the same .bats file. Without an explicit edge, these can be queued for concurrent execution and produce conflicts on a shared test file.

3. **The round-05 halt-move deepens, not severs, the dependency.** Round-05 moved the `[second-reviewer-same-vendor]` halt from T16 to T19 with the rationale "T19 owns the host x vendor matrix lookup helpers". T19's new DoD bullet at **L1136** locates that halt inside "`_resolve-lib.sh`'s host × vendor matrix lookup" — i.e., the matrix-lookup helpers T19 adds to the file T16 creates. The halt now lives in T19's territory but on T16's structural foundation. Moving the halt without adding the dep edge is precisely the kind of cross-task-contract slip that the round-05 surgical edit was supposed to clean up.

4. **The implicit ordering via T20 is not load-bearing.** T20 deps on T19 but **not** on T16, so there is no transitive path forcing T16 → T19. T17 deps on T16 but T17 doesn't block anything T19 needs. The dep graph as currently written truly permits T19 to land before T16.

## Fix

Three coordinated edits:

- **L65** (task list): change `deps: none` → `deps: [Task 16]` for Task 19.
- **L1103** (T19 per-task spec): change `**Dependencies:** none. **Blocks:** Task 20.` → `**Dependencies:** Task 16. **Blocks:** Task 20.`
- **L974** (T16 per-task spec): change `**Blocks:** T17 (...)` → `**Blocks:** T17 (...); T19 (extends \`_resolve-lib.sh\` with the host × vendor matrix and default-second-reviewer lookup helpers and the matrix-lookup-time \`[second-reviewer-same-vendor]\` halt).`

Optional but consistent: add a one-sentence note to the Dependency Graph section (after L106, dep-graph item 4) calling out "T16 (G22 `_resolve-lib.sh` creation) → T19 (G27 host × vendor matrix extension + `[second-reviewer-same-vendor]` halt at matrix-lookup time)" so the file-edit ordering is documented at the same elevation as the T09/T11/T13 → T20 chain.

## Why medium, not high

T19's `Blocks: Task 20` (L1103) and T20's `deps: [..., Task 19]` (L66) mean that in the natural numeric implementation order T16 still lands before T20, and an implementer using numeric order will not hit the bug. But the deps field is the **authoritative ordering signal** for parallel/non-numeric implementer scheduling (see `tools/build-plugin.mjs`-style dep-graph consumers and the parallelize skill). A missing edge here is a load-bearing semantic gap, not a presentational nit.
<!-- @@SCORE: quality-claude.finding-F01.score @@ -->
score: 78
reason: Verified — T16 creates scripts/_resolve-lib.sh (L973/L986) and T19 extends it (L1102/L1116); both modify tests/unit/test-routing-matrix-application.bats; T19 declares deps: none (L65, L1103) and no transitive path forces T16→T19, so the missing dep edge is a real correctness gap on the authoritative ordering signal.
<!-- @@FINDING: quality-claude.finding-F02 @@ -->
---
reviewer: claude
role: plan-quality-reviewer
round: 6
artifact: plan.md
severity: low
change_type: clarity
finding_id: F02
---

# Finding F02 — Dependency Graph narrative misattributes T39 → T21 rationale

## Location

`plan.md` Dependency Graph section, **L110** (narrative summary paragraph after dep-graph items 1–4):

> "Slice 1.7 is otherwise independent of Slices 1.1–1.6 except that T39 depends on T25 for the defensive-copy site and on T21 for the renamed `scripts/dispatch-agent.sh` path under the `build/` allow-list and `!cat` resolver inspection."

## What's wrong

The narrative claims T39 depends on T21 "for the renamed `scripts/dispatch-agent.sh` path under the `build/` allow-list and `!cat` resolver inspection." But the rename of `run-codex-review.sh` → `dispatch-agent.sh` is **owned by T20** (see L66 task list and L1164 per-task spec header). T21 (G16 path-filter exfil hardening) only modifies the already-renamed file; it does not own the rename itself.

T39's actual round-05 motivation for the new T21 edge is documented in T39's own DoD and test expectation:

- **L2253** (T39 DoD): "The guard mirrors T21's `assert_path_under_repo_root <label> <abs-path>` shape from `scripts/dispatch-agent.sh` (see Task 21 Definition of done — both guards canonicalize with `realpath` / `readlink -f` and reject canonical targets outside canonical `$REPO_ROOT/`)."
- **L2268** (T39 test): "Mirrors T21's symlink-out-of-repo regression in `tests/unit/test-dispatch-agent.bats` so the two canonicalization surfaces use the same audit-friendly diagnostic phrase."

So the T39 → T21 edge exists so T39's symlink-escape guard can **mirror** T21's `assert_path_under_repo_root` shape and `resolves outside repository` diagnostic phrase across the two canonicalization surfaces. The narrative at L110 was not updated when round-05 added T21 to T39's deps and instead pattern-matches to the older "renamed dispatch path" rationale that would imply a T20 dep (which T21 already transitively brings).

This is a low-severity narrative-quality defect, not a deps-field defect: the deps field itself (`[Task 21, Task 25]` at L92 task list and L2210 per-task spec) is correct. The rationale prose just no longer matches.

## Fix

Replace the trailing clause of L110 so the rationale matches T39's own DoD/test:

> "...except that T39 depends on T25 for the defensive-copy site (`build/skills/_shared/prompt-prose-detection.md`) and on T21 so T39's `tools/build-plugin.mjs` symlink-escape guard can mirror T21's `assert_path_under_repo_root` shape and `resolves outside repository` diagnostic phrase across the two canonicalization surfaces (T39's `!cat`-target resolver and T21's `scripts/dispatch-agent.sh` path-filter). T21 transitively brings the T20 rename, so no separate T20 edge is needed."
<!-- @@SCORE: quality-claude.finding-F02.score @@ -->
score: 60
reason: Verified narrative defect — L110 attributes T39→T21 edge to the dispatch-agent rename (which T20 owns) while T39's own DoD/test (L2253, L2268) document the real reason as mirroring T21's `assert_path_under_repo_root` shape and `resolves outside repository` diagnostic; deps field itself is correct, so this is a low-severity clarity fix.
<!-- @@FINDING: quality-claude.finding-F03 @@ -->
---
reviewer: claude
role: plan-quality-reviewer
round: 6
artifact: plan.md
severity: low
change_type: clarity
finding_id: F03
---

# Finding F03 — T16/T19 carve-out symmetry incomplete after round-05 halt-move

## Location

- `plan.md` T16 In-scope, **L986** — claims "host/vendor routing lookup" as T16's responsibility.
- `plan.md` T16 Out-of-scope, **L993–L996** — does not carve out the host × vendor matrix helpers and `[second-reviewer-same-vendor]` halt as T19-owned.
- `plan.md` T19 Out-of-scope, **L1121–L1124** — does not acknowledge that T16 creates `_resolve-lib.sh`'s tier-resolution foundation that T19 extends.

## What's wrong

Round-05 split `_resolve-lib.sh` responsibility across T16 and T19 — T16 owns "tier-to-(vendor, model) lookup" and primary-slot tier resolution; T19 owns "host × vendor matrix and default-second-reviewer lookup helpers" plus the matrix-lookup-time `[second-reviewer-same-vendor]` halt. The DoD bullets (T16 L1001–L1008; T19 L1126–L1136) now reflect that split correctly.

But the **In/Out carve-outs are stale**:

1. **T16 L986 In-scope still lists "host/vendor routing lookup"** as part of T16. After the round-05 move, "host × vendor matrix lookup" is T19's. The phrasing collision ("host/vendor routing lookup" vs "host × vendor matrix... lookup helpers") is the exact kind of ambiguity that round-05's move was meant to clean up. An implementer reading T16 in isolation would reasonably conclude they should implement the full host/vendor matrix lookup in T16, only to discover at L1116 that T19 also claims it.

2. **T16 Out (L993–L996) doesn't carve out the T19-owned surface.** The three current Out bullets defer to T17 (G23 row), T27 (Evergreen-Output snippet), and design.md ## G22 future work. There is no "host × vendor matrix lookup helpers and `[second-reviewer-same-vendor]` matrix-lookup-time halt — T19 owns" bullet. Compare to T19's Out at L1121 which **does** carve out T20's surface ("Dispatch script renames... Task 20 owns that rename-and-dispatch surface"). The carve-out symmetry is one-directional.

3. **T19 Out (L1121–L1124) doesn't acknowledge T16's upstream surface.** T19 carves out three downstream surfaces (T20 renames, T27 snippet, v0.7.3+ futures) but doesn't acknowledge that T16 owns `_resolve-lib.sh`'s primary-slot tier resolution and the `tier: none` halt. An implementer reading T19's "Extend `scripts/_resolve-lib.sh`" (L1116) needs a one-line pointer to where the file's foundation comes from.

This is low-severity because the DoD bullets disambiguate on careful reading. It's worth flagging because the round-05 surgical edit explicitly aimed at cross-task contract clarity, and the carve-outs are the highest-leverage surface for that clarity.

## Fix

Three small edits:

- **L986** (T16 In): change "tier-to-`(vendor, model)` lookup, host/vendor routing lookup, and halt-on-`none` behavior" → "tier-to-`(vendor, model)` lookup, **primary-slot** host/vendor routing lookup (the host × vendor matrix helpers consumed by T19's second-reviewer probe are deferred to T19), and halt-on-`none` behavior".
- **L996** (T16 Out): add a new bullet — "Host × vendor matrix lookup helpers, default-second-reviewer lookup, and the matrix-lookup-time `[second-reviewer-same-vendor]` halt — T19 owns the second-reviewer-facing extension of `_resolve-lib.sh`."
- **L1124** (T19 Out): add a new bullet — "Creation of `scripts/_resolve-lib.sh`, primary-slot tier resolution, and the `tier: none` halt — T16 owns the schema-migration foundation this task extends."

These three edits make the file-edit ordering plus the round-05 halt-move boundary self-documenting from either task spec alone, eliminating the need to cross-read both specs to understand who owns which slice of `_resolve-lib.sh`.
<!-- @@SCORE: quality-claude.finding-F03.score @@ -->
score: 45
reason: Real but minor clarity gap — T16 In line says "host/vendor routing lookup" which collides with T19's "host × vendor matrix... lookup helpers" surface, and neither task's Out carves out the other's slice of _resolve-lib.sh; DoD bullets disambiguate on careful reading, so it's a legitimate low-severity clarity nit rather than a load-bearing defect.
<!-- @@FINDING: quality-codex.finding-F01 @@ -->
---
finding_id: R6-F01
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-30-v072-release/plan.md]
---

Task 19 still declares no dependency even though it is now explicitly layered on top of Task 16's `_resolve-lib.sh` surface, creating a dep-graph inconsistency that allows unsafe parallel execution.

Evidence from Task 16:
- L973: `**Target files:** ... create/modify \`scripts/_resolve-lib.sh\` ... modify \`tests/unit/test-routing-matrix-application.bats\``
- L974: `**Dependencies:** none.`

Evidence from Task 19:
- L1102: `**Target files:** ... \`scripts/_resolve-lib.sh\` ... \`tests/unit/test-routing-matrix-application.bats\``
- L1116: `Extend \`scripts/_resolve-lib.sh\` with the host × vendor matrix...`
- L1103: `**Dependencies:** none.`

This means both tasks can be scheduled concurrently while editing the same contract-defining files, even though Task 19 is described as an extension of that shared resolver/matrix behavior. Add `Task 16` as a dependency of Task 19 (and update the slice summary line at L65) to keep the graph consistent with the task contracts.
<!-- @@SCORE: quality-codex.finding-F01.score @@ -->
score: 75
reason: Verified — T16 creates `_resolve-lib.sh` and `test-routing-matrix-application.bats` and T19 modifies both while declaring `deps: none`, contradicting the plan's own stated rationale for sequencing T16→T17 on shared edit surfaces and the prose "Extend `scripts/_resolve-lib.sh`" that presupposes T16.
<!-- @@FINDING: security-claude.finding-F01 @@ -->
---
change_type: scope
severity: medium
score: 3
artifact: plan.md
location: "## Phase 1: v0.7.2 release → ### Phase 1 Acceptance Criteria, AC #2 (master fail-loud enumeration); ### Task 39 Definition of done + Test expectations"
---

## Summary

The round-05 AC #2 enumeration extension added T39's symlink-escape canonicalization halt and T19's `[second-reviewer-same-vendor]` halt, but AC #2 still omits **four other build-pipeline fail-loud halts that T39 explicitly requires in its own DoD and Test Expectations**. These are precisely the kind of seeded-regression invariant AC #2 is meant to bill — and one of them (the `${CLAUDE_SKILL_DIR}` halt) is already named as an acceptance fixture inside T39 itself. The master enumeration is therefore incomplete relative to the build-pipeline surface it claims to cover.

## Per-task DoD halts vs. AC #2 master enumeration

Cross-walking T39's `## Definition of done` against AC #2:

| T39 DoD fail-loud halt | T39 DoD line | T39 test fixture | AC #2 enumerated? |
|---|---|---|---|
| `!cat` target canonicalizes outside `$REPO_ROOT/` (symlink-escape) | "canonicalizes every `!cat` target path with `fs.realpathSync` … fails non-zero with a `resolves outside repository` diagnostic" | "Symlink-escape regression" | **Yes** (round-05 addition) |
| Include cycle with full cycle printed | "fail non-zero with file:line plus reason for … include cycles with full cycle printed" | "a deliberate include-cycle failure with the required diagnostics" | **No** |
| Malformed `!cat` directive | "fail non-zero with file:line plus reason for malformed `!cat` lines" | "Unit-test resolver failure cases for malformed `!cat` lines" | **No** |
| Missing `!cat` target | "fail non-zero with file:line plus reason for … missing targets" | "Unit-test resolver failure cases for … missing targets" | **No** |
| `${CLAUDE_SKILL_DIR}` occurrence in shipped files | "fail non-zero … for … any `${CLAUDE_SKILL_DIR}` occurrence in shipped files" | "a legacy `${CLAUDE_SKILL_DIR}` directive failure … with the required diagnostics" | **No** |

(Absolute / path-traversal includes and outside-root includes are subsumable under the symlink-escape canonicalization halt — same boundary check — so I'm not flagging those.)

AC #4 (the build-pipeline AC) covers the **positive** outputs ("all `!cat` directives are expanded", "`${CLAUDE_SKILL_DIR}` does not appear anywhere in the shipped tree", `git diff --exit-code` is empty) but does not assert that adversarial inputs are halted with diagnostics. AC #2 is the criterion that says "Every fail-loud invariant in the release fires loud on a seeded regression input", with an explicit enumeration. The four halts above are exactly that shape — adversarial input → non-zero exit + diagnostic — and one of them (`${CLAUDE_SKILL_DIR}`) is even called out as a release-level acceptance fixture in T39's own test expectations.

## Why this matters (security framing)

These four halts protect build-time integrity of the shipped plugin tree. Silent fallback on any of them is a release-integrity failure:

- **`${CLAUDE_SKILL_DIR}` halt**: prevents the legacy resolver token from shipping to hosts that won't expand it. Silent ship → runtime `!cat` directives reference a non-existent path on Copilot CLI → load-bearing skill content silently goes missing in production. This is the *primary* invariant that protects every other Slice 1.5 prompt-prose edit from regressing at install time.
- **Include-cycle halt**: prevents non-terminating expansion at build time, but more importantly prevents a partially-expanded ambiguous artifact from being committed. Silent fallback → build emits unexpected content or hangs CI.
- **Malformed `!cat` / missing-target halt**: prevents typo'd or stale include directives from being silently dropped or partially expanded. Silent fallback → reviewer-protocol or dispatch-prose snippet quietly vanishes from a shipped skill and the on-disk-write contract degrades to chat-only fallback at runtime (the exact failure G3/G6/G12 are designed to prevent).

These are fail-closed boundaries at the same security tier as the symlink-escape halt that round-05 *did* add. The release verification machinery shouldn't ship the symlink halt with a regression seed but ship the `${CLAUDE_SKILL_DIR}` halt without one in the AC #2 master list — the Test phase reads AC #2 as the bill of materials for seeded-regression coverage at phase boundary. If AC #2 is the authoritative cross-task seed list, a Test-phase implementer can mark AC #2 green without ever firing the `${CLAUDE_SKILL_DIR}` or include-cycle seed.

## Suggested AC #2 extension

Extend AC #2 (after the existing `tools/build-plugin.mjs` `resolves outside repository` clause, since these four halts live in the same script and surface the same diagnostic discipline) with the missing build-pipeline halts. Suggested wording, slotted at the end of the AC #2 bullet:

> … and `tools/build-plugin.mjs` `resolves outside repository` halt when a `!cat` target canonicalizes outside `$REPO_ROOT/` (symlink-escape exfiltration surface), `tools/build-plugin.mjs` include-cycle halt with the full cycle printed, `tools/build-plugin.mjs` malformed `!cat` directive and missing-target halts with `file:line` diagnostics, and `tools/build-plugin.mjs` `${CLAUDE_SKILL_DIR}` shipped-file halt when any built file under `build/` still contains the legacy resolver token — each produce non-zero exit with a diagnostic, never silent fallback.

(T39's Test Expectations already cover all four with regression fixtures, so no per-task DoD changes are needed — only the AC #2 master enumeration needs to be made consistent with what T39 already requires.)

## Out of scope for this finding (verified covered)

- T20 splitter halts ("missing flags / missing raw output / missing boundaries / write errors"): AC #2 item 1 ("splitter on adversarial Codex stdout") subsumes the missing/malformed-boundaries case, which is the canonical adversarial-input scenario. The other three are minor edge cases acceptable at per-task altitude.
- T19's "unknown host / missing default vendor / unknown vendor" halts: all share the `[second-reviewer-unavailable]` diagnostic prefix already enumerated by AC #2 item 6, so a single regression seed covers all four entry conditions.
- T12 / T13 round-prepare exit codes 10/11/12 and prior-round bookkeeping halts: operational-orchestration scoped, properly at per-task altitude rather than the AC #2 cross-task list.
- T24 invalid-`QRSPI_INTERACTION_MODE` halt: per-task scoped, no cross-task observability requirement.
- T16/T17 schema/validation-table halts: AC #2 already covers items 3 ("validation table on missing `model_routing:`") and 4 (`tier: none`).
<!-- @@SCORE: security-claude.finding-F01.score @@ -->
score: 50
reason: Verified consistency gap — AC #2 enumerates only the symlink-escape build-plugin halt while T39 DoD/Test expectations explicitly require four sibling fail-loud halts (include-cycle, malformed !cat, missing target, ${CLAUDE_SKILL_DIR}-in-shipped-files) with fixtures; real Plan-altitude completeness issue but partially mitigated by T39's per-task tests running in the release suite and AC #2 not being formally an exhaustive bill-of-materials.
<!-- @@FINDING: security-codex.finding-F01 @@ -->
---
finding_id: R6-F01
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-30-v072-release/plan.md]
---

AC #2 at plan.md:22 enumerates only the G5 hash-mismatch halt (`plan.md post-approval split halt when ... '# block-hash:' no longer matches`), but Task 34 defines two additional halt paths that are not represented in the phase-level fail-loud gate:
- missing header halt (plan.md:1951, test pin at 1965)
- malformed header halt (plan.md:1952, test pin at 1966)
This leaves the phase acceptance under-specified for idempotent-split integrity: a release could satisfy AC #2 while regressing the pre-G5/malformed-header fail-loud protections that T34 explicitly requires.
<!-- @@SCORE: security-codex.finding-F01.score @@ -->
score: 50
reason: Verified — AC #2 enumerates only the G5 hash-mismatch halt while T34 (plan.md:1951-1952, test pins 1965-1966) defines two additional fail-loud halts (missing-header, malformed-header); the AC's verifier-fan-in entry sets a precedent for enumerating each materially-distinct halt subtype, so omitting two of the three G5 halts is a real under-specification of the phase-level fail-loud gate, though per-task ACs in T34 still cover them.
<!-- @@FINDING: security-codex.finding-F02 @@ -->
---
finding_id: R6-F02
severity: high
change_type: correctness
referenced_files: [docs/qrspi/2026-05-30-v072-release/plan.md]
---

AC #2 (plan.md:22) includes only one build-plugin boundary halt (`resolves outside repository` on canonicalized `!cat` target), but Task 39's locked fail-loud set is broader and includes additional security-relevant parser/path guards:
- fail non-zero for absolute/path-traversal attempts (plan.md:2224, 2246)
- fail non-zero for malformed `!cat` directives and missing targets/cycles (plan.md:2224, 2246)
- fail non-zero on `${CLAUDE_SKILL_DIR}` occurrence in shipped files (plan.md:2224, 2246)
Because AC #2 is the release-level seeded-regression gate, omitting these listed fail-loud conditions means phase acceptance can pass without proving those T39 security controls remain enforced.
<!-- @@SCORE: security-codex.finding-F02.score @@ -->
score: 60
reason: Real completeness gap — AC #2 enumerates per-task fail-loud halts in detail for other tasks (verifier-fan-in lists five causes) but only lists one of T39's six locked fail-loud conditions; task-level tests still cover these so impact is mitigated, but phase-level gate is asymmetric.
<!-- @@FINDING: silent-failure-codex.finding-F01 @@ -->
---
finding_id: R6-F01
severity: high
change_type: correctness
referenced_files: [docs/qrspi/2026-05-30-v072-release/plan.md]
---

AC #2 explicitly treats both routing and second-reviewer slot selection as fail-loud release invariants in one chain: line 22 requires loud failure for both "dispatch on misrouted `model_routing` entries" and `_resolve-lib.sh` `[second-reviewer-same-vendor]` cases.

But the task graph does not enforce that ordering: Task 16 (the `model_routing` migration + `_resolve-lib.sh` routing semantics) is line 63 and blocks only T17 (line 974), while Task 19 (which adds `_resolve-lib.sh` same-vendor / second-reviewer fail-loud behavior) has "**Dependencies:** none" (line 1103 / list line 65).

This leaves a fail-open planning gap: T19 acceptance can pass before the G22 resolver migration lands, then later `_resolve-lib.sh` edits from T16 can invalidate T19's fail-loud guarantees without a dependency-enforced gate. For an AC #2 invariant that is explicitly cross-task and fail-loud, the plan should force T16-before-T19 (or equivalent explicit gating) instead of allowing independent sequencing.
<!-- @@SCORE: silent-failure-codex.finding-F01.score @@ -->
score: 55
reason: T16 creates `_resolve-lib.sh` with tier-routing+halt-on-none semantics and T19 modifies the same file to extend host×vendor matrix and add `[second-reviewer-same-vendor]` halt, yet T19 declares Dependencies: none — a real shared-file/AC#2 coordination gap, though somewhat overstated (each fail-loud is independently tested per task and both feed T20).
<!-- @@FINDING: spec-codex.finding-F01 @@ -->
---
reviewer: codex
role: plan-spec-reviewer
round: 6
artifact: plan.md
severity: medium
change_type: correctness
finding_id: F01
referenced_files: [docs/qrspi/2026-05-30-v072-release/plan.md]
---

# Finding F01 — R1–R7 reviewer-judgment test expectations on T27/T33/T37/T38

## Location

- `plan.md` Task 27, **L1542** — "**Content-semantic review applies R1-R7...**"
- `plan.md` Task 33, **L1904** — "**Implementer applies R1-R7... reviewer ... verifies...**"
- `plan.md` Task 37, **L2138** — "**Implementer applies R1-R7... reviewer verifies...**"
- `plan.md` Task 38, **L2191–L2192** — "**Apply R1-R7...**" and "**Mental-replay check... would not trigger...**"

## What's wrong

Several task `Test expectations` clauses are written as reviewer-judgment checks
rather than deterministic, reproducible acceptance conditions, so Test-phase
pass/fail cannot be mechanically verified from fixed inputs/outputs.

These checks depend on subjective interpretation ("content-semantic review",
"mental-replay"), not on concrete fixtures/assertions with expected outputs.
That breaks the spec-review requirement that author-side Test Expectations be
deterministically verifiable by Test phase, and risks false-clean outcomes
where regressions pass because reviewer interpretation differs round-to-round.

## Notes

T27/T33/T37/T38 are content-semantic prose tasks (SKILL.md edits, decisions
doc updates) where R1–R7 IS the framework for the deterministic check —
but the test-expectation language as currently written reads as
"a reviewer subjectively applies R1–R7" rather than "this fixture matches
this expected output". The fix is to either (a) reframe the R1–R7 application
as a binary grep/diff against pinned prose anchors, or (b) accept that
content-semantic tasks have a different test-altitude than code tasks and
mark these expectations as "reviewer-applied" rather than "mechanically
verifiable" to set Test-phase expectations correctly.
<!-- @@SCORE: spec-codex.finding-F01.score @@ -->
score: 35
reason: Real but minor — the cited R1-R7/mental-replay bullets are supplementary lines added alongside extensive deterministic grep/anchor/diff/file-existence checks (which dominate each Test expectations block), the Plan SKILL allows plain-language behaviors/edge-cases rather than purely mechanical assertions, and the finding itself concedes a valid second disposition (accept reviewer-applied altitude for prose tasks), making this closer to a stylistic nit than a correctness defect.
<!-- @@FINDING: test-coverage-codex.finding-F01 @@ -->
---
finding_id: R6-F01
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-30-v072-release/plan.md]
---

Task 19's test expectation permits non-executable evidence for a fail-loud behavior that should be runtime-verifiable.

Evidence:
- DoD requires behavioral rejection: `skills/using-qrspi/SKILL.md` "config-validation prose rejects legacy `codex_reviews:` with a rename-naming diagnostic instead of aliasing it." (plan.md:1133)
- But the test expectation is: `Config-validation tests or grep-pinned prose confirm ...` (plan.md:1146, emphasis on "or grep-pinned prose").

A grep-only check can pass while actual validation behavior is wrong (e.g., field silently accepted/aliased at runtime). This leaves the error-condition coverage nondeterministic for a documented fail-loud invariant.
<!-- @@SCORE: test-coverage-codex.finding-F01.score @@ -->
score: 22
reason: Design G27 D1 and the DoD itself scope the codex_reviews rejection as a prose-defined Config Validation Procedure owned by using-qrspi SKILL.md (no runtime validator exists for unknown fields), so grep-pinned prose IS the appropriate executable verification; the "or" disjunction in the test expectation correctly accommodates both paths and the finding's premise that runtime validation could mask a grep pass does not apply to a prose-contract mechanism.
<!-- @@CLEAN: goal-traceability-claude.clean @@ -->
---
reviewer: claude
reviewer_role: goal-traceability
round: 6
artifact: plan.md
verdict: clean
note: filename suffixed `.goal-trace` to avoid collision with `claude.clean.md` (test-coverage-reviewer) already present in this round_subdir.
---

# Round 6 goal-traceability review — clean

Verified the 35-goal forward + 38-task backward traceability matrix against the
round-06 broaden-vs-main diff of `plan.md`.

## Backward trace (38 tasks → goals)

Every task has a non-empty `Goal IDs:` field keyed to the G1–G35 / CD-{1,2,3,4}
namespace. Task count by slice: 1.1=7, 1.2=4, 1.3=3, 1.4=7, 1.5=12, 1.6=2,
1.7=3 → 38 ✓. Gap dispositions (T18/T22/T23/T41/T42/T43) preserved as Overview
rationales referencing design.md ## G24/G25/G26.

| Task | Goal(s)                         | Task | Goal(s)                            |
|------|----------------------------------|------|------------------------------------|
| T01  | [G7]                            | T20  | [G3]                              |
| T02  | [G12]                           | T21  | [G16]                             |
| T03  | [G6]                            | T24  | [G6, G11, G12] (CD-4)             |
| T04  | [G8]                            | T25  | [G31]                             |
| T05  | [G13]                           | T26  | [G31]                             |
| T06  | [G11]                           | T27  | [G3, G4, G22, G27] (CD-2)         |
| T07  | [G14]                           | T28  | [G1, G30, G33] (CD-3)             |
| T08  | [G19]                           | T29  | [G34]                             |
| T09  | [G20]                           | T30  | [G1]                              |
| T10  | [G28]                           | T31  | [G33]                             |
| T11  | [G3] (round-02 relabel from G29) | T32 | [G30]                             |
| T12  | [G4]                            | T33  | [G2]                              |
| T13  | [G9]                            | T34  | [G5]                              |
| T14  | [G15]                           | T35  | [G10]                             |
| T15  | [G18]                           | T36  | [G17]                             |
| T16  | [G22]                           | T37  | [G35]                             |
| T17  | [G23]                           | T38  | [G35]                             |
| T19  | [G27]                           | T39  | [G32]                             |
|      |                                  | T40  | [G21, G26]                        |
|      |                                  | T44  | [G24] (F05 only)                  |

## Forward trace (35 goals → tasks)

33/35 goals have ≥1 direct task. G25 and G29 are documented absorptions:

- **G25** (per-H4 mirror-paragraph contract) — Overview "absorbed by CD-1".
  Plan-authored acceptance lives in Phase 1 per-phase block via the
  `_resolve-lib.sh halt when a CD-1 dispatch resolves to a 'tier: none'
  configuration` fail-loud invariant, which structurally replaces the per-H4
  mirror enforcement contract G25 framed.
- **G29** (large-artifact `artifact_path` escape hatch) — Overview "absorbed
  by CD-1 and ships no standalone task — T11 was repurposed to a CD-1
  dispatch-manifest-provenance task under G3". T11 spec body confirms
  ("G29 … is moot per design.md ## G29 (absorbed by CD-1, no separate task
  ships)"). Plan-authored coverage via T11's CD-1 manifest provenance Test
  Expectations + per-phase second-reviewer fail-loud bullets.

## Round-history verification

- Round-04 surgical moot-goals deletion (T18/T22/T23/T41/T42/T43) — gaps
  present in task numbering; per-gap dispositions enumerated in Overview L11.
- Round-04 T11 G29→G3 relabel — `Goal IDs: [G3]`; T11 spec body retains the
  CD-1 dispatch-manifest semantics and the explicit G29-absorption note.
- Round-04 dep-graph item 4 (T09/T11/T13 → T20) present.
- Round-05 T21→T39 dependency — T39 `Dependencies: [Task 21, Task 25]` and
  dep-graph item 3 explicitly chains G3→G16→G32.

## Spec-to-design fidelity

Plan's 7 vertical slices (1.1 apply-fix/verifier; 1.2 verifier rubric +
instrumentation; 1.3 per-task review pipeline; 1.4 dispatch infrastructure;
1.5 skill prose + interactive dialog; 1.6 Structure absorbs unified
architecture; 1.7 build + test-infra) match design.md's slice partitioning.
CD-1/CD-2/CD-3/CD-4 task assignments (T11/T27/T28/T24) match design.md's
cross-cutting decisions.

## Decomposition check

Spot-checked T08 (G19 cite-check + HALLUCINATED), T09 (G20 actual_model flow),
T10 (G28 defect_class + Sub-Threshold Observations), T11 (G3/CD-1 manifest
provenance). Each Test Expectations bullet traces upstream to the goal's
problem framing in goals.md and the design.md decision payload.

## Verdict

No traceability findings. The 35-goal forward + 38-task backward matrix is
100% complete with consistent goal-IDs across Overview, Task List by Slice,
Dependency Graph, and per-task specs.
<!-- @@CLEAN: scope-claude.clean @@ -->
---
reviewer: scope-claude
round: 6
status: clean
---

Round 06 plan scope review (Claude, broaden-vs-main): all 3 scope-procedure checks clean. No scope findings.

- Check 1 (lexical boundary-drift): no if/else/for/while logic walkthroughs; no test-code text; no design-layer leaks; v0.7.3+ mentions are bounded scope-deferral framing.
- Check 2 (semantic boundary-drift): borderline items (T11 dispatch_spec field enumeration, T16 five low-tier agent files, T20 12 consumer SKILL migrations, T21 assert_path_under_repo_root, T29/T37 introducer prose, T34 halt diagnostics) all judged acceptable as acceptance-criterion mirroring of locked upstream contracts, not new authoring.
- Check 3 (scope compliance per Plan OWNS): all 38 task specs present with stable numbering; every task has populated Test Expectations; no forward dependencies; LOC estimates with sizing_exception fields on oversized tasks.

Round-05 carry-over: all 3 fixes present (T16→T19 same-vendor halt; T39 deps; AC #2 enumeration). 2 drops remain absent. No regressions.
<!-- @@CLEAN: scope-codex.clean @@ -->
---
reviewer: scope-codex
round: 6
status: clean
---

Round 06 plan scope review (Codex, broaden-vs-main): NO_FINDINGS_ROUND_6.
<!-- @@CLEAN: silent-failure-claude.clean @@ -->
---
reviewer: claude
reviewer_type: silent-failure
artifact: plan.md
round: 6
scope: broaden-vs-main
findings: 0
---

# Silent-failure review — clean

Round-6 broaden-vs-main silent-failure review of `plan.md` found no fail-open,
log-and-continue, silent-fallback, or partial-state patterns warranting a
finding at Plan altitude.

## Surfaces verified loud

**AC #2 fail-loud enumeration ↔ per-task DoD mapping (every item maps to a
per-task DoD or test-expectations bullet with matching diagnostic text):**

- Splitter on adversarial third-party stdout → T20 DoD L1202 ("fails loudly
  for missing flags, missing raw output, missing boundaries, or write errors").
- Dispatch on misrouted `model_routing` entries → T16 DoD L1001 (tier=none halt,
  no neighbor-tier or agent-bundled fallback) + test L1014.
- Validation table on missing `model_routing:` → T17 DoD L1077 ("A config
  missing `model_routing:` still fails loudly... no silent default").
- `_resolve-lib.sh` `tier: none` halt → T16 DoD L1001 + test L1014.
- `_resolve-lib.sh` `[second-reviewer-same-vendor]` halt → T19 DoD L1136 +
  test L1148. Round-5 ownership move from T16→T19 lands at the correct
  matrix-lookup altitude.
- `second-reviewer-available.sh` `[second-reviewer-unavailable]` halt → T19
  DoD L1131 + L1135 + tests L1141 + L1147.
- Plan post-approval split block-hash mismatch / missing-header /
  malformed-header halts → T34 DoD L1949-1952, exact diagnostic strings
  pinned in test expectations L1964-1967.
- `scripts/verifier-fan-in.sh` halt taxonomy (`missing_change_type`,
  `change_type_out_of_enum`, missing sidecar, wrong sidecar extension,
  unparseable score) → T02 DoD L206 + test L214; T05 preserves
  missing-vs-out-of-enum distinction at L373.
- Reviewer-protocol anti-fabrication `CONTRACT-CONFLICT:` single-line exit
  with no `Write`/findings/sentinels/round-counter advance → T35 DoD
  L2009-2018 + test L2023-2028.
- Path-filter exfil guard in `scripts/dispatch-agent.sh` → T21 DoD
  L1267-1272 + symlink/companion regressions L1277-1282.
- `tools/build-plugin.mjs` `resolves outside repository` halt → T39 DoD
  L2253 (round-5 AC-coverage addition) mirrored by symlink-escape regression
  L2268 ("Mirrors T21's symlink-out-of-repo regression... so the two
  canonicalization surfaces use the same audit-friendly diagnostic phrase").

**Soft-fallback patterns examined, dispositioned as intentional / not
silent-failure:**

- T09 `actual_model: unknown` fallback (L589) — backward-compat for finding
  files emitted before this audit field existed. Verifier sidecars surface
  the unknown signal in their frontmatter rather than hiding it;
  observability instrumentation only, not a correctness gate.
- T10 `defect_class: unspecified` (L646) — observability instrumentation;
  does not affect keep/drop or the existing verifier-fan-in threshold
  filter.
- T24 unknown-host `VERDICT=interactive` (L1332) — caller sees explicit
  `PLATFORM=unknown` + `DETECTION_TYPE=user-override-only` + safe-default
  evidence. The unknown-host signal is surfaced in output, not silenced;
  invalid override values still fail loud per L1334.
- T19 D3 probe-failure → `second_reviewer: false` (L1117) — round-5 D1
  drop preserved. Design D3 explicitly says "skip silently" with
  `[second-reviewer-unavailable]` stderr (the user sees the diagnostic at
  config time), and D4 enforces a loud halt at dispatch time if `true`
  is hand-edited in. The two safety nets together close the surface; no
  new evidence in round-6 to re-litigate D3.
- T44 G24-F05 (L2360-2393) actively hardens prior literal-substring pins
  into regex assertions that catch the silent-fallback semantic family
  ("silently substitutes the bundled default", "silently degrades to the
  agent default", "no silent fallback to a neighboring tier") and adds a
  mandatory `[ -n "$body" ]` body-presence guard so missing extracts fail
  loud rather than vacuously passing.

**Borderline phrasing examined:**

- T26 "silently skip `task_type: lightweight` tasks" for
  `qrspi-plan-test-coverage-reviewer` (L1446) — yellow-flag wording, but
  the in-context DoD line L1464 ("skips lightweight tasks instead of
  emitting missing-RED-test findings") makes intent clear: the reviewer
  suppresses the missing-RED-test rule for prompt-prose-class tasks where
  TDD does not apply. Reviewer dispatch-side output-contract semantics
  (clean sentinel vs. no output) live in `skills/reviewer-protocol/SKILL.md`
  per F-5 altitude rule — the same rule round-5 cited when dropping D2.
  Not a load-bearing finding at Plan altitude.

## Convergence assessment

Round-5 made three surgical edits (T16→T19 halt move, T39 dep edge correction,
AC #2 build-pipeline halt enumeration). Each lands coherently in the
round-6 broader read:

- T19 own-and-extend of `_resolve-lib.sh` for the same-vendor halt is
  consistent with its existing matrix-lookup scope; no new dep-graph
  drift in the silent-failure surface.
- T39's `[Task 21, Task 25]` dep edge is reflected in dep-graph item 3
  (L110) and in T39's own DoD/test mirroring of T21's guard.
- AC #2's `tools/build-plugin.mjs` enumeration matches T39 DoD L2253 word
  choice (`resolves outside repository`), giving the symlink-escape exfil
  surface a Phase 1 cross-task observable check.

No new silent-failure / fail-open / log-and-continue / silent-fallback
patterns introduced; no carry-over patterns missed in prior rounds surface
on the broader-vs-main read.
<!-- @@CLEAN: spec-claude.clean @@ -->
---
reviewer: claude
role: qrspi-plan-reviewer
round: 6
artifact: plan.md
verdict: clean-with-concurrence
concurs_with:
  - quality-claude.finding-F01.md
  - quality-claude.finding-F02.md
  - quality-claude.finding-F03.md
review_type: broaden-vs-main
---

# Plan reviewer (claude) — Round 6 (broaden-vs-main)

No additional findings beyond the three `quality-claude.finding-F0[1-3].md`
files already present in this round's directory, with which I concur.

## Scope of this review

Round-06 broaden-vs-main review of plan.md (full 2401-line artifact). Per
Round-05 history note, focused on the surfaces edited in Round-05:

- L22 — Phase 1 Acceptance Criteria #2 enumeration extension
- L92 / L110 — Task List + Dependency Graph narrative
- T16 (L966–L1040) — DoD + Test Expectations after `[second-reviewer-same-vendor]`
  halt removal
- T19 (L1095–L1162) — Out, DoD, Test Expectations, References after the halt
  re-ownership to T19
- T39 (L2202–L2280) — deps update + canonicalization-halt alignment

## Concurrence rationale

### quality-claude.finding-F01 (T19 missing `Dependencies: Task 16`)

I identified this same surface during my analysis but held back from raising
it under a "pre-existing condition" framing. The F01 author's "round-05
**deepens**, not severs, the dependency" framing is the correct
characterization and I was wrong to suppress. Specifically:

- Before round-05: T19 extended `_resolve-lib.sh` with host × vendor matrix
  helpers without a T16 dep edge. The halt lived in T16, so the structural
  ordering was at least notionally tracked via T16 owning the halt that uses
  the helpers T19 adds.
- After round-05: the halt was moved to T19 ("`_resolve-lib.sh`'s host ×
  vendor matrix lookup halts loudly with `[second-reviewer-same-vendor]`" at
  L1136). Now T19 owns both the matrix-lookup helpers AND the halt that uses
  them — but still has no dep edge to T16 which **creates** the file these
  helpers extend.
- The same-file edit risk on `tests/unit/test-routing-matrix-application.bats`
  (both T16 L991 and T19 L1147–L1148 modify it) compounds the ordering
  concern.

This is a load-bearing new defect exposed by the round-05 fix, not a
pre-existing condition the fix left untouched. F01's recommended fix
(`Dependencies: Task 16` on T19 L1103 + `Blocks: Task 17, Task 19` on T16
L974) is the minimal correct edit.

### quality-claude.finding-F02 (L110 narrative misattribution)

I missed this in my Round-06 pass. The L110 rewrite said T39 depends on T21
"for the renamed `scripts/dispatch-agent.sh` path under the `build/`
allow-list and `!cat` resolver inspection" — but T20 owns the rename, not
T21 (T20 task header at L1164; T21 only modifies the already-renamed file).
The actual round-05 rationale per T39 DoD L2253 ("mirrors T21's
`assert_path_under_repo_root` shape") and T39 Test L2268 ("Mirrors T21's
symlink-out-of-repo regression... so the two canonicalization surfaces use
the same audit-friendly diagnostic phrase") is the diagnostic-phrase
consistency, not the rename path. The deps field itself is correct; only
the narrative needs to match the actual rationale.

### quality-claude.finding-F03 (T16/T19 carve-out symmetry)

I missed this in my Round-06 pass. T19's Out (L1121–L1124) carves out
downstream surfaces (T20 renames, T27 snippet, v0.7.3+ futures) but not
T16's upstream resolver foundation. T16's Out (L993–L996) carves out T17,
T27, and v0.7.3+ futures but not T19's matrix-lookup territory. The In
phrasing collision between T16 L986 ("host/vendor routing lookup") and T19
L1116 ("host × vendor matrix... lookup helpers") is precisely the kind of
ambiguity round-05's halt-move was supposed to clean up.

## Verification of round-05 edits not flagged by F01-F03

- L22 AC #2 enumeration extension: `tools/build-plugin.mjs` `resolves
  outside repository` clause is byte-aligned with T39 DoD L2253 and Test
  L2268. Diagnostic phrase consistent.
- L92 + L2210 T39 deps: `[Task 21, Task 25]` consistent across task list
  and per-task spec.
- T16 DoD/Test removal of `[second-reviewer-same-vendor]`: clean — no
  vestigial mention in T16's DoD, Test Expectations, or References.
- T19 DoD L1136 + Test L1148 addition: correctly attributes the halt to
  `_resolve-lib.sh` matrix-lookup time with the clarifying parenthetical
  that `second-reviewer-available.sh` checks reachability only.
- T19 Out removal of the bullet that deferred halt enforcement to T16:
  verified absent.
- Halt-vs-task ownership across the full AC #2 list: every enumerated halt
  traces to an owning task's DoD + Test Expectations (T2/T3/T5/T6/T16/T17/T19/T20/T21/T35/T39).

## Surface-area summary

| Round-05 edit surface | F01 | F02 | F03 | My pass | Net verdict |
|---|---|---|---|---|---|
| L22 AC #2 build-plugin halt | – | – | – | clean | clean |
| L92 / L2210 T39 deps field | – | – | – | clean | clean |
| L110 narrative rewrite | – | flagged | – | missed | F02 stands |
| T16 halt removal | – | – | flagged (carve-out stale) | clean (DoD/Test only) | F03 stands |
| T19 halt addition + Out edit | flagged (missing T16 dep) | – | flagged (Out asymmetry) | partially clean | F01 + F03 stand |
| T39 DoD L2253 mirror language | – | flagged (L110 misattribution) | – | clean | F02 stands |

No edit surface is fully clean; F01-F03 collectively cover the gaps the
round-05 fix exposed or left behind on its own touched surfaces.
<!-- @@CLEAN: test-coverage-claude.clean @@ -->
---
reviewer: claude
role: test-coverage-reviewer
round: 6
artifact: plan.md
verdict: clean
---

# Test Coverage Review — Round 6 (broaden-vs-main)

No findings.

## Verification scope

Round-05 narrowed-diff history (clean) verified 38 task specs and Phase 1 AC
#2 had complete deterministic Test Expectations. This round re-checks the
round-05 edits against `main` to confirm the surgical changes still meet the
Test phase's deterministic-test bar.

Round-05 edits in scope:

- **T16** — removed `[second-reviewer-same-vendor]` DoD + test (responsibility
  moved to T19); `tier: none` halt coverage retained.
- **T19 L1136 (DoD) + L1148 (test)** — added `[second-reviewer-same-vendor]`
  halt at `_resolve-lib.sh` matrix-lookup time.
- **T39** — deps-only fix (no test changes); pre-existing L2268
  symlink-escape regression test for `resolves outside repository` halt
  unchanged.
- **AC #2** — added `tools/build-plugin.mjs` `resolves outside repository`
  halt to the enumeration; backed by T39 L2268.

## Test-expectation-quality bar — both new/cross-referenced halts pass

**T19 L1148** (`[second-reviewer-same-vendor]`):

- Named test file: `tests/unit/test-routing-matrix-application.bats`.
- Specific precondition: `second_reviewer: true` dispatch resolves primary
  and second-reviewer slots to the same vendor.
- Specific diagnostic prefix: `[second-reviewer-same-vendor]`.
- Two observable behaviors: `_resolve-lib.sh` halts with the diagnostic AND
  emits zero dispatch spec lines for that round.
- Component-under-test disambiguation: matrix-lookup, not the
  reachability-only probe (L1136 parenthetical).

Specific, observable, deterministic, falsifiable. ✓

**T39 L2268** (`resolves outside repository`):

- Named scenario: committed `!cat`-targeted file that is itself a symlink
  whose canonical target is outside `$REPO_ROOT` (e.g., `/etc/passwd` or
  `/tmp/secret`).
- Two observable behaviors: build fails non-zero before any byte of the
  referent enters `build/` AND stderr diagnostic contains
  `resolves outside repository`.
- Cross-reference to T21's parallel surface
  (`tests/unit/test-dispatch-agent.bats`) for diagnostic-phrase consistency
  across both canonicalization guards.

Specific, observable, deterministic, falsifiable. ✓

## AC-vs-task halt-enumeration cross-check (round-06 broaden surface)

Every fail-loud halt named in Phase 1 AC #2 has a backing per-task test
expectation:

| AC #2 halt                              | Backing task / line |
|-----------------------------------------|---------------------|
| splitter adversarial Codex stdout       | T20                 |
| dispatch misrouted `model_routing`      | T16                 |
| validation-table missing `model_routing:` | T17               |
| `_resolve-lib.sh` `tier: none`          | T16                 |
| `_resolve-lib.sh` `[second-reviewer-same-vendor]` | T19 L1148 |
| `second-reviewer-available.sh` `[second-reviewer-unavailable]` | T19 L1141, L1147 |
| plan.md post-approval split block-hash mismatch | T14 / T15   |
| `verifier-fan-in.sh` audit-cause halts  | T02 / T05 / T06     |
| reviewer-protocol fabricated procedural-authority | T03      |
| path-filter exfil in `dispatch-agent.sh` | T21                |
| `build-plugin.mjs` `resolves outside repository` | T39 L2268   |

No orphan AC enumeration entries; no vague "handles X" test expectations
introduced by round-05 edits. The round-05 split (move same-vendor halt
T16 → T19) leaves both T16's remaining halt coverage and T19's new halt
coverage complete and non-overlapping.

## Scope-hint discipline

This round was broaden-vs-main with no `scope_hint` narrowing — I reviewed
all four round-05 touchpoints (T16, T19, T39, AC #2) plus the AC-vs-task
cross-check across the full 38-task spec set. No findings outside the
prompt's named verification surface either.

## Verdict

Clean. Test phase can proceed to generate acceptance tests from the plan's
Test Expectations without ambiguity for any round-05 surgical edit or
broader AC enumeration item.
