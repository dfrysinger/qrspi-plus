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

# -----------------------------------------------------------------------------
# 5. Per-printf and per-bullet scope_hint rigor (B9)
# -----------------------------------------------------------------------------
#
# Mirrors test-diff-file-emission.bats's per-step sweeps for diff_file_path
# (PR-1 invariant). Each sweep covers a different surface to bind the wiring
# to the code, not just to prose.

# The in-scope skill list (excludes test/SKILL.md per spec §2.6 opt-out and
# excludes implementer-protocol/reviewer-protocol/using-qrspi which do not
# emit reviewer dispatches).
SCOPED_SKILLS_LIST=(goals questions research design phasing structure parallelize plan replan integrate implement)

@test "[112-PR2] every in-scope per-step SKILL.md wires scope_hint into Codex printf format strings" {
  # B9: every Codex printf block carrying reviewer_tag MUST also carry
  # scope_hint with the wrapper.
  for skill in goals questions research design phasing structure parallelize plan replan integrate implement; do
    skill_path="$REPO_ROOT/skills/$skill/SKILL.md"
    [ -f "$skill_path" ] || { echo "missing $skill_path"; return 1; }

    # Every printf line that emits a reviewer_tag must also carry scope_hint.
    # Count them and assert equality (per-tag dispatch parity).
    rt_count=$(grep -cE "reviewer_tag: [a-z-]+\\\\n" "$skill_path" || true)
    sh_count=$(grep -cE "scope_hint: <<<UNTRUSTED-SCOPE-HINT-START id=scope_hint>>>%s<<<UNTRUSTED-SCOPE-HINT-END id=scope_hint>>>\\\\n" "$skill_path" || true)
    if [[ "$rt_count" != "$sh_count" ]]; then
      echo "skill $skill: reviewer_tag count ($rt_count) != scope_hint count ($sh_count) in printf format strings"
      return 1
    fi
    if [[ "$sh_count" -lt 1 ]]; then
      echo "skill $skill: zero scope_hint printf format strings (expected at least 1)"
      return 1
    fi
  done
}

@test "[112-PR2] every in-scope per-step SKILL.md wraps scope_hint values in untrusted-data markers (B2)" {
  # The wrapper contract from B2: every scope_hint value MUST be wrapped
  # between <<<UNTRUSTED-SCOPE-HINT-START id=scope_hint>>> and
  # <<<UNTRUSTED-SCOPE-HINT-END id=scope_hint>>>.
  for skill in goals questions research design phasing structure parallelize plan replan integrate implement; do
    skill_path="$REPO_ROOT/skills/$skill/SKILL.md"
    grep -qF '<<<UNTRUSTED-SCOPE-HINT-START id=scope_hint>>>' "$skill_path" \
      || { echo "skill $skill: missing UNTRUSTED-SCOPE-HINT-START marker"; return 1; }
    grep -qF '<<<UNTRUSTED-SCOPE-HINT-END id=scope_hint>>>' "$skill_path" \
      || { echo "skill $skill: missing UNTRUSTED-SCOPE-HINT-END marker"; return 1; }
  done
}

@test "[112-PR2] every in-scope reviewer agent has a ## Scope Hint section (B9)" {
  # Every in-scope reviewer agent MUST have a ## Scope Hint section
  # documenting the absence + empty-value-equivalence semantics.
  agents=(
    qrspi-goals-reviewer qrspi-goals-scope-reviewer
    qrspi-questions-reviewer
    qrspi-research-reviewer
    qrspi-design-reviewer qrspi-design-scope-reviewer
    qrspi-phasing-reviewer qrspi-phasing-scope-reviewer
    qrspi-structure-reviewer qrspi-structure-scope-reviewer
    qrspi-parallelize-reviewer qrspi-parallelize-scope-reviewer
    qrspi-replan-reviewer qrspi-replan-scope-reviewer
    qrspi-plan-reviewer qrspi-plan-scope-reviewer qrspi-plan-spec-reviewer
    qrspi-plan-security-reviewer qrspi-plan-silent-failure-hunter
    qrspi-plan-goal-traceability-reviewer qrspi-plan-test-coverage-reviewer
    qrspi-implement-gate-reviewer
    qrspi-integration-reviewer qrspi-security-integration-reviewer
    qrspi-spec-reviewer qrspi-code-quality-reviewer qrspi-silent-failure-hunter
    qrspi-security-reviewer qrspi-goal-traceability-reviewer
    qrspi-type-design-analyzer qrspi-code-simplifier
  )
  for agent in "${agents[@]}"; do
    agent_path="$REPO_ROOT/agents/$agent.md"
    [ -f "$agent_path" ] || { echo "missing $agent_path"; return 1; }
    grep -qE '^## Scope Hint' "$agent_path" \
      || { echo "agent $agent: missing ## Scope Hint section"; return 1; }
  done
}

