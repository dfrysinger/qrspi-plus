---
finding_id: R3-F10
severity: medium
change_type: clarity
referenced_files: [docs/qrspi/2026-05-17-v07-release/questions.md:L34]
artifact: questions
round: 3
reviewer: quality-claude
---

Q28's parenthetical enumerates G4's two named candidates as the framing of the research. The question asks about freshness and accuracy contracts for "derived or condensed prompt inputs (summaries, indices, embeddings, caching layers) used in agent frameworks" — `summaries` and `indices` are exactly G4's "What we know so far" candidates ("Candidate (a): summary shim" and "Candidate (b): file index"), and the broader noun phrase "derived or condensed prompt inputs" combined with "freshness and accuracy contracts" maps to G4's explicit warning that "summaries must NOT replace source-of-truth reads" and the freshness-contract weighting G4 calls for. A researcher reading Q28 alone learns both the candidate mechanisms and the contract dimension to investigate. Generalize the noun examples to a wider, less goal-shaped set — for example, "(summaries, indices, embeddings, retrieval layers, caching mechanisms)" — or drop the parenthetical entirely so the question surfaces the freshness/accuracy landscape without pre-committing the categories.
