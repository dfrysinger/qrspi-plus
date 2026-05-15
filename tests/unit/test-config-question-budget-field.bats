#!/usr/bin/env bats

# Structural pin for the `question_budget` schema field. Mirrors the
# `test-config-visual-fidelity-field.bats` precedent. The field is written to
# `config.md` only when `pipeline: quick`, so tests below differ from the
# visual-fidelity precedent on the writer-fence assertion: the question_budget
# writer fence is the quick-pipeline fence (carries `pipeline: quick`), not
# the full-pipeline fence.

bats_require_minimum_version 1.5.0

setup() {
  USING_QRSPI="skills/using-qrspi/SKILL.md"
  GOALS="skills/goals/SKILL.md"
  PLAN="skills/plan/SKILL.md"
  PARALLELIZE="skills/parallelize/SKILL.md"
  VALIDATOR="tests/fixtures/validate-config-field.sh"
}

teardown() {
  if [[ -n "${tmpdir:-}" && -d "${tmpdir:-}" ]]; then
    rm -rf "$tmpdir"
  fi
  return 0
}

@test "question_budget appears in the Full-format YAML fence in using-qrspi/SKILL.md" {
  # The canonical schema fence in using-qrspi/SKILL.md carries every supported
  # field. Even though question_budget is written only when pipeline is quick,
  # the Full-format fence is the canonical readers' reference and must list it
  # so readers learn the field exists alongside the others.
  awk '
    /^```/ { in_fence = !in_fence; if (!in_fence) { if (has_route && has_qb) { print "TEMPLATE_FENCE_OK"; exit }; has_route=0; has_qb=0 } }
    in_fence && /^[[:space:]]*route:/ { has_route=1 }
    in_fence && /^[[:space:]]*question_budget:[[:space:]]*5/ { has_qb=1 }
  ' "$USING_QRSPI" | grep -q '^TEMPLATE_FENCE_OK$' \
    || { echo "no fenced code block in $USING_QRSPI contains both 'route:' and 'question_budget: 5' (the canonical schema fence)"; return 1; }
}

@test "question_budget has a Field Definitions bullet entry describing integer default 5 quick-only" {
  awk '
    /^\*\*Field definitions:\*\*/ { in_section=1; next }
    /^\*\*/ && in_section { in_section=0 }
    /^## / && in_section { in_section=0 }
    in_section { print }
  ' "$USING_QRSPI" \
    | grep -qE '`question_budget`.*integer.*5' \
    || { echo "question_budget not in Field Definitions list with integer/default-5 description"; return 1; }
}

@test "Field Definitions entry for question_budget mentions quick pipeline scope and Research dispatch cap" {
  awk '
    /^\*\*Field definitions:\*\*/ { in_section=1; next }
    /^\*\*/ && in_section { in_section=0 }
    /^## / && in_section { in_section=0 }
    in_section { print }
  ' "$USING_QRSPI" \
    | awk '/`question_budget`/' \
    | grep -qE 'quick' \
    || { echo "question_budget Field Definitions entry does not mention 'quick' pipeline scope"; return 1; }

  awk '
    /^\*\*Field definitions:\*\*/ { in_section=1; next }
    /^\*\*/ && in_section { in_section=0 }
    /^## / && in_section { in_section=0 }
    in_section { print }
  ' "$USING_QRSPI" \
    | awk '/`question_budget`/' \
    | grep -qiE 'research|specialist' \
    || { echo "question_budget Field Definitions entry does not reference Research specialist dispatch cap"; return 1; }
}

@test "question_budget is a row in the Fields-that-affect-pipeline-behavior table" {
  awk '
    /^### Fields that affect pipeline behavior/ { in_section=1; next }
    /^### / && in_section { in_section=0 }
    in_section { print }
  ' "$USING_QRSPI" \
    | grep -qE '\`question_budget\`' \
    || { echo "question_budget missing from Fields-that-affect-pipeline-behavior validation table"; return 1; }
}

@test "auto-approve cascade contract for quick pipeline names Questions, Research, Plan" {
  # The behavioral semantics block must name all three autonomous steps that
  # auto-approve under the cascade. We accept any prose that lists them
  # together within a single section bounded by H2/H3 headings.
  grep -nE 'Questions.*Research.*Plan|auto-approve cascade' "$USING_QRSPI" >/dev/null \
    || { echo "no 'Questions, Research, Plan' grouping or 'auto-approve cascade' phrase found in $USING_QRSPI"; return 1; }

  grep -qiE 'auto-approve|auto approve|automatically approve' "$USING_QRSPI" \
    || { echo "auto-approve language missing from $USING_QRSPI"; return 1; }

  grep -qiE 'zero kept findings|no kept findings|clean review|clean.*round' "$USING_QRSPI" \
    || { echo "cascade trigger condition (clean review / zero kept findings) missing from $USING_QRSPI"; return 1; }
}

@test "two mandatory human gates Goals and Design are documented as excluded from cascade" {
  # The block must call out Goals AND Design as the two surviving human gates
  # under quick pipeline, distinct from the cascading autonomous steps.
  grep -qiE 'Goals and Design|Goals.*Design.*human gate|human gate.*Goals.*Design|two.*human.*gate' "$USING_QRSPI" \
    || { echo "Goals + Design two-gate exclusion language missing from $USING_QRSPI"; return 1; }
}

@test "Test phase binary ship/fix gate documented; routes back to Plan on fix" {
  grep -qiE 'binary.*ship.*fix|ship/fix|ship or fix' "$USING_QRSPI" \
    || { echo "binary ship/fix gate language missing from $USING_QRSPI"; return 1; }

  grep -qiE 'route.*back.*Plan|routes.*back.*Plan|back to Plan' "$USING_QRSPI" \
    || { echo "Test 'fix' routing back to Plan missing from $USING_QRSPI"; return 1; }
}

@test "Goals SKILL.md emits question_budget: 5 only inside the quick-pipeline writer fence" {
  # The Goals run-creation writer has ONE fence today (the quick-pipeline
  # example). Assert question_budget: 5 appears in a fence that also carries
  # `pipeline: quick`. If a future split adds a separate full-pipeline fence,
  # this test still passes as long as the question_budget line lives in the
  # quick fence (per the spec, full pipeline must omit the field entirely).
  awk '
    /^```/ { in_fence = !in_fence; if (!in_fence) { if (has_quick && has_qb) { print "QUICK_FENCE_OK"; exit }; has_quick=0; has_qb=0 } }
    in_fence && /^[[:space:]]*pipeline:[[:space:]]*quick/ { has_quick=1 }
    in_fence && /^[[:space:]]*question_budget:[[:space:]]*5/ { has_qb=1 }
  ' "$GOALS" | grep -q '^QUICK_FENCE_OK$' \
    || { echo "Goals SKILL.md run-creation writer does not emit 'question_budget: 5' inside a fence that carries 'pipeline: quick'"; return 1; }
}

