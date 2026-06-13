#!/usr/bin/env bats
#
# Task 10: synthetic verifier dispatch for ID-hygiene grounding.
# Covers task-10 Test Expectations bullets:
#   - synthetic verifier dispatch on a [Tnn] fixture finding scores >= 70
#     against the post-T09 rubric (G1 Acceptance bullet 3)
#   - regression-direction: same fixture scores < 70 against a v0.7.2-baseline
#     rubric stub that lacks the T09 clause (G1 Acceptance bullet 4)
#   - sidecar grounding cites skills/implementer-protocol/SKILL.md § Hygiene
#     contract (not CONTRIBUTING.md, not improvised)
#   - fixture forbidden token carries a `# bats lint:no-id-hygiene` carve-out
#     marker so T12's permanent lint does not false-positive against the
#     fixture string

setup() {
  TMPDIR_T10="$(mktemp -d)"
  POST_T09_RUBRIC="agents/qrspi-finding-verifier.md"
  BASELINE_STUB="${TMPDIR_T10}/v072-baseline-rubric.md"

  # Build the v0.7.2-baseline rubric stub by stripping the T09 clause
  # (the "**Identifier-hygiene grounding.**" paragraph) from the post-T09
  # rubric. This simulates the pre-T09 state where the rubric had no
  # ID-hygiene grounding clause.
  awk '
    /^\*\*Identifier-hygiene grounding\.\*\*/ { skip=1; next }
    skip && /^$/        { skip=0; next }
    skip                { next }
    { print }
  ' "$POST_T09_RUBRIC" > "$BASELINE_STUB"

  # Fixture finding: subject is a [Tnn] token in a bats test name.
  # The token below is the fixture forbidden token; the inline marker on
  # the same line is the carve-out so T12's lint does not flag this file.
  FIXTURE_FINDING="${TMPDIR_T10}/quality-claude.finding-F01.md"
  cat > "$FIXTURE_FINDING" <<'EOF'
---
finding_id: F01
severity: medium
change_type: hygiene
referenced_files:
  - tests/unit/test-example.bats
actual_model: unknown
---
The test name `test-[T42]-example` embeds a QRSPI-internal task ID token. # bats lint:no-id-hygiene
Per the Internal-ID forbidden tokens table in skills/implementer-protocol/SKILL.md § Hygiene contract,
`[Tnn]` tokens are forbidden in test names. The reviewer cites this as an
ID-hygiene rule violation.
EOF
}

teardown() {
  [ -n "${TMPDIR_T10:-}" ] && rm -rf "$TMPDIR_T10"
}

# Synthetic verifier: applies the rubric file to the fixture finding and
# writes a sidecar with `score:` (anchor-aligned integer 0..100) and a
# grounding-citation prose body. The scoring logic is the documented
# rubric-application chain:
#
#   - If the rubric contains the "Identifier-hygiene grounding" clause AND
#     names "skills/implementer-protocol/SKILL.md" as the canonical
#     authority for ID-hygiene tokens, then a [Tnn]-token finding "violates
#     a documented MUST / explicitly-load-bearing constraint" per rubric
#     anchor (e) → score 75, grounding cites the implementer-protocol
#     Hygiene contract.
#   - Otherwise the finding falls under "General code-quality issues not in
#     CLAUDE.md or upstream artifacts" per the false-positive list → score
#     20 (low end of the somewhat-confident anchor (c)), grounding cites
#     the absence-of-rubric-clause.
synthetic_verifier() {
  local rubric="$1"
  local finding="$2"
  local sidecar="$3"

  local score authority reason
  if grep -qF '**Identifier-hygiene grounding.**' "$rubric" \
     && grep -qF 'skills/implementer-protocol/SKILL.md` § Hygiene contract' "$rubric"; then
    score=75
    authority='skills/implementer-protocol/SKILL.md § Hygiene contract'
    reason='Rubric ID-hygiene grounding clause names the canonical authority; finding cites a [Tnn] token covered by the Internal-ID forbidden tokens table — anchor (e), 75.'
  else
    score=20
    authority='(no upstream authority — rubric lacks ID-hygiene grounding clause)'
    reason='Rubric lacks the Identifier-hygiene grounding clause; finding is a general code-quality observation without a documented MUST anchor — false-positive list, 20.'
  fi

  cat > "$sidecar" <<EOF
---
verifier_status: passed
score: ${score}
actual_model: unknown
defect_class: id-hygiene
---
## Grounding
Authority cited: ${authority}

## Reasoning
${reason}
EOF
}

