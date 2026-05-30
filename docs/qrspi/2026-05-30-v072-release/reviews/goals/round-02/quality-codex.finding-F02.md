---
finding_id: R2-F02
artifact: goals
severity: low
change_type: clarity
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/goals.md
round: 2
reviewer: quality-codex
---

## G25 "Needs a new vocab pin" framed as prescription, not candidate

### Location
`goals.md` § G25 — "What we know so far" block, line ~741: "Needs a new vocab pin in `using-qrspi/SKILL.md` to lock the canonical handoff parlance."

### Observation
The bullet uses prescriptive phrasing ("Needs a new vocab pin") rather than candidate framing. Adjacent bullets in the same section properly use "Candidates Design should weigh:" framing. This single bullet drifts to a solution commitment.

### Rule violated
Goals skill → "Solutions-as-possibilities framing": when surfacing solution candidates, frame as possibilities for Design to weigh, not as commitments.

### Expected correction
Reframe as a Design candidate: "Candidate Design should weigh: a vocab pin in `using-qrspi/SKILL.md` could lock the canonical handoff parlance to prevent drift across reviewers." Or fold into the existing Candidates bullet block.
