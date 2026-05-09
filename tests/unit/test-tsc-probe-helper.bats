#!/usr/bin/env bats

setup_file() {
  REPO_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../.." && pwd -P)"
  export REPO_ROOT
}

@test "_shared/tsc-probe-helper.md exists" {
  [ -f "$REPO_ROOT/skills/_shared/tsc-probe-helper.md" ]
}

@test "tsc-probe-helper convention doc deprecates project-tsconfig-glob pattern" {
  run grep -E -i 'deprecat|do not use.*project tsconfig|racy' "$REPO_ROOT/skills/_shared/tsc-probe-helper.md"
  [ "$status" -eq 0 ]
}

@test "tsc-probe-helper convention doc names UUID-based filename pattern" {
  run grep -E -i 'uuid|unique|suffix' "$REPO_ROOT/skills/_shared/tsc-probe-helper.md"
  [ "$status" -eq 0 ]
}

@test "tsc-probe-helper convention doc points at templates/tsc-probe.ts" {
  run grep -F 'templates/tsc-probe.ts' "$REPO_ROOT/skills/_shared/tsc-probe-helper.md"
  [ "$status" -eq 0 ]
}

@test "templates/tsc-probe.ts exists" {
  [ -f "$REPO_ROOT/templates/tsc-probe.ts" ]
}

@test "templates/tsc-probe.ts exports tscProbe function" {
  run grep -E 'export.*function tscProbe|export.*tscProbe' "$REPO_ROOT/templates/tsc-probe.ts"
  [ "$status" -eq 0 ]
}

@test "templates/tsc-probe.ts writes a probe-specific tsconfig with only the probe file in include" {
  run grep -F 'tsconfig.probe-' "$REPO_ROOT/templates/tsc-probe.ts"
  [ "$status" -eq 0 ]
  run grep -F 'include' "$REPO_ROOT/templates/tsc-probe.ts"
  [ "$status" -eq 0 ]
}

@test "templates/tsc-probe.ts cleans up in finally" {
  run grep -E 'finally|unlinkSync' "$REPO_ROOT/templates/tsc-probe.ts"
  [ "$status" -eq 0 ]
}
