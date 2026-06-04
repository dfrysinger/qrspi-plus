# Test Coverage Review — Task 39, Round 4 (post fix-cycle 3)

**Reviewer:** test-coverage-claude
**Verdict:** CLEAN — no new findings.

## Verification of R3 fix-cycle 3 closures

### tc-F01 — Acceptance fixtures actually invoked through the resolver
`tests/acceptance/v07-phase1/test-phase1-acceptance.bats` lines 3128–3197
add two tests that stage each fixture into a manifest-shaped tmp root and
invoke `node tools/build-plugin.mjs --root … --out …` against it:

- **Legacy `${CLAUDE_SKILL_DIR}` fixture:** copies
  `tests/fixtures/build-resolver/legacy-claude-skill-dir/README.md` into
  `skills/legacy-fixture/SKILL.md`; asserts status≠0 plus three diagnostic
  shape matchers (`CLAUDE_SKILL_DIR` token, `SKILL\.md:[0-9]+` file:line,
  and one of `legacy|shipped|forbidden|occurrence`). Matches the production
  diagnostic emitted by `assertNoClaudeSkillDir` at
  `tools/build-plugin.mjs:257`.
- **Include-cycle fixture:** stages the fixture pair at the bare-relative
  paths the fixture's `!cat` directives expect, plus an entry
  `skills/cycle-fixture/SKILL.md` that hops into `a.md`; asserts status≠0,
  `cycle|circular` keyword, AND that BOTH `a.md` and `b.md` paths appear in
  the output. Matches `expand()`'s `include cycle detected: <stack>`
  diagnostic at `tools/build-plugin.mjs:192`. Full chain
  `SKILL.md → a.md → b.md → a.md` guarantees both file paths print.

Non-vacuous — assertions tie to spec-required diagnostic phrasing and exit
status, not just "ran without crashing".

### tc-F02 — Legacy-path caller search tightened
`tests/acceptance/v07-phase1/test-cache-retirement-invariants.bats:307+`
replaces the broad `grep -RF 'scripts/render-skill.sh'` (which excluded
`docs/`, hiding stale doc callers) with ERE
`(bash[[:space:]]+|\\./)scripts/render-skill\\.sh` and drops the docs
exclusion. The accompanying diff updates three stale doc references under
`docs/qrspi/2026-05-27-v071-hardening/fixes/` from `bash scripts/...` to
`bash tools/...` — exactly the class of false-negative the prior
pattern allowed. Non-vacuous.

Advisory only (not finding-worthy): the regex still won't match `sh
scripts/...`, `source scripts/...`, or unprefixed CI `run:` invocations.
Given the dispatch's audit context and the canonical invocation idioms
in this repo, this is acceptable.

### tc-F03 — SECRET_BASENAME_PATTERNS denylist coverage
`tests/unit/test-build-gate.bats:421+` adds three tests that plant secret
basenames matching three distinct regex branches in three distinct
manifest dirs:

- `skills/sample/.env` (regex `/^\.env(\..+)?$/i`, `recurseDir` nested call)
- `scripts/id_rsa` (regex `/^id_(rsa|…)/i`, different manifest dir)
- `.claude-plugin/server.pem` (regex `/\.(pem|key|p12|pfx)$/i`, manifest
  top-level)

Each asserts (a) non-zero exit, (b) diagnostic contains the offending
relative path, (c) diagnostic contains `denylist|secret|refused`, and
(d) no `build/` artifact for the offender was created. Matches the throw
at `tools/build-plugin.mjs:315–317`. Non-vacuous; covers both
top-level-dir and nested-subtree call sites of `isSecretBasename`.

### tc-F05 — CRLF assertion portability
`tests/unit/test-build-gate.bats:160–168` replaces `grep -U $'\r'` (GNU-only
`-U` flag — on BSD/BusyBox grep this would either fail-as-error or be
silently ignored, making the prior assertion vacuous on non-GNU systems)
with a `wc -c` raw vs `tr -d '\r' | wc -c` byte-count comparison. POSIX
`tr -d '\r'` is portable to bash 3.2 + BSD/GNU/BusyBox. Asserts the actual
byte-level invariant (zero CRs ⇒ equal sizes). Non-vacuous and portable.

## Categories reviewed

1. **Behavioral coverage** — all four targeted spec lines now have at
   least one assertion that ties to observable behavior (exit status +
   diagnostic phrasing + side effects). ✓
2. **Edge cases** — denylist tests cover three orthogonal regex branches
   and two `recurseDir` entry paths; cycle test covers a 3-hop chain
   (entry → a → b → a) which exercises both stack-traversal and
   the `${CLAUDE_SKILL_DIR}` fixture covers a legacy-token leak in a
   non-`!cat`-directive context (token embedded in body prose). ✓
3. **Error conditions** — all new tests target failure paths and assert
   on the diagnostic contract, not just on exit status. ✓
4. **Test quality** — assertions check observable behavior (exit code,
   stderr text, presence/absence of build artifacts), not internal
   implementation details. Test names contain `[T39/G32]` and a short
   purpose tag, so a failure is locatable without reading the body. ✓
5. **Missing scenarios** — none introduced; tc-F04
   (manifest-exclusions / required-missing) was deferred per verifier
   score 45 and is explicitly out of scope per the dispatch.
6. **Test isolation** — every new test stages into `BATS_TEST_TMPDIR`
   under a fresh subdir name and runs a fresh `node tools/build-plugin.mjs`
   subprocess; no shared mutable state, no global state mutated, no order
   dependency. ✓

No new findings.