@test "[112-PR2] every in-scope reviewer agent documents empty-value equivalence (B7)" {
  agents=(
    qrspi-goals-reviewer qrspi-goals-scope-reviewer
    qrspi-questions-reviewer
    qrspi-research-reviewer
    qrspi-design-reviewer qrspi-design-scope-reviewer
    qrspi-phasing-reviewer qrspi-phasing-scope-reviewer
    qrspi-structure-reviewer qrspi-structure-scope-reviewer
    qrspi-parallelize-reviewer qrspi-parallelize-scope-reviewer
    qrspi-replan-reviewer qrspi-replan-scope-reviewer
    qrspi-plan-reviewer qrspi-plan-scope-reviewer qrspi-plan-spec-reviewer
    qrspi-plan-security-reviewer qrspi-plan-silent-failure-hunter
    qrspi-plan-goal-traceability-reviewer qrspi-plan-test-coverage-reviewer
    qrspi-implement-gate-reviewer
    qrspi-integration-reviewer qrspi-security-integration-reviewer
    qrspi-spec-reviewer qrspi-code-quality-reviewer qrspi-silent-failure-hunter
    qrspi-security-reviewer qrspi-goal-traceability-reviewer
    qrspi-type-design-analyzer qrspi-code-simplifier
  )
  for agent in "${agents[@]}"; do
    agent_path="$REPO_ROOT/agents/$agent.md"
    grep -qiE 'empty value|empty-value|empty.*value|empty.*scope_hint|scope_hint.*empty' "$agent_path" \
      || { echo "agent $agent: missing empty-value-equivalence prose"; return 1; }
  done
}

@test "[112-PR2] test step opts out: skills/test/SKILL.md has no scope_hint printf (B9)" {
  test_skill="$REPO_ROOT/skills/test/SKILL.md"
  [ -f "$test_skill" ]
  grep -qE 'scope_hint: %s' "$test_skill" \
    && { echo "skills/test/SKILL.md should NOT carry scope_hint printf (test-step opt-out)"; return 1; } \
    || true
  grep -qF 'scope_hint: <<<UNTRUSTED-SCOPE-HINT-START id=scope_hint>>>' "$test_skill" \
    && { echo "skills/test/SKILL.md should NOT carry the wrapped scope_hint printf"; return 1; } \
    || true
  return 0
}

@test "[112-PR2] qrspi-test-coverage-reviewer has NO ## Scope Hint section (test-step opt-out)" {
  agent_path="$REPO_ROOT/agents/qrspi-test-coverage-reviewer.md"
  [ -f "$agent_path" ]
  grep -qE '^## Scope Hint' "$agent_path" \
    && { echo "qrspi-test-coverage-reviewer should NOT have ## Scope Hint section"; return 1; } \
    || true
  return 0
}

# -----------------------------------------------------------------------------
# 6. Tagger normalization invariants (I1, I2, I8)
# -----------------------------------------------------------------------------

@test "[112-PR2] tagger documents trailing-whitespace strip (I2)" {
  body=$(awk '/^---$/{n++; next} n>=2{print}' "$AGENT")
  echo "$body" | grep -qiE 'trailing whitespace|strip.*whitespace' \
    || { echo "tagger missing trailing-whitespace-strip rule"; return 1; }
}

@test "[112-PR2] tagger forbids comma in H2 heading tags (I1)" {
  body=$(awk '/^---$/{n++; next} n>=2{print}' "$AGENT")
  echo "$body" | grep -qiE 'comma|contains comma' \
    || { echo "tagger missing comma-handling rule for H2 headings"; return 1; }
  # Must also describe the conservative-broaden fallback.
  echo "$body" | grep -qiE 'tagged as full-artifact|tag with <full>|<full>' \
    || { echo "tagger missing comma -> <full> fallback"; return 1; }
}

