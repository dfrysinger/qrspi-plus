#!/usr/bin/env bats

# Structural file-content scan against skills/implement/SKILL.md.
# Verifies the five verifier-wiring behavioral surface phrases required by the verifier enforcement goal.
# Does NOT exercise runtime behavior of the orchestrator.
#
# All greps are section-scoped via awk extraction to prevent false-positive matches from
# unrelated sections that happen to contain the same tokens (e.g. "round:" appears dozens
# of times throughout SKILL.md in unrelated contexts).
#
# Extraction contract (uniform across all five test cases):
#   1. Each awk extraction uses STRUCTURAL exit anchors only — next `### ` heading,
#      next `## ` heading, or end-of-code-block fence (``` line). Content-based exit
#      anchors (e.g. matching specific prose phrases) are forbidden — they couple the
#      test to prose wording and rot when the skill text is reworded harmlessly.
#   2. Each awk pattern exits BEFORE printing the boundary line — the next-section heading
#      and the closing code-fence are NEVER included in the extracted slice. This prevents
#      off-by-one section-boundary inclusion where a token from a foreign section could
#      satisfy a grep that should be section-scoped.
#   3. After every extraction, an empty-extract guard fires a diagnostic to stderr and
#      fails the test setup loudly if the anchor heading was not found in the skill file.
#      A silent zero-byte extract would otherwise pass every grep with no match (failing
#      tests for the right reason but with an inscrutable message) — the guard makes the
#      missing-heading defect explicit.

setup() {
  REPO_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../.." && pwd -P)"
  if [ -z "${REPO_ROOT}" ]; then
    echo "ERROR: REPO_ROOT could not be determined" >&2
    return 1
  fi
  SKILL_FILE="${REPO_ROOT}/skills/implement/SKILL.md"
  if [ ! -f "${SKILL_FILE}" ]; then
    # Write to stdout (BATS captures stdout from setup) so the FATAL message surfaces
    # in the failure annotation regardless of output mode (--tap, --pretty, --junit).
    echo "FATAL: skills/implement/SKILL.md not found at expected path: ${SKILL_FILE}"
    return 1
  fi
}

# Test case 1 — Per-task fix-loop verifier dispatch
#
# Asserts the per-task fix-loop verifier-dispatch language is present:
# a) the agent name qrspi-finding-verifier is documented
# b) the sidecar write path reviews/tasks/ with .score.yml suffix is documented
#
# Greps are scoped to the "Review Fix Loop" section to prevent false-positive
# matches from the HARD-GATE or smoke-check sections that also mention these tokens.
# Both greps must succeed; failure names the missing target and its expected section.
@test "per-task fix-loop dispatch of qrspi-finding-verifier is documented" {
  # Extract the "Review Fix Loop (Inner Loop, Per-Task)" section into a temp file.
  # Exit anchors: next `### ` heading or next `## ` heading. The boundary line is
  # consumed by `exit` BEFORE the `flag { print }` rule runs, so the next-section
  # heading is never included in the slice.
  awk '/^### Review Fix Loop \(Inner Loop, Per-Task\)/ { flag = 1; next }
       flag && /^### |^## / { exit }
       flag { print }' \
    "${SKILL_FILE}" > "${BATS_TEST_TMPDIR}/fix_loop_section.txt"

  if [ ! -s "${BATS_TEST_TMPDIR}/fix_loop_section.txt" ]; then
    echo "EXTRACTION ERROR: section heading '### Review Fix Loop (Inner Loop, Per-Task)' not found in skills/implement/SKILL.md" >&2
    return 1
  fi

  grep -qF 'qrspi-finding-verifier' "${BATS_TEST_TMPDIR}/fix_loop_section.txt" \
    || { echo "MISSING: agent name 'qrspi-finding-verifier' not found in Review Fix Loop section of skills/implement/SKILL.md"; return 1; }

  grep -qF 'reviews/tasks/' "${BATS_TEST_TMPDIR}/fix_loop_section.txt" \
    || { echo "MISSING: sidecar write path 'reviews/tasks/' not documented in fix-loop verifier dispatch section of skills/implement/SKILL.md"; return 1; }

  grep -qF '.score.yml' "${BATS_TEST_TMPDIR}/fix_loop_section.txt" \
    || { echo "MISSING: sidecar suffix '.score.yml' not found in Review Fix Loop section of skills/implement/SKILL.md"; return 1; }
}

