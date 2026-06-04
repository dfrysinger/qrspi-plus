---
reviewer: silent-failure-claude
task: 17
round: 4
fix: fix-3 (commit 1d0778b)
verdict: clean
---

# Silent-Failure Review — Round 04 — Clean

No silent-failure issues found in `tests/unit/test-config-model-routing.bats` block L728–792.

## Checks performed

### 1. Anchor non-vacuousness (critical check)

The tightened anchor `^[[:space:]]*\|[[:space:]]*\`?model_routing:\`?[[:space:]]*\|`
was verified against SKILL.md:615 (production row in worktree):

```
| `model_routing:` | using-qrspi, Goals, Plan, Parallelize, Implement, Integrate | ...
```

The anchor matches this row exactly — count == 1. The tests are non-vacuous: they
genuinely fail if the row is absent or the first-column field name is malformed.

### 2. `|| true` scope (L734, L744, L755, L767, L773)

All five uses of `|| true` are narrowly scoped to suppress grep's non-zero exit on
zero-match, not to swallow count or content failures:

- **L734** (`grep -cE … || true`): count receives "0" if grep exits 1; `[ "$count" -eq 1 ]`
  fires loudly. `|| true` does not mask the assertion.
- **L744, L755, L767** (`grep -E … || true`): `$row` receives empty string;
  `[ -n "$row" ]` fires loudly. No silent pass.
- **L773** (`grep -cE … || true`): counts line-number-style references; `|| true`
  handles the expected-good path (zero matches). `[ "$c" -eq 0 ]` still asserts.

### 3. `[ -n "$row" ]` guards (L745, L756, L768)

Every multi-step extraction test asserts `[ -n "$row" ]` before applying content checks.
An absent row is a loud test failure, not a silent pass.

### 4. Content assertions are non-vacuous and unguarded by `|| true`

- **TE-2 shape** (L746): `grep -qE "five.tier|per.vendor|vendor.neutral"` — no `|| true`;
  exits nonzero on mismatch. Row text "per-vendor five-tier map" satisfies the pattern.
- **TE-3 schema heading** (L757): `grep -qF '\`model_routing:\` block'` — no `|| true`;
  row contains this literal.
- **TE-3 fail-loud heading** (L770): `grep -qF 'Missing \`model_routing:\` block in \`config.md\`'`
  — no `|| true`; row contains this literal.
- **TE-4 back-links** (L782, L791): `grep -qF 'Fields that affect pipeline behavior (must be validated)'`
  — no `|| true`; both SKILL.md paragraphs contain this literal (confirmed from diff).

### 5. No new silent-failure path introduced

Fix-3 is test-only. No production code was changed. No error path was added or widened.
`extract_section` on a missing H3 heading returns empty → count=0 → `[ "$count" -eq 1 ]`
fails loudly. No vacuous pass path exists.

## ✅ Approved
