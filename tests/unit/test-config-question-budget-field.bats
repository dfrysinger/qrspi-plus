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
  # Section-scoped grep: extract the behavioral-semantics block bounded by its
  # leading bold marker and the next H2/H3 heading, then grep within. Without
  # the section scoping, the three step names could happen to appear elsewhere
  # in the file and produce a silent pass.
  awk '
    /^\*\*Behavioral semantics — `pipeline: quick`/ { in_section=1; next }
    /^## / && in_section { in_section=0 }
    /^### / && in_section { in_section=0 }
    in_section { print }
  ' "$USING_QRSPI" > "${BATS_TEST_TMPDIR}/cascade_section.txt"

  grep -nE 'Questions.*Research.*Plan|auto-approve cascade' "${BATS_TEST_TMPDIR}/cascade_section.txt" >/dev/null \
    || { echo "no 'Questions, Research, Plan' grouping or 'auto-approve cascade' phrase in behavioral-semantics section"; return 1; }

  grep -qiE 'auto-approve|auto approve|automatically approve' "${BATS_TEST_TMPDIR}/cascade_section.txt" \
    || { echo "auto-approve language missing from behavioral-semantics section"; return 1; }

  grep -qiE 'zero kept findings|no kept findings|clean review|clean.*round' "${BATS_TEST_TMPDIR}/cascade_section.txt" \
    || { echo "cascade trigger condition (clean review / zero kept findings) missing from behavioral-semantics section"; return 1; }
}

@test "two mandatory human gates Goals and Design are documented as excluded from cascade" {
  # Section-scoped (see test above) — the Goals + Design exclusion language must
  # appear inside the behavioral-semantics block itself, not elsewhere.
  awk '
    /^\*\*Behavioral semantics — `pipeline: quick`/ { in_section=1; next }
    /^## / && in_section { in_section=0 }
    /^### / && in_section { in_section=0 }
    in_section { print }
  ' "$USING_QRSPI" > "${BATS_TEST_TMPDIR}/cascade_section.txt"

  grep -qiE 'Goals and Design|Goals.*Design.*human gate|human gate.*Goals.*Design|two.*human.*gate' "${BATS_TEST_TMPDIR}/cascade_section.txt" \
    || { echo "Goals + Design two-gate exclusion language missing from behavioral-semantics section"; return 1; }
}

@test "Test phase binary ship/fix gate documented; routes back to Plan on fix" {
  # Section-scoped (see tests above).
  awk '
    /^\*\*Behavioral semantics — `pipeline: quick`/ { in_section=1; next }
    /^## / && in_section { in_section=0 }
    /^### / && in_section { in_section=0 }
    in_section { print }
  ' "$USING_QRSPI" > "${BATS_TEST_TMPDIR}/cascade_section.txt"

  grep -qiE 'binary.*ship.*fix|ship/fix|ship or fix' "${BATS_TEST_TMPDIR}/cascade_section.txt" \
    || { echo "binary ship/fix gate language missing from behavioral-semantics section"; return 1; }

  grep -qiE 'route.*back.*Plan|routes?.*back.*Plan|routing.?back.*Plan|back to Plan|routes back to Plan' "${BATS_TEST_TMPDIR}/cascade_section.txt" \
    || { echo "Test 'fix' routing back to Plan missing from behavioral-semantics section"; return 1; }
}

@test "cascade contract: orchestrator is exclusive writer of clean.md sentinels (forgery-resistance)" {
  # The behavioral-semantics block must close the sentinel-forgery surface: a
  # compromised reviewer subagent could otherwise emit a `<reviewer-tag>.clean.md`
  # file and trick the cascade auto-approval into firing without orchestrator
  # fan-in. Pin the explicit orchestrator-exclusive-writer rule and the
  # in-session-count trigger.
  awk '
    /^\*\*Behavioral semantics — `pipeline: quick`/ { in_section=1; next }
    /^## / && in_section { in_section=0 }
    /^### / && in_section { in_section=0 }
    in_section { print }
  ' "$USING_QRSPI" > "${BATS_TEST_TMPDIR}/cascade_section.txt"

  grep -qiE 'orchestrator.*(exclusive|only).*writ(es|er).*clean' "${BATS_TEST_TMPDIR}/cascade_section.txt" \
    || { echo "missing orchestrator-exclusive-writer rule for clean.md sentinels"; return 1; }

  grep -qiE 'reviewer subagent[s]?[[:space:]]+(MUST NOT|must not|SHALL NOT|shall not)[[:space:]]+(write|emit).*(cascade.*clean|clean.*sentinel)' "${BATS_TEST_TMPDIR}/cascade_section.txt" \
    || { echo "missing explicit imperative prohibition (MUST NOT write/emit cascade clean sentinel) for reviewer subagents"; return 1; }

  grep -qiE 'in-session.*kept findings|kept findings.*count|sentinel.*audit-trail|audit-trail.*sentinel|NOT.*on-disk.*sentinel|not.*sentinel.*directly' "${BATS_TEST_TMPDIR}/cascade_section.txt" \
    || { echo "missing rule that the cascade trigger reads the orchestrator's in-session kept-findings count, not the on-disk sentinel"; return 1; }
}