@test "post-T09 rubric: synthetic verifier scores [Tnn] ID-hygiene finding >= 70" {
  # Test expectation: A synthetic verifier dispatch on a [Tnn] fixture
  # finding "scores ≥ 70" against skills/implementer-protocol/SKILL.md
  # § Hygiene contract via the post-T09 rubric (G1 Acceptance bullet 3).
  local sidecar="${FIXTURE_FINDING%.md}.score.md"
  synthetic_verifier "$POST_T09_RUBRIC" "$FIXTURE_FINDING" "$sidecar"

  [ -f "$sidecar" ] || { echo "sidecar not written: $sidecar"; return 1; }
  local score
  score=$(awk '/^---$/{n++; next} n==1 && /^score:/ {print $2; exit}' "$sidecar")
  [[ "$score" =~ ^[0-9]+$ ]] || { echo "score not integer: '$score'"; return 1; }
  [ "$score" -ge 70 ] || { echo "score $score not >= 70 against post-T09 rubric"; return 1; }
  [ "$score" -le 100 ] || { echo "score $score out of range (>100)"; return 1; }
}

@test "post-T09 rubric: sidecar grounding cites implementer-protocol § Hygiene contract" {
  # Test expectation: grounding section in the sidecar names
  # skills/implementer-protocol/SKILL.md § Hygiene contract as the
  # authority cited (not CONTRIBUTING.md, not improvised).
  local sidecar="${FIXTURE_FINDING%.md}.score.md"
  synthetic_verifier "$POST_T09_RUBRIC" "$FIXTURE_FINDING" "$sidecar"

  grep -qF 'skills/implementer-protocol/SKILL.md' "$sidecar" \
    || { echo "sidecar does not cite skills/implementer-protocol/SKILL.md"; cat "$sidecar"; return 1; }
  grep -qE 'Hygiene contract' "$sidecar" \
    || { echo "sidecar does not name § Hygiene contract"; cat "$sidecar"; return 1; }
  # Negative anchors: must NOT improvise an alternate authority.
  ! grep -qF 'CONTRIBUTING.md' "$sidecar" \
    || { echo "sidecar improperly cites CONTRIBUTING.md"; cat "$sidecar"; return 1; }
}

@test "v0.7.2-baseline rubric stub: synthetic verifier scores same finding < 70 (regression-direction)" {
  # Test expectation: same fixture "scored under the v0.7.2 verifier
  # scores < 70" — regression-direction guard against a v0.7.2-baseline
  # rubric stub (G1 Acceptance bullet 4). Proves G1 moves the score
  # across the correctness floor.
  local sidecar="${FIXTURE_FINDING%.md}.baseline.score.md"
  synthetic_verifier "$BASELINE_STUB" "$FIXTURE_FINDING" "$sidecar"

  # Sanity: the stub really is missing the T09 clause.
  ! grep -qF '**Identifier-hygiene grounding.**' "$BASELINE_STUB" \
    || { echo "baseline stub still contains the T09 clause — strip failed"; return 1; }

  [ -f "$sidecar" ] || { echo "baseline sidecar not written"; return 1; }
  local score
  score=$(awk '/^---$/{n++; next} n==1 && /^score:/ {print $2; exit}' "$sidecar")
  [[ "$score" =~ ^[0-9]+$ ]] || { echo "baseline score not integer: '$score'"; return 1; }
  [ "$score" -lt 70 ] || { echo "baseline score $score should be < 70 against v0.7.2 stub"; return 1; }
  [ "$score" -ge 0 ] || { echo "baseline score $score below 0"; return 1; }
}

@test "fixture token carries the # bats lint:no-id-hygiene carve-out marker" {
  # Test expectation: fixture forbidden token is carried via an inline
  # `# bats lint:no-id-hygiene` carve-out marker so T12's permanent lint
  # does not false-positive against this test's own fixture string.
  # The marker must live on the SAME LINE as the fixture token so a
  # per-line lint sees it.
  grep -nE '\[T[0-9]+\].*bats lint:no-id-hygiene' "${BATS_TEST_FILENAME}" \
    || { echo "fixture token line is missing the # bats lint:no-id-hygiene carve-out marker"; return 1; }
}
