#!/usr/bin/env bats
bats_require_minimum_version 1.5.0

# Task 19 (pin 2 of 2) — G17: Bash 3.2 runtime ban-list coverage pin
#
# Asserts every construct enumerated in the lint job's Option B ban-list grep
# step actually fails under `docker run --rm bash:3.2 bash -c '<construct>'`.
#
# The fixture set is derived by parsing the ban-list out of the workflow's
# lint job step body so the test stays synchronized with the workflow rather
# than carrying an independent enumeration.
#
# Contrapositive observation: if a ban-listed construct SUCCEEDS under bash:3.2,
# the ban-list is stale and the test fails loudly.
#
# NOTE: The docker run invocations require the docker daemon. When docker is
# absent (e.g., a bare CI lint runner without Docker-in-Docker), the test
# skips individual constructs with a SKIP diagnostic rather than failing,
# so the test suite remains green on non-Docker runners while the bash32
# Docker job (which does have Docker available) provides the real validation.
#
# Bash 3.2 portable: no mapfile, no declare -A, no ${var,,}, no coproc, no wait -n.

load '../helpers/skill-markdown'

setup_file() {
  require_repo_root
  CI_YML="$REPO_ROOT/.github/workflows/ci.yml"
  export CI_YML
  # Check docker availability once
  if command -v docker >/dev/null 2>&1; then
    DOCKER_AVAILABLE=1
  else
    DOCKER_AVAILABLE=0
  fi
  export DOCKER_AVAILABLE
}

# ---------------------------------------------------------------------------
# Parse ban-list constructs from the workflow's lint job step body.
# The step is named "Option B ban-list grep (bash 4+ constructs)".
# Each `-e '<pattern>'` in the grep invocation is one banned construct.
# ---------------------------------------------------------------------------
_parse_ban_list_from_workflow() {
  local ci_yml="$1"
  # Extract the -e patterns from the ban-list step in ci.yml
  # Each pattern is on a line like: -e '\bmapfile\b' \
  grep -E "^\s+-e '" "$ci_yml" | sed "s/.*-e '//;s/'.*$//"
}

# ---------------------------------------------------------------------------
# _assert_construct_fails_under_bash32 <construct_name> <bash_snippet>
# Asserts that the snippet exits non-zero under bash:3.2.
# Skips when docker is unavailable.
# ---------------------------------------------------------------------------
_assert_construct_fails_under_bash32() {
  local name="$1"
  local snippet="$2"

  if [ "$DOCKER_AVAILABLE" = "0" ]; then
    skip "docker not available; skipping bash:3.2 runtime check for $name"
    return 0
  fi

  run docker run --rm bash:3.2 bash -c "$snippet"
  if [ "$status" -eq 0 ]; then
    printf 'COVERAGE FAILURE: construct "%s" succeeded under bash:3.2 — ban-list may be stale\n' "$name" >&2
    printf 'Snippet: %s\n' "$snippet" >&2
    return 1
  fi
  # Non-zero exit is correct (construct fails under bash 3.2)
  return 0
}

# ---------------------------------------------------------------------------
# ci.yml exists and has a ban-list step
# ---------------------------------------------------------------------------
@test "[T19-ban] ci.yml ban-list step is present and parseable" {
  require_repo_root
  [ -f "$CI_YML" ]
  run grep -c "Option B ban-list" "$CI_YML"
  [ "$status" -eq 0 ]
  [ "$output" -ge 1 ]
}

# ---------------------------------------------------------------------------
# Ban-list parses to at least 4 constructs (mapfile, declare -A, ,,, coproc)
# ---------------------------------------------------------------------------
@test "[T19-ban] ban-list step enumerates at least 4 banned constructs" {
  require_repo_root
  [ -f "$CI_YML" ]
  local count
  count="$(_parse_ban_list_from_workflow "$CI_YML" | grep -c '.' || true)"
  if [ "$count" -lt 4 ]; then
    printf 'Expected >= 4 banned constructs; got %d\n' "$count" >&2
    return 1
  fi
}

