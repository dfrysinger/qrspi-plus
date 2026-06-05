---
verifier_enabled: true
scope_tagger_enabled: true
scored: 1
kept: 1
dropped: 1
failed: 0
clean: 2
---

<!-- @@FINDING: quality-codex.finding-F01 @@ -->
---
finding_id: R4-F01
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/phasing.md
  - docs/qrspi/2026-05-30-v072-release/goals.md
artifact: phasing
round: 4
reviewer: quality-codex
---

## Over-abstraction of acceptance-gate wording reduces checkability

`phasing.md` replaced concrete `change_type` wording with `finding-categorization` in both Slice 1.1 and Phase 1 acceptance gates (`phasing.md:50,54,148,153`). That abstraction makes the gate less checkable because "finding-categorization" is not a concrete field name in the contracted finding schema, while the companion goals artifact still names this surface as "change-type schema enforcement" (`goals.md:9`).

To keep replan/release gates demonstrable and unambiguous, acceptance text should reference the exact schema field (`change_type`) and invalid-value test cases using that literal field name.
<!-- @@SCORE: quality-codex.finding-F01.score @@ -->
score: 15
reason: Directly contradicts the R3 scope-driven boundary fix (schema-field names cross the Phasing→Structure DEFERS line); reverting to the literal `change_type` would re-introduce the residual drift R3 just closed, and G-ID grounding already preserves checkability.
<!-- @@FINDING: scope-codex.finding-F01 @@ -->
---
finding_id: R4-F01
severity: medium
change_type: scope
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/phasing.md:L50-L55
  - docs/qrspi/2026-05-30-v072-release/phasing.md:L147-L154
artifact: phasing
round: 4
reviewer: scope-codex
---

## Residual boundary drift in Slice/Phase wording

The R4 wording swap landed (`change_type`/`model_routing` renamed), but the edited Slice 1.1 and Phase 1 gate text still names mechanism-level implementation details (specific config/enum internals) rather than phasing-level outcome boundaries. Under **Phasing DEFERS**, that detail belongs downstream (Structure/Plan/Implement). Keep phasing language at slice/phase deliverable outcomes and move mechanism specifics out of `phasing.md`.
<!-- @@CLEAN: quality-claude.clean @@ -->
---
reviewer_tag: quality-claude
artifact: phasing
round: 4
status: clean
---

# Phasing quality review — round 04 — clean

Reviewed the R4 diff (40 lines, terminology renames in Slice 1.1 + Phase 1
acceptance-gate items 1–2) against the seven phasing-specific quality checks,
with scope_hint focused on `## Slices` and `## Phases`. Also scanned the
remainder of the artifact for anything significant outside the hint per the
scope-hint contract.

## What changed in R4

The diff is a narrow terminology pass:

- Slice 1.1 surface + demonstrable-by: `change_type` → `finding-categorization`
- Phase 1 gate 1: `model routing` → `model-routing`; `change_type enum silent
  fall-through` → `finding-categorization enum silent fall-through`
- Phase 1 gate 2: `missing model_routing` → `missing dispatch-routing config`;
  `invalid change_type` → `invalid finding categorization`

This brings phasing.md prose in line with roadmap.md's existing thematic
language ("finding-categorization discipline" was already in roadmap Slice 1.1).

## Checks

1. **Every in-scope goal has a slice.** Unchanged by R4. G6–G14 still mapped
   to Slice 1.1; G13 still listed; G9 still in Slice 1.3. All 35 goals
   accounted for across slices 1.1–1.7.
2. **Every slice has a phase.** Unchanged. All seven slices ride Phase 1.
3. **Iron Law 1 (vertical slices).** Unchanged. Terminology renames do not
   alter slice composition or verticality.
4. **Phase 1 PoC guideline.** Unchanged. The "Phase 1 IS v0.7.2 release"
   justification stands; the PoC is the end-to-end pipeline exercise.
5. **Replan-gate criteria concrete and checkable.** Gates 1 & 2 were the
   touched surface. The new thematic phrasing is slightly more abstract than
   the prior field-level names but remains checkable in context: gate 1
   still enumerates anchor goal IDs (G6, G7/G22/G23, G12, G13, G9) for each
   observable outcome, and gate 2 still names the concrete trip-the-trap
   targets (dispatch config, finding categorization, malformed sidecar).
   Gates 3–5 are unchanged and remain concrete (instrumentation
   completeness, build pipeline produces a clean artifact, five GitHub
   issues closed). No checkability regression rises to finding level.
6. **Four-artifact pruning procedure.** No changes to `future-*.md`
   companions in this diff. Pre-existing pruning state was clean per
   prior rounds; nothing leaked into or out of the empty future
   placeholders this round.
7. **Goal-ID consistency.** Unchanged by R4. Edited passages still
   reference the same goal IDs (G6, G7, G22, G23, G12, G13, G9) and
   the slice/roadmap goal-ID set still matches goals.md.

## Outside scope_hint

Nothing significant. The `## Why single phase`, `## Replan checkpoints`,
`## Amendment items`, and `## Future-phase content` sections are unchanged
and remain coherent with the (unchanged) totals: 35 goals, single phase,
0 deferred.

No findings.
<!-- @@CLEAN: scope-claude.clean @@ -->
---
reviewer: scope-claude
artifact: phasing
round: 4
status: clean
---

# Scope review — clean

R4 diff is narrow (40 lines) and reflects only R3's targeted fix:

- Slice 1.1 Surface/Demonstrable: `change_type` → `finding-categorization` discipline/values.
- Phase 1 acceptance gate item 1: `change_type enum silent fall-through` → `finding-categorization enum silent fall-through`; `model routing` → `model-routing` (hyphenated descriptor).
- Phase 1 acceptance gate item 2: `missing model_routing` → `missing dispatch-routing config`; `invalid change_type` → `invalid finding categorization`.

## DEFERS compliance

Replacements describe capabilities and disciplines (`dispatch-routing config`, `finding-categorization`, `model-routing fallbacks`) rather than naming schema fields, enum identifiers, or interface contracts. No Implement / Structure / Plan jargon remains in the diffed surface.

## OWNS compliance (no over-stripping)

Slice 1.1 still articulates an end-to-end demonstrable surface (verifier sidecar pipeline + finding-categorization discipline + reviewer disk-write reliability), and Phase 1 acceptance gates still enumerate the specific failure classes that must not recur. Semantic content preserved.

## Outside-hint scan

Nothing significant outside `## Slices` / `## Phases` in this diff.

No scope findings.
