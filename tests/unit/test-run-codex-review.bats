#!/usr/bin/env bats
#
# Tests for scripts/run-codex-review.sh — the single-entrypoint Codex
# reviewer-dispatch wrapper. Uses --dry-run mode so no Codex jobs are
# launched; we assert on the assembled prompt's structure.

setup_file() {
  REPO_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../.." && pwd -P)"
  export REPO_ROOT
  WRAPPER="$REPO_ROOT/scripts/run-codex-review.sh"
  export WRAPPER
}

setup() {
  TMP_DIR="$(mktemp -d)"
  cd "$TMP_DIR"

  # Minimal subject_code, task_def, and plan/goals fixtures.
  mkdir -p src tasks
  echo "export const x = 1;" > src/foo.ts
  echo "Task spec body" > tasks/task-99.md
  echo "Plan body" > plan.md
  echo "Goals body" > goals.md
  echo "Test expectations block" > /tmp/test-exp-fixture.md

  # The wrapper's `--diff-file` is checked for existence (-f) so we provide
  # a real file when the test passes the flag.
  echo "diff body" > "$TMP_DIR/round-1.diff"

  export TMP_DIR
}

teardown() {
  cd /
  rm -rf "$TMP_DIR"
  rm -f /tmp/test-exp-fixture.md
}

# ---------------------------------------------------------------------------
# Required-flag validation
# ---------------------------------------------------------------------------

@test "errors when --agent-file missing" {
  run "$WRAPPER" --reviewer-tag spec-codex --output-dir /tmp/out --round 1 \
    --subject-code "$TMP_DIR/src/foo.ts" --dry-run
  [ "$status" -eq 1 ]
  [[ "$output" =~ "agent-file" ]]
}

@test "errors when --reviewer-tag missing" {
  run "$WRAPPER" --agent-file "$REPO_ROOT/agents/qrspi-spec-reviewer.md" \
    --output-dir /tmp/out --round 1 \
    --subject-code "$TMP_DIR/src/foo.ts" --dry-run
  [ "$status" -eq 1 ]
  [[ "$output" =~ "reviewer-tag" ]]
}

@test "errors when --subject-code missing" {
  run "$WRAPPER" --agent-file "$REPO_ROOT/agents/qrspi-spec-reviewer.md" \
    --reviewer-tag spec-codex --output-dir /tmp/out --round 1 --dry-run
  [ "$status" -eq 1 ]
  [[ "$output" =~ "subject-code" ]]
}

@test "errors clearly when subject-code file does not exist" {
  run "$WRAPPER" --agent-file "$REPO_ROOT/agents/qrspi-spec-reviewer.md" \
    --reviewer-tag spec-codex --output-dir /tmp/out --round 1 \
    --subject-code "$TMP_DIR/nonexistent.ts" --dry-run
  [ "$status" -eq 1 ]
  [[ "$output" =~ "not found" ]]
}

@test "errors on unrecognized flag" {
  run "$WRAPPER" --bogus-flag value --dry-run
  [ "$status" -eq 1 ]
  [[ "$output" =~ "unrecognized" ]]
}

# ---------------------------------------------------------------------------
# Prompt-shape assertions (all use --dry-run)
# ---------------------------------------------------------------------------

