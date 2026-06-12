# R05 Apply-Fix Log

## Applied (2 findings — real-but-minor, applied preemptively)

### quality-claude.R5-F03 (score 55) — G5 phase-base anchor under-specified
**Fix applied** at G5 Dependencies (phase-base SHA edge case):
Acknowledged that the concrete anchor surface is deferred to Plan (option b). G6 produces stage commits whose SHAs are recoverable; Plan specifies the consume-site. Sequencing constraint preserved.

Verifier (sidecar 55) confirms real inter-item linkage gap — G5 asserts dependency on G6 "producing a recoverable phase-base anchor" but G6's prose only describes parent-SHA validation, not anchor authorship. Below 70 correctness threshold but real per verifier; applied as one-sentence preemptive fix to avoid Plan-phase confusion.

### quality-claude.R5-F04 (score 45) — G3 non-sequential letter labels unexplained
**Fix applied** at G3 Solution preamble:
Added one-sentence note clarifying that G3.a/G3.b/G3.e/G3.d sub-labels are goals.md sub-requirement IDs (intentionally non-sequential, no missing G3.c).

Verifier (sidecar 45) confirms real cosmetic inconsistency. Below 50 keep threshold but real per verifier; one-sentence fix prevents reader confusion.

## Deferred (1 finding — recurring scope-codex blanket critique)

### scope-codex.R5-F01 (score 30)
Same disposition as R03/R04. No specific quoted prose; verifier confirms OWNS contract authorizes the cited patterns. Documented; no change.

scope-claude (Claude scope reviewer) re-reviewed with thorough 3-check procedure and emitted full NO_FINDINGS endorsement — strong evidence the scope-codex repeated critique is reviewer-prompt drift rather than real boundary violation.

## Dropped (4 findings — recurring quality hallucinations)

- quality-claude.R5-F01 (15) — Mermaid
- quality-claude.R5-F02 (20) — Test Strategy
- quality-codex.R5-F01 (10) — Mermaid
- quality-codex.R5-F02 (15) — Test Strategy

All recurring; both reviewer prompts need negative-check additions in v0.7.3 backlog.
