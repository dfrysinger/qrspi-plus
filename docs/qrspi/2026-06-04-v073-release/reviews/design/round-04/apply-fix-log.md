# R04 Apply-Fix Log

## Applied (1 finding — real markdown bug)

### quality-claude.R4-F02 (score 75) — malformed fence nesting in G5 prose-design blocks
**Fix applied** at L281 and L297:
- Changed outer ``` (triple-backtick) to ```` (quad-backtick) for the two G5 Orchestration Boundary prose-design blocks ({integrate,test}).
- This matches the existing convention used at L65 and L102 in G_R8 prose-design (quad-backtick outer, triple-backtick inner). The G5 blocks were the only nested-fence blocks using mismatched delimiters; all other prose-design blocks in design.md have no nested fences and remain ```.

Verifier scored 75 — real correctness defect (in standard CommonMark, the second ``` closes the outer fence). The fix uses CommonMark's standard "outer fence wider than inner fence" pattern; the inner HARD-RULE ``` blocks are now properly contained.

## Deferred (2 findings — recurring low-confidence scope critiques, no actionable citations)

### scope-codex.R4-F01 (score 25) — file architecture (verbatim repeat of R3 finding)
### scope-codex.R4-F02 (score 25) — test mechanics (verbatim repeat of R3 finding)

Both findings are blanket boundary-drift critiques without specific quoted prose. The R4 cites add coarse line ranges (L9-L49, L130-L236, L281-L385) but no quoted text; the verifier (sidecar scores 25 each) confirms the OWNS contract authorizes the cited patterns:
- "named architectural components by purpose" — covers script-path naming.
- "acceptance criteria including concrete examples and rough test-pairing shapes" — covers the acceptance bullets.

No change applied. Same disposition as R03; both will recur in R05 if the file is unchanged. This is a known reviewer-prompt drift pattern (scope-codex blanket assertions without anchoring) that the v0.7.3 backlog should address by tightening the scope-reviewer prompt's citation requirement.

## Dropped (2 findings — recurring hallucinations)

- quality-claude.R4-F01 (15) — Mermaid: HALLUCINATED requirement. Recurring drift; v0.7.3 backlog should add negative-check list to qrspi-design-reviewer.
- quality-claude.R4-F03 (20) — Test Strategy: same recurring drift.
