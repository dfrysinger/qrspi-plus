#!/usr/bin/env bats
bats_require_minimum_version 1.5.0
#
# Task 08 — CD-3: anchor-phrase + structural lint for the R8 prose-density rule
# in skills/_shared/prompt-design-rules.md.
#
# Covers Test Expectations (per task-08.md):
#   1. The R8 heading is present verbatim. (CD-3 Acceptance bullet 1, sub-1)
#   2. The tightening-pattern table header is present verbatim. (sub-2)
#   3. The `What NOT to tighten` subheading is present verbatim. (sub-3)
#   4. The reviewer-test sentence is present exact. (sub-4)
#   5. The `rule-violation` row of the finding-type gate cites the literal
#      substring `R1-R8`. (CD-3 Acceptance bullet 2)
#   6. No R-rule heading is duplicated, and every R-ID cited in the
#      finding-type gate exists as a section heading. (CD-3 Acceptance bullet 4)
#   7. Fail-direction guard: a fixture file with a duplicated R3 heading
#      fails the duplicate-heading check.

setup() {
  REPO_ROOT="$(git -C "${BATS_TEST_DIRNAME}" rev-parse --show-toplevel)"
  export REPO_ROOT
  RULES_FILE="${REPO_ROOT}/skills/_shared/prompt-design-rules.md"
  export RULES_FILE
}

# ---------------------------------------------------------------------------
# Helper: count R-rule headings (lines matching `^### R<N>` for N in 1..8)
# in $1. Echoes "<id> <count>" lines for any duplicates (count > 1).
# ---------------------------------------------------------------------------
_duplicated_r_headings() {
  local file="$1"
  awk '
    /^### R[0-9]+([^0-9].*)?$/ {
      # Extract the R-ID (e.g., R3) from the heading line.
      match($0, /R[0-9]+/)
      id = substr($0, RSTART, RLENGTH)
      counts[id]++
    }
    END {
      for (id in counts) {
        if (counts[id] > 1) {
          printf "%s %d\n", id, counts[id]
        }
      }
    }
  ' "$file"
}

# ---------------------------------------------------------------------------
# Test expectation: The R8 heading is present verbatim.
# ---------------------------------------------------------------------------
@test "prompt-design-rules.md contains the verbatim R8 heading" {
  local heading='### R8 — Prose density: short declarative sentences, full behavioral precision'
  if ! grep -qxF -- "${heading}" "${RULES_FILE}"; then
    echo "R8 heading missing or paraphrased in ${RULES_FILE}" >&2
    echo "  expected verbatim line: ${heading}" >&2
    return 1
  fi
}

# ---------------------------------------------------------------------------
# Test expectation: The tightening-pattern table header is present verbatim.
# ---------------------------------------------------------------------------
@test "prompt-design-rules.md contains the verbatim tightening-pattern table header" {
  local header='| Pattern in current prose | Tightened form | Why it works |'
  if ! grep -qxF -- "${header}" "${RULES_FILE}"; then
    echo "tightening-pattern table header missing or altered in ${RULES_FILE}" >&2
    echo "  expected verbatim line: ${header}" >&2
    return 1
  fi
}

# ---------------------------------------------------------------------------
# Test expectation: The `What NOT to tighten` subheading is present verbatim.
# ---------------------------------------------------------------------------
@test "prompt-design-rules.md contains the verbatim 'What NOT to tighten' subheading" {
  # Authoring uses bold-as-subheading per the surrounding R8 prose convention.
  # We accept the bold form OR an H4 heading form, both with the exact phrase.
  if ! grep -qF -- 'What NOT to tighten' "${RULES_FILE}"; then
    echo "'What NOT to tighten' subheading missing in ${RULES_FILE}" >&2
    return 1
  fi
}

# ---------------------------------------------------------------------------
# Test expectation: The reviewer-test sentence is present exact.
# ---------------------------------------------------------------------------
@test "prompt-design-rules.md contains the verbatim R8 reviewer-test sentence" {
  local sentence='**Reviewer test:** Could this sentence be shorter without losing behavioral precision OR load-bearing rationale?'
  if ! grep -qxF -- "${sentence}" "${RULES_FILE}"; then
    echo "R8 reviewer-test sentence missing or altered in ${RULES_FILE}" >&2
    echo "  expected verbatim line: ${sentence}" >&2
    return 1
  fi
}

# ---------------------------------------------------------------------------
# Test expectation: The `rule-violation` row of the finding-type gate cites
# the literal substring `R1-R8`.
# ---------------------------------------------------------------------------
@test "finding-type gate rule-violation row cites the literal 'R1-R8' range" {
  # Find a table row that mentions both 'rule-violation' (the row label) and
  # the literal 'R1-R8' substring.
  if ! grep -E -- '\| *\*\*rule-violation\*\* *\|' "${RULES_FILE}" | grep -qF -- 'R1-R8'; then
    echo "finding-type gate 'rule-violation' row does not cite the literal 'R1-R8' range in ${RULES_FILE}" >&2
    grep -nE -- '\| *\*\*rule-violation\*\* *\|' "${RULES_FILE}" >&2 || true
    return 1
  fi
}

