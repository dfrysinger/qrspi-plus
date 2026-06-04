---
finding_id: R1-F02
reviewer_tag: spec-codex
round: 1
severity: high
change_type: correctness
referenced_files: [tests/integration/test-reference-gate-pause.bats]
adjudication: accepted
---
**Claim:** No bats pin asserts the explicit both-fields-missing / independent-finding scenario required by task-15.md:42 ("independent findings when a task is both sweep-shaped and consumer-surface-touching") and :49 ("a task missing both `dependent_tests:` and `cross_task_consumers:`").

**Adjudication: ACCEPTED.** The agent rubric DOES contain the production text ("the reviewer evaluates each clause independently — a finding may be emitted against either, both, or neither. The two clauses do not merge."), but no section-scoped pin asserts it. Existing pins cover: SKILL.md composition note (L518), separate-clause H3 headings (L586). Neither asserts the reviewer's independent-evaluation contract for the both-missing case. Fix: add ONE section-scoped extract_and_grep pin against the agent H3 "Cross-task consumer surface detection" asserting the "either, both, or neither" / "evaluates each clause independently" text. Same class of gap tc-claude/tc-codex caught in T14.
