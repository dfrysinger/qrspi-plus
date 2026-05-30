---
finding: F03
reviewer: sec-claude
round: 5
task: 1
override_type: implementer-declined
override_authority: orchestrator-accepted
override_date: 2026-05-28
---

# sec.F03 (NUL TOCTOU) — implementer declined with sound rationale

## Reviewer recommendation
Restructure NUL pre-flight to use single `$(cat; printf x)` read so the byte-count comparison is consistent with the NUL detection.

## Implementer rationale for declining
> bash command substitution strips ALL NUL bytes (not just trailing ones), so
> `_raw_config` would never contain NUL and both byte-counts would always be
> equal, completely disabling NUL detection. The original two-read approach is
> retained; the TOCTOU risk is bounded because bash strips NUL during awk
> parse anyway (as noted in the spec).

## Empirical evidence
Test 34 (NUL detection regression test) was the witness when the suggested fix was trialled.

## Orchestrator decision
ACCEPT the decline. Bash semantics (command substitution strips NULs) make the suggested fix infeasible; the spec itself acknowledges "bash strips NUL during awk parse anyway"; the regression check confirms the fix breaks detection. Two-read approach retained.

## Disposition
Finding remains documented; recommended fix rejected as infeasible; no further action this round.
