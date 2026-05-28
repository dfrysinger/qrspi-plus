# Plan round-3 fixes

## Summary
- 17 findings emitted (Claude only; codex still pending usage-limit reset).
- 17 findings kept (all scored ≥70 at verifier).
- 17 findings applied (10 via T43 cleanup-cluster consolidated rewrite, 7 via individual edits).
- Plan.md line delta: 1304 → 1308 (+4 lines net). The T43 rewrite was largely a re-scoping of an existing block; the cluster's net additions were balanced by the T43 target-files reduction (from 2 files to 1) and the deletion of the "Anthropic SDK path" prose.

## Per-finding application status

### T43 cleanup cluster — applied as ONE consolidated rewrite of T43 + dual-flag schema additions to T01/T03/T07/T36
| Finding | Status | Notes |
|---|---|---|
| quality-claude.R3-F01 | APPLIED | plan.md removed from T43 target files |
| quality-claude.R3-F03 | APPLIED | `conditional:` / `conditional_precondition:` documented in new `## Task Specs` preamble |
| quality-claude.R3-F04 | APPLIED | T36 Path B language now references dual-flag gate, not transport |
| quality-claude.R3-F06 | APPLIED | "implementation log" replaced everywhere with "implementer's terminal DONE report" + `status:` field |
| spec-claude.R3-F01 | APPLIED | plan.md removed from T43 target files (same edit as quality.R3-F01) |
| spec-claude.R3-F02 | APPLIED | "Anthropic SDK path" eliminated; gate is now dual-flag combination |
| silent-failure-claude.R3-F01 | APPLIED | T43 test expectations now require loud failure on absent/malformed/stale spike report; lock-file run-ID match enforced |
| silent-failure-claude.R3-F02 | APPLIED | DONE report `status: skipped` is the observable skip artifact (no new artifact invented) |
| silent-failure-claude.R3-F03 | APPLIED — load-bearing | Added `emit_cache_control_markers:` config field (default `false`); T03 emits only on dual-flag true; T43 sets the new flag on Path B; T33 spike measurement integrity preserved |
| goal-traceability-claude.R3-F01 | APPLIED | plan.md removed from T43 target files (same edit) |
| test-coverage-claude.R3-F01 | APPLIED | Dual-flag gating provides deterministic, observable fixture condition |

### Outside-cluster fixes
| Finding | Status | Notes |
|---|---|---|
| quality-claude.R3-F02 | APPLIED | T34 sidecar reference rephrased as non-binding tracking TODO; implementer explicitly NOT required to action the structure.md amendment |
| quality-claude.R3-F05 | APPLIED | T20 LOC estimate bumped 60 → 120 with audit-driven upper-bound rationale + opus-escalation note for >6 drift fixes |
| quality-claude.R3-F07 | APPLIED | Slice 7 acceptance L122 reworded "gated in the replan acceptance block" → "observed in the Phase 1 replan-gate criteria" |
| security-claude.R3-F01 | APPLIED | T03 SSRF list now includes IPv6 `::1` with same carve-out rule as `127.0.0.0/8`; T07 pin covers `[::1]` fixture both with and without carve-out env var |
| security-claude.R3-F02 | APPLIED | T27 path-validation now requires `sibling_allowed_paths:` entries to lie within artifact-dir or worktree root; T30 reference-gate-fields pin covers out-of-tree sibling-allowed rejection (e.g., `["/etc"]`) |
| security-claude.R3-F03 | APPLIED | T33 `--report-out` validation now requires `realpath` normalization before the `docs/qrspi/` prefix check, with `docs/qrspi/../../../etc/shadow` fixture asserting rejection |

## Architecture decision recorded
The cache_control emission ownership architecture was redesigned via a NEW per-provider config field `emit_cache_control_markers:`. The default is `false`. Dispatcher emits cache_control IFF `supports_prompt_cache: true` AND `emit_cache_control_markers: true`. This:
1. Preserves T33 spike measurement integrity (probe runs see no auto-inserted markers regardless of `supports_prompt_cache:` values).
2. Eliminates the T03/T43 file-ownership conflict (T43 now only touches `<artifact-dir>/config.md`, not the dispatcher script).
3. Makes the Path B activation a single one-flag-flip per provider entry — minimal, auditable, easy to roll back.
4. Provides a deterministic, observable schema condition for T07 + T36 truth-table coverage (no transport-type ambiguity).

The decision is recorded in T01 schema, T03 description + truth table, T07 truth-table pin coverage, T36 dual-flag pin coverage, and T43's restructured target/description/test-expectation block.

## Files touched
- `docs/qrspi/2026-05-17-v07-release/plan.md` (Modify) — 14 distinct edits across:
  - Slice 7 acceptance criteria (L122, L123)
  - `## Task Specs` preamble (new)
  - T01 description + 1 test expectation
  - T03 description + 2 test expectations (SSRF carve-out + cache_control truth table)
  - T07 2 test expectations (SSRF + dual-flag)
  - T20 frontmatter loc_estimate + LOC rationale
  - T27 path-validation test expectation
  - T30 reference-gate-fields test expectation
  - T33 path-validation test expectation
  - T34 description sidecar phrasing
  - T36 1 target-files line + 1 description line + 2 test expectations
  - T43 — full rewrite (frontmatter + Conditional + Target files + Dependencies + LOC + Description + all 4 test expectations)

## Round-4 outlook
Expected emission: 5–10 findings. Likely categories:
- Consistency sweep for any "Anthropic SDK path" or "supports_prompt_cache only" residue the round-3 sweep missed (low risk).
- Possible quality finding on the new `conditional_precondition:` field schema — does Implement skill consume this? (cross-skill consistency at Plan-skill ↔ Implement-skill boundary.)
- Possible silent-failure finding on the `emit_cache_control_markers:` field default at T01-resume (if a legacy config without the field is loaded, does the dispatcher loud-warn or silently default?).
- Possible test-coverage finding on T07's four-cell truth table: does it cover BOTH transport-type branches × four cells, or just one branch?

No new architecture issues expected. Round-4 should be near-clean (≤10 findings, all low/medium correctness). Round-5 likely clean.

## Convergence trend assessment
R1=46, R2=22, R3=17. Decay ratio R2/R1 = 0.48, R3/R2 = 0.77. The R3/R2 ratio is higher than R2/R1 because R3 surfaced the round-2-added-T43 defect cluster (a localized but high-density region of new emission), not because overall plan quality is regressing. With the T43 cluster fully resolved, R4 should resume the R2/R1 decay rate — projecting ~10 findings R4, ~5 findings R5. **On track for round-4 near-clean and round-5 clean.**

## Codex catch-up status / recommendation
- Round 1: codex partial (4 of 7 reviewers); 3 reviewers failed.
- Round 2: codex full absence (usage-limit).
- Round 3: codex not attempted (still pending limit-reset window per round-2-closure note).

Recommendation: Defer codex catch-up to between rounds 4 and 5. If round-4 is near-clean as projected, fold the catch-up codex pass into a final pre-approval validation. If codex emits >2 high-severity findings during catch-up that Claude missed, hold approval and run one more Claude+codex round; otherwise approve.
