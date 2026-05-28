---
round: 10
artifact: design
status: fixing
---

# Round 10 dispositions

## Findings inventory

- quality-claude: 0 findings (clean sentinel)
- scope-claude: 0 findings (clean sentinel)
- quality-codex: 1 finding (medium=1)
- scope-codex: 0 findings (clean sentinel)

Total: 1 finding. 3/4 reviewers clean. This is the strongest convergence signal so far.

## R10-F01 quality-codex (medium) — accept

G7 is advisory: self-check reports hits, implementer removes or explicitly acknowledges, commit proceeds, reviewers see unacknowledged hits. Cross-cutting test strategy wrongly says the self-check "rejects added lines" containing internal IDs, implying a blocking gate.

**Fix:** Update cross-cutting test strategy "Hygiene contract (G7 + G18)" so G7 language says:
- Implementer self-check reports added-line hits containing QRSPI internal IDs in non-exempt files.
- Implementer must either remove the hit or explicitly acknowledge it in the DONE report.
- Reviewer visibility covers unacknowledged hits.

Keep G18 BATS wording unchanged.

## Status

draft → fixing → (post-fix) → re-review round 11.
