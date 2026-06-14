#!/usr/bin/env bats
# ============================================================================
# Task 14 — Fail-direction proof for the T12 id-hygiene CI lint helper.
#
# This file drives the T12 lint (`qrspi_id_hygiene_lint_check_file`, loaded
# from tests/helpers/id-hygiene-lint) against a generated fixture under
# tests/fixtures/id-hygiene/bad-test-name.bats.fixture, and asserts the
# documented diagnostic shape: non-zero exit, the fixture file path AND the
# offending line number both appear in the failure output, and the
# offending token string appears verbatim.
#
# Test Expectations coverage (task-14 spec):
#   - "A regression PR (synthetic) that adds a forbidden internal-ID token
#     to a real test name is rejected at CI by the lint — exercised against
#     the fixture file under tests/fixtures/id-hygiene/" — primary @test.
#   - "The lint's failure output for the fixture lists the fixture file path
#     and line number with the offending string (named-diagnostic guard)."
#   - "This test's own @test description strings contain zero forbidden
#     tokens (the fixture file under tests/fixtures/ is the carrier, not
#     this test's descriptions)." — descriptions deliberately neutral.
#
# Carrier-file safety: the fixture has the `.bats.fixture` extension so the
# T12 corpus-invariant grep (restricted via `grep --include="*.bats"`) does
# NOT match it; the permanent CI lint never sees it as a real `@test` line.
#
# Bash 3.2 (macOS /bin/bash 3.2.57) compatibility: no associative arrays,
# no mapfile, no globstar. Uses printf, mkdir -p, grep -n, [[ ]].
# ============================================================================

setup() {
  REPO_ROOT=$(cd "$BATS_TEST_DIRNAME/../.." && pwd)
  export REPO_ROOT
  FIXTURE="$REPO_ROOT/tests/fixtures/id-hygiene/bad-test-name.bats.fixture"
  export FIXTURE

  # Maintenance / emit step (idempotent): re-materialize the canonical
  # fixture content so the file is restored byte-for-byte if anything
  # mutates it locally. The carve-out marker on this body line documents
  # that the forbidden token in the printf format-string argument is
  # intentional and exempt from the body-line scan. The corpus-invariant
  # greps are anchored at `^@test "`, so a `printf` source line is never
  # matched by them regardless of carve-out — the marker is the
  # documented exemption layer for the per-file lint helper.
  mkdir -p "$(dirname "$FIXTURE")"
  {
    printf '#!/usr/bin/env bats\n'
    printf '# ----------------------------------------------------------------------------\n'
    printf '# Generated fixture for tests/unit/test-id-hygiene-lint-fail-direction.bats.\n'
    printf '#\n'
    printf '# This file is INTENTIONALLY carrying a forbidden bracketed-internal-ID token\n'
    printf '# inside an `@test "..."` description string. It exists solely as the input\n'
    printf '# to a fail-direction proof for the T12 id-hygiene lint helper.\n'
    printf '#\n'
    printf '# It lives under tests/fixtures/ (not tests/**/*.bats) AND uses the\n'
    printf '# `.bats.fixture` extension precisely so the permanent CI corpus-invariant\n'
    printf '# grep — which is restricted with `--include="*.bats"` — never sees this\n'
    printf '# file as a real test. The basename ends in `.fixture`, so the `*.bats`\n'
    printf '# glob filter does not match it, and the file is silently skipped by the\n'
    printf '# corpus sweep.\n'
    printf '#\n'
    printf '# Do not rename, move, or "fix" this file. Its forbidden token is the\n'
    printf '# load-bearing input to the fail-direction test.\n'
    printf '# ----------------------------------------------------------------------------\n'
    printf '@test "%s" {\n' '[T99] forbidden bracketed-internal-id token in description string'  # bats lint:no-id-hygiene
    printf '  :\n'
    printf '}\n'
  } > "$FIXTURE"

  # Load the shared lint helper. Until the implementer extracts
  # `qrspi_id_hygiene_lint_check_file` from tests/lint/test-bats-test-name-id-hygiene.bats
  # into a sourceable helper at tests/helpers/id-hygiene-lint.bash, this
  # `load` fails and every @test below reports RED — that is the
  # RED-gate signal for the implementer step.
  load '../helpers/id-hygiene-lint'
}

