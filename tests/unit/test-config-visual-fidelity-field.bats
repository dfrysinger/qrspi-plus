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
  # Broadened per round-02 F05: scope to the "Config Validation" section and
  # accept any line within that section that mentions the field. The prior
  # pattern required the literal substring "Goals validates" adjacent to the
  # field name, which was more restrictive than the spec ("lists the field …
  # alongside the other validated fields").
  awk '
    /^### Config Validation \(when config.md exists\)/ { in_section=1; next }
    /^### / && in_section { in_section=0 }
    /^## / && in_section { in_section=0 }
    in_section { print }
  ' "$GOALS" \
    | grep -qE '`visual_fidelity_required`' \
    || { echo "Goals per-skill validation prose (### Config Validation section) does not list visual_fidelity_required"; return 1; }
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
  # Round-02 F06 guard: pin the silent-mismatch risk by asserting the sed
  # transformation took effect before invoking the validator on the wrong input.
  grep -q '^visual_fidelity_required: false$' "$tmpdir/config.md" \
    || { echo "sed did not apply: expected 'visual_fidelity_required: false' in config.md"; return 1; }
  run bash "$VALIDATOR" visual_fidelity_required "$tmpdir"
  [ "$status" -eq 0 ] || { echo "expected exit 0 for visual_fidelity_required=false, got $status: $output"; return 1; }

  sed -i.bak 's/visual_fidelity_required: false/visual_fidelity_required: yesplease/' "$tmpdir/config.md"
  grep -q '^visual_fidelity_required: yesplease$' "$tmpdir/config.md" \
    || { echo "sed did not apply: expected 'visual_fidelity_required: yesplease' in config.md"; return 1; }
  # Separate stderr from stdout: the validator writes its invalid-value
  # diagnostic to stderr (per task-01 spec line 34), so assert against $stderr.
  run --separate-stderr bash "$VALIDATOR" visual_fidelity_required "$tmpdir"
  [ "$status" -ne 0 ] || { echo "expected non-zero exit for invalid value, got 0"; return 1; }
  echo "$stderr" | grep -qE 'invalid value for .*visual_fidelity_required|Expected.*true.*false' \
    || { echo "expected standard invalid-value error on stderr, got stdout=$output stderr=$stderr"; return 1; }

  # Round-02 F03: document the case-sensitive contract. `True` (capital T) is
  # a plausible user mistake / YAML-parser pre-normalization edge; the
  # validator's comparison is case-sensitive (`!= "true" && != "false"`) so
  # `True` must be rejected with the standard invalid-value error on stderr.
  sed -i.bak 's/visual_fidelity_required: yesplease/visual_fidelity_required: True/' "$tmpdir/config.md"
  grep -q '^visual_fidelity_required: True$' "$tmpdir/config.md" \
    || { echo "sed did not apply: expected 'visual_fidelity_required: True' in config.md"; return 1; }
  run --separate-stderr bash "$VALIDATOR" visual_fidelity_required "$tmpdir"
  [ "$status" -ne 0 ] || { echo "expected non-zero exit for case-sensitive 'True', got 0"; return 1; }
  echo "$stderr" | grep -qE 'invalid value for .*visual_fidelity_required|Expected.*true.*false' \
    || { echo "expected standard invalid-value error on stderr for 'True', got stdout=$output stderr=$stderr"; return 1; }

  # Cleanup is handled by teardown().
}

@test "validator exits non-zero with named-field stderr warning when visual_fidelity_required is absent from config.md" {
  # Round-02 F01 (test-coverage HIGH): cover the missing-field path at
  # validator lines 174–181. Round 02 redirected the missing-field menu to
  # stderr — without this test, that redirect could be silently reverted.
  tmpdir="$(mktemp -d)"
  cat > "$tmpdir/config.md" <<'EOF'
---
created: 2026-05-14
pipeline: full
codex_reviews: false
route:
  - goals
  - questions
---
EOF
  run --separate-stderr bash "$VALIDATOR" visual_fidelity_required "$tmpdir"
  [ "$status" -ne 0 ] || { echo "expected non-zero exit when visual_fidelity_required is absent, got 0: stdout=$output stderr=$stderr"; return 1; }
  echo "$stderr" | grep -qF 'config.md has no `visual_fidelity_required` field' \
    || { echo "expected stderr to contain literal 'config.md has no \`visual_fidelity_required\` field', got stdout=$output stderr=$stderr"; return 1; }
}

@test "validator exits non-zero with present-but-empty stderr warning when visual_fidelity_required value is blank" {
  # Round-02 F02 + goal-traceability F01 (HIGH): cover the empty-value branch
  # at validator lines 184–191. The "present but extraction returned empty"
  # diagnostic is a distinct path from the standard invalid-value menu and
  # exists precisely to surface malformed-frontmatter anomalies — without this
  # test, a future refactor could silently collapse it back into the invalid-
  # value branch.
  tmpdir="$(mktemp -d)"
  cat > "$tmpdir/config.md" <<'EOF'
---
created: 2026-05-14
pipeline: full
codex_reviews: false
route:
  - goals
  - questions
visual_fidelity_required:
---
EOF
  run --separate-stderr bash "$VALIDATOR" visual_fidelity_required "$tmpdir"
  [ "$status" -ne 0 ] || { echo "expected non-zero exit for present-but-empty visual_fidelity_required value, got 0: stdout=$output stderr=$stderr"; return 1; }
  echo "$stderr" | grep -qF 'present but extraction returned empty' \
    || { echo "expected stderr to contain 'present but extraction returned empty', got stdout=$output stderr=$stderr"; return 1; }
}

@test "using-qrspi/SKILL.md carve-out prose documents the runtime-backfill contract (behavioral test deferred to task-02)" {
  # Round-02 F04 rename: this test is a prose-content check that the carve-out
  # paragraph in `using-qrspi/SKILL.md` describes the two observable side
  # effects (stderr warning + write-back). It does NOT exercise the runtime
  # backfill code path — the consuming-skill backfill logic lands in a later
  # task; the behavioral assertion (invoke the backfill path and verify the
  # warning + appended default) is deferred to task-02 (the goals-skill update)
  # or whichever later task introduces the read-time backfill consumer.
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
