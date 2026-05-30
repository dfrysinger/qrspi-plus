---
artifact: research
reviewer: quality-claude
finding_id: quality-claude.F01
severity: medium
change_type: correctness
location: "research/summary.md § Cross-References (lines 234–241)"
---

# Verbatim-collation violation: synthesized `## Cross-References` section not extracted from any q-file `## Summary` block

## Observation

`research/summary.md` contains a `## Cross-References` section (lines 234–241) that does not
correspond to any `## Summary` block in any of the twelve companion q-files. This section is
original content introduced during collation — cross-question connections that were composed
by the collator rather than extracted verbatim from per-question summaries.

The verbatim-collation requirement states: `research/summary.md` must be a verbatim extraction
of the per-question `## Summary` blocks from the `q*.md` files; any paraphrasing,
editorializing, or synthesis introduced during collation is a finding.

## Evidence

Six cross-reference bullets appear in summary.md lines 234–241, none of which originate in
any q-file `## Summary` block:

| Bullet | Appears in any q-file Summary? |
|--------|-------------------------------|
| `Q01 ↔ Q02: The grep -qP invocation … Q02's recommended portable replacement …` | No |
| `Q08/Q15 ↔ Q09: run-third-party-llm.sh has no host-specific gating … gap between the available signal … ` | No |
| `Q10 ↔ Q08/Q15: scripts/g4-cache-probe.sh … is also the secondary call site …` | No |
| `Q11 ↔ Q12: The haiku/sonnet/opus/inherit tier vocabulary … independently validated …` | No |
| `Q03 ↔ Q04: The commit procedure relies on .git/info/exclude … Q04 confirms that .gitignore has no entry …` | No |
| `Q05/Q13 ↔ Q07: tests/helpers/skill-markdown.bash … is the shared helper loaded by test-evergreen-markdown.bats …` | No |

Verification: q01-codebase.md, q02-web.md, q03-codebase.md, q04-codebase.md,
q05-codebase.md, q06-codebase.md, q07-codebase.md, q08-codebase.md, q09-web.md,
q10-codebase.md, q11-codebase.md, and q12-web.md were each read in full. None contains
a `## Cross-References` section or a `## Summary` block with this cross-question
synthesis content.

## Impact

The collation contract is broken: `summary.md` is no longer a faithful mechanical
extraction of per-question summaries. Downstream consumers (orchestrators, implementers)
that rely on summary.md as a transparent window into individual question outputs will
encounter content that was not present in the underlying research and cannot be
attributed to any individual question's findings.