@test "dry-run produces prompt with reviewer-protocol body, agent body, override, dispatch params" {
  run "$WRAPPER" \
    --agent-file "$REPO_ROOT/agents/qrspi-spec-reviewer.md" \
    --reviewer-tag spec-codex \
    --output-dir /tmp/out \
    --round 1 \
    --subject-code "$TMP_DIR/src/foo.ts" \
    --task-def "$TMP_DIR/tasks/task-99.md" \
    --dry-run
  [ "$status" -eq 0 ]
  # Reviewer-protocol body landed (frontmatter stripped — distinctive content
  # like `## Finding Schema` or `## Reviewer Dispatch Contract` must appear).
  [[ "$output" =~ "Reviewer Dispatch Contract" ]] || [[ "$output" =~ "Finding Schema" ]]
  # Codex emission override appears (its distinctive `<<<FINDING-BOUNDARY>>>` marker)
  [[ "$output" =~ "FINDING-BOUNDARY" ]]
  # Dispatch parameters block appears
  [[ "$output" =~ "## Dispatch parameters" ]]
  [[ "$output" =~ "subject_code:" ]]
  [[ "$output" =~ "task_definition:" ]]
  [[ "$output" =~ "reviewer_tag: spec-codex" ]]
  [[ "$output" =~ "round: 1" ]]
  [[ "$output" =~ "round_subdir: /tmp/out" ]]
}

@test "untrusted-artifact wrappers are present around subject_code and task_definition" {
  run "$WRAPPER" \
    --agent-file "$REPO_ROOT/agents/qrspi-spec-reviewer.md" \
    --reviewer-tag spec-codex \
    --output-dir /tmp/out \
    --round 1 \
    --subject-code "$TMP_DIR/src/foo.ts" \
    --task-def "$TMP_DIR/tasks/task-99.md" \
    --dry-run
  [ "$status" -eq 0 ]
  # Subject-code wrapper carries the path as id (path is repo-rooted but here
  # we passed an absolute path under TMP_DIR — the script uses the literal
  # value the caller passed for the id).
  [[ "$output" =~ "<<<UNTRUSTED-ARTIFACT-START id=$TMP_DIR/src/foo.ts>>>" ]]
  [[ "$output" =~ "<<<UNTRUSTED-ARTIFACT-END id=$TMP_DIR/src/foo.ts>>>" ]]
  # Task-def wrapper
  [[ "$output" =~ "<<<UNTRUSTED-ARTIFACT-START id=$TMP_DIR/tasks/task-99.md>>>" ]]
  [[ "$output" =~ "<<<UNTRUSTED-ARTIFACT-END id=$TMP_DIR/tasks/task-99.md>>>" ]]
}

@test "task_definition is OMITTED when --task-def not provided (test-step reuse signal)" {
  run "$WRAPPER" \
    --agent-file "$REPO_ROOT/agents/qrspi-spec-reviewer.md" \
    --reviewer-tag spec-codex \
    --output-dir /tmp/out \
    --round 1 \
    --subject-code "$TMP_DIR/src/foo.ts" \
    --companion "companion_plan=$TMP_DIR/plan.md" \
    --companion "companion_goals=$TMP_DIR/goals.md" \
    --dry-run
  [ "$status" -eq 0 ]
  # task_definition: line MUST NOT appear — its absence is load-bearing for
  # test-phase reuse on per-task reviewer agents (see test/SKILL.md §
  # Test-phase reuse contract).
  ! [[ "$output" =~ "task_definition:" ]]
  # But companion_plan and companion_goals MUST appear
  [[ "$output" =~ "companion_plan:" ]]
  [[ "$output" =~ "companion_goals:" ]]
}

@test "diff_file_path is omitted when --diff-file not provided" {
  run "$WRAPPER" \
    --agent-file "$REPO_ROOT/agents/qrspi-spec-reviewer.md" \
    --reviewer-tag spec-codex \
    --output-dir /tmp/out \
    --round 1 \
    --subject-code "$TMP_DIR/src/foo.ts" \
    --task-def "$TMP_DIR/tasks/task-99.md" \
    --dry-run
  [ "$status" -eq 0 ]
  ! [[ "$output" =~ "diff_file_path:" ]]
}

@test "diff_file_path appears verbatim when provided" {
  run "$WRAPPER" \
    --agent-file "$REPO_ROOT/agents/qrspi-spec-reviewer.md" \
    --reviewer-tag spec-codex \
    --output-dir /tmp/out \
    --round 1 \
    --subject-code "$TMP_DIR/src/foo.ts" \
    --task-def "$TMP_DIR/tasks/task-99.md" \
    --diff-file "$TMP_DIR/round-1.diff" \
    --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" =~ "diff_file_path: $TMP_DIR/round-1.diff" ]]
}

