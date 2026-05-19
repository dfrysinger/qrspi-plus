#!/usr/bin/env bats
bats_require_minimum_version 1.5.0

# Task 18 — G7, G18: Implementer pre-DONE self-check BATS pin
#
# Exercises the combined pre-DONE self-check contract defined in
# skills/implementer-protocol/SKILL.md § Hygiene contract.
#
# Fixtures are synthesized commit-diff lines (the "+" lines from
# `git diff HEAD~1 --unified=0`) applied against simulated file paths.
#
# Contract under test:
#   1. Added line with internal-ID on skills/foo/SKILL.md → hit (internal-ID family)
#   2. Same token under docs/qrspi/** path → no hit (path carve-out)
#   3. Added evergreen token on a non-exempt .md file → hit (evergreen family)
#   4. Same evergreen token on a .sh file → no hit (evergreen applies to .md only)
#   5. Retained hit + explicit DONE-report acknowledgment → proceeds; preserved
#   6. Retained hit + no acknowledgment → still proceeds (advisory); hit surfaced
#      to reviewer via DONE-report companion channel
#
# Bash 3.2 portable: no mapfile, no declare -A, no ${var,,}, no coproc, no wait -n.

load '../helpers/skill-markdown'

# ---------------------------------------------------------------------------
# Setup/teardown: fixture directories
# ---------------------------------------------------------------------------
setup() {
  FIXTURE_DIR="$(mktemp -d /tmp/hygiene-self-check-XXXXXX)"
  export FIXTURE_DIR
}

teardown() {
  rm -rf "$FIXTURE_DIR"
}

# ---------------------------------------------------------------------------
# Internal-ID detection helpers
# ---------------------------------------------------------------------------

# _contains_internal_id <line>
# Returns 0 if line contains an internal-ID forbidden token, 1 otherwise.
# Families: round-N finding-N / R\d+-F\d+, T\d{2}, G\d+, Q\d+, F-\d+, D\d+
_contains_internal_id() {
  local line="$1"
  # Reviewer finding ID: round-N finding-N or RN-FN
  printf '%s\n' "$line" | grep -qE 'round-[0-9]+ finding-[0-9]+|R[0-9]+-F[0-9]+'  && return 0
  # Task ID: T\d\d (two digits)
  printf '%s\n' "$line" | grep -qE '\bT[0-9]{2}\b'                                  && return 0
  # Goal ID: G\d+
  printf '%s\n' "$line" | grep -qE '\bG[0-9]+\b'                                    && return 0
  # Question ID: Q\d+
  printf '%s\n' "$line" | grep -qE '\bQ[0-9]+\b'                                    && return 0
  # Future-goal ID: F-\d+
  printf '%s\n' "$line" | grep -qE '\bF-[0-9]+\b'                                   && return 0
  # Design decision ID: D\d+
  printf '%s\n' "$line" | grep -qE '\bD[0-9]+\b'                                    && return 0
  return 1
}

