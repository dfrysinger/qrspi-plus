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
