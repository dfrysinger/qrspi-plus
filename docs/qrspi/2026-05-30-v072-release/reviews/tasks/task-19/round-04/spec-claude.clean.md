# Spec Review — Task 19 Round 4 — CLEAN

**Reviewer:** spec-claude  
**Round:** 4  
**HEAD:** a312e49  
**Result:** ✅ Approved — no spec divergence, no regressions, test is meaningful.

---

## Scope of round-04 changes

Two files touched, exactly as claimed:

| File | Change |
|------|--------|
| `scripts/second-reviewer-available.sh` | Added `[ -z "$_default_vendor" ]` as FIRST clause of the availability guard (line 55); comment above guard updated to document the empty-string case |
| `tests/unit/test-second-reviewer-available.bats` | Added `empty-default-vendor-guard` test at line 453 |

No files outside the task-19 target list were modified.

---

## Guard clause verification

**File:** `scripts/second-reviewer-available.sh` line 55

```bash
if [ -z "$_default_vendor" ] || [ "$_default_vendor" = "none" ] || [ "$_vendor" = "none" ] || ! second_reviewer_vendor_known "$_vendor"; then
```

`[ -z "$_default_vendor" ]` is correctly positioned as the **first** clause.

**Logic path with empty default vendor + valid override (the injected fault):**
1. `_default_vendor=""` (empty from stub `lookup_default_second_reviewer`)
2. `_vendor="openai-codex"` (passed as positional override, lines 44–48)
3. Guard: `[ -z "" ]` → **TRUE** → enters block → emits `[second-reviewer-unavailable]`, exits 1 ✓

**Without this guard** (pre-round-04 code): `[ "" = "none" ]` = FALSE, `[ "openai-codex" = "none" ]` = FALSE, `! second_reviewer_vendor_known "openai-codex"` = FALSE → would exit 0 (silent bug). The guard closes that hole.

---

## Override-success regression check

Tested against existing override-success tests:

| Scenario | `_default_vendor` value | `[ -z "$_default_vendor" ]` | Outcome |
|----------|-------------------------|-----------------------------|---------|
| COPILOT_CLI=1, override `openai-codex` | `openai-codex` (non-empty) | FALSE | not triggered; exits 0 ✓ |
| COPILOT_CLI=1, override `anthropic-claude` | `openai-codex` (non-empty) | FALSE | not triggered; exits 0 ✓ |
| COPILOT_CLI=1, no override | `openai-codex` (non-empty) | FALSE | not triggered; exits 0 ✓ |
| CLAUDE_PROJECT_DIR set, no override | `openai-codex` (non-empty) | FALSE | not triggered; exits 0 ✓ |

All existing override-success tests (`override-boundary: explicit vendor override accepted on Copilot CLI`, `override-boundary: explicit anthropic-claude override accepted on Copilot CLI`, `override-boundary: probe works without CONFIG_MD`, `override-boundary: probe does not enforce primary/second vendor distinctness`) remain valid. No regression.

---

## Unknown-host guard regression check

With all host env vars unset: `_default_vendor` = `none` (from `*) printf 'none\n'` branch in `lookup_default_second_reviewer`). `[ -z "none" ]` = FALSE; next clause `[ "none" = "none" ]` = TRUE → exits 1. The unknown-host-guard test (`unknown-host-guard: unknown host with recognized vendor override exits non-zero`) is not affected. ✓

---

## New test: meaningfulness analysis

**Test name:** `empty-default-vendor-guard: empty lookup result exits non-zero with [second-reviewer-unavailable]`  
**Location:** `tests/unit/test-second-reviewer-available.bats` line 453

**Fault injection mechanism:** Stub `_resolve-lib.sh` at `$_work_dir/_resolve-lib.sh` with `lookup_default_second_reviewer() { printf ''; }`. The probe script is copied to `$_work_dir/`, so `_SCRIPT_DIR` resolves to `$_work_dir`, and both stubs are sourced correctly from that directory. ✓

**Why the test is non-vacuous:**

- The stub `second_reviewer_vendor_known` returns 0 for `openai-codex` (the injected override). This is intentional — it isolates the empty-default-vendor guard from the vendor-known check, proving that `[ -z "$_default_vendor" ]` is the specific clause that fires.
- On the **old** code (without `[ -z "$_default_vendor" ]`), this test would have asserted non-zero but seen exit 0 → **test would FAIL on old code**. It is a genuine discriminator.
- On the **new** code, `[ -z "$_default_vendor" ]` fires first → exits 1 → **test PASSES**. ✓

**Assertions are adequate:**
- `[ "$_status" -ne 0 ]` — non-zero exit checked ✓
- `line_count -eq 1` — exactly one stderr line checked ✓
- `grep -q '^\[second-reviewer-unavailable\]'` — correct diagnostic tag checked ✓

The test does not assert `host=` or `vendor=` content in the stderr line, but the tested behavior (fail-closed on empty default, single-line diagnostic, correct tag) is the core property being pinned. The assertions are sufficient to verify the spec requirement: "missing default vendor exits non-zero with exactly one `[second-reviewer-unavailable]` stderr line."

---

## Spec alignment

Task-19.md Definition of done:
> "Unknown host, missing default vendor, unknown vendor, and unavailable vendor all exit non-zero with exactly one stderr line beginning `[second-reviewer-unavailable]` and naming the detected host plus requested/default vendor."

The "missing default vendor" case was previously emergent (fell through to `"none"` check only if `lookup_default_second_reviewer` returned a string). Making it inherent via `[ -z "$_default_vendor" ]` as the first clause is fully within spec. The comment at lines 50–54 accurately documents the reason. ✓

No scope creep. No over-engineering. No missing requirements.
