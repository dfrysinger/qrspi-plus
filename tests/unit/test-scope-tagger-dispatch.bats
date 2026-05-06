#!/usr/bin/env bats
#
# #112 PR-2 Mechanism B regression: qrspi-scope-tagger agent file + tagger
# dispatch wiring + scope-set output schema.
#
# Test scope (per PR-2 spec test plan):
#   1. agents/qrspi-scope-tagger.md exists with the right frontmatter
#      (Haiku, [Read, Write] tools).
#   2. The agent body documents the multi-file vs single-file tag derivation
#      branches, the line-range-missing warning behavior, the deduplication
#      requirement, and the write-only output discipline.
#   3. using-qrspi/SKILL.md step 5.5 is present, dispatches the tagger,
#      and references the scope-set output file.
#   4. The scope_tagger_enabled gate + backfill is documented (mirrors
#      verifier_enabled exactly).
#   5. Scope-set output schema is specified verbatim in the agent body.
#
# Anti-vacuous-pass discipline:
#   - Each assertion grounds on a load-bearing surface (the literal output
#     filename, the gate field name, the backfill command line, etc.).
#   - Every assertion produces a clear diagnostic on failure.

setup() {
  REPO_ROOT="$BATS_TEST_DIRNAME/../.."
  export REPO_ROOT
  export AGENT="$REPO_ROOT/agents/qrspi-scope-tagger.md"
  export USING_QRSPI="$REPO_ROOT/skills/using-qrspi/SKILL.md"
}

# -----------------------------------------------------------------------------
# 1. Agent file exists + frontmatter contract
# -----------------------------------------------------------------------------

@test "[112-PR2] qrspi-scope-tagger agent file exists" {
  [ -f "$AGENT" ]
}

@test "[112-PR2] qrspi-scope-tagger frontmatter declares model: haiku" {
  awk '/^---$/{n++; next} n==1{print}' "$AGENT" \
    | grep -qE '^model:\s*haiku' \
    || { echo "qrspi-scope-tagger frontmatter missing 'model: haiku'"; return 1; }
}

@test "[112-PR2] qrspi-scope-tagger frontmatter declares tools: [Read, Write]" {
  awk '/^---$/{n++; next} n==1{print}' "$AGENT" \
    | grep -qE '^tools:\s*\[\s*Read\s*,\s*Write\s*\]' \
    || { echo "qrspi-scope-tagger frontmatter missing 'tools: [Read, Write]'"; return 1; }
}

@test "[112-PR2] qrspi-scope-tagger has a description in frontmatter" {
  awk '/^---$/{n++; next} n==1{print}' "$AGENT" \
    | grep -qE '^description:\s*' \
    || { echo "qrspi-scope-tagger frontmatter missing 'description:'"; return 1; }
}

# -----------------------------------------------------------------------------
# 2. Body covers both branches + write-only contract
# -----------------------------------------------------------------------------

@test "[112-PR2] body documents multi-file tag derivation branch (file path from referenced_files)" {
  local body
  body=$(awk '/^---$/{n++; next} n>=2{print}' "$AGENT")
  echo "$body" | grep -qiE 'multi-file' \
    || { echo "missing multi-file branch documentation"; return 1; }
  echo "$body" | grep -qE 'referenced_files' \
    || { echo "missing referenced_files reference"; return 1; }
}

@test "[112-PR2] body documents single-file tag derivation branch (H2 heading from artifact body)" {
  local body
  body=$(awk '/^---$/{n++; next} n>=2{print}' "$AGENT")
  echo "$body" | grep -qiE 'single-file' \
    || { echo "missing single-file branch documentation"; return 1; }
  # Must mention H2 explicitly.
  echo "$body" | grep -qE 'H2|^## |enclosing.*heading' \
    || { echo "missing H2 heading derivation"; return 1; }
}

