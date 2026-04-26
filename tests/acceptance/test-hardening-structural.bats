#!/usr/bin/env bats
bats_require_minimum_version 1.5.0

# Acceptance tests for Phase 4 Hardening — Structural improvement goals.
#
# Covers:
#   U4  — Frontmatter parser consolidation: single frontmatter_get function;
#          no fixed line-depth scan; no other frontmatter parsers in hooks/lib/
#   U8  — Artifact-step mapping consolidation: single lookup in artifact-map.sh;
#          no duplicated mapping arrays in state.sh, artifact.sh, pipeline.sh,
#          or pre-tool-use
#   U11 — Rename protected_is_blocked → is_protected_path: zero references to
#          old name anywhere in hooks/
#   M23 — State bootstrap: state_init function exists in state.sh; using-qrspi
#          SKILL.md references state initialization at pipeline entry

setup() {
  export WORK_DIR
  WORK_DIR=$(mktemp -d)
  export ARTIFACT_DIR="$WORK_DIR/artifacts"
  mkdir -p "$ARTIFACT_DIR/tasks"
  mkdir -p "$WORK_DIR/.qrspi"
  cd "$WORK_DIR"

  export HOOKS_DIR
  HOOKS_DIR="$(dirname "$BATS_TEST_FILENAME")/../../hooks"
  export SKILLS_DIR
  SKILLS_DIR="$(dirname "$BATS_TEST_FILENAME")/../../skills"
}

teardown() {
  rm -rf "$WORK_DIR"
}

# ── U4: Frontmatter parser consolidation ─────────────────────────────────────
# Criterion: A single frontmatter_get function exists that accepts a file path
# and optionally a field name. No fixed line-depth scan. No other frontmatter
# parsers in hooks/lib/.

# U4 — frontmatter_get function exists and accepts file path argument
@test "[U4] frontmatter_get function exists in frontmatter.sh" {
  # AC: single consolidated frontmatter parser function must exist
  local fm_lib="$HOOKS_DIR/lib/frontmatter.sh"
  [ -f "$fm_lib" ]
  grep -q "^frontmatter_get()" "$fm_lib"
}

# U4 — frontmatter_get accepts optional field_name argument (not fixed field extraction)
@test "[U4] frontmatter_get accepts optional field_name and returns full JSON without it" {
  # AC: the function signature accepts [field_name] — when omitted, returns JSON object
  local fm_lib="$HOOKS_DIR/lib/frontmatter.sh"

  # Without field_name: returns full JSON object
  local test_file="$WORK_DIR/test-artifact.md"
  printf -- '---\nstatus: approved\nphase: 2\n---\n\n# Content\n' > "$test_file"

  run bash -c "source '$fm_lib'; frontmatter_get '$test_file'"
  [ "$status" -eq 0 ]
  # Must be a JSON object
  echo "$output" | jq . > /dev/null
  [ "$(echo "$output" | jq -r '.status')" = "approved" ]
  [ "$(echo "$output" | jq -r '.phase')" = "2" ]
}

# U4 — frontmatter_get with field_name returns only that field
@test "[U4] frontmatter_get with field_name returns only that field's value" {
  # AC: when field_name is provided, returns only the named field (not full JSON)
  local fm_lib="$HOOKS_DIR/lib/frontmatter.sh"

  local test_file="$WORK_DIR/test-artifact.md"
  printf -- '---\nstatus: approved\nphase: 3\n---\n\n# Content\n' > "$test_file"

  run bash -c "source '$fm_lib'; frontmatter_get '$test_file' 'status'"
  [ "$status" -eq 0 ]
  [ "$output" = "approved" ]
}

# U4 — No alternative frontmatter parsers exist in hooks/lib/
@test "[U4] No fixed line-depth frontmatter parsers exist in hooks/lib/ (no alternatives to frontmatter_get)" {
  # AC: all frontmatter reads route through frontmatter_get; no ad-hoc parsers remain.
  # Verify no hooks/lib/ file (other than frontmatter.sh) defines its own frontmatter
  # extraction via head/sed/awk line-depth scans.
  #
  # Pattern: head -N | grep "^status:" (fixed line depth) should not appear
  run grep -r "head -[0-9]\+.*grep.*status" "$HOOKS_DIR/lib/"
  [ "$status" -ne 0 ]
}

# U4 — No sed-based frontmatter extractors in hooks/lib/ (no "sed -n '2p'" style)
@test "[U4] No sed line-number frontmatter extraction patterns in hooks/lib/" {
  # AC: fixed line-number sed patterns would indicate a non-consolidated parser
  run grep -r "sed -n '[0-9]\+p'" "$HOOKS_DIR/lib/"
  [ "$status" -ne 0 ]
}

