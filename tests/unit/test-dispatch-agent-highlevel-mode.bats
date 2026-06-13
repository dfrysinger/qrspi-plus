#!/usr/bin/env bats
# ============================================================================
# Task-04a (CD-2): scripts/dispatch-agent.sh — high-level entry mode.
#
# task_definition path: tasks/task-04a.md (Wave-3, v0.7.3, qrspi/v0.7.3/task-04a).
#
# Test Expectations bullets covered (RED gate — these MUST fail against the
# un-implemented state of dispatch-agent.sh on the task-04a branch):
#
#   B1. Dispatch order: test-writer first, implementer second (RED-verification
#       gate between).
#   B2. High-level `--step --round --artifact-dir` invocation produces a
#       dispatch byte-identical (in prompt content) to the equivalent
#       low-level invocation with pre-computed paths (CD-2 Acceptance #2).
#   B3. High-level mode threads `diff_file_path:` and `absorption_map_path:`
#       (when applicable) into the dispatch prompt; Design fixture asserts
#       both parameters appear, Goals fixture asserts only `diff_file_path:`.
#   B4. review-prep failure causes dispatch-agent to exit non-zero with
#       review-prep's stderr verbatim.
#   B5. The low-level `--diff-file <path>` mode remains functional — its
#       prompt content is byte-stable against the baseline contract.
#   B6. Partial high-level flag combinations (e.g., `--step` without `--round`,
#       or `--step + --round` without `--artifact-dir`) cause visible failure
#       with a named diagnostic identifying the absent flag — never silently
#       falling through to the low-level mode or producing an empty prompt
#       (test-coverage-codex R6-F02).
# ============================================================================

bats_require_minimum_version 1.5.0

setup_file() {
  REPO_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../.." && pwd -P)"
  export REPO_ROOT
  WRAPPER="$REPO_ROOT/scripts/dispatch-agent.sh"
  export WRAPPER
}

setup() {
  # TMP_DIR must live UNDER $REPO_ROOT so dispatch-agent's repo-boundary
  # guard (assert_path_under_repo_root) accepts per-test fixture paths
  # (mirrors the pattern in tests/unit/test-dispatch-agent.bats).
  TMP_DIR="$(mktemp -d "$REPO_ROOT/.bats-tmp.XXXXXX")"
  export TMP_DIR
  cd "$TMP_DIR"

  # Build a small git working tree as the --artifact-dir target. review-prep.sh
  # requires the artifact-dir to be inside a git repo and to have an artifact
  # file (goals.md / design.md / plan.md) with a non-empty diff against the
  # narrowing base.
  ART_DIR="$TMP_DIR/artifact"
  export ART_DIR
  mkdir -p "$ART_DIR"
  git init -q -b main "$ART_DIR"
  (
    cd "$ART_DIR"
    git config user.email "t@example.test"
    git config user.name "Tester"
    printf '# Goals v0\n' > goals.md
    cp "$REPO_ROOT/tests/fixtures/design-absorption-markers/all-four.md" design.md
    git add goals.md design.md
    git commit -q -m "base"
    git checkout -q -b task
    printf '\nNew goals line.\n' >> goals.md
    printf '\n<!-- absorbing-id: T99 -->\n' >> design.md
    git add goals.md design.md
    git commit -q -m "round-1 work"
  )

  # Output dir for dispatch prompts.
  OUT_DIR="$TMP_DIR/out"
  export OUT_DIR
  mkdir -p "$OUT_DIR"

  # Plain artifact body fixture for the single-reviewer (low-level)
  # `--diff-file` regression test.
  echo "Plan body" > "$TMP_DIR/plan.md"
  echo "diff body" > "$TMP_DIR/round-1.diff"
}

teardown() {
  cd /
  rm -rf "$TMP_DIR"
}

# ── Helper: extract the dispatch parameters block from a prompt file ────────
# Returns the slice of the prompt starting at "## Dispatch parameters" so
# byte-equality and substring assertions ignore upstream skill/agent body
# concatenation order (which both modes share verbatim).
_dispatch_params_block() {
  awk '/^## Dispatch parameters/{p=1} p' "$1"
}

# ============================================================================
# B6. Partial high-level flag combinations cause named-diagnostic failure.
# ============================================================================

@test "B6: --step + --artifact-dir without --round exits non-zero with named diagnostic" {
  # Test expectation: partial high-level flag combinations cause visible
  # failure with a named diagnostic identifying which required flag is
  # absent. Here --round is missing.
  run "$WRAPPER" \
    --step design \
    --artifact-dir "$ART_DIR" \
    --output-dir "$OUT_DIR" \
    --agents design-claude=qrspi-design-reviewer
  [ "$status" -ne 0 ]
  # Diagnostic must name the absent flag (round) so the operator can fix it.
  [[ "$output" =~ round ]]
}