@test "scope_hint is OMITTED when --scope-hint flag not present (broaden semantics)" {
  run "$WRAPPER" \
    --agent-file "$REPO_ROOT/agents/qrspi-spec-reviewer.md" \
    --reviewer-tag spec-codex \
    --output-dir /tmp/out \
    --round 1 \
    --subject-code "$TMP_DIR/src/foo.ts" \
    --task-def "$TMP_DIR/tasks/task-99.md" \
    --dry-run
  [ "$status" -eq 0 ]
  # The reviewer-protocol descriptive prose mentions "scope_hint:" so we can't
  # just grep for that. Match the canonical dispatch-parameter form instead.
  ! [[ "$output" =~ "scope_hint: <<<UNTRUSTED-SCOPE-HINT-START" ]]
}

@test "scope_hint with empty value emits wrapped empty block (Codex broaden pattern)" {
  run "$WRAPPER" \
    --agent-file "$REPO_ROOT/agents/qrspi-spec-reviewer.md" \
    --reviewer-tag spec-codex \
    --output-dir /tmp/out \
    --round 1 \
    --subject-code "$TMP_DIR/src/foo.ts" \
    --task-def "$TMP_DIR/tasks/task-99.md" \
    --scope-hint "" \
    --dry-run
  [ "$status" -eq 0 ]
  # Wrapped empty block — reviewers treat as semantically identical to absence
  [[ "$output" =~ "scope_hint: <<<UNTRUSTED-SCOPE-HINT-START id=scope_hint>>><<<UNTRUSTED-SCOPE-HINT-END id=scope_hint>>>" ]]
}

@test "scope_hint with comma-separated value is wrapped" {
  run "$WRAPPER" \
    --agent-file "$REPO_ROOT/agents/qrspi-spec-reviewer.md" \
    --reviewer-tag spec-codex \
    --output-dir /tmp/out \
    --round 1 \
    --subject-code "$TMP_DIR/src/foo.ts" \
    --task-def "$TMP_DIR/tasks/task-99.md" \
    --scope-hint "src/foo.ts, src/bar.ts" \
    --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" =~ "scope_hint: <<<UNTRUSTED-SCOPE-HINT-START id=scope_hint>>>src/foo.ts, src/bar.ts<<<UNTRUSTED-SCOPE-HINT-END id=scope_hint>>>" ]]
}

@test "multiple --subject-code paths concatenate as separate wrapped blocks" {
  echo "export const y = 2;" > "$TMP_DIR/src/bar.ts"
  run "$WRAPPER" \
    --agent-file "$REPO_ROOT/agents/qrspi-spec-reviewer.md" \
    --reviewer-tag spec-codex \
    --output-dir /tmp/out \
    --round 1 \
    --subject-code "$TMP_DIR/src/foo.ts" \
    --subject-code "$TMP_DIR/src/bar.ts" \
    --task-def "$TMP_DIR/tasks/task-99.md" \
    --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" =~ "<<<UNTRUSTED-ARTIFACT-START id=$TMP_DIR/src/foo.ts>>>" ]]
  [[ "$output" =~ "<<<UNTRUSTED-ARTIFACT-START id=$TMP_DIR/src/bar.ts>>>" ]]
  # Both file bodies present
  [[ "$output" =~ "export const x = 1" ]]
  [[ "$output" =~ "export const y = 2" ]]
}

@test "--field NAME=VALUE emits 'NAME: VALUE' as a plain scalar (no wrapping)" {
  run "$WRAPPER" \
    --agent-file "$REPO_ROOT/agents/qrspi-plan-reviewer.md" \
    --reviewer-tag quality-codex \
    --output-dir /tmp/out \
    --round 1 \
    --artifact-body "$TMP_DIR/plan.md" \
    --field route=full \
    --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" =~ "route: full" ]]
  ! [[ "$output" =~ "<<<UNTRUSTED-ARTIFACT-START id=route" ]]
}

