#!/usr/bin/env bats
#
# Plan-level acceptance / e2e tests for G8 (Centralized version source for
# the plugin manifest set).
#
# Maps to design.md § G8 Acceptance and plan.md Phase 1 Acceptance Criteria
# bullets 14-15 (VERSION at repo root is sole authoring path; single
# `node tools/build-plugin.mjs` propagates to all five consumer manifests;
# .github/plugin/* stays in lockstep with .claude-plugin/*).

setup_file() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")"/../../.. && pwd)"
  export REPO_ROOT
  export VERSION_FILE="$REPO_ROOT/VERSION"
  export BUILD_PLUGIN="$REPO_ROOT/tools/build-plugin.mjs"
}

@test "acceptance: VERSION file exists at repo root, contains exactly one non-empty line" {
  # G8 acceptance bullet 1.
  [ -f "$VERSION_FILE" ]
  lines=$(wc -l < "$VERSION_FILE" | tr -d ' ')
  # `wc -l` counts trailing newlines; expect 1 (canonical) or 0 (no trailing newline).
  [ "$lines" -le 1 ]
  v="$(tr -d '\n\r' < "$VERSION_FILE")"
  [ -n "$v" ]
  # Looks like a semver-ish triple.
  echo "$v" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+'
}

@test "acceptance: VERSION file value matches the v0.7.3 release tag" {
  # plan.md Phase 1 Acceptance bullet 15 — VERSION bumped to 0.7.3.
  v="$(tr -d '\n\r' < "$VERSION_FILE")"
  [ "$v" = "0.7.3" ]
}

@test "acceptance: all five consumer manifests exist on disk" {
  # design.md § G8 Solution — five consumer manifests stamped by build-plugin.mjs.
  [ -f "$REPO_ROOT/.claude-plugin/plugin.json" ]
  [ -f "$REPO_ROOT/.claude-plugin/marketplace.json" ]
  [ -f "$REPO_ROOT/.github/plugin/plugin.json" ]
  [ -f "$REPO_ROOT/.github/plugin/marketplace.json" ]
  [ -f "$REPO_ROOT/build/.claude-plugin/plugin.json" ]
}

@test "acceptance: every consumer manifest carries the same VERSION value (lockstep invariant)" {
  v="$(tr -d '\n\r' < "$VERSION_FILE")"
  for f in \
      "$REPO_ROOT/.claude-plugin/plugin.json" \
      "$REPO_ROOT/.claude-plugin/marketplace.json" \
      "$REPO_ROOT/.github/plugin/plugin.json" \
      "$REPO_ROOT/.github/plugin/marketplace.json" \
      "$REPO_ROOT/build/.claude-plugin/plugin.json"; do
    grep -qF "\"$v\"" "$f" || {
      echo "consumer manifest $f does not carry VERSION=$v" >&2
      grep -E '"version"' "$f" >&2 || true
      false
    }
  done
}

@test "acceptance: .github/plugin/* and .claude-plugin/* are in lockstep on the version field" {
  # plan.md Phase 1 Acceptance bullet 15: .github/plugin/* in lockstep with .claude-plugin/*.
  cp_p="$(grep '"version"' "$REPO_ROOT/.claude-plugin/plugin.json" | head -1)"
  gh_p="$(grep '"version"' "$REPO_ROOT/.github/plugin/plugin.json" | head -1)"
  [ "$cp_p" = "$gh_p" ]
}

@test "acceptance: tools/build-plugin.mjs reads VERSION (not a hardcoded literal)" {
  # G8 acceptance bullet 2 — build script is the sole stamper.
  [ -f "$BUILD_PLUGIN" ]
  grep -qE "readFileSync\(.*VERSION|path\.join\([^)]*'VERSION'\)" "$BUILD_PLUGIN"
}

@test "acceptance: build-plugin.mjs halts named version-source-missing-or-malformed on empty/multiline VERSION" {
  # G8 acceptance bullet 4 — fail-loud direction; grep the diagnostic string.
  grep -qF 'version-source-missing-or-malformed' "$BUILD_PLUGIN"
}

@test "acceptance: build-then-diff CI workflow file exists (G8 CI gate)" {
  # plan.md T29 / Phase 1 Acceptance bullet 15 — CI step runs build && git diff --exit-code.
  [ -f "$REPO_ROOT/.github/workflows/build-then-diff.yml" ]
  grep -qE 'build-plugin\.mjs' "$REPO_ROOT/.github/workflows/build-then-diff.yml"
  grep -qE 'git diff --exit-code' "$REPO_ROOT/.github/workflows/build-then-diff.yml"
}

@test "acceptance: release runbook documents VERSION as the single authoring path (G8 bullet 5)" {
  runbook="$REPO_ROOT/docs/release-runbook.md"
  [ -f "$runbook" ]
  grep -qF 'VERSION' "$runbook"
  grep -qF 'build-plugin.mjs' "$runbook"
}