# Test case 2 — Sidecar-presence HARD-GATE
#
# Asserts the sidecar-presence HARD-GATE language is present:
# a) the literal token HARD-GATE is present in a context that also mentions .score.yml sidecar
# b) at least one of the two accepted escape-hatch phrasings is documented:
#    - verifier-disabled.md marker (round-NN-verifier-disabled.md)
#    - verifier_enabled: false in config
#
# Greps are scoped to the "Review Fix Loop" section (which contains step 5, the sidecar-presence
# HARD-GATE) to prevent matches on the unrelated Implement-Entry HARD-GATE block (step 3 of the
# smoke check) or the general input-gating HARD-GATE, neither of which mention .score.yml.
@test "sidecar-presence HARD-GATE language with escape hatches is documented" {
  # Extract the "Review Fix Loop (Inner Loop, Per-Task)" section — step 5 lives here.
  # Same structural extraction pattern as test 1 (exit-before-print on `### ` or `## `).
  awk '/^### Review Fix Loop \(Inner Loop, Per-Task\)/ { flag = 1; next }
       flag && /^### |^## / { exit }
       flag { print }' \
    "${SKILL_FILE}" > "${BATS_TEST_TMPDIR}/fix_loop_section.txt"

  if [ ! -s "${BATS_TEST_TMPDIR}/fix_loop_section.txt" ]; then
    echo "EXTRACTION ERROR: section heading '### Review Fix Loop (Inner Loop, Per-Task)' not found in skills/implement/SKILL.md" >&2
    return 1
  fi

  grep -qF 'HARD-GATE' "${BATS_TEST_TMPDIR}/fix_loop_section.txt" \
    || { echo "MISSING: literal token 'HARD-GATE' not found in Review Fix Loop section of skills/implement/SKILL.md"; return 1; }

  # The HARD-GATE section must reference the .score.yml sidecar mechanism
  grep -qF '.score.yml' "${BATS_TEST_TMPDIR}/fix_loop_section.txt" \
    || { echo "MISSING: '.score.yml' sidecar reference not found in Review Fix Loop section of skills/implement/SKILL.md"; return 1; }

  # At least one of the two accepted escape-hatch phrasings must be documented in the HARD-GATE section
  grep -qE 'verifier-disabled\.md|verifier_enabled:[[:space:]]*false' "${BATS_TEST_TMPDIR}/fix_loop_section.txt" \
    || { echo "MISSING: neither 'verifier-disabled.md' marker nor 'verifier_enabled: false' escape hatch found in Review Fix Loop section of skills/implement/SKILL.md"; return 1; }
}

# Test case 3 — Implement-entry smoke check
#
# Asserts the Implement-entry smoke-check language is present at Implement entry:
# a) a smoke check token (case-insensitive) is documented in the smoke-check section
# b) the verifier agent file is named (qrspi-finding-verifier.md or agents/qrspi-finding-verifier)
# c) the sidecar write path reviews/tasks/ is named
# d) the verifier_enabled config field is named
#
# Greps are scoped to the "Implement-Entry Smoke Check" section to prevent matches on the
# per-task "Smoke-Check Verification" step (§ TDD Process) which also contains "smoke check"
# but is unrelated to the verifier-wiring entry precondition.
# All greps must succeed; failure names the missing target and its expected section.
@test "implement-entry smoke check names all three smoke targets" {
  # Extract the "Implement-Entry Smoke Check" section. Exit on the next `## ` heading
  # (the section is `## `-level, so a `### ` heading within it must NOT terminate the slice;
  # only a sibling `## ` heading does). Exit-before-print prevents the next `## ` heading
  # from being included in the slice.
  awk '/^## Implement-Entry Smoke Check/ { flag = 1; next }
       flag && /^## / { exit }
       flag { print }' \
    "${SKILL_FILE}" > "${BATS_TEST_TMPDIR}/smoke_section.txt"

  if [ ! -s "${BATS_TEST_TMPDIR}/smoke_section.txt" ]; then
    echo "EXTRACTION ERROR: section heading '## Implement-Entry Smoke Check' not found in skills/implement/SKILL.md" >&2
    return 1
  fi

  grep -qiF 'smoke check' "${BATS_TEST_TMPDIR}/smoke_section.txt" \
    || { echo "MISSING: 'smoke check' (case-insensitive) not found in Implement-Entry Smoke Check section of skills/implement/SKILL.md"; return 1; }

  grep -qE 'agents/qrspi-finding-verifier|qrspi-finding-verifier\.md' "${BATS_TEST_TMPDIR}/smoke_section.txt" \
    || { echo "MISSING: verifier agent file reference 'agents/qrspi-finding-verifier' or 'qrspi-finding-verifier.md' not found in Implement-Entry Smoke Check section of skills/implement/SKILL.md"; return 1; }

  grep -qF 'reviews/tasks/' "${BATS_TEST_TMPDIR}/smoke_section.txt" \
    || { echo "MISSING: sidecar write path 'reviews/tasks/' not named as smoke-check target in Implement-Entry Smoke Check section of skills/implement/SKILL.md"; return 1; }

  grep -qF 'verifier_enabled' "${BATS_TEST_TMPDIR}/smoke_section.txt" \
    || { echo "MISSING: config field 'verifier_enabled' not found in Implement-Entry Smoke Check section of skills/implement/SKILL.md"; return 1; }
}

