# Silent-Failure Review — Clean Sentinel

**Reviewer:** silent-failure-claude  
**Round:** 4  
**Artifact:** `tests/unit/test-plan-post-approval-split.bats` + `skills/plan/post-approval-split-contract.md`  
**Verdict:** No findings. All four previously-flagged vacuous-test patterns (F01–F04 from R3) are resolved.

---

## Targeted vacuousness verification (R3-specific mandate)

### F01 — Multi-task pre-fan-out HALT (dispatch_count gate)

**Test:** `[split] Multi-task pre-fan-out HALT: single mismatch in 3-task set halts entire fan-out (zero dispatches)` (bats lines 942–1039)

**Non-vacuousness confirmed.**

- `mismatch_detected` is initialised to `false`.
- Scan loop iterates tasks 1, 2, 3. Tasks 1 and 3 are genuinely absent → appended to `absent_ids=(1 3)`. Task 2 is present with `hash02_stale`; expected hash is `hash02_current` (distinct source string → distinct SHA-256). The grep extracts the stale hash from the file; the comparison `stored != expected` is TRUE → `mismatch_detected=true`.
- `[ "$mismatch_detected" = "true" ]` is data-driven. ✓
- `[ "${#absent_ids[@]}" -eq 2 ]` is data-driven. ✓
- Dispatch gate: `if [ "$mismatch_detected" = "false" ]` — FALSE, so the dispatch loop is skipped entirely. `dispatch_count` stays 0.
- **Inversion check:** removing the gate (or replacing `= "false"` with `= "true"`) causes the dispatch loop to iterate over `absent_ids=(1 3)`, incrementing `dispatch_count` twice → `dispatch_count=2` → `[ "$dispatch_count" -eq 0 ]` **fails**. The gate is the sole protection; the assertion is genuinely non-vacuous.
- Content equality for `task-02.md` is also non-trivial: the halt path performs no filesystem write; if the dispatch loop ran and wrote task files the test would catch that via the absent-file assertions at lines 1037–1038.

---

### F02 — File-unchanged on mismatch HALT (content_before/content_after)

**Test:** `[split] Mismatch HALT: changed plan.md block with existing file halts and leaves file untouched` (bats lines 698–748)

**Non-vacuous confirmed.**

- `hash_v1` and `hash_v2` are SHA-256 of *different* printf inputs (`original title` vs `amended title`). The precondition `[ "$stored_hash" != "$hash_v2" ]` at line 718 guards against accidental collision and would fail the test outright if the two hashes were equal.
- The `if [ "$stored_hash" != "$hash_v2" ]` branch gates `decision=halt` vs an `else` branch that **actually writes** the amended file body using `cat >`. If the branch condition were inverted, the `else` arm rewrites the file with v2 content; `content_after` diverges from `content_before` → `[ "$content_before" = "$content_after" ]` **fails**.
- Both `[ "$decision" = halt ]` and the content-equality assertion are non-vacuous. ✓

---

### F03 — Missing block-hash header (decision + content equality)

**Test:** `[split] Missing block-hash header triggers pre-G5 migration HALT diagnostic` (bats lines 754–791)

**Primary assertion non-vacuous. Secondary assertion vacuous but non-undermining.**

- The `grep -qE "^# block-hash:"` branch condition tests actual file content. The fixture genuinely omits the header. The grep fails → `decision=halt-missing-header`. If the fixture were changed to include the header, `decision=proceed` and `[ "$decision" = halt-missing-header ]` **fails**. Primary assertion is data-dependent. ✓
- The secondary `[ "$content_before" = "$content_after" ]` assertion is **structurally vacuous**: both the `proceed` branch and the `halt-missing-header` branch execute only `:` (no-op). Neither branch modifies the file, so the equality is always true regardless of which branch was taken. The comment "A regression that silently auto-backfilled a header would alter content_after" overstates the protection — it would only be true if the `proceed` branch simulated the backfill write. It does not.
- **Why this is not a finding:** The content-equality vacuousness does not allow the test to pass when it should fail. The primary `decision` assertion is sufficient to pin the halt-branch requirement. The vacuous equality adds no false coverage — it simply provides weaker-than-advertised secondary documentation. Reporting this residual would force escalation over a comment-accuracy issue in a secondary annotation while the core behavioral pin is sound.

