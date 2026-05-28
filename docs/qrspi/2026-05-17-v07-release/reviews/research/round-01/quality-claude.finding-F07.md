---
finding_id: R1-F07
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/research/summary.md:L209-L221]
artifact: research
round: 1
reviewer: quality-claude
---

The combined Q13/Q14/Q21 section is `[codebase]` research about Parallelize worktree checks, Branch Map vocabulary, and artifact shape. Six Key findings bullets make concrete claims about content of named files but none of those bullets carries a `file:line` citation — only the TL;DR and the Surprises text name the files in prose form. Examples of the citation gap:

- "Parallelize owns symbolic planning artifacts and defers concrete branch/worktree creation, baseline tests, runtime `task-00`, and commit hashes to Implement." — no `skills/parallelize/SKILL.md:LXX-LYY` or `skills/parallelize/owns-defers.md:LXX-LYY`.
- "Worktree-aware validation checks eslint, tsconfig, vitest/jest, and recursive framework build-dir ignores from the project root; missing exclusions are advisory and get surfaced in `parallelization.md` plus a notification line." — no line range for the validation step in `skills/parallelize/SKILL.md`.
- "Canonical Parallelize `Base` values are `feature branch tip`, `task-NN tip`, `stage-after-W{N}`, and `task-00 tip`." — no line range citing where the canonical vocabulary is defined.
- "The quality reviewer's symbolic-base check does not match the canonical vocabulary in `skills/parallelize/SKILL.md`." — no `agents/qrspi-parallelize-reviewer.md:LXX-LYY` citation for the reviewer's check text.

The reviewer-protocol research check requires `[codebase]` research to include `file:line` references for every factual claim. Other sections of summary.md (Q1/Q26, Q3, Q6/Q7, Q8, Q10, Q12/Q29, Q17, Q20, Q23) consistently include `file:line` ranges on bullet claims; the inconsistency in Q13/Q14/Q21 prevents downstream consumers from auditing each Parallelize-vs-reviewer drift claim against the named line ranges.
