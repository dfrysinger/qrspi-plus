# Structure round-2 dispositions

5 findings emitted; 4 verified and applied to `structure.md`; 1 dropped at verifier (score 10, premature).

## Applied (4)

- **scope-codex R2-F01** (medium, scope; verified 75) — Rewrote `.github/workflows/ci.yml` Interfaces block. Removed YAML skeleton, comment step stubs, `docker run ... sh -c "apk add ..."` command stub, package list. Replaced with prose-only boundary description naming file, two-job shape, trigger families, concurrency, action-pinning, Integrate CI signal — with explicit defer to Plan/Implement.

- **quality-codex R2-F01** (HIGH, correctness; verified 85) — Rewrote Slice 8 `skills/implementer-protocol/SKILL.md` Responsibility. Removed "literal command sequence ... preserved" wording (would have kept the G12 bug). Replaced with three-invariants-only contract; procedure deferred to Plan/Implement per Design G12.

- **quality-claude R2-F01** (medium, correctness; verified 95) — Added `tests/unit/test-test-writer-dual-mode.bats` to `G14Consumers` diagram node.

- **quality-claude R2-F02** (low, correctness; verified 75) — Reversed Slice 5 arrow `PlanSkill5 -> StructureSkill5` to `StructureSkill5 -.provides UI Reference Affordances.-> PlanSkill5`.

## Stale / dropped (1)

- **quality-codex R2-F02** (medium, correctness; verified 10) — Claim: G4 Slice 7 missing section-anchor-index file allocations. Dropped because G4 is a measurement spike (Iron Law 1 departure per phasing.md); the spike outcome decides Path A (prefix caching alone) vs Path B (anchor index needed). Pre-spike file allocation would prematurely commit to Path B. Design G4 explicitly defers anchor-index file allocation to post-spike outcome.

## Deferred / intent-class (0)

None.

## Notes

- Verifier scores: scope-codex.F01=75, quality-codex.F01=85, quality-codex.F02=10 (DROPPED), quality-claude.F01=95, quality-claude.F02=75.
- Round 2 had no diff narrowing (file still untracked). Round 3 likewise.
- scope-claude returned clean for round 2.
- Trend: round 1 had 5/5 kept; round 2 had 4/5 kept (1 dropped). Looking for convergence in round 3.
