#!/usr/bin/env bats

# Task 29 / G8 — .github/workflows/build-then-diff.yml CI gate.
#
# Covers Test Expectations from tasks/task-29.md:
#   - The CI step runs `node tools/build-plugin.mjs && git diff --exit-code`
#     and fails on any divergence (G8 Acceptance bullet 3, first half).
#   - A fixture commit that hand-edits `"version"` in one consumer file
#     (without bumping VERSION) causes the CI step to fail (G8 Acceptance
#     bullet 3, second half).
#   - A non-version drift fixture commit causes the CI step to fail —
#     hand-editing a non-`"version"` field (e.g. `"description"`) in
#     `build/.claude-plugin/plugin.json` without re-running the build
#     script (coverage-codex R4-F02 — proves the gate catches the entire
#     build-artifact-drift class, not version-only drift).
#   - The workflow triggers on every PR (pull_request event configured).
#   - Workflow failure output names the diverging file(s) (named-diagnostic
#     discipline via `git diff --exit-code`'s natural output).
#   - Happy-path success: a fixture commit where the committed `build/`
#     tree exactly matches the source tree (post-`node tools/build-plugin.mjs`
#     shape) passes the CI step — exit 0, no divergence diagnostic
#     (R6-F03 — gate is observably reachable in the no-drift case).
#
# Test expectation: each `@test` is annotated inline to its bullet.

setup_file() {
  REPO_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../.." && pwd -P)"
  export REPO_ROOT
  WORKFLOW="$REPO_ROOT/.github/workflows/build-then-diff.yml"
  export WORKFLOW
}

# ---------------------------------------------------------------------------
# Fixture helpers — stage a self-contained source tree the build script can
# walk, init a git repo, run the build to produce a no-drift baseline, and
# commit. Each behavioral @test then mutates that baseline and runs the
# workflow's documented command sequence.
# ---------------------------------------------------------------------------

setup() {
  TMP_T29="$(mktemp -d)"
  WORK="$TMP_T29/repo"
  mkdir -p "$WORK"
  # Copy only trees the build script reads — mirrors test-version-stamping's
  # sandbox so the fixture isolates from docs/ and other non-build content.
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

  # Produce a no-drift baseline: build, then commit the full tree (source +
  # build/ output). After this, `node tools/build-plugin.mjs && git diff
  # --exit-code` must exit 0 unless something drifts.
  ( cd "$WORK" && node "$WORK/tools/build-plugin.mjs" --root "$WORK" >/dev/null )
  ( cd "$WORK" \
      && git init -q \
      && git -c user.email=t29@example.invalid -c user.name=t29 add -A \
      && git -c user.email=t29@example.invalid -c user.name=t29 commit -q -m baseline )
  export WORK
}

teardown() {
  rm -rf "$TMP_T29"
}

# Extract the canonical workflow `run:` command string from the build-then-diff
# step. Centralized so every behavioral test exercises whatever the workflow
# actually ships, not a hand-restated copy. If the workflow file is missing or
# the step is absent, yq returns null/non-zero and the caller fails.
_t29_extract_workflow_run() {
  yq -r '
    .jobs[]
    | .steps[]?
    | select(.run | test("node\\s+tools/build-plugin\\.mjs.*git\\s+diff\\s+--exit-code"))
    | .run
  ' "$WORKFLOW" 2>/dev/null | head -1
}

# Run the workflow's command string inside the fixture repo.
_t29_run_workflow_step() {
  local run_cmd
  run_cmd="$(_t29_extract_workflow_run)"
  if [ -z "$run_cmd" ]; then
    printf 'build-then-diff workflow run-step not extractable from %s\n' "$WORKFLOW" >&2
    return 127
  fi
  ( cd "$WORK" && bash -c "$run_cmd" )
}

# ===========================================================================
# Static workflow-shape pins.
# ===========================================================================

# Test expectation: "A new CI workflow ... `.github/workflows/build-then-diff.yml`"
@test "build-then-diff.yml exists at .github/workflows/" {
  [ -f "$WORKFLOW" ]
}

