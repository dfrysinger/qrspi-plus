#!/usr/bin/env bats
bats_require_minimum_version 1.5.0

# Task 23 (pin 1 of 2) — G8, G9, G14: Parallelize owns-defers Slice 4 pin
#
# Asserts skills/parallelize/owns-defers.md contains the Worktree-Aware
# Setup Validation entry in the OWNS section (advisory-only, no auto-patch),
# and that the DEFERS section retains the four Implement-owned categories.
#
# Bash 3.2 portable: no mapfile, no declare -A, no ${var,,}, no coproc,
# no wait -n.

load '../helpers/skill-markdown'

setup_file() {
  require_repo_root
  OWNS_DEFERS="$REPO_ROOT/skills/parallelize/owns-defers.md"
  export OWNS_DEFERS
}

# ---------------------------------------------------------------------------
# OWNS section: Worktree-Aware Setup Validation entry exists
# ---------------------------------------------------------------------------
@test "[T23-owns] OWNS section contains Worktree-Aware Setup Validation entry" {
  extract_and_grep "$OWNS_DEFERS" H3 "Parallelize OWNS" \
    "Worktree-Aware Setup Validation"
}

# ---------------------------------------------------------------------------
# OWNS section: advisory-only scope (no auto-patch)
# ---------------------------------------------------------------------------
@test "[T23-owns] OWNS Worktree-Aware entry names advisory-only scope" {
  extract_and_grep "$OWNS_DEFERS" H3 "Parallelize OWNS" \
    "advisory"
}

@test "[T23-owns] OWNS Worktree-Aware entry explicitly negates auto-patch responsibility" {
  # The entry must contain an explicit negation of auto-patch.
  # Canonical text: "Parallelize does NOT auto-patch ... perform the setup itself"
  extract_and_grep "$OWNS_DEFERS" H3 "Parallelize OWNS" "does NOT auto-patch"
}

# ---------------------------------------------------------------------------
# DEFERS section: worktree creation, branch creation, baseline-test, config edits
# ---------------------------------------------------------------------------
@test "[T23-owns] DEFERS section retains worktree creation as Implement-owned" {
  extract_and_grep "$OWNS_DEFERS" H3 "Parallelize DEFERS" \
    "[Ww]orktree creation"
}

@test "[T23-owns] DEFERS section retains branch creation as Implement-owned" {
  extract_and_grep "$OWNS_DEFERS" H3 "Parallelize DEFERS" \
    "branch creation"
}

@test "[T23-owns] DEFERS section retains baseline-test execution as Implement-owned" {
  extract_and_grep "$OWNS_DEFERS" H3 "Parallelize DEFERS" \
    "baseline.test"
}

@test "[T23-owns] DEFERS section retains config edits as Implement-owned" {
  extract_and_grep "$OWNS_DEFERS" H3 "Parallelize DEFERS" \
    "config"
}

# ---------------------------------------------------------------------------
# Missing-anchor loud-failure: helper emits named diagnostic on bad heading
# ---------------------------------------------------------------------------
@test "[T23-owns] missing-anchor emits skill-markdown loud diagnostic" {
  run extract_and_grep "$OWNS_DEFERS" H3 "Nonexistent Section XXXX" "anything"
  [ "$status" -ne 0 ]
  printf '%s\n' "$output" | grep -q "skill-markdown:"
}

# ---------------------------------------------------------------------------
# Shared helper loads and REPO_ROOT resolves.
# ---------------------------------------------------------------------------
@test "[T23-owns] shared helper loads and require_repo_root resolves REPO_ROOT" {
  require_repo_root
  [ -n "$REPO_ROOT" ]
  [ -d "$REPO_ROOT" ]
}
