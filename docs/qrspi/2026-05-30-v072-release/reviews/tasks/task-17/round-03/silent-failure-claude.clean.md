# Silent-Failure Review — Clean Sentinel
reviewer: silent-failure-claude
task: T17 (G23 doc-hardening)
round: 3
artifact: tests/unit/test-config-model-routing.bats + skills/using-qrspi/SKILL.md

## Verdict: CLEAN

No silent-failure paths found in the round-03 fix-2 changes.

---

## Verification of anchored grep pattern

**Pattern added**: `^[[:space:]]*\|.*model_routing:`

**Against SKILL.md L615**:
```
| `model_routing:` | using-qrspi, Goals, Plan, Parallelize, Implement, Integrate | required top-level block — a per-vendor five-tier map …
```
- `^[[:space:]]*` — matches zero leading spaces (line starts at column 0) ✓
- `\|` — matches opening `|` ✓
- `.*model_routing:` — matches ` \`model_routing:\`` in the field cell ✓

Pattern is **non-vacuous**: the shape prefix `^[[:space:]]*\|` requires a genuine markdown table-row leader, not a bare prose mention of `model_routing:`.

---

## Test-by-test silent-failure analysis

### Test 1 — "validation table lists exactly one model_routing: row"
- `grep -cE … || true` — `|| true` suppresses grep exit-1 on zero matches; count becomes 0.  
  `[ "$count" -eq 1 ]` then fails when the row is absent. **Non-vacuous exact-count guard. ✓**

### Test 2 — "… row names per-vendor five-tier map shape"
- Row extracted with `grep -E … || true`; `[ -n "$row" ]` fails loud if nothing matched.  
- Then `grep -qE "five.tier|per.vendor|vendor.neutral"` matches "per-vendor five-tier map" in L615  
  (`.` in ERE matches `-`). **Non-vacuous. ✓**

### Test 3 — "… row cross-references schema-definition heading by literal text"
- Same `[ -n "$row" ]` guard; then `grep -qF '\`model_routing:\` block'` matches L615's
  "see the schema heading \`model_routing:\` block". **Non-vacuous. ✓**

### Test 4 — "… cross-references fail-loud paragraph by literal heading text not line number"
- `[ -n "$row" ]` guard ✓  
- `grep -qF 'Missing \`model_routing:\` block in \`config.md\`'` matches L615 ✓  
- Negative: `grep -cE "line [0-9]{2,}|#[0-9]{2,}" || true` then `[ "$c" -eq 0 ]` — L615
  contains no bare line-number references. **Both positive and negative assertions non-vacuous. ✓**

### Test 5 — "missing-model_routing: fail-loud paragraph back-links to validation table heading"
- `_extract_h4` targets `#### Missing \`model_routing:\` block in \`config.md\`` (L510).  
  Helper fails loud (stderr + return 1) if anchor absent or content empty.  
- Extracted section includes L512: "This required block is enumerated in the validation table
  at \`### Fields that affect pipeline behavior (must be validated)\`."  
- `grep -qF 'Fields that affect pipeline behavior (must be validated)'` matches. **Non-vacuous. ✓**

### Test 6 — "model_routing-block none-halt fail-loud paragraph back-links to validation table heading"
- `_extract_h4` targets `#### \`model_routing:\` block` (L448).  
  Section spans L449–L467 (terminates at L468 `#### \`trusted_path:\` block`).  
- L466 contains "This required block is enumerated in the validation table at
  \`### Fields that affect pipeline behavior (must be validated)\`."  
- `grep -qF 'Fields that affect pipeline behavior (must be validated)'` matches. **Non-vacuous. ✓**

---

## No new silent-failure paths introduced

- `extract_section` fails loudly (returns 1, emits named diagnostic to stderr) on missing anchor
  or empty extract; called without `run` so test fails immediately on non-zero return. ✓
- `_extract_h4` emits `echo "h4 anchor not found: … in $file" >&2; return 1` on missing anchor;
  stderr passes through command substitution unaffected; subsequent grep failure is visible. ✓
- `|| true` on grep is only used to suppress exit-1 from `grep -c` (zero-count case), never to
  suppress a downstream assertion. Count/content assertions follow unconditionally. ✓
- SKILL.md prose changes (L466, L512, L615) are additive back-pointer sentences; no existing
  fail-loud invariant is weakened or conditionalized. ✓