# U4 — frontmatter.sh is sourced transitively in pre-tool-use (not reimplemented)
@test "[U4] pre-tool-use does not contain inline frontmatter parsing logic" {
  # AC: pre-tool-use should not re-implement frontmatter parsing; it routes through
  # the consolidated library. Check that pre-tool-use doesn't have its own
  # "grep status:" or "head -N | grep" patterns.
  local pre_hook="$HOOKS_DIR/pre-tool-use"
  run grep "head -[0-9]\+.*grep.*status\|grep.*^status:" "$pre_hook"
  [ "$status" -ne 0 ]
}

# ── U8: Artifact-step mapping consolidation ───────────────────────────────────
# Criterion: Single lookup table/function in artifact-map.sh. No duplicated
# mapping arrays outside that single source.

# U8 — artifact-map.sh exists with canonical mapping function
@test "[U8] artifact-map.sh exists with artifact_map_get function" {
  # AC: single source of truth for step→file and file→step mappings
  local amap_lib="$HOOKS_DIR/lib/artifact-map.sh"
  [ -f "$amap_lib" ]
  grep -q "^artifact_map_get()" "$amap_lib"
}

# U8 — artifact_map_get covers all 6 pipeline steps
@test "[U8] artifact_map_get returns correct path for each of the 6 pipeline steps" {
  # AC: all pipeline steps must be in the single lookup
  local amap_lib="$HOOKS_DIR/lib/artifact-map.sh"

  run bash -c "source '$amap_lib'; artifact_map_get goals"
  [ "$output" = "goals.md" ]

  run bash -c "source '$amap_lib'; artifact_map_get questions"
  [ "$output" = "questions.md" ]

  run bash -c "source '$amap_lib'; artifact_map_get research"
  [ "$output" = "research/summary.md" ]

  run bash -c "source '$amap_lib'; artifact_map_get design"
  [ "$output" = "design.md" ]

  run bash -c "source '$amap_lib'; artifact_map_get structure"
  [ "$output" = "structure.md" ]

  run bash -c "source '$amap_lib'; artifact_map_get plan"
  [ "$output" = "plan.md" ]
}

# U8 — artifact_map_get_step provides reverse lookup
@test "[U8] artifact_map_get_step reverse-maps filenames to pipeline step names" {
  # AC: reverse lookup must exist in the single canonical source
  local amap_lib="$HOOKS_DIR/lib/artifact-map.sh"

  run bash -c "source '$amap_lib'; artifact_map_get_step 'goals.md'"
  [ "$output" = "goals" ]

  run bash -c "source '$amap_lib'; artifact_map_get_step 'research/summary.md'"
  [ "$output" = "research" ]

  run bash -c "source '$amap_lib'; artifact_map_get_step '/abs/path/design.md'"
  [ "$output" = "design" ]
}

# U8 — No hardcoded artifact mappings in state.sh
@test "[U8] state.sh contains no hardcoded step→file mappings (uses artifact-map.sh)" {
  # AC: state.sh must not duplicate the mapping; it sources artifact-map.sh instead
  local state_lib="$HOOKS_DIR/lib/state.sh"

  # Verify state.sh sources artifact-map.sh
  grep -q "artifact-map.sh" "$state_lib"

  # Verify state.sh does NOT contain hardcoded filename assignments for pipeline steps
  # (e.g., goals_file="goals.md" or research_file="research/summary.md")
  run grep 'goals_file\s*=\s*"goals\.md"\|research_file\s*=\s*"research/summary\.md"\|design_file\s*=\s*"design\.md"' "$state_lib"
  [ "$status" -ne 0 ]
}

# U8 — pre-tool-use uses artifact_map_get_step for reverse lookup (no hardcoded map)
@test "[U8] pre-tool-use uses artifact_map_get_step for step detection (no inline mapping)" {
  # AC: pre-tool-use must call artifact_map_get_step, not maintain its own case statement
  # for mapping filenames to steps
  local pre_hook="$HOOKS_DIR/pre-tool-use"

  # Must call artifact_map_get_step
  grep -q "artifact_map_get_step" "$pre_hook"
}

# U8 — No duplicated step→file arrays in pipeline.sh
@test "[U8] pipeline.sh contains no hardcoded PIPELINE_ARTIFACTS arrays (uses artifact-map.sh)" {
  # AC: pipeline.sh may use artifact_map_get but must not redefine the mapping inline
  local pipeline_lib="$HOOKS_DIR/lib/pipeline.sh"

  # Should not have its own hardcoded array of pipeline step → file mappings
  run grep 'goals\.md.*questions\.md.*research.*summary\.md' "$pipeline_lib"
  [ "$status" -ne 0 ]
}