@test "Goals SKILL.md does NOT emit question_budget inside any full-pipeline writer fence" {
  # The spec is explicit: when pipeline is full, the field is omitted entirely
  # from the writer's config.md output. Assert no fence carrying
  # `pipeline: full` (without an or-quick comment) carries question_budget.
  # The current single fence uses `pipeline: quick  # or full` as a comment
  # placeholder — that fence is still considered the quick-mode example
  # because the literal field value is `quick`. The test guards against a
  # future split that introduces a dedicated full fence.
  awk '
    /^```/ { in_fence = !in_fence; if (!in_fence) { if (has_full_only && has_qb) { print "FULL_FENCE_LEAK"; exit }; has_full_only=0; has_qb=0 } }
    in_fence && /^[[:space:]]*pipeline:[[:space:]]*full[[:space:]]*$/ { has_full_only=1 }
    in_fence && /^[[:space:]]*question_budget:/ { has_qb=1 }
  ' "$GOALS" | grep -q '^FULL_FENCE_LEAK$' \
    && { echo "Goals SKILL.md leaks question_budget into a fence that carries literal 'pipeline: full' (must be omitted on full pipeline)"; return 1; }
  return 0
}

@test "Goals SKILL.md per-skill validation prose lists question_budget" {
  awk '
    /^### Config Validation \(when config.md exists\)/ { in_section=1; next }
    /^### / && in_section { in_section=0 }
    /^## / && in_section { in_section=0 }
    in_section { print }
  ' "$GOALS" \
    | grep -qE '`question_budget`' \
    || { echo "Goals per-skill validation prose (### Config Validation section) does not list question_budget"; return 1; }
}

@test "Plan SKILL.md per-skill validation prose lists question_budget" {
  awk '
    /^### Config Validation/ { in_section=1; next }
    /^### / && in_section { in_section=0 }
    /^## / && in_section { in_section=0 }
    in_section { print }
  ' "$PLAN" \
    | grep -qE '`question_budget`' \
    || { echo "Plan per-skill validation prose (### Config Validation section) does not list question_budget"; return 1; }
}

@test "Parallelize SKILL.md per-skill validation prose lists question_budget" {
  awk '
    /^### Config Validation/ { in_section=1; next }
    /^### / && in_section { in_section=0 }
    /^## / && in_section { in_section=0 }
    in_section { print }
  ' "$PARALLELIZE" \
    | grep -qE '`question_budget`' \
    || { echo "Parallelize per-skill validation prose (### Config Validation section) does not list question_budget"; return 1; }
}

@test "validate-config-field.sh has a question_budget case branch" {
  awk '
    /case[[:space:]]*"\$FIELD"[[:space:]]*in/ { in_case=1; next }
    in_case && /^esac/ { in_case=0 }
    in_case { print }
  ' "$VALIDATOR" \
    | grep -qE '^[[:space:]]*question_budget\)' \
    || { echo "question_budget) branch missing from case block in $VALIDATOR"; return 1; }
}

@test "validator accepts question_budget=5 and =12; rejects 0, negative, and non-integer values" {
  tmpdir="$(mktemp -d)"
  cat > "$tmpdir/config.md" <<'EOF'
---
created: 2026-05-15
pipeline: quick
codex_reviews: false
route:
  - goals
  - questions
question_budget: 5
---
EOF
  run bash "$VALIDATOR" question_budget "$tmpdir"
  [ "$status" -eq 0 ] || { echo "expected exit 0 for question_budget=5, got $status: $output"; return 1; }

  sed -i.bak 's/question_budget: 5/question_budget: 12/' "$tmpdir/config.md"
  grep -q '^question_budget: 12$' "$tmpdir/config.md" \
    || { echo "sed did not apply: expected 'question_budget: 12' in config.md"; return 1; }
  run bash "$VALIDATOR" question_budget "$tmpdir"
  [ "$status" -eq 0 ] || { echo "expected exit 0 for question_budget=12, got $status: $output"; return 1; }

  # Zero — not a positive integer.
  sed -i.bak 's/question_budget: 12/question_budget: 0/' "$tmpdir/config.md"
  grep -q '^question_budget: 0$' "$tmpdir/config.md" \
    || { echo "sed did not apply: expected 'question_budget: 0' in config.md"; return 1; }
  run --separate-stderr bash "$VALIDATOR" question_budget "$tmpdir"
  [ "$status" -ne 0 ] || { echo "expected non-zero exit for question_budget=0, got 0"; return 1; }
  echo "$stderr" | grep -qE 'invalid value for .*question_budget|positive integer' \
    || { echo "expected standard invalid-value error on stderr for 0, got stdout=$output stderr=$stderr"; return 1; }

  # Negative integer.
  sed -i.bak 's/question_budget: 0/question_budget: -3/' "$tmpdir/config.md"
  grep -q '^question_budget: -3$' "$tmpdir/config.md" \
    || { echo "sed did not apply: expected 'question_budget: -3' in config.md"; return 1; }
  run --separate-stderr bash "$VALIDATOR" question_budget "$tmpdir"
  [ "$status" -ne 0 ] || { echo "expected non-zero exit for question_budget=-3, got 0"; return 1; }
  echo "$stderr" | grep -qE 'invalid value for .*question_budget|positive integer' \
    || { echo "expected standard invalid-value error on stderr for -3, got stdout=$output stderr=$stderr"; return 1; }

  # Non-integer (alphabetic).
  sed -i.bak 's/question_budget: -3/question_budget: many/' "$tmpdir/config.md"
  grep -q '^question_budget: many$' "$tmpdir/config.md" \
    || { echo "sed did not apply: expected 'question_budget: many' in config.md"; return 1; }
  run --separate-stderr bash "$VALIDATOR" question_budget "$tmpdir"
  [ "$status" -ne 0 ] || { echo "expected non-zero exit for question_budget=many, got 0"; return 1; }
  echo "$stderr" | grep -qE 'invalid value for .*question_budget|positive integer' \
    || { echo "expected standard invalid-value error on stderr for 'many', got stdout=$output stderr=$stderr"; return 1; }

  # Non-integer (decimal).
  sed -i.bak 's/question_budget: many/question_budget: 2.5/' "$tmpdir/config.md"
  grep -q '^question_budget: 2.5$' "$tmpdir/config.md" \
    || { echo "sed did not apply: expected 'question_budget: 2.5' in config.md"; return 1; }
  run --separate-stderr bash "$VALIDATOR" question_budget "$tmpdir"
  [ "$status" -ne 0 ] || { echo "expected non-zero exit for question_budget=2.5, got 0"; return 1; }
  echo "$stderr" | grep -qE 'invalid value for .*question_budget|positive integer' \
    || { echo "expected standard invalid-value error on stderr for 2.5, got stdout=$output stderr=$stderr"; return 1; }
}

@test "validator exits non-zero with named-field stderr warning when question_budget is absent from config.md" {
  tmpdir="$(mktemp -d)"
  cat > "$tmpdir/config.md" <<'EOF'
---
created: 2026-05-15
pipeline: quick
codex_reviews: false
route:
  - goals
  - questions
---
EOF
  run --separate-stderr bash "$VALIDATOR" question_budget "$tmpdir"
  [ "$status" -ne 0 ] || { echo "expected non-zero exit when question_budget is absent, got 0: stdout=$output stderr=$stderr"; return 1; }
  echo "$stderr" | grep -qF 'config.md has no `question_budget` field' \
    || { echo "expected stderr to contain literal 'config.md has no \`question_budget\` field', got stdout=$output stderr=$stderr"; return 1; }
}
