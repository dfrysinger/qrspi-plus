#!/usr/bin/env bats
# ============================================================================
# Task 11 acceptance — sweep [Tnn] and forbidden-finding-ID tokens from
# @test descriptions across the bats corpus.
#
# Covers the per-task Test Expectations from
# v072-plan.md / task-11 (Implement-phase RED gate):
#
#   - After the sweep PR, both forbidden-token greps against tests/**/*.bats
#     return zero matches, AND the zero-match holds without any
#     @test-description carve-out exemption (TE bullet 2).
#   - The mechanical-check structural-lint script accepts the actual sweep
#     diff (against the integration base) — non-empty and mechanical-only
#     (TE bullet 3, in-tree pass-case half).
#   - Body content between `@test "..."` and the next `}` is byte-identical
#     pre- and post-sweep for every modified test file (per-file diff guard,
#     TE bullet 4).
#
# These tests are written BEFORE the implementer applies the sweep and are
# expected to FAIL on the bare integration-base (RED gate); after the sweep
# they must all pass.
#
# IMPORTANT: this file's own @test description strings deliberately avoid
# any forbidden token pattern (no `[T<digits>]`, no `R<digits>-F<digits>`)
# so the post-sweep zero-match assertions are not self-undermined by the
# test file itself.
# ============================================================================

setup() {
  REPO_ROOT=$(cd "$BATS_TEST_DIRNAME/../.." && pwd)
  export REPO_ROOT
  # The integration-base for v0.7.3 Wave 3 task-11 — the commit the sweep
  # diffs against. The post-W2 stage ref is stable and present in every
  # task-branch worktree cut from that stage.
  SWEEP_BASE_REF="qrspi/v0.7.3/stage-after-W2"
  export SWEEP_BASE_REF
}

# ----------------------------------------------------------------------------
# TE bullet 2 — zero-match grep, both token classes, WITHOUT carve-out
# exemption.
# ----------------------------------------------------------------------------

# Test expectation: After the sweep PR, `grep -rE '@test "[^"]*\[T[0-9]+'
# tests/**/*.bats` returns zero matches (bracketed internal-ID token class
# from goals.md G2 + design.md G2 Solution change 1).
@test "task-11 acceptance: bracketed internal-ID token absent from every @test description in the bats corpus" {
  cd "$REPO_ROOT"
  # Use --include='*.bats' so the recursive walk matches the plan's
  # `tests/**/*.bats` semantics without depending on shell globstar.
  # Anchor to `^@test "` so the grep matches only real @test declaration
  # lines, never literal `@test "..."` substrings appearing inside heredoc
  # bodies or printf-string fixtures used by other tests in the corpus.
  run bash -c 'grep -rEn --include="*.bats" "^@test \"[^\"]*\[T[0-9]+" tests/'
  # grep exits 1 on zero matches with empty stdout.
  [ "$status" -eq 1 ]
  [ -z "$output" ]
}

# Test expectation: After the sweep PR, `grep -rE '^@test
# "[^"]*R[0-9]+-F[0-9]+' tests/**/*.bats` returns zero matches
# (round-finding-ID token class). Anchored at start-of-line; see test
# above for rationale.
@test "task-11 acceptance: round-finding-ID token absent from every @test description in the bats corpus" {
  cd "$REPO_ROOT"
  run bash -c 'grep -rEn --include="*.bats" "^@test \"[^\"]*R[0-9]+-F[0-9]+" tests/'
  [ "$status" -eq 1 ]
  [ -z "$output" ]
}

# Test expectation: the zero-match holds WITHOUT any `@test`-description
# carve-out exemption — no `@test "..."` description line carries the
# inline `# bats lint:no-id-hygiene` carve-out marker. (The marker is
# valid only on fixture-construction body lines, never on @test names.)
@test "task-11 acceptance: id-hygiene carve-out marker is never co-located on an @test description line" {
  cd "$REPO_ROOT"
  run bash -c 'grep -rEn --include="*.bats" "^@test \"[^\"]*bats lint:no-id-hygiene" tests/'
  [ "$status" -eq 1 ]
  [ -z "$output" ]
}

# ----------------------------------------------------------------------------
# TE bullet 3 (in-tree pass-case) — the structural-lint script accepts the
# real sweep diff against the integration base.
# ----------------------------------------------------------------------------

