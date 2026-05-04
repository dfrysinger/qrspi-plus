#!/usr/bin/env bats

# Cross-cutting CI test: verifies the 22 legacy reviewer-template + boilerplate
# files deleted in commit 20/22 of #110 are absent at HEAD. Catches a future
# revert / accidental restore.
# Added in commit 22/22 of issue-110 migration.

setup() {
  cd "$BATS_TEST_DIRNAME/../.."
}

@test "deleted legacy reviewer-template + boilerplate files are absent at HEAD" {
  local paths=(
    skills/_shared/reviewer-boilerplate.md
    skills/_shared/templates/scope-reviewer.md
    skills/integrate/templates/integration-reviewer.md
    skills/integrate/templates/security-integration-reviewer.md
    skills/implement/templates/correctness/spec-reviewer.md
    skills/implement/templates/correctness/code-quality-reviewer.md
    skills/implement/templates/correctness/silent-failure-hunter.md
    skills/implement/templates/correctness/security-reviewer.md
    skills/implement/templates/thoroughness/goal-traceability-reviewer.md
    skills/implement/templates/thoroughness/test-coverage-reviewer.md
    skills/implement/templates/thoroughness/type-design-analyzer.md
    skills/implement/templates/thoroughness/code-simplifier.md
    skills/test/templates/test-writer.md
    skills/test/templates/acceptance-test.md
    skills/test/templates/boundary-test.md
    skills/test/templates/e2e-test.md
    skills/test/templates/integration-test.md
    skills/plan/templates/spec-reviewer.md
    skills/plan/templates/security-reviewer.md
    skills/plan/templates/silent-failure-hunter.md
    skills/plan/templates/goal-traceability-reviewer.md
    skills/plan/templates/test-coverage-reviewer.md
  )
  for path in "${paths[@]}"; do
    [[ ! -e "$path" ]] || { echo "$path should have been deleted"; return 1; }
  done
}