# Test expectation: workflow parses as valid YAML (yq exits 0).
@test "build-then-diff.yml parses as valid YAML" {
  [ -f "$WORKFLOW" ]
  run yq '.' "$WORKFLOW"
  [ "$status" -eq 0 ]
}

# Test expectation: "The workflow triggers on every PR (not only on release
# branches) — pull_request event configured."
@test "build-then-diff.yml triggers on pull_request" {
  [ -f "$WORKFLOW" ]
  run yq -r '.on | has("pull_request")' "$WORKFLOW"
  [ "$status" -eq 0 ]
  [ "$output" = "true" ]
}

# Test expectation: "triggers on every PR (not only on release branches)" —
# if the pull_request trigger filters branches, it must include `main` (or
# omit `branches` entirely / use a `**` wildcard) so every PR is in scope.
@test "build-then-diff.yml pull_request trigger is not restricted to release branches only" {
  [ -f "$WORKFLOW" ]
  # If `branches:` is absent the trigger fires on every PR — accept that shape.
  run bash -c "yq -r '.on.pull_request.branches // \"__none__\"' '$WORKFLOW'"
  [ "$status" -eq 0 ]
  if [ "$output" = "__none__" ] || [ "$output" = "null" ]; then
    return 0
  fi
  # Otherwise the branches list MUST include main or a wildcard — a list of
  # only `release/*` / `qrspi/**` would scope the gate too narrowly and miss
  # PRs targeting main, which is the scope the spec mandates.
  run yq -r '.on.pull_request.branches[]' "$WORKFLOW"
  [ "$status" -eq 0 ]
  echo "$output" | grep -E -x '(main|\*\*|\*)' >/dev/null
}

# Test expectation: "The CI step ... runs `node tools/build-plugin.mjs && git
# diff --exit-code`". The literal command (in some run: step) is the gate.
@test "build-then-diff.yml contains the documented build-then-diff command" {
  [ -f "$WORKFLOW" ]
  local run_cmd
  run_cmd="$(_t29_extract_workflow_run)"
  [ -n "$run_cmd" ]
  # Substring sanity: command sequences both halves with &&.
  echo "$run_cmd" | grep -F 'node tools/build-plugin.mjs' >/dev/null
  echo "$run_cmd" | grep -F 'git diff --exit-code' >/dev/null
}

# Test expectation: workflow declares at least one job whose step carries the
# build-then-diff command — anchors the gate inside an executable job, not a
# floating top-level fragment.
@test "build-then-diff.yml job hosts the build-then-diff step" {
  [ -f "$WORKFLOW" ]
  run yq -r '
    [ .jobs[]
      | .steps[]?
      | select(.run | test("node\\s+tools/build-plugin\\.mjs.*git\\s+diff\\s+--exit-code"))
    ] | length
  ' "$WORKFLOW"
  [ "$status" -eq 0 ]
  [ "$output" -ge 1 ]
}

# ===========================================================================
# Behavioral fixture pins — run the workflow's actual `run:` block inside a
# fixture repo. RED until the workflow exists (run-step extraction returns
# empty, helper returns 127). Post-implementation, these exercise the gate's
# end-to-end semantics.
# ===========================================================================

# Test expectation (R6-F03 happy path): "a fixture commit where the committed
# `build/` tree exactly matches the source tree ... passes the CI step —
# `git diff --exit-code` returns 0, the workflow exits 0, and no divergence
# diagnostic is emitted."
@test "build-then-diff CI step exits 0 on a clean baseline (no-drift)" {
  run _t29_run_workflow_step
  [ "$status" -eq 0 ]
  # No-drift case: git diff --exit-code emits no path-naming output.
  [ -z "$output" ] || ! echo "$output" | grep -E '^(diff --git|---|\+\+\+) ' >/dev/null
}

