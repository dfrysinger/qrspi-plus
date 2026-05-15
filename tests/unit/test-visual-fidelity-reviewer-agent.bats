#!/usr/bin/env bats

# Structural pins for agents/qrspi-visual-fidelity-reviewer.md.
# Asserts frontmatter shape, dispatch-parameter contract, silent-skip
# documentation, path-traversal refusal, and the skipped-sentinel schema in
# skills/using-qrspi/SKILL.md.
#
# Every assertion targets observable file content only — no production code
# executes at test time. Mirrors the structural patterns used in
# test-config-verifier-enabled-field.bats and test-verifier-agent-file.bats.

bats_require_minimum_version 1.5.0

setup() {
  # All paths are relative to the repository root, which bats resolves by
  # stepping two directories up from tests/unit/.
  cd "$BATS_TEST_DIRNAME/../.."
  AGENT="agents/qrspi-visual-fidelity-reviewer.md"
  USING_QRSPI="skills/using-qrspi/SKILL.md"
}

# ---------------------------------------------------------------------------
# 1. Agent file existence
# ---------------------------------------------------------------------------

@test "agent file exists at agents/qrspi-visual-fidelity-reviewer.md" {
  [ -f "$AGENT" ] \
    || { echo "agent file not found: $AGENT"; return 1; }
}

# ---------------------------------------------------------------------------
# 2. Frontmatter shape
# ---------------------------------------------------------------------------

@test "agent file declares model: sonnet" {
  awk '/^---$/{n++; next} n==1{print} n==2{exit}' "$AGENT" \
    | grep -qE '^model:[[:space:]]*sonnet$' \
    || { echo "frontmatter in $AGENT does not declare 'model: sonnet'"; return 1; }
}

@test "agent file declares tools: including Read" {
  awk '/^---$/{n++; next} n==1{print} n==2{exit}' "$AGENT" \
    | grep -qE '^tools:.*\bRead\b' \
    || { echo "frontmatter in $AGENT tools: line does not include 'Read'"; return 1; }
}

@test "agent file declares tools: including Write" {
  awk '/^---$/{n++; next} n==1{print} n==2{exit}' "$AGENT" \
    | grep -qE '^tools:.*\bWrite\b' \
    || { echo "frontmatter in $AGENT tools: line does not include 'Write'"; return 1; }
}

@test "agent file declares skills: including reviewer-protocol" {
  awk '/^---$/{n++; next} n==1{print} n==2{exit}' "$AGENT" \
    | grep -qE '^skills:.*reviewer-protocol' \
    || { echo "frontmatter in $AGENT does not declare skills: [reviewer-protocol]"; return 1; }
}

@test "agent file declares name: qrspi-visual-fidelity-reviewer" {
  awk '/^---$/{n++; next} n==1{print} n==2{exit}' "$AGENT" \
    | grep -qE '^name:[[:space:]]*qrspi-visual-fidelity-reviewer$' \
    || { echo "frontmatter in $AGENT does not declare 'name: qrspi-visual-fidelity-reviewer'"; return 1; }
}

# ---------------------------------------------------------------------------
# 3. Dispatch-parameter contract documented in agent body
#    (all seven parameters from structure.md § "qrspi-visual-fidelity-reviewer
#    agent frontmatter contract" must appear verbatim)
# ---------------------------------------------------------------------------

@test "agent body documents artifact_body dispatch parameter" {
  awk '/^---$/{n++; next} n>=2{print}' "$AGENT" \
    | grep -qE '\bartifact_body\b' \
    || { echo "$AGENT body does not document the 'artifact_body' dispatch parameter"; return 1; }
}

@test "agent body documents wireframe_paths dispatch parameter" {
  awk '/^---$/{n++; next} n>=2{print}' "$AGENT" \
    | grep -qE '\bwireframe_paths\b' \
    || { echo "$AGENT body does not document the 'wireframe_paths' dispatch parameter"; return 1; }
}

@test "agent body documents screenshot_paths dispatch parameter" {
  awk '/^---$/{n++; next} n>=2{print}' "$AGENT" \
    | grep -qE '\bscreenshot_paths\b' \
    || { echo "$AGENT body does not document the 'screenshot_paths' dispatch parameter"; return 1; }
}

@test "agent body documents round_subdir dispatch parameter" {
  awk '/^---$/{n++; next} n>=2{print}' "$AGENT" \
    | grep -qE '\bround_subdir\b' \
    || { echo "$AGENT body does not document the 'round_subdir' dispatch parameter"; return 1; }
}

@test "agent body documents round dispatch parameter" {
  awk '/^---$/{n++; next} n>=2{print}' "$AGENT" \
    | grep -qE '\bround\b' \
    || { echo "$AGENT body does not document the 'round' dispatch parameter"; return 1; }
}

@test "agent body documents reviewer_tag set to visual-fidelity-claude" {
  awk '/^---$/{n++; next} n>=2{print}' "$AGENT" \
    | grep -qE '\breviewer_tag\b' \
    || { echo "$AGENT body does not document the 'reviewer_tag' dispatch parameter"; return 1; }
  awk '/^---$/{n++; next} n>=2{print}' "$AGENT" \
    | grep -qE 'visual-fidelity-claude' \
    || { echo "$AGENT body does not document reviewer_tag value 'visual-fidelity-claude'"; return 1; }
}

@test "agent body documents diff_file_path dispatch parameter" {
  awk '/^---$/{n++; next} n>=2{print}' "$AGENT" \
    | grep -qE '\bdiff_file_path\b' \
    || { echo "$AGENT body does not document the 'diff_file_path' dispatch parameter"; return 1; }
}

# ---------------------------------------------------------------------------
# 4. Silent-skip condition documentation
# ---------------------------------------------------------------------------