@test "errors when --field lacks NAME=VALUE form" {
  run "$WRAPPER" \
    --agent-file "$REPO_ROOT/agents/qrspi-spec-reviewer.md" \
    --reviewer-tag spec-codex \
    --output-dir /tmp/out \
    --round 1 \
    --subject-code "$TMP_DIR/src/foo.ts" \
    --field "no_equals" \
    --dry-run
  [ "$status" -eq 1 ]
  [[ "$output" =~ "NAME=VALUE" ]]
}

@test "primary field uses artifact_body when --artifact-body is passed" {
  run "$WRAPPER" \
    --agent-file "$REPO_ROOT/agents/qrspi-design-reviewer.md" \
    --reviewer-tag quality-codex \
    --output-dir /tmp/out \
    --round 1 \
    --artifact-body "$TMP_DIR/plan.md" \
    --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" =~ "artifact_body:" ]]
  ! [[ "$output" =~ "subject_code:" ]]
  [[ "$output" =~ "<<<UNTRUSTED-ARTIFACT-START id=$TMP_DIR/plan.md>>>" ]]
}

@test "errors when both --subject-code and --artifact-body are passed (mutex)" {
  run "$WRAPPER" \
    --agent-file "$REPO_ROOT/agents/qrspi-spec-reviewer.md" \
    --reviewer-tag spec-codex \
    --output-dir /tmp/out \
    --round 1 \
    --subject-code "$TMP_DIR/src/foo.ts" \
    --artifact-body "$TMP_DIR/plan.md" \
    --dry-run
  [ "$status" -eq 1 ]
  [[ "$output" =~ "mutually exclusive" ]]
}

@test "errors when --companion lacks NAME=PATH form" {
  run "$WRAPPER" \
    --agent-file "$REPO_ROOT/agents/qrspi-spec-reviewer.md" \
    --reviewer-tag spec-codex \
    --output-dir /tmp/out \
    --round 1 \
    --subject-code "$TMP_DIR/src/foo.ts" \
    --companion "no_equals_sign" \
    --dry-run
  [ "$status" -eq 1 ]
  [[ "$output" =~ "NAME=PATH" ]]
}

@test "errors when --companion NAME contains invalid characters" {
  run "$WRAPPER" \
    --agent-file "$REPO_ROOT/agents/qrspi-spec-reviewer.md" \
    --reviewer-tag spec-codex \
    --output-dir /tmp/out \
    --round 1 \
    --subject-code "$TMP_DIR/src/foo.ts" \
    --companion "bad-name=$TMP_DIR/plan.md" \
    --dry-run
  [ "$status" -eq 1 ]
  [[ "$output" =~ "NAME must match" ]]
}

@test "multiple --companion paths under same NAME concatenate as wrapped blocks" {
  echo "Spec body 1" > "$TMP_DIR/spec-1.md"
  echo "Spec body 2" > "$TMP_DIR/spec-2.md"
  run "$WRAPPER" \
    --agent-file "$REPO_ROOT/agents/qrspi-implement-gate-reviewer.md" \
    --reviewer-tag implement-gate-codex \
    --output-dir /tmp/out \
    --round 1 \
    --subject-code "$TMP_DIR/src/foo.ts" \
    --companion "companion_task_specs=$TMP_DIR/spec-1.md" \
    --companion "companion_task_specs=$TMP_DIR/spec-2.md" \
    --dry-run
  [ "$status" -eq 0 ]
  # Field header appears exactly once, both wrapped blocks follow.
  count=$(echo "$output" | grep -c "^companion_task_specs:$")
  [ "$count" -eq 1 ]
  [[ "$output" =~ "<<<UNTRUSTED-ARTIFACT-START id=$TMP_DIR/spec-1.md>>>" ]]
  [[ "$output" =~ "<<<UNTRUSTED-ARTIFACT-START id=$TMP_DIR/spec-2.md>>>" ]]
  [[ "$output" =~ "Spec body 1" ]]
  [[ "$output" =~ "Spec body 2" ]]
}

