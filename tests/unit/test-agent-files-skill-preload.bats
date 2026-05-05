#!/usr/bin/env bats

# Structural CI test: every reviewer agent file must declare skills: [reviewer-protocol]
# Added in commit 5/22 of issue-110 migration.

setup() {
  cd "$BATS_TEST_DIRNAME/../.."
}

@test "every reviewer agent file declares skills: [reviewer-protocol]" {
  local reviewer_files=(
    agents/qrspi-goals-reviewer.md
    agents/qrspi-questions-reviewer.md
    agents/qrspi-research-reviewer.md
    agents/qrspi-design-reviewer.md
    agents/qrspi-structure-reviewer.md
    agents/qrspi-phasing-reviewer.md
    agents/qrspi-plan-reviewer.md
    agents/qrspi-parallelize-reviewer.md
    agents/qrspi-replan-reviewer.md
    agents/qrspi-goals-scope-reviewer.md
    agents/qrspi-design-scope-reviewer.md
    agents/qrspi-structure-scope-reviewer.md
    agents/qrspi-phasing-scope-reviewer.md
    agents/qrspi-plan-scope-reviewer.md
    agents/qrspi-parallelize-scope-reviewer.md
    agents/qrspi-replan-scope-reviewer.md
    agents/qrspi-integration-reviewer.md
    agents/qrspi-security-integration-reviewer.md
    agents/qrspi-implement-gate-reviewer.md
    agents/qrspi-spec-reviewer.md
    agents/qrspi-code-quality-reviewer.md
    agents/qrspi-security-reviewer.md
    agents/qrspi-goal-traceability-reviewer.md
    agents/qrspi-test-coverage-reviewer.md
    agents/qrspi-silent-failure-hunter.md
    agents/qrspi-type-design-analyzer.md
    agents/qrspi-code-simplifier.md
    agents/qrspi-plan-spec-reviewer.md
    agents/qrspi-plan-security-reviewer.md
    agents/qrspi-plan-goal-traceability-reviewer.md
    agents/qrspi-plan-test-coverage-reviewer.md
    agents/qrspi-plan-silent-failure-hunter.md
  )
  for f in "${reviewer_files[@]}"; do
    awk '/^---$/{n++; next} n==1{print}' "$f" | grep -qE '^skills:.*reviewer-protocol' \
      || { echo "missing reviewer-protocol skill preload in $f"; return 1; }
  done
}
