#!/usr/bin/env bats
#
# Plan-level acceptance tests for CD-2 (Per-step pre-dispatch input
# generation owned by scripts/review-prep.sh, invoked from
# scripts/dispatch-agent.sh in high-level mode).
#
# Maps to design.md § CD-2 Acceptance, plan.md Phase 1 Acceptance bullets
# 3-4 (high-level mode produces identical prompts; diff-redirect prose
# shrinkage ≥ 80 lines across 8 artifact-step SKILLs).
#
# Asserts the wiring is in place at the phase boundary (artifact-step
# SKILLs no longer carry raw diff-redirect prose; review-prep.sh and
# dispatch-agent.sh high-level mode both exist and connect). Detailed
# script-internal behaviour is covered by tests/unit/test-review-prep.bats,
# tests/unit/test-dispatch-agent-highlevel-mode.bats, and
# tests/lint/test-no-diff-redirect-prose.bats.

setup_file() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")"/../../.. && pwd)"
  export REPO_ROOT
  export REVIEW_PREP="$REPO_ROOT/scripts/review-prep.sh"
  export DISPATCH_AGENT="$REPO_ROOT/scripts/dispatch-agent.sh"
}

@test "acceptance: scripts/review-prep.sh exists, is executable, and is the source of truth for per-step pre-dispatch generation" {
  [ -x "$REVIEW_PREP" ]
  # Identity of purpose: header line names per-step pre-dispatch input generation.
  grep -q 'per-step pre-dispatch input generation' "$REVIEW_PREP"
}

@test "acceptance: scripts/dispatch-agent.sh accepts high-level mode flags (--step --round --artifact-dir)" {
  [ -x "$DISPATCH_AGENT" ]
  # CLI surface contracted by CD-2: high-level mode is the per-round entry point.
  grep -q -- '--step' "$DISPATCH_AGENT"
  grep -q -- '--round' "$DISPATCH_AGENT"
  grep -q -- '--artifact-dir' "$DISPATCH_AGENT"
}

@test "acceptance: dispatch-agent.sh high-level mode invokes review-prep.sh internally" {
  # Contracted by CD-2: high-level mode calls review-prep.sh; the orchestrator
  # makes one call per round (review-prep is not invoked separately by skills).
  grep -q 'review-prep.sh' "$DISPATCH_AGENT"
}

@test "acceptance: zero git-diff-redirect Bash blocks remain in the 8 artifact-step SKILLs (CD-2 quantitative)" {
  # plan.md Phase 1 Acceptance bullet 4 — prose shrinkage ≥80 lines is
  # bounded above by the absence of these blocks. We assert ZERO matches
  # for the exact redirect shape across all 8 artifact-step skills.
  for s in goals questions research design phasing structure parallelize replan; do
    f="$REPO_ROOT/skills/$s/SKILL.md"
    [ -f "$f" ]
    # Forbidden: `git diff ... > .../round-NN.diff` raw-redirect prose.
    run grep -nE 'git diff .*>[[:space:]]+["'\'']?[^"'\'']*round-NN\.diff' "$f"
    [ "$status" -ne 0 ] || {
      echo "diff-redirect prose found in $f:" >&2
      echo "$output" >&2
      false
    }
  done
}

@test "acceptance: each of the 8 artifact-step SKILLs invokes dispatch-agent.sh --step (high-level dispatch)" {
  # Mirror of the prior test in the positive direction: replacement landed,
  # not just deletion.
  for s in goals questions research design phasing structure parallelize replan; do
    f="$REPO_ROOT/skills/$s/SKILL.md"
    grep -q 'dispatch-agent.sh' "$f" || {
      echo "skills/$s/SKILL.md missing dispatch-agent.sh invocation" >&2
      false
    }
  done
}
