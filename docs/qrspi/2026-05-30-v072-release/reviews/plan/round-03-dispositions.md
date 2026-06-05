# Round 03 dispositions

**Scored:** 26 findings across 7 Claude + 7 Codex reviewers (4 clean sentinels).
**Kept post-verifier-filter:** 9 (7 above-threshold correctness + 2 scope/intent bypass).
**Dropped sub-threshold:** 17 (verifier correctly identified them as scope-creep — Plan asking for Implement-altitude contract detail; aligns with F-5 fix-altitude rule).

## Applied (4 edits, 4-reviewer convergence on Phase 1 AC)

1. **Overview L11 — per-gap dispositions for moot/absorbed goal IDs** (quality-claude.F01, score 70). Replaced umbrella "moot/absorbed-by-CD-1 per design.md ## G24/G25/G26/G29" with per-gap breakdown: gap 18 (G25→CD-1), 22 (G24-F02→G25→CD-1), 23 (G24-F03 moot — duplication target never existed), 41 (G26 already fixed pre-v0.7.2; BW02 prevention rides on G21 in T40), 42 (G24-F01 moot), 43 (G24-F04 moot per design.md L2064). Also clarified G29 absorption — T11 was repurposed to [G3] rather than deleted.

2. **Overview L11 — acknowledge T09/T11/T13→T20 cross-slice chain** (quality-codex.F02, score 72). Removed misleading "G4→G9 is the only cross-slice prerequisite" claim. Added second cross-slice chain (b): T09 actual_model + T11 dispatch-manifest + T13 per-task round-prepare all land before T20 G3 splitter rename.

3. **T11 slice annotation** (quality-claude.F02, score 70). Added one-line note clarifying T11 is parked under Slice 1.2 by display position for cross-reference stability after the round-02 [G29]→[G3] relabel; dispatch-infrastructure work is Slice 1.4 surface.

4. **Phase 1 AC bullets rewrite** — 4-reviewer convergence (quality-codex.F01 score 85; goal-traceability-codex.F01 score 75; silent-failure-claude.F01 score 72; test-coverage-claude.F04 score 80). Removed orphaned deliverables from deleted tasks T18/T22/T23:
   - Fail-loud bullet: replaced "dispatch-routing top-level fail-loud paragraph" with the surviving T16 `_resolve-lib.sh` halt on `tier: none` against unknown vendor.
   - bats-suite bullet: removed "parameterized dispatch-routing assertion callers" (T23 deleted), "consolidated H4-extraction helper" (T22 deleted), "bats-deprecation warnings on test-codex-splitter.bats are gone" (orphaned). Replaced with T40 seeded G21 + BW02 violation lint coverage + T44 regex pins on existing fixtures.

## Declined per F-5 fix-altitude (2 findings; round-02 precedent)

- **scope-codex.F01** (T39 helper signature `assert_path_under_repo_root <label> <abs-path>`, score 72): user-approved enhanced shape per round-02 prompt; concrete contract language stays.
- **scope-codex.F02** (T40 concrete bash assertion syntax, score 35): central to regex-pin task; concrete contract language stays. scope-claude clean on this surface.

## Dropped sub-threshold (17; verifier judged as scope-creep)

The verifier consistently scored "Plan should specify implementation contract detail" findings 22–50 — below the 70 correctness floor. Notable patterns:

- **T11 fail-loud / spoofing tests** (6-reviewer convergence: sec-claude.F01 22, sec-claude.F02 22, sec-codex.F01 20, sf-claude.F02 50, sf-codex.F02 30, tc-claude.F01 42, tc-codex.F01 22): all asking Plan to specify Implement-altitude test scaffolding. Verifier correctly identified as next-altitude detail.
- **T20 splitter adversarial / provenance survival** (sec-claude.F04 45, tc-claude.F02 42, tc-codex.F02 28): Implement-altitude test detail.
- **T40 BW02 RED fixture + bypass tests** (sec-codex.F02 30, sf-codex.F01 50, tc-claude.F03 28 — Haiku flaked on first dispatch, score captured from chat per PI-V073-001): Implement-altitude test detail; declined.
- **Misc** (sec-claude.F03 58, sec-claude.F05 18, sf-claude.F03 42, gtx-codex.F02 40): individual sub-threshold findings, no convergence pattern.

The verifier's calibration matched F-5: every dropped finding asked Plan to specify Implement-altitude or test-shape detail. The 6-reviewer T11 fail-loud convergence was the strongest signal — and the verifier still correctly suppressed it because the asks were all "Plan needs implementation contract X" rather than "Plan task spec X is wrong."

## Plugin-friction note

- **PI-V073-001 / issue #293 (Haiku verifier 0-turn flake)** reproduced on vfy-tc-claude-03: completed in 135s with `total_turns: 0`, score returned in brief-return chat output as "test-coverage-claude.F03: 28" but no sidecar written to disk. Orchestrator hand-wrote the sidecar with `verifier_note:` recording the chat-only capture and the agent ID. Filed; no new issue needed.
