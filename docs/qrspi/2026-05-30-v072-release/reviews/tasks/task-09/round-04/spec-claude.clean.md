# Spec Review — Task 09 Round 4 — CLEAN

**Reviewer:** spec-claude  
**Round:** 4 (post-final-fix cycle, commit 7aa0ecc0)  
**Verdict:** CLEAN — all R3 fixes correctly close their issues; no scope overreach; T09 contract preserved.

---

## Verification of R3 Fixes

### Issue A (MED, convergent sf) — jq exit-code guard

**Claim:** `||` guard added after `entry="$(jq -nc ...)"` to prevent silent malformed-manifest writes when jq is absent or fails.

**Verified at** `scripts/run-codex-review.sh` lines 619–626:

```bash
local entry
entry="$(jq -nc \
  --arg tag    "$REVIEWER_TAG" \
  --arg host   "$detected_host" \
  --arg vendor "openai-codex" \
  --arg model  "$MODEL" \
  '{tag: $tag, host: $host, vendor: $vendor, model: $model}')" \
  || { echo "error: jq failed building dispatch-manifest entry (jq exit $?)" >&2; exit 1; }
```

Correctness confirmed on three dimensions:

1. **Guard fires before any manifest write.** `mkdir -p "$round_dir"` and the `tmp`-file sequence begin at line 628 — after the guarded assignment. `exit 1` in the `||` block prevents reaching them. ✓

2. **`$?` value is accurate.** The script runs `set -u` / `set +e` (line 49–50). In bash, the exit status of `var=$(cmd)` is the exit status of `cmd`, so `$?` inside the `||` block carries jq's exit code. ✓

3. **Stderr diagnostic names 'jq'.** The message is `"error: jq failed building dispatch-manifest entry (jq exit $?)"` — the literal string `jq` appears, satisfying the AC12 assertion `grep -qiE 'jq'`. ✓

### Issue B (MED, novel cq-claude F03) — AC11 grep tightened

**Claim:** AC11 grep changed from `'model'` → `'\-\-model'` for symmetry with AC10.

**Verified at** `tests/acceptance/v07-phase1/test-phase1-acceptance.bats` line 1702:

```bash
echo "$err" | grep -qiE '\-\-model' \
  || { echo "stderr does not name --model in rejection diagnostic; got: $err"; return 1; }
```

Pattern tightened as claimed. This is symmetric with the `--reviewer-tag` check in AC10 (line 1639: `grep -qiE 'reviewer-tag'`). ✓

### Issue C (LOW, convergent cq) — Comment updated

**Claim:** Stale "Hand-built JSON object" comment rewritten to jq-centric framing.

**Verified at** `scripts/run-codex-review.sh` lines 589–618. The comment now reads:

> "JSON entry constructed via jq (defense-in-depth: jq --arg performs unconditional JSON string escaping…)"

followed by inline R2/R3 rationale blocks. The old "Hand-built JSON object — values are controlled (no embedded quotes from untrusted input)" phrasing is fully replaced. The new comment accurately describes the implementation and explains the `set +e` guard motivation. ✓

### AC12 new test

**Verified at** `tests/acceptance/v07-phase1/test-phase1-acceptance.bats` lines 1720–1786.

The test:
- Creates a stub `$TMP_DIR/bin/jq` that exits 1 (lines 1750–1755)
- Prepends `$TMP_DIR/bin` to PATH so the stub is found ahead of system jq (line 1762)
- Uses a valid `--model "gpt-5-codex-canary"` and `--reviewer-tag spec-codex` so argument validation passes and jq is actually invoked (ensuring the guard is exercised, not an earlier validation exit)
- Asserts non-zero exit (line 1776) ✓
- Asserts stderr contains `'jq'` (line 1779) ✓
- Asserts no manifest file written (line 1782) ✓

RED→GREEN path is sound: before the R3 fix, `entry` would be `""` (command substitution exit code ignored under `set +e`), and the script would proceed to write `[\n  \n]\n` — a malformed manifest. After the fix, `exit 1` fires and no manifest is written.

---

## Scope Check

Diff touches exactly two files:
- `scripts/run-codex-review.sh` — guard + comment only; no behavioral changes outside `emit_dispatch_manifest_entry`
- `tests/acceptance/v07-phase1/test-phase1-acceptance.bats` — one pattern tighten (AC11) + one new test (AC12)

No T11 fields pre-loaded, no schema drift, no extraneous helpers, no files outside the T09 target list. ✓

---

**All three issues closed correctly. No new issues introduced. PASS.**
