#!/usr/bin/env bats

# Structural file-content scan against skills/implement/SKILL.md.
# Verifies the five verifier-wiring behavioral surface phrases required by the verifier enforcement goal.
# Does NOT exercise runtime behavior of the orchestrator.

setup() {
  REPO_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../.." && pwd -P)"
  SKILL_FILE="${REPO_ROOT}/skills/implement/SKILL.md"
  if [ ! -f "${SKILL_FILE}" ]; then
    echo "FATAL: skills/implement/SKILL.md not found at expected path: ${SKILL_FILE}" >&2
    return 1
  fi
}

# Test case 1 — Per-task fix-loop verifier dispatch
#
# Asserts the per-task fix-loop verifier-dispatch language is present:
# a) the agent name qrspi-finding-verifier is documented
# b) the sidecar write path reviews/tasks/ with .score.yml suffix is documented
#
# Both greps must succeed; failure names the missing target.
@test "per-task fix-loop dispatch of qrspi-finding-verifier is documented" {
  grep -qF 'qrspi-finding-verifier' "${SKILL_FILE}" \
    || { echo "MISSING: agent name 'qrspi-finding-verifier' not found in skills/implement/SKILL.md"; return 1; }

  grep -qF 'reviews/tasks/' "${SKILL_FILE}" \
    || { echo "MISSING: sidecar write path 'reviews/tasks/' not found in skills/implement/SKILL.md"; return 1; }

  grep -qF '.score.yml' "${SKILL_FILE}" \
    || { echo "MISSING: sidecar suffix '.score.yml' not found in skills/implement/SKILL.md"; return 1; }
}

# Test case 2 — Sidecar-presence HARD-GATE
#
# Asserts the sidecar-presence HARD-GATE language is present:
# a) the literal token HARD-GATE is present in a context that also mentions .score.yml sidecar
# b) at least one of the two accepted escape-hatch phrasings is documented:
#    - verifier-disabled.md marker (round-NN-verifier-disabled.md)
#    - verifier_enabled: false in config
#
# Both greps must succeed; failure names the missing surface phrase.
@test "sidecar-presence HARD-GATE language with escape hatches is documented" {
  grep -qF 'HARD-GATE' "${SKILL_FILE}" \
    || { echo "MISSING: literal token 'HARD-GATE' not found in skills/implement/SKILL.md"; return 1; }

  # The HARD-GATE section must reference the .score.yml sidecar mechanism
  grep -qF '.score.yml' "${SKILL_FILE}" \
    || { echo "MISSING: '.score.yml' sidecar reference not found in skills/implement/SKILL.md"; return 1; }

  # At least one of the two accepted escape-hatch phrasings must be documented
  grep -qE 'verifier-disabled\.md|verifier_enabled:[[:space:]]*false' "${SKILL_FILE}" \
    || { echo "MISSING: neither 'verifier-disabled.md' marker nor 'verifier_enabled: false' escape hatch found in skills/implement/SKILL.md"; return 1; }
}

# Test case 3 — Implement-entry smoke check
#
# Asserts the Implement-entry smoke-check language is present at Implement entry:
# a) a smoke check token (case-insensitive) is documented
# b) the verifier agent file is named (qrspi-finding-verifier.md or agents/qrspi-finding-verifier)
# c) the sidecar write path reviews/tasks/ is named
# d) the verifier_enabled config field is named
#
# All greps must succeed; failure names the missing target.
@test "implement-entry smoke check names all three smoke targets" {
  grep -qiF 'smoke check' "${SKILL_FILE}" \
    || { echo "MISSING: 'smoke check' (case-insensitive) not found in skills/implement/SKILL.md"; return 1; }

  grep -qE 'agents/qrspi-finding-verifier|qrspi-finding-verifier\.md' "${SKILL_FILE}" \
    || { echo "MISSING: verifier agent file reference 'agents/qrspi-finding-verifier' or 'qrspi-finding-verifier.md' not found in skills/implement/SKILL.md"; return 1; }

  grep -qF 'reviews/tasks/' "${SKILL_FILE}" \
    || { echo "MISSING: sidecar write path 'reviews/tasks/' not found in skills/implement/SKILL.md"; return 1; }

  grep -qF 'verifier_enabled' "${SKILL_FILE}" \
    || { echo "MISSING: config field 'verifier_enabled' not found in skills/implement/SKILL.md"; return 1; }
}

# Test case 4 — Marker schema documentation
#
# Asserts the skill text documents the round-NN-verifier-disabled.md marker schema:
# the three required frontmatter fields: reason:, round:, created_by:
@test "verifier-disabled marker schema documents reason, round, and created_by fields" {
  grep -qF 'reason:' "${SKILL_FILE}" \
    || { echo "MISSING: 'reason:' field not documented in skills/implement/SKILL.md marker schema"; return 1; }

  grep -qF 'round:' "${SKILL_FILE}" \
    || { echo "MISSING: 'round:' field not documented in skills/implement/SKILL.md marker schema"; return 1; }

  grep -qF 'created_by:' "${SKILL_FILE}" \
    || { echo "MISSING: 'created_by:' field not documented in skills/implement/SKILL.md marker schema"; return 1; }
}

# Test case 5 — Round-scoped validation
#
# Asserts the skill text documents the round-scoped validation rule:
# a stale marker from a prior round does NOT satisfy the gate for the current round.
# The SKILL.md text reads: "a marker with `round: 2` is not accepted when the current round is 3"
@test "round-scoped validation: stale marker from prior round does not satisfy the gate" {
  grep -qE 'not accepted when the current round|round.*not accepted|prior round.*does not satisfy|stale.*marker' "${SKILL_FILE}" \
    || { echo "MISSING: round-scoped validation rule (stale marker from prior round does not satisfy gate) not found in skills/implement/SKILL.md"; return 1; }
}