@test "cascade contract: cascade-audit.log entry required per auto-approval event" {
  # The behavioral-semantics block must require an append-only audit-log entry
  # for every auto-approval: artifact name, timestamp, trigger round, contributing
  # reviewer tags, rationale (initial-clean or first-fix-clean). On write
  # failure, halt the cascade — no silent skip.
  awk '
    /^\*\*Behavioral semantics — `pipeline: quick`/ { in_section=1; next }
    /^## / && in_section { in_section=0 }
    /^### / && in_section { in_section=0 }
    in_section { print }
  ' "$USING_QRSPI" > "${BATS_TEST_TMPDIR}/cascade_section.txt"

  grep -qiE 'cascade-audit\.log|cascade-auto-approve.*audit|audit-log.*cascade|audit log.*cascade' "${BATS_TEST_TMPDIR}/cascade_section.txt" \
    || { echo "missing cascade-audit.log requirement in behavioral-semantics section"; return 1; }

  grep -qiE 'append-only|append only' "${BATS_TEST_TMPDIR}/cascade_section.txt" \
    || { echo "missing append-only requirement on cascade audit log"; return 1; }

  grep -qiE 'ISO-8601|ISO 8601|timestamp' "${BATS_TEST_TMPDIR}/cascade_section.txt" \
    || { echo "missing timestamp requirement in cascade audit-log entry"; return 1; }

  grep -qiE 'initial-clean|first-fix-clean|initial clean|first fix clean' "${BATS_TEST_TMPDIR}/cascade_section.txt" \
    || { echo "missing rationale enumeration (initial-clean vs first-fix-clean) in cascade audit-log entry"; return 1; }

  grep -qiE 'halt.*cascade|cascade.*halt|do NOT silently skip|stop.*cascade' "${BATS_TEST_TMPDIR}/cascade_section.txt" \
    || { echo "missing halt-on-write-failure rule for cascade audit-log entry"; return 1; }
}

@test "cascade trigger: zero kept findings is post-verifier-filtering, not raw" {
  # Pin the post-verifier semantics so the downstream cascade-branch implementers do not diverge
  # on whether the trigger reads pre-filter or post-filter counts.
  awk '
    /^\*\*Behavioral semantics — `pipeline: quick`/ { in_section=1; next }
    /^## / && in_section { in_section=0 }
    /^### / && in_section { in_section=0 }
    in_section { print }
  ' "$USING_QRSPI" > "${BATS_TEST_TMPDIR}/cascade_section.txt"

  grep -qiE 'after verifier.*filter|post.?verifier.*filter|verifier.?filtered|after.*verifier.?filtering' "${BATS_TEST_TMPDIR}/cascade_section.txt" \
    || { echo "missing 'zero kept findings AFTER verifier filtering' clarification (post-filter, not raw, count)"; return 1; }
}

@test "cascade contract: 'fix round' phrasing replaces round-count-bound 'second review round'" {
  # The earlier prose said 'if the second review round still carries kept
  # findings' — round-count-bound and ambiguous (round 2 vs. round 3). The
  # round-count-agnostic phrase 'fix round' avoids the ambiguity.
  ! grep -nE 'second review round' "$USING_QRSPI" \
    || { echo "round-count-bound phrase 'second review round' still present in $USING_QRSPI — replace with round-count-agnostic 'fix round'"; return 1; }

  awk '
    /^\*\*Behavioral semantics — `pipeline: quick`/ { in_section=1; next }
    /^## / && in_section { in_section=0 }
    /^### / && in_section { in_section=0 }
    in_section { print }
  ' "$USING_QRSPI" > "${BATS_TEST_TMPDIR}/cascade_section.txt"

  grep -qiE 'fix round.*kept findings|fix round.*carries' "${BATS_TEST_TMPDIR}/cascade_section.txt" \
    || { echo "missing round-count-agnostic 'fix round' phrasing in behavioral-semantics pause-condition"; return 1; }
}

