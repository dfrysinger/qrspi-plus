---
round: 05
artifact: goals
status: clean
---

# Round 05 dispositions

## Trigger

Backward loop from Design step. User reviewed the G1–G18 design decisions and noted that earlier session work had agreed to remove A/B-replay as a candidate validation methodology for G5 (Dispatcher tolerance research) and G6 (Test-writer subagent investigation), but the A/B-replay bullets had reappeared in approved `goals.md`. The chosen approach is heuristic categorization + production tuning via G1's policy schema — no A/B harness.

## Changes against c007603

- `goals.md` frontmatter: `status: approved` → `status: draft` (re-open for backward loop).
- G5 "What we know so far": removed the bullet "Replay or A/B validation is referenced by the source issues as the way to determine which dispatcher/task combinations tolerate cheaper models."
- G6 "What we know so far": removed the bullet "A/B replay is the candidate validation methodology: write both code and tests in the unified subagent, then re-run with the split shape and compare outputs. Design should weigh how to structure that comparison."
- No other prose changed. Both G5 and G6 retain the three required subsections and concrete `type` values.

## Findings inventory

- quality-claude: 0 findings (clean sentinel)
- scope-claude: 0 findings (clean sentinel)
- quality-codex: 0 findings (clean sentinel)
- scope-codex: 0 findings (clean sentinel)

## Per-finding dispositions

No findings. Convergence on first pass.

## Notes

Scope reviewers explicitly verified that curating candidates inside "What we know so far" is within Goals' OWNS contract — that subsection's purpose is to surface candidates Design should weigh, and removing a candidate after Design rejects it is in-scope curation, not Design-territory drift.

Status: draft → approved.
