---
finding_id: R1-F01
reviewer: silent-failure-claude
task: 27
round: 1
severity: medium
change_type: correctness
referenced_files:
  - skills/reviewer-protocol/SKILL.md
  - skills/_shared/evergreen-output-rule.md
  - skills/questions/SKILL.md
  - skills/research/SKILL.md
---

# F01 — MEDIUM — Reviewer-protocol enforcement clause scope mismatch

The new `### Evergreen-Output Rule Enforcement` clause in `skills/reviewer-protocol/SKILL.md` cites the snippet's named in-scope set as authoritative ("goals, design, structure, phasing, plan, parallelization, roadmap, future-goals"). But `questions.md` and `research/q*.md` are also `status: draft → approved` artifacts whose producing SKILL.md files (`skills/questions/SKILL.md`, `skills/research/SKILL.md`) `!cat`-include the rule. A reviewer reading the clause literally can decline to surface antagonist-pattern findings against those artifacts with no observable signal that enforcement was skipped — author-side guidance and reviewer-side enforcement are asymmetric.

**Recommended fix:** either (a) add `questions, research` to the scope set in the snippet, or (b) state in the reviewer-protocol clause that the rule applies to every QRSPI artifact whose producing SKILL.md `!cat`-includes the snippet (delegating scope authority to the include topology rather than the named list).
