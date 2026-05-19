#!/usr/bin/env bats
bats_require_minimum_version 1.5.0

# T30 (pin 4 of 5) — G11 + G14: Slice 5 quick-tier-wording contract pin.
#
# Asserts T29's reviewer-protocol edit in skills/reviewer-protocol/SKILL.md:
#   - § Quick-Tier Finding Disposition codifies inline-patch for high
#     severity and correctness-medium findings.
#   - Acceptance carve-out for low-severity findings (no inline patch).
#   - Blanket quick-tier merge is prohibited — surfaced via a named
#     diagnostic.
#   - The section is reachable via the standard section-anchor convention
#     so the shared markdown helper can extract it.
#
# Uses skill-markdown.bash per task spec (helper-load is load-bearing).
#
# Bash 3.2 portable.

load '../helpers/skill-markdown'

setup_file() {
  require_repo_root
  REVIEWER_PROTOCOL="$REPO_ROOT/skills/reviewer-protocol/SKILL.md"
  export REVIEWER_PROTOCOL
}

# =============================================================================
# High-severity inline-patch requirement
# =============================================================================

@test "[T30-qt-wording] High-severity findings require inline patch in quick tier" {
  extract_and_grep "$REVIEWER_PROTOCOL" H2 "Quick-Tier Finding Disposition" \
    "[Hh]igh-severity.*inline-patch"
}

@test "[T30-qt-wording] Unpatched high finding triggers named quick-tier-close diagnostic" {
  extract_and_grep "$REVIEWER_PROTOCOL" H2 "Quick-Tier Finding Disposition" \
    "quick-tier close blocked"
}

# =============================================================================
# Correctness-medium inline-patch requirement
# =============================================================================

@test "[T30-qt-wording] Correctness-medium findings require inline patch in quick tier" {
  extract_and_grep "$REVIEWER_PROTOCOL" H2 "Quick-Tier Finding Disposition" \
    "[Cc]orrectness-medium.*inline-patch"
}

@test "[T30-qt-wording] Correctness-medium rule names change_type: correctness" {
  extract_and_grep "$REVIEWER_PROTOCOL" H2 "Quick-Tier Finding Disposition" \
    "change_type: correctness"
}

# =============================================================================
# Low-severity acceptance carve-out
# =============================================================================

@test "[T30-qt-wording] Low-severity findings may be accepted without inline patch" {
  extract_and_grep "$REVIEWER_PROTOCOL" H2 "Quick-Tier Finding Disposition" \
    "[Ll]ow-severity.*acceptance"
}

@test "[T30-qt-wording] Accepted-without-patch dispositions logged in round dispositions" {
  extract_and_grep "$REVIEWER_PROTOCOL" H2 "Quick-Tier Finding Disposition" \
    "accepted-without-patch"
}

# =============================================================================
# Blanket-merge prohibition
# =============================================================================

@test "[T30-qt-wording] Blanket quick-tier merge is prohibited (process violation)" {
  extract_and_grep "$REVIEWER_PROTOCOL" H2 "Quick-Tier Finding Disposition" \
    "[Bb]lanket.*prohibition"
}

@test "[T30-qt-wording] Blanket-merge prohibition names process violation" {
  extract_and_grep "$REVIEWER_PROTOCOL" H2 "Quick-Tier Finding Disposition" \
    "process violation"
}

# =============================================================================
# Section-anchor reachability (shared markdown helper convention)
# =============================================================================

@test "[T30-qt-wording] Section anchor reachable via standard section-anchor convention" {
  # The section body explicitly documents the anchor convention so shared
  # markdown helpers (T13's skill-markdown.bash) can extract it. This pin
  # also implicitly verifies extract_section finds the section by H2 anchor —
  # if it did not, the prior tests would have failed first.
  extract_and_grep "$REVIEWER_PROTOCOL" H2 "Quick-Tier Finding Disposition" \
    "section-anchor convention"
}