# Test case 4 — Marker schema documentation
#
# Asserts the skill text documents the round-NN-verifier-disabled.md marker schema:
# the three required frontmatter fields: reason:, round:, created_by:
#
# Greps are scoped to the marker-schema sub-region within "Review Fix Loop" to prevent
# false-positive matches — "round:" appears dozens of times throughout SKILL.md in unrelated
# contexts (YAML dispatch examples, round-count prose, audit-log format strings, etc.).
#
# Structural exit anchor for the marker-schema sub-region:
#   The marker schema is a paragraph followed by exactly three nested bullets at a 3-space
#   indent. The structural boundary AFTER the schema is the next top-level numbered list
#   item (e.g., `6. **Implementer-fix dispatch...**`), OR the next `### `/`## ` heading,
#   OR a code-block fence. Content-based anchors like `created_by.*identifying who created`
#   are forbidden — they couple the test to prose wording and break on harmless rewording.
@test "verifier-disabled marker schema documents reason, round, and created_by fields" {
  # Outer extraction: the "Review Fix Loop (Inner Loop, Per-Task)" section.
  awk '/^### Review Fix Loop \(Inner Loop, Per-Task\)/ { flag = 1; next }
       flag && /^### |^## / { exit }
       flag { print }' \
    "${SKILL_FILE}" > "${BATS_TEST_TMPDIR}/fix_loop_section.txt"

  if [ ! -s "${BATS_TEST_TMPDIR}/fix_loop_section.txt" ]; then
    echo "EXTRACTION ERROR: section heading '### Review Fix Loop (Inner Loop, Per-Task)' not found in skills/implement/SKILL.md" >&2
    return 1
  fi

  # Inner extraction: the marker-schema sub-region. Anchor on the "schema-validated before
  # acceptance" phrase (this is the unambiguous opening of the schema documentation — the
  # phrase appears exactly once in the skill, naming the schema-validation contract).
  # Exit anchors are STRUCTURAL ONLY:
  #   - next top-level numbered list item (^[0-9]+\.[[:space:]])
  #   - next `### ` or `## ` heading
  #   - code-block fence (^```)
  # Exit-before-print ensures the boundary line is never included.
  awk '/schema-validated before acceptance/ { flag = 1 }
       flag && /^[0-9]+\.[[:space:]]|^### |^## |^```/ { exit }
       flag { print }' \
    "${BATS_TEST_TMPDIR}/fix_loop_section.txt" > "${BATS_TEST_TMPDIR}/marker_schema_section.txt"

  if [ ! -s "${BATS_TEST_TMPDIR}/marker_schema_section.txt" ]; then
    echo "EXTRACTION ERROR: marker-schema anchor 'schema-validated before acceptance' not found in Review Fix Loop section of skills/implement/SKILL.md" >&2
    return 1
  fi

  grep -qF 'reason:' "${BATS_TEST_TMPDIR}/marker_schema_section.txt" \
    || { echo "MISSING: 'reason:' field not documented in marker schema (step 5b) of Review Fix Loop section in skills/implement/SKILL.md"; return 1; }

  grep -qF 'round:' "${BATS_TEST_TMPDIR}/marker_schema_section.txt" \
    || { echo "MISSING: 'round:' field not documented in marker schema (step 5b) of Review Fix Loop section in skills/implement/SKILL.md"; return 1; }

  grep -qF 'created_by:' "${BATS_TEST_TMPDIR}/marker_schema_section.txt" \
    || { echo "MISSING: 'created_by:' field not documented in marker schema (step 5b) of Review Fix Loop section in skills/implement/SKILL.md"; return 1; }
}

# Test case 5 — Round-scoped validation
#
# Asserts the skill text documents the round-scoped validation rule:
# a stale marker from a prior round does NOT satisfy the gate for the current round.
# The SKILL.md text reads: "a marker with `round: 2` is not accepted when the current round is 3"
#
# Grep is scoped to the "Review Fix Loop" section where step 5(b) documents the marker's
# round-matching requirement, preventing accidental matches in unrelated prose.
@test "round-scoped validation: stale marker from prior round does not satisfy the gate" {
  # Extract the "Review Fix Loop (Inner Loop, Per-Task)" section.
  awk '/^### Review Fix Loop \(Inner Loop, Per-Task\)/ { flag = 1; next }
       flag && /^### |^## / { exit }
       flag { print }' \
    "${SKILL_FILE}" > "${BATS_TEST_TMPDIR}/fix_loop_section.txt"

  if [ ! -s "${BATS_TEST_TMPDIR}/fix_loop_section.txt" ]; then
    echo "EXTRACTION ERROR: section heading '### Review Fix Loop (Inner Loop, Per-Task)' not found in skills/implement/SKILL.md" >&2
    return 1
  fi

  grep -qE 'not accepted when the current round|round.*not accepted|prior round.*does not satisfy|stale.*marker' \
    "${BATS_TEST_TMPDIR}/fix_loop_section.txt" \
    || { echo "MISSING: round-scoped validation rule (stale marker from prior round does not satisfy gate) not found in Review Fix Loop section of skills/implement/SKILL.md"; return 1; }
}
