# Spec Review — Task 20, Round 6 — CLEAN

Reviewer: spec-claude  
Round: 6  
Diff ref: round-06.diff  
Phase: Test (spec-gate for R5 fix additions)

## Verdict: CLEAN — no findings

### Changes verified

**test-dispatch-sites.bats (6 changes)**

1. **Strengthened full-flag-set test** (line 287): Changed assertion from `[ "$status" -ne 127 ]` (vacuous "not command-not-found") to `[ "$status" -eq 0 ]` (proves every required-flag die() guard was satisfied). Matches task-20.md DoD "loud failure for missing flags" — the positive counterpart that confirms the script exits cleanly when all flags are present.

2. **`--vendor` empty die() guard** (lines 301–315): Omits `--vendor ""`, asserts exit != 0 and stderr contains `"--vendor"`. Directly encodes task-20.md L55 "loud failure for missing flags."

3. **`--model` empty die() guard** (lines 317–331): Same pattern for `--model`. ✓

4. **`--prompt-file` empty die() guard** (lines 333–345): Same pattern for `--prompt-file`. ✓

5. **`--round-dir` empty die() guard** (lines 347–361): Same pattern for `--round-dir`. ✓

6. **`--tag` empty die() guard** (lines 363–377): Same pattern for `--tag`. ✓

**test-dispatch-sites.bats — await stderr-silence strengthening (diff lines 249–271):**

- `run` changed to `run --separate-stderr` to capture channels independently.
- `local await_stderr="$stderr"` captured.
- Added `! [[ "$await_stderr" == *"STUB-REVIEWER-RAW-OUTPUT-MARKER-AAA"* ]]` assertion.
- Directly encodes task-20.md L43/L55 "without echoing payload text to stdout or stderr."

**test-dispatch-agent.bats — multi-reviewer batched dispatch test** (lines 1296–1405):

- Invokes `dispatch-agent.sh` with two `--agents` entries: `quality-claude` (first-party) and `spec-codex` (third-party).
- Asserts exactly one `MODE=first_party TAG=quality-claude` spec line on stdout (task-20.md L42, L54).
- Asserts both tags present as distinct entries in `.dispatch-manifest.json` (task-20.md L43).
- Asserts `TAG=spec-codex` does NOT appear in stdout spec lines (proves third-party routing path).
- Exit status 0 validated via `wrapper_rc`.
- Falsifiability commentary is present and correct.

### Scope compliance

- No production files touched. Test-only diff, as stated in round context.
- All modified files are within the task-20 Target files list (`tests/unit/test-dispatch-sites.bats`, `tests/unit/test-dispatch-agent.bats`).
- No out-of-scope additions detected.

### DoD cross-check

| DoD bullet | Coverage |
|---|---|
| "loud failure for missing flags" (dispatch-companion launch) | 5 die() guard tests (F01 set) ✓ |
| "without echoing payload text to stdout or stderr" (await) | Stderr-silence assertion added (F02) ✓ |
| "emits exactly one first-party spec line per first-party reviewer" | Multi-reviewer batched test (F04) ✓ |
| "appends first-party/background entries to .dispatch-manifest.json" | Manifest two-entry assertion (F04) ✓ |

All R5 fix-cycle gaps closed. No prior assertions regressed.
