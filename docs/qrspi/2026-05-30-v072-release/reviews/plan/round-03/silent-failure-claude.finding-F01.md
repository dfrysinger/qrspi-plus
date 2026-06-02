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
