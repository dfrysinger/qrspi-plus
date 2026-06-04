---
finding_id: F01
reviewer_tag: test-coverage-claude
round: 13
task: 21
artifact: tests/unit/test-dispatch-agent.bats
severity: low
change_type: test-only
status: open
---

# F01 — No regression test for trailing-slash-anchored prefix matcher (sibling-directory masquerade vector)

## Where
- `scripts/lib/path-guard.sh:140-149` — implementation of the trailing-slash-anchored prefix match.
- `tests/unit/test-dispatch-agent.bats` — Path-filter section (L1525–1898) has no test exercising the sibling-directory masquerade.

## What is missing
The `assert_path_under_repo_root` matcher uses a trailing-slash anchor specifically so that `$REPO_ROOT=/repo` does NOT match a path resolving to `/repo-evil/secrets`:

```bash
case "$canon/" in
  "$canon_root"/*) : ;;
  *) ... ;;
esac
```

The implementation comment at `path-guard.sh:140` calls this out as a deliberate hardening:
> Trailing-slash-anchored prefix match: `/repo/` must be a strict ancestor of `/repo/foo`, but not of `/repo-evil/foo`.

This is the canonical "sibling-directory masquerade" attack: an attacker who can create a directory whose name is a string-prefix of the canonical repo root (e.g. `/Users/.../qrspi-plus-v0.7.2-evil/` next to `/Users/.../qrspi-plus-v0.7.2/`) can place readable files there. A naïve `case "$canon" in "$canon_root"*) :` (no trailing slash) would let those paths through.

The 14-test path-filter battery only covers paths that lie in `${TMPDIR:-/tmp}/...` (clearly disjoint from the canonical repo root) and a `/etc/hosts` smoke. There is **no** test that creates a sibling directory whose pathname shares a textual prefix with `$REPO_ROOT` and confirms it is rejected.

## Why the gap is non-vacuous (falsifiability)
If a future simplification rewrote the case arm as `"$canon_root"*)`, every existing path-filter test would still pass:
- `/etc/hosts` does not start with `$REPO_ROOT` regardless of trailing-slash anchoring.
- `${TMPDIR}/bats-pguard-oor.XXXXXX/...` does not start with `$REPO_ROOT` regardless.
- The symlink test (L1636) uses `$OUT_OF_REPO_TMP` which is already in `${TMPDIR}`.

A regression test pinning the `/repo-evil/` masquerade specifically would falsify any simplification that drops the trailing-slash anchor.

## Suggested test (≈10 lines)
```bash
@test "sibling-directory masquerade: path starting with REPO_ROOT-as-string-prefix is rejected" {
  # Falsifies a 'simplification' that drops the trailing-slash anchor in
  # path-guard.sh:142. /repo-evil/foo lexically starts with /repo but
  # canonically is NOT under /repo/.
  local sibling
  sibling="$(mktemp -d "${REPO_ROOT}-evil-XXXXXX")"
  echo "secret" > "$sibling/oor-subject.ts"
  run "$WRAPPER" \
    --agent-file "$REPO_ROOT/agents/qrspi-spec-reviewer.md" \
    --reviewer-tag spec-codex \
    --output-dir /tmp/out --round 1 \
    --subject-code "$sibling/oor-subject.ts" \
    --dry-run
  rm -rf "$sibling"
  [ "$status" -ne 0 ]
  [[ "$output" =~ "resolves outside repository" ]]
}
```

(`mktemp -d "${REPO_ROOT}-evil-XXXXXX"` creates the sibling alongside the worktree root — outside the repo but textually prefixed by it.)

## Severity rationale
Low. The implementation is correct as written and the hardening is documented in-source. The gap is purely test-coverage: a future refactor that drops the trailing-slash anchor would break exfil hardening with no test to catch it. Not a correctness defect in this round.

## Out-of-scope (not reflagged)
- v0.7.3 deferral: sf-codex R11 F01 set-e discipline (v072-issues.md).
- Broader all-`scripts/` exfil sweeps beyond the dispatch entry points (task-21.md Out-of-Scope; design.md G16 v0.7.3 open question).
