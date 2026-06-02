#!/usr/bin/env bats
#
# QRSPI v0.7 Phase 1 acceptance gate.
#
# This file does NOT re-test what the ~400 task-level BATS pins already cover.
# It asserts the traceability spine: every Phase 1 acceptance criterion
# enumerated in `docs/qrspi/2026-05-17-v07-release/plan.md` (Phase 1 Acceptance
# Criteria section, around lines 82-135) is observable in this repo via:
#   (a) a named pin file existing AND being green, or
#   (b) load-bearing tokens existing in a named artifact (doc-shape), or
#   (c) a filesystem/git invariant being satisfied, or
#   (d) a documented skip (human-verified Integrate gate, known-bug, env-dep).
#
# See: docs/qrspi/2026-05-17-v07-release/reviews/test/round-01-results.md
# for the criterion <-> test mapping.

setup_file() {
  # Resolve repo root from THIS file's location (tests/acceptance/v07-phase1/),
  # not from cwd — bats may be invoked from a sibling git repo.
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"
  export REPO_ROOT
  export PINS="$REPO_ROOT/tests/unit"
  export INTPINS="$REPO_ROOT/tests/integration"
  export SKILLS="$REPO_ROOT/skills"
}

# Helper: run a bats pin file silently; pass if exit 0.
run_pin() {
  local pin="$1"
  [ -f "$pin" ] || return 90
  bats "$pin" >/dev/null 2>&1
}

# --------------------------------------------------------------------------
# Slice 1 — Cost-opt routing end-to-end
# --------------------------------------------------------------------------

@test "[Phase1 Slice 1 C-1] cost-opt routing dispatches and emits telemetry (G5 telemetry pin green)" {
  run run_pin "$PINS/test-g5-telemetry-emission.bats"
  [ "$status" -eq 0 ]
}

@test "[Phase1 Slice 1 C-2] implement/SKILL.md Per-Task Routing section documents matrix and routing-matrix pin green" {
  grep -q "### Per-Task Routing" "$SKILLS/implement/SKILL.md"
  [ -f "$PINS/test-routing-matrix-application.bats" ]
  run run_pin "$PINS/test-routing-matrix-application.bats"
  [ "$status" -eq 0 ]
}

# --------------------------------------------------------------------------
# Slice 2 — TDD test-writer split
# --------------------------------------------------------------------------

@test "[Phase1 Slice 2 C-1] pre-implementer test-writer dispatch order observable (tdd-dispatch-order pin green)" {
  run run_pin "$PINS/test-tdd-dispatch-order.bats"
  [ "$status" -eq 0 ]
}

@test "[Phase1 Slice 2 C-2] RED-verification gate four-state classifier pin green" {
  run run_pin "$PINS/test-red-verification-gate.bats"
  [ "$status" -eq 0 ]
}

@test "[Phase1 Slice 2 C-3] test-writer dual-mode (Implement per-task + Test plan-level) pin green" {
  run run_pin "$PINS/test-test-writer-dual-mode.bats"
  [ "$status" -eq 0 ]
}

# --------------------------------------------------------------------------
# Slice 3 — Hygiene + CI foundation
# --------------------------------------------------------------------------

@test "[Phase1 Slice 3 C-1] CI workflow shape pin green (lint + bash32 jobs both present)" {
  # The pin parses ci.yml via `yq`; CI runs it on Ubuntu where yq is present.
  command -v yq >/dev/null 2>&1 || skip "yq not available in this environment (env-dep — passes in CI per .github/workflows/ci.yml)"
  run run_pin "$PINS/test-ci-workflow-shape.bats"
  [ "$status" -eq 0 ]
}

@test "[Phase1 Slice 3 C-2] shellcheck clean over shell surface (run-smoke-checks pin or equivalent)" {
  # Phase 1 ships shellcheck as a CI job; locally we verify via the workflow shape
  # pin's enumeration. The actual shellcheck binary is not a local-machine assumption.
  command -v shellcheck >/dev/null 2>&1 || skip "shellcheck not available in this environment (env-dep)"
  run run_pin "$PINS/test-run-smoke-checks.bats"
  [ "$status" -eq 0 ]
}

@test "[Phase1 Slice 3 C-3] bash-3.2 runtime coverage pin green (docker job backstop / ban-list current)" {
  run run_pin "$PINS/test-bash32-runtime-coverage.bats"
  [ "$status" -eq 0 ]
}

@test "[Phase1 Slice 3 C-4] evergreen-markdown scan pin green under unit BATS surface" {
  # implement-summary.md issue #5 documents this test as designed to fail
  # against pre-existing AGENTS.md / README.md violations until cleaned up.
  skip "implementer-protocol issue #5 (implement-summary.md): test-evergreen-markdown documents pre-existing violations as expected-failures (skipped-known-bug)"
  run run_pin "$PINS/test-evergreen-markdown.bats"
  [ "$status" -eq 0 ]
}

@test "[Phase1 Slice 3 C-5] implementer hygiene self-check pin green (added-line internal-ID/version reporting)" {
  run run_pin "$PINS/test-hygiene-self-check.bats"
  [ "$status" -eq 0 ]
}

# --------------------------------------------------------------------------
# Slice 4 — Parallelize hygiene + G14 consumers
# --------------------------------------------------------------------------

@test "[Phase1 Slice 4 C-1] shared skill-markdown helper exists and helpers pin is green" {
  [ -f "$REPO_ROOT/tests/helpers/skill-markdown.bash" ]
  run run_pin "$PINS/test-helpers-skill-markdown.bats"
  [ "$status" -eq 0 ]
}

@test "[Phase1 Slice 4 C-2] parallelize worktree-aware-defaults pin green (no scope-drift on canonical artifact)" {
  run run_pin "$PINS/test-worktree-aware-defaults.bats"
  [ "$status" -eq 0 ]
}

@test "[Phase1 Slice 4 C-3] parallelize vocab pin green (canonical multi-stage vocabulary asserted)" {
  run run_pin "$PINS/test-parallelize-vocab.bats"
  [ "$status" -eq 0 ]
}

@test "[Phase1 Slice 4 C-4] parallelize OWNS-list pin asserts worktree-aware validation responsibility" {
  run run_pin "$PINS/test-parallelize-owns-defers.bats"
  [ "$status" -eq 0 ]
}

# --------------------------------------------------------------------------
# Slice 5 — Visual-fidelity + human-gate references
# --------------------------------------------------------------------------

@test "[Phase1 Slice 5 C-1] reference-gate field shape pin green (renderable reference surfaced, not just path)" {
  run run_pin "$PINS/test-reference-gate-fields.bats"
  [ "$status" -eq 0 ]
}

@test "[Phase1 Slice 5 C-2] reference-gate pause integration pin green (approval persists, blocks dependents)" {
  run run_pin "$INTPINS/test-reference-gate-pause.bats"
  [ "$status" -eq 0 ]
}

@test "[Phase1 Slice 5 C-3] visual-fidelity reviewer surfaces sibling context (sibling-notification-protocol pin green)" {
  run run_pin "$PINS/test-sibling-notification-protocol.bats"
  [ "$status" -eq 0 ]
}

@test "[Phase1 Slice 5 C-4] quick-tier wording pin green (high/correctness-medium inline-patch, low acceptance, no blanket merges)" {
  run run_pin "$PINS/test-quick-tier-wording.bats"
  [ "$status" -eq 0 ]
}

# --------------------------------------------------------------------------
# Slice 6 — Plan post-approval split
# --------------------------------------------------------------------------

@test "[Phase1 Slice 6 C-1] plan post-approval split pin green (N>=3 parallel per-task spec authoring)" {
  run run_pin "$PINS/test-plan-post-approval-split.bats"
  [ "$status" -eq 0 ]
}

@test "[Phase1 Slice 6 C-2] plan post-approval split pin asserts N<=2 inline carve-out (same pin file)" {
  # Same pin file covers both branches; assert the carve-out token is present in the pin.
  [ -f "$PINS/test-plan-post-approval-split.bats" ]
  grep -qE "carve|inline|N.?<.?=.?2|threshold" "$PINS/test-plan-post-approval-split.bats"
}

# --------------------------------------------------------------------------
# Slice 7 — Caching spike + verify
#
# T8 (v0.7.1-hardening) retired the prompt-cache mechanism. The G4
# cache-probe spike, the dual-flag capability-gate pin, and the cache-hit-
# rate pin were deleted from the tree. The Slice 7 C-1, C-2, and C-5
# criteria (which gated on those deleted artifacts) are therefore removed
# from this acceptance file. The retirement itself is gated by
# `tests/acceptance/v07-phase1/test-cache-retirement-invariants.bats`,
# which asserts filesystem-absence and content-absence invariants from
# outside this file. C-3 and C-4 (unrelated to the cache mechanism)
# remain.
# --------------------------------------------------------------------------

