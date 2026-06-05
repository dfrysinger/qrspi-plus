# Spec Review — Task 17, Round 04

- **Reviewer:** spec-claude
- **Round:** 04
- **Verdict:** ✅ Approved — no findings

## Summary

Fix-3 (round-04 diff) is a **test-precision-only** change: four grep patterns in
`tests/unit/test-config-model-routing.bats` were tightened from an any-column anchor
(`^[[:space:]]*\|.*model_routing:`) to a first-column anchor
(`^[[:space:]]*\|[[:space:]]*\`?model_routing:\`?[[:space:]]*\|`) at lines 734, 744,
755, and 767. The `line [0-9]` negative-guard at L773 is unchanged. No production-doc
change was introduced in fix-3.

## Completeness

All five spec DoD items (task-17.md L37–42) are satisfied:

| DoD Item | File:Line | Status |
|---|---|---|
| Exactly one `model_routing:` row in validation table | SKILL.md:615 | ✅ |
| Row names per-vendor five-tier map shape | SKILL.md:615 ("per-vendor five-tier map") | ✅ |
| Row cross-refs schema-def heading by literal text | SKILL.md:615 ("`model_routing:` block") | ✅ |
| Row cross-refs missing-block fail-loud para by literal heading | SKILL.md:615 ("Missing `model_routing:` block in `config.md`") | ✅ |
| Both fail-loud paragraphs back-link to validation table heading | SKILL.md:466, 512 | ✅ |

## Test Expectations (all 5 covered, 6 @test blocks)

| Spec TE | @test block | Lines | Status |
|---|---|---|---|
| TE-1: exactly one row | validation table lists exactly one model_routing: row | L728–736 | ✅ non-vacuous |
| TE-2a: row names shape | …names per-vendor five-tier map shape | L738–747 | ✅ non-vacuous |
| TE-2b: row → schema heading | …cross-references schema-definition heading by literal text | L749–758 | ✅ non-vacuous |
| TE-3: row → fail-loud para by heading not line num | …cross-references fail-loud paragraph by literal heading text not line number | L760–775 | ✅ non-vacuous |
| TE-4: back-pointers from both fail-loud paras | missing-model_routing: + model_routing-block none-halt back-links | L777–792 | ✅ non-vacuous (two separate tests) |
| TE-5: existing loud-failure path intact | NOTE citing pre-existing test; no regression | L723–726 | ✅ |

## Grep-anchoring Fix (fix-3)

The tightened pattern `^[[:space:]]*\|[[:space:]]*\`?model_routing:\`?[[:space:]]*\|`
correctly matches SKILL.md L615 (`| \`model_routing:\` | ...`) and rejects spurious
matches on rows containing `model_routing:` in non-first-column cells. No false
negatives introduced; assertions remain non-vacuous.

## Scope

Only the two target files were modified: `skills/using-qrspi/SKILL.md` and
`tests/unit/test-config-model-routing.bats`. No generated index, no canonical-source
file, no new validator framework, no rows added for other config blocks. Production
diff is narrow: one table row + two one-sentence back-pointer appends. ✅