@test "companion_test_expectations appears as wrapped block under generic --companion flag" {
  run "$WRAPPER" \
    --agent-file "$REPO_ROOT/agents/qrspi-test-coverage-reviewer.md" \
    --reviewer-tag test-coverage-codex \
    --output-dir /tmp/out \
    --round 1 \
    --subject-code "$TMP_DIR/src/foo.ts" \
    --task-def "$TMP_DIR/tasks/task-99.md" \
    --companion "companion_plan=$TMP_DIR/plan.md" \
    --companion "companion_test_expectations=/tmp/test-exp-fixture.md" \
    --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" =~ "companion_test_expectations:" ]]
  # id defaults to the path the caller passed (no special hardcode)
  [[ "$output" =~ "<<<UNTRUSTED-ARTIFACT-START id=/tmp/test-exp-fixture.md>>>" ]]
  [[ "$output" =~ "Test expectations block" ]]
}

# ---------------------------------------------------------------------------
# Frontmatter-stripping assertion: the prompt MUST NOT contain the YAML
# frontmatter from reviewer-protocol/SKILL.md or the agent file.
# ---------------------------------------------------------------------------

@test "agent-file YAML frontmatter is stripped (no 'name:' or 'description:' from frontmatter survives)" {
  run "$WRAPPER" \
    --agent-file "$REPO_ROOT/agents/qrspi-spec-reviewer.md" \
    --reviewer-tag spec-codex \
    --output-dir /tmp/out \
    --round 1 \
    --subject-code "$TMP_DIR/src/foo.ts" \
    --task-def "$TMP_DIR/tasks/task-99.md" \
    --dry-run
  [ "$status" -eq 0 ]
  # Read the agent file's frontmatter; assert its `name:` line does NOT
  # appear in the assembled prompt (the awk should have stripped it).
  agent_name="$(awk 'NR>1 && /^name:/{print; exit}' "$REPO_ROOT/agents/qrspi-spec-reviewer.md" | head -1)"
  if [[ -n "$agent_name" ]]; then
    ! [[ "$output" =~ $agent_name ]]
  fi
}

# ---------------------------------------------------------------------------
# Post-PR-#153 review fixes
# ---------------------------------------------------------------------------

@test "F1: body-level '---' lines after frontmatter are PRESERVED (not eaten as separators)" {
  # Build a fixture agent file with: frontmatter + body containing a
  # markdown horizontal rule (`^---$`) and a fenced YAML mini-frontmatter
  # example (also `^---$`). The fixed strip_frontmatter awk should keep
  # all body-level `---` lines.
  cat > "$TMP_DIR/agent-with-body-rules.md" <<'EOF'
---
name: fixture
description: body-level --- preservation fixture
model: sonnet
tools: Read, Write
---

You are a fixture agent.

## Section A

Some prose.

---

## Section B (separated by horizontal rule above)

```
---
status: draft
---
```

End of body.
EOF
  run "$WRAPPER" \
    --agent-file "$TMP_DIR/agent-with-body-rules.md" \
    --reviewer-tag spec-codex \
    --output-dir /tmp/out \
    --round 1 \
    --subject-code "$TMP_DIR/src/foo.ts" \
    --dry-run
  [ "$status" -eq 0 ]
  # Frontmatter (name: fixture) MUST be stripped
  ! [[ "$output" =~ "name: fixture" ]]
  # Body-level prose MUST be preserved
  [[ "$output" =~ "Section A" ]]
  [[ "$output" =~ "Section B (separated by horizontal rule above)" ]]
  # The body-level `---` (markdown horizontal rule) must survive — count
  # how many `^---$` lines appear in the output (must be ≥1 for body rule
  # plus 2 for the fenced YAML example plus 2 for inter-section wrapper
  # separators). Pre-fix this count would be 0 for body content.
  body_rules=$(printf '%s\n' "$output" | grep -c '^---$' || true)
  [ "$body_rules" -ge 3 ]
}

