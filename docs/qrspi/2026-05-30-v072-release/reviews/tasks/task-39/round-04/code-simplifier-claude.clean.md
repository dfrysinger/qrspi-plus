# Code Simplifier — Clean (round 4)

Task 39, R3 fix-cycle 3, tests-only diff (+138/-12). Reviewed against
the six simplification categories (unnecessary complexity, dead code,
verbose patterns, premature abstraction, inconsistency, readability).

## Walkthrough

- **Doc s/scripts/tools/ touch-ups (3 historical fix-task notes):**
  Mechanical path-correction inside `\`bash …\`` callouts. Nothing
  to simplify.

- **`tests/acceptance/v07-phase1/test-phase1-acceptance.bats` +60
  (two new T39/G32 acceptance tests):** Each stages a manifest-shaped
  source root (`.claude-plugin/plugin.json` + `LICENSE` + `README.md`
  + `skills/<id>/SKILL.md`), copies fixture content into the staged
  tree, runs `node tools/build-plugin.mjs --root … --out …`, and
  asserts non-zero exit plus the spec-required diagnostic phrasing
  (legacy-token name + `file:line` for the `${CLAUDE_SKILL_DIR}`
  case; cycle/circular keyword + both chain endpoints for the
  include-cycle case). The header comment block (L82-95) explicitly
  justifies why staging is necessary — the bare fixture dirs are not
  manifest-shaped, and `--root` requires manifest shape. That is
  load-bearing context, not over-explanation. No simplification.

- **`tests/unit/test-build-gate.bats` CRLF check (L160-168):**
  Replaces `grep -U $'\r'` (GNU-only flag, vacuously passes on
  BSD/BusyBox grep) with a `wc -c` size-diff via `tr -d '\r'`. A
  terser portable alternative (`! grep -q $'\r' "$built"`) exists,
  but the size-diff form is unambiguous and the inline comment cites
  the portability rationale. Not a finding — readability is at least
  equal, and the explicit form telegraphs the invariant ("byte count
  unchanged after stripping CR" ≡ "no CR bytes present").

- **`tests/unit/test-build-gate.bats` +45 (three denylist coverage
  tests):** `.env` under `skills/sample/`, `id_rsa` under `scripts/`,
  `*.pem` under `.claude-plugin/`. Each test follows the same
  6-line skeleton: stage clean root → plant offending basename with
  realistic-looking content → run build → assert non-zero + path
  appears in diagnostic + denylist/secret/refused keyword present +
  no `build/` artifact emitted. A `_t39_assert_denylist_rejects
  <subdir> <filename> <content>` helper would deduplicate to roughly
  3 lines per test, but each test's inline form keeps the planted
  basename, the subtree it lives in, and the content payload
  immediately visible at the assertion site — exactly the audit
  surface a denylist test exists to advertise. Hiding those bytes
  behind a helper would make the tests *harder* to read for a
  security reviewer scanning for "what basenames are we covering and
  in which subtrees?". The bounded triplication is the correct call.

## Out-of-scope acknowledgement

cs-F01 (canonicalUnderRoot triplication, prior verifier score 42 =
DEFER across multiple rounds) was explicitly excluded by dispatch and
is not re-raised here.

## Verdict

No findings.
