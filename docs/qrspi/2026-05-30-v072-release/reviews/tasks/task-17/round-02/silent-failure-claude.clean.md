# Silent-Failure Review — Clean

**Reviewer:** silent-failure-claude  
**Task:** T17 (G23 doc-hardening)  
**Round:** 2  
**Artifact:** `skills/using-qrspi/SKILL.md` + `tests/unit/test-config-model-routing.bats`

No silent-failure issues found in the changed lines.

## Rationale

All six new `@test` blocks were traced against the actual SKILL.md content (post-diff):

| Test | Key assertion | Vacuous-pass risk | Verdict |
|------|--------------|-------------------|---------|
| "validation table lists exactly one model_routing: row" | `grep -c … \|\| true` → `[ "$count" -eq 1 ]` | On no-match, `grep -c` outputs `"0"` before `\|\|` fires; `count="0"`; `[ "0" -eq 1 ]` fails | ✓ robust |
| "…names per-vendor five-tier map shape" | `[ -n "$row" ]` then `grep -qE "five.tier\|per.vendor\|vendor.neutral"` (no `\|\| true`) | `[ -n "" ]` fails on no-match; trailing `grep -qE` fails if pattern absent | ✓ robust |
| "…cross-references schema-definition heading by literal text" | `[ -n "$row" ]` then `grep -qF '\`model_routing:\` block'` (no `\|\| true`) | Same structure | ✓ robust |
| "…cross-references fail-loud paragraph by literal heading text not line number" | `grep -qF 'Missing \`model_routing:\` block in \`config.md\`'` (no `\|\| true`) | Same structure; negative `grep -cE … \|\| true` + `[ "$c" -eq 0 ]` is correct for an absence check | ✓ robust |
| "missing-model_routing: fail-loud paragraph back-links…" | `_extract_h4` (loud-fail on missing anchor/empty) then `grep -qF` (no `\|\| true`) | Extractor fails loudly; grep fails on absent text | ✓ robust |
| "model_routing-block none-halt fail-loud paragraph back-links…" | Same pattern as T5 | Same; H4 section window confirmed to include the appended sentence before next heading boundary | ✓ robust |

### `|| true` pattern verdict

The `|| true` guard on `grep -c` / `grep` (no `-c`) assignments is correct: it prevents `set -e` from killing the test before the subsequent `[ -n "$row" ]` or `[ "$count" -eq 1 ]` assertion fires. In each case the variable is still set to `""` or `"0"` (grep's stdout is captured before `||` evaluates), so the downstream assertion correctly detects absence.

### Extraction window verification

- **Test 6 (`#### \`model_routing:\` block`):** back-pointer sentence (line 466) is before the next H4 boundary `#### \`trusted_path:\` block` (line 468) — fully captured. ✓  
- **Test 5 (`#### Missing \`model_routing:\` block in \`config.md\``):** back-pointer sentence (line 512) is before the H2 boundary `## Config Validation Procedure` (line 517) — fully captured. ✓  
- **Tests 1–4 (`### Fields that affect pipeline behavior (must be validated)`):** prose notes (lines 625–629) mention only `verifier_enabled`, `scope_tagger_enabled`, `question_budget`; no extra `model_routing:` occurrences; `grep -c` count is 1. ✓
