---
status: approved
release: qrspi-plus v0.7.2
phase_count: 1
total_goals: 35
---

# v0.7.2 Roadmap

Canonical phase → slice → goal-ID mapping. Source of truth consumed by
Structure, Plan, and Replan.

## Phase 1 — v0.7.2 release

| Slice | Goal IDs | Theme |
|---|---|---|
| 1.1 Apply-fix / verifier backbone | G6, G7, G8, G11, G12, G13, G14 | Verifier sidecar pipeline + finding-categorization discipline + reviewer disk-write reliability |
| 1.2 Verifier rubric calibration + instrumentation | G19, G20, G28, G29 | Hallucination class + model calibration + dispositions instrumentation |
| 1.3 Per-task review pipeline corrections | G9, G15, G18 | Implement-phase per-task review orchestration |
| 1.4 Dispatch infrastructure | G3, G4, G16, G22, G23, G24 (F02, F04), G25, G27 | Splitter + diff helper + path filter + dispatch-routing config schema + dispatch-routing H4 paragraph edit-surface (G24-F02 prose, G24-F04 tier-regex, G25 fail-loud invariant) + Codex helper |
| 1.5 Skill prose & interactive dialog quality | G1, G2, G5, G10, G17, G30, G31, G33, G34 | SKILL.md prose hardening + Goals/Design dialog quality |
| 1.6 Structure SKILL absorbs unified architecture | G35 | Structure re-scoping |
| 1.7 Build & release tooling + test-infrastructure hardening | G21, G24 (F01, F03, F05), G26, G32 | Bats hardening + helper deduplication + anti-pattern pin regex + plugin build pipeline |

**Goal-ID coverage:** 7 + 4 + 3 + 8 + 9 + 1 + 4 = 36 slice-entries covering
35 distinct goal IDs. G24's five sub-findings split across two slices per the
clustering in goals.md's Cross-Cutting Notes: F02 + F04 (dispatch-routing
edit surface) ride with slice 1.4 alongside G22/G23/G25/G27; F01 + F03 + F05
(test-infrastructure / test-gate-hardening edit surface) ride with slice 1.7
alongside G21/G26. G24 is enumerated in both slices but counts as one distinct
goal in the 35-goal total — the 36-entry sum reflects the shared listing.

## Future phases

None. v0.7.2 is a single-phase release.