# ---------------------------------------------------------------------------
# Test expectation: No R-rule heading is duplicated (R1-R8 each appear
# exactly once).
# ---------------------------------------------------------------------------
@test "no R-rule heading (R1-R8) is duplicated in prompt-design-rules.md" {
  local dupes
  dupes="$(_duplicated_r_headings "${RULES_FILE}")"
  if [ -n "${dupes}" ]; then
    echo "duplicated R-rule heading(s) detected in ${RULES_FILE}:" >&2
    echo "${dupes}" >&2
    return 1
  fi

  # Also assert each of R1..R8 is present exactly once.
  local id missing=""
  for id in R1 R2 R3 R4 R5 R6 R7 R8; do
    local count
    count="$(grep -cE "^### ${id}([^0-9]|$)" "${RULES_FILE}" || true)"
    if [ "${count}" != "1" ]; then
      missing="${missing} ${id}=${count}"
    fi
  done
  if [ -n "${missing}" ]; then
    echo "expected exactly one ### heading per R-ID, got:${missing}" >&2
    return 1
  fi
}

# ---------------------------------------------------------------------------
# Test expectation: Every R-ID cited in the finding-type gate exists as a
# section heading. The gate cites the literal range 'R1-R8' — every ID in
# that range must have a ### heading.
# ---------------------------------------------------------------------------
@test "every R-ID cited in the finding-type gate has a corresponding ### heading" {
  # Extract the rule-violation row.
  local row
  row="$(grep -E -- '\| *\*\*rule-violation\*\* *\|' "${RULES_FILE}" | head -n1)"
  if [ -z "${row}" ]; then
    echo "could not locate the finding-type gate 'rule-violation' row in ${RULES_FILE}" >&2
    return 1
  fi

  # Collect cited R-IDs. Handle both individual mentions (Rn) and the literal
  # range form (Rn-Rm), expanding the range to every R-ID it contains.
  local -a cited=()
  local token
  # Individual Rn tokens.
  for token in $(printf '%s\n' "${row}" | grep -oE 'R[0-9]+' | sort -u); do
    cited+=("${token}")
  done
  # Range tokens of the form Rn-Rm — expand inclusively.
  local range
  for range in $(printf '%s\n' "${row}" | grep -oE 'R[0-9]+-R[0-9]+' | sort -u); do
    local lo hi i
    lo="${range%-*}"; lo="${lo#R}"
    hi="${range#*-}"; hi="${hi#R}"
    i="${lo}"
    while [ "${i}" -le "${hi}" ]; do
      cited+=("R${i}")
      i=$((i + 1))
    done
  done

  if [ "${#cited[@]}" -eq 0 ]; then
    echo "rule-violation row contains no R-ID citations in ${RULES_FILE}" >&2
    echo "  row: ${row}" >&2
    return 1
  fi

  local missing="" id
  for id in "${cited[@]}"; do
    if ! grep -qE "^### ${id}([^0-9]|$)" "${RULES_FILE}"; then
      missing="${missing} ${id}"
    fi
  done
  if [ -n "${missing}" ]; then
    echo "finding-type gate cites R-IDs with no matching ### heading in ${RULES_FILE}:${missing}" >&2
    return 1
  fi
}

# ---------------------------------------------------------------------------
# Test expectation: Fail-direction guard — a fixture file with a duplicated R3
# heading fails the duplicate-heading detector.
# ---------------------------------------------------------------------------
@test "fail-direction guard: duplicate-detector flags a fixture with two R3 headings" {
  local fixture="${BATS_TEST_TMPDIR}/fixture-duplicated-r3.md"
  cat >"${fixture}" <<'EOF'
# Fixture — duplicated R3 heading (intentional)

### R1 — first rule
body

### R2 — second rule
body

### R3 — third rule
body

### R3 — duplicate of third rule
body

### R4 — fourth rule
body
EOF

  local dupes
  dupes="$(_duplicated_r_headings "${fixture}")"
  if [ -z "${dupes}" ]; then
    echo "fail-direction guard: duplicate-detector did NOT flag the fixture (silent pass)" >&2
    echo "  fixture: ${fixture}" >&2
    cat "${fixture}" >&2
    return 1
  fi
  if ! printf '%s\n' "${dupes}" | grep -qE '^R3 [2-9]'; then
    echo "fail-direction guard: detector ran but did not report R3 as duplicated" >&2
    echo "  detector output:" >&2
    printf '%s\n' "${dupes}" >&2
    return 1
  fi
}
