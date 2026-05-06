# Deferred Reviewer Migration: Per-Finding Emission + Reviewer-Protocol Bifurcation Collapse

**Status:** Design
**Issue:** [#125](https://github.com/dfrysinger/qrspi-plus/issues/125)
**Milestone:** v0.5
**Date:** 2026-05-05
**Predecessor:** [#109 — Sonnet→Haiku confidence verifier](2026-05-04-109-sonnet-haiku-verifier-design.md) — established the per-finding contract and migrated 14 of 32 reviewer-class agents.

## 1. Overview

#109 introduced the per-finding disk-write contract and migrated 14 reviewers (8 quality + 6 scope) for `goals/questions/research/design/phasing/structure/parallelize/replan`. The remaining 18 reviewers — Plan-stage, per-task, and integration-class — still use the legacy single-file-per-reviewer contract (`reviews/{step}/round-NN-{reviewer-tag}.md`). The reviewer-protocol skill carries both contracts in parallel.

This issue migrates all 18 deferred reviewers to per-finding emission in a **single atomic cutover commit**, then collapses the reviewer-protocol bifurcation back to a single per-finding contract.

## 2. Atomicity Constraint

**The cutover is one commit.** Splitting it across commits would produce a runtime state where a single Plan review round dispatches reviewers using mixed contracts: some emit per-finding files, some emit a single legacy file. The apply-fix protocol's schema-violation guard (#109) cannot reason about a mixed round — it expects either per-finding files OR no output (the clean-sentinel case) for every expected reviewer tag in `## Expected-Reviewer Matrix`. A mixed round corrupts the matrix.

**Why Plan in particular.** Plan's review round dispatches up to 7 Claude reviewers in parallel (unified plan-quality + 5 plan-artifact + scope-reviewer) plus 7 Codex parallels. Currently 0/7 use per-finding emission. After cutover: 7/7. The transition window must be one commit because Plan re-runs that hit the window mid-edit dispatch one tag's reviewer with the new contract and another tag's reviewer with the old, against a shared `reviews/plan/round-NN/` directory.

**Implementation discipline.** All agent-file edits + all dispatching-SKILL edits + the reviewer-protocol edit + the test updates land in **one squash-merged PR with one final commit** (development can use multiple commits during PR iteration; the merge is a single commit on main).

## 3. Migration Scope

### 3.1 Deferred reviewers (18 agent files)

Verified by listing `agents/qrspi-*reviewer*.md` + `qrspi-*hunter*.md` + `qrspi-*analyzer*.md` + `qrspi-code-simplifier.md`, subtracting the 14 already-migrated #109 reviewers:

**Plan-artifact reviewers (5):**
- `agents/qrspi-plan-spec-reviewer.md`
- `agents/qrspi-plan-security-reviewer.md`
- `agents/qrspi-plan-goal-traceability-reviewer.md`
- `agents/qrspi-plan-test-coverage-reviewer.md`
- `agents/qrspi-plan-silent-failure-hunter.md`

**Unified plan quality + scope (2):**
- `agents/qrspi-plan-reviewer.md`
- `agents/qrspi-plan-scope-reviewer.md`

**Per-task reviewers (8):**
- `agents/qrspi-spec-reviewer.md`
- `agents/qrspi-code-quality-reviewer.md`
- `agents/qrspi-security-reviewer.md`
- `agents/qrspi-goal-traceability-reviewer.md`
- `agents/qrspi-test-coverage-reviewer.md`
- `agents/qrspi-silent-failure-hunter.md`
- `agents/qrspi-type-design-analyzer.md`
- `agents/qrspi-code-simplifier.md`

**Implement-gate (1):**
- `agents/qrspi-implement-gate-reviewer.md`

**Integration-class (2):**
- `agents/qrspi-integration-reviewer.md`
- `agents/qrspi-security-integration-reviewer.md`

**Total: 18 agent files.**

### 3.2 Per-agent edit shape

Each agent file currently contains either explicit single-file legacy contract prose or a reference to "the disk-write contract from the reviewer-protocol skill" that resolves to `## Legacy Disk-Write Contract` via the routing table. Since the routing table goes away in this cutover (§4.1), the edit shape per agent depends on what's in the file today:

**If the agent body cites a specific path pattern** (e.g., `Output file: reviews/{step}/round-NN-{reviewer-tag}.md`): replace with `reviews/{step}/round-NN/<reviewer_tag>.finding-F<NN>.md` per-finding pattern + clean-sentinel reference.

**If the agent body just defers to the protocol** (e.g., the audited `qrspi-plan-reviewer.md` body says "conforming to the disk-write contract from the reviewer-protocol skill"): no agent-file edit needed for the contract — the protocol redirect resolves to the new (single, unified) per-finding contract once §4.1 lands.

**Audit pass during implementation.** For each of the 18 agent files, grep for `round-NN-` and explicit legacy-shape language. Files with no path-specific prose need no edit; files with path-specific prose need surgical updates.

## 4. Reviewer-Protocol Skill Updates

### 4.1 Bifurcation collapse

**Sections affected:** `skills/reviewer-protocol/SKILL.md`

| Section | Current state (pre-cutover) | Post-cutover |
|---|---|---|
| `## Reviewer-Tag Routing Table` (lines 19–29) | Bifurcates by tag, points to two contract sections | **Removed.** No bifurcation; one contract. |
| `## Expected-Reviewer Matrix` (lines 31–46) | Covers 8 #109 steps only; line 46 says "Plan, Implement-gate, Integrate, Test are out of scope for #109 — see follow-up issue." | **Extended** to cover Plan, Implement-gate, Integrate, Test. Line 46's parenthetical is removed. |
| `## Legacy Disk-Write Contract (deferred reviewers)` (lines 160–202) | The legacy single-file contract | **Removed in entirety.** |
| `## Per-Finding Disk-Write Contract (#109 reviewers)` (lines 204–256) | The per-finding contract, qualified to #109 reviewers | **Renamed** to `## Per-Finding Disk-Write Contract`. The "(#109 reviewers)" qualifier is removed. Otherwise the section is unchanged — its prose already covers all reviewer tags now that no others remain. |

**Cross-references updated.** Lines that mention the bifurcation (e.g., line 21's "The reviewer protocol bifurcates during the #109 migration window") are removed or rewritten.

### 4.2 Expected-Reviewer Matrix extension

The matrix table gets new rows for Plan, Implement-gate, Integrate, Test. Each row's expected tags are derived from the dispatching SKILL today:

| Step | `codex_reviews: true` | `codex_reviews: false` |
|---|---|---|
| `plan` | `quality-claude`, `scope-claude`, plus 5 plan-artifact reviewer tags (`plan-spec-claude`, `plan-security-claude`, `plan-goal-traceability-claude`, `plan-test-coverage-claude`, `plan-silent-failure-hunter-claude`) and their Codex counterparts where applicable | claude-only equivalents |
| `implement-gate` | `implement-gate-claude`, `implement-gate-codex` | `implement-gate-claude` |
| `integrate` | `integration-claude`, `security-integration-claude`, plus Codex counterparts | claude-only equivalents |
| `test` | `test-coverage-claude`, plus Codex counterpart | `test-coverage-claude` |

**Authoritative source for tag names.** During implementation, derive each tag from the dispatching SKILL.md — these names must match what the dispatcher actually passes as `reviewer_tag`. The table above is illustrative; the implementer reconciles against grep of dispatcher SKILLs before writing the final table.

## 5. Dispatching-SKILL Updates

The dispatching skills that currently emit legacy single-file output paths must switch to per-finding round-directory paths in their reviewer dispatch logic.

**Sites to audit + edit** (verified by `grep -lE 'round-NN-\{|Output file:.*round-NN-'`):

- `skills/plan/SKILL.md` — Plan reviewer dispatch (7 Claude + 7 Codex sites)
- `skills/implement/SKILL.md` — per-task reviewer dispatch (8 Claude + Codex parallels per task) and implement-gate dispatch
- `skills/integrate/SKILL.md` — integration + security-integration dispatch
- `skills/test/SKILL.md` — test-coverage dispatch
- `skills/replan/SKILL.md` — verify already-migrated state; the replan-reviewer was migrated by #109 but the SKILL may carry residual legacy-shape prose for adjacent reviewers
- `skills/using-qrspi/SKILL.md` — `## Review Output Handling` doc; update to drop the bifurcation reference

**Edit shape (per dispatch site).** Replace the `Output file: reviews/{step}/round-NN-{reviewer-tag}.md` parameter with `Output directory: reviews/{step}/round-NN/` (the reviewer constructs the per-finding filename per the protocol contract).

## 6. Test Updates

Per #125 issue body, four tests added by #109 currently skip the deferred reviewers with a comment citing this issue number. They must extend on cutover:

- `tests/unit/test-per-finding-file-emission.bats` (test #2 in #109 plan)
- `tests/unit/test-clean-sentinel-and-schema-guard.bats` (test #4)
- `tests/unit/test-change-type-partition.bats` (test #6)
- `tests/unit/test-failure-menu.bats` (test #10)

**Edit shape (per test):** remove the deferred-reviewer skip block; extend assertions to iterate over the full reviewer-tag set including the 18 newly-migrated tags. The fixture set in `tests/fixtures/issue-109/` may need new fixtures for plan/implement-gate/integrate/test rounds — assess during implementation.

**New test:** `tests/unit/test-no-legacy-disk-write-references.bats` — grep guard:

```bash
@test "no agent file references the legacy round-NN-{tag}.md path pattern" {
  local offenders
  offenders=$(grep -rE 'round-NN-\{?[a-z-]+\}?\.md' agents/ skills/ \
    | grep -v 'reviewer-protocol/SKILL.md' \
    || true)
  if [ -n "$offenders" ]; then
    echo "legacy single-file path references remain:"
    echo "$offenders"
    return 1
  fi
}

@test "reviewer-protocol skill carries no Legacy Disk-Write Contract section" {
  ! grep -qE '^## Legacy Disk-Write Contract' skills/reviewer-protocol/SKILL.md
}

@test "reviewer-protocol skill carries no Reviewer-Tag Routing Table" {
  ! grep -qE '^## Reviewer-Tag Routing Table' skills/reviewer-protocol/SKILL.md
}
```

Three assertions, ~25 lines of bats. Catches future regression to the bifurcated state.

## 7. Sequence

**Single PR.** Single squash-merged commit on main (per §2). During PR development the work can split across commits for reviewability:

1. **`refactor(agents): migrate 18 deferred reviewers to per-finding contract`** — touches the agent files in §3.1.
2. **`refactor(skills): switch dispatching skills to per-finding output paths`** — Plan/Implement/Integrate/Test/Replan/using-qrspi.
3. **`refactor(reviewer-protocol): collapse bifurcation`** — drops Legacy section, Routing Table; renames per-finding section; extends matrix.
4. **`test: extend per-finding tests + add legacy-pattern guard`** — updates the four #109 tests, adds the new grep guard test.

The squash merges these into one cutover commit on main. Developmentally splitting them is fine; **squashing on merge is required**.

## 8. Test Plan

- Full bats suite green: `bats tests/unit/`
- New legacy-pattern grep guard passes
- Existing #109 tests extended and passing across all 32 reviewer tags
- Manual smoke (deferred to a v0.5 follow-up review run): one Plan review round in a real artifact dir produces a `reviews/plan/round-NN/` directory with per-finding files for every expected tag, no legacy `round-NN-{tag}.md` files written

## 9. Backwards Compatibility

**None preserved.** The cutover is breaking by design — the bifurcation existed only to permit incremental #109 migration, and #125 closes that window.

**In-flight artifact dirs.** A `reviews/{step}/` directory authored before cutover contains legacy `round-NN-{reviewer-tag}.md` files. After cutover, new rounds in the same artifact dir create `round-NN+1/` per-finding directories. Reading older legacy rounds is not affected — they remain on disk untouched. The apply-fix protocol only reads the most recent round; it does not need to interpret older rounds in the new shape.

**Fix-round dispatches mid-rebase.** A user rebasing a review-round branch onto the cutover commit must restart the in-flight review round from scratch (a fresh round on the new contract). Mid-round files cannot mix contracts. Document this in the commit message and PR body.

## 10. Out of Scope

- **Extending the `scope_tag` field** (#112) — not a precondition for cutover. Lands in a separate PR after #125 merges.
- **Renaming `round-NN-fixes.md` → `round-NN-dispositions.md`** (#113) — the `round-NN-fixes.md` filename is the fix-round per-finding-disposition file, downstream of reviewer findings. Independent of this migration.
- **Adding new reviewer tags or splitting existing ones.** Migration only — preserves the current reviewer-tag set.
- **Centralizing duplicated reviewer-dispatch wrapper-marker boilerplate via `!cat`** (#130, v0.6) — the wrapper-marker prose duplicated across Plan/Implement/Integrate/Test/Replan lives on different lines than what this cutover edits. Folding it in would roughly double the diff and review burden. Cleaner sequencing: #125 atomic cutover lands first, #130 refactors the centralization on top.
- **Performance work** on the parallel-dispatch fan-out. Per-finding emission is structurally faster than legacy single-file (no rewriting one file per finding) but quantifying that is not a §10 deliverable.

## 11. Closes

- Closes #125

## 12. Open Questions for User

(Surfaced for explicit confirmation before implementation begins, since this is the largest spec in the v0.5 spec round.)

- **§4.2 Expected-Reviewer Matrix tag names.** The illustrative names (`plan-spec-claude`, `implement-gate-claude`, `test-coverage-claude`, etc.) may not match what the dispatchers currently pass. Implementer reconciles by grep — flagging here in case any tag rename is desired during this cutover (recommended: no, keep cutover migration-only per §10).
- **§9 in-flight rebase guidance.** Does this need explicit bats coverage, or is the commit-message + PR-body warning sufficient? Recommended: warning only — automated coverage of mid-rebase user behavior isn't a thing.
