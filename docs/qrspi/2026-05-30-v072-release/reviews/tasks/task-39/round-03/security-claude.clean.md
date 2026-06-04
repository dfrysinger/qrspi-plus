# Security Review — Task 39, Round 3 (final)

**Reviewer:** security-claude
**Subject:** `tools/build-plugin.mjs`
**Result:** CLEAN — no findings.

## Verification of R2 sec-F01 fix (output-size DoS)

The R2 finding (materialized fan-out blow-up; score 55) is fully addressed:

1. **`MAX_EXPAND_BYTES = 4 * 1024 * 1024`** (line 135) is checked at line 233
   after each `!cat` child expansion is appended within `expand()`. The check
   fires *per directive*, before the next sibling include is processed, so
   the cache entry for any single file cannot exceed ~4 MB plus one child's
   worth of overshoot. Diagnostic includes the file:line, byte counts, and
   the include chain — fail-loud, audit-friendly.

2. **`MAX_INCLUDE_DEPTH = 8`** (line 127), reduced from 16, bounds nesting
   depth at line 194. Combined with the cycle-stack check at line 190, this
   forecloses both direct cycles and non-cyclic deep nesting before the
   byte cap is ever needed for legitimate inputs.

3. **Memoization** (line 200, 245): cache lookup precedes work, cache
   population follows successful expansion. Total materialized work is
   bounded by O(N_files × MAX_EXPAND_BYTES) — well within process memory
   for any plausible repo size.

The cycle check intentionally precedes the cache check (line 190 before
line 200) so a re-entry while the same relpath is on the stack is always
flagged as a true cycle, never short-circuited by a partial cache entry.

## Residual surfaces examined and cleared

- **Plain-text accumulation** (line 242, non-`!cat` lines): skips the byte
  check, but `out` for a non-including file is bounded by the source file's
  on-disk size (`fs.readFileSync` of a trusted repo). Not an attacker-
  controlled sink — build runs over committed source under `--root`.
- **Final-pass scan** (`assertBuildTreeFreeOfLegacyToken`, line 441): reads
  each output file with `utf8`; output `.md` size is bounded by
  `MAX_EXPAND_BYTES`, output non-`.md` size is bounded by source file size.
- **Symlink escape**: `realpathSync` + `startsWith(rootReal + path.sep)`
  guard applied at every entry point (`resolveTarget`, `recurseDir` `.md`
  pre-flight, `copyFilePreservingMode`). Consistent diagnostic phrase.
- **Secret denylist** (line 91): basename-pattern fail-loud catches
  `.env`/`*.pem`/`id_rsa`/backup files even under manifest dirs.
- **`--out` wipe guard** (line 509–520): rejects `outDirAbs === rootReal`
  and rejects any `--out` that is an ancestor of `rootReal`, preventing
  `rmSync(force:true)` from silently destroying the source tree.
- **Manifest allowlist** (line 65–79): explicit; eliminates accidental
  inclusion of contributor-local files outside the allowed subtrees.
- **`${CLAUDE_SKILL_DIR}` post-pass** (line 441): walks the assembled
  build tree and rejects any literal occurrence in `.md` or non-`.md`
  shipped files.

No remaining escalation surface within this task's threat model
(trusted-source build tool; contributor-error and supply-chain-leak
defense-in-depth). R3 final-round review concludes clean.