@test "B6: --step + --round without --artifact-dir exits non-zero with named diagnostic (no silent low-level fallthrough)" {
  # Test expectation: partial high-level flag combinations never silently
  # fall through to the low-level mode. Today this invocation is accepted
  # by the legacy batched mode; the new contract requires it to FAIL with
  # a named diagnostic citing --artifact-dir as the absent high-level flag.
  run "$WRAPPER" \
    --step design \
    --round 1 \
    --output-dir "$OUT_DIR" \
    --agents design-claude=qrspi-design-reviewer
  [ "$status" -ne 0 ]
  [[ "$output" =~ artifact-dir ]]
}

# ============================================================================
# B3. High-level threads diff_file_path / absorption_map_path into prompt.
# ============================================================================

@test "B3 (design): high-level mode threads BOTH diff_file_path: and absorption_map_path: into the prompt" {
  # Test expectation: a Design-step fixture proves both parameters appear.
  run "$WRAPPER" \
    --step design \
    --round 1 \
    --artifact-dir "$ART_DIR" \
    --output-dir "$OUT_DIR" \
    --agents design-claude=qrspi-design-reviewer
  [ "$status" -eq 0 ]
  PROMPT="$OUT_DIR/.dispatch/design-claude.prompt"
  [ -f "$PROMPT" ]
  params="$(_dispatch_params_block "$PROMPT")"
  [[ "$params" == *"diff_file_path:"* ]]
  [[ "$params" == *"absorption_map_path:"* ]]
  # Threaded values must resolve to the real review-prep outputs under
  # <artifact-dir>/reviews/<step>/round-NN.* (proves the mode actually
  # invoked review-prep first and forwarded its produced paths, not a
  # placeholder string).
  [[ "$params" == *"$ART_DIR/reviews/design/round-01.diff"* ]]
  [[ "$params" == *"$ART_DIR/reviews/design/round-01.absorption-map.tsv"* ]]
}

@test "B3 (goals): high-level mode threads diff_file_path: ONLY (no absorption_map_path:) for steps without an absorption map" {
  # Test expectation: a Goals-step fixture proves only diff_file_path: appears.
  run "$WRAPPER" \
    --step goals \
    --round 1 \
    --artifact-dir "$ART_DIR" \
    --output-dir "$OUT_DIR" \
    --agents goals-claude=qrspi-goals-reviewer
  [ "$status" -eq 0 ]
  PROMPT="$OUT_DIR/.dispatch/goals-claude.prompt"
  [ -f "$PROMPT" ]
  params="$(_dispatch_params_block "$PROMPT")"
  [[ "$params" == *"diff_file_path:"* ]]
  [[ "$params" == *"$ART_DIR/reviews/goals/round-01.diff"* ]]
  # absorption_map_path is design/plan-only; it must NOT appear for goals.
  [[ "$params" != *"absorption_map_path:"* ]]
}

# ============================================================================
# B2. Byte-equality: high-level vs equivalent low-level pre-computed paths.
# ============================================================================

@test "B2: high-level prompt is byte-identical (Dispatch parameters block) to the equivalent low-level invocation with pre-computed paths" {
  # Test expectation: side-by-side bats fixture asserts byte-equality of
  # the resulting prompt (CD-2 Acceptance bullet 2).
  #
  # Strategy: run review-prep.sh out-of-band to materialise the same diff +
  # absorption-map paths the high-level mode would compute, then invoke the
  # low-level dispatch (batched mode with the new pre-computed --diff-file
  # / --absorption-map flags) and compare the produced prompt to the
  # high-level prompt's Dispatch parameters block byte-for-byte.

  # High-level invocation:
  HL_OUT="$TMP_DIR/out-hl"
  mkdir -p "$HL_OUT"
  run "$WRAPPER" \
    --step design \
    --round 1 \
    --artifact-dir "$ART_DIR" \
    --output-dir "$HL_OUT" \
    --agents design-claude=qrspi-design-reviewer
  [ "$status" -eq 0 ]
  HL_PROMPT="$HL_OUT/.dispatch/design-claude.prompt"
  [ -f "$HL_PROMPT" ]

  # Pre-compute the same paths via review-prep.sh, then drive the low-level
  # batched dispatch with explicit pre-computed-path flags.
  bash "$REPO_ROOT/scripts/review-prep.sh" \
    --step design --round 1 --artifact-dir "$ART_DIR" --base-ref main
  [ -f "$ART_DIR/reviews/design/round-01.diff" ]
  [ -f "$ART_DIR/reviews/design/round-01.absorption-map.tsv" ]

  LL_OUT="$TMP_DIR/out-ll"
  mkdir -p "$LL_OUT"
  run "$WRAPPER" \
    --step design \
    --round 1 \
    --output-dir "$LL_OUT" \
    --agents design-claude=qrspi-design-reviewer \
    --diff-file "$ART_DIR/reviews/design/round-01.diff" \
    --absorption-map "$ART_DIR/reviews/design/round-01.absorption-map.tsv"
  [ "$status" -eq 0 ]
  LL_PROMPT="$LL_OUT/.dispatch/design-claude.prompt"
  [ -f "$LL_PROMPT" ]

  # Byte-equality of the Dispatch parameters block (the per-mode threading
  # surface) — the upstream skill/agent body concatenation is identical in
  # both modes since both call the same compose path.
  hl_params="$(_dispatch_params_block "$HL_PROMPT")"
  ll_params="$(_dispatch_params_block "$LL_PROMPT")"
  [ "$hl_params" = "$ll_params" ]
}

