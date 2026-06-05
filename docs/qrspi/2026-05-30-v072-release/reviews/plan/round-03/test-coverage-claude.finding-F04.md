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
