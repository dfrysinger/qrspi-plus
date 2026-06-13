#!/usr/bin/env bats
#
# T8 — Cache-mechanism retirement invariants (Phase 1 acceptance).
#
# This file is the external (non-self-referential) gate on the prompt-cache
# mechanism retirement performed by task-08. It greps neighbor artifacts —
# never itself — and asserts:
#
#   * Filesystem absence of the four deleted artifacts
#     (TE1: scripts/g4-cache-probe.sh,
#      TE2: docs/qrspi/2026-05-17-v07-release/spikes/g4-cache-probe.md,
#      TE3: tests/unit/test-cache-control-capability-gate.bats,
#      TE4: tests/unit/test-cache-hit-rate.bats).
#
#   * Content-level retirement in skills/using-qrspi/SKILL.md
#     (TE5: no cache_control / supports_prompt_cache /
#      emit_cache_control_markers literal strings remain after T8).
#
#   * Structural retirement in tests/unit/test-run-third-party-llm.bats
#     (TE8: no `@test "cache_control gate` truth-table blocks remain after T8).
#
#   * SPIKE/run_pin absence in tests/acceptance/v07-phase1/test-phase1-acceptance.bats
#     (TE9: SPIKE= export to the deleted spike file and run_pin invocations
#      pointing at the deleted unit suites are gone after T8). Greps the
#      neighbor file from outside — eliminates the self-referential grep
#      antipattern that would otherwise force the assertion to grep its own
#      bytes.
#
#   * G6 host-detection assertions still present in test-phase1-acceptance.bats
#     (TE10: the COPILOT_CLI=1 (Copilot CLI) and COPILOT_CLI-unset (Claude
#      Code) acceptance assertions added by Task 7 are NOT collateral-damaged
#      by the T8 mechanical removal pass).
#
# Bash 3.2 portable: no mapfile, no declare -A, no ${var,,}, no coproc.

setup_file() {
  # Resolve repo root from THIS file's location (tests/acceptance/v07-phase1/),
  # matching the neighbor test-phase1-acceptance.bats convention. Bats may be
  # invoked from a sibling worktree; do not rely on cwd.
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"
  export REPO_ROOT
  export PHASE1_ACCEPTANCE="$REPO_ROOT/tests/acceptance/v07-phase1/test-phase1-acceptance.bats"
  export DISPATCHER_PIN="$REPO_ROOT/tests/unit/test-run-third-party-llm.bats"
  export USING_QRSPI_SKILL="$REPO_ROOT/skills/using-qrspi/SKILL.md"
}

# ---------------------------------------------------------------------------
# TE1–TE4: Filesystem absence of the four deleted artifacts.
# ---------------------------------------------------------------------------

@test "scripts/g4-cache-probe.sh is absent from the repository" {
  # Test expectation: scripts/g4-cache-probe.sh does not exist in the
  # repository after the task completes (filesystem absence)
  [ ! -e "$REPO_ROOT/scripts/g4-cache-probe.sh" ]
}

@test "docs/qrspi/2026-05-17-v07-release/spikes/g4-cache-probe.md is absent from the repository" {
  # Test expectation: docs/qrspi/2026-05-17-v07-release/spikes/g4-cache-probe.md
  # does not exist in the repository after the task completes (filesystem absence)
  [ ! -e "$REPO_ROOT/docs/qrspi/2026-05-17-v07-release/spikes/g4-cache-probe.md" ]
}

@test "tests/unit/test-cache-control-capability-gate.bats is absent from the repository" {
  # Test expectation: tests/unit/test-cache-control-capability-gate.bats does
  # not exist in the repository after the task completes (filesystem absence)
  [ ! -e "$REPO_ROOT/tests/unit/test-cache-control-capability-gate.bats" ]
}

@test "tests/unit/test-cache-hit-rate.bats is absent from the repository" {
  # Test expectation: tests/unit/test-cache-hit-rate.bats does not exist in
  # the repository after the task completes (filesystem absence)
  [ ! -e "$REPO_ROOT/tests/unit/test-cache-hit-rate.bats" ]
}

# ---------------------------------------------------------------------------
# TE5: skills/using-qrspi/SKILL.md contains no cache_control /
# supports_prompt_cache / emit_cache_control_markers literal strings.
#
# Three independent literal-string greps; word-boundary regex (-w) keeps the
# assertion sharp and avoids partial collisions with adjacent identifiers.
# ---------------------------------------------------------------------------

