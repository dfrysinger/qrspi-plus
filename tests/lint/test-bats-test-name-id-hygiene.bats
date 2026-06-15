#!/usr/bin/env bats
# ============================================================================
# Task 12 — Permanent CI lint: id-hygiene of @test description strings.
#
# This file IS the permanent CI gate (no separate script). It bundles two
# load-bearing behaviours:
#
#   (a) Corpus invariant — every @test description string under tests/**/*.bats
#       is free of the forbidden internal-ID token class (`[T<digits>]`,
#       optionally with sub-task suffix) and the forbidden round-finding-ID
#       token class (`R<digits>-F<digits>`). These are the two token shapes
#       enumerated by goals.md G2 and design.md G2 Solution change 1.
#
#   (b) Lint-logic contract — a helper, `qrspi_id_hygiene_lint_check_file`,
#       accepts a single .bats file path and exits non-zero whenever the file
#       carries a forbidden token inside an `@test "..."` description string.
#       The helper's failure output names the offending `file:line` location
#       and the offending string verbatim (named-diagnostic discipline).
#       The helper honours the inline carve-out marker
#       `# bats lint:no-id-hygiene` ONLY on a fixture-construction body line
#       inside a test body; an `@test "..."` description string is NEVER
#       exempted on the basis of an adjacent carve-out marker.
#
# Test Expectations coverage (from task-12 spec):
#   - "The lint exists and passes on the post-sweep clean tree (Acceptance
#     bullet 3, first half)" — (a) above; two corpus @tests.
#   - "The lint fails ... against a fixture file ... that carries a forbidden
#     internal-ID token ... AND a fixture file that carries a forbidden
#     round-finding-ID token" — fail-direction @tests below.
#   - "The carve-out marker ... on a fixture-construction body line inside a
#     test body exempts that body line from the lint match" — carve-out @test
#     below.
#   - "An `@test "..."` description string containing a forbidden token is
#     NOT exempted by an adjacent carve-out marker" — anti-carve-out @test.
#   - "The lint's failure output lists `file:line` locations and the
#     offending strings" — diagnostic-shape @test.
#
# IMPORTANT — self-referential token hygiene:
#   This file's own @test description strings deliberately avoid every
#   forbidden token shape (no `[T<digits>]`, no `R<digits>-F<digits>`) so the
#   corpus-invariant @tests above are not self-undermined.
#
#   Forbidden tokens appear ONLY inside test bodies, and only as ARGUMENTS to
#   `printf` format strings used to construct on-disk fixture files at runtime
#   — NEVER on a source line that begins with `@test "`. This is what keeps
#   the T11 / corpus-invariant greps (`^@test "[^"]*\[T[0-9]+` and
#   `^@test "[^"]*R[0-9]+-F[0-9]+`) anchored to the start of the line: those
#   greps cannot match a line that begins with `printf` or whitespace, so
#   building fixture lines via printf is safe and the carve-out marker on
#   those printf body lines documents the intentional construction. The
#   carve-out is illustrative documentation for human readers; the corpus
#   greps already cannot match these source lines.
#
# Bash 3.2 (macOS /bin/bash 3.2.57) compatibility: no associative arrays,
# no `${var//pat/}` on multi-KB inputs, no `mapfile`. Used: `printf`,
# `mktemp -d`, `[[ ... ]]` with `==` glob, `run`.
# ============================================================================

setup() {
  REPO_ROOT=$(cd "$BATS_TEST_DIRNAME/../.." && pwd)
  export REPO_ROOT
  T12_TMPDIR=$(mktemp -d -t qrspi-id-hygiene-XXXXXX)
  export T12_TMPDIR
  # Load the shared lint helper. The function `qrspi_id_hygiene_lint_check_file`
  # used by the @tests below is defined here as the single source of truth and
  # shared with tests/unit/test-id-hygiene-lint-fail-direction.bats (T14).
  # See the helper file's header for the full contract; the in-file
  # specification comment block above setup() remains canonical reading.
  load '../helpers/id-hygiene-lint'
}

# ----------------------------------------------------------------------------
# The `qrspi_id_hygiene_lint_check_file` helper is sourced via `load` in
# setup() above from tests/helpers/id-hygiene-lint.bash. See that file for
# the function body; the contract documented in the header comment of this
# file remains authoritative.
# ----------------------------------------------------------------------------

teardown() {
  if [ -n "${T12_TMPDIR:-}" ] && [ -d "$T12_TMPDIR" ]; then
    rm -rf "$T12_TMPDIR"
  fi
}