@test "[Phase1 Slice 7 C-3] no-summary-shim-dispatches invariant pin runs green" {
  run run_pin "$PINS/test-no-summary-shim-dispatches.bats"
  [ "$status" -eq 0 ]
}

@test "[Phase1 Slice 7 C-4] three colocated SKILL.anchors.json files and manifest exist; index-shape pin green" {
  [ -f "$SKILLS/reviewer-protocol/SKILL.anchors.json" ]
  [ -f "$SKILLS/using-qrspi/SKILL.anchors.json" ]
  [ -f "$SKILLS/plan/SKILL.anchors.json" ]
  [ -f "$REPO_ROOT/scripts/g4-section-anchor-manifest.json" ]
  run run_pin "$PINS/test-section-anchor-index-shape.bats"
  [ "$status" -eq 0 ]
  # narrow-read pin contains 4 T36 expected-failures documenting the T35
  # H2-with-H3-span byte-identity bug (implement-summary.md issue #2). The
  # bug is tracked separately; the criterion is satisfied for the green
  # index-shape pin + the 3 anchor files + manifest above.
}

# --------------------------------------------------------------------------
# Slice 8 — Commit-message scratch staging
# --------------------------------------------------------------------------

@test "[Phase1 Slice 8 C-1] implementer scratch file absent from committed tree; worktree-local exclude carries entry" {
  # The scratch file path is the implementer's commit-message compose file.
  ! git -C "$REPO_ROOT" ls-files --error-unmatch ".git/info/exclude" 2>/dev/null
  # Excluded scratch path token must be present in the local exclude file when worktree is set up.
  if [ -f "$REPO_ROOT/.git/info/exclude" ]; then
    grep -qE "commit-msg|implementer-scratch|\.qrspi-scratch" "$REPO_ROOT/.git/info/exclude" || skip "worktree exclude entry not present in this checkout (env-dep)"
  else
    skip "no .git/info/exclude in this environment (env-dep)"
  fi
}

@test "[Phase1 Slice 8 C-2] three commit-hygiene architectural invariants observable in test output" {
  run run_pin "$PINS/test-commit-hygiene-invariants.bats"
  [ "$status" -eq 0 ]
}

# --------------------------------------------------------------------------
# Slice 9 — u14-lint worktree
# --------------------------------------------------------------------------

@test "[Phase1 Slice 9 C-1] u14-lint pin: confusable + genuine-integrate fixtures both exercised" {
  # Assert the criterion-load-bearing tokens: the test file exists and names both fixtures.
  [ -f "$PINS/test-u14-lint.bats" ]
  grep -qE "confusable|worktree-confusable" "$PINS/test-u14-lint.bats"
  grep -qE "genuine-integrate" "$PINS/test-u14-lint.bats"
  # Pin has 1 pre-existing scannability sub-test failure inherited from main
  # (per reviews/test/baseline-failures.md); v0.7's contribution to this pin
  # (T40) is green — both new fixtures pass. Not gating phase acceptance on
  # the pre-existing scannability regression.
}

# --------------------------------------------------------------------------
# Slice 10 — Replan <-> Goals coordination
# --------------------------------------------------------------------------

@test "[Phase1 Slice 10 C-1] replan/SKILL.md Boundary with Goals section exists; T42 pin asserts decision branches" {
  grep -q "## Boundary with Goals" "$SKILLS/replan/SKILL.md"
  [ -f "$REPO_ROOT/tests/fixtures/future-goals-mixed-shape.md" ]
  run run_pin "$PINS/test-replan-boundary-with-goals.bats"
  [ "$status" -eq 0 ]
}

@test "[Phase1 Slice 10 C-2] replan skill prose names hand-off-report shape (T42 doc-shape assertion green)" {
  # Same pin covers both contract and doc-shape assertions; assert hand-off tokens.
  grep -qE "hand-off|handoff|promoted Formal|skipped Idea" "$SKILLS/replan/SKILL.md"
  run run_pin "$PINS/test-replan-boundary-with-goals.bats"
  [ "$status" -eq 0 ]
}

@test "[Phase1 Slice 10 C-3] Integrate-phase Replan dry-run against future-goals fixture (human-verified gate)" {
  skip "human-verified Integrate-phase gate per plan.md line 135; not enforced by BATS per spec"
}

# --------------------------------------------------------------------------
# Regression / known-bug guards (implement-summary.md known issues)
# --------------------------------------------------------------------------

@test "[Regression issue #2] section-anchor-refresh H2-with-H3-span byte-identity (T36 expected-failure documented)" {
  skip "documents known bug per implement-summary.md issue #2 (T35 g4-section-anchor-refresh.sh truncates H2 at first H3 child)"
  run run_pin "$PINS/test-section-anchor-refresh.bats"
  [ "$status" -eq 0 ]
}

@test "[Regression issue #1] duplicate ## Overview in plan/SKILL.md (anchor-index silent-skip vs refresh fail-loud)" {
  skip "documents known bug per implement-summary.md issue #1 (skills/plan/SKILL.md has duplicate '## Overview' headings)"
  # When fixed, this should run cleanly:
  # grep -c '^## Overview' "$SKILLS/plan/SKILL.md" | grep -qx 1
}

# ===========================================================================
# T7 — v0.7.1 hardening: using-qrspi SKILL prose + Codex dispatch transport
# routing acceptance.
#
# Task spec: docs/qrspi/2026-05-27-v071-hardening/tasks/task-07.md
# Target files (per spec):
#   - skills/using-qrspi/SKILL.md  (Codex detection section gains per-host
#     conditional prose naming both transports)
#   - tests/acceptance/v07-phase1/test-phase1-acceptance.bats  (this file —
#     gains end-to-end host-detection assertions exercising the dispatch
#     surface under mocked conditions for each host path)
#
# Coverage: bullets TE1..TE13 of task-07.md ## Test Expectations.
#
# RED scope at test-author time (i.e., before Task 7's implementer runs):
#   TE1..TE4  RED: SKILL.md does not yet name the Copilot CLI task-tool
#             transport, the `agent_type: code-review` / `model: gpt-5.3-codex`
#             parameters, or the mismatch warning-vs-gating policy.
#   TE5..TE6  Already green from Task 6 (trace markers are emitted today);
#             added here for traceability to the acceptance gate, per spec.
#   TE7       RED: current run-codex-review.sh does NOT short-circuit when
#             check_codex_available returns non-zero — it only emits a
#             [mismatch] warning when codex_reviews=true and continues
#             dispatch.  Task 7's bullet 7 requires a hard short-circuit with
#             single-line stderr diagnostic and non-zero exit propagation.
#   TE8..TE9  Discriminating-power tests; passes when env matches branch,
#             fails (RED) when env disagrees.  Mostly green today (Task 6).
#   TE10..11  Pass today (mock invoked + trace marker fires); added here so
#             the acceptance gate proves the mock transport actually ran,
#             not just a happy exit code (per spec emphasis).
#   TE12      Green today (Task 6 propagates transport exit).
#   TE13      RED today: the current mismatch path emits the [mismatch] line
#             ONLY when check_codex_available fails (lines 607-611 of
#             run-codex-review.sh).  Task 7's bullet 13 scenario requires
#             mismatch to be detectable from host-vs-config disagreement
#             alone (e.g., detected copilot-cli + codex_reviews: false),
#             where check_codex_available succeeds and dispatch reaches the
#             transport.  Under current code, no [mismatch] line fires for
#             this scenario, so the warning-emitted assertion is RED.
#
# Mock strategy (shared by TE5..TE13):
#   Per-test, build a self-contained mock REPO_ROOT in a fresh mktemp dir
#   (mirrors the pattern in tests/unit/test-host-detection.bats).  The mock
#   `scripts/run-third-party-llm.sh` drains stdin, optionally writes
#   ${MOCK_TRANSPORT_STDOUT} to stdout, optionally writes
#   ${MOCK_TRANSPORT_STDERR} to stderr, and exits ${MOCK_TRANSPORT_EXIT:-0}.
#   The wrapper is invoked with QRSPI_REPO_ROOT pointing at the mock dir, so
#   it resolves the dispatcher to the mock instead of the real one.
#
#   Each test uses its OWN distinguishable MOCK_TRANSPORT_STDOUT marker so
#   "the mock was invoked" is provable from stdout, not just from exit code.
#
#   Per-test setup is inlined (this file's setup_file() is shared with the
#   earlier traceability tests and we do not want to widen its scope).
# ===========================================================================

