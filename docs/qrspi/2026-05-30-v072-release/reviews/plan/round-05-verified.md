---
verifier_enabled: true
scored: 5
kept: 3
dropped: 2
failed: 0
clean: 9
---

<!-- @@FINDING: quality-claude.finding-F01 @@ -->
---
reviewer: qrspi-plan-reviewer
reviewer_tag: quality-claude
artifact: plan.md
round: 5
finding_id: F01
severity: significant
change_type: correctness
score: 68
location: plan.md L1002 (T16 DoD) + L1016 (T16 test exp) + L1118 (T19 In) + L96-110 (Dependency Graph)
---

# T16's new `[second-reviewer-same-vendor]` halt has no infrastructure foothold in T16's own scope; the data structure it needs is exclusively in T19, with no dep edge

## What the artifact says

Round-04's surgical fix added a new DoD bullet and test expectation to T16 (L1002, L1016):

> "`_resolve-lib.sh` halts loudly with `[second-reviewer-same-vendor]` when a `second_reviewer: true` resolution returns the same `(vendor)` for both the primary and second-reviewer slots in a single round; it never silently emits two dispatch spec lines that resolve to the same model under distinct reviewer tags."

> "Verify a `second_reviewer: true` dispatch whose primary and second-reviewer resolutions return the same vendor halts with `[second-reviewer-same-vendor]` and emits no dispatch spec lines for that round."

For the resolver to compute this halt, it must resolve **both** the primary `(vendor, model)` **and** the second-reviewer `(vendor, model)` from a `second_reviewer: true` input. Resolving the second-reviewer slot requires a default-second-reviewer-vendor lookup (which vendor is the second-reviewer for the active host?).

T16's `In` scope (L986) only enumerates resolver responsibilities for the **primary** dispatch path:

> "agent-frontmatter `tier:` parsing, precedence (...), tier-to-`(vendor, model)` lookup, host/vendor routing lookup, and halt-on-`none` behavior."

The "host/vendor routing lookup" phrase is primary-slot wording; it does not name second-reviewer resolution.

T19's `In` (L1118) is where the second-reviewer-vendor data structure is actually delivered:

> "Extend `scripts/_resolve-lib.sh` with the host × vendor matrix and **default-second-reviewer lookup helpers** consumed by both the probe and dispatcher-facing routing tests, without a parallel hardcoded host table in the probe."

And T19's DoD L1138 reinforces this:

> "Routing-matrix coverage demonstrates that `second_reviewer: true` can emit primary and second-reviewer entries at the same tier..."

T19 owns the primary+second-reviewer dispatch fan-out matrix. T16 owns the halt that consumes it.

**Dep edges:** T16 `deps: none`. T19 `deps: none`. The Dependency Graph (L96-110) lists four cross-slice clusters; none of them mentions T16 ↔ T19 ordering.

## Why this is a Plan-altitude defect

Three concrete failure modes the plan currently underspecifies:

1. **Implementation order is undefined.** Both tasks have `deps: none` and both `create/modify scripts/_resolve-lib.sh`. If T16 lands first, the implementer cannot build the same-vendor halt — the resolver has no way to look up the second-reviewer vendor for a `second_reviewer: true` input, because that lookup helper does not yet exist. If T19 lands first, T19 has to either create `_resolve-lib.sh` (currently framed as T16's create surface) or wait for T16.

2. **Test fixture co-ownership ambiguity.** Both T16 (L973) and T19 (L1104) modify `tests/unit/test-routing-matrix-application.bats`. T16's new same-vendor-halt fixture and T19's primary+second-reviewer fan-out fixture sit in the same file with no merge-ordering rule. The round-04 disposition explicitly said this test file is "the natural home for the new fixture," but did not assign a dep edge.

3. **T16's `In` scope is materially incomplete.** The round-04 verifier's reasoning was that "the resolver is the layer that computes the second-reviewer dispatch" — true at the architecture level, but T16's `In` bullets do not actually carve out *any* second-reviewer resolution responsibility. A reader of T16 alone has no signal that T16's `_resolve-lib.sh` must learn to resolve second-reviewer slots. The new DoD bullet at L1002 floats free of `In` scope.

This is the same class of defect round-04 fixed for AC #2 enumeration (universal-quantified claim with under-enumerated coverage). Here the halt is *enumerated* in the AC but *under-scoped* in its owning task.

## Suggested fix (pick one — Plan altitude, leaves implementer free)

**Option A (preferred — minimal edit):** Add a dep edge `T19 → T16` (T16 depends on T19) AND add one `In` bullet to T16 carving out the second-reviewer resolution step it now owns:

> "- Add the `second_reviewer: true` resolution step that calls T19's default-second-reviewer lookup helper, compares primary vs second-reviewer vendor, and halts with `[second-reviewer-same-vendor]` when both slots resolve to the same `(vendor)`."

And add a 5th cluster to the Dependency Graph naming this edge.

**Option B:** Move the same-vendor halt DoD bullet + test expectation from T16 to T19 (where the matrix lives). Update AC #2 enumeration entry to attribute the halt to T19. T16's `In` stays as-is. T19 already has the necessary fan-out matrix work; the halt sits naturally adjacent.

**Option C:** Split T16's `In` "host/vendor routing lookup" into two explicit primitives (a) primary-slot routing lookup and (b) second-reviewer-slot routing lookup; the latter is the same primitive T19 then extends with the full host × vendor matrix. Add `T19 deps: T16` since T19 would now be extending T16's second-reviewer primitive rather than introducing it.

Any of the three resolves the under-scoping; the verifier or author should pick the one that minimizes total churn.

## Why this matters now (broaden round signal)

This is a fresh defect introduced by the round-04 surgical fix. The fix correctly identified the missing AC enumeration but landed the new halt on a task whose `In` scope and dep edges don't support it. Without a fix, the implementer working T16 in isolation will either (a) discover mid-task that they need T19's matrix and block, or (b) re-implement the second-reviewer lookup locally, creating exactly the "parallel hardcoded host table" T19's In explicitly forbids ("without a parallel hardcoded host table in the probe").
<!-- @@SCORE: quality-claude.finding-F01.score @@ -->
score: 70
reason: Verified real Plan-altitude defect — T16's new L1002 DoD bullet and L1016 test expectation require resolving the second-reviewer slot, but T16's `In` (L984-991) only carves primary-slot routing while the host × vendor matrix and default-second-reviewer lookup helpers are explicitly created in T19's `In` (L1118); both tasks carry `deps: none` and both modify `scripts/_resolve-lib.sh`, with no T16↔T19 edge in the Dependency Graph (L96-110); T19's Out at L1127 confirms ownership intent but the dep edge and `In` carve-out are still missing, violating Plan SKILL's HARD-GATE that "every task spec must be self-contained — an implementation agent reading only that task must have everything it needs."
<!-- @@FINDING: quality-codex.finding-F01 @@ -->
---
finding_id: R5-F01
reviewer_tag: quality-codex
round: 5
artifact: plan.md
severity: high
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/plan.md
---

# G32 dependency contract is internally inconsistent (T39 missing T21/T20 dependency edge)

## What

The plan's Dependency Graph item 3 (plan.md L104) explicitly states `G3 splitter rename (Slice 1.4) → G16 dispatch-agent path-filter (Slice 1.4) → G32 build pipeline (Slice 1.7)`, but Task 39 is declared in both the task list (L92) and the per-task spec (L2211) with `Dependencies: Task 25` only.

Additionally, line 110 contradicts line 104 explicitly: "Slice 1.7 is otherwise independent of Slices 1.1–1.6 (only T39 depends on T25 for the defensive-copy site)."

This means the executable task spec allows T39 to run before T20/T21, contradicting both the graph narrative AND the task's own scope (which audits/updates renamed script paths and shipped script surfaces under `build/`).

## Why it matters

Implement uses task dependency metadata (the `deps:` field), not prose, to schedule work. With the current spec, T39 can be dispatched before the dispatch-script rename (T20) and the path-filter hardening (T21) land, producing:
- Stale path assertions in T39's `build/` allow-list (T20 renames `scripts/run-codex-review.sh` → `scripts/dispatch-agent.sh`)
- Symlink-escape regression-test divergence (T39's symlink-escape test at L2269 explicitly mirrors T21's `assert_path_under_repo_root` — both must use the same diagnostic phrase, so T21 must land first)
- Build-gate noise during the transition

The artifact also has an internal-consistency defect: prose at L104 and L110 contradict each other on T39's dependencies.

## Suggested fix

Two options:
(a) **Align deps with the graph (preferred):** Update T39's `deps:` in both the task list (L92) and the per-task spec (L2211) to `[Task 21, Task 25]` (T21 transitively pulls in T20 via T21's own deps). Then either delete the contradictory clause at L110 or rewrite it as "Slice 1.7 is otherwise independent of Slices 1.1–1.6 (T39 depends on T25 for the defensive-copy site and on T21 for the renamed/hardened dispatch-agent surface)."
(b) **Retract the graph edge (worse):** Delete dependency-graph item 3 (L104) — but this is incorrect given T39's scope explicitly audits the renamed script surface and mirrors T21's path-guard.

Option (a) is correct.
<!-- @@SCORE: quality-codex.finding-F01.score @@ -->
score: 80
reason: Verified — T39 deps:[Task 25] (L92, L2211) contradicts dep-graph item 3 (L104) and T39's own scope/DoD (L2254, L2269) which explicitly mirrors T21's path guard and audits T20's renamed scripts; L110 also self-contradicts L104. Implement schedules by the `deps:` field, so the gap is materially actionable.
<!-- @@FINDING: security-claude.finding-F01 @@ -->
---
finding_id: F01
severity: high
change_type: scope
location: plan.md → ### Phase 1 Acceptance Criteria → bullet 2 ("Every fail-loud invariant in the release fires loud on a seeded regression input")
---

## AC #2 enumeration still omits T39's build-resolver path-canonicalization exfil guard (parallel to T21, explicitly created in T39 DoD)

### What the plan says

Phase 1 Acceptance Criterion #2 was extended in round-04 to enumerate four new fail-loud invariants (T16 `[second-reviewer-same-vendor]`, T19 `[second-reviewer-unavailable]`, T34 block-hash mismatch, T02 verifier-fan-in halt causes). The leading clause remains universal-quantified: *"Every fail-loud invariant in the release fires loud on a seeded regression input."*

The enumeration as it stands in round-05 covers:

1. splitter on adversarial Codex stdout (T20)
2. dispatch on misrouted `model_routing` entries (T16)
3. validation table on missing `model_routing:` (T17)
4. `_resolve-lib.sh` `tier: none` halt (T16)
5. `_resolve-lib.sh` `[second-reviewer-same-vendor]` halt (T16) — added round-04
6. `second-reviewer-available.sh` `[second-reviewer-unavailable]` halt (T19) — added round-04
7. `plan.md` post-approval split block-hash mismatch halt (T34) — added round-04
8. `scripts/verifier-fan-in.sh` halt causes for five documented malformations (T02) — added round-04
9. reviewer-protocol anti-fabrication output (T35)
10. path-filter exfil guard in `scripts/dispatch-agent.sh` (T21)