@test "F2: --agent-file as last arg fails with 'requires a value' (no unbound-variable crash)" {
  # set -u previously made truncated value-flags crash with
  # "unbound variable" before the wrapper's diagnostic could fire.
  run "$WRAPPER" --agent-file
  [ "$status" -eq 1 ]
  [[ "$output" =~ "requires a value" ]]
  ! [[ "$output" =~ "unbound variable" ]]
}

@test "F2: --scope-hint as last arg fails with 'requires a value' (no unbound-variable crash)" {
  run "$WRAPPER" \
    --agent-file "$REPO_ROOT/agents/qrspi-spec-reviewer.md" \
    --reviewer-tag spec-codex \
    --output-dir /tmp/out \
    --round 1 \
    --subject-code "$TMP_DIR/src/foo.ts" \
    --task-def "$TMP_DIR/tasks/task-99.md" \
    --scope-hint
  [ "$status" -eq 1 ]
  [[ "$output" =~ "requires a value" ]]
  ! [[ "$output" =~ "unbound variable" ]]
}

@test "F3: --output-dir rejects relative paths (Bucket-3 #4 fail-loud bypass guard)" {
  # A relative `reviews/test/...` would defeat the agent-side
  # /reviews/test/ substring check; reject at the wrapper.
  run "$WRAPPER" \
    --agent-file "$REPO_ROOT/agents/qrspi-spec-reviewer.md" \
    --reviewer-tag spec-codex \
    --output-dir reviews/test/round-1/ \
    --round 1 \
    --subject-code "$TMP_DIR/src/foo.ts" \
    --dry-run
  [ "$status" -eq 1 ]
  [[ "$output" =~ "must be absolute" ]]
}

@test "F3: --output-dir accepts absolute paths" {
  run "$WRAPPER" \
    --agent-file "$REPO_ROOT/agents/qrspi-spec-reviewer.md" \
    --reviewer-tag spec-codex \
    --output-dir /tmp/abs/reviews/test/round-1/ \
    --round 1 \
    --subject-code "$TMP_DIR/src/foo.ts" \
    --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" =~ "round_subdir: /tmp/abs/reviews/test/round-1/" ]]
}

@test "F6: compose_prompt emits <<<AGENT-BODY-END>>> structural marker before dispatch parameters" {
  # The marker delimits trusted protocol+agent body from orchestrator-
  # supplied dispatch parameters; agent self-reference exception clauses
  # (research-isolation Pre-Flight) reference it for a positional carve-out.
  run "$WRAPPER" \
    --agent-file "$REPO_ROOT/agents/qrspi-spec-reviewer.md" \
    --reviewer-tag spec-codex \
    --output-dir /tmp/out \
    --round 1 \
    --subject-code "$TMP_DIR/src/foo.ts" \
    --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" =~ "<<<AGENT-BODY-END>>>" ]]
  # Marker must appear BEFORE the dispatch parameters block (positional
  # carve-out: text after the marker is orchestrator-supplied).
  marker_line=$(printf '%s\n' "$output" | grep -n '^<<<AGENT-BODY-END>>>$' | head -1 | cut -d: -f1)
  dispatch_line=$(printf '%s\n' "$output" | grep -n '^## Dispatch parameters$' | head -1 | cut -d: -f1)
  [ -n "$marker_line" ]
  [ -n "$dispatch_line" ]
  [ "$marker_line" -lt "$dispatch_line" ]
}
