#!/usr/bin/env bats

setup() {
  PROTOCOL=$(awk '
    /\*\*Apply-fix protocol\.\*\*/ { in_block=1 }
    in_block && /\*\*Diff handling between rounds/ { exit }
    in_block { print }
  ' skills/using-qrspi/SKILL.md)
}

@test "scope and intent flow to pause gate REGARDLESS of score" {
  echo "$PROTOCOL" | grep -qE 'scope.*intent.*bypass.*score|scope.*intent.*pause gate.*regardless|scope.*intent.*never.*score-filtered'
}

@test "style/clarity/correctness are score-filtered at >=80" {
  echo "$PROTOCOL" | grep -qE 'style.*clarity.*correctness.*(>=|≥)\s*80|score\s*(>=|≥)\s*80.*style.*clarity.*correctness'
}

@test "out-of-enum change_type triggers loud failure" {
  echo "$PROTOCOL" | grep -qE 'out-of-enum.*loud failure|change_type.*loud failure|schema guard.*change_type'
}

@test "the canonical 5-value change_type enum is cited from reviewer-protocol" {
  grep -qE 'style.*clarity.*correctness.*scope.*intent' skills/reviewer-protocol/SKILL.md
}

@test "fixture-backed partition: scope/intent kept regardless of score, style/clarity/correctness filtered at >=80" {
  # Run the partition logic against the mixed-change-types fixture and assert
  # the spec routing rule: scope/intent always-keep; SCC score-filtered at 80.
  local D=tests/fixtures/issue-109/round-mixed-change-types/round-04
  shopt -s nullglob
  local kept=0 dropped=0
  for f in "$D"/*.finding-*.md; do
    local sc="${f%.md}.score.yml"
    local ct score
    ct=$(awk -F': *' '/^change_type:/ {print $2; exit}' "$f")
    score=$(awk -F': *' '/^score:/ {print $2; exit}' "$sc")
    if [[ "$ct" == "scope" || "$ct" == "intent" ]]; then
      kept=$((kept + 1))
    elif (( score >= 80 )); then
      kept=$((kept + 1))
    else
      dropped=$((dropped + 1))
    fi
  done
  [[ "$kept" -eq 4 ]] || { echo "expected kept=4, got $kept"; return 1; }
  [[ "$dropped" -eq 1 ]] || { echo "expected dropped=1, got $dropped"; return 1; }
}