@test "agent body documents visual_fidelity_required_false silent-skip condition" {
  awk '/^---$/{n++; next} n>=2{print}' "$AGENT" \
    | grep -qE 'visual_fidelity_required' \
    || { echo "$AGENT body does not document the visual_fidelity_required silent-skip condition"; return 1; }
}

@test "agent body documents missing_visual_fidelity_check silent-skip condition" {
  awk '/^---$/{n++; next} n>=2{print}' "$AGENT" \
    | grep -qE 'visual_fidelity_check' \
    || { echo "$AGENT body does not document the missing visual_fidelity_check silent-skip condition"; return 1; }
}

@test "agent body documents empty_wireframe_paths silent-skip condition" {
  awk '/^---$/{n++; next} n>=2{print}' "$AGENT" \
    | grep -qE 'empty_wireframe_paths|wireframe_paths.*empty|empty.*wireframe_paths' \
    || { echo "$AGENT body does not document the empty_wireframe_paths silent-skip condition"; return 1; }
}

@test "agent body documents empty_screenshot_paths silent-skip condition" {
  awk '/^---$/{n++; next} n>=2{print}' "$AGENT" \
    | grep -qE 'empty_screenshot_paths|screenshot_paths.*empty|empty.*screenshot_paths' \
    || { echo "$AGENT body does not document the empty_screenshot_paths silent-skip condition"; return 1; }
}

# ---------------------------------------------------------------------------
# 5. Path-traversal refusal (belt-and-suspenders, agent-side)
# ---------------------------------------------------------------------------

@test "agent body documents path-traversal refusal naming the allow-prefix check and refusal outcome" {
  awk '/^---$/{n++; next} n>=2{print}' "$AGENT" \
    | grep -qiE 'allow.prefix|allow_prefix' \
    || { echo "$AGENT body is missing the allow-prefix check language required for path-traversal refusal"; return 1; }
  awk '/^---$/{n++; next} n>=2{print}' "$AGENT" \
    | grep -qiE 'refus|skip.*path|path.*escap|reject.*path|path.*reject' \
    || { echo "$AGENT body does not document a refusal or skip outcome for paths failing the allow-prefix check"; return 1; }
}

# ---------------------------------------------------------------------------
# 6. No ## Report Format block (per Slice 2 contract: five-line brief only)
# ---------------------------------------------------------------------------

@test "agent body does not contain a ## Report Format block" {
  awk '/^---$/{n++; next} n>=2{print}' "$AGENT" \
    | grep -qE '^## Report Format' \
    && { echo "$AGENT body contains a '## Report Format' block; it should be absent (five-line brief from reviewer-protocol is the sole return surface)"; return 1; } \
    || true
}

# ---------------------------------------------------------------------------
# 7. skipped.md sentinel schema in using-qrspi/SKILL.md
#    (task spec requires these to be BATS-pinned, not just prose)
# ---------------------------------------------------------------------------

@test "using-qrspi/SKILL.md documents skipped.md as a valid third sentinel form" {
  grep -qE 'skipped\.md' "$USING_QRSPI" \
    || { echo "$USING_QRSPI does not document the '.skipped.md' sentinel form"; return 1; }
}

@test "using-qrspi/SKILL.md documents the skip_reason: frontmatter field" {
  grep -qE 'skip_reason' "$USING_QRSPI" \
    || { echo "$USING_QRSPI does not document the 'skip_reason:' frontmatter schema"; return 1; }
}

@test "using-qrspi/SKILL.md documents the visual_fidelity_required_false skip_reason value" {
  grep -qE 'visual_fidelity_required_false' "$USING_QRSPI" \
    || { echo "$USING_QRSPI does not document skip_reason value 'visual_fidelity_required_false'"; return 1; }
}

@test "using-qrspi/SKILL.md documents the missing_visual_fidelity_check skip_reason value" {
  grep -qE 'missing_visual_fidelity_check' "$USING_QRSPI" \
    || { echo "$USING_QRSPI does not document skip_reason value 'missing_visual_fidelity_check'"; return 1; }
}

@test "using-qrspi/SKILL.md documents the empty_wireframe_paths skip_reason value" {
  grep -qE 'empty_wireframe_paths' "$USING_QRSPI" \
    || { echo "$USING_QRSPI does not document skip_reason value 'empty_wireframe_paths'"; return 1; }
}

@test "using-qrspi/SKILL.md documents the empty_screenshot_paths skip_reason value" {
  grep -qE 'empty_screenshot_paths' "$USING_QRSPI" \
    || { echo "$USING_QRSPI does not document skip_reason value 'empty_screenshot_paths'"; return 1; }
}

# ---------------------------------------------------------------------------
# 8. Apply-fix guard's malformed-sentinel rejection documented in
#    using-qrspi/SKILL.md (the guard treats a skipped.md with missing or
#    unrecognized skip_reason: as absent — the tag-produced-no-output schema
#    violation fires — and logs it as a bypass attempt)
# ---------------------------------------------------------------------------

@test "using-qrspi/SKILL.md documents that a skipped.md with missing or unrecognized skip_reason: is treated as absent" {
  grep -qiE 'missing.*skip_reason|unrecognized.*skip_reason|skip_reason.*missing|skip_reason.*unrecognized' "$USING_QRSPI" \
    || { echo "$USING_QRSPI does not document that a skipped.md with missing/unrecognized skip_reason: is treated as absent"; return 1; }
}

@test "using-qrspi/SKILL.md documents that a malformed skipped.md is logged as a bypass attempt" {
  grep -qiE 'bypass.attempt|bypass attempt' "$USING_QRSPI" \
    || { echo "$USING_QRSPI does not document that a malformed skipped.md is logged as a bypass attempt"; return 1; }
}
