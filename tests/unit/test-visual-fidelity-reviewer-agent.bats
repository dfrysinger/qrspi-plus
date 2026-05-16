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
    | grep -qE '^[-*][[:space:]]+`round`' \
    || { echo "$AGENT body does not document the 'round' dispatch parameter as a bullet entry"; return 1; }
}

@test "agent body documents reviewer_tag set to visual-fidelity-claude" {
  awk '/^---$/{n++; next} n>=2{print}' "$AGENT" \
    | grep -qE 'reviewer_tag.*visual-fidelity-claude|visual-fidelity-claude.*reviewer_tag' \
    || { echo "$AGENT body does not document 'reviewer_tag' with value 'visual-fidelity-claude' in the same context"; return 1; }
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

@test "using-qrspi/SKILL.md documents skipped.md as a valid third sentinel form in the apply-fix section" {
  # Section-scoped: grep only within the visual-fidelity-claude apply-fix block
  awk '/visual-fidelity-claude.*tag.*third valid sentinel/,/This schema mirrors/' "$USING_QRSPI" \
    | grep -qE 'skipped\.md' \
    || { echo "$USING_QRSPI apply-fix section does not document the '.skipped.md' sentinel form"; return 1; }
}

@test "using-qrspi/SKILL.md documents the skip_reason: frontmatter field in the apply-fix section" {
  # Section-scoped: grep only within the visual-fidelity-claude apply-fix block
  awk '/visual-fidelity-claude.*tag.*third valid sentinel/,/This schema mirrors/' "$USING_QRSPI" \
    | grep -qE 'skip_reason' \
    || { echo "$USING_QRSPI apply-fix section does not document the 'skip_reason:' frontmatter schema"; return 1; }
}

@test "using-qrspi/SKILL.md documents the visual_fidelity_required_false skip_reason value in the apply-fix section" {
  awk '/visual-fidelity-claude.*tag.*third valid sentinel/,/This schema mirrors/' "$USING_QRSPI" \
    | grep -qE 'visual_fidelity_required_false' \
    || { echo "$USING_QRSPI apply-fix section does not document skip_reason value 'visual_fidelity_required_false'"; return 1; }
}

@test "using-qrspi/SKILL.md documents the missing_visual_fidelity_check skip_reason value in the apply-fix section" {
  awk '/visual-fidelity-claude.*tag.*third valid sentinel/,/This schema mirrors/' "$USING_QRSPI" \
    | grep -qE 'missing_visual_fidelity_check' \
    || { echo "$USING_QRSPI apply-fix section does not document skip_reason value 'missing_visual_fidelity_check'"; return 1; }
}

@test "using-qrspi/SKILL.md documents the empty_wireframe_paths skip_reason value in the apply-fix section" {
  awk '/visual-fidelity-claude.*tag.*third valid sentinel/,/This schema mirrors/' "$USING_QRSPI" \
    | grep -qE 'empty_wireframe_paths' \
    || { echo "$USING_QRSPI apply-fix section does not document skip_reason value 'empty_wireframe_paths'"; return 1; }
}

@test "using-qrspi/SKILL.md documents the empty_screenshot_paths skip_reason value in the apply-fix section" {
  awk '/visual-fidelity-claude.*tag.*third valid sentinel/,/This schema mirrors/' "$USING_QRSPI" \
    | grep -qE 'empty_screenshot_paths' \
    || { echo "$USING_QRSPI apply-fix section does not document skip_reason value 'empty_screenshot_paths'"; return 1; }
}

# ---------------------------------------------------------------------------
# 8. Apply-fix guard's malformed-sentinel rejection documented in
#    using-qrspi/SKILL.md (the guard treats a skipped.md with missing or
#    unrecognized skip_reason: as absent — the tag-produced-no-output schema
#    violation fires — and logs it as a bypass attempt)
# ---------------------------------------------------------------------------

@test "using-qrspi/SKILL.md documents that a skipped.md with missing or unrecognized skip_reason: is treated as absent" {
  # Section-scoped: grep only within the visual-fidelity-claude apply-fix block
  awk '/visual-fidelity-claude.*tag.*third valid sentinel/,/This schema mirrors/' "$USING_QRSPI" \
    | grep -qiE 'missing.*skip_reason|unrecognized.*skip_reason|skip_reason.*missing|skip_reason.*unrecognized' \
    || { echo "$USING_QRSPI apply-fix section does not document that a skipped.md with missing/unrecognized skip_reason: is treated as absent"; return 1; }
}

@test "using-qrspi/SKILL.md documents that a malformed skipped.md is logged as a bypass attempt" {
  # Section-scoped: grep only within the visual-fidelity-claude apply-fix block
  awk '/visual-fidelity-claude.*tag.*third valid sentinel/,/This schema mirrors/' "$USING_QRSPI" \
    | grep -qiE 'bypass[- ]attempt|bypass attempt' \
    || { echo "$USING_QRSPI apply-fix section does not document that a malformed skipped.md is logged as a bypass attempt"; return 1; }
}

# ---------------------------------------------------------------------------
# 9. Partial-rejection emits finding with change_type: scope (disposition B)
# ---------------------------------------------------------------------------

@test "agent body documents that partial path rejection emits a finding with change_type scope" {
  awk '/^---$/{n++; next} n>=2{print}' "$AGENT" \
    | grep -qiE 'change_type.*scope|scope.*change_type' \
    || { echo "$AGENT body does not document emitting a change_type: scope finding on partial path rejection"; return 1; }
}

@test "agent body documents that CLEAN sentinel is never emitted when any path was rejected" {
  awk '/^---$/{n++; next} n>=2{print}' "$AGENT" \
    | grep -qiE 'clean.*never|never.*clean|clean.*must not|must not.*clean|CLEAN.*reject|reject.*CLEAN' \
    || { echo "$AGENT body does not document that CLEAN sentinel is never emitted when any path was rejected"; return 1; }
}

# ---------------------------------------------------------------------------
# 10. Every image must load — partial-load requires finding (disposition C)
# ---------------------------------------------------------------------------

@test "agent body documents that EVERY image in both lists must load successfully" {
  awk '/^---$/{n++; next} n>=2{print}' "$AGENT" \
    | grep -qiE 'every.*image|every.*path|every.*wireframe|all.*image.*load|every.*load|each.*load' \
    || { echo "$AGENT body does not document that every image in both lists must load successfully"; return 1; }
}

# ---------------------------------------------------------------------------
# 11. Write-confirmation contract (disposition D)
# ---------------------------------------------------------------------------

@test "agent body documents Write tool success verification before returning brief" {
  awk '/^---$/{n++; next} n>=2{print}' "$AGENT" \
    | grep -qiE 'write.*success|confirm.*write|write.*fail|write.*confirm|verify.*write' \
    || { echo "$AGENT body does not document verifying Write tool success before returning the five-line brief"; return 1; }
}

# ---------------------------------------------------------------------------
# 12. Symlink-traversal refusal with canonicalization (disposition E)
# ---------------------------------------------------------------------------

@test "agent body documents symlink-traversal refusal with canonical path check" {
  awk '/^---$/{n++; next} n>=2{print}' "$AGENT" \
    | grep -qiE 'symlink|canonical|derefer' \
    || { echo "$AGENT body does not document symlink-traversal refusal or canonical path check"; return 1; }
}

# ---------------------------------------------------------------------------
# 13. Image content as untrusted data (disposition F)
# ---------------------------------------------------------------------------

@test "agent body frames image content as untrusted data not instructions" {
  awk '/^---$/{n++; next} n>=2{print}' "$AGENT" \
    | grep -qiE 'image.*content.*untrusted|visual.*content.*data|treat.*image.*data|image.*data.*never.*instruct|embedded.*text.*image' \
    || { echo "$AGENT body does not frame visual/image content as untrusted data distinct from instructions"; return 1; }
}

# ---------------------------------------------------------------------------
# 14. Sentinel exclusive-writer contract (disposition G)
# ---------------------------------------------------------------------------

@test "agent body documents that this agent is exclusive writer of finding and clean sentinel files" {
  awk '/^---$/{n++; next} n>=2{print}' "$AGENT" \
    | grep -qiE 'exclusive.*writer|exclusive writer' \
    || { echo "$AGENT body does not document the exclusive-writer contract for finding and clean sentinel files"; return 1; }
}

# ---------------------------------------------------------------------------
# 15. Honest symlink-trust framing — primary defense is orchestrator (disp A)
# ---------------------------------------------------------------------------

@test "agent body acknowledges orchestrator as primary defense against symlink traversal" {
  awk '/^---$/{n++; next} n>=2{print}' "$AGENT" \
    | grep -qiE 'primary defense|primary.defence' \
    || { echo "$AGENT body does not acknowledge the orchestrator gate as the primary defense against symlink traversal"; return 1; }
}

@test "agent body explicitly states the agent CANNOT detect physical symlinks" {
  awk '/^---$/{n++; next} n>=2{print}' "$AGENT" \
    | grep -qiE 'cannot detect.*symlink|cannot.*canonicali|no.*canonicali.*primitive|does not.*canonicali' \
    || { echo "$AGENT body does not explicitly state the agent cannot detect physical symlinks at the filesystem layer"; return 1; }
}

@test "agent body documents the residual trust boundary for symlinks as an architectural residual" {
  awk '/^---$/{n++; next} n>=2{print}' "$AGENT" \
    | grep -qiE 'residual|architectural.*residual|documented.*residual|residual.*trust' \
    || { echo "$AGENT body does not document the symlink residual trust boundary as an architectural residual"; return 1; }
}

# ---------------------------------------------------------------------------
# 16. EXIF metadata in untrusted-data framing (disp B)
# ---------------------------------------------------------------------------

@test "agent body mentions EXIF in the untrusted-data enumeration" {
  awk '/^---$/{n++; next} n>=2{print}' "$AGENT" \
    | grep -qE 'EXIF' \
    || { echo "$AGENT body does not include the literal token 'EXIF' in the untrusted-data framing"; return 1; }
}

# ---------------------------------------------------------------------------
# 17. round_subdir traversal-marker scan before Write (disp C, reframed)
#
# The dispatch contract does not include an allow_prefix parameter, so the
# agent can only perform a syntactic traversal-marker scan on round_subdir.
# These tests pin the enumerated markers and the architectural-residual
# acknowledgment parallel to the symlink-honest-framing pattern.
# ---------------------------------------------------------------------------

@test "agent body documents round_subdir traversal-marker scan enumerating dot-dot sequences" {
  awk '/^---$/{n++; next} n>=2{print}' "$AGENT" \
    | grep -qiE 'round_subdir.*\.\.|round_subdir.*traversal|traversal.*round_subdir|traversal.*marker.*round_subdir|round_subdir.*traversal.*marker' \
    || { echo "$AGENT body does not document dot-dot traversal-marker scan for round_subdir"; return 1; }
}

@test "agent body documents round_subdir traversal-marker scan covering leading tilde home-directory expansion" {
  awk '/^---$/{n++; next} n>=2{print}' "$AGENT" \
    | grep -qiE 'round_subdir.*tilde|tilde.*round_subdir|leading.*~|~.*home|home.*expand' \
    || { echo "$AGENT body does not document leading-tilde (home-directory expansion) as a round_subdir traversal marker"; return 1; }
}

@test "agent body documents round_subdir traversal-marker scan covering URI scheme prefixes" {
  awk '/^---$/{n++; next} n>=2{print}' "$AGENT" \
    | grep -qiE 'URI.*scheme|file://|scheme.*prefix|http://' \
    || { echo "$AGENT body does not document URI scheme prefixes as round_subdir traversal markers"; return 1; }
}

@test "agent body documents round_subdir architectural residual acknowledging orchestrator as primary defense" {
  awk '/^---$/{n++; next} n>=2{print}' "$AGENT" \
    | grep -qiE 'round_subdir.*primary defense|primary defense.*round_subdir|primary defense.*write|write.*primary defense' \
    || { echo "$AGENT body does not acknowledge the orchestrator as the primary defense for round_subdir path validation"; return 1; }
}

@test "agent body documents that the agent CANNOT verify round_subdir physical containment without canonicalization" {
  awk '/^---$/{n++; next} n>=2{print}' "$AGENT" \
    | grep -qiE 'CANNOT.*contain|cannot.*physical.*contain|cannot.*verify.*round_subdir|physical.*contain.*round_subdir' \
    || { echo "$AGENT body does not state the agent CANNOT detect physical containment for round_subdir without canonicalization"; return 1; }
}

# ---------------------------------------------------------------------------
# 18. Write concrete success criterion (disp D)
# ---------------------------------------------------------------------------

@test "agent body specifies a concrete Write success criterion" {
  awk '/^---$/{n++; next} n>=2{print}' "$AGENT" \
    | grep -qiE 'File created successfully|file created' \
    || { echo "$AGENT body does not specify a concrete Write success criterion (e.g. 'File created successfully')"; return 1; }
}

# ---------------------------------------------------------------------------
# 19. Image-injection finding change_type is correctness not scope (disp F)
# ---------------------------------------------------------------------------

@test "agent body documents image-injection-attempt findings with change_type correctness not scope" {
  awk '/^---$/{n++; next} n>=2{print}' "$AGENT" \
    | grep -qiE 'inject.*change_type.*correctness|change_type.*correctness.*inject|inject.*correctness' \
    || { echo "$AGENT body does not document change_type: correctness for image-injection-attempt findings (not scope)"; return 1; }
}
