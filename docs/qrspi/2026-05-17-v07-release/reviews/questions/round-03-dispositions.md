---
round: 03
artifact: questions
status: applied
---

# Round 03 dispositions

## Findings inventory

- quality-claude: 10 (4 high/clarity, 6 medium/clarity)
- quality-codex: 2 (1 high/correctness systemic restatement, 1 medium/correctness — NEW scope gap on config.md backfill)

## Per-finding dispositions

| Finding | Disposition | Action / Rationale |
|---|---|---|
| quality-claude R3-F01 (high/clarity) | Applied | Q19 — dropped the `REPO_ROOT, empty-extract, structural-anchor` triplet (verbatim G14 vocabulary). Now asks "what conventions, if any, do those tests share?" |
| quality-claude R3-F02 (high/clarity) | Applied | Q20 — dropped G15-specific phrases ("mechanical phase-snapshot", "interactive scope-capture", "Ideas"). Now asks neutrally about Replan's described scope relative to Goals and how it describes handling new items surfaced during phase completion. |
| quality-claude R3-F03 (high/clarity) | Applied | Q24 — dropped "exempted from any prose-rot scan" (presupposed G18's planned mechanism). Now asks which dated paths are intentionally release-bound. |
| quality-claude R3-F04 (high/clarity) | Applied | Q25 — generalized "release-version-token rot in evergreen contract files" (G18 signature phrase) to "version strings, milestone references, or other dated language from accumulating in files intended to be stable across releases." |
| quality-claude R3-F05 (medium/clarity) | Applied | Q7 — dropped "must any mechanical split preserve" modal that presupposed G3's mechanism. Now asks what contracts those templates currently document. |
| quality-claude R3-F06 (medium/clarity) | Applied | Q8 — rewrote to drop "repeatedly include the same long stable files" framing that mirrored G4. Now asks how composition is currently assembled and what inputs are typically composed. |
| quality-claude R3-F07 (medium/clarity) | Applied | Q9 — rewrote to drop "reduce repeated context input" framing. Now asks generically about mechanisms or patterns to manage large stable inputs. |
| quality-claude R3-F08 (medium/clarity) | Applied | Q6 — dropped `(input bounds, output contract, ID-hygiene expectations, status reporting)` parenthetical that mirrored G3 deliverables. |
| quality-claude R3-F09 (medium/clarity) | Applied | Q15 — dropped `(screenshot, golden file, fixture)` parenthetical (G10 triplet). Now asks what kinds of reference artifacts appear today. |
| quality-claude R3-F10 (medium/clarity) | Applied | Q28 — dropped `(summaries, indices, embeddings, caching layers)` parenthetical that named G4 candidates. |
| quality-codex R3-F01 (high/correctness) | Resolved-by-other | Systemic restatement of leakage class; per-question Claude rewrites address each surface it named. |
| quality-codex R3-F02 (medium/correctness) | Applied | Added Q31 ([codebase] config.md parsing/defaulting/backfill) per goals.md L17 hard constraint that any new config field must support runtime-backfill defaults for resumed runs. |

## Notes

Round 3 surfaced finer-grained parenthetical and modal-clause leakage that rounds 1–2 missed. Total now 31 questions. The leakage finding count went 4 → 9 → 10, but the round-3 findings are smaller in nature than rounds 1–2 (mostly drop-parenthetical and re-phrase-clause, not whole-question rewrites). One scope gap closed (config.md backfill).
