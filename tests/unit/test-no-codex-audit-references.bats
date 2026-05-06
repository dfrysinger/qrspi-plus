#!/usr/bin/env bats
# Guards #114: the codex-companion audit-write surface was removed in v0.5.
# Reappearance of audit symbols in the script or dispatch sites would be a
# regression — re-introduce only via an explicit issue.

@test "codex-companion-bg.sh has no audit symbols" {
  local offenders
  offenders=$(grep -nE 'emit_audit_row|resolve_audit_dir|QRSPI_AUDIT_|audit-codex-review' \
    scripts/codex-companion-bg.sh 2>/dev/null || true)
  if [ -n "$offenders" ]; then
    echo "audit symbols remain in codex-companion-bg.sh:"
    echo "$offenders"
    return 1
  fi
}

@test "no skill or agent file passes --artifact-dir to codex-companion-bg.sh" {
  local offenders
  offenders=$(grep -rnE 'codex-companion-bg\.sh +await +.*--artifact-dir' \
    skills/ agents/ 2>/dev/null || true)
  if [ -n "$offenders" ]; then
    echo "dispatch sites still pass --artifact-dir:"
    echo "$offenders"
    return 1
  fi
}

@test "regression #114: no state.json read in codex-companion-bg.sh" {
  local non_comment
  non_comment=$(grep -nE '^[^#]*state\.json' scripts/codex-companion-bg.sh 2>/dev/null || true)
  [ -z "$non_comment" ]
}
