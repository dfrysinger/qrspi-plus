---
finding_id: R7-F01
severity: medium
change_type: scope
referenced_files:
  - structure.md (line 775, G31 prompt-prose-writer `!cat` include sites — plan/SKILL.md row)
artifact: structure
round: 7
reviewer: scope-codex
---

## Finding (scope)

The Hook-Point Locations section is declared as "locations only," but the new G31 subsection's plan/SKILL.md row specifies payload-content requirements ("each site carries `!cat skills/_shared/prompt-prose-detection.md` + `!cat skills/_shared/prompt-prose-writer-addition.md` + **Addition B verbatim**"), which crosses from placement metadata into prose-content contract territory.

## Evidence

- `skills/structure/owns-defers.md`: Structure OWNS hook-point *locations only* and DEFERS "actual prompt or SKILL.md text content."
- structure.md `## Hook-Point Locations` section header (line ~680): "Locations only — text content lives in source snippets."
- structure.md line 775 (R6 fix): adds `+ Addition B verbatim` content requirement beyond a pure location.

## Comparison with existing Hook-Point subsections

The existing CD-1, CD-2, CD-3, CD-4, G34, G35 subsections all stay location-only — they name the consumer file + section heading but do not say what additional verbatim text the site must include. The R6 G31 entry breaks that pattern by mentioning "Addition B verbatim" as a payload requirement.

## Suggested fix

Strip `+ Addition B verbatim` from the plan/SKILL.md row so the entry remains location-only. The "Addition B" content requirement belongs in the source snippet (`skills/_shared/prompt-prose-writer-addition.md`) or in design.md G31 Consumer #2 — both of which already document it. Updated row:

| Consumer file | Section / location |
|---|---|
| `skills/plan/SKILL.md` | writer-subagent dispatch payloads (2 sites): each site `!cat`-includes `skills/_shared/prompt-prose-detection.md` + `skills/_shared/prompt-prose-writer-addition.md` (per design.md G31 Consumer #2) |

## Dispatch transport note

scope-codex (gpt-5.3-codex via code-review agent_type) returned this finding in chat-only output. Orchestrator hand-persisted per the write-restricted-codex pattern (#288). Change_type=scope per the auto-bypass classifier — does not require a verifier per protocol (scope/intent findings pause for orchestrator/user judgment).
