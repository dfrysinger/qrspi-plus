#!/usr/bin/env bats
# Tests for Task 25 round-02 review findings (fix pass).
# Findings addressed:
#   code-quality: internal IDs in test-file comments re-introduced during R1 fix
#   silent-failure (assembly guard): no assembly-layer guard in wrapper SKILL.md files
#   silent-failure (ambiguous stop): ambiguous "stop" in per-file loop in reviewer-addition

setup_file() {
  REPO_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../.." && pwd -P)"
  export REPO_ROOT
  R1_TEST="$REPO_ROOT/tests/unit/test-task-25-round01-fixes.bats"
  REVIEWER_SKILL="$REPO_ROOT/skills/prompt-prose-reviewer/SKILL.md"
  WRITER_SKILL="$REPO_ROOT/skills/prompt-prose-writer/SKILL.md"
  REVIEWER_ADD="$REPO_ROOT/skills/_shared/prompt-prose-reviewer-addition.md"
  export R1_TEST REVIEWER_SKILL WRITER_SKILL REVIEWER_ADD
}

# ── code-quality round-02 — no internal IDs in R1-fix test comments ──────────

@test "R1-fix test file comment has no parenthetical internal-ID list on finding-description line" {
  # The finding-description comment line must not enumerate internal IDs like
  # the parenthetical that was re-introduced in the R1 fix pass.
  run grep -E 'goal IDs \(' "$R1_TEST"
  [ "$status" -ne 0 ]
}

@test "R1-fix test file body comment has no bare internal goal-ID token" {
  # The inline comment in the Last-applied test must use a generic description,
  # not a bare internal goal-ID reference.
  run grep -E '# The Last applied:.*\bG[0-9]+\b' "$R1_TEST"
  [ "$status" -ne 0 ]
}

# ── silent-failure round-02: assembly guard — both SKILL.md files ────────────

@test "prompt-prose-reviewer SKILL.md has load guard for partial-include failure" {
  # After the !cat chain, the SKILL must instruct the agent not to apply the
  # skill if any include is unavailable — partial context is worse than none.
  run grep -iE 'if.*(include|cat|unavailable|fails)' "$REVIEWER_SKILL"
  [ "$status" -eq 0 ]
}

@test "prompt-prose-writer SKILL.md has load guard for partial-include failure" {
  run grep -iE 'if.*(include|cat|unavailable|fails)' "$WRITER_SKILL"
  [ "$status" -eq 0 ]
}

@test "prompt-prose-reviewer SKILL.md guard says do NOT apply skill on partial load" {
  # Must explicitly prohibit applying the skill when includes are missing.
  run grep -iE '(do not|do NOT|NOT).*(apply|proceed|use)' "$REVIEWER_SKILL"
  [ "$status" -eq 0 ]
}

@test "prompt-prose-writer SKILL.md guard says do NOT apply skill on partial load" {
  run grep -iE '(do not|do NOT|NOT).*(apply|proceed|use)' "$WRITER_SKILL"
  [ "$status" -eq 0 ]
}

# ── silent-failure round-02: ambiguous stop — reviewer-addition ───────────────

@test "prompt-prose-reviewer-addition.md stop-guard says stop the review entirely" {
  # Ambiguous per-iteration "stop" must be clarified to entire-review stop so
  # a transient Read failure on one file cannot produce silent partial enforcement.
  run grep -iE 'stop the review entirely|do not proceed with any further files' "$REVIEWER_ADD"
  [ "$status" -eq 0 ]
}
