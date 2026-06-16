#!/usr/bin/env bats
bats_require_minimum_version 1.5.0
#
# tests/lint/test-codex-reviews-rename-rejection.bats
#
# v0.7.4 G1 (audit item #1) — codex_reviews → second_reviewer rename sweep
# regression test.
#
# Contract under test
# -------------------
# The legacy config field `codex_reviews:` was renamed to `second_reviewer:`
# in v0.7.3. `skills/using-qrspi/SKILL.md` documents the rejection rule:
#
#   `codex_reviews`: removed — legacy name for `second_reviewer`. A stray
#   `codex_reviews:` field in `config.md` is a hard validation error,
#   never silently aliased.
#
# But the rename never finished — ~25 skill prose references and the
# `scripts/dispatch-agent.sh` config-read block still treat `codex_reviews`
# as the canonical field name. This lint pins the rename: every reference
# to `codex_reviews` in skills and scripts must be one of:
#
#   (a) the deprecation rule itself (documents that the field is removed)
#   (b) the worked-example script-function rename
#       (`check_codex_available → check_second_reviewer_available`)
#
# Every other reference is a sweep target and is flagged.
#
# Allowed-exception detection is content-based, not line-anchored, so the
# lint stays robust under prose edits.
#
# RED→GREEN trajectory
# --------------------
# Today (before the sub-phase 1.2/1.3 sweep): this test fails, reporting
# every stale `codex_reviews` consumer reference.
# After the sweep:                              this test passes silently.
#
# Bash 3.2 compatible (macOS /bin/bash 3.2): no associative arrays, no
# mapfile, no ${var,,}, no coproc, no wait -n.

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)"
  export REPO_ROOT
}

# ---------------------------------------------------------------------------
# qrspi_codex_reviews_rename_audit [--repo-root <DIR>]
#
# Scans every SKILL.md and reference file under <DIR>/skills/, plus
# <DIR>/scripts/dispatch-agent.sh, for occurrences of the bare token
# `codex_reviews` (with word boundaries on both sides).
#
# A line is exempt if its content matches any of:
#
#   (a) `check_codex_available` AND `check_second_reviewer_available` on
#       the SAME line — the v0.7.2-era public function name cited in plan
#       worked-examples as the BEFORE side of a symbol rename. Requiring
#       both tokens prevents dispatch-agent.sh comments that mention
#       `check_codex_available` alongside a stale `codex_reviews=...`
#       reference from slipping past the lint (R1 dual-review finding).
#   (b) `**removed**`                  — the deprecation-rule bullet.
#   (c) `legacy name for`              — the deprecation-rule bullet.
#   (d) `legacy \`codex_reviews:\``    — the rejection-rule menu header.
#   (e) `no longer a valid field`      — the rejection-rule diagnostic.
#   (f) `Reject it loudly`             — the rejection-rule diagnostic.
#   (g) `renamed to \`second_reviewer` — bridging prose in deprecation.
#   (h) `rename-naming diagnostic`     — rejection-rule plumbing.
#
# Any non-exempt line containing `codex_reviews` is a finding. The helper
# exits 0 silently on clean input, non-zero with one diagnostic per finding
# of shape `<file>:<line>: codex_reviews-rename-audit: <line text>` to
# stderr.
qrspi_codex_reviews_rename_audit() {
  local repo_root="$REPO_ROOT"
  if [[ "${1:-}" == "--repo-root" ]]; then
    repo_root="$2"
    shift 2
  fi

  local skills_dir="$repo_root/skills"
  local dispatch_script="$repo_root/scripts/dispatch-agent.sh"

  local hits_file
  hits_file="$(mktemp -t codex-reviews-audit-hits.XXXXXX)"
  : > "$hits_file"

  local file
  while IFS= read -r file; do
    _t_codex_reviews_scan_file "$file" >> "$hits_file"
  done < <(find "$skills_dir" -type f -name '*.md' 2>/dev/null | sort)

  if [[ -f "$dispatch_script" ]]; then
    _t_codex_reviews_scan_file "$dispatch_script" >> "$hits_file"
  fi

  if [[ -s "$hits_file" ]]; then
    cat "$hits_file" >&2
    rm -f "$hits_file"
    return 1
  fi
  rm -f "$hits_file"
  return 0
}