@test "canonical error menu in using-qrspi/SKILL.md covers question_budget (four cases)" {
  # The 'When a required field is missing or has an invalid value' block lists
  # one menu per validated field; question_budget must have a menu in the same
  # shape as its sibling fields, covering the four failure modes:
  # missing-when-quick-required, present-when-full-forbidden, value-zero-or-negative,
  # value-non-integer.
  awk '
    /^### When a required field is missing or has an invalid value/ { in_section=1; next }
    /^### / && in_section { in_section=0 }
    /^## / && in_section { in_section=0 }
    in_section { print }
  ' "$USING_QRSPI" > "${BATS_TEST_TMPDIR}/menu_section.txt"

  grep -qE '`question_budget`' "${BATS_TEST_TMPDIR}/menu_section.txt" \
    || { echo "question_budget menu missing from canonical error-menu block"; return 1; }

  grep -qiE 'missing.*pipeline.*quick|pipeline.*quick.*required|required.*pipeline.*quick' "${BATS_TEST_TMPDIR}/menu_section.txt" \
    || { echo "missing 'missing-when-quick-required' case for question_budget"; return 1; }

  grep -qiE 'present.*pipeline.*full|pipeline.*full.*forbidden|forbidden.*pipeline.*full|omit.*pipeline.*full' "${BATS_TEST_TMPDIR}/menu_section.txt" \
    || { echo "missing 'present-when-full-forbidden' case for question_budget"; return 1; }

  grep -qiE 'zero|negative|non-positive|positive integer' "${BATS_TEST_TMPDIR}/menu_section.txt" \
    || { echo "missing zero/negative-value case for question_budget"; return 1; }

  grep -qiE 'non-integer|not an integer|integer' "${BATS_TEST_TMPDIR}/menu_section.txt" \
    || { echo "missing non-integer-value case for question_budget"; return 1; }
}

@test "validation table lists Research as a consumer-validator of question_budget" {
  # Research is the runtime CONSUMER of question_budget; without naming Research
  # as a validator (or at minimum a documented consumer dependency), a corrupted
  # value would be consumed without bounds-checking. The validation table column
  # for question_budget should mention Research alongside the other three skills.
  awk '
    /^### Fields that affect pipeline behavior/ { in_section=1; next }
    /^### / && in_section { in_section=0 }
    in_section { print }
  ' "$USING_QRSPI" > "${BATS_TEST_TMPDIR}/table_section.txt"

  awk '/`question_budget`/' "${BATS_TEST_TMPDIR}/table_section.txt" \
    | grep -qiE 'Research' \
    || { echo "Research not named as consumer/validator on question_budget validation table row"; return 1; }
}