@test "skills/using-qrspi/SKILL.md contains no cache_control literal" {
  # Test expectation: skills/using-qrspi/SKILL.md contains no references to
  # cache_control [...] after modification
  [ -f "$USING_QRSPI_SKILL" ]
  run grep -nwE 'cache_control' "$USING_QRSPI_SKILL"
  [ "$status" -ne 0 ]
}

@test "skills/using-qrspi/SKILL.md contains no supports_prompt_cache literal" {
  # Test expectation: skills/using-qrspi/SKILL.md contains no references to
  # [...] supports_prompt_cache [...] after modification
  [ -f "$USING_QRSPI_SKILL" ]
  run grep -nwE 'supports_prompt_cache' "$USING_QRSPI_SKILL"
  [ "$status" -ne 0 ]
}

@test "skills/using-qrspi/SKILL.md contains no emit_cache_control_markers literal" {
  # Test expectation: skills/using-qrspi/SKILL.md contains no references to
  # [...] emit_cache_control_markers after modification
  [ -f "$USING_QRSPI_SKILL" ]
  run grep -nwE 'emit_cache_control_markers' "$USING_QRSPI_SKILL"
  [ "$status" -ne 0 ]
}

# ---------------------------------------------------------------------------
# TE8: tests/unit/test-run-third-party-llm.bats contains no cache-control
# truth-table @test blocks after modification.
#
# Pattern targets the literal `@test "cache_control gate` prefix used by the
# four truth-table tests (false,false), (true,false), (false,true), (true,true).
# Anchored at column 1 to avoid matching incidental occurrences inside
# helper bodies or commit-message scratch lines.
# ---------------------------------------------------------------------------

@test "tests/unit/test-run-third-party-llm.bats contains no '@test \"cache_control gate' truth-table blocks" {
  # Test expectation: tests/unit/test-run-third-party-llm.bats contains no
  # cache-control truth-table test blocks after modification
  [ -f "$DISPATCHER_PIN" ]
  run grep -nE '^@test "cache_control gate' "$DISPATCHER_PIN"
  [ "$status" -ne 0 ]
}

# ---------------------------------------------------------------------------
# TE9: tests/acceptance/v07-phase1/test-phase1-acceptance.bats contains
# (a) no SPIKE variable export referencing the deleted spike report, and
# (b) no run_pin invocations referencing the deleted unit suite files.
#
# Greps the neighbor file from OUTSIDE — this is the load-bearing
# self-reference elimination required by the spec (the previous design grep'd
# its own file body, producing a tautological pass when the assertion text
# itself contained the forbidden token).
# ---------------------------------------------------------------------------

@test "tests/acceptance/v07-phase1/test-phase1-acceptance.bats contains no SPIKE export referencing the deleted spike report" {
  # Test expectation: test-phase1-acceptance.bats contains no SPIKE variable
  # export referencing the deleted spike file after modification
  [ -f "$PHASE1_ACCEPTANCE" ]
  # Match `SPIKE=` (assignment or export) on any line that also references
  # the deleted spike file path. Both sides must be on the same line, which
  # is the exact shape the deletion target uses.
  run grep -nE 'SPIKE=.*g4-cache-probe\.md' "$PHASE1_ACCEPTANCE"
  [ "$status" -ne 0 ]
}

@test "tests/acceptance/v07-phase1/test-phase1-acceptance.bats contains no run_pin invocations referencing the deleted capability-gate suite" {
  # Test expectation: no run_pin invocations referencing the deleted suite
  # files after modification (test-cache-control-capability-gate.bats)
  [ -f "$PHASE1_ACCEPTANCE" ]
  run grep -nE 'run_pin[[:space:]].*test-cache-control-capability-gate' "$PHASE1_ACCEPTANCE"
  [ "$status" -ne 0 ]
}

@test "tests/acceptance/v07-phase1/test-phase1-acceptance.bats contains no run_pin invocations referencing the deleted cache-hit-rate suite" {
  # Test expectation: no run_pin invocations referencing the deleted suite
  # files after modification (test-cache-hit-rate.bats)
  [ -f "$PHASE1_ACCEPTANCE" ]
  run grep -nE 'run_pin[[:space:]].*test-cache-hit-rate' "$PHASE1_ACCEPTANCE"
  [ "$status" -ne 0 ]
}