# ── U11: Rename protected_is_blocked → is_protected_path ─────────────────────
# Criterion: Zero references to old function name anywhere in hooks/.

# U11 — Old function name protected_is_blocked has zero references in hooks/
@test "[U11] Zero references to old name 'protected_is_blocked' in hooks/ directory" {
  # AC: renaming is complete; no residual uses of the old name
  run grep -r "protected_is_blocked" "$HOOKS_DIR/"
  [ "$status" -ne 0 ]
}

# U11 — New function name is_protected_path is defined in protected.sh
@test "[U11] New function name 'is_protected_path' is defined in protected.sh" {
  # AC: the rename has landed — function must exist under new name
  local protected_lib="$HOOKS_DIR/lib/protected.sh"
  [ -f "$protected_lib" ]
  grep -q "^is_protected_path()" "$protected_lib"
}

# U11 — pre-tool-use enforces .qrspi/ artifact-dir protection (post 2026-04-26 rewrite)
@test "[U11] pre-tool-use enforces artifact-dir .qrspi/ protection" {
  # AC: pre-tool-use must protect <artifact_dir>/.qrspi/ paths from any writer.
  # Post 2026-04-26 implement-runtime-fix the protection is inline in the hook
  # binary (anchored regex on docs/qrspi/*/.qrspi/), not a protected.sh call.
  local pre_hook="$HOOKS_DIR/pre-tool-use"
  grep -q "check_artifact_qrspi_protection\|docs/qrspi/.*\.qrspi" "$pre_hook"
}

# U11 — protected.sh does not define protected_is_blocked (old name removed)
@test "[U11] protected.sh does not define the old function name protected_is_blocked" {
  # AC: old function definition is removed, not just renamed at call sites
  local protected_lib="$HOOKS_DIR/lib/protected.sh"
  run grep "^protected_is_blocked()" "$protected_lib"
  [ "$status" -ne 0 ]
}

# ── M23: State bootstrap ──────────────────────────────────────────────────────
# Criterion: state.sh has state_init function; using-qrspi SKILL.md references
# state initialization at pipeline entry.

# M23 — state.sh contains state_init_or_reconcile function
@test "[M23] state.sh has state_init_or_reconcile function for pipeline bootstrap" {
  # AC: state bootstrap function must exist in state.sh
  local state_lib="$HOOKS_DIR/lib/state.sh"
  grep -q "^state_init_or_reconcile()" "$state_lib"
}

# M23 — using-qrspi SKILL.md references state initialization at pipeline entry
@test "[M23] using-qrspi SKILL.md references state_init_or_reconcile for pipeline entry" {
  # AC: the skill prompt instructs the agent to call state initialization;
  # this prevents stale or missing state from causing pipeline failures
  local skill_file="$SKILLS_DIR/using-qrspi/SKILL.md"
  [ -f "$skill_file" ]
  grep -q "state_init_or_reconcile" "$skill_file"
}

# M23 — goals SKILL.md also references state bootstrap (first skill to need it)
@test "[M23] goals SKILL.md references state_init_or_reconcile for state bootstrap" {
  # AC: the Goals skill (first in pipeline) is responsible for bootstrapping state;
  # the SKILL.md must instruct this
  local skill_file="$SKILLS_DIR/goals/SKILL.md"
  [ -f "$skill_file" ]
  grep -q "state_init_or_reconcile\|state bootstrap\|State bootstrap" "$skill_file"
}

# M23 — state_init_or_reconcile correctly initializes state from scratch
@test "[M23] state_init_or_reconcile creates valid state.json from artifact directory" {
  # AC: function works end-to-end for the bootstrap use case.
  # Post-F-1: state.json now lands at <artifact_dir>/.qrspi/state.json (per spec),
  # not at the caller's PWD/.qrspi/.
  local state_lib="$HOOKS_DIR/lib/state.sh"
  local artifact_dir="$WORK_DIR/new-artifacts"
  mkdir -p "$artifact_dir"
  printf -- '---\nstatus: approved\n---\n# Goals\n' > "$artifact_dir/goals.md"

  run bash -c "cd '$WORK_DIR'; source '$state_lib'; state_init_or_reconcile '$artifact_dir'"
  [ "$status" -eq 0 ]
  [ -f "$artifact_dir/.qrspi/state.json" ]
  # Must be valid JSON with required fields
  jq . "$artifact_dir/.qrspi/state.json" > /dev/null
  [ "$(jq -r '.version' "$artifact_dir/.qrspi/state.json")" = "1" ]
  [ "$(jq -r '.artifacts.goals' "$artifact_dir/.qrspi/state.json")" = "approved" ]
}
