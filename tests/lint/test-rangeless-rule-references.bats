#!/usr/bin/env bats
bats_require_minimum_version 1.5.0
#
# v0.7.4 audit item #3 regression lint.
#
# Defect class: hard-coded rule-range references (e.g., "R1-R7", "R1-R8")
# in prompt-prose consumer files silently drop any rule added after the
# snippet was written. The structural fix is to forbid the range form
# in consumer prose; the rules file itself uses generic framing
# ("an R-rule defined in this file") instead of pinning a count.
#
# This lint asserts the ABSENCE of `R[0-9]+-R[0-9]+` hard ranges across
# the prompt-prose surface. A small allow-list covers files that
# legitimately reference historical rule-range labels (e.g., docs/
# review notes that name "R7-R10 of the Phase 4 refactor" as a
# review-round identifier, not a rule-range claim).

setup() {
  REPO_ROOT="$(git -C "${BATS_TEST_DIRNAME}" rev-parse --show-toplevel)"
  export REPO_ROOT
}

# Files that may legitimately contain an R<n>-R<m> substring as a
# historical/review-round label, not a rule-range claim. Paths are
# relative to REPO_ROOT.
_is_allowlisted() {
  local rel="$1"
  case "${rel}" in
    # Self-references and historical examples inside the rules file.
    skills/_shared/prompt-design-rules.md) return 0 ;;
    # The audit report cites the original brittle ranges as evidence.
    docs/qrspi/*/prompt-audit-report.md) return 0 ;;
    skills/using-qrspi/references/fix-altitude-rule.md) return 0 ;;
    # The R8 lint and this lint both name the literal pattern.
    tests/lint/test-prompt-design-rules-r8.bats) return 0 ;;
    tests/lint/test-rangeless-rule-references.bats) return 0 ;;
    # build/ is regenerated; allow-list mirrors source allow-list.
    build/*) return 0 ;;
  esac
  return 1
}

@test "no prompt-prose file pins a hard rule-range (R<n>-R<m>)" {
  local violations=""
  local file rel
  while IFS= read -r file; do
    rel="${file#${REPO_ROOT}/}"
    if _is_allowlisted "${rel}"; then
      continue
    fi
    if grep -qE 'R[0-9]+-R[0-9]+' "${file}"; then
      local hits
      hits="$(grep -nE 'R[0-9]+-R[0-9]+' "${file}")"
      violations="${violations}\n${rel}:\n${hits}\n"
    fi
  done < <(find "${REPO_ROOT}/skills" "${REPO_ROOT}/agents" "${REPO_ROOT}/AGENTS.md" "${REPO_ROOT}/CLAUDE.md" \
             -type f \( -name '*.md' -o -name 'AGENTS.md' -o -name 'CLAUDE.md' \) 2>/dev/null | sort)

  if [ -n "${violations}" ]; then
    printf 'prompt-prose file(s) pin a hard rule-range (R<n>-R<m>); use rangeless framing instead:%b\n' "${violations}" >&2
    return 1
  fi
}
