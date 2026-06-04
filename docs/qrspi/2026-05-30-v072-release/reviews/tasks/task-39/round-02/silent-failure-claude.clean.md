# Silent-Failure Hunter — Task 39 Round 2 — CLEAN

Reviewer: silent-failure-claude
Round: 2
Subjects:
- tools/build-plugin.mjs
- .github/workflows/ci.yml

## R1 fix verification

- **sf-F01 (non-md `${CLAUDE_SKILL_DIR}` scan):** Closed. `assertBuildTreeFreeOfLegacyToken` (build-plugin.mjs:424-441) recursively walks the assembled `build/` tree and runs `assertNoClaudeSkillDir` against every regular file, .md and non-.md alike. utf8-decoding binary content yields harmless garble for a literal-token `indexOf`.
- **sf-F02 (`rootReal` rmSync wipe):** Closed. Guards at build-plugin.mjs:492-503 reject `outDirAbs === rootReal` and any `--out` that is an ancestor of `rootReal`, BEFORE `fs.rmSync(..., {force:true})` runs. `canonicalizeMaybeMissing` (463-485) realpaths the existing prefix so symlinked `--out` (e.g. macOS `/tmp` → `/private/tmp`) compares correctly.
- **sf-F03 (ENOENT silent skip):** Closed. Every ENOENT site in `resolveTarget`, `copyFilePreservingMode`, `recurseDir` (readdir + stat), the pre-flight .md realpath, and required-manifest entry checks throws `BuildError` with file:line + reason. Optional-manifest ENOENT continues by design (`required: false`).

## New-surface review (manifest-driven walk + depth-cap memoization)

- `recurseDir` dispatches on `fs.statSync` (follows symlinks); broken-symlink ENOENT is fail-loud. `MANIFEST_PATH_EXCLUSIONS` and `SECRET_BASENAME_PATTERNS` are checked at every recursion level — denylist hits raise `BuildError` rather than silently skipping.
- `.md` files get a pre-flight realpath/outside-root check (build-plugin.mjs:328-344) before `expand()` reads bytes, mirroring the `copyFilePreservingMode` canonicalization for non-.md.
- `expand()` orders cycle-check → depth-check → cache-check (181, 185, 191). Cache is populated only after full expansion (228), so re-entry while a file is on `stack` is unambiguously a cycle. Depth cap gates even cached returns, defending diamond-fan-in DoS without false positives.
- Sort in `recurseDir` (293) is byte-lexicographic — locale-independent and reproducible.
- CI build-sync gate: `node tools/build-plugin.mjs` then `git diff --exit-code build/ .claude-plugin/marketplace.json` — both steps propagate non-zero exits, no `|| true`, no auto-commit, recursive `bats -r tests` covers the suite.

## Categories swept

1. Swallowed errors — none. All `try/catch` blocks rethrow as `BuildError` or rethrow the original.
2. Silent fallbacks — none. No `|| []`, no `??` past required fields, no empty-array success substitutions.
3. Missing error paths — none new. Every fs operation has explicit ENOENT handling; main() wraps `copyManifest` + final-pass token scan in a `BuildError` translator that exits non-zero.
4. Inappropriate error transformation — none. `BuildError` messages preserve `file:line: reason` shape; non-BuildError exceptions propagate untouched.
5. Log-and-continue — none. `process.stderr.write` paths are paired with `process.exit(1|2)`.
6. Partial state on failure — `rmSync` + `mkdirSync` happens AFTER the wipe-safety guards, so a fail-loud during `copyManifest` leaves a partially-populated `build/` (acceptable: next invocation wipes it; the `git diff --exit-code` gate would still flag the divergence).

No findings.
