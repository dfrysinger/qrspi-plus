---
finding_id: F01
reviewer: silent-failure-claude
task: 13
round: 4
severity: medium
category: missing-error-path / silent-fallback
location: scripts/round-prepare.sh:141, 154-160
---

## Round-1 non-advance check silently no-ops when `--base-ref` cannot be resolved

The Definition of Done requires: "Round-one non-advance detection compares against
the task base commit and names that base condition in the diagnostic." That check
(exit 12) is implemented at lines 154–160, but it is silently disabled whenever the
task-base SHA cannot be resolved.

Trace:

- Line 135–142: `TASK_BASE_SHA` is captured with a swallowed failure —
  `TASK_BASE_SHA="$(git -C "${WORKTREE:-.}" rev-parse "$BASE_REF" 2>/dev/null || true)"`.
  If `$BASE_REF` does not resolve (wrong/stale ref, detached worktree, ref typo),
  or if `--base-ref` is omitted entirely (it is an optional flag — line 52/60),
  `TASK_BASE_SHA` becomes the empty string with no diagnostic.
- Line 153–156: on round 1, `PRIOR="$TASK_BASE_SHA"` (so `PRIOR=""`).
- Line 157: `if [ -n "$PRIOR" ] && [ "$IMPLEMENTER_COMMIT" = "$PRIOR" ]` — the
  `[ -n "$PRIOR" ]` guard is false, so the exit-12 branch is skipped entirely.

Consequence: on round 1, if the implementer reports DONE without committing (HEAD
still at the task base) AND the base ref happens to be unresolvable/absent, the
script does **not** fire exit 12. It silently proceeds to write the round-1 commit
anchor (line 228) and emit the diff. The documented belt-and-suspenders round-1
non-advance backstop becomes a no-op precisely in the failure mode (base ref
problems / orchestrator path drift) where it is most needed.

Compounding effect (line 377–381): the same unresolvable `$REF` then flows into
`git diff "$REF" -- > "$DIFF_TMP" 2>/dev/null || true`. A failed `git diff` is
swallowed, `mv` succeeds, and an **empty** `round-NN.diff` is published with
exit 0 — reviewers consume it as "no changes this round," masking the bad ref a
second time.

Ask answered: if the base ref fails to resolve, no one knows — the round prepares
"successfully" with a skipped advance check and possibly an empty diff.

Suggested fix: when `PER_TASK -eq 1` and `$BASE_REF` is non-empty but
`TASK_BASE_SHA` came back empty, fail loud (exit 1 or a dedicated code) with a
diagnostic naming the unresolvable base ref, rather than letting `|| true` drop it
and the `-n "$PRIOR"` guard silently skip the round-1 check. Optionally require
`--base-ref` for per-task round 1 so the check can never be skip-by-absence.
