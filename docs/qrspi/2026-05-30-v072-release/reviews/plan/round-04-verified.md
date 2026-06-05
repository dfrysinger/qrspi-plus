---
verifier_enabled: true
scored: 8
kept: 3
dropped: 5
failed: 0
clean: 8
---

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

# Phase 1 Acceptance bullet 2 specifies a `_resolve-lib.sh` halt condition that no task delivers

## What

Phase 1 Acceptance Criteria bullet 2 (plan.md L28) reads:

> ... `_resolve-lib.sh` halt when CD-1 dispatch resolves `tier: none` **against an unknown vendor** ...

The "against an unknown vendor" qualifier names a halt condition (tier=none AND vendor=unknown) that is not pinned by any task in the plan. The actual halt contract authored by Task 16 (G22) and locked by design.md ## G25 / CD-1 is narrower: halt when the resolved tier itself is configured as `none`, regardless of vendor.

Evidence:

- Task 16 Definition of done (plan.md L1007): "`_resolve-lib.sh` resolves tiers in the specified precedence order and **halts loudly when the selected tier is configured as `none`**; it never silently falls back to a neighboring tier or agent-bundled model."
- Task 16 Test expectations (plan.md L1020): "Verify a dispatch resolving to a tier configured as `none` halts with a diagnostic naming the unresolved tier and does not fall back." — no "unknown vendor" leg.
- design.md ## G25 absorption (L2090): "an agent dispatch that resolves to a `none` tier halts with a loud diagnostic (no silent fallback to a neighboring tier)." — single condition, no vendor leg.
- design.md ## G25 #2 (L2096): the executable counterpart is "A single bats smoke test exercising a **tier-resolved-to-`none`** dispatch (asserting the dispatcher halts with a loud diagnostic)" — again single condition.

## Why it matters

This is the canonical Plan-altitude consistency contract: every per-phase acceptance bullet must trace to a task deliverable that the Test phase can verify. The "against an unknown vendor" phrasing in bullet 2 has two failure modes when read literally by a downstream consumer:

