# Silent Failure Hunter — Task 39, Round 4 (fix-cycle 3, tests-only)

**Verdict:** clean — no silent-failure issues found in the round-04 diff.

## Surface reviewed

Round-04 is a tests-only diff (+138/-12) addressing R3 fix-cycle 3:

- `tests/acceptance/v07-phase1/test-cache-retirement-invariants.bats` — two
  tightened greps for stale `scripts/render-skill.sh` /
  `scripts/g4-section-anchor-refresh.sh` references
- `tests/acceptance/v07-phase1/test-phase1-acceptance.bats` — two new
  fixture-driven acceptance tests (legacy `${CLAUDE_SKILL_DIR}` rejection;
  include-cycle rejection with full chain printed)
- `tests/unit/test-build-gate.bats` — CRLF-stripping assertion rewrite +
  three new denylist coverage tests (.env, id_rsa, *.pem)
- Three doc-only path corrections in v0.7.1 fix notes (prose, no executable
  surface)

## What I traced

For every new or modified assertion I traced the assertion against:

1. The actual `BuildError` strings emitted by `tools/build-plugin.mjs`
   (`resolveTarget`, `expand`, `recurseDir`, `assertNoClaudeSkillDir`,
   `isSecretBasename` / `SECRET_BASENAME_PATTERNS`).
2. The fixture content under `tests/fixtures/build-resolver/`
   (`legacy-claude-skill-dir/README.md`, `include-cycle/{a,b}.md`).
3. Walk order through `MANIFEST_DIRS` (skills → agents → scripts →
   templates → .claude-plugin) plus alphabetical `entries.sort` inside
   `recurseDir`, to confirm denylist throws fire before any copy of the
   offending file.
4. Bats per-command exit-status semantics (every non-`run`-prefixed
   command in `@test` body fails the test on non-zero exit) to confirm
   chained `echo "$output" | grep …` assertions are load-bearing.

## Specific silent-failure shapes the round *closes*

- **`grep -U $'\r'` vacuous pass (R3 tc-F05):** Prior CRLF assertion used
  GNU-only `-U`; on BSD/BusyBox grep the unknown option produced a
  non-zero exit before any pattern match, satisfying the
  `[ "$status" -ne 0 ]` assertion *without ever inspecting the file*.
  Replacement (`wc -c` vs `tr -d '\r' | wc -c` size equality) is
  portable across bash 3.2 + BSD/GNU/BusyBox and cannot pass vacuously.
- **Existence-only fixture tests (R3 tc-F01):** Prior tests merely
  asserted the legacy-token / cycle fixtures sat on disk; they never
  invoked the resolver against them and never verified the spec-required
  diagnostic phrasing. New tests stage each fixture's content into a
  minimal manifest-shaped source root, actually run
  `node tools/build-plugin.mjs --root <staged>`, and assert
  `status -ne 0` plus three independent grep pins on the diagnostic
  (token/keyword + `<file>:<lineno>` for the legacy case; cycle keyword
  + both cycle-member paths for the cycle case).
- **`--exclude-dir=docs` blind spot (R3 tc-F02):** Prior stale-caller
  greps excluded `docs/`, allowing today's-workflow docs to point at
  retired `scripts/` paths undetected. Round-04 drops that exclusion AND
  tightens the pattern to invocation forms (`bash <path>` or
  `./<path>`), so historical narrative no longer false-positives but
  actual stale callers do.
- **Denylist coverage gap (R3 tc-F03):** No prior unit test exercised
  `SECRET_BASENAME_PATTERNS`. New tests cover all three call-site
  shapes through which `isSecretBasename` fires (nested manifest dir,
  manifest-dir top level, dotfile basename) and each asserts (a) build
  fails non-zero, (b) diagnostic names the offending path, (c)
  diagnostic carries denylist/secret/refused keyword, (d) no build/
  artifact exists at the offending path.

## Residual surface checked, judged acceptable

- The `grep -E -i 'legacy|shipped|forbidden|occurrence'` keyword set is a
  loose union — a future diagnostic regression that drops one but
  retains another would still satisfy the test. The diff comments
  acknowledge this as a deliberate fuzz tolerance against benign
  rephrasings, and at least one keyword anchor is preserved. Acceptable.
- The CRLF assertion verifies absence of CR bytes but does not
  re-verify that the included content was actually inlined. The
  inlining-presence pin is covered by the separate "directive line is
  replaced 1:1 with include content" test elsewhere in the same file,
  so the orthogonal split is sound.
- `[ ! -e "$root/build/<offending>" ]` denylist final assertions are
  partially redundant given `recurseDir` throws before any file copy,
  but they act as defense-in-depth pins against a future refactor that
  switches to copy-then-validate semantics.

No findings to emit.