# ---------------------------------------------------------------------------
# TE10: After T8 modifications, test-phase1-acceptance.bats STILL contains the
# G6 host-detection assertions added by T7. The mechanical removal pass for
# T8 (SPIKE export, two run_pin lines, Slice 7 C-5 test body) must not
# collateral-delete the T7 / TE5 and T7 / TE6 assertion blocks.
#
# We grep for the load-bearing tokens that uniquely identify each block:
#   * positive (Copilot CLI): the COPILOT_CLI=1 path emits
#     `[transport: task-tool]` exactly once.
#   * negative (Claude Code): the COPILOT_CLI-unset path emits
#     `[transport: shell-pipeline]` exactly once.
# ---------------------------------------------------------------------------

@test "tests/acceptance/v07-phase1/test-phase1-acceptance.bats still contains the G6 COPILOT_CLI=1 host-detection assertion (T7 / TE5 preserved)" {
  # Test expectation: After Task 8 modifications, test-phase1-acceptance.bats
  # still contains the G6 host-detection acceptance assertions added by
  # Task 7 (specifically, the COPILOT_CLI=1 Copilot CLI path assertion)
  [ -f "$PHASE1_ACCEPTANCE" ]
  # Anchored at the @test header for the T7 / TE5 block; matches the unique
  # `T7 / TE5` tag + COPILOT_CLI=1 phrase from the test name.
  run grep -nF '[T7 / TE5] dispatch surface: COPILOT_CLI=1 path emits [transport: task-tool]' "$PHASE1_ACCEPTANCE"
  [ "$status" -eq 0 ]
}

@test "tests/acceptance/v07-phase1/test-phase1-acceptance.bats still contains the G6 COPILOT_CLI-unset host-detection assertion (T7 / TE6 preserved)" {
  # Test expectation: After Task 8 modifications, test-phase1-acceptance.bats
  # still contains the G6 host-detection acceptance assertions added by
  # Task 7 (specifically, the COPILOT_CLI unset Claude Code path assertion)
  [ -f "$PHASE1_ACCEPTANCE" ]
  run grep -nF '[T7 / TE6] dispatch surface: COPILOT_CLI-unset path emits [transport: shell-pipeline]' "$PHASE1_ACCEPTANCE"
  [ "$status" -eq 0 ]
}

# ===========================================================================
# T39 / G32 — built-tree strip/copy invariants and shipped-file invariants.
#
# Per docs/qrspi/2026-05-30-v072-release/structure.md
# §`tests/acceptance/v07-phase1/test-cache-retirement-invariants.bats`
# (Slice 1.7) and tasks/task-39.md §"Test expectations":
#
#   - build/ exists with manifest-driven content and the fixed include list.
#   - build/skills/goals/SKILL.md contains inlined skills/goals/owns-defers.md
#     content with no remaining `!cat` directive for that include.
#   - build/skills/_shared/prompt-prose-detection.md exists (defensive copy).
#   - build/docs/, build/tools/, build/tests/ do NOT exist.
#   - scripts/ ships in full.
#   - Zero ${CLAUDE_SKILL_DIR} occurrences in shipped files (under build/).
#   - tools/render-skill.sh and tools/g4-section-anchor-refresh.sh exist;
#     scripts/render-skill.sh and scripts/g4-section-anchor-refresh.sh gone.
# ===========================================================================

@test "build/ tree exists at the repo root" {
  [ -d "$REPO_ROOT/build" ]
}

@test "build/skills/goals/SKILL.md exists and contains inlined owns-defers.md content" {
  local built="$REPO_ROOT/build/skills/goals/SKILL.md"
  local source="$REPO_ROOT/skills/goals/owns-defers.md"
  [ -f "$built" ]
  [ -f "$source" ]
  # Pick a stable, non-trivial token from owns-defers.md and assert it landed
  # inline in the built SKILL.md.
  run grep -F 'Goals OWNS' "$source"
  [ "$status" -eq 0 ]
  run grep -F 'Goals OWNS' "$built"
  [ "$status" -eq 0 ]
}

@test "build/skills/goals/SKILL.md retains NO !cat directive for owns-defers.md" {
  local built="$REPO_ROOT/build/skills/goals/SKILL.md"
  [ -f "$built" ]
  run grep -F '!cat skills/goals/owns-defers.md' "$built"
  [ "$status" -ne 0 ]
}

