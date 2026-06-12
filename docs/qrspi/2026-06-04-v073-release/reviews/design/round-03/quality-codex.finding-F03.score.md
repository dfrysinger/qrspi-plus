---
verifier_status: passed
score: 40
defect_class: unanchored-claim
---

Cite check: the finding quotes "per Q1 research" and "Q4 established practice" attributed to design.md. Verified — line 155 contains the parenthetical "(per Q1 research)" grounding the Hygiene-contract correctness claim, and line 173 contains "the Q4 'grep/awk CI script' established practice" grounding the CI-lint shape. Both quoted phrases exist in the cited file; cite check passes.

Substance: the observation is real — design.md grounds several rationale claims in research findings by question-ID alone, without a `research/q*.md` (or `research/summary.md`) path citation that would let a verifier mechanically follow the trace. This does weaken auditability vs. attaching an explicit path. However, the QRSPI design-step conventions do not appear to mandate per-claim research path citations (the upstream-paths machinery makes the research summary lazy-Readable for verifiers, and Q-ID references are the established shorthand). The two specific cases are also low-stakes: line 155 is an out-of-scope aside ("tables are already correct"), and line 173 is a corroborating "matches established practice" note, not a load-bearing decision pivot. Neither claim hinges on the citation for correctness.

This is a verifiable but stylistic traceability nudge — moderate confidence, low practical impact. Scores at the lower end of the "moderately confident" band.
