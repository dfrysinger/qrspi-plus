---
round: 1
verifier_enabled: true
scored: 5
kept_after_verifier: 3
dropped_by_verifier: 2
clean: 0
---

# Round 1 — Dispositions

## Verifier filtering

| Finding | change_type | Score | Threshold | Status |
|---|---|---|---|---|
| quality-claude.R1-F01 (G23 prescriptive framing) | clarity | 70 | ≥80 | DROPPED |
| quality-codex.R1-F01 (G23/G26 "Mechanical" framing) | clarity | 79 | ≥80 | DROPPED |
| scope-claude.R1-F01 (G27 preferred + verbatim bash) | scope | 75 | n/a (kept) | KEPT |
| scope-claude.R1-F02 (G21 known-good replacement) | scope | 75 | n/a (kept) | KEPT |
| scope-codex.R1-F01 (phasing leakage G22/G23/CCN) | correctness | 85 | ≥70 | KEPT |

## Fixes applied to goals.md

1. **G21** — replaced "Known-good replacement (already used in R5 pins): `body=…`" verbatim assertion block with a generic reference to "the safer R5-era pattern" + Candidates framing. Removed verbatim bash assertion text per scope-claude.R1-F02 (assertion text → Plan/Implement DEFERS).
2. **G23** — replaced "Mechanical addition: one row in the validation table…" + "Order suggestion: G22 first, G23 as a sub-task" with a "Candidates Design should weigh:" list and a Phasing-deferred coupling note. Closes both the clarity finding (dropped) and the phasing-leakage portion of scope-codex.R1-F01.
3. **G26** — replaced "Mechanical fix per bats docs — replace shebang. Two options: `#!/usr/bin/env…`" with Candidates framing that defers to upstream docs without quoting the verbatim replacement strings. Closes the quality-codex.R1-F01 portion that flagged G26.
4. **G27** — replaced the "(preferred)" label and verbatim `bash -c 'set -e; QRSPI_SOURCE_ONLY=1 source scripts/run-codex-review.sh; check_codex_available …'` invocation with three named candidates ("Single source of truth at probe time", "Documented contract reference", "Generated probe") that name the canonical helper functions without quoting their invocation surface. Removed "Plan-phase" phasing language from the cross-link. Closes scope-claude.R1-F01.
5. **Cross-Cutting Notes** — replaced "Landing these in a single Plan-phase wave avoids repeated churn" with "Phasing should evaluate whether the cluster benefits from being scheduled together," removing the phasing recommendation. Closes the remaining portion of scope-codex.R1-F01.

The two dropped clarity findings are functionally subsumed by the scope/correctness fixes (G23 and G26's "Mechanical…" framing was rewritten as part of fixes 2 and 3); no additional edits required.

## Round-01 plugin-issues observed (logged to session db `plugin_issues`)

- **PI-002** — Codex (gpt-5.3-codex) task-tool dispatch reliably returns chat-only — no disk write — for reviewer agents declaring `tools: Read, Write`. Orchestrator persisted Codex chat-fallback finding files manually.
- **PI-003** — `qrspi-goals-reviewer` (Claude) emitted finding filename as `<tag>.FNN.md` instead of canonical `<tag>.finding-FNN.md`. Orchestrator renamed.
- **PI-004** — `finding_id` format drifts across reviewers (canonical `R{round}-F{NN}` only honored by scope-claude; quality-claude/Codex/scope-codex emit varied forms). Orchestrator normalized.