@test "Goals writer fence emits question_budget: 5 with no inline comment that would break the validator" {
  # The validator extracts the field value as everything after 'question_budget:'
  # on the same line. An inline ' # comment' becomes part of the value and the
  # positive-integer regex rejects it. The fence must emit '5' alone (any prose
  # explanation of when the field is written belongs OUTSIDE the fence).
  awk '
    /^```/ { in_fence = !in_fence }
    in_fence && /^[[:space:]]*question_budget:/ { print }
  ' "$GOALS" > "${BATS_TEST_TMPDIR}/goals_qb_lines.txt"

  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    [[ "$line" =~ ^[[:space:]]*question_budget:[[:space:]]*[1-9][0-9]*[[:space:]]*$ ]] \
      || { echo "Goals writer fence line is not a clean 'question_budget: <int>' (inline-comment hazard): '$line'"; return 1; }
  done < "${BATS_TEST_TMPDIR}/goals_qb_lines.txt"

  [[ -s "${BATS_TEST_TMPDIR}/goals_qb_lines.txt" ]] \
    || { echo "no question_budget line found inside any fenced block in $GOALS"; return 1; }
}

@test "validator rejects question_budget upper-bound violations (>50)" {
  # Documented cap at 50 (Research specialist dispatch fan-out wider than 50
  # exhausts orchestrator subagent slots and yields diminishing returns). The
  # validator must reject 51, 100, and other above-cap values with the standard
  # invalid-value error mentioning the cap.
  tmpdir="$(mktemp -d)"
  cat > "$tmpdir/config.md" <<'EOF'
---
created: 2026-05-15
pipeline: quick
codex_reviews: false
route:
  - goals
  - questions
question_budget: 51
---
EOF
  run --separate-stderr bash "$VALIDATOR" question_budget "$tmpdir"
  [ "$status" -ne 0 ] || { echo "expected non-zero exit for question_budget=51 (above cap of 50), got 0"; return 1; }
  echo "$stderr" | grep -qiE 'invalid value.*question_budget|cap|upper bound|exceeds|out of range|50' \
    || { echo "expected invalid-value error citing the cap for question_budget=51, got stdout=$output stderr=$stderr"; return 1; }

  sed -i.bak 's/question_budget: 51/question_budget: 100/' "$tmpdir/config.md"
  run --separate-stderr bash "$VALIDATOR" question_budget "$tmpdir"
  [ "$status" -ne 0 ] || { echo "expected non-zero exit for question_budget=100 (above cap), got 0"; return 1; }
  echo "$stderr" | grep -qiE 'invalid value.*question_budget|cap|upper bound|exceeds|out of range|50' \
    || { echo "expected invalid-value error citing the cap for question_budget=100, got stdout=$output stderr=$stderr"; return 1; }
}

@test "validator accepts question_budget at the upper bound (=50) and one below (=49)" {
  tmpdir="$(mktemp -d)"
  cat > "$tmpdir/config.md" <<'EOF'
---
created: 2026-05-15
pipeline: quick
codex_reviews: false
route:
  - goals
  - questions
question_budget: 50
---
EOF
  run bash "$VALIDATOR" question_budget "$tmpdir"
  [ "$status" -eq 0 ] || { echo "expected exit 0 for question_budget=50 (at cap), got $status: $output"; return 1; }

  sed -i.bak 's/question_budget: 50/question_budget: 49/' "$tmpdir/config.md"
  run bash "$VALIDATOR" question_budget "$tmpdir"
  [ "$status" -eq 0 ] || { echo "expected exit 0 for question_budget=49 (below cap), got $status: $output"; return 1; }
}

@test "validator rejects question_budget YAML-truthy variants (yes/no/on/off/True/False)" {
  # YAML 1.1 truthy variants would be coerced to booleans by a permissive
  # reader; the strict positive-integer validator must reject them all.
  tmpdir="$(mktemp -d)"
  for variant in yes no on off True False; do
    cat > "$tmpdir/config.md" <<EOF
---
created: 2026-05-15
pipeline: quick
codex_reviews: false
route:
  - goals
question_budget: $variant
---
EOF
    run --separate-stderr bash "$VALIDATOR" question_budget "$tmpdir"
    [ "$status" -ne 0 ] || { echo "expected non-zero exit for question_budget=$variant (YAML-truthy), got 0"; return 1; }
  done
}

@test "validator rejects question_budget scientific notation (1e2)" {
  tmpdir="$(mktemp -d)"
  cat > "$tmpdir/config.md" <<'EOF'
---
created: 2026-05-15
pipeline: quick
codex_reviews: false
route:
  - goals
question_budget: 1e2
---
EOF
  run --separate-stderr bash "$VALIDATOR" question_budget "$tmpdir"
  [ "$status" -ne 0 ] || { echo "expected non-zero exit for question_budget=1e2 (scientific notation), got 0"; return 1; }
}

@test "validator rejects question_budget signed-positive (+5)" {
  tmpdir="$(mktemp -d)"
  cat > "$tmpdir/config.md" <<'EOF'
---
created: 2026-05-15
pipeline: quick
codex_reviews: false
route:
  - goals
question_budget: +5
---
EOF
  run --separate-stderr bash "$VALIDATOR" question_budget "$tmpdir"
  [ "$status" -ne 0 ] || { echo "expected non-zero exit for question_budget=+5 (signed-positive), got 0"; return 1; }
}

@test "validator rejects question_budget leading-zero (05)" {
  tmpdir="$(mktemp -d)"
  cat > "$tmpdir/config.md" <<'EOF'
---
created: 2026-05-15
pipeline: quick
codex_reviews: false
route:
  - goals
question_budget: 05
---
EOF
  run --separate-stderr bash "$VALIDATOR" question_budget "$tmpdir"
  [ "$status" -ne 0 ] || { echo "expected non-zero exit for question_budget=05 (leading-zero), got 0"; return 1; }
}

@test "validator rejects question_budget hex (0x5) and octal (010)" {
  tmpdir="$(mktemp -d)"
  cat > "$tmpdir/config.md" <<'EOF'
---
created: 2026-05-15
pipeline: quick
codex_reviews: false
route:
  - goals
question_budget: 0x5
---
EOF
  run --separate-stderr bash "$VALIDATOR" question_budget "$tmpdir"
  [ "$status" -ne 0 ] || { echo "expected non-zero exit for question_budget=0x5 (hex), got 0"; return 1; }

  sed -i.bak 's/question_budget: 0x5/question_budget: 010/' "$tmpdir/config.md"
  run --separate-stderr bash "$VALIDATOR" question_budget "$tmpdir"
  [ "$status" -ne 0 ] || { echo "expected non-zero exit for question_budget=010 (octal-like), got 0"; return 1; }
}

@test "validator rejects question_budget decimal-with-trailing-zero (5.0)" {
  tmpdir="$(mktemp -d)"
  cat > "$tmpdir/config.md" <<'EOF'
---
created: 2026-05-15
pipeline: quick
codex_reviews: false
route:
  - goals
question_budget: 5.0
---
EOF
  run --separate-stderr bash "$VALIDATOR" question_budget "$tmpdir"
  [ "$status" -ne 0 ] || { echo "expected non-zero exit for question_budget=5.0 (decimal), got 0"; return 1; }
}

@test "validator rejects question_budget with inline comment ('5  # comment')" {
  # The extractor returns everything after the colon (including trailing
  # whitespace and comment text), so an inline ' # comment' becomes part of
  # the captured value and must fail the integer-range check.
  tmpdir="$(mktemp -d)"
  cat > "$tmpdir/config.md" <<'EOF'
---
created: 2026-05-15
pipeline: quick
codex_reviews: false
route:
  - goals
question_budget: 5  # inline comment that breaks the value
---
EOF
  run --separate-stderr bash "$VALIDATOR" question_budget "$tmpdir"
  [ "$status" -ne 0 ] || { echo "expected non-zero exit for question_budget with inline comment, got 0"; return 1; }
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

@test "validator rejects question_budget integer-overflow values (INT64_MAX+1 and 20-digit string)" {
  # Arithmetic overflow guard: bash (( VALUE > 50 )) wraps on values larger than
  # INT64_MAX. INT64_MAX+1 (9223372036854775808, 19 digits) wraps to a large
  # negative number, making (( VALUE > 50 )) false and bypassing the cap entirely.
  # The length check before the arithmetic catches any value > 3 digits before
  # bash arithmetic can overflow.
  tmpdir="$(mktemp -d)"
  printf '%s\n' '---' 'created: 2026-05-15' 'pipeline: quick' 'codex_reviews: false' 'route:' '  - goals' '  - questions' 'question_budget: 9223372036854775808' '---' > "$tmpdir/config.md"
  run --separate-stderr bash "$VALIDATOR" question_budget "$tmpdir"
  [ "$status" -ne 0 ] || { echo "expected non-zero exit for question_budget=9223372036854775808 (INT64_MAX+1 overflow bypass), got 0"; return 1; }
  echo "$stderr" | grep -qiE 'too many digits|invalid value.*question_budget|cap|upper bound|exceeds|out of range|50' \
    || { echo "expected rejection error for INT64_MAX+1 overflow value, got stdout=$output stderr=$stderr"; return 1; }

  printf '%s\n' '---' 'created: 2026-05-15' 'pipeline: quick' 'codex_reviews: false' 'route:' '  - goals' '  - questions' 'question_budget: 99999999999999999999' '---' > "$tmpdir/config.md"
  run --separate-stderr bash "$VALIDATOR" question_budget "$tmpdir"
  [ "$status" -ne 0 ] || { echo "expected non-zero exit for question_budget=99999999999999999999 (20-digit overflow value), got 0"; return 1; }
  echo "$stderr" | grep -qiE 'too many digits|invalid value.*question_budget|cap|upper bound|exceeds|out of range|50' \
    || { echo "expected rejection error for 20-digit overflow value, got stdout=$output stderr=$stderr"; return 1; }
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
