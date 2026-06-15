#!/usr/bin/env bats
#
# Plan-level acceptance tests for G1 (Verifier rubric grounded in canonical
# ID-hygiene authority).
#
# Maps to design.md § G1 Acceptance and plan.md Phase 1 Acceptance Criteria
# bullet 6 (synthetic verifier dispatch scores ≥ 70 against
# implementer-protocol § Hygiene contract).
#
# The score-≥70 simulation lives in tests/unit/test-finding-verifier-id-hygiene-grounding.bats;
# this file asserts the chain wiring: the rubric clause is in the verifier
# agent body, the upstream-paths script appends the canonical authority, and
# the implementer-protocol Hygiene-contract anchor exists for the rubric to
# read.

setup_file() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")"/../../.. && pwd)"
  export REPO_ROOT
  export VERIFIER_AGENT="$REPO_ROOT/agents/qrspi-finding-verifier.md"
  export IMP_PROTO="$REPO_ROOT/skills/implementer-protocol/SKILL.md"
  export UPSTREAM="$REPO_ROOT/scripts/upstream-paths.sh"
}

@test "acceptance: verifier agent body carries the ID-hygiene grounding clause" {
  [ -f "$VERIFIER_AGENT" ]
  # Anchor-phrase from design.md § G1 / agents/qrspi-finding-verifier.md line 20.
  grep -qF 'skills/implementer-protocol/SKILL.md' "$VERIFIER_AGENT"
  grep -qF 'Hygiene contract' "$VERIFIER_AGENT"
}

@test "acceptance: verifier rubric directs reading via <upstream_paths> (no improvised fallback)" {
  # Acceptance contract: clause grounds the verdict in implementer-protocol
  # via upstream_paths Read; absence is a dispatch defect.
  grep -qE 'upstream_paths' "$VERIFIER_AGENT"
  grep -qE 'dispatch defect|dispatch-defect' "$VERIFIER_AGENT"
}

@test "acceptance: implementer-protocol § Hygiene contract section exists (canonical authority is materialized)" {
  [ -f "$IMP_PROTO" ]
  grep -qE '^##+ Hygiene contract' "$IMP_PROTO"
}

@test "integration: upstream-paths.sh always-appended array includes implementer-protocol on every supported step" {
  # G1 acceptance bullet 2 + plan.md Phase 1 bullet 2.
  for step in goals questions research design phasing structure parallelize replan plan; do
    if [ "$step" = "plan" ]; then
      fix="$(mktemp -d)"
      printf 'pipeline: full\n' > "$fix/config.md"
      run "$UPSTREAM" --step plan --artifact-dir "$fix"
      rm -rf "$fix"
    else
      run "$UPSTREAM" --step "$step"
    fi
    [ "$status" -eq 0 ]
    echo "$output" | grep -qx 'skills/implementer-protocol/SKILL.md'
  done
}

@test "acceptance: hygiene contract carries the Internal-ID forbidden-token table the rubric reads" {
  # Without the table existing the rubric is grounded in nothing.
  grep -qE 'Internal-ID forbidden tokens|forbidden tokens table' "$IMP_PROTO"
}