@test "[112-PR2] body documents whole-file fallback warning when line-range is missing" {
  local body
  body=$(awk '/^---$/{n++; next} n>=2{print}' "$AGENT")
  # Must describe both the warning emission and the <full> tag fallback.
  echo "$body" | grep -qE '<full>' \
    || { echo "missing <full> whole-artifact tag"; return 1; }
  echo "$body" | grep -qiE 'warning.*line.range|line.range.*warning|no line-range' \
    || { echo "missing line-range-missing warning behavior"; return 1; }
}

@test "[112-PR2] body documents deduplication (each unique tag emitted once)" {
  local body
  body=$(awk '/^---$/{n++; next} n>=2{print}' "$AGENT")
  echo "$body" | grep -qiE 'dedup|deduplicat|each unique|emit each unique' \
    || { echo "missing deduplication requirement"; return 1; }
}

@test "[112-PR2] body documents write-only output discipline (no mutation of finding files)" {
  local body
  body=$(awk '/^---$/{n++; next} n>=2{print}' "$AGENT")
  # Must mention the tagger NEVER mutates findings/sidecars.
  echo "$body" | grep -qiE 'NEVER mutates|never mutates|write[-]only|no mutation|does NOT mutate' \
    || { echo "missing write-only discipline"; return 1; }
}

@test "[112-PR2] body documents the scope-set output schema (round-NN-scope-set.txt)" {
  local body
  body=$(awk '/^---$/{n++; next} n>=2{print}' "$AGENT")
  # Output filename + comment header + tag line shape (## ... or file path).
  echo "$body" | grep -qF 'round-NN-scope-set.txt' \
    || { echo "missing round-NN-scope-set.txt filename"; return 1; }
  # generated_by comment marker + total_findings_kept comment marker.
  echo "$body" | grep -qE 'generated_by:[[:space:]]*qrspi-scope-tagger' \
    || { echo "missing generated_by comment"; return 1; }
  echo "$body" | grep -qE 'total_findings_kept' \
    || { echo "missing total_findings_kept comment"; return 1; }
}

# -----------------------------------------------------------------------------
# 3. using-qrspi step 5.5 wires the dispatch
# -----------------------------------------------------------------------------

@test "[112-PR2] using-qrspi/SKILL.md has step 5.5 (scope-tagger dispatch)" {
  [ -f "$USING_QRSPI" ]
  # Must have a numbered step 5.5 in the Apply-fix protocol body.
  grep -qE '^5\.5\.' "$USING_QRSPI" \
    || { echo "missing step 5.5 in using-qrspi/SKILL.md"; return 1; }
}

