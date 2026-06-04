# spec-claude — CLEAN (round 02)

Reviewer: spec-claude  
Round: 2  
Task: 17 (G23 validation table covers `model_routing:` and cross-links fail-loud paragraphs)  
Verdict: **CLEAN — no findings**

## R01 F01 gap closure verified

Round-01 found that the `#### \`model_routing:\` block` none-halt paragraph's back-pointer was
present in production but unpinned by any bats test.

Round-02 fix: added `@test "model_routing-block none-halt fail-loud paragraph back-links to
validation table heading by literal text"` (test-config-model-routing.bats L785-792). The test
calls `_extract_h4 "$USING" '` `` `model_routing:` block` `` '` and asserts the extracted section
contains the literal string `Fields that affect pipeline behavior (must be validated)`. The
production paragraph at SKILL.md L466 now ends with exactly that back-pointer sentence, so the
assertion is correctly exercised.

## All task-17.md test expectations satisfied

| TE | Bats test (line) | Evidence |
|----|-----------------|---------|
| TE-1: exactly one `model_routing:` row | L728-736 | `grep -c "model_routing:"` eq 1 |
| TE-2: row names per-vendor five-tier map shape | L738-747 | `grep -qE "five.tier\|per.vendor\|vendor.neutral"` |
| TE-2/TE-3: row cross-refs schema heading by literal text | L749-758 | `grep -qF '` `` `model_routing:` block` `` '` |
| TE-3: row cross-refs fail-loud heading by literal text, not line number | L760-775 | `grep -qF 'Missing \`model_routing:\` block in \`config.md\`'` + line-number absence check |
| TE-4 (missing-block para back-pointer) | L777-783 | `_extract_h4` + `grep -qF 'Fields that affect pipeline behavior (must be validated)'` |
| TE-4 (none-halt para back-pointer) — **R01 F01 gap** | L785-792 | same pattern, now closed |

## DoD verification (production doc)

- SKILL.md L466 (`#### \`model_routing:\` block` none-halt paragraph): back-pointer sentence
  present. ✅
- SKILL.md L512 (`#### Missing \`model_routing:\` block in \`config.md\`` paragraph): back-pointer
  sentence present. ✅
- SKILL.md L615 (validation table): exactly one `model_routing:` row; names "per-vendor five-tier
  map"; references `\`model_routing:\` block` heading and `Missing \`model_routing:\` block in
  \`config.md\`` heading by literal text, no line numbers. ✅

## Scope / over-implementation

- Only `skills/using-qrspi/SKILL.md` and `tests/unit/test-config-model-routing.bats` modified —
  both in the Target files list. ✅
- Six new `@test` blocks map 1:1 to the six task-17 test expectations; no extras. ✅
- No new helpers, config options, generated indexes, or utility functions beyond spec. ✅