@test "[112-PR2] tagger documents <full> as reserved literal token (I8)" {
  body=$(awk '/^---$/{n++; next} n>=2{print}' "$AGENT")
  echo "$body" | grep -qiE 'reserved.*token|literal token' \
    || { echo "tagger missing <full> reserved-literal-token invariant"; return 1; }
  # Must explain why H2 headings cannot collide.
  echo "$body" | grep -qiE 'always carry the .## . prefix|H2.*prefix|## .*prefix' \
    || { echo "tagger missing 'H2 always carries ## prefix -> no collision' rationale"; return 1; }
}

@test "[112-PR2] tagger documents path-traversal / malformed-citation guard (I9)" {
  body=$(awk '/^---$/{n++; next} n>=2{print}' "$AGENT")
  echo "$body" | grep -qiE 'path.traversal|\\.\\.|charset|range form' \
    || { echo "tagger missing citation-schema guard (path traversal / charset / range form)"; return 1; }
}

# -----------------------------------------------------------------------------
# 7. #140 — per-task Implement and Integrate convergence narrowing
# -----------------------------------------------------------------------------
#
# #140 lifts the DEFERRED status from per-task Implement and Integrate, wiring
# scope-tagger dispatch + convergence narrowing for both surfaces. These
# assertions ground on the per-flow scope-set output paths, the absence of the
# DEFERRED token, the per-round commit anchor file paths, and the implement-
# gate opt-out decision.

@test "[140] skills/implement/SKILL.md per-task review section drops the DEFERRED framing" {
  # The line-383 paragraph MUST no longer claim the per-task narrowing is
  # DEFERRED. Scope is the per-task review section only — match against the
  # phrase "per-task narrowing DEFERRED" (the original DEFERRED label) plus
  # any "DEFERRED to a follow-up" hedge.
  local impl="$REPO_ROOT/skills/implement/SKILL.md"
  [ -f "$impl" ]
  if grep -qE 'per-task narrowing DEFERRED|narrowing.*DEFERRED|DEFERRED to a follow-up' "$impl"; then
    echo "implement/SKILL.md still carries DEFERRED framing for per-task narrowing"
    return 1
  fi
}

@test "[140] skills/integrate/SKILL.md drops the DEFERRED framing" {
  local intg="$REPO_ROOT/skills/integrate/SKILL.md"
  [ -f "$intg" ]
  if grep -qE 'Integrate-side narrowing DEFERRED|narrowing.*DEFERRED|DEFERRED to a follow-up' "$intg"; then
    echo "integrate/SKILL.md still carries DEFERRED framing for Integrate narrowing"
    return 1
  fi
}

@test "[140] per-task Implement scope-set emission path is reviews/tasks/task-NN/round-NN-scope-set.txt" {
  local impl="$REPO_ROOT/skills/implement/SKILL.md"
  grep -qF 'reviews/tasks/task-NN/round-NN-scope-set.txt' "$impl" \
    || { echo "implement/SKILL.md missing per-task scope-set emission path"; return 1; }
}

@test "[140] per-task Implement dispatches qrspi-scope-tagger" {
  local impl="$REPO_ROOT/skills/implement/SKILL.md"
  # Either an explicit qrspi-scope-tagger reference in the per-task convergence
  # subsection, OR a reference to using-qrspi step 5.5 (which does the dispatch).
  grep -qE 'qrspi-scope-tagger' "$impl" \
    || { echo "implement/SKILL.md missing qrspi-scope-tagger reference"; return 1; }
  # Must also reference using-qrspi step 5.5 as the canonical contract.
  grep -qE 'step.*5\.5|5\.5.*step' "$impl" \
    || { echo "implement/SKILL.md does not reference using-qrspi step 5.5"; return 1; }
}

@test "[140] per-task Implement carries kept_findings parameter for tagger dispatch" {
  local impl="$REPO_ROOT/skills/implement/SKILL.md"
  grep -qE 'kept_findings' "$impl" \
    || { echo "implement/SKILL.md missing kept_findings parameter"; return 1; }
}