# ============================================================================
# B4. review-prep failure propagates verbatim.
# ============================================================================

@test "B4: review-prep failure causes non-zero exit AND its stderr appears verbatim in dispatch-agent stderr" {
  # Test expectation: review-prep failure propagates verbatim — dispatch-agent
  # exits non-zero with review-prep's stderr (CD-2 § Why this approach —
  # single-exit-code shape).
  #
  # Trigger a review-prep failure deterministically: round >= 2 with a
  # missing per-round anchor file produces the named
  # `anchor-file-missing:` diagnostic and a non-zero exit (per
  # tests/unit/test-review-prep.bats bullet 13).
  run "$WRAPPER" \
    --step design \
    --round 2 \
    --artifact-dir "$ART_DIR" \
    --output-dir "$OUT_DIR" \
    --agents design-claude=qrspi-design-reviewer
  [ "$status" -ne 0 ]
  # review-prep's diagnostic must appear verbatim in our combined stderr/out.
  [[ "$output" == *"anchor-file-missing:"* ]]
}

# ============================================================================
# B5. Low-level --diff-file mode regression guard.
# ============================================================================

@test "B5: low-level --diff-file mode still threads diff_file_path: into the single-reviewer prompt (regression)" {
  # Test expectation: the low-level `--diff-file <path>` mode remains
  # functional. A regression-guard fixture invokes dispatch-agent with the
  # explicit --diff-file flag (no --step/--round/--artifact-dir triple),
  # captures the resulting dispatch-prompt content (--dry-run), and asserts
  # the diff_file_path: line is present unchanged.
  #
  # This pins the v0.7.2 single-reviewer prompt-content contract for the
  # --diff-file surface so the high-level mode addition cannot regress it.
  run "$WRAPPER" \
    --agent-file "$REPO_ROOT/agents/qrspi-design-reviewer.md" \
    --reviewer-tag design-claude \
    --output-dir "$TMP_DIR/out-single" \
    --round 1 \
    --artifact-body "$TMP_DIR/plan.md" \
    --diff-file "$TMP_DIR/round-1.diff" \
    --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" == *"diff_file_path: $TMP_DIR/round-1.diff"* ]]
  # The Dispatch parameters block must still be assembled in full.
  [[ "$output" == *"## Dispatch parameters"* ]]
  [[ "$output" == *"reviewer_tag: design-claude"* ]]
  [[ "$output" == *"round: 1"* ]]
}

# ============================================================================
# B1. Dispatch order: test-writer first, implementer second.
# ============================================================================

@test "B1: high-level --step implement emits test-writer spec line BEFORE implementer spec line (RED-verification gate between)" {
  # Test expectation: dispatch order is test-writer first, implementer second,
  # with the RED-verification gate between them. For a per-task implement
  # dispatch the script must emit MODE=first_party spec lines in test-writer-
  # then-implementer order regardless of the order they appear in --agents
  # (the order is contract, not caller-controlled).
  #
  # The implement step's review-prep contract is silent-no-op (per
  # scripts/review-prep.sh `case "$STEP" in implement) exit 0`), so the
  # high-level invocation is valid without per-step diff/map files.
  run "$WRAPPER" \
    --step implement \
    --round 1 \
    --artifact-dir "$ART_DIR" \
    --output-dir "$OUT_DIR" \
    --agents qrspi-implementer-claude=qrspi-implementer,qrspi-test-writer-claude=qrspi-test-writer
  [ "$status" -eq 0 ]
  # Extract the order of MODE=first_party spec lines from stdout. The
  # test-writer tag must appear strictly before the implementer tag.
  tw_line="$(printf '%s\n' "$output" | grep -n '^MODE=first_party.*TAG=qrspi-test-writer-claude' | head -1 | cut -d: -f1)"
  impl_line="$(printf '%s\n' "$output" | grep -n '^MODE=first_party.*TAG=qrspi-implementer-claude' | head -1 | cut -d: -f1)"
  [ -n "$tw_line" ]
  [ -n "$impl_line" ]
  [ "$tw_line" -lt "$impl_line" ]
}