# Scans one file for non-exempt `codex_reviews` references and prints one
# diagnostic per finding to stdout.
_t_codex_reviews_scan_file() {
  local file="$1"
  local lineno=0
  local line
  while IFS= read -r line; do
    lineno=$((lineno + 1))
    case "$line" in
      *codex_reviews*) : ;;
      *) continue ;;
    esac

    # Exemption (a) — both function-name tokens on the same line (the
    # worked-example "BEFORE → AFTER" rename pattern).
    if [[ "$line" == *"check_codex_available"* && "$line" == *"check_second_reviewer_available"* ]]; then continue; fi

    # Exemptions (b)-(h) — deprecation-rule prose.
    if [[ "$line" == *"**removed**"* ]]; then continue; fi
    if [[ "$line" == *"legacy name for"* ]]; then continue; fi
    if [[ "$line" == *'legacy `codex_reviews:`'* ]]; then continue; fi
    if [[ "$line" == *"no longer a valid field"* ]]; then continue; fi
    if [[ "$line" == *"Reject it loudly"* ]]; then continue; fi
    if [[ "$line" == *'renamed to `second_reviewer'* ]]; then continue; fi
    if [[ "$line" == *"rename-naming diagnostic"* ]]; then continue; fi

    printf '%s:%d: codex_reviews-rename-audit: %s\n' "$file" "$lineno" "$line"
  done < "$file"
}

# ---------------------------------------------------------------------------
@test "codex_reviews-rename-audit: no stale consumer references remain in skills or dispatch-agent.sh" {
  run -0 qrspi_codex_reviews_rename_audit
}

@test "codex_reviews-rename-audit: deprecation-rule prose in using-qrspi is exempt (does NOT trigger lint)" {
  local f="$REPO_ROOT/skills/using-qrspi/SKILL.md"
  [[ -f "$f" ]]
  local hits
  hits="$(_t_codex_reviews_scan_file "$f" | grep -F 'removed' || true)"
  [[ -z "$hits" ]]
}

@test "codex_reviews-rename-audit: worked-example script-function rename in plan is exempt (BOTH tokens required)" {
  local f="$REPO_ROOT/skills/plan/SKILL.md"
  [[ -f "$f" ]]
  local hits
  hits="$(_t_codex_reviews_scan_file "$f" | grep -F 'check_codex_available' || true)"
  [[ -z "$hits" ]]
}

@test "codex_reviews-rename-audit: planted line with only BEFORE function name is still flagged (defense-in-depth for R1 finding)" {
  # Pins the fix for the R1 finding: a comment that mentions
  # `check_codex_available` alone (as dispatch-agent.sh:1481 does today)
  # MUST still be flagged when it also contains `codex_reviews`.
  local tmpdir
  tmpdir="$(mktemp -d -t codex-reviews-audit-fixture-leak.XXXXXX)"
  mkdir -p "$tmpdir/skills/fakeskill" "$tmpdir/scripts"
  cat > "$tmpdir/skills/fakeskill/SKILL.md" <<'EOF'
A stale comment mentioning check_codex_available trivially with codex_reviews=false reference.
EOF
  : > "$tmpdir/scripts/dispatch-agent.sh"
  run qrspi_codex_reviews_rename_audit --repo-root "$tmpdir"
  [[ "$status" -ne 0 ]]
  rm -rf "$tmpdir"
}

@test "codex_reviews-rename-audit: planted non-exempt reference is flagged (no-false-negative guard)" {
  local tmpdir
  tmpdir="$(mktemp -d -t codex-reviews-audit-fixture.XXXXXX)"
  mkdir -p "$tmpdir/skills/fakeskill" "$tmpdir/scripts"
  cat > "$tmpdir/skills/fakeskill/SKILL.md" <<'EOF'
Apply the Config Validation Procedure. This skill validates codex_reviews.
EOF
  : > "$tmpdir/scripts/dispatch-agent.sh"
  run qrspi_codex_reviews_rename_audit --repo-root "$tmpdir"
  [[ "$status" -ne 0 ]]
  rm -rf "$tmpdir"
}