1. **Test-phase author writes the wrong fixture.** A Test-phase author trying to honor bullet 2 literally will construct an "unknown vendor + tier=none" fixture, which is a different code path than what T16 actually delivers (the resolver halts on tier=none regardless of vendor identity). If "unknown vendor" routes through a separate code path that doesn't reach the tier-none check, the constructed fixture might pass without exercising the real halt — re-introducing the silent-pass class the bullet exists to prevent.
2. **Reviewer at Test phase can't tell whether the bullet is met.** If the only fixture is T16's "tier=none halts" test (which doesn't vary vendor known/unknown), the literal reading of bullet 2 is unsatisfied. If a separate unknown-vendor fixture is added, it has no task spec to anchor against.

Round-03's edit to this bullet replaced an older orphaned reference to a deleted top-level dispatch-routing paragraph. The replacement landed correctly in shape (it now names the surviving T16 deliverable) but the "against an unknown vendor" qualifier was added that doesn't match any task's actual scope.

## Suggested fix

Drop the unsupported vendor qualifier so the bullet matches T16's actual halt contract:

**Before (plan.md L28):**
```
`_resolve-lib.sh` halt when CD-1 dispatch resolves `tier: none` against an unknown vendor
```

**After:**
```
`_resolve-lib.sh` halt when a CD-1 dispatch resolves to a `tier: none` configuration
```

This matches design.md ## G25 L2090 and L2096 verbatim phrasing, and the T16 Definition of done at plan.md L1007. No other edits needed — T16 already owns the deliverable and the test fixture.
<!-- @@SCORE: quality-claude.finding-F01.score @@ -->
score: 70
reason: Verified — plan.md L28 "against an unknown vendor" qualifier is absent from design.md G25 (L2090/L2096) and T16's DoD/Test Expectations (L1001/L1014), creating a real Plan-altitude traceability gap between the phase acceptance bullet and the only task delivering the halt; fix is surgical and well-scoped.
<!-- @@FINDING: quality-claude.finding-F02 @@ -->
---
finding_id: F02
severity: low
change_type: clarity
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/plan.md
artifact: docs/qrspi/2026-05-30-v072-release/plan.md
---

# Dep-graph item 4 and Task 13 `Blocks:` both misidentify the surface T20 consumes from T13

## What

Two adjacent rationale surfaces in the plan claim that Task 20's G3 splitter rename consumes Task 13's `scripts/round-prepare.sh` edits. T20 does not in fact modify or reference `scripts/round-prepare.sh`; the real shared edit surface forcing T13 → T20 is `skills/implement/SKILL.md`, which both tasks modify.

Evidence:

1. **Overview cross-slice chain (plan.md L17, chain (b)):**
   > T13's per-task round-prepare edits all land before T20's G3 splitter rename (T09/T11/T13 → T20), so the pre-rename dispatch surface is fully provisioned before the script hard-rename collapses it.

   And dep-graph item 4 (plan.md L112):
   > T09, T11, and T13 all modify the pre-rename dispatch surface (`scripts/run-codex-review.sh` for T09/T11; **`scripts/round-prepare.sh` for T13**)

2. **Task 13 `Blocks:` clause (plan.md L808):**
   > **Blocks:** T20 (G3 dispatch-script rename consumes this task's `scripts/round-prepare.sh` per-task scope-tagger + commit-anchor edits).

3. **What T20 actually modifies (plan.md L1176):** T20's target-files list renames `run-codex-review.sh` → `dispatch-agent.sh`, renames `run-third-party-llm.sh` → `dispatch-companion.sh`, renames `codex-finding-splitter.sh` → `third-party-finding-splitter.sh`, modifies `scripts/await-round.sh`, creates `skills/_shared/reviewer-dispatch-prose.md`, and modifies 12 SKILL.md consumers including `skills/implement/SKILL.md`. **It does not touch `scripts/round-prepare.sh`.**

4. **What T13 actually modifies (plan.md L807):** `scripts/round-prepare.sh`, `skills/implement/SKILL.md`, `tests/unit/test-scope-tagger-dispatch.bats`.

The overlap surface that forces T13 to land before T20 is `skills/implement/SKILL.md`: T13 inserts the G9 between-round checklist into the per-task reviewer fan-out section, and T20's 12-skill consumer migration replaces the per-skill dispatch block in the same file. If T20 lands first, T13's insertion-site language drifts; if T13 lands first, T20 migrates against the post-G9 surface.

(The neighboring claim in chain (b) that T09 and T11 modify `scripts/run-codex-review.sh` is correct — both edit the pre-rename file. The bug is specifically the `scripts/round-prepare.sh` citation for T13.)

## Why it matters

The dep is correct and load-bearing — T13 truly must precede T20. The rationale is what's wrong, in two places that mirror each other (Overview narrative + Task 13's `Blocks:` clause). At Plan altitude this matters because:

1. **A reader auditing the dep graph traces the wrong file.** Anyone validating the T13 → T20 dependency by grepping the round-prepare.sh diff between the two task commits will find no overlap and conclude the dep is spurious — potentially removing it and reintroducing the real `skills/implement/SKILL.md` merge conflict.
2. **The mis-citation undermines round-03's cross-slice-chain edit.** Round-03 added the T09/T11/T13 → T20 chain to the Overview specifically to make the pre-rename surface story explicit. Including a wrong file citation in that chain weakens the audit trail it exists to provide.

## Suggested fix

Two coupled edits:

**1. Plan Overview L17 chain (b)** — change the parenthetical for T13:

Before:
```
T09's `actual_model:` provenance edits and T13's per-task round-prepare edits all land before T20's G3 splitter rename
```

After:
```
T09's `actual_model:` provenance edits and T13's per-task `skills/implement/SKILL.md` between-round checklist edits all land before T20's G3 splitter rename
```

**2. Plan Dep-Graph item 4 (L112)** — correct the file citation:

Before:
```
T09, T11, and T13 all modify the pre-rename dispatch surface (`scripts/run-codex-review.sh` for T09/T11; `scripts/round-prepare.sh` for T13)
```

After:
```
T09 and T11 modify the pre-rename dispatch surface `scripts/run-codex-review.sh`; T13 modifies `skills/implement/SKILL.md` at the per-task reviewer fan-out site, which T20's 12-skill consumer migration also rewrites
```

**3. Task 13 `Blocks:` clause (L808)** — match the corrected rationale:

Before:
```
**Blocks:** T20 (G3 dispatch-script rename consumes this task's `scripts/round-prepare.sh` per-task scope-tagger + commit-anchor edits).
```

After:
```
**Blocks:** T20 (G3 dispatch-script rename and 12-skill consumer migration share the `skills/implement/SKILL.md` per-task reviewer fan-out edit surface this task inserts the G9 between-round checklist into).
```

No task target-file changes needed — the dep itself is right, only the explanation text drifts.
<!-- @@SCORE: quality-claude.finding-F02.score @@ -->
score: 60
reason: Verified — T20's target-files list (L1170) does not include scripts/round-prepare.sh, while it does modify skills/implement/SKILL.md (which T13 also edits at L801); the dep-graph item 4 (L106) and Task 13 Blocks clause (L802) both cite the wrong shared surface, so the rationale is genuinely incorrect even though the dep itself is right. Low-severity clarity issue that mainly affects readers auditing the dep graph by grepping file overlap.
<!-- @@FINDING: quality-codex.finding-F01 @@ -->
---
finding_id: R4-F01
reviewer_tag: quality-codex
round: 4
artifact: plan.md
severity: high
change_type: correctness
referenced_files: plan.md (lines 26-27)
---

Phase-acceptance criterion #6 requires that "each of the 35 goal-backing parent issues closes when its backing commits land," but that is no longer true for this release after the locked design dispositions for absorbed/moot goals. In design.md, G25 (#242), G26 (#243), and G29 (#262) are explicitly closed at design lock with no standalone shipping task, so this plan gate encodes an impossible/incorrect closure condition for those goals. At PLAN altitude, acceptance gates must be executable and aligned with upstream locked dispositions; otherwise Test-phase release gating can fail or report false non-compliance even when implementation matches the approved design.
<!-- @@SCORE: quality-codex.finding-F01.score @@ -->
score: 45
reason: Gate text "closes when its backing commits land" is genuinely loose vs. design.md's explicit "close #242/#243/#262 on design lock (not on ship)" for G25/G26/G29, but in practice those issues are already closed before Test-phase gating runs and criterion #7 ("release notes name each goal-backing issue's disposition") covers reporting, so the high-severity correctness framing overstates the actual gating risk.
<!-- @@FINDING: security-claude.finding-F01 @@ -->
---
finding_id: F01
severity: high
change_type: scope
location: plan.md → ### Phase 1 Acceptance Criteria → bullet 2 ("Every fail-loud invariant in the release fires loud on a seeded regression input")
---

## Phase-1 fail-loud acceptance criterion claims exhaustive coverage but enumerates only a subset of the release's fail-loud invariants

### What the plan says

Phase 1 Acceptance Criterion #2 reads (verbatim from plan.md, the round-04 diff):

> **Every fail-loud invariant in the release fires loud on a seeded regression input** — splitter on adversarial Codex stdout, dispatch on misrouted `model_routing` entries, validation table on missing `model_routing:`, `_resolve-lib.sh` halt when CD-1 dispatch resolves `tier: none` against an unknown vendor, reviewer-protocol against fabricated procedural-authority outputs, and the path-filter exfil guard in `scripts/dispatch-agent.sh` each produce non-zero exit with a diagnostic, never silent fallback.

The leading clause is a universal: *"Every fail-loud invariant in the release fires loud on a seeded regression input."* The enumerated list that follows names six invariants: splitter (T20), dispatch model_routing (T16), validation table (T17), `_resolve-lib.sh` `tier: none` halt (T16), reviewer-protocol anti-fabrication (T35), and `dispatch-agent.sh` path-filter exfil (T21).

### Why this is a Plan-altitude security concern, not an Implement-altitude test request

The release introduces several other fail-loud invariants whose per-task DoD or Test Expectations require non-zero exit + diagnostic on a documented failure class, but which are **not** enumerated under this phase-level gate. The gate's leading clause is universal-quantified ("Every fail-loud invariant"), so a regression that breaks an unenumerated invariant between commits would land green at the phase-acceptance boundary because no operative bullet asks the Test phase to seed and exercise that regression. Per-task tests still exist, but the phase gate is the cross-task release boundary that catches regressions introduced *by other tasks* into a shared script — exactly the integration window where these invariants are most likely to silently regress.

This is a Plan-altitude scope concern (the release-gate enumeration is non-exhaustive given its universal-quantified framing), not an Implement-altitude test detail request. The fix is to either narrow the leading clause (e.g., "The following fail-loud invariants fire loud on seeded regression inputs:") or extend the enumeration to cover the invariants below — both are Plan-author decisions about what the phase boundary gates.

### Unenumerated fail-loud invariants visible in the round-04 diff

At least three release-introduced fail-loud invariants are missing from the gate enumeration:

1. **T19 / G27 `[second-reviewer-unavailable]` halt at dispatch time.** Task 19's DoD requires the dispatch-time resolver to halt with `[second-reviewer-unavailable]` "instead of silently falling back to single-reviewer dispatch" when `second_reviewer: true` but no eligible second-reviewer vendor resolves. This is a security-relevant fail-loud invariant — silent degradation defeats the whole point of `second_reviewer: true` (two-model review redundancy). A T20 dispatch-rename regression or a `_resolve-lib.sh` refactor in a later task could silently restore single-reviewer fall-through; the phase gate as written would not catch it.

2. **T34 / G5 post-approval split block-hash mismatch halt.** Task 34's DoD requires `plan.md` post-approval split to halt loudly when a present per-task file's `# block-hash:` header no longer matches the normalized source block. This protects against Implementation silently consuming a stale per-task spec after Plan re-runs (e.g., post-compaction restart). A regression in the hash-check code path lets stale specs feed Implementation without operator awareness — the same fail-open failure mode the round-03 verifier rejections recognized as load-bearing.

3. **T02 / G12 verifier-fan-in halt causes.** Task 02's DoD requires `scripts/verifier-fan-in.sh` to exit non-zero and record a matching `.verifier-fan-in-audit.json` halt cause for each of: missing `change_type`, out-of-enum `change_type`, missing sidecar, wrong sidecar extension, unparseable score. These are the script-owned guards that prevent the apply-fix pipeline from silently consuming a malformed reviewer output as a clean round. The phase-acceptance gate enumerates the upstream splitter halt on the third-party path (T20) and the downstream `_resolve-lib.sh` `tier: none` halt (T16), but not the fan-in halt causes in the middle of the same pipeline.

(Task 13's prior-round artifact halts — missing/malformed `round-(NN-1)-commit.txt`, missing/empty `round-(NN-1)-scope-set.txt` — are similar in shape but arguably already covered by criterion #1's "no orchestrator chat-parsing fallback fires" clause. The three above are not covered by any other phase bullet.)

### Risk

The phase acceptance gate is the cross-task release-boundary check. If its universal-quantified clause does not actually enumerate the invariants it claims to gate, then a regression in a shared script (e.g., `_resolve-lib.sh` touched by both T16 and T19; `scripts/dispatch-agent.sh` touched by both T20 and T21; `scripts/round-prepare.sh` touched by both T12 and T13) can silently restore a fail-open behavior between commits and ship to release with green CI. The per-task tests pin behavior in isolation; only the phase gate exercises the cross-task integration surface end-to-end with the production configuration knobs set.

The three unenumerated invariants all protect against silent-failure modes the rest of the release is explicitly designed to eliminate (second-reviewer redundancy degradation; stale-spec consumption; malformed-sidecar consumption). Letting any one of them regress at integration time would partially undo the security posture v0.7.2 is shipping.

### Suggested fix (Plan-altitude, not Implement-altitude)

Either:

(a) **Narrow the leading clause** so the gate is honest about being selective: replace "Every fail-loud invariant in the release fires loud on a seeded regression input" with "The following fail-loud invariants each fire loud on a seeded regression input:" and leave the existing list as-is. This trades coverage for honesty and pushes the missing invariants back into per-task scope only.

(b) **Extend the enumeration** so the gate matches its universal-quantified framing: add three bullets to the operative list — `[second-reviewer-unavailable]` halt when `second_reviewer: true` and the configured second-reviewer vendor is unavailable; `plan.md` post-approval split halts when a present per-task file's `# block-hash:` no longer matches its source block; `scripts/verifier-fan-in.sh` halts with a matching `.verifier-fan-in-audit.json` halt cause for each of the five documented malformations (missing `change_type`, out-of-enum `change_type`, missing sidecar, wrong sidecar extension, unparseable score).

Either resolution is a Plan-author decision; the current text is internally inconsistent (universal claim, selective enumeration) and that inconsistency is what creates the release-gate gap.
<!-- @@SCORE: security-claude.finding-F01.score @@ -->
score: 62
reason: Real internal inconsistency — phase criterion #2 uses universal-quantified language but enumerates only 6 invariants; verified T02/T19/T34 each define unenumerated release-introduced fail-loud halts, though per-task tests partially mitigate the practical regression risk.
<!-- @@FINDING: security-codex.finding-F01 @@ -->
---
finding_id: R4-F01
reviewer_tag: security-codex
round: 4
artifact: plan.md
severity: high
change_type: correctness
referenced_files: plan.md (lines 1170-1188, 1196-1216)
---

Task 20 plans to persist prompt/raw payloads under `<round-dir>/.dispatch/` and only remove them on normal `await-round.sh` completion, but the task spec has no requirement to add an interrupted-run safeguard (for example, a committed ignore rule) for those files. That creates a fail-open leak path: if a run halts before cleanup, sensitive dispatch prompt/raw artifacts remain in the working tree and can be accidentally committed or exfiltrated through normal repo workflows.

At Plan altitude this is a missing security acceptance criterion, not implementation detail: the task should require a durable safeguard for leftover `.dispatch/` artifacts in addition to best-effort runtime cleanup.
<!-- @@SCORE: security-codex.finding-F01.score @@ -->
score: 28
reason: Real hygiene observation (leftover `.dispatch/` on interrupted runs is tracked-tree-adjacent), but the "sensitive payload leak/exfil" framing overstates what reviewer prompt/raw outputs actually contain, and no upstream artifact (goals.md G3, design.md CD-1) establishes a `.gitignore`/durable-safeguard acceptance criterion the Plan would be failing to carry; severity "high/correctness" is not supported.
<!-- @@FINDING: silent-failure-claude.finding-F01 @@ -->
---
finding_id: F01
severity: medium
change_type: scope
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/plan.md
  - docs/qrspi/2026-05-30-v072-release/goals.md
artifact: plan.md
---

## Summary

T19 (G27 second-reviewer-available.sh) explicitly defers enforcement of primary-vendor vs. second-vendor distinctness to "dispatch-time code", but no Plan task accepts that responsibility. The result is a Plan-altitude scope gap: G27's goal of enabling second-MODEL review on Copilot CLI can be silently nullified at runtime when both reviewer slots resolve to the same vendor — producing two reviews from the same model under two distinct reviewer tags, with no diagnostic.

## Evidence

T19 Out section (plan.md, in the round-04 diff):

> Enforcing primary-vendor versus second-vendor distinctness inside `second-reviewer-available.sh`; dispatch-time code owns that invariant.

Searching the other dispatch-time-code task specs for an accepting contract:

- **T16 (G22 `model_routing` schema + `_resolve-lib.sh`)** — DoD covers tier-precedence resolution and the `none`-tier halt (`"halts loudly when the selected tier is configured as 'none'; it never silently falls back to a neighboring tier or agent-bundled model"`), but neither the `_resolve-lib.sh` DoD nor the test expectations mention primary/second-reviewer vendor distinctness, the second-reviewer slot, or a same-vendor halt.
- **T20 (G3 dispatch-script rename collapse, `dispatch-agent.sh`)** — DoD enumerates first-party spec-line emission, manifest entries, splitter materialization, and the universal dispatcher contract, but the DoD/Test Expectations make no statement about rejecting or warning when the resolved primary and second-reviewer entries name the same vendor.
- **T19 itself** explicitly *opts out* of this enforcement (the line quoted above).

So the invariant is named in T19's Out list but is not picked up by any task in the Plan.

## Why it matters (silent-failure semantics)

G27's stated problem (goals.md ### G27) is that every Copilot CLI operator is *silently opted out* of second-model review. The whole point of the goal is to ensure the operator actually receives second-MODEL review when they set `second_reviewer: true`.

With the migrated `model_routing:` schema (T16), an operator can now configure both the primary reviewer and the default second-reviewer to the same vendor (e.g., both `openai-codex`, or both `anthropic`). The probe (T19) returns "available" because the vendor is reachable; the dispatcher (T20) emits two spec lines under distinct reviewer tags but the same `(vendor, model)`; both Task calls execute the same underlying model on the same prompt. The aggregate review then *looks* like two-reviewer coverage but is effectively a single-reviewer round duplicated under a second tag — the exact failure class G27 exists to close, re-introduced through a different door.

This is a classic Silent Fallback: the round produces output that callers cannot distinguish from a legitimate two-reviewer round, but the underlying diversity invariant is silently violated.

## Plan-altitude (not implementation-altitude)

This finding is about **task decomposition coverage**, not about how an implementation should code an assertion. The two round-03 findings the verifier suppressed (F02, F03) were about specifying implementation test scaffolding inside Plan; per the F-5 fix-altitude rule, those properly belong to test-writer phase.

This finding is different: it identifies a contract that **the plan itself declares to exist** ("dispatch-time code owns that invariant") but that **no task in the plan accepts**. Allocating a contract to a task — or declaring it pre-existing and out of scope — is core Plan responsibility per `skills/plan/SKILL.md`'s G18 cross-task-consumer-surface contract (T15 adds enforcement for exactly this pattern).

The finding does not prescribe how the assertion is written or which test pins it; it asks Plan to assign the contract to a task (or to a pre-existing surface) so the v0.7.2 release does not ship with an orphaned invariant.

## Suggested resolution shapes (Plan picks one; any of the four resolves the gap)

1. **Add the distinctness check to T16's `_resolve-lib.sh` second-reviewer matrix lookup**: when the resolver returns a default-second-reviewer vendor identical to the resolved primary vendor for the round, halt with a documented diagnostic (e.g., `[second-reviewer-same-vendor]`). Add one bats fixture to `tests/unit/test-routing-matrix-application.bats` (already in T16's target files).
2. **Add the distinctness check to T20's `dispatch-agent.sh`**: when the dispatcher would emit two spec lines whose `dispatch_spec.vendor` values are identical, halt before emission with a diagnostic. Add one bats fixture to the renamed `tests/unit/test-dispatch-agent.bats` (already in T20's target files).
3. **Add a new narrow Task** under Slice 1.4 that owns the distinctness invariant — small (~40 LOC) and dependency-chained after T16 + T19.
4. **Move the line into T19's In section** as a lightweight stderr-only check at the probe layer (treating it as a probe-time observation rather than a hard halt) — accept that approach if Goals/Design did not intend a hard halt.

