# Security Review — Round 3 — CLEAN

**Reviewer:** security-claude  
**Artifact:** tests/unit/test-change-type-partition.bats (R3 delta)  
**Round:** 3  
**Verdict:** CLEAN — no exploitable security vulnerabilities found

---

## Surface reviewed

R3 changed only `tests/unit/test-change-type-partition.bats`.  
Two prior R2 fixes were verified in context:

1. `cp -R` → `cp -RL` (symlink dereference hardening)
2. `FIXTURE_DEST="$(cd "$dest" && pwd -P)" || { return 95; }` + non-empty guard (silent-assignment hardening)

R3 added two new `@test` blocks and updated one comment block.

---

## Findings

None.

---

## Category analysis

### 1. Injection — CLEAN

**`cp -RL` cross-platform behavior (macOS BSD cp vs GNU cp)**  
`-L` is POSIX-specified: both macOS BSD `cp` and GNU `cp` dereference all symlinks
encountered during the recursive walk when `-RL` is used together. A symlinked file
in the fixture source (`$src`) becomes a regular file whose bytes are physically written
inside `$dest`. No behavioral divergence exists between the two implementations for
file-symlink dereference.

Edge case examined and dismissed: a directory symlink forming a cycle under `cp -RL`
would loop indefinitely on either platform. Dismissed because (a) production fixtures
are developer-controlled source-tree directories, not attacker-controlled runtime input;
(b) the synthetic fixture in the new symlink-deref test creates only a single file
symlink (not a directory symlink), which both implementations handle identically.

**`$src` path traversal guard** — present and unchanged (`case "$name" in ''|'.'|'..'|*/*)
…`). The new symlink test passes a path whose basename is `symlink-fixture-round`,
which clears this guard. ✓

### 2. Authentication / Authorization — not applicable (test helper, no auth surface)

### 3. Data Exposure — CLEAN

No sensitive data flows through the test helper or the new tests. The synthetic
"malicious" fixture content (`change_type: malicious`) is inert ASCII written to
`$BATS_TEST_TMPDIR`, which is cleaned up by BATS after each test run.

### 4. Input Validation — CLEAN

**`pwd` shadow — scope cannot bleed to other tests.**  
BATS executes each `@test` block in a dedicated subshell. The `pwd() { return 1; }`
override defined at line 264 is scoped to that subshell and cannot reach any other
`@test` subshell. Belt-and-suspenders: `unset -f pwd` at line 268 executes
*unconditionally and before any assertion that could `return 1` early*, so there is
no code path in which the test exits with `pwd` still overridden in the subshell.

**Override does not affect the fan-in script subprocess.**  
`_run_fan_in_on_fixture` invokes `bash scripts/verifier-fan-in.sh "$dest"` as a
child process. Bash does not export shell functions to child `bash` invocations unless
`export -f` is used. The override fires only for the `"$(cd "$dest" && pwd -P)"`
command substitution that executes within the same shell process — which is the
intended injection point for the hardening test. ✓

**`FIXTURE_DEST` guard form is correct.**  
`FIXTURE_DEST="$(cd "$dest" && pwd -P)" || { return 95; }` — the assignment has no
`local` prefix, so bash propagates the exit status of the command substitution to the
outer `||`. A `cd` failure or `pwd -P` failure (including the override returning 1)
correctly triggers `return 95`. The added `[[ -n "$FIXTURE_DEST" ]]` empty-string
guard (lines 249–250) independently catches the degenerate case where the subshell
exits 0 but produces empty output. ✓

**`|| true` in symlink-deref test is appropriately scoped.**  
`_run_fan_in_on_fixture "$src" || true` — the `|| true` suppresses the helper's exit
code because the test's security assertion is the *post-copy state* (is the entry a
regular file, not a symlink?), not the fan-in script's verdict on a synthetic fixture
that lacks score sidecars. The immediately following `[[ -n "$FIXTURE_DEST" ]]` check
independently guards against the helper failing before setting `FIXTURE_DEST`. ✓

### 5. Dependency Risks — not applicable (no new dependencies)

### 6. Cryptography — not applicable

### 7. Race Conditions — CLEAN

Each `@test` operates on a unique `$BATS_TEST_TMPDIR` subdirectory created by `mktemp -d`
with a random suffix. No shared mutable state exists between tests.

---

## R2 fix verification

| Fix | Verified |
|-----|----------|
| `cp -R` → `cp -RL`: symlink dereference on both BSD and GNU `cp` | ✓ — both platforms dereference file symlinks to regular files; no behavioral gap |
| `FIXTURE_DEST` assignment guarded with `\|\| { return 95; }` | ✓ — non-`local` form propagates exit code; empty-string guard added as defense-in-depth |
| `\|\| true` removed from dup-alt `grep -vE` filter (line ~549) | ✓ — `filter_rc` + `[[ $filter_rc -le 1 ]]` correctly surfaces grep exit ≥2 |
| `pwd` shadow scoped to test subshell, `unset -f pwd` before assertions | ✓ — BATS subshell isolation + unconditional unset; no bleed risk |
