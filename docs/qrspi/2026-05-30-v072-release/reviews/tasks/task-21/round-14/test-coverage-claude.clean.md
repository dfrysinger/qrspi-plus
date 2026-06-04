# Test Coverage Review — Task 21, Round 14 (test-coverage-claude)

**Verdict:** CLEAN

## Scope reviewed

- Diff: `round-14.diff` (67 lines, test-only)
- Two new bats tests added to `tests/unit/test-dispatch-agent.bats`:
  1. `sibling-directory masquerade: path starting with REPO_ROOT-as-string-prefix is rejected` (lines 1660–1679)
  2. `companion launch: out-of-repo --prompt-file rejected with 'resolves outside repository'` (lines 2081–2105)
- Production code unchanged from R12 (40fe6de) → fix-cycle 13 (843c951).

## Findings closed this round

### tc-claude R13-F01 (sibling-directory masquerade) — CLOSED

The new test creates `${REPO_ROOT}-evil-XXXXXX` via `mktemp -d`, producing a
sibling directory whose absolute path is a *textual* prefix of `$REPO_ROOT`
but lies outside it. This is precisely the case a naive `$path == $repo_root*`
check would falsely accept and the trailing-slash anchor in `path-guard.sh:142`
correctly rejects. Assertions:

- `[ "$status" -ne 0 ]` — guard must exit non-zero.
- `[[ "$output" =~ "resolves outside repository" ]]` — canonical diagnostic.

The header comment correctly notes that the existing 14 path-filter tests do
not cover this case because their OOR fixtures live under `$TMPDIR` (textually
disjoint from `$REPO_ROOT`). A future simplification dropping the trailing-slash
anchor would now fail loudly here.

### tc-codex R13-F01 (out-of-repo `--prompt-file` behavioral test) — CLOSED

The new test passes an OOR `--prompt-file` while keeping `--round-dir` inside
the repo so the prompt-file check is the one that fires. This properly
isolates the boundary under test from the round-dir boundary check (which
already has its own behavioral test). Assertions:

- `[ "$status" -ne 0 ]`
- `[[ "$output" =~ "resolves outside repository" ]]`

Together with the pre-existing structural audit test, the prompt-file boundary
is now pinned both structurally and behaviorally.

## Coverage analysis

- **Behavioral coverage:** Both new tests assert observable behavior (exit
  status + stderr diagnostic), not implementation details.
- **Edge cases:** Sibling-prefix masquerade is a meaningful boundary case the
  prior suite missed.
- **Error conditions:** Both exercise rejection paths through the canonical
  diagnostic.
- **Test quality:** No vacuous assertions; descriptive names; comments
  explicitly call out the regression each test prevents.
- **Test isolation:** Unique `mktemp -d` fixtures per test; `rm -rf` cleanup
  scoped to the fixture; no shared mutable state; no order dependencies.
- **Missing scenarios:** None introduced this round.

## v0.7.3 deferrals honored

- sf-codex R11 F01 (`set -e` propagation) — not tested here, correct.
- cs R13 four simplifications — production code unchanged, correct.

No findings.
