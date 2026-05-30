# T6 — TERMINAL CLEAN

**Head SHA:** 600232f
**Tests:** 1244/1244 (full repo suite, 0 skipped on dfrysinger MacBook Air)
**Final round:** R13 (narrow-verify of R12 fix; both gt + tc returned NO-FINDINGS)

## Round chain summary

- R1–R7: spec-gate + correctness fan-out for sec/cq/sf findings + fix cycles
- R8: sec narrow-verify → sec.F01 (78) KEEP (printf fallback re-opens R6 vectors), sec.F02 (25) DROP
- R9: fix-cycle commit 7fa34d6 — fail-closed `_gh_path=""` on realpath/readlink-f fallback (replaces printf '%s' fallback)
- R10: sec narrow-verify → NO-FINDINGS (chat-only fallback; sentinel written manually)
- R11: thoroughness fan-out (gt + tc + cs) → 5 KEEP (3 same root: TE1/TE14 env-dependent), 3 DROP, 2 cs advisory
- R12: fix-cycle commit 600232f — TE1/TE14 skip-guards (4 tests via `_have_trusted_gh`) + `[r12-tc.F03]` HOME-newline rejection + `[r12-tc.F04]` `_codex_reviews` injection sanitization
- R13: narrow-verify → both gt + tc NO-FINDINGS

## Defense-in-depth verification (R12 tc.F04)

- Single mutation (disabling `case` statement OR loosening `[[ == "true" ]]`) → test stays GREEN (strict comparison still blocks `true; echo INJECTED`)
- Compound mutation (case disabled AND comparison loosened to `!= ""`) → test goes RED → "INJECTED" found in stderr
- Sanitization is correctly characterized as second-line defense

## Skip-guard portability note

On dfrysinger's macOS (Homebrew `gh` at `/opt/homebrew/bin/gh` matching `/opt/*` trusted prefix), 0/1244 tests skip. Skip-guards activate only on hosts where `gh` is not in a trusted prefix.