Any of 1, 2, or 3 produces a fail-loud surface; option 4 is acceptable only if it is paired with a Plan note that documents the operator-visible warning shape.

## Why this also matters for the Phase 1 Acceptance Criteria

Phase 1 AC #2 says: *"Every fail-loud invariant in the release fires loud on a seeded regression input — splitter on adversarial Codex stdout, dispatch on misrouted `model_routing` entries, validation table on missing `model_routing:`, `_resolve-lib.sh` halt when CD-1 dispatch resolves `tier: none` against an unknown vendor, reviewer-protocol against fabricated procedural-authority outputs, and the path-filter exfil guard in `scripts/dispatch-agent.sh` each produce non-zero exit with a diagnostic, never silent fallback."*

The list above does not include the same-vendor-for-primary-and-second case. If Plan considers this case in scope for v0.7.2 (which the T19 deferral wording implies), the AC needs the corresponding bullet so the Test phase can verify it; if Plan considers it out of scope, T19's Out wording should be rewritten to "explicitly out of v0.7.2 scope; defer to v0.7.3+ question" rather than implying an unowned dispatch-time enforcement layer.

Either resolution closes the silent-failure gap at the right altitude.
<!-- @@SCORE: silent-failure-claude.finding-F01.score @@ -->
score: 68
reason: Design D4/D5 explicitly assign primary-vs-second vendor distinctness halt to dispatch-agent.sh; T19 defers to "dispatch-time code" but neither T20 (dispatch-agent.sh) nor T16 (_resolve-lib.sh) DoD/test-expectations pick up the invariant, and Phase 1 AC #2 omits it — a real Plan-altitude allocation gap, though triggered only by operator overrides under default matrix.
<!-- @@FINDING: test-coverage-claude.finding-F01 @@ -->
---
finding_id: F01
artifact: plan.md
reviewer_tag: test-coverage-claude
round: 4
severity: medium
change_type: clarity
location: "Task 38 — Test expectations bullet 5 (Mental-replay check)"
---

