# Spec Reviewer (claude) — Task 39, Round 2: CLEAN

No spec-deviation findings. Gate PASS.

## Verification summary

Reviewed against `tasks/task-39.md` Definition of done + Test expectations,
focused on R2 fix-cycle scope (6 KEPT findings) plus spec-drift sweep.

### R2 fixes — all correctly addressed

1. **sec-F01 / sec-F02 (secret denylist + final legacy-token pass over all
   shipped files + --out wipe guard)**
   - `SECRET_BASENAME_PATTERNS` (build-plugin.mjs:91–101) covers `.env*`,
     `.envrc`, `.npmrc`, `.netrc`, `id_rsa/dsa/ecdsa/ed25519(.pub)`,
     `credentials*`, `*.pem|key|p12|pfx`, `*.bak|orig|rej|swp|swo`, `*~`.
     Enforced both during walk (recurseDir:297–301) and on top-level
     manifest files (copyManifest:402–406) — fail-loud, not silent skip.
   - `assertBuildTreeFreeOfLegacyToken` (build-plugin.mjs:424–441) walks
     the assembled `build/` tree post-copy and scans every file (.md OR
     non-.md) for `${CLAUDE_SKILL_DIR}`. Closes the prior gap where
     non-.md shipped files (shell scripts, JSON, templates) bypassed the
     scan. Test pin at test-build-gate.bats:328–339.
   - `--out` guard (build-plugin.mjs:492–503) rejects `--out == rootReal`
     AND `--out` ancestor-of-rootReal BEFORE the rmSync at line 520.
     Two test pins (test-build-gate.bats:295–320) verify a CANARY file
     at the source root survives the failed run, proving rmSync was not
     reached. Aligns with DoD's reproducibility intent without enabling
     the silent-source-wipe failure mode.

2. **sf-F01 (ENOENT → BuildError everywhere)**
   - resolveTarget (build-plugin.mjs:151–157), copyFilePreservingMode
     (251–254), recurseDir stat (310–317), copyManifest dir/file stat
     (361–369, 386–394) all catch ENOENT and re-throw as BuildError with
     a file:line/relpath-prefixed message. Non-ENOENT errors propagate
     unchanged (correct: those are programmer errors, not user input).

3. **sf-F02 (depth cap)**
   - `MAX_INCLUDE_DEPTH = 16` (build-plugin.mjs:126), enforced in
     `expand` (185–190) BEFORE the cache check, with full chain printed
     in the diagnostic. Test pin at test-build-gate.bats:346–362
     constructs a 24-level linear chain and asserts non-zero exit with
     a `depth|too deep|nesting` diagnostic. Defends against billion-
     laughs diamond DoS that the cycle-stack alone wouldn't catch.

4. **sf-F03 (subtractive → additive walk)**
   - `MANIFEST_DIRS` + `MANIFEST_FILES` (build-plugin.mjs:65–79) replace
     the prior walk-and-strip strategy with an explicit allowlist.
     Anything not listed is implicitly excluded — eliminates the
     contributor-worktree leak class (.env, *.bak, etc.) by construction.
     `MANIFEST_PATH_EXCLUSIONS` (83–85) excludes
     `.claude-plugin/marketplace.json` from being shipped inside
     `build/.claude-plugin/` (correct: marketplace.json is the registry
     pointing AT `./build`, shipping it inside would self-reference).
   - Required vs optional flag (66–79) lets the manifest fail-loud when
     `skills/` or `.claude-plugin/` are missing while tolerating absent
     optional `agents/`, `templates/`, `AGENTS.md`, etc.

### cq-F02 deferral (score 45) — accepted

Code-quality finding deferred per the documented score threshold. Not a
spec-deviation issue, not a gate concern.

### Spec-drift sweep — no new drift introduced in R2

- DoD bullets 1–11 still satisfied. The additive walk preserves the
  "Copy runtime plugin content … omitting dev-only paths" contract via
  a stronger mechanism (allowlist vs denylist) without changing the
  shipped surface. The implementer's report claims `build/` tree is
  byte-unchanged, consistent with the manifest covering exactly what
  the prior subtractive walk produced.
- Symlink-escape DoD bullet (line 56 of task-39.md) still enforced via
  `fs.realpathSync` + canonical-prefix check in resolveTarget (148–166),
  copyFilePreservingMode (250–264), and the .md pre-flight in recurseDir
  (328–344). Test pin at test-build-gate.bats:262–277 still asserts the
  required `resolves outside repository` diagnostic phrase.
- `${CLAUDE_SKILL_DIR}` rejection now strictly stronger: per-.md scan
  during expansion (assertNoClaudeSkillDir at 347, 411) PLUS the
  post-copy whole-tree pass (528). DoD line 50 explicitly requires
  shipped-file zero occurrences — the post-copy pass is the audit-
  friendly version of that requirement.
- CI workflow (ci.yml:119–133) unchanged in R2 scope and still encodes
  the build → diff-gate sequence with no auto-commit step. Lint job
  walks `tests/` recursively (line 39) per Slice 1.7.

### Target-files deviation (advisory)

Diff modifies `tools/build-plugin.mjs`, `.github/workflows/ci.yml`,
`tests/unit/test-build-gate.bats` — all on the Target files list. No
out-of-scope edits.

### Test-coverage trace

Every R2 fix carries a corresponding test pin in
`test-build-gate.bats`:

| Fix | Test pin |
|---|---|
| sec-F01 secret denylist (non-.md token) | 328–339 |
| sec-F02 --out == root guard | 295–307 |
| sec-F02 --out ancestor-of-root guard | 309–320 |
| sf-F02 depth cap | 346–362 |
| sf-F03 manifest-driven | implicit via happy-path 93–101 + non-.md scan 328–339 |
| sf-F01 ENOENT → BuildError | implicit via missing-target test 203–210 |

24/24 build-gate suite green per implementer report; spot-checked the
test bodies against the resolver behavior — assertions match claims.

## Verdict

**PASS.** Spec gate clears. Other reviewers (security, code-quality,
sleeper-feature) may run.
