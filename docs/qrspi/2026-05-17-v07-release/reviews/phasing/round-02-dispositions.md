---
round: 2
artifact: phasing
status: fixing
---

# Phasing Round 2 dispositions

## Findings inventory

- quality-claude: 2 findings (medium=1, low=1)
- scope-claude: 2 findings (medium=1, low=1)
- quality-codex: 1 finding (medium=1)
- scope-codex: 1 finding (HIGH=1)

Total: 6 findings → 4 distinct (2 cross-reviewer matches). 1 HIGH. All accept.

Convergence trend: round 1 had 9 findings (4 distinct after dedupe/reject), round 2 has 4 distinct. Trending down. Scope-claude false-positive warning in dispatch prompt worked — no missing-deliverable claims this round.

## Cross-reviewer matches

- quality-claude R2-F02 + quality-codex R2-F01: G16 Goal-ID Consistency claim wrong.
- scope-claude R2-F01 + scope-codex R2-F01: Slice 5 wave-numbering + task-spec fields. (scope-codex flagged this HIGH for broader Plan/Parallelize/Implement boundary cross.)

## ACCEPT (4 distinct)

### R2-F01 scope-codex (HIGH, scope — overlaps scope-claude F01) — Slice 5 boundary drift

Slice 5 specifies concrete task-spec field names (`reference-gate`, `reference-artifact`, `ui-flag`, `lift-source`), wave-boundary behavior ("wave-1 task pauses Implement before wave-2"), Implement pause procedure, approval recording, duplicate-agent constraints. Crosses Plan (task specs), Parallelize (wave decisions), Implement (dispatch behavior).

**Fix:** Rewrite Slice 5 description AND its replan-gate criterion to phase-level outcomes only. Strip ALL of:
- Specific task-spec field names → use "task-spec-level signal for UI work"
- Wave-1/wave-2 numbering → use "ordering between dependent reviews"
- Implement pause procedure → use "human gate fires before downstream dependents proceed"
- Approval recording / duplicate-agent constraints → omit (these are Implement-level)

Replace with: "Slice 5 delivers visual-fidelity reviewing for UI-producing work and reference-rendering at human gates. Demonstrates: a UI-producing task surfaces its visual reference at the human gate in a renderable form (not just a path); the visual-fidelity reviewer participates in review cycles for UI tasks with awareness of sibling reviews in the same wave."

### R2-F01 quality-claude (medium, clarity) — Slice 3 gate criterion FD-02 reference not self-contained

The Slice 3 replan-gate criterion at L75 carries the parenthetical "(Full resolution context lives in future-design FD-02.)" — readers must consult a deferred future-design entry to understand what the criterion asserts. Replan-gate criteria must be self-contained.

**Fix:** Inline the contrapositive framing per FD-02 and drop the future-design reference: "CI's bash-3.2 docker job is the load-bearing backstop. The grep ban-list catches known bash-4 constructs early; the docker job validates the ban-list remains current by execution test, surfacing any new bash-4 construct authors introduce that the ban-list does not enumerate."

### R2-F02 quality-claude + R2-F01 quality-codex (medium, correctness — double-flag) — Goal-ID Consistency claim wrong on G16

phasing.md claims "Every goal ID listed in `roadmap.md` is accounted for above" but G16 (in roadmap as `phase: future`) is not mentioned in slices/phases. The "No orphan IDs" claim is technically correct (G16 isn't orphaned — it's deferred), but the preceding consistency claim misleads.

**Fix:** Rewrite the `## Goal-ID Consistency` section to distinguish current-phase IDs from deferred IDs:
- "Every current-phase goal ID listed in `roadmap.md` (G1–G15, G17–G18) is accounted for in the slices above. G16 carries `phase: future` and is deferred to a later release; its full context lives in `future-goals.md` and `future-design.md`. No orphan IDs."

### R2-F02 scope-claude (low, scope) — Slice 7 implementation-mechanism wording

Slice 7's description and gate use "marker-insertion," "prefix shape and marker placement decision" — Implement-level mechanism wording.

**Fix:** Rewrite Slice 7 description and replan-gate criterion to outcome-observable: "Slice 7 delivers a measurement-grounded decision about whether the platform's existing caching behavior covers the high-token-cost dispatch surface, and a follow-up implementation if it does not. Demonstrates: a written deliverable records the hit-rate behavior of representative dispatches on stable prefixes; downstream implementation work is either green-lit-by-measurement or scoped against the gap the measurement surfaced."

## Fix dispatch plan

Single fix subagent. 4 distinct accepts. All in phasing.md.

## Status

draft → fixing → re-review round 3.