@test "[140] per-task Implement carries multi-file tagger branch (artifact_path: null)" {
  local impl="$REPO_ROOT/skills/implement/SKILL.md"
  # Per-task is multi-file by construction — both artifact_path and artifact_body
  # pass the literal `null` so the tagger fires its multi-file branch. Pin to
  # the artifact_path null token (the load-bearing dispatch parameter).
  grep -qE 'artifact_path.*null' "$impl" \
    || { echo "implement/SKILL.md missing per-task artifact_path: null tagger branch"; return 1; }
}

@test "[140] Integrate scope-set emission path is reviews/integration/round-NN-scope-set.txt" {
  local intg="$REPO_ROOT/skills/integrate/SKILL.md"
  grep -qF 'reviews/integration/round-NN-scope-set.txt' "$intg" \
    || { echo "integrate/SKILL.md missing scope-set emission path"; return 1; }
}

@test "[140] Integrate dispatches qrspi-scope-tagger" {
  local intg="$REPO_ROOT/skills/integrate/SKILL.md"
  grep -qE 'qrspi-scope-tagger' "$intg" \
    || { echo "integrate/SKILL.md missing qrspi-scope-tagger reference"; return 1; }
  # Must also reference using-qrspi step 5.5 as the canonical contract.
  grep -qE 'step.*5\.5|5\.5.*step' "$intg" \
    || { echo "integrate/SKILL.md does not reference using-qrspi step 5.5"; return 1; }
}

@test "[140] Integrate tagger dispatch is multi-file (artifact_path: null)" {
  local intg="$REPO_ROOT/skills/integrate/SKILL.md"
  grep -qE 'artifact_path.*null' "$intg" \
    || { echo "integrate/SKILL.md missing artifact_path: null tagger branch"; return 1; }
}

@test "[140] implement-gate reviewer is documented as opt-out (single-shot, no narrowing)" {
  local impl="$REPO_ROOT/skills/implement/SKILL.md"
  # The opt-out must mention either implement-gate-reviewer with opt-out semantics,
  # OR implement-gate-scope-set explicitly absent. The current decision is opt-out.
  grep -qiE 'implement.gate.*opt.out|implement.gate.*single.shot|single.shot.*implement.gate|implement-gate.*not.*multi.round' "$impl" \
    || { echo "implement/SKILL.md missing implement-gate opt-out documentation"; return 1; }
  # Negative regression: there should be NO scope-set emission path under
  # reviews/integration/round-NN-implement-gate-scope-set.txt
  if grep -qF 'round-NN-implement-gate-scope-set.txt' "$impl"; then
    echo "implement/SKILL.md should NOT emit a scope-set for implement-gate (opt-out)"
    return 1
  fi
}

@test "[140] per-task Implement structural-validation guard is referenced (B4)" {
  local impl="$REPO_ROOT/skills/implement/SKILL.md"
  # B4 fail-loud guard: malformed scope-set routes through verifier-round failure menu.
  grep -qiE 'structural validation|structurally valid|malformed scope-set|fail.loud' "$impl" \
    || { echo "implement/SKILL.md missing per-task B4 structural-validation reference"; return 1; }
}

@test "[140] Integrate structural-validation guard is referenced (B4)" {
  local intg="$REPO_ROOT/skills/integrate/SKILL.md"
  grep -qiE 'structural validation|structurally valid|malformed scope-set|fail.loud' "$intg" \
    || { echo "integrate/SKILL.md missing B4 structural-validation reference"; return 1; }
}

@test "[140] per-task Implement full-artifact-fallback diagnostic is referenced (B8)" {
  local impl="$REPO_ROOT/skills/implement/SKILL.md"
  grep -qiE 'full-artifact|<full>.*fall.*back|fell back to <full>|full-artifact-fallback' "$impl" \
    || { echo "implement/SKILL.md missing per-task B8 full-artifact-fallback diagnostic"; return 1; }
}

@test "[140] Integrate full-artifact-fallback diagnostic is referenced (B8)" {
  local intg="$REPO_ROOT/skills/integrate/SKILL.md"
  grep -qiE 'full-artifact|<full>.*fall.*back|fell back to <full>|full-artifact-fallback' "$intg" \
    || { echo "integrate/SKILL.md missing B8 full-artifact-fallback diagnostic"; return 1; }
}
