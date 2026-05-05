#!/usr/bin/env bats

@test "Apply-fix step 3 jumps to step 5 when verifier_enabled is false" {
  local protocol
  protocol=$(awk '
    /\*\*Apply-fix protocol\.\*\*/ { in_block=1 }
    in_block && /\*\*Diff handling between rounds/ { exit }
    in_block { print }
  ' skills/using-qrspi/SKILL.md)
  echo "$protocol" | grep -qE 'verifier_enabled.*false.*jump.*step 5|verifier_enabled.*false.*skip dispatch'
}

@test "Apply-fix step 7 keeps all findings via no-sidecar branch (NOT a synthetic 80 score)" {
  local protocol
  protocol=$(awk '
    /\*\*Apply-fix protocol\.\*\*/ { in_block=1 }
    in_block && /\*\*Diff handling between rounds/ { exit }
    in_block { print }
  ' skills/using-qrspi/SKILL.md)
  echo "$protocol" | grep -qE 'no sidecar.*keep|sidecar absent.*keep|keep-all'
  ! echo "$protocol" | grep -qE 'synthetic.*80|inject.*score.*80|default score 80'
}

@test "Apply-fix step 7 keeps findings whose sidecar is VERIFY_FAILED (degraded-but-uncertain → favor surfacing)" {
  # Spec §3 retry-skip flow depends on this routing: a verifier that returns
  # VERIFY_FAILED degrades to "no useful score" — the safe default is to keep
  # the finding (let the user see it) rather than drop it. Without this branch
  # documented in the prose, the §3 menu's `skip` option would have nothing
  # to fall through to.
  local protocol
  protocol=$(awk '
    /\*\*Apply-fix protocol\.\*\*/ { in_block=1 }
    in_block && /\*\*Diff handling between rounds/ { exit }
    in_block { print }
  ' skills/using-qrspi/SKILL.md)
  echo "$protocol" | grep -qE 'VERIFY_FAILED.*keep|keep.*VERIFY_FAILED|VERIFY_FAILED.*flow.*apply|VERIFY_FAILED.*surface' \
    || { echo "Apply-fix step 7 does not document the VERIFY_FAILED → keep routing"; return 1; }
}

@test "disabled-from-start fixture has NO sidecars on disk" {
  ! ls tests/fixtures/issue-109/round-disabled-from-start/round-01/*.score.yml 2>/dev/null
}