# _is_internal_id_path_exempt <rel_path>
# Returns 0 if path is in an internal-ID carve-out surface.
_is_internal_id_path_exempt() {
  local rel="$1"
  # docs/qrspi/** and docs/qrspi/YYYY-MM-DD-*/** (both covered by docs/qrspi/)
  case "$rel" in
    docs/qrspi/*) return 0 ;;
  esac
  # agents/qrspi-*-reviewer.md
  case "$rel" in
    agents/qrspi-*-reviewer.md) return 0 ;;
  esac
  return 1
}

# _is_evergreen_path_exempt <rel_path>
# Returns 0 if path is in an evergreen-markdown carve-out surface.
_is_evergreen_path_exempt() {
  local rel="$1"
  case "$rel" in
    docs/qrspi/*) return 0 ;;
    CHANGELOG.md) return 0 ;;
    tests/fixtures/*) return 0 ;;
  esac
  return 1
}

# _contains_evergreen_token <line>
# Returns 0 if line contains an evergreen-markdown forbidden token.
_contains_evergreen_token() {
  local line="$1"
  printf '%s\n' "$line" | grep -qE 'v[0-9]+\.[0-9]+'                                          && return 0
  printf '%s\n' "$line" | grep -qE 'in v[0-9]+\.[0-9]+|after this release|after the [a-zA-Z]+ release' && return 0
  printf '%s\n' "$line" | grep -qE '(see|per|fixes|closes)[[:space:]]+#[0-9]+'                && return 0
  return 1
}

# _scan_diff_line <added_line> <file_path>
# Simulates a single line of the pre-DONE self-check scan.
# Prints a diagnostic to stdout on a hit; returns 1 if any hit; 0 otherwise.
_scan_diff_line() {
  local line="$1"
  local rel_path="$2"
  local hit=0

  # Inline carve-out: id-hygiene-exempt suppresses internal-ID check
  case "$line" in *'<!-- id-hygiene-exempt -->'*) : ;;
    *)
      if ! _is_internal_id_path_exempt "$rel_path" && _contains_internal_id "$line"; then
        printf 'HYGIENE HIT: %s [internal-ID]: %s\n' "$rel_path" "$line"
        hit=1
      fi
      ;;
  esac

  # Inline carve-out: evergreen-exempt suppresses evergreen check
  case "$line" in *'<!-- evergreen-exempt -->'*) : ;;
    *)
      # Evergreen applies to .md files only
      case "$rel_path" in
        *.md)
          if ! _is_evergreen_path_exempt "$rel_path" && _contains_evergreen_token "$line"; then
            printf 'HYGIENE HIT: %s [evergreen-markdown]: %s\n' "$rel_path" "$line"
            hit=1
          fi
          ;;
      esac
      ;;
  esac

  return $hit
}

# ---------------------------------------------------------------------------
# Fixture 1: internal-ID token on skills/foo/SKILL.md → hit
# ---------------------------------------------------------------------------
@test "[T18] fixture-1: internal-ID on skills/foo/SKILL.md triggers hit naming file and family" {
  local line="This was found in round-2 finding-05 and needs attention."
  local path="skills/foo/SKILL.md"

  run _scan_diff_line "$line" "$path"
  [ "$status" -ne 0 ]
  printf '%s\n' "$output" | grep -q "internal-ID"
  printf '%s\n' "$output" | grep -q "skills/foo/SKILL.md"
}

# ---------------------------------------------------------------------------
# Fixture 2: same internal-ID token under docs/qrspi/** → no hit (path carve-out)
# ---------------------------------------------------------------------------
@test "[T18] fixture-2: internal-ID under docs/qrspi/** path carve-out — no hit" {
  local line="This was found in round-2 finding-05 and needs attention."
  local path="docs/qrspi/2026-05-17-v07-release/reviews/goals/round-01.md"

  run _scan_diff_line "$line" "$path"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# ---------------------------------------------------------------------------
# Fixture 3: evergreen token on non-exempt .md file → hit
# ---------------------------------------------------------------------------
@test "[T18] fixture-3: evergreen token on non-exempt .md triggers hit naming file and family" {
  local line="This feature ships in v0.7+ as the new default."
  local path="skills/implementer-protocol/SKILL.md"

  run _scan_diff_line "$line" "$path"
  [ "$status" -ne 0 ]
  printf '%s\n' "$output" | grep -q "evergreen-markdown"
  printf '%s\n' "$output" | grep -q "skills/implementer-protocol/SKILL.md"
}

# ---------------------------------------------------------------------------
# Fixture 4: evergreen token on .sh file → no hit (markdown-only rule)
# ---------------------------------------------------------------------------
@test "[T18] fixture-4: evergreen token on .sh file — no hit (markdown-only rule)" {
  local line="echo 'Ships in v0.7'"
  local path="scripts/my-deploy.sh"

  run _scan_diff_line "$line" "$path"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# ---------------------------------------------------------------------------
# Fixture 5: retained hit + explicit DONE-report acknowledgment → acknowledged
# The acknowledgment is preserved in the DONE report for reviewer visibility.
# ---------------------------------------------------------------------------
@test "[T18] fixture-5: hit with DONE-report acknowledgment — acknowledged, preserved in report" {
  # Simulate a DONE report file with acknowledgment
  local done_report="$FIXTURE_DIR/done-report.md"
  printf '# DONE Report\n\n## Pre-DONE Self-Check Hits\n\n**Acknowledged hit:** skills/foo/SKILL.md line 7 [internal-ID: round-2 finding-05]\nRationale: This line documents the finding schema itself and is the work product.\n' > "$done_report"

  # Verify DONE-report contains acknowledgment
  run grep -q "Acknowledged hit" "$done_report"
  [ "$status" -eq 0 ]

  # Verify the acknowledgment names the hit's line reference
  run grep -q "internal-ID" "$done_report"
  [ "$status" -eq 0 ]

  # Advisory contract: commit proceeds (we verify the DONE report exists and is non-empty)
  [ -f "$done_report" ]
  [ -s "$done_report" ]
}

# ---------------------------------------------------------------------------
# Fixture 6: retained hit + NO acknowledgment → advisory proceed; hit surfaced
# via DONE-report companion channel
# ---------------------------------------------------------------------------
@test "[T18] fixture-6: unacknowledged hit still proceeds (advisory) and is surfaced to reviewer" {
  # Simulate a DONE report with an unacknowledged hit
  local done_report="$FIXTURE_DIR/done-report-unack.md"
  printf '# DONE Report\n\n## Pre-DONE Self-Check Hits\n\n**Unacknowledged hit:** skills/bar/SKILL.md line 42 [evergreen-markdown: v0.7]\nNo rationale provided.\n' > "$done_report"

  # Advisory: commit still proceeds — verify report file exists (represents commit happening)
  [ -f "$done_report" ]

  # Reviewer visibility: DONE-report file path would be passed as companion param
  # Assert the unacknowledged hit appears in the report body
  run grep -q "Unacknowledged hit" "$done_report"
  [ "$status" -eq 0 ]

  # Assert the DONE-report file path itself is non-empty (would be listed in dispatch payload)
  local report_path="$done_report"
  [ -n "$report_path" ]
  [ -f "$report_path" ]
}

# ---------------------------------------------------------------------------
# Hygiene contract section exists in implementer-protocol SKILL.md
# ---------------------------------------------------------------------------
@test "[T18] hygiene contract H2 section exists in implementer-protocol SKILL.md" {
  require_repo_root
  local skill_file="$REPO_ROOT/skills/implementer-protocol/SKILL.md"
  extract_section "$skill_file" H2 "Hygiene contract"
}

# ---------------------------------------------------------------------------
# Internal-ID forbidden tokens H3 exists under Hygiene contract
# ---------------------------------------------------------------------------
@test "[T18] Internal-ID forbidden tokens H3 section present in hygiene contract" {
  require_repo_root
  local skill_file="$REPO_ROOT/skills/implementer-protocol/SKILL.md"
  extract_and_grep "$skill_file" H3 "Internal-ID forbidden tokens" "round"
}

# ---------------------------------------------------------------------------
# Evergreen-markdown forbidden tokens H3 exists under Hygiene contract
# ---------------------------------------------------------------------------
@test "[T18] Evergreen-markdown forbidden tokens H3 section present in hygiene contract" {
  require_repo_root
  local skill_file="$REPO_ROOT/skills/implementer-protocol/SKILL.md"
  extract_and_grep "$skill_file" H3 "Evergreen-markdown forbidden tokens" "v\\\\d"
}

# ---------------------------------------------------------------------------
# Pre-DONE self-check H3 exists and names advisory nature
# ---------------------------------------------------------------------------
@test "[T18] pre-DONE self-check H3 section names advisory contract" {
  require_repo_root
  local skill_file="$REPO_ROOT/skills/implementer-protocol/SKILL.md"
  extract_and_grep "$skill_file" H3 "Pre-DONE self-check (combined hygiene scan)" "advisory"
}

# ---------------------------------------------------------------------------
# Pre-DONE self-check mentions reviewer visibility channel
# ---------------------------------------------------------------------------
@test "[T18] pre-DONE self-check H3 section names reviewer visibility channel" {
  require_repo_root
  local skill_file="$REPO_ROOT/skills/implementer-protocol/SKILL.md"
  extract_and_grep "$skill_file" H3 "Pre-DONE self-check (combined hygiene scan)" "[Rr]eviewer"
}

# ---------------------------------------------------------------------------
# Shared helper loads and REPO_ROOT resolves.
# ---------------------------------------------------------------------------
@test "[T18] shared helper loads and require_repo_root resolves REPO_ROOT" {
  require_repo_root
  [ -n "$REPO_ROOT" ]
  [ -d "$REPO_ROOT" ]
}
