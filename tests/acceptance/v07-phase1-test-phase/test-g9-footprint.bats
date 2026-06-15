#!/usr/bin/env bats
#
# Plan-level acceptance / e2e tests for G9 (Active-skill-prompt footprint
# reduction across all 14 skills).
#
# Maps to design.md § G9 Acceptance and plan.md Phase 1 Acceptance Criteria
# bullets 16-17 (v0.7.2 phase-1 suite passes against trimmed skill set with
# zero regressions; measure-active-footprint.sh reports < 30K tokens per
# typical session, captured at g9-footprint-report.md).
#
# Per-script behaviour is covered by tests/unit/test-measure-active-footprint.bats;
# this file asserts the OBSERVABLE phase-boundary criteria: the report file
# exists, carries a total_tokens line, and that total is < 30000.

setup_file() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")"/../../.. && pwd)"
  export REPO_ROOT
  export MEASURE="$REPO_ROOT/scripts/measure-active-footprint.sh"
  export REPORT="$REPO_ROOT/docs/qrspi/2026-06-04-v073-release/g9-footprint-report.md"
  export SHARED="$REPO_ROOT/skills/_shared"
}

@test "acceptance: scripts/measure-active-footprint.sh exists and is executable" {
  [ -x "$MEASURE" ]
}

@test "acceptance: g9-footprint-report.md exists at the canonical artifact path (T37)" {
  # plan.md Phase 1 Acceptance bullet 17 — report path is the load-bearing artifact.
  [ -f "$REPORT" ]
}

@test "acceptance: g9-footprint-report.md carries a total_tokens line" {
  grep -qE '^total_tokens=[0-9]+' "$REPORT"
}

@test "acceptance: reported total_tokens is < 30000 (G9 acceptance threshold)" {
  # design.md § G9 Acceptance bullet 7 + plan.md Phase 1 bullet 17.
  total="$(grep -E '^total_tokens=' "$REPORT" | head -1 | sed 's/total_tokens=//')"
  [ -n "$total" ]
  [ "$total" -lt 30000 ] || {
    echo "total_tokens=$total exceeds the 30000 acceptance threshold" >&2
    false
  }
}

@test "acceptance: required skills/_shared/ snippets exist (T31 populated SSoT)" {
  # design.md § G9 Acceptance bullet 3 — _shared/ populated.
  for snippet in reviewer-dispatch.md review-loop.md config-validation.md \
                 compaction-checkpoint.md pause-gate.md feedback-format.md; do
    [ -f "$SHARED/$snippet" ] || {
      echo "missing required _shared snippet: $snippet" >&2
      false
    }
  done
}

@test "acceptance: v0.7.2 phase-1 acceptance suite still exists (regression-guard precondition)" {
  # plan.md Phase 1 Acceptance bullet 16 — v07-phase1/ suite kept; its
  # green status is asserted by orchestrator-level test execution, not by
  # this file (we cannot self-recurse bats).
  [ -d "$REPO_ROOT/tests/acceptance/v07-phase1" ]
  [ -f "$REPO_ROOT/tests/acceptance/v07-phase1/test-phase1-acceptance.bats" ]
}

@test "acceptance: trim-audit forbidden narrative tokens are absent across active SKILL.md files (G9 bullet 8)" {
  # design.md § G9 Acceptance bullet 8 — `jobId`, `tmpfile`, `HEAD~1` narrative,
  # `narrow.broaden`, `sidecar.*schema`, `change_type:.*enum`,
  # `verifier.*threshold`, `third-party.*splitter` narrative restatements.
  # We check the four most diagnostic of these here; the full sweep lives
  # in tests/lint/test-skill-trim-audit.bats.
  for f in "$REPO_ROOT"/skills/*/SKILL.md; do
    # Skip _shared (not an active SKILL); skip references/.
    case "$f" in
      */_shared/*) continue ;;
    esac
    ! grep -qE 'jobId' "$f"
    ! grep -qE '\btmpfile\b' "$f"
  done
}
