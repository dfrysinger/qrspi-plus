#!/usr/bin/env bats

# Structural pin for the `visual_fidelity_required` schema field. Mirrors the
# `test-config-verifier-enabled-field.bats` precedent — the field-addition
# protocol authored in `using-qrspi/SKILL.md` requires this field to land in
# seven coordinated surfaces, and this file asserts the presence of each one.

bats_require_minimum_version 1.5.0

setup() {
  USING_QRSPI="skills/using-qrspi/SKILL.md"
  GOALS="skills/goals/SKILL.md"
  VALIDATOR="tests/fixtures/validate-config-field.sh"
}

teardown() {
  # Guaranteed post-test cleanup of any per-test tmpdir created by tests below.
  # Bats invokes teardown after every test (pass or fail), so this fires even
  # when an assertion short-circuits the test body. The explicit `return 0`
  # ensures teardown succeeds even when no tmpdir was created (most tests in
  # this file are file-grep only and never set tmpdir).
  if [[ -n "${tmpdir:-}" && -d "${tmpdir:-}" ]]; then
    rm -rf "$tmpdir"
  fi
  return 0
}

@test "visual_fidelity_required: false appears in a Full-format YAML fence in using-qrspi/SKILL.md" {
  # Walk fenced code blocks and assert at least one fence contains both
  # `route:` (a Full-format fence marker) and `visual_fidelity_required: false`.
  awk '
    /^```/ { in_fence = !in_fence; if (!in_fence) { if (has_route && has_vfr) { print "TEMPLATE_FENCE_OK"; exit }; has_route=0; has_vfr=0 } }
    in_fence && /^[[:space:]]*route:/ { has_route=1 }
    in_fence && /^[[:space:]]*visual_fidelity_required:[[:space:]]*false/ { has_vfr=1 }
  ' "$USING_QRSPI" | grep -q '^TEMPLATE_FENCE_OK$' \
    || { echo "no fenced code block in $USING_QRSPI contains both 'route:' and 'visual_fidelity_required: false' (the Full-format fence)"; return 1; }
}

@test "visual_fidelity_required has a Field Definitions bullet entry describing boolean default false" {
  awk '
    /^\*\*Field definitions:\*\*/ { in_section=1; next }
    /^\*\*/ && in_section { in_section=0 }
    /^## / && in_section { in_section=0 }
    in_section { print }
  ' "$USING_QRSPI" \
    | grep -qE '`visual_fidelity_required`.*(boolean|default).*false' \
    || { echo "visual_fidelity_required not in Field Definitions list with boolean/default-false description"; return 1; }
}

@test "visual_fidelity_required is a row in the Fields-that-affect-pipeline-behavior table" {
  awk '
    /^### Fields that affect pipeline behavior/ { in_section=1; next }
    /^### / && in_section { in_section=0 }
    in_section { print }
  ' "$USING_QRSPI" \
    | grep -qE '\`visual_fidelity_required\`' \
    || { echo "visual_fidelity_required missing from Fields-that-affect-pipeline-behavior validation table or bullet list"; return 1; }
}

@test "missing-field menu entry exists for visual_fidelity_required" {
  awk '
    /^### When a required field is missing or has an invalid value/ { in_section=1; next }
    /^### / && in_section { in_section=0 }
    in_section { print }
  ' "$USING_QRSPI" \
    | grep -qE '`visual_fidelity_required`' \
    || { echo "visual_fidelity_required missing-field menu entry not in 'When a required field is missing or has an invalid value' section"; return 1; }
}

@test "runtime-backfill carve-out for visual_fidelity_required documented in Exceptions" {
  awk '
    /^### Exceptions to the no-silent-defaults rule/ { in_section=1; next }
    /^### / && in_section { in_section=0 }
    in_section { print }
  ' "$USING_QRSPI" \
    | grep -qE 'visual_fidelity_required.*runtime backfill|runtime backfill.*visual_fidelity_required' \
    || { echo "runtime-backfill carve-out for visual_fidelity_required not in ### Exceptions section"; return 1; }
}

@test "Goals SKILL.md emits visual_fidelity_required: false in a run-creation config.md writer fence" {
  awk '
    /^```/ { in_fence = !in_fence; if (!in_fence) { if (has_route && has_vfr) { print "WRITER_FENCE_OK"; exit }; has_route=0; has_vfr=0 } }
    in_fence && /^[[:space:]]*route:/ { has_route=1 }
    in_fence && /^[[:space:]]*visual_fidelity_required:[[:space:]]*false/ { has_vfr=1 }
  ' "$GOALS" | grep -q '^WRITER_FENCE_OK$' \
    || { echo "Goals SKILL.md run-creation config.md writer fence does not emit 'visual_fidelity_required: false'"; return 1; }
}