### Why this is a Plan-altitude security gap, not an Implement-altitude detail

A release-introduced fail-loud invariant of the **same security class as item 10 (T21)** is missing from the enumeration: **T39's `tools/build-plugin.mjs` path-canonicalization guard**, which Task 39 DoD line 2254 makes explicit (plan.md L2254):

> `tools/build-plugin.mjs` canonicalizes every `!cat` target path with `fs.realpathSync` (or equivalent) BEFORE reading the target's bytes, and fails non-zero with a `resolves outside repository` diagnostic when the canonical path is not lexically prefixed by the canonical `$REPO_ROOT/`. This closes a symlink-escape exfiltration surface where a checked-in `skills/<dir>/<name>.md` symlink could point at `/etc/passwd` or any other path outside the repo and have its contents inlined into a shipped `build/` file. **The guard mirrors T21's `assert_path_under_repo_root <label> <abs-path>` shape from `scripts/dispatch-agent.sh`** (see Task 21 Definition of done — both guards canonicalize with `realpath` / `readlink -f` and reject canonical targets outside canonical `$REPO_ROOT/`).

The plan body itself names the parallel to T21. T39 also carries a per-task regression test for it (plan.md L2269, "Symlink-escape regression"). Yet AC #2 enumerates T21's guard and not T39's, despite their being functionally equivalent fail-loud halts that defend the same exfil class (out-of-repo content inlined into a sanctioned channel).

### Why omission matters at the release boundary

`tools/build-plugin.mjs` is the supply-chain producer — its output `build/` is what every host (Claude Code, Copilot CLI, future Codex CLI) actually loads. A regression that drops `fs.realpathSync` canonicalization (e.g., a future refactor that switches to `path.resolve` only, or a perf-motivated rewrite that skips the boundary check on already-existing files) would:

- Allow any committed-in or maliciously-PR'd symlink under `skills/` whose `!cat` directive references it to inline arbitrary host-side content (`/etc/passwd`, `~/.ssh/`, dotfile secrets, sibling-repo source, etc.) into the shipped plugin tree.
- Ship green through CI because the build itself would still produce a `build/` tree and `git diff --exit-code` would still be empty against the (now-poisoned) committed `build/`.
- Land on every installed host's disk via the marketplace `qrspi` plugin source flip to `./build` (T39 DoD).

This is the same supply-chain exfil class as T21's `dispatch-agent.sh` guard (out-of-repo file content reaching a sanctioned LLM channel), one altitude up: T21 protects per-dispatch reads, T39 protects the build-time inline that defines the runtime contract of every host install.

The leading clause "Every fail-loud invariant in the release fires loud on a seeded regression input" applies, and the asymmetry with T21 (in) vs T39 (out) is internally inconsistent given the plan body's explicit "mirrors T21" rationale.

### What other release-introduced fail-loud invariants remain unenumerated (lower-severity, noted for completeness, not the load-bearing claim)

These are noted so the Plan author can decide whether they belong in AC #2 alongside T39's guard, or whether the gate is intentionally limited to security-critical and apply-fix-pipeline invariants:

- **T20 third-party-finding-splitter additional halt causes**: "missing flags, missing raw output, missing boundaries, or write errors" (plan.md L1203). "Adversarial Codex stdout" in AC #2 likely covers boundary malformation, but missing-flags and write-error failure modes are distinct orchestration halts.
- **T34 missing-header and malformed-header halts** (plan.md L1952–1953, distinct exact diagnostics from the mismatch case AC #2 already enumerates). The pre-G5 migration file and corrupted-header cases are separate halt causes.
- **T12/T13 `round-prepare.sh` SHA validation halts** (exit 10 partial commit provenance, exit 11 worktree HEAD mismatch, exit 12 unadvanced commit; plan.md L761, L827). Exit 11 in particular is review-integrity-relevant: a HEAD-mismatch halt prevents reviewing against the wrong tree.

These secondary items are tier-2; the T39 build-resolver canonicalization guard is the load-bearing security finding of this round.

### Suggested fix (Plan-altitude)

Extend AC #2's operative enumeration with one additional bullet for T39's guard. Suggested wording (mirrors the existing T21 phrasing for symmetry):

> ... and the path-filter exfil guard in `scripts/dispatch-agent.sh` each produce non-zero exit with a diagnostic, **plus `tools/build-plugin.mjs` rejects any `!cat` target whose canonical path resolves outside canonical `$REPO_ROOT/` with a `resolves outside repository` diagnostic before any byte of the target enters the `build/` tree,** never silent fallback.

This is a one-sentence extension that preserves the universal-quantified leading clause, makes the supply-chain build-time exfil surface visible at the release gate, and matches the per-task DoD that already exists. Without it, the round-04 fix's stated goal — making AC #2's universal claim match its enumeration — remains incomplete for the most security-critical invariant in the build pipeline.
<!-- @@SCORE: security-claude.finding-F01.score @@ -->
score: 62
reason: Real Plan-altitude internal consistency gap — AC #2 enumerates T21's path-canonicalization guard but omits T39's structurally-identical guard that plan.md L2254 itself says "mirrors T21"; impact tempered because T39 DoD and L2269 regression test already enforce it per-task.
<!-- @@FINDING: security-codex.finding-F01 @@ -->
---
finding_id: R5-F01
reviewer_tag: security-codex
round: 5
artifact: plan.md
severity: high
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/plan.md
  - docs/qrspi/2026-05-30-v072-release/design.md
---

# Probe-failure silent downgrade to single-review (fail-open)

## What the plan says

The plan preserves a fail-open default for second-review coverage: on probe failure, Goals/using-qrspi writes `second_reviewer: false` and continues (`plan.md` line 1119; mirrored in design D3 line 2182 "skip silently"). That means any probe breakage/transient host-detect failure can silently disable dual-review instead of forcing an explicit operator decision.

## Why it matters

This bypasses the intended fail-loud security posture that exists only when `second_reviewer: true` reaches dispatch (`plan.md` lines 1138, 1149; design lines 2189-2190). In practice, an attacker or bad environment state only needs to force probe non-zero once to downgrade review depth with no halt, no prompt, and no AC gate explicitly requiring "probe failure must halt or require explicit override."

## Suggested fix

Either:
(a) Require probe failure to prompt the operator (set `second_reviewer: false` only after acknowledgement), and add an AC bullet exercising the prompt path; OR
(b) Document explicitly in design.md ## G27 / D3 that probe-failure silent skip is an accepted trade-off, and add an AC bullet asserting the probe-failure → `second_reviewer: false` path is intentional and operator-visible via a single stderr diagnostic at probe time.

Resolution requires a Design-level decision (D3 is the source-of-truth), so this may warrant a backward loop to Design rather than a Plan-only patch.
<!-- @@SCORE: security-codex.finding-F01.score @@ -->
score: 22
reason: Altitude mismatch (Plan reviewer flagging a documented Design D3 decision); the probe-failure → `second_reviewer:false` path is intentional per D3, the stderr `[second-reviewer-unavailable]` diagnostic is already required by plan line 1134, and D4 enforces a loud halt at dispatch time if a `true` value is hand-edited in — so the proposed "fix (b)" is substantively already met and "fix (a)" contradicts a recorded design posture.
<!-- @@FINDING: test-coverage-codex.finding-F01 @@ -->
---
finding_id: R5-F01
reviewer_tag: test-coverage-codex
round: 5
artifact: plan.md
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/plan.md
---

# T16 scope claims dispatch-order preservation but Test Expectations include no ordering assertion

## What

Task 16 scope (plan.md line 990) requires preserving the TDD dispatch order (test-writer first, implementer second after RED verification). The Test Expectations block (lines 1013-1023) covers routing precedence, none-tier halt, same-vendor halt, schema validation, tier sweep, and co-escalation, but no ordering check.

## Why it matters

Scope explicitly requires order preservation at line 990. If the order can silently regress (e.g., dispatch refactor accidentally reverses), no test in the plan would catch it. A test-writer-after-implementer order defeats TDD (the implementer would write code against no failing test).

## Suggested fix

Add a Task 16 test expectation that asserts dispatch sequencing remains test-writer-before-implementer with the RED gate in between (e.g., via a targeted unit/integration fixture over the implement dispatch flow).
<!-- @@SCORE: test-coverage-codex.finding-F01.score @@ -->
score: 35
reason: Real gap between scope's order-preservation clause and Test Expectations, but T16 is a routing-schema migration that does not touch dispatch sequencing (governed by Implement/Test skills with existing tests); co-escalation (the routing-relevant half of the contract) is already covered at line 1022, so an explicit ordering test is a nice-to-have non-regression net rather than a load-bearing omission.
<!-- @@CLEAN: goal-traceability-claude.clean @@ -->
---
reviewer: goal-traceability-claude
artifact: plan.md
round: 05
ref: main (broaden)
verdict: clean
---

# Goal Traceability Review — plan.md round 05 (broaden vs main)

## Summary

Zero findings. Bidirectional traceability is complete across all 35 approved goals (G1–G35), 38 tasks, and the seven vertical slices. The Overview's absorbed-goal narrative for G24/G25/G26/G29 matches design.md dispositions verbatim. Every task carries a goal-ID tag and References block citing both goals.md and design.md (or design.md cross-goal decisions CD-1/CD-2/CD-3/CD-4 motivated by named goals).

## Forward trace (goal → task)

All 35 goals covered:

| Goal | Disposition | Covering task(s) |
|---|---|---|
| G1 | implemented | T30 (Design decision-completeness template); ride-along context in T28 |
| G2 | implemented | T33 |
| G3 | implemented | T11 (CD-1 manifest provenance — round-02 relabel), T20 (rename + dispatch prose migration) |
| G4 | implemented | T12 (round-prepare.sh + await-round.sh + anchors) |
| G5 | implemented | T34 (post-approval split idempotency) |
| G6 | implemented | T03 (reviewer disk-write contract); supported by T24 (CD-4 interaction-mode helper) |
| G7 | implemented | T01 (verifier-filter-rule shared snippet) |
| G8 | implemented | T04 (change_type frontmatter) |
| G9 | implemented | T13 (per-task review orchestration) |
| G10 | implemented | T35 (anti-fabrication rule) |
| G11 | implemented | T06 (sidecar extension lock); supported by T24 |
| G12 | implemented | T02 (verifier-fan-in script); supported by T24 |
| G13 | implemented | T05 (change_type enum drift hardening) |
| G14 | implemented | T07 (Informational-rubric carve-out) |
| G15 | implemented | T14 (sweep-task contract) |
| G16 | implemented | T21 (dispatch-agent path-filter exfil guard) |
| G17 | implemented | T36 (stale prose cleanup) |
| G18 | implemented | T15 (cross-task consumer surface) |
| G19 | implemented | T08 (wholesale-hallucination rubric class) |
| G20 | implemented | T09 (reviewer-model calibration; actual_model provenance) |
| G21 | implemented | T40 (body-assertion-guard lint, incl. G26 BW02 rule) |
| G22 | implemented | T16 (model_routing schema + agent-sweep migration) |
| G23 | implemented | T17 (validation-table row + cross-links) |
| G24 | F05-only via T44; F01/F03/F04 moot per design.md L2062–L2064; F02 absorbed by G25 | T44 |
| G25 | absorbed by CD-1 (none-tier halt smoke test rides on CD-1; ships in T16 acceptance) | gap 18 (documented absorption) |
| G26 | runtime fix predates v0.7.2 (`tests/unit/test-codex-splitter.bats:8` already declares `bats_require_minimum_version 1.5.0`); BW02-guard regression-prevention rides on T40 | gap 41 (documented absorption) |
| G27 | implemented | T19 (`second-reviewer-available.sh` + `_host-detect.sh` + Goals consumer migration) |
| G28 | implemented | T10 (convergent-evidence exception + sub-threshold instrumentation) |
| G29 | absorbed by CD-1 (off-LLM prompt assembly; orchestrator tool-call args never carry artifact body); T11 repurposed to [G3] CD-1 manifest provenance | gap (T11 relabel) |
| G30 | implemented | T32 (Goals + Design incremental persistence + dialogue conduct mirror) |
| G31 | implemented | T25 (primitives — three shared snippets + two wrapper SKILLs + rules-file migration), T26 (Design/Plan/agent include sites) |
| G32 | implemented | T39 (plugin build pipeline) |
| G33 | implemented | T31 (Design simple-language Rule 5) |
| G34 | implemented | T29 (`design-altitude-boundary` primitive + scope-reviewer + owns-defers) |
| G35 | implemented | T37 (Structure absorbs unified architecture), T38 (Structure reviewer enforcement) |

## Backward trace (task → goal)

All 38 tasks (T01–T17, T19–T21, T24–T40, T44; gaps at T18/T22/T23/T41/T42/T43 preserved) carry:
- A `Goal IDs:` line citing at least one approved goal in goals.md.
- A References block citing both `goals.md ### Gxx` and `design.md ## Gxx` (or `design.md ### CD-N` for cross-goal-decision-derived work).

No task lacks upstream traceability.

## Absorbed-goal narrative cross-check (Overview ↔ design.md)

Verified each absorption claim in the plan Overview (L17) against the matching design.md disposition section:

- **G24** (gap 22 = F02 → G25; gap 23 = F03 moot; gap 42 = F01 moot; gap 43 = F04 moot; F05 → T44): matches `design.md ## G24` L2050–L2080. F02 "defers to G25" is concrete in design.md L2065; F01 "Helper and target test files do not exist in current tree" L2062; F03 "Helper exists in exactly one file" L2063; F04 "regex no longer present at meaningful volume" L2064. ✓
- **G25** (gap 18, absorbed by CD-1, no separate task): matches `design.md ## G25` L2082–L2119. Executable enforcement (`none`-tier halt smoke test) is added as a CD-1 acceptance criterion per L2096; ships in T16 acceptance per the plan's T16 Test expectations. ✓
- **G26** (gap 41, runtime concern already fixed pre-v0.7.2; BW02 lint rides on G21/T40): matches `design.md ## G26` L2123–L2162. Premise inversion per L2129–L2131; existing `bats_require_minimum_version 1.5.0` at `tests/unit/test-codex-splitter.bats:8` per L2131; BW02-guard amendment to G21 lint per L2139. T40's Goal IDs `[G21, G26]` correctly carries both surfaces. ✓
- **G29** (absorbed by CD-1; T11 repurposed [G29]→[G3]): matches `design.md ## G29` L2308–L2323. Orchestrator's tool-call args never carry artifact body under CD-1's PROMPT_FILE shape; G29 candidates target a contract surface CD-1 deletes. T11's References block correctly cites both `design.md ## CD-1 → "Dispatch manifest schema"` and `design.md ## G29` (the absorbed-disposition lock). ✓

## Per-phase acceptance block (`### Phase 1 Acceptance Criteria`) coverage

The seven-bullet per-phase block authors cross-task observable behavior at phase boundary. Cross-mapped to goals:

- Bullet 1 (end-to-end pipeline) → G6/G9/G11/G12/G27/G3.
- Bullet 2 (fail-loud invariants — 10 named hooks) → G3/G22/G23/CD-1/G27/G5/G12/G13/G11/G8/G10/G16.
- Bullet 3 (apply-fix sub-threshold + dispositions; wholesale-hallucination) → G28/G19/G20.
- Bullet 4 (plugin build pipeline) → G32.
- Bullet 5 (bats hardening) → G21/G26/G24.
- Bullet 6 (issue closures) → release-level gate covering all 35 goals.
- Bullet 7 (release PR) → release-level gate.

Goals not surfaced in the per-phase block (G1, G2, G4, G7, G14, G15, G17, G18, G29, G30, G31, G33, G34, G35) are covered by per-task `## Test Expectations` blocks per the trailing parenthetical at L35. This conforms to the strip-from-goals contract: per-phase block carries cross-task observable behavior only; per-task blocks carry per-task acceptance criteria.

## Design-to-plan fidelity

Plan's slice structure (1.1–1.7) and the four-surface narrative (apply-fix / verifier backbone; per-task review pipeline; dispatch infrastructure; skill-prose/structural/build hardening) align with design.md's cross-goal-decision clusters CD-1/CD-2/CD-3/CD-4 and the per-goal solution blocks. All design.md cross-goal decisions have a landing task: CD-1 → T11+T16+T19+T20+T21; CD-2 → T27; CD-3 → T28; CD-4 → T02+T06+T24. No design commitment is orphaned.

## Decomposition check

Each goal's per-task work decomposes from the goal's problem framing in goals.md without leakage. The G31 plumbing split (T25 primitives → T26 consumer sites) decomposes cleanly from G31's "wide drift surface" framing. The G3 split (T11 manifest provenance + T20 rename collapse) decomposes from G3's "shell-pipeline splitter collapse + sanctioned-channel persistence" framing. The G35 split (T37 absorb + T38 reviewer enforcement) decomposes from G35's "Authoring gap + Reviewer false-positives" two-pronged framing.

## Verdict

Clean. No findings to file in round 05.
<!-- @@CLEAN: goal-traceability-codex.clean @@ -->
---
reviewer_tag: goal-traceability-codex
round: 5
findings: 0
---

# Clean — no findings in round 05
<!-- @@CLEAN: scope-claude.clean @@ -->
---
reviewer: scope-claude
artifact: plan.md
round: 05
ref: main
status: clean
---

# Scope review — clean

Applied the 3-check OWNS/DEFERS procedure against plan.md (2,402 lines, 38 task specs across 7 slices) on round-05 broaden vs `main`.

## Check 1 — Boundary-drift detection: clean

No content crosses into Plan DEFERS territory:

- **No Structure-altitude function signatures.** T39 DoD (line 2260) names `fs.realpathSync` as a canonicalization primitive but explicitly hedges with "(or equivalent)" and frames the behavior at observable altitude ("canonicalizes... BEFORE reading the target's bytes... fails non-zero with a `resolves outside repository` diagnostic"). No parenthesized parameter lists or return-type arrows defining project functions.
- **No Implement-TDD-altitude assertion code.** Test Expectations blocks across all 38 tasks use plain language ("Grep audit confirms…", "Bats fixture verifies…", "Acceptance assertions confirm…"). The exact diagnostic strings in T34 (lines 1957–1958, 1971–1973), T19 (`[second-reviewer-unavailable]`), T20 (`JOB_ID=<id>`), and T21 (`resolves outside repository`) are locked design payload being pinned as observable behavior — not `expect(...)` / `assert.` / `toBe()` test code.
- **No Implement-altitude algorithm logic.** No `if/else`/`for`/`while`/line-numbered walkthroughs in any task spec. Behavioral specifications stay at "what" altitude, not "how".
- **No Design-altitude rationale.** Tasks consistently route rationale upstream via "(Why: see goals.md ### GNN. Approach: see design.md ## GNN.)" headers. No "trade-off", "we considered", or "alternative approach" prose.
- **No Phasing-altitude forward references.** Deferrals point to "v0.7.3+" with a one-line reason (consistent with Phasing's ownership of phase boundaries); no "phase 2 will…" roadmap re-authoring.

## Check 2 — Scope compliance per OWNS: clean

All four Plan OWNS concerns are present and well-formed:

- **Ordered task specs:** 38 tasks numbered 1–44 (sparse), with gap dispositions (18/22/23/41/42/43) and the T11 round-02 relabel both explained inline in the Overview. Slice 1.1–1.7 carve corresponds to the four-surface coherence described in design.md.
- **Test expectations in plain language:** every task carries a `**Test expectations**` bullet list, plain-language only.
- **Dependencies:** every task declares `Dependencies: none` or `[Task NN]` and `Blocks: [...]`. Cross-slice forward dep (Slice 1.4 T12 → Slice 1.3 T13) is documented in the Dependency Graph section with explicit ordering rationale; no implicit forward deps.
- **LOC estimates:** every task carries `~N` (60–360 range). The four oversize tasks (T12 ~280, T16 ~320, T19 ~210, T20 ~260, T25 ~340, T39 ~360) each carry `**Sizing exception:** {reusable primitives | schema-migration | CI scaffolding}` per the closed exception vocabulary in T33.

Aggregate length 2,402 lines sits inside the 1000–2000 soft band's upper neighborhood for a 38-task release (~63 lines per task, slightly above the 52-line average — acceptable given the cross-cutting/migration density of this release).

## Check 3 — Lexical leakage: clean

Heuristic scan for the five trigger patterns returned no hits:

- Parenthesized function signatures with named params and return arrows: absent.
- `expect(`, `assert.`, `assertEqual`, `toBe(` in Test Expectations: absent.
- `if/else`/`for`/`while` line-by-line logic: absent.
- "trade-off"/"we considered"/"alternative approach" in task descriptions: absent.
- "phase 2 will"/"future phases" roadmap-style forward refs: absent (only deferral-pointer mentions of "v0.7.3+", which is Plan DEFERS→Phasing handled correctly).

## Result

No findings emitted. plan.md respects the Plan OWNS / Plan DEFERS boundary on round-05 broaden vs `main`.
<!-- @@CLEAN: scope-codex.clean @@ -->
---
reviewer_tag: scope-codex
round: 5
findings: 0
---

# Clean — no findings in round 05
<!-- @@CLEAN: silent-failure-claude.clean @@ -->
---
reviewer_tag: silent-failure-claude
round: 05
artifact: plan.md
verdict: clean
---

# Silent-Failure Hunter — Plan Round 05 (broaden vs main)

No silent-failure findings.

## Audit summary

The round-04 fix for the orphaned `[second-reviewer-same-vendor]` invariant is solid:

- **T16 DoD line 1002** names the `_resolve-lib.sh` halt with the exact `[second-reviewer-same-vendor]` diagnostic and the "never silently emits two dispatch spec lines" negative clause.
- **T16 Test expectations line 1016** asserts the same-vendor fixture halts and emits no spec lines for the round.
- **T19 Out section line 1127** carries a positive ownership pointer at T16's `_resolve-lib.sh` matrix lookup (not vague "dispatch-time code"), and clarifies the probe checks reachability only, not slot distinctness.
- **AC #2 line 28** enumeration includes the new halt alongside the other fail-loud invariants.

## AC #2 fail-loud invariant ownership audit

Every fail-loud invariant enumerated in AC #2 has named DoD ownership and matching test expectations in a single task:

| Invariant | Owner | DoD line |
|---|---|---|
| splitter on adversarial third-party stdout | T20 | 1203 |
| dispatch on misrouted `model_routing` | T16 | 1001 |
| validation table on missing `model_routing:` | T17 | 1079 |
| `_resolve-lib.sh` halt on `tier: none` | T16 | 1001 |
| `_resolve-lib.sh` `[second-reviewer-same-vendor]` halt | T16 | 1002 |
| `second-reviewer-available.sh` `[second-reviewer-unavailable]` halt | T19 | 1134, 1138 |
| `plan.md` post-approval split block-hash-mismatch halt | T34 | 1950, 1965 |
| `verifier-fan-in.sh` halt for each malformation cause | T02 + T05 | 206, 370 |
| reviewer-protocol vs fabricated procedural-authority | T35 | 2015 |
| path-filter exfil guard in `dispatch-agent.sh` | T21 | 1253 |

## Categories swept

- **Swallowed errors:** none. Tasks consistently specify non-zero exits, named diagnostics, and audit-record causes.
- **Silent fallbacks:** none survives. T19 line 1138 explicitly rejects "silently falling back to single-reviewer dispatch"; T16 line 1001 explicitly rejects silently falling back to a neighboring tier; T44 hardens four silent-fallback prose pins with regex coverage. The T16 precedence-chain terminal "hardcoded `medium` with loud warning" (line 986) is unreachable under valid inputs because T16 DoD line 1004 enforces every agent carries a `tier:` field at test time, and the "loud warning" provides operator visibility for the defense-in-depth corruption case — not a designed silent fallback.
- **Partial state on failure:** T11 manifest writes are atomic + append-safe (line 709); T34 mismatch halt leaves existing file untouched (line 1950); T20 `.dispatch/` cleanup gated on completion (line 1187); T39 symlink-escape regression mirrors T21 path-canonicalization (lines 2254, 2269).
- **Log-and-continue:** none. The recurring pattern across the plan is halt + diagnostic + audit-record, with `await-round.sh`'s payload-silent terminal output (T12 line 767, T20 line 1202) bounded to status summaries.

Clean.
<!-- @@CLEAN: silent-failure-codex.clean @@ -->
---
reviewer_tag: silent-failure-codex
round: 5
findings: 0
---

# Clean — no findings in round 05
<!-- @@CLEAN: spec-claude.clean @@ -->
---
reviewer: spec-claude
round: 5
findings: 0
verdict: clean
---

# Spec Review Round 05 — Clean

No findings. Round-04 surgical edits (AC #2 bullet 2 rewrite, T16 same-vendor halt, T19 Out pointer to T16) integrated cleanly; full-file re-read against `<base-branch>` reconfirms every approved goal is covered by at least one task with a verifiable `## Test Expectations` block.

## Round-04 fix verification

| Round-04 fix | Artifact location | Status |
|---|---|---|
| AC #2 bullet 2 `_resolve-lib.sh` phrasing aligned to design.md ## G25 | plan.md L22 ("when a CD-1 dispatch resolves to a `tier: none` configuration") | ✅ matches design |
| AC #2 bullet 2 enumeration extended with T19 same-vendor + T19 unavailable + T34 block-hash + T02 fan-in halt causes | plan.md L22 (all 4 new invariants present; T02 fan-in enumerates 5 underlying malformations) | ✅ universal-quantified leading clause now matches operative list |
| T16 DoD same-vendor halt | plan.md L1002 | ✅ exact `[second-reviewer-same-vendor]` token, "never silently emits two dispatch spec lines" negative clause present |
| T16 Test expectation same-vendor halt | plan.md L1016 | ✅ fixture description names tag + emits-no-spec-lines observable |
| T19 Out distinctness ownership pointer | plan.md L1127 | ✅ positive ownership pointer at T16 ("Task 16's `_resolve-lib.sh` matrix lookup owns the `[second-reviewer-same-vendor]` halt at resolve time"); probe-vs-resolver boundary stated explicitly |

## Goal coverage (re-verified, full-file)

All 35 approved goals trace either to a standalone task or to an explicit absorbed-by-CD-N disposition documented in the Overview:

- **33 directly-owned**: G1 (T30), G2 (T33), G3 (T11+T20), G4 (T12), G5 (T34), G6 (T03), G7 (T01), G8 (T04), G9 (T13), G10 (T35), G11 (T06), G12 (T02), G13 (T05), G14 (T07), G15 (T14), G16 (T21), G17 (T36), G18 (T15), G19 (T08), G20 (T09), G21 (T40), G22 (T16), G23 (T17), G24 (T44 owns F05; F01–F04 dispositions documented), G26 (T40, BW02 rule rides on G21), G27 (T19), G28 (T10), G30 (T32), G31 (T25+T26), G32 (T39), G33 (T31), G34 (T29), G35 (T37+T38).
- **2 absorbed by CD-1**: G25 (Overview L11 gap-18), G29 (Overview L11 explicit absorption note — T11 repurposed to G3).

Slice tallies: 1.1=7, 1.2=4, 1.3=3, 1.4=7, 1.5=12, 1.6=2, 1.7=3 = **38 tasks** matching Overview's "38 tasks (task numbers 1–44 with gaps at 18, 22, 23, 41, 42, 43)".

## Test Expectations presence (re-verified, full-file)

Every one of the 38 task specs carries a non-vague `**Test expectations**` block with concrete grep targets, file paths, bats fixtures, or observable diagnostics. No `TBD` / `TODO` / `see Task N` / `appropriate handling` placeholders introduced or re-introduced.

## Sizing exceptions (re-verified)

All tasks >200 LOC carry the explicit closed-set exception: T12 (~280, reusable primitives), T16 (~320, schema-migration), T19 (~210, reusable primitives), T20 (~260, reusable primitives), T25 (~340, reusable primitives), T39 (~360, CI scaffolding). No bundling violation; no exception value outside the closed set {schema-migration, CI scaffolding, reusable primitives}.

## Verdict

Round-04 fixes integrated cleanly. Plan continues to cover every approved goal with verifiable per-task Test Expectations and per-phase Acceptance Criteria whose enumeration now matches its universal-quantified leading clause. No spec-level findings.
<!-- @@CLEAN: spec-codex.clean @@ -->
---
reviewer_tag: spec-codex
round: 5
findings: 0
---

# Clean — no findings in round 05
<!-- @@CLEAN: test-coverage-claude.clean @@ -->
---
reviewer_tag: test-coverage-claude
round: 5
artifact: plan.md
verdict: clean
---

# Test Coverage Reviewer — Clean Sentinel

Round 05 (broaden vs main) review of `plan.md` finds **no above-threshold test-coverage issues**.

## What I verified

Scanned every task spec (38 tasks: T01–T17, T19–T21, T24–T40, T44) for:

1. **Behavioral coverage** — every happy path has a specific, deterministic test expectation naming the observable result (exit code, written file path, exact diagnostic string, frontmatter field, etc.). Lightweight prompt-prose tasks (T25, T26, T28, T29, T30, T31, T36, T37, T38) appropriately scope expectations to grep audits plus rules-application review consistent with the project's non-TDD prompt-prose contract.

2. **Edge cases** — tasks operating on data/collections enumerate boundaries:
   - T02/T05 cover the five fan-in malformation classes plus all five canonical `change_type` values
   - T12 covers eight convergence cases, three distinct exit codes (10/11/12), prior-round validation, backward-loop flag, non-git workspace
   - T16 covers tier-`none`, same-vendor (round-04 add), missing/malformed config; T19 covers unknown host, missing default vendor, unknown vendor, unavailable vendor
   - T34 covers absent/matching/mismatching/missing-header/malformed-header with **verbatim** diagnostic strings
   - T39 covers malformed `!cat`, missing target, cycles, absolute paths, traversal, outside-root, and symlink-escape (named diagnostic phrase)

3. **Error conditions** — every fail-loud invariant from Phase 1 AC #2 (line 22) maps to a task with a specific exit/diagnostic expectation:
   - splitter→T20, `model_routing` misroute→T16, missing `model_routing:` validation→T17, tier-`none` halt→T16, `[second-reviewer-same-vendor]` halt→T16 (test at line 1016), `[second-reviewer-unavailable]` halt→T19, block-hash mismatch→T34, fan-in halts (5 causes)→T02/T05, reviewer-protocol fabrication→T35, dispatch-agent path-filter→T21. All mappings verified present.

4. **Test expectation quality** — no vague "handles appropriately" / "works correctly" / "similar to Task N" patterns found. Where R1-R7 prompt-prose rules-application substitutes for executable assertions on lightweight tasks, expectations name specific anchor phrases, structural ordering, and absence claims that a grep-based test can pin.

## Round-04 dropped findings — re-checked

- **tc-claude.F01** (T38 mental-replay clarity 45, dropped sub-threshold): Re-checked the test expectation at plan.md line 2193. The fixture properties are specific (unified architecture Mermaid diagram + top-level `## Test Architecture` section + per-goal/per-CD acceptance stitching by test type). A test-writer can derive a fixture from this description. Clarity is moderate but the expectation is not unverifiable. Holds at sub-threshold; not refiling.
- **tc-claude.F02** (AC #2 wrong task mapping, closed by qty-claude.F01 convergent fix in round 04): Spot-check above confirms AC #2 bullet 2 now correctly enumerates the surfaces that each invariant lives in. Resolved.

## Convergence outside hint

No `scope_hint` was provided (broaden-vs-main round). Full-plan scan; no findings outside any narrowed surface that would force broadening next round — because nothing was narrowed and nothing else is findable.

## No findings to file

Plan-altitude test expectations meet the bar the Test phase needs to author acceptance tests deterministically.