# Test expectation: "a fixture commit that hand-edits `\"version\"` in one
# consumer file (without bumping VERSION) causes the CI step to fail".
@test "build-then-diff CI step fails when a consumer's \"version\" is hand-edited (VERSION unchanged)" {
  # Hand-edit version in one source consumer; commit the bad state.
  # On rebuild, build-plugin re-stamps the consumer from VERSION → working-tree
  # value differs from the (bad) committed value → git diff --exit-code fires.
  python3 -c "
import json, sys
p = '$WORK/.github/plugin/plugin.json'
with open(p) as f: d = json.load(f)
d['version'] = '9.9.9-handedit'
with open(p, 'w') as f: json.dump(d, f, indent=2)
" || sed -i.bak 's/"version": *"[^"]*"/"version": "9.9.9-handedit"/' "$WORK/.github/plugin/plugin.json"
  ( cd "$WORK" \
      && git -c user.email=t29@example.invalid -c user.name=t29 add -A \
      && git -c user.email=t29@example.invalid -c user.name=t29 commit -q -m "drift: hand-edit version" )
  run _t29_run_workflow_step
  [ "$status" -ne 0 ]
  # Named-diagnostic discipline: failure output identifies the diverging file.
  echo "$output" | grep -F '.github/plugin/plugin.json' >/dev/null
}

# Test expectation (R4-F02 non-version drift): "a fixture commit that
# hand-edits a non-`\"version\"` field in `build/.claude-plugin/plugin.json`
# (e.g., flipping a `\"description\"` string) without re-running the build
# script ... the build-then-diff step must fail" — proves the gate catches
# the entire build-artifact-drift class, not version-only drift.
@test "build-then-diff CI step fails when build/.claude-plugin/plugin.json description is hand-edited" {
  python3 -c "
import json
p = '$WORK/build/.claude-plugin/plugin.json'
with open(p) as f: d = json.load(f)
d['description'] = 'HAND-EDITED-DRIFT-MARKER'
with open(p, 'w') as f: json.dump(d, f, indent=2)
" || sed -i.bak 's/"description": *"[^"]*"/"description": "HAND-EDITED-DRIFT-MARKER"/' "$WORK/build/.claude-plugin/plugin.json"
  ( cd "$WORK" \
      && git -c user.email=t29@example.invalid -c user.name=t29 add -A \
      && git -c user.email=t29@example.invalid -c user.name=t29 commit -q -m "drift: build/ description flip" )
  run _t29_run_workflow_step
  [ "$status" -ne 0 ]
  # Named-diagnostic discipline: failure output identifies the diverging file.
  echo "$output" | grep -F 'build/.claude-plugin/plugin.json' >/dev/null
}

# Test expectation: "Workflow failure output names the diverging file(s)
# (named-diagnostic discipline via `git diff --exit-code`'s natural output)."
# Cross-check at a separate drift surface (source manifest, not build/) so the
# named-diagnostic pin is not over-fit to a single fixture path.
@test "build-then-diff failure output names the diverging file (named-diagnostic discipline)" {
  python3 -c "
import json
p = '$WORK/.claude-plugin/plugin.json'
with open(p) as f: d = json.load(f)
d['description'] = 'SOURCE-DRIFT-MARKER'
with open(p, 'w') as f: json.dump(d, f, indent=2)
" || sed -i.bak 's/"description": *"[^"]*"/"description": "SOURCE-DRIFT-MARKER"/' "$WORK/.claude-plugin/plugin.json"
  ( cd "$WORK" \
      && git -c user.email=t29@example.invalid -c user.name=t29 add -A \
      && git -c user.email=t29@example.invalid -c user.name=t29 commit -q -m "drift: source description flip" )
  run _t29_run_workflow_step
  [ "$status" -ne 0 ]
  # The rebuilt build/.claude-plugin/plugin.json copies the source's edited
  # description → diff names build/.claude-plugin/plugin.json. Either the
  # source path or its build/ copy appearing in the diff satisfies the
  # named-diagnostic contract (the gate must point at SOME diverging file).
  echo "$output" | grep -E '(\.claude-plugin/plugin\.json|build/\.claude-plugin/plugin\.json)' >/dev/null
}