# ----------------------------------------------------------------------------
# (a) Corpus-invariant: the CI gate's load-bearing behaviour against the
# live tests/**/*.bats tree. These two @tests ARE the permanent CI lint —
# they encode the zero-match assertion as bats assertions so the corpus-wide
# state is verified on every PR run.
# ----------------------------------------------------------------------------

# Test expectation: "The lint exists and passes on the post-sweep clean
# tree (Acceptance bullet 3, first half)" — bracketed internal-ID half.
@test "id-hygiene lint: every @test description across the bats corpus is free of the bracketed internal-ID token shape" {
  cd "$REPO_ROOT"
  # --include='*.bats' replicates the plan's `tests/**/*.bats` semantics
  # without depending on shell globstar. Anchored to `^@test "` so the grep
  # cannot match a literal `@test "..."` substring appearing inside a
  # heredoc body, a printf format string, or any other in-body fixture
  # construction — only real declaration lines count.
  run bash -c 'grep -rEn --include="*.bats" "^@test \"[^\"]*\[T[0-9]+" tests/'
  [ "$status" -eq 1 ]
  [ -z "$output" ]
}

# Test expectation: "The lint exists and passes on the post-sweep clean
# tree (Acceptance bullet 3, first half)" — round-finding-ID half.
@test "id-hygiene lint: every @test description across the bats corpus is free of the round-finding-ID token shape" {
  cd "$REPO_ROOT"
  run bash -c 'grep -rEn --include="*.bats" "^@test \"[^\"]*R[0-9]+-F[0-9]+" tests/'
  [ "$status" -eq 1 ]
  [ -z "$output" ]
}

# ----------------------------------------------------------------------------
# (b) Lint-logic contract: `qrspi_id_hygiene_lint_check_file <path>`.
#
# The implementer adds this helper to the SAME file in the implement-step
# commit. Until then, every @test below fails because the command is
# undefined — that is the RED-gate signal.
# ----------------------------------------------------------------------------

# Test expectation: "The lint fails (with the documented diagnostic shape)
# against a fixture file ... that carries a forbidden internal-ID token
# (`[T<digits>]`) inside an `@test "..."` description string".
@test "id-hygiene lint fail-direction: a fixture with a bracketed internal-ID token in an at-test description triggers a non-zero exit" {
  fixture="$T12_TMPDIR/forbidden-bracketed-internal-id.bats"
  # Construct the fixture via printf so the SOURCE line does not begin
  # with `@test "` — the corpus-invariant greps above are anchored at
  # start-of-line and cannot match a `printf` line. The forbidden token
  # `[T99]` is intentionally embedded inside the printf argument here, as
  # the lint's fail-direction input.  # bats lint:no-id-hygiene
  printf '#!/usr/bin/env bats\n@test "%s" {\n  :\n}\n' '[T99] forbidden-bracketed-internal-id case' > "$fixture"
  # Precondition: the lint helper must be defined. A `command not found`
  # exit (127) is RED, not a false pass; we assert definedness explicitly.
  declare -F qrspi_id_hygiene_lint_check_file >/dev/null
  run qrspi_id_hygiene_lint_check_file "$fixture"
  [ "$status" -ne 0 ]
  [ "$status" -ne 127 ]
  # The forbidden token string must appear in the diagnostic output, and
  # the offender's file location must be named (named-diagnostic
  # discipline). We assert content via grep so a missing match fails the
  # test (bats does not propagate failures from a bare `[[ ]]`).
  printf '%s\n' "$output" | grep -qF -- '[T99]'
  printf '%s\n' "$output" | grep -qF -- "$fixture"
}

# Test expectation: "The lint fails ... against a fixture file that carries
# a forbidden round-finding-ID token (`R<digits>-F<digits>`) inside an
# `@test "..."` description string".
@test "id-hygiene lint fail-direction: a fixture with a round-finding-ID token in an at-test description triggers a non-zero exit" {
  fixture="$T12_TMPDIR/forbidden-round-finding-id.bats"
  # See sibling @test above for the printf-construction rationale.
  # The forbidden token `R99-F99` lives inside the printf argument.
  # bats lint:no-id-hygiene
  printf '#!/usr/bin/env bats\n@test "%s" {\n  :\n}\n' 'R99-F99 forbidden round-finding-id case' > "$fixture"
  declare -F qrspi_id_hygiene_lint_check_file >/dev/null
  run qrspi_id_hygiene_lint_check_file "$fixture"
  [ "$status" -ne 0 ]
  [ "$status" -ne 127 ]
  printf '%s\n' "$output" | grep -qF -- 'R99-F99'
  printf '%s\n' "$output" | grep -qF -- "$fixture"
}

