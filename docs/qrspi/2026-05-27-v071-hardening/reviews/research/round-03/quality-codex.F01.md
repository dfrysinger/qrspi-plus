---
artifact: research
reviewer: quality-codex
round: 3
severity: medium
change_type: correctness
file: research/summary.md
section: "## Cross-References"
lines: 234-242
---

# F01: `## Cross-References` section is synthesized cross-question content, not verbatim collation

## Description

`research/summary.md:234-247` adds a `## Cross-References` section with synthesis bullets (e.g., `Q08/Q15 ↔ Q09`). Companion research files are structured as `## Summary` followed by `## Full findings` with no cross-reference collation block to extract (e.g., `q01-codebase.md:9-25`, `q08-codebase.md:9-27`, `q09-web.md:9-30`, `q12-web.md:9-34`).

## Rule violated

The research quality contract requires `summary.md` to be a verbatim extraction of per-question `## Summary` blocks only; adding a synthesized `## Cross-References` section introduces non-verbatim editorial content.

## Recommended fix

Remove the `## Cross-References` section from `summary.md`.

## Orchestrator note

Codex flagged this same issue in round 1; orchestrator dismissed citing collator agent body's explicit "short Cross-References section" authorization. Claude reviewer joined Codex on this finding in round 3 after focusing earlier rounds on bullet-level content. Two-reviewer convergence + non-load-bearing nature of synthesis bullets ⇒ apply fix; document the SKILL ↔ agent-body contract ambiguity as a separate meta-issue.
