# Plan round-3 dispositions

## Convergence trend
| Round | Findings emitted | Kept after verifier | Notes |
|-------|------------------|---------------------|-------|
| R1    | 46               | 46                  | Codex partial (4 of 7); 0 dropped at verifier |
| R2    | 30 (Claude only) | 22                  | Codex absent (full usage-limit failure); 8 dropped at verifier per round-2 lightweight-task calibration |
| R3    | 17 (Claude only) | 17                  | Codex absent (still pending usage-limit catch-up); 0 dropped — all 17 findings independently verifiable and load-bearing |

R1→R2→R3 trajectory: 46 → 22 → 17. Steady convergence (-52% R1→R2, -23% R2→R3). Round 3's emission is dominated by the T43 cleanup cluster (10 of 17 findings converge on the round-2-added conditional task), not by net-new defect surface. Outside the cluster, only 7 findings emerged: 4 quality cleanups (T20 LOC, T34 sidecar phrasing, Slice 7 phrase, T43 frontmatter doc), 3 security gaps (IPv6 ::1, sibling-allowed bounds, T33 realpath). Convergence on track for round-4 clean or near-clean.

## Kept findings (by change_type)

### T43 cleanup cluster (consolidated rewrite, 10 findings)
- quality-claude.R3-F01 — T43 lists plan.md as Modify target with self-canceling disclaimer
- quality-claude.R3-F03 — `conditional:` frontmatter field undocumented in canonical schema
- quality-claude.R3-F04 — T36 Path B references `openai-chat-completions` transport contradicting T43 exclusion
- quality-claude.R3-F06 — "implementation log" artifact undefined in pipeline
- spec-claude.R3-F01 — T43 plan.md (Modify) target contradicts body
- spec-claude.R3-F02 — "Anthropic SDK path" transport_type not in T01 schema
- silent-failure-claude.R3-F01 — T43 missing loud-failure on absent/malformed/stale spike report
- silent-failure-claude.R3-F02 — "implementation log" undefined; vacuous-skip-pass audit hole
- silent-failure-claude.R3-F03 — **CRITICAL:** T03/T43 cache_control ownership conflict; T03's unconditional emission contaminates T33 spike measurement
- goal-traceability-claude.R3-F01 — same plan.md target stale (agrees with quality.R3-F01)
- test-coverage-claude.R3-F01 — "Anthropic SDK path" prevents deterministic fixture authorship

### Auto-apply (correctness, outside cluster)
- quality-claude.R3-F02 — T34 dangling sidecar reference phrased as binding
- quality-claude.R3-F05 — T20 LOC estimate stale after round-2 audit-scope expansion
- quality-claude.R3-F07 — Slice 7 "replan acceptance block" phrasing ambiguous
- security-claude.R3-F01 — T03/T07 SSRF list omits IPv6 loopback `::1`
- security-claude.R3-F02 — T27/T30 `sibling_allowed_paths:` escape hatch unbounded
- security-claude.R3-F03 — T33 `--report-out` validation missing path normalization

### Pause for user (intent)
- None this round.

## Dropped at verifier (score < 70)
- None this round. All 17 findings scored ≥70.

## Round-3-specific decisions

### T43 cluster resolution — cache_control ownership architecture
The load-bearing decision is silent-failure-claude.R3-F03 (CRITICAL). The current plan had T03 unconditionally emitting `cache_control` whenever `supports_prompt_cache: true`, which:
- contaminates T33's spike measurement (probe runs already have markers inserted by T03 before T33 measures whether the platform caches automatically),
- makes Path A vs Path B undetectable at measurement time,
- renders T43 redundant or contradictory.

**Resolution applied (variant of silent-failure-claude.R3-F03 Resolution 1):** introduced a NEW per-provider config field `emit_cache_control_markers:` (default `false`) layered on top of the existing `supports_prompt_cache:` capability gate. The dispatcher (T03) emits `cache_control` ONLY when BOTH flags are `true` (the dual-flag gate). T01's schema documents the new field; T03's description and test expectations enumerate the four-cell truth table; T07 and T36 cover the truth table in their pins; T43 becomes a NO-OP under Path A and a one-flag-flip per-provider-entry under Path B (no `scripts/run-third-party-llm.sh` modification at all).

Side effects of the resolution that cleared the rest of the cluster in one rewrite:
- T43 target files reduce to `<artifact-dir>/config.md` (Modify) — plan.md and `scripts/run-third-party-llm.sh` are no longer touched by T43 (clears quality.R3-F01, spec.R3-F01, goal-traceability.R3-F01).
- "Anthropic SDK path" language eliminated everywhere; the gate is now the dual-flag combination, which is an observable schema condition (clears spec.R3-F02, quality.R3-F04, test-coverage.R3-F01).
- "implementation log" mapped to the canonical "implementer's terminal DONE report" with `status: skipped` field — the existing canonical artifact per implementer-protocol/SKILL.md (clears quality.R3-F06, silent-failure.R3-F02).
- Loud-failure expectations added for absent/malformed spike report AND stale spike report (run-ID mismatch against `g4-cache-probe.lock`) (clears silent-failure.R3-F01).
- `conditional:` and `conditional_precondition:` frontmatter fields documented in a new `## Task Specs` preamble; T43 carries both fields (clears quality.R3-F03).

### Other applied fixes
- T20 LOC bumped 60 → 120 with audit-driven upper-bound rationale and opus-escalation note.
- T34 sidecar reference rephrased as a non-binding tracking TODO; implementer is explicitly NOT required to action the structure.md amendment.
- Slice 7 acceptance L122 reworded: "gated in the replan acceptance block" → "observed in the Phase 1 replan-gate criteria".
- T03 SSRF carve-out list gains `::1` (IPv6 loopback) alongside `127.0.0.0/8`; T07 pin gains `[::1]` fixture coverage on/off the carve-out env var.
- T27 path-validation gains bounded-tree constraint on `sibling_allowed_paths:` entries (artifact-dir or worktree root only); T30 reference-gate-fields pin gains out-of-tree sibling-allowed rejection fixture.
- T33 `--report-out` validation requires `realpath`-normalization before prefix check, with explicit `docs/qrspi/../../../etc/shadow` fixture.

## Codex status
- Round 3 ran Claude-only as instructed; codex catch-up STILL pending post-usage-limit-reset. The round-1 codex partial pass (4 of 7 reviewers) and the round-2 codex full absence have not been augmented. Recommendation: defer codex catch-up to after round-4 unless round-4 also fails cleanly, since the load-bearing cache_control architecture decision is now landed and a third independent reviewer view would add convergence confidence without changing the path forward. If round-4 is clean and the catch-up codex pass emits >2 new high-severity findings, that signals the Claude-only review loop missed a real class — at that point the catch-up becomes mandatory before approval.

## Next step
- Round 4 review after round-3 fixes applied.
- Expected emission: 5–10 findings, mostly downstream-of-T43-cluster consistency (any references to the old single-flag gate that round-3 did not catch) plus possibly 1–2 new low-severity quality findings. No new architecture issues expected.
- Optional: catch-up codex pass post-limit-reset, ideally folded into round-4 or round-5.