# Test expectation: "The carve-out marker `# bats lint:no-id-hygiene` on a
# fixture-construction body line inside a test body exempts that body line
# from the lint match."
@test "id-hygiene lint: carve-out marker on a fixture-construction body line exempts that body line from the lint match" {
  fixture="$T12_TMPDIR/carveout-on-body-line.bats"
  # The fixture below is the canonical legitimate-use shape: a test body
  # whose printf call emits a forbidden token to a generated fixture under
  # tests/fixtures/, with the carve-out marker on the SAME line as the
  # emission. The lint MUST treat this fixture as clean (status 0), because
  # (i) the @test description carries no forbidden token and (ii) the body
  # line carries the carve-out marker.
  # NOTE: we construct the fixture with printf instead of a heredoc so that
  # the literal `@test ...` declaration NEVER appears at the start of a line
  # in THIS script source. Bats's per-file pre-scan counts `^@test` lines
  # regardless of heredoc context, so a heredoc-embedded `@test` would
  # inflate this file's declared count and produce a spurious
  # "Executed N-1 instead of expected N" warning that fails CI under exit-1.
  printf '%s\n' \
    '#!/usr/bin/env bats' \
    '@test "test body emits forbidden token to a generated fixture file" {' \
    "  printf '@test \"%s\" { :; }\\n' '[T99] x' > tests/fixtures/generated.bats  # bats lint:no-id-hygiene" \
    '}' \
    > "$fixture"
  declare -F qrspi_id_hygiene_lint_check_file >/dev/null
  run qrspi_id_hygiene_lint_check_file "$fixture"
  [ "$status" -eq 0 ]
}

# Test expectation: "An `@test "..."` description string containing a
# forbidden token is NOT exempted by an adjacent carve-out marker — the
# `@test`-description rule has no carve-out."
@test "id-hygiene lint: an at-test description string is not exempted by an adjacent carve-out marker" {
  fixture="$T12_TMPDIR/carveout-adjacent-to-at-test-rejected.bats"
  # Fixture intent: a carve-out marker placed on the line immediately
  # preceding an `@test "..."` description that itself contains a
  # forbidden token. The lint MUST still flag the @test description; the
  # carve-out is body-line-only and has no description-line semantics.
  # Constructed via printf so the source line in THIS test file does not
  # begin with `@test "`.  # bats lint:no-id-hygiene
  {
    printf '#!/usr/bin/env bats\n'
    printf '# bats lint:no-id-hygiene\n'
    printf '@test "%s" {\n  :\n}\n' '[T99] description must still be flagged'
  } > "$fixture"
  declare -F qrspi_id_hygiene_lint_check_file >/dev/null
  run qrspi_id_hygiene_lint_check_file "$fixture"
  [ "$status" -ne 0 ]
  [ "$status" -ne 127 ]
  printf '%s\n' "$output" | grep -qF -- '[T99]'
}

# Test expectation: "The lint's failure output lists `file:line` locations
# and the offending strings (named-diagnostic discipline; no silent fail)."
@test "id-hygiene lint diagnostic shape: failure output names file:line locations and the offending token strings" {
  fixture="$T12_TMPDIR/diagnostic-shape.bats"
  # Three @test declarations: line 2 carries a bracketed-internal-ID
  # token, line 3 is clean, line 4 carries a round-finding-ID token. The
  # lint's failure output must name file:line for both offenders AND echo
  # both offending token strings verbatim.
  # bats lint:no-id-hygiene
  {
    printf '#!/usr/bin/env bats\n'
    printf '@test "%s" { :; }\n' '[T42] one'
    printf '@test "ok two" { :; }\n'
    printf '@test "%s" { :; }\n' 'R12-F03 three'
  } > "$fixture"
  declare -F qrspi_id_hygiene_lint_check_file >/dev/null
  run qrspi_id_hygiene_lint_check_file "$fixture"
  [ "$status" -ne 0 ]
  [ "$status" -ne 127 ]
  # file:line discipline — every offender's location is named. Use grep
  # so a missing match fails the test (a bare `[[ ]]` does not propagate
  # failure under bats).
  printf '%s\n' "$output" | grep -qF -- "$fixture:2"
  printf '%s\n' "$output" | grep -qF -- "$fixture:4"
  # Offending strings appear verbatim in the diagnostic.
  printf '%s\n' "$output" | grep -qF -- '[T42]'
  printf '%s\n' "$output" | grep -qF -- 'R12-F03'
  # The clean line is not named as an offender.
  ! printf '%s\n' "$output" | grep -qF -- "$fixture:3"
}