## Summary

T38's fifth Test Expectations bullet is a "Mental-replay check" that asserts a
hypothetical `structure.md` would not trigger a Structure scope finding under
the updated reviewer prompts. Combined with T38's Scope-Out clause —
*"Adding lint tests or test-code files — existing task text explicitly keeps
this reviewer-prompt task to prompt-prose surfaces"* — the expectation cannot
be operationalized into a deterministic acceptance test.

## Why this is a Plan-altitude problem

The Test skill consumes each task's Test Expectations to generate acceptance
tests. The other four bullets in T38 are grep/inspection audits that the Test
skill can mechanically translate into bats fixtures. The mental-replay bullet,
by contrast, describes an LLM-judgment outcome ("would not trigger a Structure
scope finding") without naming a fixture file, an agent-invocation harness, or
an assertion target. Two failure modes follow:

1. **Test skill cannot write a deterministic test.** The only way to verify the
   bullet is to dispatch `qrspi-structure-scope-reviewer` against a real
   fixture `structure.md` and assert zero findings — but that *is* a test-code
   file, which T38's Scope-Out forbids.
2. **No falsification path.** Because no fixture or harness is named, any
   future implementation that quietly weakens the reviewer prose could still
   "pass" mental-replay through reviewer charity. The bullet has no
   `expected = actual` shape.

The first four bullets already operationalize the same intent:
"Inspect for positive obligations that treat `unified system architecture` and
`## Test Architecture` as expected Structure content; confirm stale pre-G35
anomaly/drift framing is absent." The mental-replay bullet is redundant once
those greps land — or, if it is intended to add behavioral coverage beyond the
greps, the prose-only scope clause and the bullet contradict each other.

## Recommended fix

Pick one of:

- **(a) Demote the mental-replay sentence** from Test Expectations to a Why /
  Definition-of-Done rationale paragraph (it already documents the intent that
  the four grep assertions enforce). Test Expectations should contain only
  bullets the Test skill can mechanize.
- **(b) Lift T38's Scope-Out** for one minimal fixture + one bats test that
  dispatches `qrspi-structure-scope-reviewer` against a fixture `structure.md`
  containing the Mermaid + `## Test Architecture` content and asserts zero
  scope findings. Then keep the mental-replay bullet but anchor it to that
  fixture/test by path.
- **(c) Replace** the mental-replay bullet with an explicit grep assertion
  pair: (i) presence of the new "expected content" prose anchors in
  `agents/qrspi-structure-reviewer.md`; (ii) absence of the old anomaly/drift
  trigger prose. Both are already implied by bullets 1 and 3 — make them
  explicit and drop mental-replay.

Either (a) or (c) preserves the prose-only scope; (b) trades that scope for
real behavioral coverage. The current state is the worst of both worlds: a
Test Expectation that nothing can write.

## Why this isn't suppressed by F-5

This is not a per-task happy-path-only complaint, not a missing-RED-fixture
complaint, and not a request to specify implementation detail. It is a
**Plan-altitude verifiability** complaint: the Test Expectations block contains
a bullet the Test skill cannot translate into any test (deterministic or
otherwise) given the task's own Scope-Out constraint. That is exactly the
"vague/unfalsifiable test expectation" pattern the reviewer's category 4
(Test Expectation Quality) is meant to catch.
<!-- @@SCORE: test-coverage-claude.finding-F01.score @@ -->
score: 45
reason: Real verifiability gap — T38 bullet 5 is an LLM-judgment "mental-replay" with no fixture/harness while Scope-Out forbids test-code files — but four mechanizable sibling bullets already cover the same intent, so impact is modest.
<!-- @@FINDING: test-coverage-claude.finding-F02 @@ -->
---
finding_id: F02
artifact: plan.md
reviewer_tag: test-coverage-claude
round: 4
severity: medium
change_type: correctness
location: "Phase 1 Acceptance Criteria bullet 2 vs Task 16 / Task 19 Test Expectations"
---

## Summary

Phase 1 AC bullet 2 commits the release to a specific fail-loud invariant:

> `_resolve-lib.sh` halt when CD-1 dispatch resolves `tier: none` against an
> unknown vendor

But no surviving task's **Test Expectations** block exercises the
"unknown vendor" branch of `_resolve-lib.sh`. T16 covers the `tier: none`
operator-opt-in branch (`extra-low: none`), and T19 covers unknown-vendor
behavior in the `second-reviewer-available.sh` *probe* — but the AC bullet
names the underlying `_resolve-lib.sh` resolver, not the probe. The bullet
will be unverifiable at phase end unless one of the tasks pins the
unknown-vendor-against-`_resolve-lib.sh` halt explicitly.

## Evidence

**Phase 1 AC bullet 2** (plan.md ### Phase 1 Acceptance Criteria, bullet 2):
> `_resolve-lib.sh` halt when CD-1 dispatch resolves `tier: none` against an
> unknown vendor

**T16 Test expectations** (plan.md ### Task 16, **Test expectations**) cover:
- `_resolve-lib.sh` precedence chain
- "Verify a dispatch resolving to a tier configured as `none` halts with a
  diagnostic naming the unresolved tier and does not fall back."
- Missing / malformed `model_routing:` via config-validation procedure
- Agent-frontmatter sweep, reviewer `DISPATCH_FILE=<path>` instruction, prose
  cleanup, `tests/unit/test-config-model-routing.bats` and
  `tests/unit/test-routing-matrix-application.bats` extensions.

No test expectation names **unknown vendor** as an input class for
`_resolve-lib.sh`. T16's DoD does mention "host/vendor routing lookup" as a
resolver responsibility, but the Test Expectations never enumerate the
unknown-vendor-against-the-matrix failure mode.

**T19 Test expectations** (plan.md ### Task 19) cover:
> Executability and behavior tests for `scripts/second-reviewer-available.sh`:
> Copilot CLI and Claude Code default paths exit 0; unknown host, missing
> default vendor, **unknown vendor**, and unavailable vendor exit non-zero
> with one `[second-reviewer-unavailable]` diagnostic containing host and
> vendor.

This is unknown-vendor coverage for the *probe*, not for `_resolve-lib.sh`
directly. The probe consumes `_resolve-lib.sh` matrix helpers, but the test
asserts the probe's `[second-reviewer-unavailable]` diagnostic shape, not
`_resolve-lib.sh`'s halt shape under direct invocation by the dispatch path.

## Why this is a Plan-altitude problem

The AC bullets enumerate the *behaviors the Test phase must verify before the
release PR opens*. The Plan tells reviewers (line 35): *"Per-task criteria
live in each `tasks/task-NN.md`'s ## Test Expectations block; the per-phase
block above captures cross-task observable behavior at phase end."* That
contract requires each AC sub-clause to either (a) be visibly covered by one
or more tasks' test expectations, or (b) carry its own seed/fixture guidance
at the AC level.

Bullet 2's "splitter on adversarial Codex stdout", "dispatch on misrouted
`model_routing` entries", "validation table on missing `model_routing:`",
"reviewer-protocol against fabricated procedural-authority outputs", and
"path-filter exfil guard in `scripts/dispatch-agent.sh`" all map to surviving
tasks' Test Expectations (T20, T16, T17, T35, T21 respectively). The
"`_resolve-lib.sh` halt … against an unknown vendor" sub-clause is the
odd one out: it names a specific component and a specific input class, but
no task's Test Expectations pin that pair.

This is precisely the "AC bullet maps to deliverables of surviving tasks"
check the dispatcher asked me to run.

## Recommended fix

Pick one of:

- **(a) Add an unknown-vendor halt assertion to T16 Test Expectations.**
  Concretely: a new bullet under T16 reading something like —
  *"Verify a dispatch resolving against a vendor absent from `model_routing:`
  halts with a `[…]` diagnostic naming the unknown vendor, and does not fall
  back to `default_tier` or a neighboring vendor's matrix row."*
  This is the most direct fix because the AC bullet names `_resolve-lib.sh`.

- **(b) Move the unknown-vendor halt assertion to T19 Test Expectations and
  rewrite the AC bullet** to say "`second-reviewer-available.sh` halt …
  against an unknown vendor" (since T19 already covers this in the probe).
  This requires updating AC bullet 2's wording to match the actual component
  under test.

- **(c) Add a seed fixture / acceptance-test pointer at the AC bullet itself**
  naming `tests/unit/test-routing-matrix-application.bats` (or similar) and
  the specific input/output the Test phase should seed. This keeps T16/T19
  unchanged but makes the AC bullet self-sufficient.

Option (a) is preferred — it keeps the resolver as the load-bearing fail-loud
seam and preserves the AC's component-level wording.

## Why this isn't suppressed by F-5

This is not a per-task happy-path-only complaint and not an
implement-altitude RED-fixture complaint. It is a **Phase 1 AC ↔ task Test
Expectations mapping gap** — the same category as round-03's F04
("Phase 1 AC stale deliverables") which was kept. F04 caught AC sub-clauses
that named dead deliverables; this finding catches a live AC sub-clause that
names a behavior no task's test plan covers. The fix is symmetric: keep the
AC and task expectations in lock-step.
<!-- @@SCORE: test-coverage-claude.finding-F02.score @@ -->
score: 42
reason: Real but minor AC↔Test-Expectations mapping gap — T16 pins the load-bearing `tier: none` halt and routing-matrix lookups; the "unknown vendor" sub-phrase is a reasonable refinement rather than an uncovered fail-loud invariant.
<!-- @@CLEAN: goal-traceability-claude.clean @@ -->
# goal-traceability-claude — clean (round 04)

No findings. Bidirectional traceability verified against goals.md (35 approved goals G1–G35), design.md (CD-1/CD-2/CD-3/CD-4 + per-goal absorption rationales for G24/G25/G26/G29), and plan.md round-04 task list (38 surviving tasks T01–T44 with 6 gaps).

## Forward trace — 35 approved goals → ≥1 surviving task or documented L11 disposition

| Goal | Disposition | Coverage |
|------|-------------|----------|
| G1 | task | T30 (Phase decision-completeness template) + T28 (CD-3 multi-actor-flow-check lists G1) |
| G2 | task | T33 (Plan schema-migration task shape) |
| G3 | task | T11 (dispatch-manifest provenance, relabeled in round-02) + T20 (splitter rename) + T27 (CD-2 lists G3) |
| G4 | task | T12 (canonical cumulative diff helper) + T27 (CD-2 lists G4) |
| G5 | task | T34 (Plan post-approval split idempotency) |
| G6 | task | T03 (reviewer disk-write contract) + T24 (CD-4 detect-interaction-mode lists G6) |
| G7 | task | T01 (verifier-filter-rule shared snippet) |
| G8 | task | T04 (reviewer frontmatter `change_type`) |
| G9 | task | T13 (per-task review orchestration) |
| G10 | task | T35 (reviewer-protocol anti-fabrication hardening) |
| G11 | task | T06 (verifier sidecar extension correction) + T24 (CD-4 lists G11) |
| G12 | task | T02 (verifier-fan-in script) + T24 (CD-4 lists G12) |
| G13 | task | T05 (`change_type` enum drift hardening) |
| G14 | task | T07 (verifier rubric correction for `Informational`) |
| G15 | task | T14 (Plan sweep-task contract) |
| G16 | task | T21 (path-filter exfil hardening in dispatch-agent.sh) |
| G17 | task | T36 (implementer-protocol + test-writer stale-prose cleanup) |
| G18 | task | T15 (Plan cross-task consumer surface) |
| G19 | task | T08 (verifier wholesale-hallucination rubric class) |
| G20 | task | T09 (reviewer-model calibration for substituted Codex model) |
| G21 | task | T40 (bats short-circuit hardening + body-assertion-guard lint) |
| G22 | task | T16 (`model_routing` schema and agent-sweep migration) + T27 (CD-2 lists G22) |
| G23 | task | T17 (validation table covers `model_routing`) |
| G24 | partial-task + L11 dispositions | T44 (F05 anti-pattern pin regex hardening); F01 moot (gap 42), F02 absorbed via G25→CD-1 (gap 22), F03 moot — duplication target never existed (gap 23), F04 moot per design.md L2064 (gap 43) |
| G25 | L11 disposition | absorbed by CD-1 (gap 18); design.md ## G25 confirms |
| G26 | partial-task + L11 disposition | T40 (BW02 lint rule); runtime concern already fixed pre-v0.7.2 (gap 41); design.md ## G26 confirms |
| G27 | task | T19 (`second-reviewer-available.sh` + host-detect primitive) + T27 (CD-2 lists G27) |
| G28 | task | T10 (verifier convergent-evidence exception + sub-threshold instrumentation) |
| G29 | L11 disposition | absorbed by CD-1; T11 repurposed to [G3] not deleted; design.md ## G29 confirms |
| G30 | task | T32 (Goals/Design dialogue-authoring + compaction-resilient persistence) + T28 (CD-3 lists G30) |
| G31 | task | T25 (prompt-prose primitives) + T26 (prompt-prose include sites) |
| G32 | task | T39 (plugin build pipeline) |
| G33 | task | T31 (Design skill interactive dialog clarity) + T28 (CD-3 lists G33) |
| G34 | task | T29 (Design scope-reviewer alignment with detailed-solution boundary) |
| G35 | task | T37 (Structure SKILL absorbs unified architecture) + T38 (Structure reviewers enforce architecture-only boundary) |

## Backward trace — 38 surviving tasks → ≥1 goal or CD-derived justification

Every task in the Task List by Slice declares `goals: [...]` with valid IDs. Tasks under CD-derived primitives (T24 → CD-4; T27 → CD-2; T28 → CD-3) list source goals in the goals: field and are traceable through their CDs in design.md. No task lacks a goal or research-finding justification.

## L11 per-gap dispositions vs. design.md G24/G25/G26/G29 absorption rationales

| L11 gap | L11 claim | design.md rationale | Match? |
|---------|-----------|---------------------|--------|
| 18 | G25, absorbed by CD-1 | ## G25 "moot/absorbed by CD-1" (architectural rewrite eliminates per-H4 mirror pattern) | ✓ |
| 22 | G24-F02, defers to G25 → CD-1 | ## G24 L2065 (F02 defers to G25) + ## G25 L2098 (F02 auto-resolves to moot) | ✓ |
| 23 | G24-F03, moot — duplication target never existed | ## G24 L2063 (helper exists in exactly one file; no cross-file duplication) | ✓ |
| 41 | G26 already fixed pre-v0.7.2; BW02 prevention rides on G21/T40 | ## G26 "moot/already-fixed" + regression-prevention re-targeted to G21 lint test | ✓ |
| 42 | G24-F01, moot after tree audit | ## G24 L2062 (helper and target test files do not exist in current tree) | ✓ |
| 43 | G24-F04, moot per design.md L2064 (regex pattern no longer present at meaningful volume) | ## G24 L2064 verbatim | ✓ |
| (G29) | absorbed by CD-1; T11 repurposed to [G3] not deleted | ## G29 (absorbed by CD-1; orchestrator never carries artifact body under CD-1 dispatch shape) | ✓ |

## Spec-to-design fidelity

Plan's seven vertical slices (1.1–1.7) and 38 tasks match design.md's per-goal solution surfaces. CD-1's dispatch architecture surface is distributed across T11/T16/T17/T19/T20/T21/T24 as Overview L11 documents. No design components are missing from the task list; no task implements components absent from design.

## Decomposition check

All goals' amendment items (where applicable) are decomposable from each goal's problem framing in goals.md. The CD-absorbed goals (G25/G26/G29 and parts of G24) explicitly document their absorption rationale in design.md and Overview L11; no amendment work bleeds into goals.md acceptance-criterion territory.

Round-03 disposition cleanup (per-gap moot/absorbed rationales) successfully closed the previous Overview-L11 ambiguity. No new traceability regressions introduced in round-04.
<!-- @@CLEAN: goal-traceability-codex.clean @@ -->
---
reviewer_tag: goal-traceability-codex
round: 4
artifact: plan.md
verdict: clean
findings_count: 0
---

No traceability gaps for round 4. Codex (gpt-5.3-codex) returned clean sentinel via chat-only — orchestrator materialized to disk per Copilot-CLI Codex chat-only transport pattern.
<!-- @@CLEAN: scope-claude.clean @@ -->
---
reviewer_tag: scope-claude
round: 4
artifact: plan.md
verdict: clean
---

# Scope review — clean

No scope or boundary-drift findings.

## Round-04 surgical edits checked against `skills/plan/owns-defers.md`

1. **Overview L11 dispositions** — gap-numbering bookkeeping (gaps 18, 22, 23, 41, 42, 43) with rationale deferred to `design.md ## G24/G25/G26/G29`. Plan OWNS "Ordered task specs"; the dispositions are stable-cross-reference metadata, not re-authored design rationale.
2. **Overview cross-slice chain** — two cross-slice prerequisite chains (G4→G9; T09/T11/T13→T20 splitter rename). Plan OWNS "Dependencies — explicit task-to-task ordering". File names and field names (`round-prepare.sh`, `actual_model:`) appear as dep-defining surface identifiers, not as function signatures or interface contracts.
3. **Task 11 annotation** — note about round-02 G29→G3 relabel and numerical parking. Pure cross-reference bookkeeping.
4. **Phase 1 AC rewrite** — seven cross-task observable acceptance bullets in plain language. All are end-to-end behaviors verifiable at phase boundary (Plan OWNS "Test expectations in plain language"). Config keys (`verifier_enabled: true`, `model_routing:`, `tier: none`) and script names (`scripts/verifier-fan-in.sh`, `_resolve-lib.sh`, `scripts/dispatch-agent.sh`) appear only as behavior triggers / observation surfaces, never as schemas, parameter shapes, or algorithm steps. No `expect(...)`, no signatures, no architectural decisions.

## Broaden scan (full artifact, per scope_hint: broaden)

Sampled task specs across slices 1.1 (T01–T04), 1.2 (T09–T11), and 1.4 (T12):

- Test Expectations are plain-language behaviors (grep audits, fixture exercises, exit-code expectations, "writes X", "asserts Y"). No `expect(...)` / `assert.` / `toBe(` leakage.
- No function signatures, parameter lists, or return-type arrows in any sampled spec.
- No `if/else` / `for` / `while` / line-numbered logic walkthroughs.
- No "trade-off", "we considered", "alternative approach" phrasing — every approach reference defers cleanly to `design.md`.
- No "phase 2 will…", "future phases" forward references — `phasing.md` boundaries respected.
- Specific exit codes in T12 (10, 11, 12) are documented as behavioral contracts other tasks/tests must observe, not as algorithm pseudocode. Acceptable per the "behavior, not implementation choice" framing.

## Length / aggregate

Aggregate ~2400 lines for 38 tasks ≈ 63 lines/task — slightly above the 1000–2000 line soft window but consistent with the Keeplii ~52-line/task baseline cited in the OWNS/DEFERS doc. The owns-defers length rule explicitly calls 4000 lines the under-/over-specification alarm; 2400 with 38 tasks is comfortably below it. Not a scope finding.

## Conclusion

Round-04 edits introduced no boundary drift and no scope-compliance gaps. Plan continues to OWN ordered task specs, plain-language test expectations, dependencies, and LOC estimates without crossing into structure.md, design.md, phasing.md, or Implement-TDD territory.
<!-- @@CLEAN: scope-codex.clean @@ -->
---
reviewer_tag: scope-codex
round: 4
artifact: plan.md
verdict: clean
findings_count: 0
---

No scope/boundary violations for round 4. Codex (gpt-5.3-codex) returned clean sentinel via chat-only — orchestrator materialized to disk per Copilot-CLI Codex chat-only transport pattern.
<!-- @@CLEAN: silent-failure-codex.clean @@ -->
---
reviewer_tag: silent-failure-codex
round: 4
artifact: plan.md
verdict: clean
findings_count: 0
---

No Plan-altitude silent-failure concerns for round 4. Codex (gpt-5.3-codex) returned clean sentinel via chat-only — orchestrator materialized to disk per Copilot-CLI Codex chat-only transport pattern.
<!-- @@CLEAN: spec-claude.clean @@ -->
---
reviewer: spec-claude
round: 4
findings: 0
verdict: clean
---

# Spec Review Round 04 — Clean

No findings. Round-03 surgical edits integrated cleanly; the plan continues to cover every goal with verifiable per-task Test Expectations, and every Phase 1 AC bullet maps to deliverables of surviving tasks.

## Verification highlights (round-04 focus per dispatch)

### Goal coverage unchanged

All 35 approved goals (G1–G35) still trace to at least one task. The slice tallies — 1.1=7, 1.2=4, 1.3=3, 1.4=7, 1.5=12, 1.6=2, 1.7=3 = 38 — match the Overview's stated "38 tasks (task numbers 1–44 with gaps at 18, 22, 23, 41, 42, 43)". Absorbed-goal attribution (G24-F01/F02/F03/F04, G25, G26 standalone, G29) verified once more — no task carries an inappropriate absorbed ID.

### Phase 1 AC bullets → surviving tasks (round-04 required check)

Each AC bullet's load-bearing deliverable references map to non-deleted tasks:

| AC bullet | Cited deliverable | Owning task (surviving) |
|---|---|---|
| 1 (end-to-end) | `verifier_enabled` aggregate | T01/T02/T05/T06/T07/T24 |
| 1 (end-to-end) | `scope_tagger_enabled` per-round artifacts | T13 |
| 1 (end-to-end) | `second_reviewer` reliable persistence | T19, T03 |
| 1 (end-to-end) | per-finding sidecars with valid `change_type` | T03, T04, T05 |
| 2 (fail-loud) | splitter on adversarial Codex stdout | T20 |
| 2 (fail-loud) | dispatch on misrouted `model_routing` | T16 |
| 2 (fail-loud) | missing `model_routing:` validation table | T17 |
| 2 (fail-loud) | `_resolve-lib.sh` halt on `tier: none` against unknown vendor | T16 (DoD L1001, Test exp L1014) |
| 2 (fail-loud) | reviewer-protocol fabricated procedural-authority guard | T35 |
| 2 (fail-loud) | path-filter exfil guard in `dispatch-agent.sh` | T21 |
| 3 (apply-fix) | Sub-Threshold Observations block in dispositions | T10 (G28) |
| 3 (apply-fix) | wholesale-hallucination rubric on calibration seeds | T08 (G19) + T09 (G20) |
| 4 (build) | `node tools/build-plugin.mjs` reproducible artifact | T39 |
| 5 (bats) | `tests/lint/test-bats-body-assertion-guard.bats` body-less catch | T40 (DoD L2319) |
| 5 (bats) | T40 seeded G21 + BW02 violation → non-zero with `file:line` | T40 (DoD L2319–2320) |
| 5 (bats) | T44 regex pins on `dispatch-routing`/`config-validation` continue to fire | T44 (DoD L2380) |
| 6 (issue closure) | goal-backing issue closure / explicit deferral | goal-level rollup, no task ref |
| 7 (release PR) | green CI + canary smoke | goal-level rollup, no task ref |

No AC bullet references the deleted T18 (G25 → CD-1 absorbed), T22 (G24-F02 → G25 → CD-1), T23 (G24-F03 moot — duplication target never existed), T41 (G26 runtime concern already fixed pre-v0.7.2), T42 (G24-F01 moot), or T43 (G24-F04 moot per design.md L2064). The round-03 rewrite cleanly excised every reference to those task IDs.

### Cross-slice dependency chain (round-03 addition) still coherent

Overview dep-graph item 4 — "G20 `actual_model:` provenance (T09) + G3 dispatch-manifest provenance (T11) + G9 per-task round-prepare edits (T13) → G3 splitter rename (T20)" — is consistent with T20's `Dependencies: [Task 09, Task 11, Task 12, Task 13, Task 19]` line (plan.md L72) and with T11's `Blocks: T20` (L683) and T13's `Blocks: T20` (L802). The pre-rename surface (`scripts/run-codex-review.sh`, `scripts/round-prepare.sh`) is fully provisioned by T09/T11/T13 before T20 hard-renames.

### Per-gap disposition narrative (round-03 rewrite) is internally consistent

The Overview's per-gap breakdown (L17) — gap 18 (G25→CD-1), gap 22 (G24-F02→G25→CD-1), gap 23 (G24-F03 moot — duplication target never existed), gap 41 (G26 runtime concern already fixed pre-v0.7.2; BW02 prevention rides on G21 in T40), gap 42 (G24-F01 moot), gap 43 (G24-F04 moot per design.md L2064) — matches the Out-of-scope language in T44 (L2370: "F01/F03 helpers and target files do not exist in current tree; F02 auto-resolves via CD-1; F04 absorbed into the G3/CD-1 dispatch rewrite") and the T17 Out-of-scope (L1068: G25 absorbed by CD-1).

### Sizing exceptions unchanged

All tasks >200 LOC carry the explicit closed-set exception: T12 (~280, reusable primitives), T16 (~320, schema-migration), T19 (~210, reusable primitives), T20 (~260, reusable primitives), T25 (~340, reusable primitives), T39 (~360, CI scaffolding). No new bundling violation introduced.

### Test Expectations specificity

Sampled rounds 1–3 covered T01–T20, T24–T32, T37–T40, T44. Round-04 spot-checked the same surfaces after diff = entire-file (plan.md first commit to git) — no vague language regressions, no `TBD`/`TODO`/`see Task N` cross-references.

## Verdict

Round-03 surgery integrated cleanly. Phase 1 AC bullets and per-task specs fully cover the 35 approved goals with surviving tasks only. No spec-level findings.
<!-- @@CLEAN: spec-codex.clean @@ -->
---
reviewer_tag: spec-codex
round: 4
artifact: plan.md
verdict: clean
findings_count: 0
---

No findings for round 4. Codex (gpt-5.3-codex) returned clean sentinel via chat-only — orchestrator materialized to disk per Copilot-CLI Codex chat-only transport pattern.
<!-- @@CLEAN: test-coverage-codex.clean @@ -->
---
reviewer_tag: test-coverage-codex
round: 4
artifact: plan.md
verdict: clean
findings_count: 0
---

No findings for round 4. Codex (gpt-5.3-codex) returned clean sentinel via chat-only — orchestrator materialized to disk per Copilot-CLI Codex chat-only transport pattern.
