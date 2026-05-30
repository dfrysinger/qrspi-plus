# Round 02 Dispositions — questions.md

Reviewer dispatch this round: quality-claude (4 findings) + quality-codex (NO_FINDINGS sentinel). No scope-reviewer for Questions per canonical artifact topology.

## Verifier Scores

| Finding | Class | Severity | Score | Strict-Filter | Disposition |
|---------|-------|----------|-------|---------------|-------------|
| quality-claude.F01 (Q10) | clarity | high | 88 | KEEP | APPLIED |
| quality-claude.F02 (Q13) | clarity | high | 75 | DROP | APPLIED (exception) |
| quality-claude.F03 (Q3) | clarity | medium | 48 | DROP | DROPPED |
| quality-claude.F04 (Q19) | clarity | medium | 72 | DROP | APPLIED (exception) |

## Apply-fix protocol

Per `using-qrspi/SKILL.md` apply-fix filter:
- `clarity` change_type requires score ≥80 to KEEP.
- `scope`/`intent` change_type always KEEP regardless of score.

## Exception rationale (F02, F04)

All four findings are `change_type: clarity` of class **goal leakage** in different questions. The pattern echoes round-01 (four-finding convergent leakage across two reviewers). This round only one reviewer (Claude) flagged leakage and Codex returned NO_FINDINGS, so the convergent-across-reviewers signal is weaker than R1.

- **F02 (Q13, score 75) — APPLIED.** The leakage is named security-vulnerability disclosure: the question text names "absolute path outside the project root" and "repository-boundary check" verbatim. Even at score 75 the marginal cost of the surgical rewrite (delete two phrases) is negligible compared to the marginal value of not telegraphing G16's exfil surface in a public artifact. Convergent-class exception applied.
- **F04 (Q19, score 72) — APPLIED.** "Could call instead" is a one-word fix that removes a solution-direction signal for G4. Score is borderline (within ~8 of threshold) and the rewrite is mechanical with no downstream risk. Convergent-class exception applied.
- **F03 (Q3, score 48) — DROPPED.** The verifier's low score (48) aligns with the finding text's own admission ("mild but clear leakage… many researchers might not draw the inference"). The convergent exception does not apply at this confidence — the cost (rewriting Q3's count framing) exceeds the marginal value.

## Edits applied

1. **Q10 (F01):** stripped the compound "Does the skill include any X, Y, or Z?" clause that named G2/G15/G18 capability gaps; replaced with neutral characterization request preserving the empirical comparison ask.
2. **Q13 (F02):** removed "repository-boundary check" and "absolute path outside the project root" framing; replaced with neutral "normalize, canonicalize, or apply any constraints" path-handling description request. Keeps the file/line citation intact for research grounding.
3. **Q19 (F04):** replaced "shared helper script or function exists in `scripts/` that any of those sites could call instead" with neutral "any script or function in `scripts/` currently implements a related computation that those sites reference" — removes solution-direction signal.

## Round outcome

- 3 of 4 findings applied (F01, F02, F04).
- 1 finding dropped (F03).
- Substantive edits to Q10, Q13, Q19. R3 dispatch required to verify the rewrites do not introduce new leakage.

## Plugin-process observations (this round)

- Codex (gpt-5.3-codex) returned NO_FINDINGS sentinel as expected — clean handoff via splitter; first questions-skill Codex review of this run. Chat-only contract held.
- Claude (sonnet-4.6) reviewer this round wrote 4 finding files to disk correctly (no PI-005 narration-without-write recurrence on this dispatch).
- 4 verifier dispatches (claude-haiku-4.5) all wrote sidecars to disk. No PI-006 recurrence this batch.