# ---------------------------------------------------------------------------
# mapfile fails under bash:3.2
# ---------------------------------------------------------------------------
@test "[T19-ban] mapfile fails under bash:3.2" {
  _assert_construct_fails_under_bash32 "mapfile" 'mapfile arr < /dev/null'
}

# ---------------------------------------------------------------------------
# declare -A fails under bash:3.2
# ---------------------------------------------------------------------------
@test "[T19-ban] declare -A (associative array) fails under bash:3.2" {
  # Use && so the overall command fails when declare -A fails (exit 0 after ; would mask it)
  _assert_construct_fails_under_bash32 "declare -A" 'declare -A mymap && mymap[key]=val'
}

# ---------------------------------------------------------------------------
# ${var,,} (lowercase substitution) fails under bash:3.2
# ---------------------------------------------------------------------------
@test "[T19-ban] \${var,,} lowercase substitution fails under bash:3.2" {
  _assert_construct_fails_under_bash32 '${var,,}' 'v=HELLO; echo "${v,,}"'
}

# ---------------------------------------------------------------------------
# ${var^^} (uppercase substitution) fails under bash:3.2
# ---------------------------------------------------------------------------
@test "[T19-ban] \${var^^} uppercase substitution fails under bash:3.2" {
  _assert_construct_fails_under_bash32 '${var^^}' 'v=hello; echo "${v^^}"'
}

# ---------------------------------------------------------------------------
# coproc fails under bash:3.2
# ---------------------------------------------------------------------------
@test "[T19-ban] coproc fails under bash:3.2" {
  _assert_construct_fails_under_bash32 "coproc" 'coproc cat'
}

# ---------------------------------------------------------------------------
# wait -n fails under bash:3.2
# ---------------------------------------------------------------------------
@test "[T19-ban] wait -n fails under bash:3.2" {
  _assert_construct_fails_under_bash32 "wait -n" 'sleep 0 & wait -n'
}

# ---------------------------------------------------------------------------
# Contrapositive coverage: the ban-list does not omit any construct that
# actually fails under bash:3.2.  We verify each pattern parsed from the
# workflow ban-list corresponds to a known construct with a failing snippet.
# This surfaces any new ban-list entry added to the workflow that lacks a
# corresponding runtime check in this file — a loud diagnostic, not silent.
# ---------------------------------------------------------------------------
@test "[T19-ban] every ban-list pattern parsed from workflow has a known snippet" {
  require_repo_root
  [ -f "$CI_YML" ]
  local constructs_file
  constructs_file="$(mktemp /tmp/ban-list-constructs-XXXXXX.txt)"
  _parse_ban_list_from_workflow "$CI_YML" > "$constructs_file"

  local unknown=""
  local pattern=""

  while IFS= read -r pattern; do
    [ -n "$pattern" ] || continue
    # Known patterns (canonicalized from the -e regex shapes in ci.yml)
    case "$pattern" in
      '\bmapfile\b')           : ;;
      '\bdeclare -A\b')        : ;;
      '\$\{[^}]*,,\}')         : ;;
      '\$\{[^}]*\^\^\}')       : ;;
      '\bcoproc\b')            : ;;
      '\bwait -n\b')           : ;;
      *)
        unknown="${unknown}  - ${pattern}
"
        ;;
    esac
  done < "$constructs_file"

  rm -f "$constructs_file"

  if [ -n "$unknown" ]; then
    printf 'New ban-list constructs found in ci.yml with no runtime snippet in this file:\n'
    printf '%s' "$unknown"
    printf 'Add a @test "[T19-ban] <construct> fails under bash:3.2" test for each.\n'
    return 1
  fi
}

# ---------------------------------------------------------------------------
# Shared helper loads and REPO_ROOT resolves.
# ---------------------------------------------------------------------------
@test "[T19-ban] shared helper loads and require_repo_root resolves REPO_ROOT" {
  require_repo_root
  [ -n "$REPO_ROOT" ]
  [ -d "$REPO_ROOT" ]
}
