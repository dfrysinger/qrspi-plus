---
finding_id: R1-F02
severity: medium
change_type: scope
referenced_files:
  - "docs/qrspi/2026-06-04-v073-release/goals.md:L185"
artifact: goals
round: 1
reviewer: scope-claude
---

G8 "What we know so far" (L185) carries the sentence:

> "Acceptance must measure post-trim active footprint and demonstrate no regression on v0.7.2 phase-1 acceptance suite."

Same boundary violation as R1-F01: the word "must" makes this a binding acceptance criterion rather than a candidate. Goals DEFERS acceptance criteria to Design's Test Strategy and Plan's per-task expectations (owns-defers.md). Additionally, "no regression on the v0.7.2 phase-1 acceptance suite" is already stated as an environmental constraint in ## Constraints L17 — the second instance here is redundant even if it were framed permissibly.

Proposed resolution: remove the sentence. The measurement requirement (demonstrate footprint reduction) is Design-level test strategy; the regression guard is already captured in ## Constraints.
