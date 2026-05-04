#!/usr/bin/env bats

# Cross-cutting CI test: verifies no test file references the legacy template
# paths deleted in commit 20/22 of issue-110. This guards against the test
# suite drifting back to citing paths that no longer exist on disk.
# Added in commit 22/22 of issue-110 migration.

setup() {
  cd "$BATS_TEST_DIRNAME/../.."
}

@test "no test file references legacy template paths" {
  # Excludes the three CI test files added in commit 22/22 of issue-110, which
  # legitimately mention the forbidden patterns as part of their guard logic.
  local offenders
  offenders=$(grep -rlE '_shared/reviewer-boilerplate|_shared/templates|integrate/templates|implement/templates|test/templates|plan/templates' tests/ \
    | grep -vF 'tests/unit/test-test-skill-no-legacy-templates.bats' \
    | grep -vF 'tests/unit/test-no-deleted-files.bats' \
    | grep -vF 'tests/unit/test-dispatch-sites.bats' \
    || true)
  if [[ -n "$offenders" ]]; then
    echo "test files still reference legacy template paths:"
    echo "$offenders"
    return 1
  fi
}
