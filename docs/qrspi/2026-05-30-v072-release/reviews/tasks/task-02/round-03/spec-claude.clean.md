---
reviewer: spec-claude
round: 3
task: 02
verdict: CLEAN
---

# Spec Review — Task 02, Round 03

No findings. The R2 fix is in scope, no spec drift, no new behaviours added, all 5 new BATS tests are behavioural, and the halt-cause taxonomy comment is correct.

## Verification log

### Fix 1 — Integer overflow bypass (HIGH security)

**Script** `scripts/verifier-fan-in.sh` line 251:
```bash
if [[ -z "${raw_score:-}" ]] || ! [[ "$raw_score" =~ ^[0-9]{1,3}$ ]]; then
```
Old regex `^[0-9]+$` → new `^[0-9]{1,3}$`. Cap at 3 digits excludes any 19-digit string
that would wrap modulo 2^64. ✓

**Header comment** line 36 updated to: `score:` absent or **not 1–3 decimal digits`. ✓

**Test** `R2 fix 1: score with > 3 digits is rejected as score_unparseable`
(bats lines 402–411):
- Fixture: 20-digit string `18446744073709551706` (= 2^64 + 90, would wrap to 90 under old code).
- Asserts `status -ne 0` AND `.halts[0].cause == score_unparseable`.
- Behavioural (not vacuous). ✓

---

### Fix 2 — Sidecar readability unguarded (Medium correctness)

**Script** lines 239–243 — new guard inserted after sidecar existence check, before score parse:
```bash
if [[ ! -r "$sidecar" ]]; then
  echo "verifier-fan-in: cannot read sidecar file: $sidecar" >&2
  record_halt "$fid" sidecar_unreadable
  continue
fi
```
Guard is in the correct position: after `-f "$sidecar"` (existence confirmed) and before
`extract_frontmatter_field "$sidecar"` (read attempted). ✓

**Header comment** line 35: `sidecar_unreadable — sidecar file exists but cannot be read (permission/I/O error)`. ✓

**Test A** `R2 fix 2: unreadable sidecar records halt cause sidecar_unreadable`
(bats lines 417–427):
- Fixture: valid finding + sidecar, then `chmod 000` the sidecar.
- Asserts `status -ne 0` AND `.halts[0].cause == sidecar_unreadable`. ✓

**Test B** `R2 fix 2: unreadable sidecar emits cannot-read message to stderr`
(bats lines 429–438):
- Same fixture; asserts output/stderr contains `"cannot read sidecar"`.
- Script emits `"verifier-fan-in: cannot read sidecar file: $sidecar"` → glob `*"cannot read sidecar"*` matches. ✓

Both behavioural (not vacuous). ✓

---

### Fix 3 — Halt-cause misattribution on finding I/O error (Medium correctness)

**Script** line 203 — changed from `record_halt "$fid" missing_change_type`
to `record_halt "$fid" finding_unreadable`. ✓

The finding readability guard (lines 200–205) correctly derives `fid` from the filename
(bypassing `extract_frontmatter_field`, which would also fail on an unreadable file)
and then records the correct cause. ✓

**Header comment** line 37: `finding_unreadable — finding file exists but cannot be read (permission/I/O error)`. ✓

**Test A** `R2 fix 3: unreadable finding file records halt cause finding_unreadable`
(bats lines 445–455):
- Fixture: valid finding + sidecar, then `chmod 000` the finding.
- Asserts `status -ne 0` AND `.halts[0].cause == finding_unreadable`. ✓

**Test B** `R2 fix 3: unreadable finding file still emits cannot-read message to stderr`
(bats lines 457–466):
- Same fixture; asserts output/stderr contains `"cannot read"`.
- Script emits `"verifier-fan-in: cannot read finding file: $finding"` → matches. ✓

Both behavioural (not vacuous). ✓

---

### Finding 4 — Low (duplicate of #3)

Covered by Fix 3 above. ✓

---

### Scope check

Diff touches exactly two files:
1. `scripts/verifier-fan-in.sh` — 3 targeted hunks (header comment, finding-readability
   halt cause, sidecar-readability guard, score regex).
2. `tests/unit/test-verifier-fan-in-script.bats` — 78 lines appended (5 new test cases).

Both files are in the task-02 Target files scope (script + its tests). No other files
modified. No new behaviours added outside the 4 KEPT findings. No spec drift. ✓

### `teardown()` cleanup note

The existing `teardown()` function (line 14–17) already runs `chmod -R u+r "$BATS_TEST_TMPDIR"`
to restore permissions so BATS tmp cleanup succeeds after the new `chmod 000` fixtures.
This was present before R2; no action required. ✓