# Test expectation: The mechanical-check structural-lint script passes
# against the sweep PR's diff (computed from the integration-base ref to
# HEAD, restricted to tests/). The diff must be non-empty (vacuous pass
# forbidden) and mechanical-only.
@test "task-11 acceptance: structural-lint script accepts the actual sweep diff against the integration base" {
  cd "$REPO_ROOT"
  SCRIPT="$REPO_ROOT/scripts/structural-lints/check-bats-id-hygiene-sweep.sh"
  [ -x "$SCRIPT" ] || chmod +x "$SCRIPT"
  # Skip-guard / capability probe: this acceptance check is meaningful only
  # when the integration-base ref is reachable from the current worktree.
  # If it is not (e.g., a shallow clone in some CI contexts), skip cleanly
  # rather than hard-fail — the guard MUST be able to reach `skip` under
  # its stated failure condition.
  if ! git rev-parse --verify "$SWEEP_BASE_REF" >/dev/null 2>&1; then
    skip "integration-base ref $SWEEP_BASE_REF not reachable in this worktree"
  fi
  # Scope the diff to the sweep's OWN commits only. At task-11 branch
  # isolation, `$SWEEP_BASE_REF..HEAD` is exactly the sweep; at any
  # downstream integration stage (e.g., stage-after-W3 after the W3
  # octopus merge), the same range also contains other tasks' edits to
  # files the sweep never touched. Conflating those non-sweep edits into
  # "the sweep diff" produces false negatives here — the structural-lint
  # script then sees body-line changes it correctly rejects, even though
  # the sweep itself is mechanical-only. We identify the sweep's commits
  # via author + commit-subject grep, enumerate the files they touched,
  # and restrict the diff to that file set. (fix-r2.)
  sweep_files=$(git log --author='qrspi-implementer' --grep='task-11' \
                  "$SWEEP_BASE_REF"..HEAD --name-only --pretty=format: -- 'tests/*.bats' \
                | sed '/^$/d' | sort -u)
  if [ -z "$sweep_files" ]; then
    # No sweep commits present — the sweep has not been applied (RED
    # gate) or the commit-subject pattern has drifted. Fail loudly
    # rather than passing vacuously.
    return 1
  fi
  # shellcheck disable=SC2086 # word-splitting intentional — pathspecs
  diff_input=$(git diff "$SWEEP_BASE_REF"..HEAD -- $sweep_files)
  # Non-empty diff is required — the sweep must have applied at least one
  # mechanical edit somewhere under tests/. The naive bash parameter
  # expansion `${var//[[:space:]]/}` is O(N²) on bash 3.2 (macOS
  # /bin/bash 3.2.57) and hangs on the ~192KB sweep diff; the external
  # `tr | head -c 1` pipeline runs in constant memory and finishes
  # instantly. Mirrors the perf fix landed in production code (commit
  # 681f1c6) for the same bash-3.2 trap.
  [ -n "$(printf '%s' "$diff_input" | tr -d '[:space:]' | head -c 1)" ]
  run bash -c 'printf "%s\n" "$1" | "$2"' _ "$diff_input" "$SCRIPT"
  [ "$status" -eq 0 ]
}

# ----------------------------------------------------------------------------
# TE bullet 4 — per-file body-bytes diff guard.
# ----------------------------------------------------------------------------

# Test expectation: Body content (the lines between `@test "..."` and the
# next `}`) is byte-identical pre- and post-sweep for every modified .bats
# file under tests/. We approximate "body content" by stripping every
# `@test "..."` declaration line from both the integration-base snapshot
# and the HEAD snapshot and asserting byte equality of the remainder.
@test "task-11 acceptance: body bytes are byte-identical pre- and post-sweep for every modified bats file" {
  cd "$REPO_ROOT"
  if ! git rev-parse --verify "$SWEEP_BASE_REF" >/dev/null 2>&1; then
    skip "integration-base ref $SWEEP_BASE_REF not reachable in this worktree"
  fi
  # Enumerate every modified .bats file under tests/ between the
  # integration base and HEAD that the sweep ITSELF touched. Scoping to
  # the sweep's own commits (via author + commit-subject grep) keeps this
  # invariant meaningful at downstream integration stages: at
  # stage-after-W3 the bare `SWEEP_BASE_REF..HEAD` range also contains
  # other tasks' edits (e.g., fix-04a-r1's body-line additions to
  # test-dispatch-agent.bats), which would spuriously trip the body-bytes
  # equality check below despite the sweep being mechanical-only.
  # --diff-filter=M restricts to Modified files only. Added files (such
  # as this acceptance test file itself, which is new in the sweep PR)
  # have no base-ref content and would spuriously fail the body-bytes
  # equality check below (base_bodies="" ≠ head_bodies=<content>). The
  # body-bytes invariant is meaningful only for files that existed on
  # both sides AND that the sweep actually modified. (fix-r2.)
  sweep_files=$(git log --author='qrspi-implementer' --grep='task-11' \
                  "$SWEEP_BASE_REF"..HEAD --name-only --pretty=format: -- 'tests/*.bats' \
                | sed '/^$/d' | sort -u)
  # shellcheck disable=SC2086 # word-splitting intentional — pathspecs
  modified_list=$(git diff --name-only --diff-filter=M "$SWEEP_BASE_REF"..HEAD -- $sweep_files | grep -E '\.bats$' || true)
  # The sweep MUST touch at least one bats file under tests/; an empty
  # modified-list means the sweep has not run (RED) or stripped nothing
  # (vacuous), both of which fail this assertion.
  [ -n "$modified_list" ]

  failed_files=""
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    base_bodies=$(git show "$SWEEP_BASE_REF:$f" 2>/dev/null | awk '/^@test "/ {next} {print}')
    head_bodies=$(git show "HEAD:$f"            2>/dev/null | awk '/^@test "/ {next} {print}')
    if [ "$base_bodies" != "$head_bodies" ]; then
      failed_files="${failed_files}${f}\n"
    fi
  done <<EOF
$modified_list
EOF

  if [ -n "$failed_files" ]; then
    printf 'body-bytes mismatch (non-@test lines changed) in:\n%b' "$failed_files" >&2
    return 1
  fi
}
