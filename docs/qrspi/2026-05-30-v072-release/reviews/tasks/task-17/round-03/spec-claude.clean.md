# Spec Review: Task 17 — Round 03

**Reviewer:** spec-claude  
**Verdict:** ✅ CLEAN — no findings

---

## Checklist summary

### 1. Completeness

All five spec requirements fully implemented:

| Requirement | Location | Status |
|---|---|---|
| Exactly one `model_routing:` row in validation table | `SKILL.md` L615 under `### Fields that affect pipeline behavior (must be validated)` | ✅ |
| Row names per-vendor five-tier map shape ("a per-vendor five-tier map") and cross-references schema-definition heading by literal text ("`model_routing:` block") | `SKILL.md` L615 | ✅ |
| Row cross-references missing-block fail-loud paragraph by literal heading text ("Missing `model_routing:` block in `config.md`") | `SKILL.md` L615 | ✅ |
| Back-pointer in none-halt paragraph → validation table heading by literal text | `SKILL.md` L466 | ✅ |
| Back-pointer in missing-block paragraph → validation table heading by literal text | `SKILL.md` L512 | ✅ |

### 2. Scope

Only the two target files were modified — `skills/using-qrspi/SKILL.md` and `tests/unit/test-config-model-routing.bats`. No out-of-scope changes.

### 3. Interpretation

No misreadings. Back-pointer sentences use the exact form "This required block is enumerated in the validation table at `### Fields that affect pipeline behavior (must be validated)`." Both fail-loud paragraphs (none-halt L466, missing-block L512) carry the pointer.

### 4. All 6 TEs covered

| TE | Test name | Assertion | Status |
|---|---|---|---|
| TE-1 | `validation table lists exactly one model_routing: row` | `grep -cE '^[[:space:]]*\|.*model_routing:'`; `[ "$count" -eq 1 ]` | ✅ |
| TE-2 | `validation table model_routing: row names per-vendor five-tier map shape` | `grep -qE "five.tier\|per.vendor\|vendor.neutral"` | ✅ |
| TE-3 | `validation table model_routing: row cross-references schema-definition heading by literal text` | `grep -qF '\`model_routing:\` block'` | ✅ |
| TE-4 | `validation table model_routing: row cross-references fail-loud paragraph by literal heading text not line number` | `grep -qF 'Missing \`model_routing:\` block in \`config.md\`'` + rejects `line [0-9]{2,}\|#[0-9]{2,}` | ✅ |
| TE-5 | `missing-model_routing: fail-loud paragraph back-links to validation table heading by literal text` | `_extract_h4` → `grep -qF 'Fields that affect pipeline behavior (must be validated)'` | ✅ |
| TE-6 | `model_routing-block none-halt fail-loud paragraph back-links to validation table heading by literal text` | `_extract_h4` → `grep -qF 'Fields that affect pipeline behavior (must be validated)'` | ✅ |

Existing missing-block loud-failure path coverage is noted in the block comment (NOTE:) — correctly deferred to the prior test, no duplication.

### 5. Round-02 fix-2 anchoring correctness (the specific round-03 concern)

The 4 validation-table row-extraction greps (`grep -cE '^[[:space:]]*\|.*model_routing:'` in TE-1; `grep -E '^[[:space:]]*\|.*model_routing:'` in TE-2, TE-3, TE-4) are anchored to the markdown table-row shape `^[[:space:]]*\|.*model_routing:`. The actual SKILL.md row at L615 begins `| \`model_routing:\`` — no leading whitespace, starts with `|`, contains `model_routing:` — which satisfies the pattern. Anchoring is **not vacuous**: it requires a pipe-delimited table-row shape rather than matching prose references. No spec drift introduced.

### 6. Extra features

None. No generated index, no canonical-source file, no extra validator framework, no additional rows for other config blocks.

### 7. Target files

Diff touches only `skills/using-qrspi/SKILL.md` and `tests/unit/test-config-model-routing.bats` — the exact target files listed in the task spec.
