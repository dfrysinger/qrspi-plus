# Spec Review — Task 11 Round 8 — CLEAN

**Reviewer:** spec-claude  
**Round:** 8  
**Commit:** 7a51582  
**Verdict:** CLEAN — no findings

## Verification

### FIX-O (run-codex-review.sh lines 922–935): trap split + pre-mktemp install

All five sub-requirements verified against file content:

1. **3 separate traps installed BEFORE mktemp** — trap installs at lines 928–930;
   `mktemp` call at line 931. Ordering confirmed. ✅
2. **EXIT trap is pure cleanup (no exit call)** —
   `trap 'rm -f "$_fp_tmp" 2>/dev/null || true' EXIT` at line 928.
   No `exit` call; fires on normal completion without clobbering exit code. ✅
3. **INT trap exits 130** —
   `trap 'rm -f "$_fp_tmp" 2>/dev/null || true; exit 130' INT` at line 929. ✅
4. **TERM trap exits 143** —
   `trap 'rm -f "$_fp_tmp" 2>/dev/null || true; exit 143' TERM` at line 930. ✅
5. **`trap - EXIT INT TERM` in mktemp-failure branch** — line 932 inside
   `if ! _fp_tmp="$(mktemp ...)"` guard. ✅

Pattern mirrors `_manifest_tmp` at lines 288–290 exactly (EXIT pure-cleanup,
INT+130, TERM+143). The only structural difference (`_fp_tmp` EXIT trap omits
`rmdir`) is correct: no lock directory exists in the first-party prompt path.

### FIX-P (bats): trap-presence test updated + new ordering test

1. **Existing `"first-party prompt tmpfile has signal-cleanup trap on EXIT/INT/TERM"`
   test (lines 2816–2831)** — single combined-trap assertion replaced with three
   separate `grep -q` verbatim checks for the EXIT, INT (exit 130), and TERM
   (exit 143) trap lines. ✅
2. **New `"_fp_tmp trap is installed before mktemp"` test (lines 2861–2874)** — added
   as a standalone `@test` block; extracts `trap_line` and `mktemp_line` via
   `grep -n`, asserts `trap_line < mktemp_line`. Grep patterns are correct:
   `trap '.*rm -f.*\$_fp_tmp` (BRE, `$` in the middle is literal) will hit the
   EXIT trap at line 928; `mktemp "${_fp_prompt_file}.tmp` will hit line 931.
   Assertion `928 < 931` passes. ✅

### FIX-Q (bats line 2846): dead grep filter corrected

Old: `grep -v '^\s*#'` — matched raw content without the `linenum:` prefix
emitted by `grep -n`, so comment lines with leading digits were not filtered.

New: `grep -vE '^[0-9]+:[[:space:]]*#'` — correctly strips lines whose
`grep -n` prefix is followed by optional whitespace then `#`. ✅

### G3 / CD-1 schema drift

Diff touches only:
- `scripts/run-codex-review.sh` lines 920–935: exclusively `_fp_tmp` trap block.
  No changes to manifest fields (`subagent_type`, `host`, `vendor`, `model`,
  `prompt_file`), `emit_first_party_manifest_entry`, or the third-party path.
- `tests/acceptance/v07-phase1/test-phase1-acceptance.bats` end-of-file region:
  exclusively `_fp_tmp` / `_manifest_tmp` trap tests. No G3/CD-1 schema tests
  removed or altered.

No G3/CD-1 manifest provenance or schema behavior changed, removed, or
regressed. ✅

### Scope — out-of-spec additions

None. Diff is tightly scoped to the three named fixes. No new files, no new
configuration options, no extra helpers introduced. ✅
