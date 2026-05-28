---
round: 4
artifact: phasing
status: fixing
---

# Phasing Round 4 dispositions

## Findings inventory

- quality-claude: 2 (medium=1, low=1)
- scope-claude: 1 (low=1)
- quality-codex: 1 (medium=1)
- scope-codex: 1 (medium=1)

Total: 5 findings, 0 HIGH. All accept. Convergence trend: 9 → 6 → 5 → 5. Severity dropped (no HIGH this round).

## ACCEPT (5 distinct)

### R4-F01 quality-codex (medium, correctness) — future-design.md contains v0.7 corrections mislabeled as future deferrals

FD-01 (G1 schema test), FD-02 (G17 bash-3.2 fixture), FD-03 (G3 boundary test enum), FD-04 (G3 line-count attribution) are corrections to current-phase v0.7 decisions accepted-but-not-fixed at round-18 (per user-approved targeted-fix path). They are NOT future-release deferrals. The future-design.md frontmatter source field acknowledges this (`source: design-round-18-deferrals + v07-phasing-deferrals`), but the category label is conflated.

**Fix:** Restructure future-design.md to clearly separate two categories:
- **Category A — Future-release deferrals.** G16 (genuine deferral to a later release).
- **Category B — v0.7 known issues accepted at round-18 disposition gate.** FD-01, FD-02, FD-03, FD-04 (v0.7 design-quality polish items the user explicitly chose not to fix; recorded for future-release pickup or accept-as-is).

Update the file's H1, intro paragraph, and section organization. Update phasing.md `## Pruning Summary` line for design.md to reflect the corrected categorization:
- `design.md` — current-phase: G1–G15, G17, G18 + Decisions 1–10. Deferred to `future-design.md`: G16 (future-release deferral) and FD-01..FD-04 (v0.7 known issues accepted at round-18 gate).

### R4-F01 scope-codex (medium, scope) — Slice 1 replan gate too specific

Slice 1's replan gate names `model_routing:` key, lists transports (DeepSeek, etc.), names dispatch instrumentation details, requires "no per-call-site special-casing." Those are downstream Plan/Structure/Implement constraints, not phase-level observables.

**Fix:** Rewrite Slice 1 replan gate to observable-only phase boundary: "A configured non-Anthropic routing site dispatches through the universal dispatcher to the cheap provider and records enough telemetry to compare cost against the Anthropic baseline."

### R4-F02 quality-claude (medium, correctness) — Slice 7 Iron Law 1 departure not named

Slice 7's deliverable is a measurement document + decision record, not a multi-layer working feature. That IS an Iron Law 1 departure (the design names it a "Plan-time spike"). The departure is correct given Decision X scope (the spike measures before committing), but it must be NAMED explicitly per Iron Law 1.

**Fix:** Add a sentence to Slice 7's description: "Iron Law 1 departure (named): this slice's deliverable is a measurement-and-decision spike, not a working cross-layer feature. The departure is intentional — the design names G4 as a Plan-time spike that gates downstream cache enablement work on measurement results. The slice is included in Phase 1 because the measurement must precede phase-2 work; the departure is bounded by the design's spike contract."

### R4-F01 quality-claude (low, correctness) — Pruning Summary Q22 range wrong

Pruning Summary claims `questions.md — current-phase: Q1–Q20, Q22` but the file actually contains Q22–Q31 as current-phase entries.

**Fix:** Change "Q1–Q20, Q22" to "Q1–Q20, Q22–Q31" in the Pruning Summary section.

### R4-F01 scope-claude (low, scope) — Slice 6 dispatch verb

Slice 6 body uses "sub-subagents dispatched in parallel from the main chat" — names a dispatch mechanism + site. Implement DEFERS territory.

**Fix:** Rewrite Slice 6 body to outcome-only: replace "sub-subagents dispatched in parallel from the main chat" with "the split mechanism produces independent per-task spec files without exhausting main-chat context." The replan-gate criterion already describes the observable behavior correctly — body now aligns.

## Fix dispatch plan

Single fix subagent. 5 distinct accepts. Touches phasing.md (4 fixes) + future-design.md (1 fix).

## Status

draft → fixing → re-review round 5.
