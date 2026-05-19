#!/usr/bin/env bats
bats_require_minimum_version 1.5.0

# Task 19 (pin 1 of 2) — G17: CI workflow shape pin
#
# Asserts .github/workflows/ci.yml parses as valid YAML, declares the
# documented two-job lint/bash32 surface, trigger block, concurrency,
# SHA-pinned actions, and security invariant (no direct ${{ github.ref }}
# interpolation inside run: steps).
#
# Bash 3.2 portable: no mapfile, no declare -A, no ${var,,}, no coproc,
# no wait -n.

load '../helpers/skill-markdown'

setup_file() {
  require_repo_root
  CI_YML="$REPO_ROOT/.github/workflows/ci.yml"
  export CI_YML
}

# ---------------------------------------------------------------------------
# Parse: ci.yml must parse as valid YAML (yq exits 0 on valid YAML)
# ---------------------------------------------------------------------------
@test "[T19-shape] ci.yml parses as valid YAML via yq" {
  require_repo_root
  [ -f "$CI_YML" ]
  run yq '.' "$CI_YML"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Job count: exactly two jobs (lint and bash32)
# ---------------------------------------------------------------------------
@test "[T19-shape] ci.yml declares exactly two jobs" {
  require_repo_root
  [ -f "$CI_YML" ]
  run yq '.jobs | keys | length' "$CI_YML"
  [ "$status" -eq 0 ]
  [ "$output" = "2" ]
}

@test "[T19-shape] ci.yml has a job named 'lint'" {
  require_repo_root
  [ -f "$CI_YML" ]
  run yq '.jobs.lint | tag' "$CI_YML"
  [ "$status" -eq 0 ]
  [ "$output" != "null" ]
}

@test "[T19-shape] ci.yml has a job named 'bash32'" {
  require_repo_root
  [ -f "$CI_YML" ]
  run yq '.jobs.bash32 | tag' "$CI_YML"
  [ "$status" -eq 0 ]
  [ "$output" != "null" ]
}

# ---------------------------------------------------------------------------
# Both jobs run on ubuntu-latest
# ---------------------------------------------------------------------------
@test "[T19-shape] lint job runs on ubuntu-latest" {
  require_repo_root
  [ -f "$CI_YML" ]
  run yq '.jobs.lint["runs-on"]' "$CI_YML"
  [ "$status" -eq 0 ]
  [ "$output" = "ubuntu-latest" ]
}

@test "[T19-shape] bash32 job runs on ubuntu-latest" {
  require_repo_root
  [ -f "$CI_YML" ]
  run yq '.jobs.bash32["runs-on"]' "$CI_YML"
  [ "$status" -eq 0 ]
  [ "$output" = "ubuntu-latest" ]
}

# ---------------------------------------------------------------------------
# lint job: carries shellcheck step and Option B ban-list step
# ---------------------------------------------------------------------------
@test "[T19-shape] lint job has a shellcheck step" {
  require_repo_root
  [ -f "$CI_YML" ]
  run grep -c "shellcheck" "$CI_YML"
  [ "$status" -eq 0 ]
  [ "$output" -ge 1 ]
}

@test "[T19-shape] lint job has the Option B ban-list grep step" {
  require_repo_root
  [ -f "$CI_YML" ]
  run grep -c "Option B ban-list" "$CI_YML"
  [ "$status" -eq 0 ]
  [ "$output" -ge 1 ]
}

# ---------------------------------------------------------------------------
# bash32 job: launches bash:3.2 Docker image pinned by sha256 digest
# ---------------------------------------------------------------------------
@test "[T19-shape] bash32 job container image is bash:3.2 pinned by sha256 digest" {
  require_repo_root
  [ -f "$CI_YML" ]
  local image
  image="$(yq '.jobs.bash32.container.image' "$CI_YML")"
  # Must start with bash:3.2 and contain @sha256:
  case "$image" in
    bash:3.2@sha256:*) ;;
    *) printf 'Container image must be bash:3.2@sha256:<digest>; got: %s\n' "$image" >&2
       return 1 ;;
  esac
}

# ---------------------------------------------------------------------------
# bash32 job: runs both unit and acceptance BATS suites
# ---------------------------------------------------------------------------
@test "[T19-shape] bash32 job runs unit BATS suite" {
  require_repo_root
  [ -f "$CI_YML" ]
  run grep -c "tests/unit" "$CI_YML"
  [ "$status" -eq 0 ]
  [ "$output" -ge 1 ]
}

@test "[T19-shape] bash32 job runs acceptance BATS suite" {
  require_repo_root
  [ -f "$CI_YML" ]
  run grep -c "tests/acceptance" "$CI_YML"
  [ "$status" -eq 0 ]
  [ "$output" -ge 1 ]
}

