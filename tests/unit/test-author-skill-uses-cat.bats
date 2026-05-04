#!/usr/bin/env bats

@test "each scope-reviewed author SKILL.md uses !cat for OWNS/DEFERS" {
  for name in goals design structure phasing plan parallelize replan; do
    grep -qF "!cat skills/${name}/owns-defers.md" "skills/${name}/SKILL.md" \
      || { echo "missing !cat in skills/${name}/SKILL.md"; return 1; }
  done
}

@test "questions and research SKILL.md do NOT have OWNS/DEFERS sections" {
  ! grep -qE "^## (Questions|Research) OWNS" skills/questions/SKILL.md
  ! grep -qE "^## (Questions|Research) OWNS" skills/research/SKILL.md
}
