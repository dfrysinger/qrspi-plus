#!/usr/bin/env bats
bats_require_minimum_version 1.5.0

# tests/lint/test-bats-body-assertion-guard.bats
#
# G21 / G26 BATS hygiene lint — two parallel rules in one corpus walk.
#
# G21 (body-guard rule, design.md §G21 sub-decision B2):
#   Every line matching `[[ "$body"` inside an @test block must be preceded —
#   anywhere earlier in the same @test block — by a line matching
#   `[ -n "$body" ]`. A negation assertion that passes vacuously when $body is
#   empty is a silent-pass regression; the guard closes that surface.
#   Diagnostic: file:line for every unguarded occurrence.
#   Positive controls: the R5-era pins in tests/unit/test-using-qrspi-vocab.bats
#   (already guarded) must be accepted silently.
#
# G26 / BW02 (minimum-version rule, design.md §G21 Amendment at G26 design-lock):
#   Any .bats file that uses a bats ≥1.5.0 feature (initial pattern set:
#   `run --separate-stderr`) must declare `bats_require_minimum_version <ver>`
#   somewhere earlier in the same file. Without the declaration the bats-core
#   BW02 warning fires at runtime; with it, older bats installs fail loudly up
#   front rather than silently misbehaving mid-test.
#   Diagnostic: file:line + triggering feature name for every violation.
#
# Discovery: all *.bats under tests/ excluding this lint file itself.
# Block parsing: opener ^@test "..." {  closer ^} at column 0.
# No shellcheck rule. No pre-commit hook. CI gate only (G21 sub-decision C1).

load '../helpers/skill-markdown'

# ---------------------------------------------------------------------------
# @test G21 — body-guard rule
#
# Walk the corpus. For each @test block, track whether [ -n "$body" ] has been
# seen. Fail if [[ "$body"  appears before the guard.
# ---------------------------------------------------------------------------
@test "[G21] corpus: every [[\"\$body\"...]] assertion is preceded by [ -n \"\$body\" ] in the same @test block" {
  require_repo_root

  # Build corpus: all *.bats under tests/ except this lint file.
  local corpus=()
  while IFS= read -r f; do
    corpus+=("$f")
  done < <(find "$REPO_ROOT/tests" -name "*.bats" \
             ! -name "test-bats-body-assertion-guard.bats" \
           | sort)

  # awk parse: opener = line starting with @test (col 0)
  #            closer = bare } at col 0 while inside a block
  #            guard  = line matching [ -n "$body" ]
  #            hit    = line matching [[ "$body"  without prior guard in block
  local violations
  violations="$(
    awk '
      FNR == 1 { in_block = 0; has_guard = 0 }
      /^@test / {
        in_block  = 1
        has_guard = 0
        next
      }
      /^\}/ && in_block {
        in_block  = 0
        has_guard = 0
        next
      }
      in_block && /\[ -n "\$body" \]/ {
        has_guard = 1
      }
      in_block && /\[\[ "\$body"/ && !has_guard {
        printf "%s:%d: unguarded $body assertion: %s\n", FILENAME, FNR, $0
      }
    ' "${corpus[@]}"
  )"

  if [ -n "$violations" ]; then
    printf 'G21: unguarded $body assertions found (add [ -n "$body" ] earlier in the same @test block):\n%s\n' \
      "$violations" >&2
    return 1
  fi
}

# ---------------------------------------------------------------------------
# @test G26/BW02 — minimum-version declaration rule
#
# Walk the corpus. Any file that uses `run --separate-stderr` must have a
# `bats_require_minimum_version` declaration somewhere BEFORE the first
# such use in the file. Report file:line + triggering feature for each hit.
# ---------------------------------------------------------------------------
@test "[G26/BW02] corpus: every file using \"run --separate-stderr\" declares bats_require_minimum_version before first use" {
  require_repo_root

  # Build corpus: same walk as G21.
  local corpus=()
  while IFS= read -r f; do
    corpus+=("$f")
  done < <(find "$REPO_ROOT/tests" -name "*.bats" \
             ! -name "test-bats-body-assertion-guard.bats" \
           | sort)

  # awk parse: per-file, track whether bats_require_minimum_version has been
  # seen (has_guard). On first `run --separate-stderr` without has_guard, emit
  # a diagnostic and set flagged=1 so we report each file at most once.
  local violations
  violations="$(
    awk '
      FNR == 1 { has_guard = 0; flagged = 0 }
      /bats_require_minimum_version/ { has_guard = 1 }
      /run --separate-stderr/ && !has_guard && !flagged {
        printf "%s:%d: BW02: feature \"run --separate-stderr\" used without bats_require_minimum_version (declare it before first use)\n",
               FILENAME, FNR
        flagged = 1
      }
    ' "${corpus[@]}"
  )"

  if [ -n "$violations" ]; then
    printf 'G26/BW02: files using run --separate-stderr without bats_require_minimum_version:\n%s\n' \
      "$violations" >&2
    return 1
  fi
}
