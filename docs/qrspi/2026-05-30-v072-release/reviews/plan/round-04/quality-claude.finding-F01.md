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
