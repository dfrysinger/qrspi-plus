#!/usr/bin/env bats

# Regression guard for #41: "Parallel Group" vocabulary collapsed into
# "Wave" (Phase / Slice / Task / Wave 4-level decomposition). Wave is the
# surviving name; Parallel Group / Dispatch Wave / stage-after-G{N} are gone.

@test "no Parallel Group vocabulary in skills/" {
  local offenders
  offenders=$(grep -rnE 'Parallel Group|parallel group|parallel-group' skills/ 2>/dev/null || true)
  if [ -n "$offenders" ]; then
    echo "Parallel Group vocabulary remains in skills/:"
    echo "$offenders"
    return 1
  fi
}

@test "no stage-after-G{N} references in skills/ or agents/" {
  local offenders
  offenders=$(grep -rnE 'stage-after-G[0-9{]' skills/ agents/ 2>/dev/null || true)
  if [ -n "$offenders" ]; then
    echo "legacy stage-after-G{N} references remain:"
    echo "$offenders"
    return 1
  fi
}

@test "no Parallel Group vocabulary in agents/" {
  local offenders
  offenders=$(grep -rnE 'Parallel Group|parallel group|parallel-group' agents/ 2>/dev/null || true)
  if [ -n "$offenders" ]; then
    echo "Parallel Group vocabulary remains in agents/:"
    echo "$offenders"
    return 1
  fi
}
