#!/usr/bin/env bats

# Structural file-content scan against skills/implement/SKILL.md.
# Verifies the five verifier-wiring behavioral surface phrases required by the verifier enforcement goal.
# Does NOT exercise runtime behavior of the orchestrator.
#
# All greps are section-scoped via awk extraction to prevent false-positive matches from
# unrelated sections that happen to contain the same tokens (e.g. "round:" appears dozens
# of times throughout SKILL.md in unrelated contexts).

setup() {
  REPO_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../.." && pwd -P)"
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
  # Extract the "Review Fix Loop" section into a temp file for scoped assertion.
  awk '/^### Review Fix Loop \(Inner Loop, Per-Task\)/{flag=1} flag; /^### / && !/^### Review Fix Loop \(Inner Loop, Per-Task\)/{if(flag) exit}' \
    "${SKILL_FILE}" > "${BATS_TEST_TMPDIR}/fix_loop_section.txt"

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
  # Extract the "Review Fix Loop" section — the sidecar-presence HARD-GATE (step 5) lives here.
  awk '/^### Review Fix Loop \(Inner Loop, Per-Task\)/{flag=1} flag; /^### / && !/^### Review Fix Loop \(Inner Loop, Per-Task\)/{if(flag) exit}' \
    "${SKILL_FILE}" > "${BATS_TEST_TMPDIR}/fix_loop_section.txt"

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
  # Extract the "Implement-Entry Smoke Check" section into a temp file for scoped assertion.
  awk '/^## Implement-Entry Smoke Check/{flag=1} flag; /^## / && !/^## Implement-Entry Smoke Check/{if(flag) exit}' \
    "${SKILL_FILE}" > "${BATS_TEST_TMPDIR}/smoke_section.txt"

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
# Greps are scoped to the "Review Fix Loop" section's marker-schema subsection to prevent
# false-positive matches — "round:" appears dozens of times throughout SKILL.md in unrelated
# contexts (YAML dispatch examples, round-count prose, audit-log format strings, etc.).
@test "verifier-disabled marker schema documents reason, round, and created_by fields" {
  # Extract the "Review Fix Loop" section — step 5(b) contains the marker schema documentation.
  awk '/^### Review Fix Loop \(Inner Loop, Per-Task\)/{flag=1} flag; /^### / && !/^### Review Fix Loop \(Inner Loop, Per-Task\)/{if(flag) exit}' \
    "${SKILL_FILE}" > "${BATS_TEST_TMPDIR}/fix_loop_section.txt"

  # Further narrow to the marker-schema context: extract lines following "schema-validated before acceptance"
  # up to and including the created_by field bullet — using the marker context anchor.
  awk '/schema-validated before acceptance/{flag=1} flag && /created_by.*identifying who created/{print; exit} flag' \
    "${BATS_TEST_TMPDIR}/fix_loop_section.txt" > "${BATS_TEST_TMPDIR}/marker_schema_section.txt"

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
  # Extract the "Review Fix Loop" section — the round-scoped staleness rule lives in step 5(b).
  awk '/^### Review Fix Loop \(Inner Loop, Per-Task\)/{flag=1} flag; /^### / && !/^### Review Fix Loop \(Inner Loop, Per-Task\)/{if(flag) exit}' \
    "${SKILL_FILE}" > "${BATS_TEST_TMPDIR}/fix_loop_section.txt"

  grep -qE 'not accepted when the current round|round.*not accepted|prior round.*does not satisfy|stale.*marker' \
    "${BATS_TEST_TMPDIR}/fix_loop_section.txt" \
    || { echo "MISSING: round-scoped validation rule (stale marker from prior round does not satisfy gate) not found in Review Fix Loop section of skills/implement/SKILL.md"; return 1; }
}