# ---------------------------------------------------------------------------
# on: trigger block — push to main, qrspi/**, */issue-*, PR to main
# ---------------------------------------------------------------------------
@test "[T19-shape] on: trigger covers push to main" {
  require_repo_root
  [ -f "$CI_YML" ]
  # Branches list under push must include main
  run grep -E "^\s+- main$" "$CI_YML"
  [ "$status" -eq 0 ]
}

@test "[T19-shape] on: trigger covers push to qrspi/**" {
  require_repo_root
  [ -f "$CI_YML" ]
  run grep -F "qrspi/**" "$CI_YML"
  [ "$status" -eq 0 ]
}

@test "[T19-shape] on: trigger covers push to */issue-*" {
  require_repo_root
  [ -f "$CI_YML" ]
  run grep -F "*/issue-*" "$CI_YML"
  [ "$status" -eq 0 ]
}

@test "[T19-shape] on: trigger covers pull_request to main" {
  require_repo_root
  [ -f "$CI_YML" ]
  run grep -E "pull_request:" "$CI_YML"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# concurrency block: keyed on github.ref with cancel-in-progress: true
# ---------------------------------------------------------------------------
@test "[T19-shape] concurrency block is keyed on github.ref" {
  require_repo_root
  [ -f "$CI_YML" ]
  run grep -E "github\.ref" "$CI_YML"
  [ "$status" -eq 0 ]
}

@test "[T19-shape] concurrency block has cancel-in-progress: true" {
  require_repo_root
  [ -f "$CI_YML" ]
  run grep -E "cancel-in-progress:\s+true" "$CI_YML"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Every third-party action is pinned to a commit SHA (no floating tags).
# Scan `uses:` lines for non-SHA pins.
# ---------------------------------------------------------------------------
@test "[T19-shape] every action uses: reference is pinned to a commit SHA" {
  require_repo_root
  [ -f "$CI_YML" ]
  # Collect all `uses:` action references
  # A SHA-pinned action looks like: actions/checkout@<40-hex-chars>
  # A floating tag looks like: actions/checkout@v4 or @main or @latest
  # We check that no `uses:` line has a tag that is NOT a 40-hex SHA.
  # Uses lines with SHA contain @[0-9a-f]{40}
  local bad_uses
  bad_uses="$(grep -E '^\s+uses:\s+' "$CI_YML" | grep -Ev '@[0-9a-f]{40}' || true)"
  if [ -n "$bad_uses" ]; then
    printf 'Found action(s) not pinned to commit SHA:\n%s\n' "$bad_uses" >&2
    return 1
  fi
}

# ---------------------------------------------------------------------------
# Security: no direct ${{ github.event. / github.head_ref / github.ref }}
# interpolation inside run: steps (injection vector).
# The concurrency.group field is exempt (string field, not shell command).
# ---------------------------------------------------------------------------
@test "[T19-shape] no run: step contains direct github.event. context interpolation" {
  require_repo_root
  [ -f "$CI_YML" ]
  # Extract only run: block content (lines after `run: |` or `run: >`) and
  # check for the literal ${{ github.event. pattern.
  local hits
  hits="$(grep -n '\${{ *github\.event\.' "$CI_YML" || true)"
  if [ -n "$hits" ]; then
    printf 'Direct github.event. interpolation in workflow (injection risk):\n%s\n' "$hits" >&2
    return 1
  fi
}

@test "[T19-shape] no run: step contains direct github.head_ref context interpolation" {
  require_repo_root
  [ -f "$CI_YML" ]
  local hits
  hits="$(grep -n '\${{ *github\.head_ref' "$CI_YML" || true)"
  if [ -n "$hits" ]; then
    printf 'Direct github.head_ref interpolation in workflow (injection risk):\n%s\n' "$hits" >&2
    return 1
  fi
}

@test "[T19-shape] no run: step contains direct github.ref context interpolation (outside concurrency block)" {
  require_repo_root
  [ -f "$CI_YML" ]
  # The concurrency.group field is a string field (not a shell command), so
  # github.ref in that field is exempt. We only flag github.ref inside run: blocks.
  # Strategy: check that any line with ${{ github.ref is NOT inside a run: block.
  # A simplified heuristic: if ${{ github.ref appears on a line that is not
  # part of the concurrency block, flag it.
  local hits
  hits="$(grep -n '\${{ *github\.ref' "$CI_YML" | grep -v 'group:' || true)"
  if [ -n "$hits" ]; then
    printf 'Direct github.ref interpolation outside concurrency.group (injection risk):\n%s\n' "$hits" >&2
    return 1
  fi
}

# ---------------------------------------------------------------------------
# Shared helper loads and REPO_ROOT resolves.
# ---------------------------------------------------------------------------
@test "[T19-shape] shared helper loads and require_repo_root resolves REPO_ROOT" {
  require_repo_root
  [ -n "$REPO_ROOT" ]
  [ -d "$REPO_ROOT" ]
}
