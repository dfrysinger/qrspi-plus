---
finding_id: R1-F03
severity: low
change_type: correctness
referenced_files: [docs/qrspi/2026-06-04-v073-release/goals.md:L185-L186]
artifact: goals
round: 1
reviewer: quality-claude
---

G8's "What we know so far" contains two committed decisions that should be candidates or observations rather than locked requirements:

**L185 — Acceptance criterion as a requirement:**
> "Acceptance must measure post-trim active footprint and demonstrate no regression on v0.7.2 phase-1 acceptance suite."

The "must" phrasing commits to a specific acceptance approach. The same section correctly uses "Candidate strategies Design should weigh" (L184) and "Per-skill targets and trim depth are Design's call" (L184); the acceptance line breaks that pattern by switching to requirement language. Reframe as a candidate, e.g.: "Candidate acceptance approach: measure post-trim active footprint and confirm no regression on v0.7.2 phase-1 acceptance suite."

**L186 — Phasing directive:**
> "This goal lands LAST in v0.7.3 phasing — trimming skills while G1-G7 are editing them creates merge churn."

This embeds a phasing commitment inside a `What we know so far` section, which should record context and candidates, not sequencing decisions. The rationale (merge churn) is valid context, but the phasing order is the Phasing step's output — not a Goals conclusion. The observation is also already captured in `## Cross-Cutting Notes` (L192: "G8 lands last. Trimming skill bodies while G1-G7 are editing them creates merge churn; phasing should sequence G8 after the correctness goals settle."), which is the appropriate place for it. The L186 line in WKSO should be softened to context only, e.g.: "Sequencing note for Design/Phasing: trimming skill bodies while G1-G7 are editing them risks merge churn; the merge-order implications are worth weighing."
