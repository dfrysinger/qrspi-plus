---
finding_id: trace-claude-F01
reviewer: qrspi-goal-traceability-reviewer (claude)
artifact: docs/qrspi/2026-06-04-v073-release/plan.md
round: 2
severity: high
change_type: scope
referenced_files:
  - docs/qrspi/2026-06-04-v073-release/plan.md
  - docs/qrspi/2026-06-04-v073-release/design.md
---

# F01 — Spec-to-Design fidelity inversion: plan.md flips CD-1's unknown-step behavior from "exit 0 with SKILL-only fallback" to "exit non-zero, empty stdout" and mis-cites the source

## Summary

`design.md` § CD-1 commits the script's unknown-step handling to exit 0 with the
always-appended SKILL paths as the fallback. `plan.md` round-02 inverted that
contract — both T01 and the Phase-1 Acceptance Criteria block now require the
script to exit non-zero with empty stdout on an unknown `--step` value, and T01
labels the inverted behaviour "(CD-1 Acceptance bullet 2 — fail-loud direction)"
as if it were the design's commitment. No amendment to design.md accompanies the
flip.

Per the strip-from-goals contract, plan.md is the criterion-authoring source;
the criterion plan.md authors must not contradict the design-committed criterion
unless plan.md explicitly amends design.md and records the amendment. This is a
spec-to-design fidelity violation, not a missing-coverage gap.

## Evidence — design.md commits exit 0 with SKILL-only fallback

`design.md` § CD-1 § Dependencies + edge cases (line 20, emphasis added):

> Edge case: a step name not in the table (e.g. `plan` today) **returns the
> always-appended SKILL paths only. The script must handle unknown step names by
> printing the always-appended set and exiting 0, not by erroring** —
> orchestrator failure on an absent step would be a regression vs. today's prose
> behavior.

`design.md` § CD-1 § Acceptance bullet 2 (line 25):

> Unknown step name returns the always-appended SKILL paths + exit 0 (covered
> by a bats case).

Two load-bearing places: the edge-case prose (with a stated rationale: avoiding
a regression against today's behaviour) and the Acceptance enumeration.

## Evidence — plan.md round-02 carries the opposite behaviour

`plan.md` § Phase 1 Acceptance Criteria (line 137):

> `scripts/upstream-paths.sh --step <step>` emits the documented set for every
> supported step including the new Plan branch in both pipeline modes, and the
> always-appended array contains `skills/implementer-protocol/SKILL.md`
> (CD-1, G1, G4). **An unknown `--step` value exits non-zero with the
> `upstream-paths-unknown-step:` diagnostic and empty stdout (no SKILL-only
> fallback)** — Plan-step missing/malformed `config.md` exits non-zero with its
> own named diagnostic.

`plan.md` § T01 Description (line 172):

> An unknown `--step` value exits non-zero with a `upstream-paths-unknown-step:`
> named diagnostic listing the valid step values and emits empty stdout — there
> is no SKILL-only fallback.

`plan.md` § T01 Test expectations (line 176):

> Unknown step name exits non-zero with the `upstream-paths-unknown-step:`
> named diagnostic listing valid step values; stdout is empty
> **(CD-1 Acceptance bullet 2 — fail-loud direction).**

The parenthetical at line 176 cites CD-1 Acceptance bullet 2 as authority for
the fail-loud direction. CD-1 Acceptance bullet 2 in fact states the exact
opposite. This is a mis-citation of the source document, not just a quiet
divergence.

## Why this matters for traceability

The CD-1 inversion has three downstream effects the trace matrix exposes:

1. **G4 acceptance for Plan-step coverage.** G4 trace runs through CD-1's
   `upstream-paths.sh` script. CD-1's design-committed unknown-step fallback
   was the safety property the script was supposed to provide ("orchestrator
   failure on an absent step would be a regression vs. today's prose
   behavior"). Plan.md round-02 now ships precisely that regression: any future
   step name added to the dispatch chain that has not yet been added to the
   script returns no SKILL paths and halts the orchestrator. The behaviour the
   design specifically called out as "do not do" is now the contract.

2. **Cross-cutting Apply-fix protocol breakage.** The Apply-fix protocol in
   `using-qrspi/SKILL.md` runs verifier dispatches at every per-step Apply-fix
   call. Today (per design.md edge-case prose) an unknown step name still
   produces a usable dispatch with the always-appended SKILL paths. Under
   plan.md round-02's contract, the same call halts the whole orchestrator
   with empty stdout — silently breaking any caller that did not already
   register a new step name with `scripts/upstream-paths.sh`.

3. **Citation-as-evidence drift.** T01's parenthetical "(CD-1 Acceptance
   bullet 2 — fail-loud direction)" presents the inverted behaviour as if
   design-sourced. A reviewer checking the citation against design.md will find
   the opposite text; the citation pattern is the trace anchor a downstream
   reviewer or test-writer uses, and a wrong citation is harder to catch than
   a missing one because it presents as evidence.

## Recommended remediation

One of:

1. **Restore design fidelity.** Update T01's description, T01's test
   expectations, and the Phase-1 Acceptance bullet at line 137 to match
   design.md CD-1's edge-case prose and Acceptance bullet 2 verbatim:
   "Unknown step name returns the always-appended SKILL paths and exits 0;
   only Plan-step missing/malformed `config.md` halts non-zero (per G4)."
   Drop the mis-citation parenthetical.

2. **Amend design.md, then update plan.md.** If round-01 review surfaced a
   security or correctness reason to invert CD-1's unknown-step behaviour
   (e.g., the change was made in response to a security finding about empty
   fallback being unsafe — though none of the round-01 findings as written
   call for this inversion), dispatch a design Apply-fix round to invert
   CD-1's edge-case prose and Acceptance bullet 2 with stated rationale,
   then re-quote the amended design text in T01's citation. This is the
   round-trip the strip-from-goals contract requires for an
   acceptance-criterion change.

The inversion is a deliberate choice rather than a typo — it appears
consistently in three places (Phase-1 acceptance, T01 description, T01 test
expectations) and the named diagnostic shape (`upstream-paths-unknown-step:`)
is fully designed-out — so the fix is contract-level, not a single-line
patch.
