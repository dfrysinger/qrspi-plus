#!/usr/bin/env bats
#
# Plan-level acceptance tests for G2 (Sweep [Tnn] and R\d+-F\d+ task-ID
# markers from @test descriptions + prevent reintroduction).
#
# Maps to design.md § G2 Acceptance and plan.md Phase 1 Acceptance Criteria
# bullet 7 — the verbatim raw-grep gate that MUST return zero matches
# across the bats corpus.

setup_file() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")"/../../.. && pwd)"
  export REPO_ROOT
  export LINT="$REPO_ROOT/tests/lint/test-bats-test-name-id-hygiene.bats"
  export IMP_PROTO="$REPO_ROOT/skills/implementer-protocol/SKILL.md"
}

@test "acceptance: zero @test descriptions contain [Tnn] markers across tests/**/*.bats (verbatim plan gate)" {
  # plan.md Phase 1 Acceptance bullet 7 verbatim grep.
  # NOTE: implemented via `find -print0 | xargs -0` rather than bash 4
  # globstar (`shopt -s globstar` + `tests/**/*.bats`) so the sweep runs
  # correctly under the bash32 CI runner (globstar is bash 4+ only;
  # without it `**` collapses to single-level `*` and silently under-scans).
  cd "$REPO_ROOT"
  matches="$(find tests -type f -name '*.bats' -print0 \
    | xargs -0 grep -E '@test "[^"]*\[T[0-9]+' 2>/dev/null || true)"
  if [ -n "$matches" ]; then
    echo "Forbidden [Tnn] tokens in @test descriptions:" >&2
    echo "$matches" >&2
    false
  fi
}

@test "acceptance: zero @test descriptions contain R\\d+-F\\d+ markers across tests/**/*.bats (verbatim plan gate)" {
  # plan.md Phase 1 Acceptance bullet 7 verbatim grep (second token class).
  # See bash32 note above re: find/xargs vs globstar.
  cd "$REPO_ROOT"
  matches="$(find tests -type f -name '*.bats' -print0 \
    | xargs -0 grep -E '@test "[^"]*R[0-9]+-F[0-9]+' 2>/dev/null || true)"
  if [ -n "$matches" ]; then
    echo "Forbidden R\\d+-F\\d+ tokens in @test descriptions:" >&2
    echo "$matches" >&2
    false
  fi
}

@test "acceptance: permanent CI lint exists at tests/lint/test-bats-test-name-id-hygiene.bats" {
  # Without the lint, the sweep is mechanical-only — re-introduction is not blocked.
  [ -f "$LINT" ]
}

@test "boundary: lint detection pattern fires against a synthetic regression line carrying an internal-ID token" {
  # Fail-direction proof: the verbatim plan-gate grep matches the forbidden
  # shape. Token assembled at runtime so this test file's source does not
  # itself trip the corpus-wide sweep above.
  open_bracket='['
  close_bracket=']'
  fake_line="@test \"regression - forbidden ${open_bracket}T99${close_bracket} in description\" {"
  printf '%s\n' "$fake_line" | grep -qE '@test "[^"]*\[T[0-9]+'
}

@test "acceptance: implementer-protocol Pre-DONE self-check carries the halt-DONE blocking anchor for @test description hits" {
  # G2 acceptance bullet 2 / design.md § G2 Solution change 2.
  grep -qF 'Halt-DONE' "$IMP_PROTO"
  grep -qF '@test "..."' "$IMP_PROTO"
}
