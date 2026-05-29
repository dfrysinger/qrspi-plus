# Spec-Gate Review — Round 5 — CLEAN

**Reviewer:** spec-claude  
**Round:** 5  
**Commit:** f257cd4 (round-4 fix-cycle-3)  
**Scope:** HEAD~1..HEAD (narrowed)  
**Scope hint:** `docs/qrspi/2026-05-27-v071-hardening/tasks/task-01.md`, `tests/unit/test-run-third-party-llm.bats`

---

## Summary

No findings. Both F01 and F02 from round 4 are correctly resolved. No new defects introduced.

---

## Verification

### F01 resolution — Spec bullet 14 wording over-promise removed

The diff removes "or an empty string" from the test-expectation bullet and removes "non-empty" from the description prose.

**Before (task-01.md line 18 old):**
> An `api_key_env` field containing characters outside `[A-Za-z0-9_]` **or an empty string** causes the script to exit with a `key-resolution` diagnostic before API-key resolution

**After (task-01.md line 31 current):**
> An `api_key_env` field containing characters outside `[A-Za-z0-9_]` causes the script to exit with a `key-resolution` diagnostic before API-key resolution

Confirmed at `docs/qrspi/2026-05-27-v071-hardening/tasks/task-01.md:31` in the worktree.  
The description prose at line 16 likewise no longer includes "non-empty". ✅

The empty-string die-path (different code path, `provider-field missing`) is no longer incorrectly attributed to `key-resolution` in the spec. ✅

### F02 resolution — Asserting test added for invalid-identifier `api_key_env`

New test at `tests/unit/test-run-third-party-llm.bats:174–183`:

```
@test "exit 1: api_key_env containing invalid shell-identifier char (hyphen) exits with key-resolution diagnostic" {
  _write_config_openai "$FIXTURE_DIR" p1 https://api.example.com MY-BAD-KEY false false
  run bash -c "echo hi | '$DISPATCHER' --artifact-dir '$FIXTURE_DIR' --provider p1 --model m --output-file '$OUTPUT_FILE'"
  [ "$status" -ne 0 ]
  [[ "$output" == *"key-resolution"* ]]
  [ ! -f "$OUTPUT_FILE" ]
}
```

- Uses `MY-BAD-KEY` (contains hyphens — outside `[A-Za-z0-9_]`). ✅  
- Asserts non-zero exit (`$status -ne 0`). ✅  
- Asserts `key-resolution` appears in output. ✅  
- Asserts output file was not created (no network dispatch). ✅  
- This is a genuine behavioral assertion, not just a smoke test. ✅

### No new issues introduced

- The spec change is a narrow, accurate trim (removal of over-promised clause only).  
- The description trim is consistent with the bullet trim.  
- The pre-existing `EMPTY_KEY_XYZ=""` test at line 165–172 remains unchanged — it covers a valid-identifier-but-empty-resolved-value path, which is a distinct code path and remains correct.  
- No scope creep, no unrelated file edits, no extra features.  
- Diff is 41 lines touching exactly the two scoped files.

---

**Verdict: CLEAN — spec-gate passes for round 5.**
