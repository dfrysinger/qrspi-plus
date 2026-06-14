# ============================================================================
# tests/helpers/id-hygiene-lint.bash
#
# Shared sourceable helper carrying the per-file id-hygiene lint logic used
# by:
#   - tests/lint/test-bats-test-name-id-hygiene.bats  (T12 — permanent CI gate)
#   - tests/unit/test-id-hygiene-lint-fail-direction.bats  (T14 — fail-direction proof)
#
# Bats consumers load this file via `load '<relpath>/id-hygiene-lint'`
# (bats's `load` appends `.bash` automatically). The function below is the
# single source of truth; both T12 and T14 invoke it through `run`.
#
# Bash 3.2 (macOS /bin/bash 3.2.57) compatible: no associative arrays, no
# mapfile, no advanced regex constructs.
# ============================================================================

# ----------------------------------------------------------------------------
# qrspi_id_hygiene_lint_check_file <bats-file>
#
# Scans a single .bats file for forbidden id-shape tokens (bracketed
# internal-ID token shape and round-finding-ID token shape — see goals.md
# G2 and design.md G2 Solution change 1 for the canonical token grammar)
# and exits non-zero when any are found.
#
# Two distinct line classes with distinct rules:
#
#   * `@test "..."` description lines (source line begins with `@test "`):
#     forbidden tokens in the description string are ALWAYS flagged. The
#     inline carve-out marker `# bats lint:no-id-hygiene` has no effect on
#     description lines — this is the load-bearing "no carve-out for
#     descriptions" rule.
#
#   * Body lines (everything else, including comments, heredoc lines, and
#     fixture-construction printf calls): forbidden tokens are flagged
#     UNLESS the same source line carries the carve-out marker
#     `# bats lint:no-id-hygiene`, in which case the line is exempt.
#
# Diagnostic shape (per task spec): every offender is reported as
# `<file>:<lineno>: <source-line>` on stdout, so the offending token
# string appears verbatim alongside the file:line location.
#
# Returns 0 when clean, 1 when any offender found.
# ----------------------------------------------------------------------------
qrspi_id_hygiene_lint_check_file() {
  local file="$1"
  local lineno=0
  local found=0
  local line
  # IFS= and -r preserve leading whitespace and backslashes; the `|| [ -n
  # "$line" ]` clause flushes a final line lacking a trailing newline.
  while IFS= read -r line || [ -n "$line" ]; do
    lineno=$((lineno + 1))
    # Classify: @test description line vs body line. The corpus-invariant
    # greps in the T12 lint anchor on `^@test "`, so we use the same
    # anchor here for symmetry.
    if [[ "$line" == '@test "'* ]]; then
      # Description line — carve-out marker is intentionally ignored.
      if [[ "$line" =~ \[T[0-9]+ ]] || [[ "$line" =~ R[0-9]+-F[0-9]+ ]]; then
        printf '%s:%d: %s\n' "$file" "$lineno" "$line"
        found=1
      fi
    else
      # Body line — carve-out marker on the SAME line exempts.
      if [[ "$line" == *'# bats lint:no-id-hygiene'* ]]; then
        continue
      fi
      if [[ "$line" =~ \[T[0-9]+ ]] || [[ "$line" =~ R[0-9]+-F[0-9]+ ]]; then
        printf '%s:%d: %s\n' "$file" "$lineno" "$line"
        found=1
      fi
    fi
  done < "$file"
  return "$found"
}
