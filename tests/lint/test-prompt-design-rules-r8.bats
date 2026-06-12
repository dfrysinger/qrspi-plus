#!/usr/bin/env bats
bats_require_minimum_version 1.5.0
#
# Task 08 — CD-3: regression guard for the R8 prose-density rule in
# skills/_shared/prompt-design-rules.md.
#
# Checks:
#   1. R8 heading present (exact anchor phrase).
#   2. Tightening-pattern table header present.
#   3. "What NOT to tighten" subheading present.
#   4. Reviewer-test sentence present.
#   5. Finding-type gate cites literal "R1-R8".
#   6. No R-rule heading is duplicated.
#   7. Every R-ID cited in the gate (R1–R8) exists as a heading.

setup() {
  REPO_ROOT="$(git -C "${BATS_TEST_DIRNAME}" rev-parse --show-toplevel)"
  RULES_FILE="${REPO_ROOT}/skills/_shared/prompt-design-rules.md"
  export REPO_ROOT RULES_FILE
}

@test "R8 heading is present in prompt-design-rules.md" {
  local heading='### R8 — Prose density: short declarative sentences, full behavioral precision'
  if ! grep -qF -- "${heading}" "${RULES_FILE}"; then
    echo "R8 heading missing in ${RULES_FILE}: expected literal line '${heading}'" >&2
    return 1
  fi
}

@test "tightening-pattern table header is present in prompt-design-rules.md" {
  local header='| Pattern in current prose | Tightened form | Why it works |'
  if ! grep -qF -- "${header}" "${RULES_FILE}"; then
    echo "tightening-pattern table header missing in ${RULES_FILE}: expected literal line '${header}'" >&2
    return 1
  fi
}

@test "'What NOT to tighten' subheading is present in prompt-design-rules.md" {
  local subheading='What NOT to tighten'
  if ! grep -qF -- "${subheading}" "${RULES_FILE}"; then
    echo "subheading missing in ${RULES_FILE}: expected literal substring '${subheading}'" >&2
    return 1
  fi
}

@test "reviewer-test sentence is present in prompt-design-rules.md" {
  local sentence='Could this sentence be shorter without losing behavioral precision OR load-bearing rationale?'
  if ! grep -qF -- "${sentence}" "${RULES_FILE}"; then
    echo "reviewer-test sentence missing in ${RULES_FILE}: expected literal substring '${sentence}'" >&2
    return 1
  fi
}

@test "finding-type gate cites literal 'R1-R8' in prompt-design-rules.md" {
  if ! grep -qF -- 'R1-R8' "${RULES_FILE}"; then
    echo "finding-type gate missing R1-R8 citation in ${RULES_FILE}: expected literal substring 'R1-R8' in the rule-violation row" >&2
    return 1
  fi
}

@test "no R-rule heading is duplicated in prompt-design-rules.md" {
  local dupes
  dupes=$(grep -oE '^### R[0-9]+ —' "${RULES_FILE}" | sort | uniq -d)
  if [[ -n "${dupes}" ]]; then
    echo "duplicate R-rule headings found in ${RULES_FILE}:" >&2
    echo "${dupes}" >&2
    return 1
  fi
}

@test "every R-ID cited in the gate (R1-R8) exists as a heading in prompt-design-rules.md" {
  local id n
  for n in 1 2 3 4 5 6 7 8; do
    id="R${n}"
    if ! grep -qE "^### ${id} —" "${RULES_FILE}"; then
      echo "heading for ${id} missing in ${RULES_FILE}: finding-type gate cites R1-R8 but '### ${id} —' heading not found" >&2
      return 1
    fi
  done
}
