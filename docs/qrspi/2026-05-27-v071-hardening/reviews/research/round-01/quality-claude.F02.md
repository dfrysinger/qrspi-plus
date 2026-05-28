---
artifact: research
reviewer: quality-claude
finding_id: quality-claude.F02
severity: medium
change_type: correctness
location: "research/summary.md § Cross-References lines 236–237 (bullets 1 and 2)"
---

# Objectivity violation: prescriptive and solution-framing language in synthesized `## Cross-References` section

## Observation

The synthesized `## Cross-References` section in `research/summary.md` (lines 234–241)
contains two bullets that introduce prescriptive framing and solution suggestions. Research
findings must report what IS, not what SHOULD BE; opinions, recommendations, and solution
suggestions must not be embedded in the research.

## Evidence

**Bullet 1 (line 236):**

> Q01 ↔ Q02: … Q02's recommended portable replacement (`LC_ALL=C grep -q '[[:cntrl:]]'` or
> `tr -d '[:cntrl:]'` + byte-count) **would close Q01's silent-failure risk without requiring
> GNU grep**.

The phrase "would close Q01's silent-failure risk" is a prescriptive solution suggestion
("SHOULD BE" framing). Neither q01-codebase.md nor q02-web.md contains this recommendation
in their respective `## Summary` blocks. The q02 `## Summary` documents platform behaviors
and techniques as facts; it does not recommend that any specific technique should be used
to fix a gap in another file.

**Bullet 2 (line 237):**

> Q08/Q15 ↔ Q09: … The gap between the available signal (Q09) and the absence of any check
> on it (Q08/Q15) **is the direct motivation for a host-detection hardening task**.

The phrase "is the direct motivation for a host-detection hardening task" frames the
research gap as a task prescription. This crosses from description of what was observed
into advocacy for a specific implementation direction. Neither q08-codebase.md nor
q09-web.md uses this framing in their `## Summary` blocks.

## Impact

Research summaries consumed by downstream agents (plan, design, implementer) are treated
as factual observations, not recommendations. Prescriptive framing embedded in summary.md
can cause downstream agents to treat a collation artefact as a directive, bypassing the
proper goals-and-plan workflow for deciding whether and how to act on research findings.
