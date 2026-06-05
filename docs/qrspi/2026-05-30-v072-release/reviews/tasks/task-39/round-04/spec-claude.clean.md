# Spec Review — Task 39 Round 4 (Claude)

**Verdict:** clean — no spec-fidelity findings.

## Scope of this round

R4 diff is +138/−12 across 6 files (no production changes; tests + 3
doc-reference path bumps under `docs/qrspi/2026-05-27-v071-hardening/...`).
Production resolver `tools/build-plugin.mjs` is unchanged from R3, build/
tree byte-identical. Verification focused on whether the four R3 KEPT
test-coverage findings (tc-F01/F02/F03/F05) were closed without
introducing new spec deviations.

## Verification

### tc-F01 — acceptance fixtures actually exercise resolver + diagnostics

Task spec line 70 demands: "Acceptance fixtures cover a legacy
`${CLAUDE_SKILL_DIR}` directive failure and a deliberate include-cycle
failure with the required diagnostics."

Two new tests appended to
`tests/acceptance/v07-phase1/test-phase1-acceptance.bats` (lines 3128–
3198 of the post-diff file) stage each fixture's content into a minimal
manifest-shaped source root and actually invoke
`node tools/build-plugin.mjs --root … --out …`, asserting:

- non-zero exit,
- the load-bearing diagnostic keyword (`CLAUDE_SKILL_DIR` or
  `cycle|circular`),
- file:line locator (`SKILL\.md:[0-9]+`),
- and — for cycle — that BOTH ends of the chain appear (full cycle
  printed, per DoD line 49 / 64).

Cross-checked against the production resolver's actual diagnostic
strings:

- `tools/build-plugin.mjs:257` emits
  `${relPath}:${lineNo}: ${CLAUDE_SKILL_DIR} occurrence in shipped file
  (legacy form forbidden in v0.7.2 — convert to bare-relative !cat)` —
  satisfies `grep -F 'CLAUDE_SKILL_DIR'`,
  `grep -E 'SKILL\.md:[0-9]+'`, and
  `grep -E -i 'legacy|shipped|forbidden|occurrence'`.
- `tools/build-plugin.mjs:192` emits
  `include cycle detected: <a> -> <b> -> <a>` — satisfies
  `grep -E -i 'cycle|circular'` plus the `grep -F` of both file paths.

The tests exercise behavior, not mere existence. Closes tc-F01.

### tc-F02 — caller-reference greps tightened

The two `[T39/G32] no remaining caller references to scripts/...` tests
in `tests/acceptance/v07-phase1/test-cache-retirement-invariants.bats`
moved from `grep -RF` (substring, with `--exclude-dir=docs` whitelisting
all docs) to `grep -RnE '(bash[[:space:]]+|\./)scripts/<helper>\.sh'`
(invocation forms only) and dropped `--exclude-dir=docs`. This means:
narrative bare-path mentions in historical docs no longer false-positive,
but a doc that still tells contributors `bash scripts/render-skill.sh`
WILL fail. The R4 diff also bumps the three remaining live doc
invocations (in `v071-hardening/fixes/...`) to `bash tools/...` so the
tightened gate passes. Aligned with DoD lines 51 and 66 ("callers/docs
are updated"). Closes tc-F02.

### tc-F03 — denylist coverage

Three new tests appended to `tests/unit/test-build-gate.bats` plant
`.env` under `skills/sample/`, `id_rsa` under `scripts/`, and `*.pem`
under `.claude-plugin/`, then assert non-zero exit, the offending file
path appears in stderr, the diagnostic matches
`denylist|secret|refused`, and no `build/` artifact for the offending
path was written. Cross-checked against
`tools/build-plugin.mjs:315–317` which emits
`${rel}: refused — basename matches secret/backup denylist (...)`.
Both `recurseDir` call paths fire — denylist fires before any copy.
The fixture roots created by `_t39_stage_root` already include `scripts/`
and `.claude-plugin/` so the planted files land under walked manifest
dirs. Closes tc-F03.

### tc-F05 — portable CR-stripping assertion

`grep -U $'\r'` (GNU-only `-U` flag) was replaced with a portable
size-diff assertion: `wc -c <built` vs `wc -c <(tr -d '\r' <built)`.
Both byte-counts equal ⇒ no CR present. Portable across bash 3.2 + BSD/
GNU/BusyBox per the in-test rationale comment. Closes tc-F05.

## Spec-fidelity checks

- **Completeness:** the four KEPT findings each map to a concrete
  closure in this diff; no DoD bullet regressed.
- **Scope:** test additions trace 1:1 to "Test expectations" lines 70
  (fixtures), 64 (cycle diagnostics), and 48 (CR-stripping). Doc path
  bumps are explicit DoD targets ("update callers/docs/references",
  line 51). No out-of-scope additions observed.
- **Interpretation:** the staged-root pattern in the acceptance tests
  is non-obvious but justified inline (fixture dirs intentionally lack
  manifest shape; staging exercises the documented `--root` CLI
  surface) — and matches the resolver's actual operating contract.
- **Test coverage:** all four targeted findings now have assertions
  that fail meaningfully if the production behavior regresses.
- **TDD evidence:** task is in fix-cycle mode against an already-merged
  TDD-evidenced production implementation; no new production code in
  this round, so the round is intrinsically test-leading.
- **Extra features:** none.
- **Target files (advisory):** all six edited files are within the
  task spec's Target files list (line 14: tests/unit/test-build-gate.bats,
  tests/acceptance/v07-phase1/test-cache-retirement-invariants.bats,
  tests/acceptance/v07-phase1/test-phase1-acceptance.bats, plus the
  "existing callers/references" clause covering the three v071-hardening
  doc bumps).

## Note on R3 deferrals (not part of this round's verdict)

cs-F01 (DRY canonicalUnderRoot, score 42) and tc-F04 (manifest-
exclusions test, score 45) remain deferred per orchestrator decision;
neither is a DoD bullet, so their deferral does not affect spec
fidelity.

No findings.