@test "build/skills/goals/SKILL.md retains NO !cat directives at all (full transitive expansion)" {
  local built="$REPO_ROOT/build/skills/goals/SKILL.md"
  [ -f "$built" ]
  # Strict whole-line bare-relative grammar: `^\s*!cat <relpath>\s*$`.
  run grep -E '^[[:space:]]*!cat[[:space:]]+[A-Za-z0-9_./-]+[[:space:]]*$' "$built"
  [ "$status" -ne 0 ]
}

@test "build/skills/_shared/prompt-prose-detection.md exists (defensive shared-snippet copy)" {
  [ -f "$REPO_ROOT/build/skills/_shared/prompt-prose-detection.md" ]
}

@test "build/docs/ does NOT exist (dev-only path stripped)" {
  [ ! -e "$REPO_ROOT/build/docs" ]
}

@test "build/tools/ does NOT exist (dev-only path stripped)" {
  [ ! -e "$REPO_ROOT/build/tools" ]
}

@test "build/tests/ does NOT exist (dev-only path stripped)" {
  [ ! -e "$REPO_ROOT/build/tests" ]
}

@test "build/scripts/ exists (scripts/ ships in full as runtime)" {
  [ -d "$REPO_ROOT/build/scripts" ]
}

@test "build/templates/ exists (fixed include list)" {
  [ -d "$REPO_ROOT/build/templates" ]
}

@test "build/.claude-plugin/ exists (manifest ships)" {
  [ -d "$REPO_ROOT/build/.claude-plugin" ]
  [ -f "$REPO_ROOT/build/.claude-plugin/plugin.json" ]
}

@test "build/LICENSE and build/README.md exist (fixed include list)" {
  [ -f "$REPO_ROOT/build/LICENSE" ]
  [ -f "$REPO_ROOT/build/README.md" ]
}

@test "zero \${CLAUDE_SKILL_DIR} occurrences in shipped files under build/" {
  [ -d "$REPO_ROOT/build" ]
  # Search across the entire build/ tree; any hit is a regression.
  run bash -c "grep -RF '\${CLAUDE_SKILL_DIR}' '$REPO_ROOT/build' || true"
  [ -z "$output" ]
}

@test "zero \${CLAUDE_SKILL_DIR} occurrences in source skills/ either (legacy sites converted)" {
  # Source-side cleanup invariant — every legacy site converted to bare form.
  run bash -c "grep -RF '\${CLAUDE_SKILL_DIR}' '$REPO_ROOT/skills' || true"
  [ -z "$output" ]
}

@test "tools/render-skill.sh exists at the new path" {
  [ -f "$REPO_ROOT/tools/render-skill.sh" ]
}

@test "tools/g4-section-anchor-refresh.sh exists at the new path" {
  [ -f "$REPO_ROOT/tools/g4-section-anchor-refresh.sh" ]
}

@test "scripts/render-skill.sh has been removed from the old path" {
  [ ! -e "$REPO_ROOT/scripts/render-skill.sh" ]
}

@test "scripts/g4-section-anchor-refresh.sh has been removed from the old path" {
  [ ! -e "$REPO_ROOT/scripts/g4-section-anchor-refresh.sh" ]
}

@test "no remaining caller references to scripts/render-skill.sh in source tree" {
  # Tightened pattern (R3 fix tc-F02): match invocation forms only — `bash
  # scripts/render-skill.sh` or `./scripts/render-skill.sh`. Bare path
  # strings in historical narrative no longer false-positive, but actual
  # stale callers do. `--exclude-dir=docs` is intentionally dropped so docs
  # that document today's workflow are gated against pointing at the
  # retired path. `--exclude-dir=fixtures` and `--exclude-dir=tests` remain
  # because the tests subtree carries this assertion's own bytes plus
  # neighbor RED-test name strings that legitimately reference the legacy
  # path.
  run bash -c "grep -RnE --exclude-dir=build --exclude-dir=reviews --exclude-dir=.git --exclude-dir=fixtures --exclude-dir=tests '(bash[[:space:]]+|\\./)scripts/render-skill\\.sh' '$REPO_ROOT' || true"
  [ -z "$output" ]
}

@test "no remaining caller references to scripts/g4-section-anchor-refresh.sh in source tree" {
  # Tightened pattern (R3 fix tc-F02): see neighbor render-skill.sh test.
  run bash -c "grep -RnE --exclude-dir=build --exclude-dir=reviews --exclude-dir=.git --exclude-dir=fixtures --exclude-dir=tests '(bash[[:space:]]+|\\./)scripts/g4-section-anchor-refresh\\.sh' '$REPO_ROOT' || true"
  [ -z "$output" ]
}