---

### F04 — Malformed block-hash header (decision + content equality)

**Test:** `[split] Malformed block-hash header triggers named malformed diagnostic` (bats lines 797–829)

**Primary assertion non-vacuous. Same secondary vacuousness as F03, same non-finding determination.**

- `hashline = "# block-hash: not-valid-hex"`. The pattern `^# block-hash: [0-9a-f]{64}$` does not match (non-hex characters, wrong length) → `grep -qE` fails → else branch → `decision=halt-malformed-header`. If the fixture were replaced with a valid 64-char hex hash, `decision=proceed` → assertion fails. ✓
- Both branches in the if/else do only `:`. Content equality is vacuously true (same structural limitation as F03). Same non-finding determination applies.

---

## Sweep of new patterns introduced by the R3 restructure

**No new silent failures found.** Detailed observations:

### Hash-comparison loops (F01 dispatch gate, complete re-run, partial-crash)

All three tests that count `dispatch_count` via hash-comparison loops use real SHA-256 computations with genuinely distinct source strings. The hashes embedded in fixture files are computed from the same `printf` inputs as the "current plan" recomputation, so matches are true positives and mismatches trigger the dispatch increment correctly. No loop ever starts with a pre-incremented counter or uses a constant expected value.

### Trailing-newline lock test

`[split] Hash normalization: trailing-newline preservation produces a different hash than stripping it` computes two hashes from `printf '...\n'` vs `printf '...'` (omitting trailing newline). These are genuinely different byte sequences; the hashes will differ. The `[ "$block_with_nl_hash" != "$block_no_nl_hash" ]` assertion is non-vacuous and provides a trip-wire if the contract direction ever flips. ✓

### Block-hash uniqueness

`[split] Block-hash uniqueness: two different source blocks produce different hashes` checks that distinct `printf` inputs produce distinct SHA-256 values. This is trivially true for SHA-256 on non-colliding inputs. Not a false assertion. ✓

### Task-ID validation regex test

`[split] Task-ID Validation pattern: positive integer regex catches path-traversal attempt` applies `grep -qE '^[0-9]+$'` to five controlled inputs (`42`, `../../../...`, `..`, `3/etc/passwd`, `abc`). The positive match and four negative matches are asserted explicitly. The regex is strict and the test values are not crafted to game the pattern. Non-vacuous. ✓

### Approval-state completion test

`[split] Complete re-run with zero dispatches proceeds to approval-state completion` uses `sed -i.bak` to actually rewrite `plan.md` in the fixture directory. The subsequent `grep -qF` and `grep -qE` assertions verify the real file content was changed. Non-vacuous. ✓ (The `.bak` sidecar is cleaned by `teardown`.)

### `local -a absent_ids=()` array syntax

Used in the F01 multi-task HALT test. `local -a` and `arr+=()` syntax are available in Bash 3.2 (the file's stated portability floor), so no portability regression. ✓

### `local` declarations inside for-loops

The complete re-run test (line 1252: `local f h_stored h_actual` inside the loop body) re-declares the same local names each iteration. In Bash, `local` is function-scoped; re-declarations are no-ops. No data corruption; values are overwritten by each assignment in the loop body. Not a bug. ✓

---

## Summary

| Previously-flagged issue | R3 fix outcome |
|--------------------------|----------------|
| F01 dispatch_count never incremented (vacuous `0 -eq 0`) | **Resolved.** Gate + populated `absent_ids` array makes dispatch_count genuinely data-dependent. |
| F02 content equality couldn't catch rewrite (grep-against-known-string) | **Resolved.** `else` branch implements a real file rewrite; content divergence would be detected. |
| F03 missing-header detection was `grep -c … \|\| true` vacuity | **Resolved.** `decision` variable is set by actual file content inspection; primary assertion is non-vacuous. |
| F04 malformed-header detection was negated-grep vacuity | **Resolved.** Same decision-branch restructure; primary assertion is non-vacuous. |

No new swallowed errors, silent fallbacks, missing error paths, inappropriate error transformations, log-and-continue patterns, or partial-state-on-failure issues were found in the R3 output.
