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
