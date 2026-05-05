#!/usr/bin/env bats

# Cross-cutting CI test: verifies no migrated SKILL.md still embeds legacy
# reviewer-boilerplate content or uses the legacy /tmp or .codex-prompts
# prompt-file dispatch patterns. The migrated skills now use the stdin
# pipeline form (commit 18 / issue-110) and reference agent files +
# reviewer-protocol instead.
# Added in commit 22/22 of issue-110 migration.

setup() {
  cd "$BATS_TEST_DIRNAME/../.."
}

@test "no migrated SKILL.md embeds the old reviewer-boilerplate content" {
  local skills=(goals questions research design structure phasing plan parallelize implement integrate replan test)
  for skill in "${skills[@]}"; do
    ! grep -qF 'embed reviewer-boilerplate.md verbatim' "skills/${skill}/SKILL.md" \
      || { echo "skills/${skill}/SKILL.md still references reviewer-boilerplate verbatim embed"; return 1; }
    ! grep -qF 'skills/_shared/reviewer-boilerplate.md' "skills/${skill}/SKILL.md" \
      || { echo "skills/${skill}/SKILL.md still references skills/_shared/reviewer-boilerplate.md"; return 1; }
  done
}

@test "no migrated SKILL.md uses the legacy /tmp codex prompt-file pattern" {
  local skills=(goals questions research design structure phasing plan parallelize implement integrate replan test)
  for skill in "${skills[@]}"; do
    ! grep -qE '/tmp/codex-prompt-' "skills/${skill}/SKILL.md" \
      || { echo "skills/${skill}/SKILL.md still uses /tmp/codex-prompt- dispatch pattern"; return 1; }
  done
}

@test "no migrated SKILL.md uses the .codex-prompts worktree-local prompt-file pattern" {
  local skills=(goals questions research design structure phasing plan parallelize implement integrate replan test)
  for skill in "${skills[@]}"; do
    ! grep -qE '\.codex-prompts/codex-prompt-task-' "skills/${skill}/SKILL.md" \
      || { echo "skills/${skill}/SKILL.md still uses .codex-prompts/ dispatch pattern"; return 1; }
  done
}

@test "no migrated SKILL.md references deleted template paths" {
  local skills=(goals questions research design structure phasing plan parallelize implement integrate replan test)
  local deleted_paths=(
    'skills/_shared/templates/scope-reviewer\.md'
    'skills/implement/templates/'
    'skills/integrate/templates/'
    'skills/test/templates/'
    'skills/plan/templates/'
  )
  for skill in "${skills[@]}"; do
    for path in "${deleted_paths[@]}"; do
      ! grep -qE "$path" "skills/${skill}/SKILL.md" \
        || { echo "skills/${skill}/SKILL.md still references deleted template path: $path"; return 1; }
    done
  done
}