@test "[112-PR2] step 5.5 dispatches qrspi-scope-tagger as a subagent" {
  local protocol
  protocol=$(awk '
    /\*\*Apply-fix protocol\.\*\*/ { in_block=1 }
    in_block && /\*\*Verifier-round failure menu/ { exit }
    in_block { print }
  ' "$USING_QRSPI")
  echo "$protocol" | grep -qF 'subagent_type: qrspi-scope-tagger' \
    || { echo "step 5.5 does not dispatch qrspi-scope-tagger"; return 1; }
}

@test "[112-PR2] step 5.5 documents the kept_findings parameter (post-verifier filter)" {
  local protocol
  protocol=$(awk '
    /\*\*Apply-fix protocol\.\*\*/ { in_block=1 }
    in_block && /\*\*Verifier-round failure menu/ { exit }
    in_block { print }
  ' "$USING_QRSPI")
  echo "$protocol" | grep -qE 'kept_findings' \
    || { echo "step 5.5 missing kept_findings parameter"; return 1; }
}

@test "[112-PR2] step 5.5 references the round-NN-scope-set.txt output" {
  grep -qF 'round-NN-scope-set.txt' "$USING_QRSPI" \
    || { echo "using-qrspi/SKILL.md missing round-NN-scope-set.txt reference"; return 1; }
}

# -----------------------------------------------------------------------------
# 4. scope_tagger_enabled gate + backfill (mirrors verifier_enabled)
# -----------------------------------------------------------------------------

@test "[112-PR2] scope_tagger_enabled is documented under 'Fields that affect pipeline behavior'" {
  awk '
    /^### Fields that affect pipeline behavior/ { in_section=1; next }
    /^### / { in_section=0 }
    in_section { print }
  ' "$USING_QRSPI" \
    | grep -qE '^\s*-\s+\*\*`scope_tagger_enabled`\*\*' \
    || { echo "scope_tagger_enabled not documented under Fields that affect pipeline behavior"; return 1; }
}

@test "[112-PR2] scope_tagger_enabled default is true" {
  # Either inline 'default `true`' near the field, or 'scope_tagger_enabled: true'
  # in the run-init template fence.
  awk '/scope_tagger_enabled/{print; getline; print; getline; print}' "$USING_QRSPI" \
    | grep -qE 'default\s*`true`|scope_tagger_enabled:\s*true' \
    || { echo "scope_tagger_enabled default true not documented"; return 1; }
}

@test "[112-PR2] runtime-backfill carve-out for scope_tagger_enabled is in ### Exceptions section" {
  awk '
    /^### Exceptions/ { in_section=1; next }
    /^### / && in_section { in_section=0 }
    in_section { print }
  ' "$USING_QRSPI" \
    | grep -qE 'scope_tagger_enabled.*runtime backfill|runtime backfill.*scope_tagger_enabled' \
    || { echo "scope_tagger_enabled runtime-backfill carve-out not in ### Exceptions section"; return 1; }
}

@test "[112-PR2] step 5.5 reads scope_tagger_enabled and applies the verifier-style backfill" {
  local protocol
  protocol=$(awk '
    /\*\*Apply-fix protocol\.\*\*/ { in_block=1 }
    in_block && /\*\*Verifier-round failure menu/ { exit }
    in_block { print }
  ' "$USING_QRSPI")
  echo "$protocol" | grep -qF 'scope_tagger_enabled' \
    || { echo "step 5.5 does not read scope_tagger_enabled"; return 1; }
  echo "$protocol" | grep -qE 'scope_tagger_enabled missing from config\.md|backfilling default' \
    || { echo "step 5.5 missing backfill diagnostic"; return 1; }
}

@test "[112-PR2] fresh-run config init includes scope_tagger_enabled: true alongside verifier_enabled and route" {
  # The run-init template fence must contain all three: route, verifier_enabled,
  # AND scope_tagger_enabled. Same shape-test as test-config-verifier-enabled-field.bats
  # uses for verifier_enabled.
  awk '
    /^```/ { in_fence = !in_fence; if (!in_fence) {
      if (has_route && has_ve && has_st) { print "TEMPLATE_FENCE_OK"; exit };
      has_route=0; has_ve=0; has_st=0
    } }
    in_fence && /^[[:space:]]*route:/ { has_route=1 }
    in_fence && /^[[:space:]]*verifier_enabled:[[:space:]]*true/ { has_ve=1 }
    in_fence && /^[[:space:]]*scope_tagger_enabled:[[:space:]]*true/ { has_st=1 }
  ' "$USING_QRSPI" | grep -q '^TEMPLATE_FENCE_OK$' \
    || { echo "no fenced code block has 'route:' + 'verifier_enabled: true' + 'scope_tagger_enabled: true' together (run-init template fence missing)"; return 1; }
}

@test "[112-PR2] disabled-mode fall-through is documented (skip step 5.5, no narrowing)" {
  # When scope_tagger_enabled=false: step 5.5 skipped, step 7.5 no-op,
  # reviewers fall through to PR-1's full-base-diff behavior.
  grep -qE 'skipped.*tagger|skip[a-z ]*step 5\.5|tagger dispatch is skipped' "$USING_QRSPI" \
    || { echo "disabled-mode fall-through not documented"; return 1; }
}
