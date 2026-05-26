#!/usr/bin/env bats
bats_require_minimum_version 1.5.0

# Task 17 — G18: Repo-wide evergreen-markdown BATS scan
#
# Scans every git-tracked *.md file for evergreen-markdown forbidden tokens,
# applying path-shaped and inline carve-outs from the hygiene contract
# (skills/implementer-protocol/SKILL.md § Evergreen-markdown forbidden tokens
# and § Path-shaped carve-outs).
#
# Carve-outs (path-shaped):
#   - docs/qrspi/YYYY-MM-DD-*/**   (dated pipeline artifact directories)
#   - CHANGELOG.md                  (version-of-record file)
#   - tests/fixtures/**             (fixture files may embed version strings)
#
# Inline carve-out:
#   - A line ending with <!-- evergreen-exempt --> is skipped for that line only.
#
# Forbidden-token families (regex):
#   - release-version : v[0-9]+\.[0-9]+
#   - milestone-wording: in v[0-9]+\.[0-9]+|after this release|after the [a-zA-Z]+ release
#   - pr-issue-ref    : (see|per|fixes|closes)\s+#[0-9]+
#
# Bash 3.2 portable: no mapfile, no declare -A, no ${var,,}, no coproc,
# no wait -n.

load '../helpers/skill-markdown'

