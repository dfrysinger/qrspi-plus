---
finding_id: R2-F03
severity: high
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/questions.md:L18]
artifact: questions
round: 2
reviewer: quality-claude
---

Q9 names both of G4's candidate fixes and reveals the source-of-truth risk framing.

The question reads: "What prior art exists for prompt-context summarization shims or pre-computed file indices (line-range section maps) used as prompt inputs in agent frameworks, and how do those systems guard against summary drift becoming source-of-truth?" Three separate leaks:

1. "summarization shims" is verbatim G4 Candidate (a) ("summary shim").
2. "pre-computed file indices (line-range section maps)" is verbatim G4 Candidate (b) ("file index. A pre-computed table of section anchors with line ranges").
3. "guard against summary drift becoming source-of-truth" directly echoes G4's risk language ("summaries must NOT replace source-of-truth reads") and the freshness-contract framing.

A researcher reading only Q9 would conclude the project has already settled on two specific mechanisms (summary shim + section-anchor index) and is shopping for prior-art validation. That defeats the exploratory framing G4 carries.

Recommend splitting and neutralizing: a general question about "mechanisms agent frameworks use to reduce repeated context input across dispatches" plus a separate question about "freshness and accuracy contracts published for derived/condensed prompt inputs." The researcher then surfaces what's actually out there — summaries, indices, embeddings, caching layers, prompt-cache hints — rather than confirming the two the goal already chose.