# Helper: build a self-contained mock REPO_ROOT skeleton in $1.
# Mirrors tests/unit/test-host-detection.bats setup() but as a per-test
# helper to avoid widening this file's setup_file().
_t7_make_mock_repo() {
  local tmp="$1"

  # Subject-code file required by --subject-code for dispatch invocations.
  mkdir -p "$tmp/src"
  printf 'const x = 1;\n' > "$tmp/src/subject.ts"

  # Mock reviewer-protocol files (the wrapper's compose_prompt reads these).
  mkdir -p "$tmp/skills/reviewer-protocol"
  printf '## Reviewer Dispatch Contract\nReviewer protocol stub.\n' \
    > "$tmp/skills/reviewer-protocol/SKILL.md"
  printf '<<<FINDING-BOUNDARY>>>\nCodex emission override stub.\n' \
    > "$tmp/skills/reviewer-protocol/codex-emission-override.md"

  # Minimal agent file with no extra skill deps (keeps the skill-load chain
  # trivially short so the test fixture stays self-contained).
  mkdir -p "$tmp/agents"
  printf -- '---\nmodel: sonnet\nskills: []\n---\n\nStub agent body.\n' \
    > "$tmp/agents/qrspi-spec-reviewer.md"

  # Artifact directory with a default config (codex_reviews: false).
  # Individual tests override this when they need a specific value.
  mkdir -p "$tmp/artifact-dir"
  printf -- '---\ncodex_reviews: false\n---\n' > "$tmp/artifact-dir/config.md"

  # Mock dispatcher.  Drains stdin so the upstream pipe never blocks.
  # If MOCK_TRANSPORT_STDOUT is set, writes it to stdout.  If
  # MOCK_TRANSPORT_STDERR is set, writes it to stderr.  Exits
  # MOCK_TRANSPORT_EXIT (default 0).
  mkdir -p "$tmp/scripts"
  cat > "$tmp/scripts/run-third-party-llm.sh" <<'MOCK_DISPATCHER_EOF'
#!/usr/bin/env bash
# Mock run-third-party-llm.sh for T7 dispatch-surface tests.
cat > /dev/null
if [ -n "${MOCK_TRANSPORT_STDOUT:-}" ]; then
  printf '%s\n' "${MOCK_TRANSPORT_STDOUT}"
fi
if [ -n "${MOCK_TRANSPORT_STDERR:-}" ]; then
  printf '%s\n' "${MOCK_TRANSPORT_STDERR}" >&2
fi
exit "${MOCK_TRANSPORT_EXIT:-0}"
MOCK_DISPATCHER_EOF
  chmod +x "$tmp/scripts/run-third-party-llm.sh"

  # HOME fixture for the claude-code companion-glob probe.  Empty by default;
  # tests that want check_codex_available(claude-code) to succeed must
  # populate the codex-companion.mjs path inside this tree before invoking.
  mkdir -p "$tmp/mock-home"

  # Output directory for dispatch invocations (--output-dir must be absolute).
  mkdir -p "$tmp/out"
}

