# Spec Review — Round 08 (fix-7 increment) — CLEAN

**Reviewer:** spec-claude  
**Round:** 8  
**Fix increment:** fix-7 (R7-F01 regular-file guard correction)  
**Verdict:** ✅ Approved

## What was verified

The fix-7 increment adds `[ -f ] && [ -r ]` at the three required guard sites and adds one hermetic regression test. All checks pass.

---

### Check 1 — Site 1: `agent_file` guard in `resolve_tier` (Layer 2)

**File:** `scripts/_resolve-lib.sh` line 85

```bash
if [ -n "$agent_file" ] && [ -f "$agent_file" ] && [ -r "$agent_file" ]; then
```

✅ Both `-f` (regular-file) AND `-r` (readable) are present. A readable directory no longer passes this guard.

---

### Check 2 — Site 2: `CONFIG_MD` guard in `resolve_tier` (Layer 3)

**File:** `scripts/_resolve-lib.sh` line 99

```bash
if [ -n "${CONFIG_MD:-}" ] && [ -f "${CONFIG_MD:-}" ] && [ -r "${CONFIG_MD:-}" ]; then
```

✅ Both `-f` AND `-r` are present. A directory path for CONFIG_MD causes `config_present=0` to be set, routing to the Layer-4 fallback (not to the wrong unconfigured-tier halt).

---

### Check 3 — Site 3: negated CONFIG_MD halt guard in `resolve_model`

**File:** `scripts/_resolve-lib.sh` line 142

```bash
if [ -z "${CONFIG_MD:-}" ] || [ ! -f "${CONFIG_MD:-}" ] || [ ! -r "${CONFIG_MD:-}" ]; then
```

✅ Both `! -f` AND `! -r` are present in the negated De Morgan form. A directory path now trips `[ ! -f ]` and emits the `not a readable file` config-path diagnostic (exit 1), not the unconfigured-tier message.

---

### Check 4 — Regression test

**File:** `tests/unit/test-config-model-routing.bats` lines 506–519

Test name: `_resolve-lib.sh [exec]: resolve_model HALTS with the config-path diagnostic when CONFIG_MD points at a DIRECTORY (R7-F01 regular-file guard)`

The test:
1. Creates a real directory (`mkdir -p "$cfgdir"`) — this is readable but not a regular file.
2. Passes the directory path as CONFIG_MD to `_exec_resolve_model "$cfgdir" "medium"`.
3. Asserts `[ "$status" -eq 1 ]` — halts with non-zero exit.
4. Asserts `[[ "$stderr" == *"not a readable file"* ]]` — the config-path diagnostic, which matches the exact text in the `printf` at line 143 of `_resolve-lib.sh`.
5. Asserts `[[ "$stderr" != *unconfigured* ]]` — explicitly excludes the wrong unconfigured-tier cause.

✅ The test is hermetic, genuinely exercises the directory case, and asserts the correct diagnostic cause distinction.

---

### Check 5 — Additive-only / no scope creep

The fix-7 increment touches exactly two files:
- `scripts/_resolve-lib.sh` — only the three guard expressions were changed; `_halt_unconfigured_tier`, `_validate_tier`, allowlist cases, Layer-4 fallback text, trusted_path note, design-ID comments, matrix lookup functions, and the `QRSPI_SOURCE_ONLY` guard are all untouched.
- `tests/unit/test-config-model-routing.bats` — one new `@test` block added (lines 506–519); no existing tests modified or removed.

✅ No refactor, no diagnostic text changes, no invariants disturbed.

---

### Check 6 — Diagnostic text unchanged

The `printf '[routing] HALT: CONFIG_MD is unset or not a readable file; '` at `_resolve-lib.sh` line 143 is unchanged from prior rounds. The regression test's `[[ "$stderr" == *"not a readable file"* ]]` pattern matches this text exactly.

✅ Diagnostic text preserved.

---

## Summary

All three guard sites carry the correct `[ -f ] && [ -r ]` (or `[ ! -f ] || [ ! -r ]`) compound, the regression test exercises the directory-as-CONFIG_MD scenario and asserts the right diagnostic/cause distinction, and the change is purely additive. No findings.