@test "Goals SKILL.md per-skill validation prose lists visual_fidelity_required" {
  grep -qE 'Goals validates.*visual_fidelity_required|visual_fidelity_required.*Goals validates' "$GOALS" \
    || grep -qE 'Goals validates[^.]*\`visual_fidelity_required\`' "$GOALS" \
    || { echo "Goals per-skill validation prose does not list visual_fidelity_required"; return 1; }
}

@test "validate-config-field.sh has a visual_fidelity_required case branch" {
  # Extract the contents of the case "$FIELD" in ... esac block and confirm
  # a visual_fidelity_required) pattern is one of the branches.
  awk '
    /case[[:space:]]*"\$FIELD"[[:space:]]*in/ { in_case=1; next }
    in_case && /^esac/ { in_case=0 }
    in_case { print }
  ' "$VALIDATOR" \
    | grep -qE '^[[:space:]]*visual_fidelity_required\)' \
    || { echo "visual_fidelity_required) branch missing from case block in $VALIDATOR"; return 1; }
}

@test "validator accepts visual_fidelity_required=true and =false; rejects other values" {
  tmpdir="$(mktemp -d)"
  cat > "$tmpdir/config.md" <<'EOF'
---
created: 2026-05-14
pipeline: full
codex_reviews: false
route:
  - goals
  - questions
visual_fidelity_required: true
---
EOF
  run bash "$VALIDATOR" visual_fidelity_required "$tmpdir"
  [ "$status" -eq 0 ] || { echo "expected exit 0 for visual_fidelity_required=true, got $status: $output"; return 1; }

  sed -i.bak 's/visual_fidelity_required: true/visual_fidelity_required: false/' "$tmpdir/config.md"
  run bash "$VALIDATOR" visual_fidelity_required "$tmpdir"
  [ "$status" -eq 0 ] || { echo "expected exit 0 for visual_fidelity_required=false, got $status: $output"; return 1; }

  sed -i.bak 's/visual_fidelity_required: false/visual_fidelity_required: yesplease/' "$tmpdir/config.md"
  # Separate stderr from stdout: the validator writes its invalid-value
  # diagnostic to stderr (per task-01 spec line 34), so assert against $stderr.
  run --separate-stderr bash "$VALIDATOR" visual_fidelity_required "$tmpdir"
  [ "$status" -ne 0 ] || { echo "expected non-zero exit for invalid value, got 0"; return 1; }
  echo "$stderr" | grep -qE 'invalid value for .*visual_fidelity_required|Expected.*true.*false' \
    || { echo "expected standard invalid-value error on stderr, got stdout=$output stderr=$stderr"; return 1; }

  # Cleanup is handled by teardown().
}

@test "missing-field menu and exceptions both describe the backfill behavior consistently" {
  # The carve-out paragraph must document the two observable side effects:
  # a stderr warning naming the field, and writing the default back to config.md.
  awk '
    /^### Exceptions to the no-silent-defaults rule/ { in_section=1; next }
    /^### / && in_section { in_section=0 }
    in_section { print }
  ' "$USING_QRSPI" \
    | awk '/visual_fidelity_required/,/^$/' \
    | grep -qE 'stderr|warning' \
    || { echo "visual_fidelity_required carve-out missing stderr/warning language"; return 1; }

  awk '
    /^### Exceptions to the no-silent-defaults rule/ { in_section=1; next }
    /^### / && in_section { in_section=0 }
    in_section { print }
  ' "$USING_QRSPI" \
    | awk '/visual_fidelity_required/,/^$/' \
    | grep -qE 'writes the field back|append.*default|backfilling default' \
    || { echo "visual_fidelity_required carve-out missing write-back-to-config.md language"; return 1; }
}
