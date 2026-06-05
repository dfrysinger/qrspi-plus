#!/usr/bin/env bats
#
# v0.7.2 Phase 1 acceptance — G16 path-filter exfil guard in scripts/dispatch-agent.sh.
#
# Plan-level acceptance criterion (plan.md Phase 1 Acceptance Criteria #2,
# fail-loud invariant sub-bullet): "the path-filter exfil guard in
# `scripts/dispatch-agent.sh` ... produce non-zero exit with a diagnostic,
# never silent fallback."
#
# Upstream traceability: goals.md ### G16 — sanctioned-channel exfil through
# arbitrary wrapper path inputs; design.md ## G16 locks the fail-closed
# repo-boundary guard pattern; tasks/task-21.md owns the implementation
# (target: scripts/dispatch-agent.sh + scripts/lib/path-guard.sh +
# agents/qrspi-implementer.md allowlist).
#
# Per-task unit coverage in tests/unit/test-dispatch-agent.bats does NOT
# currently include the G16 boundary-guard assertions (the T21 branch's
# test additions did not land on main during Integrate R1). This file
# pins the cross-task observable end of the criterion at the phase-acceptance
# layer so the gap is loud at the Test gate.
#
# Strategy: drive the wrapper with --dry-run + --subject-code pointing at
# an out-of-repo absolute path (/etc/hosts is universally present on
# macOS + Linux runners). The guard must fire BEFORE any prompt assembly
# and exit non-zero with a stderr diagnostic naming the boundary failure.
# We intentionally accept either the canonical "resolves outside repository"
# wording from design.md ## G16 OR any non-zero exit accompanied by a stderr
# diagnostic that names the rejected path — the criterion is "non-zero exit
# with a diagnostic, never silent fallback", not a literal wording match.

setup_file() {
  REPO_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../../.." && pwd -P)"
  export REPO_ROOT
  WRAPPER="$REPO_ROOT/scripts/dispatch-agent.sh"
  export WRAPPER
}

@test "[G16 acceptance] dispatch-agent.sh wrapper file exists and is executable" {
  [ -x "$WRAPPER" ]
}

@test "[G16 acceptance] --subject-code resolving outside REPO_ROOT exits non-zero with a stderr diagnostic (no silent fallback)" {
  # /etc/hosts is universally present on macOS and Linux CI runners and
  # canonically lives outside any qrspi-plus checkout. A correctly-installed
  # G16 guard must reject the path before prompt emission.
  #
  # We pass --dry-run so the test exercises the GUARD path without needing
  # a real reviewer dispatch, and we pass --agent-file pointing at a real
  # in-repo agent so the wrapper gets past argument-shape checks and reaches
  # the boundary guard for --subject-code.
  local agent_file="$REPO_ROOT/agents/qrspi-implementer.md"
  [ -f "$agent_file" ]

  # NOTE: The wrapper requires --output-dir and --round even on the --dry-run
  # path (they are validated before the per-flag path guards run). Supply
  # both with safe, allowlist-clean values so the wrapper actually reaches
  # the --subject-code boundary guard rather than short-circuiting on a
  # missing-required-flag diagnostic. The test's semantic — "out-of-repo
  # --subject-code is rejected with a stderr diagnostic naming the boundary"
  # — is unchanged; we are only completing the minimum invocation surface
  # needed to exercise that guard.
  run bash "$WRAPPER" \
    --agent-file "$agent_file" \
    --reviewer-tag g16-exfil-probe \
    --output-dir /tmp/g16-acceptance-probe \
    --round 0 \
    --subject-code /etc/hosts \
    --dry-run
  # Fail-loud invariant: non-zero exit.
  [ "$status" -ne 0 ]
  # And the wrapper MUST emit a diagnostic (combined stdout+stderr via `run`)
  # that references the rejected boundary, naming either the canonical
  # design.md ## G16 wording or the offending path itself. A bare non-zero
  # exit with empty output would be a silent fallback — explicitly forbidden.
  [ -n "$output" ]
  echo "$output" | grep -qE 'resolves outside repository|outside.*repo|/etc/hosts|repo[- ]boundary|path[- ]guard'
}

@test "[G16 acceptance] scripts/lib/path-guard.sh shared helper is present (design.md ## G16 lock)" {
  # design.md ## G16 locks "a single fail-closed assert_path_under_repo_root
  # guard" extracted into scripts/lib/path-guard.sh so dispatch-agent.sh and
  # dispatch-companion.sh share one canonicalization path. Pin the helper's
  # existence so a regression that inlines the guard back into a single
  # script (losing the shared-surface contract) is caught at acceptance.
  [ -f "$REPO_ROOT/scripts/lib/path-guard.sh" ]
}

@test "[G16 acceptance] agents/qrspi-implementer.md carries the Orchestrator-Only Scripts (Bash Allowlist) section" {
  # task-21.md Definition of Done: implementer agent body MUST contain a
  # top-of-body '## Orchestrator-Only Scripts (Bash Allowlist)' section
  # forbidding implementers from invoking dispatch-agent.sh or
  # dispatch-companion.sh under any path shape. This is the prose-side
  # defense-in-depth pair to the runtime guard.
  local impl_agent="$REPO_ROOT/agents/qrspi-implementer.md"
  [ -f "$impl_agent" ]
  grep -qE '^##[[:space:]]+Orchestrator-Only Scripts' "$impl_agent"
}