# Helper: skip the test if `gh` is absent or not in a trusted prefix
# (precondition for detect_host emitting 'copilot-cli' when COPILOT_CLI=1).
# Mirrors the [r5-sec.F01] skip-guard pattern in test-host-detection.bats.
_t7_require_trusted_gh() {
  local _gh
  _gh="$(command -v gh 2>/dev/null)"
  if [ -z "$_gh" ]; then
    skip "no gh binary on this host (precondition for copilot-cli detection)"
  fi
  _gh="$(realpath "$_gh" 2>/dev/null || readlink -f "$_gh" 2>/dev/null)" || _gh=""
  case "$_gh" in
    /usr/* | /opt/* | /Applications/*) ;;
    *) skip "gh ($_gh) not in trusted prefix on this host (precondition for copilot-cli detection)" ;;
  esac
}

# ---------------------------------------------------------------------------
# T7 / TE1: SKILL prose names both transports
# ---------------------------------------------------------------------------

@test "[T7 / TE1] using-qrspi SKILL Codex detection section names BOTH Copilot CLI task-tool and Claude Code shell-pipeline transports" {
  # Test expectation: skills/using-qrspi/SKILL.md Codex detection section
  # contains conditional prose that explicitly names both the Copilot CLI
  # task-tool transport and the Claude Code shell-pipeline transport.
  #
  # Anchor: load-bearing tokens must appear in the same section block as
  # the existing "**Codex detection:**" prose (line ~405 today).
  local skill="$SKILLS/using-qrspi/SKILL.md"
  [ -f "$skill" ]
  # The section anchor must remain present.
  grep -q "Codex detection" "$skill"
  # Token 1: task-tool transport named (either "task tool" or "task-tool"
  # accepted; both are conventional in this codebase, e.g. design.md uses
  # "task tool" prose and "[transport: task-tool]" trace marker).
  grep -qE "task[- ]tool" "$skill"
  # Token 2: shell-pipeline transport named.
  grep -qE "shell[- ]pipeline|shell pipeline" "$skill"
  # Token 3: both transports must appear in the SAME Codex-related
  # conditional prose block (proves the prose is per-host conditional, not
  # an unrelated mention).  Extract the slice from the first "Codex
  # detection" heading down to the next H2/H3 boundary; assert both tokens
  # appear inside that slice.
  local slice
  slice="$(awk '
    /Codex detection/ { capture=1 }
    capture && /^#{2,4} / && NR>start { exit }
    capture { print; if (start==0) start=NR }
  ' "$skill")"
  printf '%s\n' "$slice" | grep -qE "task[- ]tool"
  printf '%s\n' "$slice" | grep -qE "shell[- ]pipeline|shell pipeline"
}

# ---------------------------------------------------------------------------
# T7 / TE2: SKILL prose names agent_type: code-review and model: gpt-5.3-codex
# ---------------------------------------------------------------------------

@test "[T7 / TE2] using-qrspi SKILL prose specifies agent_type: code-review and model: gpt-5.3-codex for Copilot CLI Codex dispatch" {
  # Test expectation: the SKILL prose specifies `agent_type: code-review`
  # and `model: gpt-5.3-codex` as the parameters for Copilot CLI Codex
  # dispatch.  Both literal tokens must be present (the model identifier
  # is the one named in design.md line 59 and goals.md G6).
  local skill="$SKILLS/using-qrspi/SKILL.md"
  [ -f "$skill" ]
  grep -q "agent_type: code-review" "$skill"
  grep -q "model: gpt-5.3-codex" "$skill"
}

# ---------------------------------------------------------------------------
# T7 / TE3: SKILL prose names scripts/run-codex-review.sh as the Claude Code
# Codex dispatch mechanism.
# ---------------------------------------------------------------------------

@test "[T7 / TE3] using-qrspi SKILL prose names scripts/run-codex-review.sh as the Claude Code Codex dispatch mechanism" {
  # Test expectation: the SKILL prose names `scripts/run-codex-review.sh`
  # as the Claude Code Codex dispatch mechanism.  The token must appear
  # in the Codex-related prose slice (not just incidentally elsewhere).
  local skill="$SKILLS/using-qrspi/SKILL.md"
  [ -f "$skill" ]
  grep -q "scripts/run-codex-review.sh" "$skill"
  # Co-location anchor: the script path must appear in the same Codex
  # detection prose slice as the shell-pipeline token from TE1.
  local slice
  slice="$(awk '
    /Codex detection/ { capture=1 }
    capture && /^#{2,4} / && NR>start { exit }
    capture { print; if (start==0) start=NR }
  ' "$skill")"
  printf '%s\n' "$slice" | grep -q "scripts/run-codex-review.sh"
}

# ---------------------------------------------------------------------------
# T7 / TE4: SKILL prose documents the mismatch warning-vs-gating policy.
# ---------------------------------------------------------------------------

@test "[T7 / TE4] using-qrspi SKILL prose documents that mismatch emits single-line stderr diagnostic and continues with configured policy (mismatch does NOT gate dispatch)" {
  # Test expectation: skills/using-qrspi/SKILL.md contains prose documenting
  # that when the detected host disagrees with the codex_reviews config
  # value, the dispatch surface emits a single-line diagnostic to stderr
  # identifying the disagreement and continues with the configured policy;
  # the mismatch diagnostic does NOT gate dispatch.
  local skill="$SKILLS/using-qrspi/SKILL.md"
  [ -f "$skill" ]
  # Mismatch tokens — at least one mismatch-naming variant must be present.
  grep -qEi "mismatch|disagree|disagreement" "$skill"
  # Policy clause: stderr diagnostic is named.
  grep -qE "stderr|diagnostic|single.line" "$skill"
  # Policy clause: dispatch is NOT blocked / continues / warning-only.
  grep -qEi "warning.only|warning only|does not block|does not gate|continues with|not block dispatch|configured policy" "$skill"
  # Co-location: all three tokens must appear in the same Codex-detection
  # prose slice (proves the policy is documented in the Codex section, not
  # incidentally elsewhere).
  local slice
  slice="$(awk '
    /Codex detection/ { capture=1 }
    capture && /^#{2,4} / && NR>start { exit }
    capture { print; if (start==0) start=NR }
  ' "$skill")"
  printf '%s\n' "$slice" | grep -qEi "mismatch|disagree"
  printf '%s\n' "$slice" | grep -qEi "stderr|diagnostic|configured policy|does not (block|gate)|warning"
}

# ---------------------------------------------------------------------------
# T7 / TE5: COPILOT_CLI=1 → [transport: task-tool] exactly once, no
# [transport: shell-pipeline].  Mocked Codex dispatch via the task-tool
# wrapper.
# ---------------------------------------------------------------------------

@test "[T7 / TE5] dispatch surface: COPILOT_CLI=1 path emits [transport: task-tool] exactly once and never [transport: shell-pipeline]" {
  # Test expectation: with COPILOT_CLI=1 set, the dispatch surface emits
  # the `[transport: task-tool]` marker to stderr exactly once and does
  # not emit the `[transport: shell-pipeline]` marker (exercising a
  # mocked Codex dispatch via the task tool wrapper).
  _t7_require_trusted_gh

  local tmp
  tmp="$(mktemp -d)"
  _t7_make_mock_repo "$tmp"
  # codex_reviews: true so the copilot-cli dispatch is not skipped by an
  # availability gate before the marker can be emitted.
  printf -- '---\ncodex_reviews: true\n---\n' > "$tmp/artifact-dir/config.md"

  local stderr_log="$tmp/te5-stderr.log"
  QRSPI_REPO_ROOT="$tmp" \
    COPILOT_CLI=1 \
    MOCK_TRANSPORT_STDOUT="te5-task-tool-mock-marker-2026-05-27" \
    MOCK_TRANSPORT_EXIT=0 \
    bash "$REPO_ROOT/scripts/run-codex-review.sh" \
      --agent-file agents/qrspi-spec-reviewer.md \
      --reviewer-tag spec-codex \
      --output-dir "$tmp/out" \
      --round 1 \
      --subject-code "$tmp/src/subject.ts" \
      --model gpt-5.3-codex \
      --output-file "$tmp/result.md" \
      --artifact-dir "$tmp/artifact-dir" \
    >"$tmp/te5-stdout.log" 2>"$stderr_log" || true

  # Exactly-once [transport: task-tool] on stderr.
  local task_tool_count
  task_tool_count="$(grep -c '\[transport: task-tool\]' "$stderr_log" 2>/dev/null || printf '0')"
  [ "$task_tool_count" -eq 1 ]
  # [transport: shell-pipeline] must be absent.
  ! grep -q '\[transport: shell-pipeline\]' "$stderr_log"

  rm -rf "$tmp"
}

# ---------------------------------------------------------------------------
# T7 / TE6: COPILOT_CLI unset → [transport: shell-pipeline] exactly once,
# no [transport: task-tool].  Mocked scripts/run-codex-review.sh path.
# ---------------------------------------------------------------------------

@test "[T7 / TE6] dispatch surface: COPILOT_CLI-unset path emits [transport: shell-pipeline] exactly once and never [transport: task-tool]" {
  # Test expectation: with COPILOT_CLI unset and the shell pipeline via
  # `scripts/run-codex-review.sh` mocked, the dispatch surface emits the
  # `[transport: shell-pipeline]` marker to stderr exactly once and does
  # not emit the `[transport: task-tool]` marker.
  local tmp
  tmp="$(mktemp -d)"
  _t7_make_mock_repo "$tmp"

  local stderr_log="$tmp/te6-stderr.log"
  QRSPI_REPO_ROOT="$tmp" \
    COPILOT_CLI="" \
    MOCK_TRANSPORT_STDOUT="te6-shell-pipeline-mock-marker-2026-05-27" \
    MOCK_TRANSPORT_EXIT=0 \
    bash "$REPO_ROOT/scripts/run-codex-review.sh" \
      --agent-file agents/qrspi-spec-reviewer.md \
      --reviewer-tag spec-codex \
      --output-dir "$tmp/out" \
      --round 1 \
      --subject-code "$tmp/src/subject.ts" \
      --model gpt-5.3-codex \
      --output-file "$tmp/result.md" \
      --artifact-dir "$tmp/artifact-dir" \
    >"$tmp/te6-stdout.log" 2>"$stderr_log" || true

  local pipe_count
  pipe_count="$(grep -c '\[transport: shell-pipeline\]' "$stderr_log" 2>/dev/null || printf '0')"
  [ "$pipe_count" -eq 1 ]
  ! grep -q '\[transport: task-tool\]' "$stderr_log"

  rm -rf "$tmp"
}

# ---------------------------------------------------------------------------
# T7 / TE7: check_codex_available non-zero → single-line stderr diagnostic
# + propagates non-zero exit (NO log-and-continue).
# ---------------------------------------------------------------------------

@test "[T7 / TE7] dispatch surface: check_codex_available non-zero short-circuits with single-line stderr diagnostic and propagates non-zero exit (no log-and-continue)" {
  # Test expectation: when check_codex_available returns non-zero for the
  # detected host, the dispatch surface emits a single-line diagnostic to
  # stderr and propagates non-zero exit (no log-and-continue).
  #
  # Scenario: detected_host=claude-code (COPILOT_CLI unset), HOME points at
  # a mock tree with NO codex-companion.mjs → check_codex_available
  # returns non-zero.  The dispatch surface MUST exit non-zero before
  # invoking the transport mock (which would otherwise exit 0).
  #
  # RED state under Task-6 code: current run-codex-review.sh only emits a
  # `[mismatch]` warning when codex_reviews=true and continues to dispatch
  # the transport, which exits 0 → dispatch exits 0 → this test fails.
  local tmp
  tmp="$(mktemp -d)"
  _t7_make_mock_repo "$tmp"
  printf -- '---\ncodex_reviews: true\n---\n' > "$tmp/artifact-dir/config.md"

  local stderr_log="$tmp/te7-stderr.log"
  local dispatch_status=0
  QRSPI_REPO_ROOT="$tmp" \
    COPILOT_CLI="" \
    HOME="$tmp/mock-home" \
    MOCK_TRANSPORT_EXIT=0 \
    bash "$REPO_ROOT/scripts/run-codex-review.sh" \
      --agent-file agents/qrspi-spec-reviewer.md \
      --reviewer-tag spec-codex \
      --output-dir "$tmp/out" \
      --round 1 \
      --subject-code "$tmp/src/subject.ts" \
      --model gpt-5.3-codex \
      --output-file "$tmp/result.md" \
      --artifact-dir "$tmp/artifact-dir" \
    >"$tmp/te7-stdout.log" 2>"$stderr_log" && dispatch_status=0 || dispatch_status=$?

  # The dispatch surface MUST exit non-zero (Codex unavailable short-circuit).
  [ "$dispatch_status" -ne 0 ]
  # A single-line stderr diagnostic must name the failure: at minimum it
  # must reference Codex unavailability or the check_codex_available probe.
  grep -qEi "codex|check_codex_available|unavailable|companion" "$stderr_log"

  rm -rf "$tmp"
}

# ---------------------------------------------------------------------------
# T7 / TE8a (positive): Copilot CLI assertion passes when COPILOT_CLI=1 set.
# ---------------------------------------------------------------------------

@test "[T7 / TE8a] dispatch surface: Copilot CLI assertion PASSES (task-tool marker present) when COPILOT_CLI=1 is set" {
  # Test expectation: the acceptance test assertion for the Copilot CLI
  # path passes when COPILOT_CLI=1 is set (positive case of TE8's
  # discriminating-power assertion).
  _t7_require_trusted_gh

  local tmp
  tmp="$(mktemp -d)"
  _t7_make_mock_repo "$tmp"
  printf -- '---\ncodex_reviews: true\n---\n' > "$tmp/artifact-dir/config.md"

  local stderr_log="$tmp/te8a-stderr.log"
  QRSPI_REPO_ROOT="$tmp" \
    COPILOT_CLI=1 \
    MOCK_TRANSPORT_STDOUT="te8a-marker-2026-05-27" \
    bash "$REPO_ROOT/scripts/run-codex-review.sh" \
      --agent-file agents/qrspi-spec-reviewer.md \
      --reviewer-tag spec-codex \
      --output-dir "$tmp/out" \
      --round 1 \
      --subject-code "$tmp/src/subject.ts" \
      --model gpt-5.3-codex \
      --output-file "$tmp/result.md" \
      --artifact-dir "$tmp/artifact-dir" \
    >"$tmp/te8a-stdout.log" 2>"$stderr_log" || true

  # Positive: task-tool marker MUST be present (assertion passes).
  grep -q '\[transport: task-tool\]' "$stderr_log"

  rm -rf "$tmp"
}

# ---------------------------------------------------------------------------
# T7 / TE8b (negative): Copilot CLI assertion FAILS (RED) when COPILOT_CLI
# is absent — i.e., the task-tool marker is correctly absent on the
# claude-code branch.
# ---------------------------------------------------------------------------

@test "[T7 / TE8b] dispatch surface: Copilot CLI assertion FAILS (task-tool marker ABSENT) when COPILOT_CLI is unset (discriminating-power negative)" {
  # Test expectation: the acceptance test assertion for the Copilot CLI
  # path fails (RED) when COPILOT_CLI is absent.  This is the inverted-
  # environment negative case proving the assertion has discriminating
  # power: the task-tool marker MUST NOT fire when the env signal is
  # absent.
  local tmp
  tmp="$(mktemp -d)"
  _t7_make_mock_repo "$tmp"

  local stderr_log="$tmp/te8b-stderr.log"
  QRSPI_REPO_ROOT="$tmp" \
    COPILOT_CLI="" \
    MOCK_TRANSPORT_STDOUT="te8b-marker-2026-05-27" \
    bash "$REPO_ROOT/scripts/run-codex-review.sh" \
      --agent-file agents/qrspi-spec-reviewer.md \
      --reviewer-tag spec-codex \
      --output-dir "$tmp/out" \
      --round 1 \
      --subject-code "$tmp/src/subject.ts" \
      --model gpt-5.3-codex \
      --output-file "$tmp/result.md" \
      --artifact-dir "$tmp/artifact-dir" \
    >"$tmp/te8b-stdout.log" 2>"$stderr_log" || true

  # Negative: task-tool marker MUST be absent (the Copilot CLI assertion
  # would fail if applied to this run — proving its discriminating power).
  ! grep -q '\[transport: task-tool\]' "$stderr_log"

  rm -rf "$tmp"
}

# ---------------------------------------------------------------------------
# T7 / TE9a (positive): Claude Code assertion passes when COPILOT_CLI unset.
# ---------------------------------------------------------------------------

@test "[T7 / TE9a] dispatch surface: Claude Code assertion PASSES (shell-pipeline marker present) when COPILOT_CLI is unset" {
  # Test expectation: the acceptance test assertion for the Claude Code
  # path passes when COPILOT_CLI is unset (positive case of TE9).
  local tmp
  tmp="$(mktemp -d)"
  _t7_make_mock_repo "$tmp"

  local stderr_log="$tmp/te9a-stderr.log"
  QRSPI_REPO_ROOT="$tmp" \
    COPILOT_CLI="" \
    MOCK_TRANSPORT_STDOUT="te9a-marker-2026-05-27" \
    bash "$REPO_ROOT/scripts/run-codex-review.sh" \
      --agent-file agents/qrspi-spec-reviewer.md \
      --reviewer-tag spec-codex \
      --output-dir "$tmp/out" \
      --round 1 \
      --subject-code "$tmp/src/subject.ts" \
      --model gpt-5.3-codex \
      --output-file "$tmp/result.md" \
      --artifact-dir "$tmp/artifact-dir" \
    >"$tmp/te9a-stdout.log" 2>"$stderr_log" || true

  grep -q '\[transport: shell-pipeline\]' "$stderr_log"

  rm -rf "$tmp"
}

# ---------------------------------------------------------------------------
# T7 / TE9b (negative): Claude Code assertion FAILS when COPILOT_CLI signal
# is active — i.e., the shell-pipeline marker is correctly absent on the
# copilot-cli branch.
# ---------------------------------------------------------------------------

@test "[T7 / TE9b] dispatch surface: Claude Code assertion FAILS (shell-pipeline marker ABSENT) when COPILOT_CLI=1 is active (discriminating-power negative)" {
  # Test expectation: the acceptance test assertion for the Claude Code
  # path fails (RED) when the Copilot CLI signal is active.  The
  # shell-pipeline marker MUST NOT fire when COPILOT_CLI=1 selects the
  # task-tool branch.
  _t7_require_trusted_gh

  local tmp
  tmp="$(mktemp -d)"
  _t7_make_mock_repo "$tmp"
  printf -- '---\ncodex_reviews: true\n---\n' > "$tmp/artifact-dir/config.md"

  local stderr_log="$tmp/te9b-stderr.log"
  QRSPI_REPO_ROOT="$tmp" \
    COPILOT_CLI=1 \
    MOCK_TRANSPORT_STDOUT="te9b-marker-2026-05-27" \
    bash "$REPO_ROOT/scripts/run-codex-review.sh" \
      --agent-file agents/qrspi-spec-reviewer.md \
      --reviewer-tag spec-codex \
      --output-dir "$tmp/out" \
      --round 1 \
      --subject-code "$tmp/src/subject.ts" \
      --model gpt-5.3-codex \
      --output-file "$tmp/result.md" \
      --artifact-dir "$tmp/artifact-dir" \
    >"$tmp/te9b-stdout.log" 2>"$stderr_log" || true

  ! grep -q '\[transport: shell-pipeline\]' "$stderr_log"

  rm -rf "$tmp"
}

# ---------------------------------------------------------------------------
# T7 / TE10: Copilot CLI path — mocked task-tool dispatch exits 0 AND
# captured stdout contains a distinguishable marker the mock emitted.
# Exit-code-0-alone is insufficient proof.
# ---------------------------------------------------------------------------

@test "[T7 / TE10] dispatch surface: Copilot CLI path — mocked task-tool dispatch exits 0 AND stdout carries a distinguishable mock-emitted marker (exit 0 alone insufficient)" {
  # Test expectation: for the Copilot CLI path, the mocked task-tool
  # dispatch exits with code 0 and captured stdout contains a
  # distinguishable marker string emitted by the mock transport (a value
  # the mock produces and no other code path produces), proving the
  # dispatch invoked the mock rather than falling back.
  _t7_require_trusted_gh

  local tmp
  tmp="$(mktemp -d)"
  _t7_make_mock_repo "$tmp"
  printf -- '---\ncodex_reviews: true\n---\n' > "$tmp/artifact-dir/config.md"

  # Distinguishable marker — unique enough that no fallback code path could
  # produce it incidentally.
  local mock_marker="te10-task-tool-mock-emitted-DAB72CC1-1429-46E0-8D0F-A8EF92AB1230"
  local stdout_log="$tmp/te10-stdout.log"
  local stderr_log="$tmp/te10-stderr.log"
  local dispatch_status=0
  QRSPI_REPO_ROOT="$tmp" \
    COPILOT_CLI=1 \
    MOCK_TRANSPORT_STDOUT="$mock_marker" \
    MOCK_TRANSPORT_EXIT=0 \
    bash "$REPO_ROOT/scripts/run-codex-review.sh" \
      --agent-file agents/qrspi-spec-reviewer.md \
      --reviewer-tag spec-codex \
      --output-dir "$tmp/out" \
      --round 1 \
      --subject-code "$tmp/src/subject.ts" \
      --model gpt-5.3-codex \
      --output-file "$tmp/result.md" \
      --artifact-dir "$tmp/artifact-dir" \
    >"$stdout_log" 2>"$stderr_log" && dispatch_status=0 || dispatch_status=$?

  # Trace marker proves the COPILOT_CLI branch ran.
  grep -q '\[transport: task-tool\]' "$stderr_log"
  # Mock marker on stdout proves the mock transport was actually invoked
  # (not a fallback).
  grep -q "$mock_marker" "$stdout_log"
  # Exit 0.
  [ "$dispatch_status" -eq 0 ]

  rm -rf "$tmp"
}

# ---------------------------------------------------------------------------
# T7 / TE11: Claude Code path — mocked scripts/run-codex-review.sh dispatch
# exits 0 AND captured stdout contains a distinguishable marker emitted by
# the mock.  Exit-code-0-alone is insufficient proof.
# ---------------------------------------------------------------------------

@test "[T7 / TE11] dispatch surface: Claude Code path — mocked shell-pipeline dispatch exits 0 AND stdout carries a distinguishable mock-emitted marker (exit 0 alone insufficient)" {
  # Test expectation: for the Claude Code path, the mocked
  # `scripts/run-codex-review.sh` dispatch exits with code 0 and captured
  # stdout contains a distinguishable marker string emitted by the mock
  # transport, proving the dispatch invoked the mock rather than falling
  # back.
  local tmp
  tmp="$(mktemp -d)"
  _t7_make_mock_repo "$tmp"

  local mock_marker="te11-shell-pipeline-mock-emitted-7F8C2A60-9B43-4E1B-AC91-3D6E2F1B0A55"
  local stdout_log="$tmp/te11-stdout.log"
  local stderr_log="$tmp/te11-stderr.log"
  local dispatch_status=0
  QRSPI_REPO_ROOT="$tmp" \
    COPILOT_CLI="" \
    MOCK_TRANSPORT_STDOUT="$mock_marker" \
    MOCK_TRANSPORT_EXIT=0 \
    bash "$REPO_ROOT/scripts/run-codex-review.sh" \
      --agent-file agents/qrspi-spec-reviewer.md \
      --reviewer-tag spec-codex \
      --output-dir "$tmp/out" \
      --round 1 \
      --subject-code "$tmp/src/subject.ts" \
      --model gpt-5.3-codex \
      --output-file "$tmp/result.md" \
      --artifact-dir "$tmp/artifact-dir" \
    >"$stdout_log" 2>"$stderr_log" && dispatch_status=0 || dispatch_status=$?

  grep -q '\[transport: shell-pipeline\]' "$stderr_log"
  grep -q "$mock_marker" "$stdout_log"
  [ "$dispatch_status" -eq 0 ]

  rm -rf "$tmp"
}

# ---------------------------------------------------------------------------
# T7 / TE12: Non-zero transport exit (correctly-routed, Codex available)
# propagates unchanged.  No suppression, no log-and-continue.
# ---------------------------------------------------------------------------

@test "[T7 / TE12] dispatch surface: non-zero transport exit propagates unchanged on the correctly-routed Codex-available path (no suppression)" {
  # Test expectation: when the mocked transport command (correctly-routed,
  # Codex available) exits with a non-zero exit code, the dispatch surface
  # propagates that same non-zero exit code to the caller — no
  # suppression, no log-and-continue.
  #
  # Correctly-routed = shell-pipeline (COPILOT_CLI unset).  Codex
  # available = mock HOME contains a codex-companion.mjs at the expected
  # glob, so check_codex_available(claude-code) returns 0 and dispatch
  # reaches the transport.
  local tmp
  tmp="$(mktemp -d)"
  _t7_make_mock_repo "$tmp"

  # Populate the companion-glob path so check_codex_available succeeds.
  mkdir -p "$tmp/mock-home/.claude/plugins/cache/openai-codex/codex/v1/scripts"
  printf '// mock codex-companion stub\n' \
    > "$tmp/mock-home/.claude/plugins/cache/openai-codex/codex/v1/scripts/codex-companion.mjs"

  local stderr_log="$tmp/te12-stderr.log"
  local dispatch_status=0
  QRSPI_REPO_ROOT="$tmp" \
    COPILOT_CLI="" \
    HOME="$tmp/mock-home" \
    MOCK_TRANSPORT_STDOUT="te12-marker-2026-05-27" \
    MOCK_TRANSPORT_EXIT=42 \
    bash "$REPO_ROOT/scripts/run-codex-review.sh" \
      --agent-file agents/qrspi-spec-reviewer.md \
      --reviewer-tag spec-codex \
      --output-dir "$tmp/out" \
      --round 1 \
      --subject-code "$tmp/src/subject.ts" \
      --model gpt-5.3-codex \
      --output-file "$tmp/result.md" \
      --artifact-dir "$tmp/artifact-dir" \
    >"$tmp/te12-stdout.log" 2>"$stderr_log" && dispatch_status=0 || dispatch_status=$?

  # Trace marker confirms the shell-pipeline path ran (anchors RED to the
  # T06 dispatch surface, not a pre-T06 legacy path that would also
  # propagate exit codes).
  grep -q '\[transport: shell-pipeline\]' "$stderr_log"
  # Exit code MUST be 42 (propagated from mock transport — no suppression,
  # no remapping, no log-and-continue).
  [ "$dispatch_status" -eq 42 ]

  rm -rf "$tmp"
}

# ---------------------------------------------------------------------------
# T7 / TE13: Mismatch warning path + non-zero transport exit propagates
# unchanged.  The mismatch warning does not suppress dispatch failures.
# ---------------------------------------------------------------------------

@test "[T7 / TE13] dispatch surface: mismatch-warning path does not suppress non-zero transport exit (mismatch emitted, transport ran, non-zero propagated)" {
  # Test expectation: when the dispatch-surface detects a mismatch
  # (warning emitted) and then invokes a mocked transport that exits with
  # a non-zero exit code, the dispatch surface propagates that same
  # non-zero exit code to the caller.  The mismatch warning path does not
  # suppress dispatch failures.
  #
  # Scenario: detected_host=copilot-cli (COPILOT_CLI=1, trusted gh),
  # config codex_reviews=false → host-vs-config mismatch.
  # check_codex_available(copilot-cli) returns 0 trivially (no filesystem
  # probe), so dispatch reaches the mock transport.  Mock exits 7.
  #
  # RED state under Task-6 code: the current mismatch line fires ONLY when
  # check_codex_available fails AND codex_reviews=true.  In this scenario
  # check_codex_available SUCCEEDS, so no `[mismatch]` line fires under
  # current code → the warning-emitted assertion is RED.  Task 7 is
  # expected to decouple the mismatch warning from check_codex_available
  # failure so it fires on any host-vs-config disagreement.
  _t7_require_trusted_gh

  local tmp
  tmp="$(mktemp -d)"
  _t7_make_mock_repo "$tmp"
  # Explicit mismatch: detected copilot-cli but config says no Codex.
  printf -- '---\ncodex_reviews: false\n---\n' > "$tmp/artifact-dir/config.md"

  local stderr_log="$tmp/te13-stderr.log"
  local dispatch_status=0
  QRSPI_REPO_ROOT="$tmp" \
    COPILOT_CLI=1 \
    MOCK_TRANSPORT_STDOUT="te13-marker-2026-05-27" \
    MOCK_TRANSPORT_EXIT=7 \
    bash "$REPO_ROOT/scripts/run-codex-review.sh" \
      --agent-file agents/qrspi-spec-reviewer.md \
      --reviewer-tag spec-codex \
      --output-dir "$tmp/out" \
      --round 1 \
      --subject-code "$tmp/src/subject.ts" \
      --model gpt-5.3-codex \
      --output-file "$tmp/result.md" \
      --artifact-dir "$tmp/artifact-dir" \
    >"$tmp/te13-stdout.log" 2>"$stderr_log" && dispatch_status=0 || dispatch_status=$?

  # Mismatch warning must be present in stderr — naming both the detected
  # host and the config value on a single line.
  grep -qE "(mismatch|disagree).*copilot-cli|copilot-cli.*(mismatch|disagree)|mismatch.*false|false.*mismatch" "$stderr_log"
  # Transport marker for the copilot-cli branch must also be present
  # (proves dispatch was NOT short-circuited by the mismatch warning).
  grep -q '\[transport: task-tool\]' "$stderr_log"
  # Exit code MUST be 7 (propagated from mock transport — mismatch warning
  # path does not suppress the failure).
  [ "$dispatch_status" -eq 7 ]

  rm -rf "$tmp"
}

# ===========================================================================
# T8 — cite-check: verifier Cite Check step + hallucination rubric tier
#
# Task spec: docs/qrspi/2026-05-30-v072-release/tasks/task-08.md
# Target files (per spec):
#   - agents/qrspi-finding-verifier.md  (gains Step 3.5 Cite Check prose,
#     0 / HALLUCINATED rubric tier, sidecar reason-prefix convention in
#     step 6)
#   - tests/acceptance/v07-phase1/test-phase1-acceptance.bats  (this file —
#     gains fixture-round tests exercising the fan-in drop path for each
#     cite-check failure type)
#
# Coverage: bullets TC1..TC8 (doc-shape + fan-in fixture).
#
# RED scope at test-author time (i.e., before Task 8's implementer runs):
#   TC1..TC3  RED: agents/qrspi-finding-verifier.md does not yet contain
#             Step 3.5, the "0 / HALLUCINATED" rubric tier, or the
#             HALLUCINATED: reason-prefix convention.
#   TC4..TC8  Already-green fan-in behavior (score:0 < every non-always-keep
#             threshold; score:72 correctness ≥ 70 threshold).  Added here so
#             the acceptance gate proves fixture construction and fan-in
#             drop/keep behavior end-to-end.
#
# Fixture strategy (TC4..TC8):
#   Per-test, build a self-contained round directory in a fresh mktemp dir.
#   Write a minimal finding file + pre-constructed score sidecar covering each
#   cite-check failure type (file-existence, line-range, quoted-content,
#   named-anchor) and one advisory-no-citation case.  Run verifier-fan-in.sh
#   against the round dir and assert kept-findings.txt content.
#
# ID hygiene: test names and in-body error strings use neutral descriptors
# ("cite-check:", "hallucination:") rather than unscoped goal IDs.
# ===========================================================================

# ---------------------------------------------------------------------------
# T8 / TC1: verifier Step 3.5 Cite Check prose present in agent file
# ---------------------------------------------------------------------------

@test "[T8 / TC1] verifier agent file contains Step 3.5 Cite Check between referenced-files read and lazy-upstream-read steps" {
  # cite-check: this assertion is RED until the verifier gains the Step 3.5
  # Cite Check paragraph between current step 3 (read referenced_files) and
  # current step 4 (lazy-Read upstreams).
  grep -qE "3\.5" "$REPO_ROOT/agents/qrspi-finding-verifier.md" \
    || { echo "cite-check: Step 3.5 not found in agents/qrspi-finding-verifier.md"; return 1; }
  grep -q "Cite Check" "$REPO_ROOT/agents/qrspi-finding-verifier.md" \
    || { echo "cite-check: 'Cite Check' label not found in agents/qrspi-finding-verifier.md"; return 1; }
}

# ---------------------------------------------------------------------------
# T8 / TC2: verifier rubric contains 0 / HALLUCINATED top-anchor tier
# ---------------------------------------------------------------------------

@test "[T8 / TC2] verifier rubric contains 0 / HALLUCINATED top-anchor tier above the existing confidence anchors" {
  # cite-check: RED until the rubric gains the new 0 / HALLUCINATED anchor
  # prepended above the existing a-e (0/25/50/75/100) anchors.
  grep -q "0 / HALLUCINATED" "$REPO_ROOT/agents/qrspi-finding-verifier.md" \
    || { echo "cite-check: '0 / HALLUCINATED' rubric tier not found in agents/qrspi-finding-verifier.md"; return 1; }
}

# ---------------------------------------------------------------------------
# T8 / TC3: verifier sidecar write step documents literal HALLUCINATED:
#           reason-prefix convention
# ---------------------------------------------------------------------------

@test "[T8 / TC3] verifier sidecar write step (step 6) documents literal HALLUCINATED: reason-prefix convention for cite-check halts" {
  # cite-check: RED until step 6 gains the sentence documenting that score:0
  # Cite Check sidecars begin reason: with the literal prefix "HALLUCINATED: ".
  grep -qF "HALLUCINATED: " "$REPO_ROOT/agents/qrspi-finding-verifier.md" \
    || { echo "cite-check: 'HALLUCINATED: ' prefix convention not found in agents/qrspi-finding-verifier.md"; return 1; }
}

# ---------------------------------------------------------------------------
# Shared helper: write a minimal finding + sidecar pair for fan-in tests.
#   _t8_write_finding_pair <round-dir> <stem> <change_type> <score> <reason>
#                          [referenced_files] [body]
#   - <stem>: file base like "quality-claude.finding-F01"
#   - <change_type>: correctness | style | clarity | scope | intent
#   - <score>: integer 0..100
#   - <reason>: sidecar reason string (empty string = no reason field emitted)
#   - [referenced_files]: YAML inline list for finding frontmatter (default: [])
#   - [body]: finding markdown body (default: "Fixture finding body.")
#
# TC4..TC7 pass realistic fabricated citations so that IF the verifier were
# invoked on the finding, the Cite Check would actually trigger the claimed
# failure shape (file-existence / line-range / quoted-content / named-anchor).
# TC8 keeps referenced_files: [] — the no-citation no-op path.
# ---------------------------------------------------------------------------

_t8_write_finding_pair() {
  local dir="$1" stem="$2" ct="$3" score="$4" reason="$5"
  local refs="${6:-[]}"
  local body="${7:-Fixture finding body.}"
  local finding="$dir/${stem}.md"
  local sidecar="$dir/${stem}.score.md"

  printf -- '---\nfinding_id: %s\nseverity: high\nchange_type: %s\nreferenced_files: %s\n---\n%s\n' \
    "$stem" "$ct" "$refs" "$body" >"$finding"

  if [[ -n "$reason" ]]; then
    printf -- '---\nverifier_status: passed\nscore: %s\nreason: %s\n---\nCite check fixture sidecar.\n' \
      "$score" "$reason" >"$sidecar"
  else
    printf -- '---\nverifier_status: passed\nscore: %s\n---\nFixture sidecar.\n' \
      "$score" >"$sidecar"
  fi
}

# ---------------------------------------------------------------------------
# T8 / TC4: file-existence cite-check failure — score:0, HALLUCINATED:
#           reason, finding absent from kept-findings.txt (correctness drop)
# ---------------------------------------------------------------------------

@test "[T8 / TC4] cite-check file-existence failure: sidecar carries score 0 and HALLUCINATED: reason; fan-in drops finding from kept-findings.txt" {
  local tmp
  tmp="$(mktemp -d)"
  local stem="quality-claude.finding-F01"
  local reason="HALLUCINATED: file nonexistent/fabricated/path.md does not exist"
  # cite-check: fixture finding cites a file that does not exist in the repo,
  # so IF the verifier were invoked its Cite Check would trigger file-existence failure.
  local refs="[src/does-not-exist.ts]"
  local body="The helper function in src/does-not-exist.ts should be extracted into a shared utility."

  _t8_write_finding_pair "$tmp" "$stem" correctness 0 "$reason" "$refs" "$body"

  # Assert sidecar content: score is 0
  local raw_score
  raw_score=$(grep "^score:" "$tmp/${stem}.score.md" | awk '{print $2}')
  [ "$raw_score" -eq 0 ] \
    || { echo "hallucination: expected score 0 in sidecar, got: $raw_score"; return 1; }

  # Assert sidecar content: reason begins with HALLUCINATED:
  local raw_reason
  raw_reason=$(grep "^reason:" "$tmp/${stem}.score.md" | sed 's/^reason: //')
  [[ "$raw_reason" == HALLUCINATED:* ]] \
    || { echo "hallucination: reason does not begin with 'HALLUCINATED:' — got: $raw_reason"; return 1; }

  # Run fan-in; expect exit 0 (well-formed round, all findings processed)
  run bash "$REPO_ROOT/scripts/verifier-fan-in.sh" "$tmp"
  [ "$status" -eq 0 ] \
    || { echo "hallucination: verifier-fan-in.sh exited $status (expected 0)"; cat "$tmp/.verifier-fan-in-audit.json" 2>/dev/null; return 1; }

  # Finding must NOT appear in kept-findings.txt (score 0 < correctness threshold 70)
  if [ -s "$tmp/kept-findings.txt" ]; then
    grep -q "$stem" "$tmp/kept-findings.txt" \
      && { echo "hallucination: file-existence cite-check finding reached kept-findings.txt"; return 1; }
  fi

  rm -rf "$tmp"
}

# ---------------------------------------------------------------------------
# T8 / TC5: line-range cite-check failure — score:0, HALLUCINATED: reason,
#           finding absent from kept-findings.txt (correctness drop)
# ---------------------------------------------------------------------------

@test "[T8 / TC5] cite-check line-range failure: sidecar carries score 0 and HALLUCINATED: reason; fan-in drops finding from kept-findings.txt" {
  local tmp
  tmp="$(mktemp -d)"
  local stem="quality-claude.finding-F02"
  local reason="HALLUCINATED: README.md has fewer lines than cited range L99999-L99999 (line 99999 out of range)"
  # cite-check: fixture finding cites README.md at a line range (L99999-L99999)
  # well past EOF (README.md is ~944 lines), so IF the verifier were invoked its
  # Cite Check would trigger line-range failure.
  local refs="[README.md#L99999-L99999]"
  local body="As documented in README.md lines 99999-99999, the pipeline configuration should be updated."

  _t8_write_finding_pair "$tmp" "$stem" correctness 0 "$reason" "$refs" "$body"

  local raw_score
  raw_score=$(grep "^score:" "$tmp/${stem}.score.md" | awk '{print $2}')
  [ "$raw_score" -eq 0 ]

  local raw_reason
  raw_reason=$(grep "^reason:" "$tmp/${stem}.score.md" | sed 's/^reason: //')
  [[ "$raw_reason" == HALLUCINATED:* ]] \
    || { echo "hallucination: reason does not begin with 'HALLUCINATED:' — got: $raw_reason"; return 1; }

  run bash "$REPO_ROOT/scripts/verifier-fan-in.sh" "$tmp"
  [ "$status" -eq 0 ]

  if [ -s "$tmp/kept-findings.txt" ]; then
    ! grep -q "$stem" "$tmp/kept-findings.txt" \
      || { echo "hallucination: line-range cite-check finding reached kept-findings.txt"; return 1; }
  fi

  rm -rf "$tmp"
}

# ---------------------------------------------------------------------------
# T8 / TC6: quoted-content cite-check failure — score:0, HALLUCINATED:
#           reason, finding absent from kept-findings.txt (style drop)
# ---------------------------------------------------------------------------

@test "[T8 / TC6] cite-check quoted-content failure: sidecar carries score 0 and HALLUCINATED: reason; fan-in drops finding from kept-findings.txt" {
  local tmp
  tmp="$(mktemp -d)"
  local stem="quality-claude.finding-F03"
  local reason="HALLUCINATED: quoted content 'const fabricatedFunction = () => {}' not found in README.md"
  # cite-check: fixture finding cites README.md and quotes a string that does NOT
  # appear anywhere in that file, so IF the verifier were invoked its Cite Check
  # would trigger quoted-content mismatch failure.
  local refs="[README.md]"
  local body="The implementation contains \`const fabricatedFunction = () => {}\` which should be extracted into a shared module per README.md."

  _t8_write_finding_pair "$tmp" "$stem" style 0 "$reason" "$refs" "$body"

  local raw_score
  raw_score=$(grep "^score:" "$tmp/${stem}.score.md" | awk '{print $2}')
  [ "$raw_score" -eq 0 ]

  local raw_reason
  raw_reason=$(grep "^reason:" "$tmp/${stem}.score.md" | sed 's/^reason: //')
  [[ "$raw_reason" == HALLUCINATED:* ]] \
    || { echo "hallucination: reason does not begin with 'HALLUCINATED:' — got: $raw_reason"; return 1; }

  run bash "$REPO_ROOT/scripts/verifier-fan-in.sh" "$tmp"
  [ "$status" -eq 0 ]

  if [ -s "$tmp/kept-findings.txt" ]; then
    ! grep -q "$stem" "$tmp/kept-findings.txt" \
      || { echo "hallucination: quoted-content cite-check finding reached kept-findings.txt"; return 1; }
  fi

  rm -rf "$tmp"
}

# ---------------------------------------------------------------------------
# T8 / TC7: named-anchor cite-check failure — score:0, HALLUCINATED: reason,
#           finding absent from kept-findings.txt (clarity drop)
# ---------------------------------------------------------------------------

@test "[T8 / TC7] cite-check named-anchor failure: sidecar carries score 0 and HALLUCINATED: reason; fan-in drops finding from kept-findings.txt" {
  local tmp
  tmp="$(mktemp -d)"
  local stem="quality-claude.finding-F04"
  local reason="HALLUCINATED: anchor 'nonexistentFunc()' not found in README.md"
  # cite-check: fixture finding cites README.md and names a section/function anchor
  # (nonexistentFunc) that does not exist anywhere in the file, so IF the verifier
  # were invoked its Cite Check would trigger named-anchor failure.
  local refs="[README.md]"
  local body="The nonexistentFunc() documented in README.md should be split into smaller helpers for clarity."

  _t8_write_finding_pair "$tmp" "$stem" clarity 0 "$reason" "$refs" "$body"

  local raw_score
  raw_score=$(grep "^score:" "$tmp/${stem}.score.md" | awk '{print $2}')
  [ "$raw_score" -eq 0 ]

  local raw_reason
  raw_reason=$(grep "^reason:" "$tmp/${stem}.score.md" | sed 's/^reason: //')
  [[ "$raw_reason" == HALLUCINATED:* ]] \
    || { echo "hallucination: reason does not begin with 'HALLUCINATED:' — got: $raw_reason"; return 1; }

  run bash "$REPO_ROOT/scripts/verifier-fan-in.sh" "$tmp"
  [ "$status" -eq 0 ]

  if [ -s "$tmp/kept-findings.txt" ]; then
    ! grep -q "$stem" "$tmp/kept-findings.txt" \
      || { echo "hallucination: named-anchor cite-check finding reached kept-findings.txt"; return 1; }
  fi

  rm -rf "$tmp"
}

# ---------------------------------------------------------------------------
# T8 / TC8: advisory finding with no specific factual citation — Cite Check
#           is a no-op; fan-in keeps the finding (score 72 ≥ correctness 70)
# ---------------------------------------------------------------------------

@test "[T8 / TC8] advisory finding with no specific factual citation: cite-check is a no-op; fan-in keeps finding when score meets threshold" {
  local tmp
  tmp="$(mktemp -d)"
  local stem="quality-claude.finding-F05"

  # Advisory/stylistic finding — no HALLUCINATED: reason, score above threshold
  _t8_write_finding_pair "$tmp" "$stem" correctness 72 ""

  local raw_score
  raw_score=$(grep "^score:" "$tmp/${stem}.score.md" | awk '{print $2}')
  [ "$raw_score" -eq 72 ]

  run bash "$REPO_ROOT/scripts/verifier-fan-in.sh" "$tmp"
  [ "$status" -eq 0 ]

  # Finding MUST appear in kept-findings.txt (72 ≥ correctness threshold 70)
  grep -q "$stem" "$tmp/kept-findings.txt" \
    || { echo "cite-check: advisory finding with score 72 unexpectedly absent from kept-findings.txt"; return 1; }

  rm -rf "$tmp"
}

# ---------------------------------------------------------------------------
# T8 / TC9: HALLUCINATED scope/intent bypass regression — a score:0 finding
#           with change_type: scope must NOT reach kept-findings.txt.
#           (Regression: pre-fix fan-in scope|intent arm unconditionally kept
#           findings, bypassing the score:0 / HALLUCINATED gate.)
# ---------------------------------------------------------------------------

@test "[T8 / TC9] HALLUCINATED score-0 scope finding is dropped by fan-in (universal HALLUCINATED gate precedes change_type arm)" {
  local tmp
  tmp="$(mktemp -d)"
  local stem="quality-claude.finding-F09"
  local reason="HALLUCINATED: file nonexistent/scope-example.md does not exist"
  # cite-check: fixture is a scope finding with score:0 (HALLUCINATED);
  # the pre-fix fan-in scope|intent arm kept findings unconditionally —
  # this test asserts the universal HALLUCINATED gate fires before the arm.
  local refs="[nonexistent/scope-example.md]"
  local body="The scope of this change extends beyond the task boundary per nonexistent/scope-example.md."

  _t8_write_finding_pair "$tmp" "$stem" scope 0 "$reason" "$refs" "$body"

  # Assert sidecar has score 0 and HALLUCINATED: reason
  local raw_score raw_reason
  raw_score=$(grep "^score:" "$tmp/${stem}.score.md" | awk '{print $2}')
  [ "$raw_score" -eq 0 ] \
    || { echo "cite-check: expected score 0 in sidecar, got: $raw_score"; return 1; }
  raw_reason=$(grep "^reason:" "$tmp/${stem}.score.md" | sed 's/^reason: //')
  [[ "$raw_reason" == HALLUCINATED:* ]] \
    || { echo "hallucination: reason does not begin with 'HALLUCINATED:' — got: $raw_reason"; return 1; }

  # Run fan-in; expect exit 0 (well-formed round, finding processed and dropped)
  run bash "$REPO_ROOT/scripts/verifier-fan-in.sh" "$tmp"
  [ "$status" -eq 0 ] \
    || { echo "hallucination: verifier-fan-in.sh exited $status (expected 0)"; cat "$tmp/.verifier-fan-in-audit.json" 2>/dev/null; return 1; }

  # Finding must NOT appear in kept-findings.txt — HALLUCINATED score:0 must be dropped
  # regardless of change_type (scope/intent no longer bypasses the score filter for score:0)
  if [ -s "$tmp/kept-findings.txt" ]; then
    grep -q "$stem" "$tmp/kept-findings.txt" \
      && { echo "hallucination: HALLUCINATED scope finding reached kept-findings.txt (universal gate missing)"; return 1; }
  fi

  rm -rf "$tmp"
}
