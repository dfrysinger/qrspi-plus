#!/usr/bin/env bats

# Coverage for T28 / G8: VERSION authoring path + build-plugin stamping.
#
# Per task spec (tasks/task-28.md § Test expectations):
#   - VERSION exists at repo root and contains exactly one version string.
#   - `echo "9.9.9" > VERSION && node tools/build-plugin.mjs && grep` matches
#     in all five consumer files.
#   - Build halts non-zero with the named diagnostic
#     `version-source-missing-or-malformed:` on missing-file, empty-file, and
#     multi-line cases (per design.md § Dependencies + edge cases bullet 1).
#   - `build/.claude-plugin/plugin.json` is updated by the build script (not
#     by hand) — proves sole-writer discipline for `build/`.

setup_file() {
  REPO_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../.." && pwd -P)"
  export REPO_ROOT
}

setup() {
  TMP_T28="$(mktemp -d)"
  WORK="$TMP_T28/repo"
  # Minimal sandbox: copy only the trees the build script consumes. Avoids
  # cp -R'ing the 70+ MB docs/ tree (not part of the build manifest) per
  # test, which would make this file dominate `bats -r tests` runtime.
  mkdir -p "$WORK"
  for d in skills agents scripts templates .claude-plugin .github tools; do
    if [ -d "$REPO_ROOT/$d" ]; then
      cp -R "$REPO_ROOT/$d" "$WORK/$d"
    fi
  done
  for f in LICENSE README.md AGENTS.md CLAUDE.md PROVENANCE.md VERSION; do
    if [ -f "$REPO_ROOT/$f" ]; then
      cp "$REPO_ROOT/$f" "$WORK/$f"
    fi
  done
  export WORK
}

teardown() {
  rm -rf "$TMP_T28"
}

@test "VERSION file exists at repo root with a single non-empty line" {
  [ -f "$REPO_ROOT/VERSION" ]
  # Single line, non-empty. `wc -l` counts trailing newlines; allow 0 or 1.
  raw="$(cat "$REPO_ROOT/VERSION")"
  [ -n "$raw" ]
  # No interior newlines.
  case "$raw" in
    *$'\n'*) return 1 ;;
  esac
}

@test "build script stamps VERSION into all five consumer manifests" {
  echo "9.9.9" > "$WORK/VERSION"
  run node "$WORK/tools/build-plugin.mjs" --root "$WORK"
  [ "$status" -eq 0 ]
  grep -F '"version": "9.9.9"' "$WORK/.claude-plugin/plugin.json"
  grep -F '"version": "9.9.9"' "$WORK/.claude-plugin/marketplace.json"
  grep -F '"version": "9.9.9"' "$WORK/.github/plugin/plugin.json"
  grep -F '"version": "9.9.9"' "$WORK/.github/plugin/marketplace.json"
  grep -F '"version": "9.9.9"' "$WORK/build/.claude-plugin/plugin.json"
}

@test "build halts non-zero with named diagnostic on missing VERSION" {
  rm -f "$WORK/VERSION"
  run node "$WORK/tools/build-plugin.mjs" --root "$WORK"
  [ "$status" -ne 0 ]
  [[ "$output" == *"version-source-missing-or-malformed:"* ]]
}

@test "build halts non-zero with named diagnostic on empty VERSION" {
  : > "$WORK/VERSION"
  run node "$WORK/tools/build-plugin.mjs" --root "$WORK"
  [ "$status" -ne 0 ]
  [[ "$output" == *"version-source-missing-or-malformed:"* ]]
}

@test "build halts non-zero with named diagnostic on whitespace-only VERSION" {
  printf "   \n" > "$WORK/VERSION"
  run node "$WORK/tools/build-plugin.mjs" --root "$WORK"
  [ "$status" -ne 0 ]
  [[ "$output" == *"version-source-missing-or-malformed:"* ]]
}

@test "build halts non-zero with named diagnostic on multi-line VERSION" {
  printf "0.7.3\n0.7.4\n" > "$WORK/VERSION"
  run node "$WORK/tools/build-plugin.mjs" --root "$WORK"
  [ "$status" -ne 0 ]
  [[ "$output" == *"version-source-missing-or-malformed:"* ]]
}

@test "build/.claude-plugin/plugin.json is produced by build (sole-writer discipline)" {
  echo "1.2.3" > "$WORK/VERSION"
  rm -rf "$WORK/build"
  run node "$WORK/tools/build-plugin.mjs" --root "$WORK"
  [ "$status" -eq 0 ]
  [ -f "$WORK/build/.claude-plugin/plugin.json" ]
  grep -F '"version": "1.2.3"' "$WORK/build/.claude-plugin/plugin.json"
}
