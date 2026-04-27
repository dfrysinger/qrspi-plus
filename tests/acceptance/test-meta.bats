#!/usr/bin/env bats
bats_require_minimum_version 1.5.0

# Acceptance tests for Criterion 8.
#
# Criterion 8: "All existing pipeline functionality (Goals through Replan)
#   continues to work after Phase 4 changes — validated by the unit tests
#   passing (baseline confirmed)."
#   → Meta-test: confirm the unit test suite still has exactly 287 @test entries
#     across exactly 12 .bats files.
#
# Phase 4 changes: test-validate.bats deleted (M27), test-artifact-map.bats
# added (U8). File count stays at 12, test count updated to 287.

# ── Helpers ──────────────────────────────────────────────────────────────────

unit_test_dir() {
  echo "$(dirname "$BATS_TEST_DIRNAME")/unit"
}

# ── Criterion 8: Unit test suite baseline ────────────────────────────────────

# AC8 — The unit test directory contains exactly 12 .bats files
@test "[AC8] Unit test suite has exactly 12 .bats files (baseline)" {
  local dir
  dir="$(unit_test_dir)"
  local count
  count=$(find "$dir" -maxdepth 1 -name "*.bats" -type f | wc -l | tr -d ' ')
  [ "$count" -eq 12 ]
}

# AC8 — Unit test count baseline (updated 2026-04-26)
@test "[AC8] Unit test suite has exactly 308 @test definitions (baseline)" {
  # Baseline updated after 2026-04-26 implement-runtime-fix:
  # +test-agent.bats (Task 2), -test-enforcement.bats (Task 11 — dead code).
  # 2026-04-26 (later) — Commit A part 1 added 5 unit tests covering F-1 and
  # F-7 fixes: 2 in test-artifact.bats ([F-7] mid-session current_step),
  # 3 in test-pre-tool-use.bats ([F-1] fail-closed for unresolved artifact,
  # empty {} state, corrupted-state message). Baseline 283 → 288.
  # 2026-04-26 (round-2 review fix) — added 1 in test-pipeline.bats covering
  # F-7 cascade path (current_step recompute after pipeline_cascade_reset).
  # 288 → 289.
  # 2026-04-26 (Commit A part 2) — added 14 unit tests covering F-3, Important
  # #1, and F-19: 5 in test-bash-detect.bats ([F-3] project-internal absolute
  # paths allowed), 4 in test-audit.bats ([Important #1] ambiguous-slug
  # fail-loud + [Important #1+3] integration that diagnostic propagates through
  # audit_log_event), 5 in test-pre-tool-use.bats ([F-19] alpha-suffix worktree
  # IDs). 289 → 303.
  # 2026-04-26 (Codex round-2 catch) — added 5 more covering the cross-file
  # F-19 regex invariant Codex caught: 3 in test-worktree.bats
  # ([F-19] worktree_extract_slug must accept task-07a/07b/12c too) plus 2 in
  # test-audit.bats ([F-19] audit_log_event writes audit.jsonl row for
  # task-07a Edit and task-07b Bash). 303 → 308. Without this fix the
  # asymmetric wall would let alpha-suffix writes through but audit silently
  # drops them — a silent observability hole.
  local dir
  dir="$(unit_test_dir)"
  local count
  count=$(grep -r "^@test" "$dir" --include="*.bats" | wc -l | tr -d ' ')
  [ "$count" -eq 308 ]
}

# AC8 — Every expected unit test file is present by name (updated 2026-04-26)
@test "[AC8] All 12 expected unit test files are present by name" {
  local dir
  dir="$(unit_test_dir)"

  local expected_files=(
    "test-agent.bats"
    "test-artifact-map.bats"
    "test-artifact.bats"
    "test-audit.bats"
    "test-bash-detect.bats"
    "test-frontmatter.bats"
    "test-pipeline.bats"
    "test-pre-tool-use.bats"
    "test-setup-project-hooks.bats"
    "test-state.bats"
    "test-task.bats"
    "test-worktree.bats"
  )

  for f in "${expected_files[@]}"; do
    [ -f "$dir/$f" ]
  done
}

# AC8 — No unit test file is empty (each has at least one @test)
@test "[AC8] No unit test file is empty (all have at least one @test)" {
  local dir
  dir="$(unit_test_dir)"

  while IFS= read -r bats_file; do
    local test_count
    test_count=$(grep -c "^@test" "$bats_file" || true)
    [ "$test_count" -gt 0 ]
  done < <(find "$dir" -maxdepth 1 -name "*.bats" -type f | sort)
}