# ----------------------------------------------------------------------------
# Acceptance bullet 4 (G2): a regression PR that adds a forbidden internal-ID
# token to a real test name is rejected at CI by the lint — exercised here
# against the fixture under tests/fixtures/id-hygiene/.
# ----------------------------------------------------------------------------

@test "fail-direction: lint helper rejects the fixture carrying a forbidden internal-id token" {
  declare -F qrspi_id_hygiene_lint_check_file >/dev/null
  run qrspi_id_hygiene_lint_check_file "$FIXTURE"
  [ "$status" -ne 0 ]
  [ "$status" -ne 127 ]
}

# ----------------------------------------------------------------------------
# Named-diagnostic guard: failure output lists `file:line` location AND
# the offending token string verbatim.
# ----------------------------------------------------------------------------

@test "fail-direction diagnostic: failure output names the fixture file path" {
  declare -F qrspi_id_hygiene_lint_check_file >/dev/null
  run qrspi_id_hygiene_lint_check_file "$FIXTURE"
  [ "$status" -ne 0 ]
  [ "$status" -ne 127 ]
  printf '%s\n' "$output" | grep -qF -- "$FIXTURE"
}

@test "fail-direction diagnostic: failure output names the offending line number of the at-test declaration" {
  declare -F qrspi_id_hygiene_lint_check_file >/dev/null
  # Compute the offending @test line number from the on-disk fixture so the
  # assertion is not coupled to fixture authorship details (comment count
  # may evolve; the lint-relevant fact is the line carrying `@test "`).
  offending_lineno=$(grep -nE '^@test "' "$FIXTURE" | head -n 1 | cut -d: -f1)
  [ -n "$offending_lineno" ]
  run qrspi_id_hygiene_lint_check_file "$FIXTURE"
  [ "$status" -ne 0 ]
  [ "$status" -ne 127 ]
  printf '%s\n' "$output" | grep -qF -- "$FIXTURE:$offending_lineno"
}

@test "fail-direction diagnostic: failure output echoes the offending token string verbatim" {
  declare -F qrspi_id_hygiene_lint_check_file >/dev/null
  run qrspi_id_hygiene_lint_check_file "$FIXTURE"
  [ "$status" -ne 0 ]
  [ "$status" -ne 127 ]
  # The bracketed-internal-id token from the fixture's @test description.
  # The carve-out marker on the next line exempts this assertion body line
  # from the per-file lint helper; the corpus-invariant greps are anchored
  # at `^@test "` and cannot match this `printf`/`grep` line regardless.
  expected_token='[T99]'  # bats lint:no-id-hygiene
  printf '%s\n' "$output" | grep -qF -- "$expected_token"
}

# ----------------------------------------------------------------------------
# Carrier-file shape guard: confirm the fixture lives under tests/fixtures/
# (NOT tests/**/*.bats) so the permanent CI lint never sees it as an
# `@test` line. This locks the "carve-out by extension" property in place.
# ----------------------------------------------------------------------------

@test "fixture carrier path: the fixture lives under tests/fixtures and is not picked up by the corpus grep" {
  [ -f "$FIXTURE" ]
  case "$FIXTURE" in
    "$REPO_ROOT"/tests/fixtures/*) : ;;
    *) printf 'fixture not under tests/fixtures/: %s\n' "$FIXTURE" >&2; return 1 ;;
  esac
  # Basename must NOT match the `*.bats` glob used by the corpus grep's
  # `--include` filter; otherwise the corpus invariant would itself flag
  # the fixture and the carrier strategy collapses.
  basename=$(basename "$FIXTURE")
  case "$basename" in
    *.bats) printf 'fixture basename matches *.bats glob: %s\n' "$basename" >&2; return 1 ;;
    *) : ;;
  esac
  # Cross-check against the corpus-invariant grep itself: run it and
  # confirm the fixture's offending token is NOT reported.
  cd "$REPO_ROOT"
  run bash -c 'grep -rEn --include="*.bats" "^@test \"[^\"]*\[T[0-9]+" tests/'
  [ "$status" -eq 1 ]
  [ -z "$output" ]
}