# ---------------------------------------------------------------------------
# _is_path_exempt <rel_path>
# Returns 0 if rel_path falls under a path-shaped carve-out; 1 otherwise.
# ---------------------------------------------------------------------------
_is_path_exempt() {
  local rel="$1"
  # Carve-out 1: dated pipeline artifact dirs (docs/qrspi/YYYY-MM-DD-*/**)
  case "$rel" in
    docs/qrspi/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-*/*)
      return 0 ;;
  esac
  # Carve-out 2: CHANGELOG.md
  case "$rel" in
    CHANGELOG.md)
      return 0 ;;
  esac
  # Carve-out 3: tests/fixtures/**
  case "$rel" in
    tests/fixtures/*)
      return 0 ;;
  esac
  return 1
}

# ---------------------------------------------------------------------------
# _check_file_for_evergreen <abs_path> <rel_path>
# Scans a single file for evergreen-markdown hits outside carve-outs.
# Prints diagnostics to stdout for any hit.
# Returns 1 if any hits were found, 0 otherwise.
# ---------------------------------------------------------------------------
_check_file_for_evergreen() {
  local abs_path="$1"
  local rel_path="$2"
  local found_hit=0

  # Use awk for the scan: Bash 3.2 portable, one pass per file.
  # Families checked:
  #   1. release-version : v[0-9]+\.[0-9]+
  #   2. milestone-wording: in v[0-9]+\.[0-9]+|after this release|after the [a-zA-Z]+ release
  #   3. pr-issue-ref: (see|per|fixes|closes) +#[0-9]+
  local hits
  hits="$(awk -v rp="$rel_path" '
    /<!-- evergreen-exempt -->/ { next }
    /v[0-9]+\.[0-9]+/ {
      printf "EVERGREEN HIT: %s:%d [release-version]: %s\n", rp, NR, $0
      found = 1
    }
    /in v[0-9]+\.[0-9]+|after this release|after the [a-zA-Z]+ release/ {
      printf "EVERGREEN HIT: %s:%d [milestone-wording]: %s\n", rp, NR, $0
      found = 1
    }
    /(see|per|fixes|closes) +#[0-9]+/ {
      printf "EVERGREEN HIT: %s:%d [pr-issue-ref]: %s\n", rp, NR, $0
      found = 1
    }
    END { exit (found ? 1 : 0) }
  ' "$abs_path")"
  local awk_rc=$?

  if [ -n "$hits" ]; then
    printf '%s\n' "$hits"
    return 1
  fi
  return 0
}

setup_file() {
  require_repo_root
}

# ---------------------------------------------------------------------------
# Fixture: a markdown file with no forbidden tokens passes.
# ---------------------------------------------------------------------------
@test "[T17] clean markdown file (no forbidden tokens) passes" {
  local fixture
  fixture="$(mktemp /tmp/evergreen-clean-XXXXXX.md)"
  printf '# My Feature\n\nThis documents the contract surface. No version tokens here.\n' > "$fixture"
  run _check_file_for_evergreen "$fixture" "fake/clean.md"
  rm -f "$fixture"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# ---------------------------------------------------------------------------
# Fixture: a markdown file with a release-version token fails with diagnostic.
# ---------------------------------------------------------------------------
@test "[T17] markdown file with release-version token (in v0.6) outside carve-out fails" {
  local fixture
  fixture="$(mktemp /tmp/evergreen-hit-XXXXXX.md)"
  printf '# Feature\n\nThis was introduced in v0.6 as the canonical approach.\n' > "$fixture"
  run _check_file_for_evergreen "$fixture" "skills/fake/SKILL.md"
  rm -f "$fixture"
  [ "$status" -ne 0 ]
  printf '%s\n' "$output" | grep -q "release-version"
  printf '%s\n' "$output" | grep -q "skills/fake/SKILL.md"
}

# ---------------------------------------------------------------------------
# Fixture: a line with <!-- evergreen-exempt --> is skipped even with a hit.
# ---------------------------------------------------------------------------
@test "[T17] line with evergreen-exempt inline comment is skipped" {
  local fixture
  fixture="$(mktemp /tmp/evergreen-exempt-XXXXXX.md)"
  printf '# Feature\n\nReleased in v0.7 <!-- evergreen-exempt -->\n' > "$fixture"
  run _check_file_for_evergreen "$fixture" "skills/fake/SKILL.md"
  rm -f "$fixture"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# ---------------------------------------------------------------------------
# Path carve-out: docs/qrspi/YYYY-MM-DD-*/** is exempt.
# ---------------------------------------------------------------------------
@test "[T17] file under docs/qrspi/YYYY-MM-DD-* carve-out path is exempt" {
  run _is_path_exempt "docs/qrspi/2026-05-17-v07-release/tasks/task-01.md"
  [ "$status" -eq 0 ]
}

@test "[T17] file outside carve-out path is not exempt" {
  run _is_path_exempt "skills/implement/SKILL.md"
  [ "$status" -ne 0 ]
}

# ---------------------------------------------------------------------------
# Path carve-out: CHANGELOG.md is exempt.
# ---------------------------------------------------------------------------
@test "[T17] CHANGELOG.md is exempt from path-shaped carve-out check" {
  run _is_path_exempt "CHANGELOG.md"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Path carve-out: tests/fixtures/** is exempt.
# ---------------------------------------------------------------------------
@test "[T17] file under tests/fixtures/ is exempt" {
  run _is_path_exempt "tests/fixtures/some-fixture.md"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Non-markdown file: a .sh file with release-version token has no effect
# (the scan only checks .md files — tested via the repo-wide scan logic).
# ---------------------------------------------------------------------------
@test "[T17] non-markdown file path is not exempt (but scan skips non-.md)" {
  # The repo-wide scan filters for *.md; a .sh file would not be fed to
  # _check_file_for_evergreen. Path-exemption logic is only for .md paths.
  run _is_path_exempt "scripts/my-script.sh"
  # .sh paths have no carve-out; return value is 1 (not exempt).
  [ "$status" -ne 0 ]
}

# ---------------------------------------------------------------------------
# Repo-wide scan: iterate every git-tracked *.md file and apply the hygiene
# contract. Failures are accumulated; the test reports all hits at once.
# ---------------------------------------------------------------------------
@test "[T17] repo-wide evergreen-markdown scan — no hits outside carve-outs" {
  require_repo_root
  local all_hits=""
  local tmp_list
  tmp_list="$(mktemp /tmp/evergreen-mdlist-XXXXXX.txt)"

  # Collect all git-tracked .md files into temp file (avoid pipe subshell)
  git -C "$REPO_ROOT" ls-files '*.md' 2>/dev/null > "$tmp_list"

  while IFS= read -r rel; do
    [ -n "$rel" ] || continue

    # Apply path-shaped carve-outs
    if _is_path_exempt "$rel"; then
      continue
    fi

    local abs_path="$REPO_ROOT/$rel"
    [ -f "$abs_path" ] || continue

    local file_hits
    # Capture hits; ignore nonzero from _check_file_for_evergreen
    file_hits="$(_check_file_for_evergreen "$abs_path" "$rel")" || true
    if [ -n "$file_hits" ]; then
      all_hits="${all_hits}${file_hits}
"
    fi
  done < "$tmp_list"

  rm -f "$tmp_list"

  if [ -n "$all_hits" ]; then
    printf 'Evergreen-markdown violations found:\n%s\n' "$all_hits" >&2
    return 1
  fi
}

# ---------------------------------------------------------------------------
# Helper loads correctly via the shared helper convention.
# ---------------------------------------------------------------------------
@test "[T17] shared helper loads and require_repo_root resolves REPO_ROOT" {
  require_repo_root
  [ -n "$REPO_ROOT" ]
  [ -d "$REPO_ROOT" ]
}

# ===========================================================================
# Jargon scan (skills/** + agents/**)
#
# Catches non-evergreen vocabulary that drifts into the canonical orchestrator
# and step skills. Scope is intentionally narrower than the repo-wide
# release-version scan above: historical surfaces (docs/qrspi/YYYY-MM-DD-*/,
# docs/superpowers/, reviews/, CHANGELOG.md) preserve past protocol state
# as snapshots and are not scanned.
#
# Forbidden-token families (regex):
#   - bare-paren-pr-ref : \(#[0-9]+               (e.g. "(#112 PR-1 ...)")
#   - mechanism-codename: \bMechanism [A-Z]\b     (e.g. "Mechanism A")
#   - b-code-in-parens  : \(B[0-9]+[a-z]?\)       (e.g. "(B5)", "(B5a)")
#   - half-step-number  : \bstep (5\.5|7\.5)\b  (e.g. "step 5.5", "step 7.5")
#                         Only the two retired half-step labels are forbidden;
#                         legitimate hierarchical sub-step numbering (e.g.
#                         "step 5.2", "step 1.1") is allowed.
#
# Inline carve-out: lines ending with <!-- evergreen-exempt --> are skipped.
# ---------------------------------------------------------------------------

_check_file_for_jargon() {
  local abs_path="$1"
  local rel_path="$2"

  local hits
  hits="$(awk -v rp="$rel_path" '
    /<!-- evergreen-exempt -->/ { next }
    /\(#[0-9]+/ {
      printf "JARGON HIT: %s:%d [bare-paren-pr-ref]: %s\n", rp, NR, $0
      found = 1
    }
    /(^|[^A-Za-z])Mechanism [A-Z]([^A-Za-z]|$)/ {
      printf "JARGON HIT: %s:%d [mechanism-codename]: %s\n", rp, NR, $0
      found = 1
    }
    /\(B[0-9]+[a-z]?\)/ {
      printf "JARGON HIT: %s:%d [b-code-in-parens]: %s\n", rp, NR, $0
      found = 1
    }
    /(^|[^A-Za-z])step (5\.5|7\.5)([^0-9]|$)/ {
      printf "JARGON HIT: %s:%d [half-step-number]: %s\n", rp, NR, $0
      found = 1
    }
    END { exit (found ? 1 : 0) }
  ' "$abs_path")"

  if [ -n "$hits" ]; then
    printf '%s\n' "$hits"
    return 1
  fi
  return 0
}

@test "[jargon] positive fixture: bare-paren PR ref triggers detection" {
  local fixture
  fixture="$(mktemp /tmp/jargon-pr-XXXXXX.md)"
  printf '# Heading\n\nSee details (#112 PR-1 background) for context.\n' > "$fixture"
  run _check_file_for_jargon "$fixture" "skills/fake/SKILL.md"
  rm -f "$fixture"
  [ "$status" -ne 0 ]
  printf '%s\n' "$output" | grep -q "bare-paren-pr-ref"
}

@test "[jargon] positive fixture: Mechanism codename triggers detection" {
  local fixture
  fixture="$(mktemp /tmp/jargon-mech-XXXXXX.md)"
  printf '# Heading\n\nThe Mechanism A pathway is the canonical entry.\n' > "$fixture"
  run _check_file_for_jargon "$fixture" "skills/fake/SKILL.md"
  rm -f "$fixture"
  [ "$status" -ne 0 ]
  printf '%s\n' "$output" | grep -q "mechanism-codename"
}

@test "[jargon] negative fixture: 'Mechanism' table header (no trailing letter) does NOT trigger" {
  local fixture
  fixture="$(mktemp /tmp/jargon-mech-neg-XXXXXX.md)"
  printf '# Heading\n\n| Mechanism | Trigger |\n|---|---|\n| foo | bar |\n' > "$fixture"
  run _check_file_for_jargon "$fixture" "skills/fake/SKILL.md"
  rm -f "$fixture"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "[jargon] positive fixture: B-code in parens triggers detection" {
  local fixture
  fixture="$(mktemp /tmp/jargon-bcode-XXXXXX.md)"
  printf '# Heading\n\nThe anchor invariant (B5) governs ref selection.\n' > "$fixture"
  run _check_file_for_jargon "$fixture" "skills/fake/SKILL.md"
  rm -f "$fixture"
  [ "$status" -ne 0 ]
  printf '%s\n' "$output" | grep -q "b-code-in-parens"
}

@test "[jargon] positive fixture: half-step numbering triggers detection" {
  local fixture
  fixture="$(mktemp /tmp/jargon-halfstep-XXXXXX.md)"
  printf '# Heading\n\nReferenced from step 5.5 (scope-tagger).\n' > "$fixture"
  run _check_file_for_jargon "$fixture" "skills/fake/SKILL.md"
  rm -f "$fixture"
  [ "$status" -ne 0 ]
  printf '%s\n' "$output" | grep -q "half-step-number"
}

@test "[jargon] negative fixture: full integer step number does NOT trigger" {
  local fixture
  fixture="$(mktemp /tmp/jargon-int-XXXXXX.md)"
  printf '# Heading\n\nReferenced from step 6 (scope-tagger dispatch).\n' > "$fixture"
  run _check_file_for_jargon "$fixture" "skills/fake/SKILL.md"
  rm -f "$fixture"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "[jargon] negative fixture: hierarchical sub-step numbering (step 5.2, step 1.1) does NOT trigger" {
  local fixture
  fixture="$(mktemp /tmp/jargon-substep-XXXXXX.md)"
  printf '# Heading\n\nSee step 5.2 (HARD-GATE check) and step 1.1 (precondition).\n' > "$fixture"
  run _check_file_for_jargon "$fixture" "skills/fake/SKILL.md"
  rm -f "$fixture"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "[jargon] inline evergreen-exempt comment suppresses jargon hit" {
  local fixture
  fixture="$(mktemp /tmp/jargon-exempt-XXXXXX.md)"
  printf '# Heading\n\nLegacy note: see Mechanism A behavior. <!-- evergreen-exempt -->\n' > "$fixture"
  run _check_file_for_jargon "$fixture" "skills/fake/SKILL.md"
  rm -f "$fixture"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "[jargon] skills/** + agents/** scan — no jargon hits" {
  require_repo_root
  local all_hits=""
  local tmp_list
  tmp_list="$(mktemp /tmp/jargon-mdlist-XXXXXX.txt)"

  git -C "$REPO_ROOT" ls-files 'skills/*.md' 'skills/**/*.md' 'agents/*.md' 'agents/**/*.md' 2>/dev/null > "$tmp_list"

  while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    local abs_path="$REPO_ROOT/$rel"
    [ -f "$abs_path" ] || continue

    local file_hits
    file_hits="$(_check_file_for_jargon "$abs_path" "$rel")" || true
    if [ -n "$file_hits" ]; then
      all_hits="${all_hits}${file_hits}
"
    fi
  done < "$tmp_list"

  rm -f "$tmp_list"

  if [ -n "$all_hits" ]; then
    printf 'Jargon violations found in skills/** + agents/**:\n%s\n' "$all_hits" >&2
    return 1
  fi
}
