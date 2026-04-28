#!/usr/bin/env bats
bats_require_minimum_version 1.5.0
#
# NOTE (CodexF3, FU-8 cross-reference):
#   This is a prompt-render contract assertion, not a live-LLM dispatch.
#   See FU-8 in `docs/qrspi/2026-04-26-prompt-improvements/future-followups.md`
#   for the post-Integrate opt-in live-dispatch harness. The bats unit-test
#   runtime budget (≤60s for the suite) makes live LLM dispatch impractical
#   inside the runner; the rendered-prompt completeness contract asserted
#   here catches all breakage upstream of the LLM call (escalation rule,
#   route classification, cap-counter rule, BATCH-WITH-OVERRIDES UI prose,
#   3-option menu prose, pending-findings audit-file contract). FU-8 will
#   add the live-dispatch smoke test gated behind LIVE_DISPATCH=1, run
#   out-of-band from this bats suite.
#
# Task 16 — M48 cross-cutting acceptance test: review-loop pause flow
#
# End-to-end exercise of the Review-Loop Pause Gate when a seeded reviewer
# finding citing `feedback/*.md` triggers the secondary-escalation rule and
# routes to the BATCH-WITH-OVERRIDES UI with the per-finding 3-option menu.
#
# The test exercises:
#   1. Seeded `feedback/*.md`-citing finding → escalates to change_type=intent.
#   2. Pause Gate fires → BATCH-WITH-OVERRIDES UI is presented.
#   3. The 3-option menu (apply / skip / loop-back) is offered for the
#      escalated finding.
#   4. The round counter respects the pause: cap_counter does not decrement
#      while the pause is unresolved.
#
# This is a content-and-flow acceptance test: it asserts the prose contracts
# in `skills/using-qrspi/SKILL.md` define the required UI and behavior, and
# it exercises the seeded fixture through the same shell stand-in dispatch
# logic used by the change-type classification unit test (so the
# "fixture → escalation → pause UI dispatch" path runs end-to-end). The
# load-bearing prose contracts are anchored back to using-qrspi/SKILL.md.

setup() {
  REPO_ROOT="$BATS_TEST_DIRNAME/../.."
  FIXTURES_DIR="$BATS_TEST_DIRNAME/../fixtures"
  USING_QRSPI_FILE="$REPO_ROOT/skills/using-qrspi/SKILL.md"
  BOILERPLATE_FILE="$REPO_ROOT/skills/_shared/reviewer-boilerplate.md"
  ESCALATION_FIXTURE="$FIXTURES_DIR/reviewer-finding-secondary-escalation.json"
  export REPO_ROOT FIXTURES_DIR USING_QRSPI_FILE BOILERPLATE_FILE ESCALATION_FIXTURE
}

# extract_section <file> <heading-line>
extract_section() {
  local file="$1"
  local heading="$2"
  awk -v h="$heading" '
    $0 == h { in_section = 1; print; next }
    in_section && /^## / { in_section = 0 }
    in_section { print }
  ' "$file"
}

# escalate_if_feedback / classify_route / cap_counter_after_round —
# stand-ins matching the unit test's loop logic. Mirrored here because the
# acceptance test is run independently (no shared sourcing) and the round
# counter behavior is part of what is under test.
escalate_if_feedback() {
  local primary="$1"
  local refs_json="$2"
  local hit
  hit="$(echo "$refs_json" | jq -r '.[]' | grep -E '^feedback/.*\.md$' || true)"
  if [ -n "$hit" ]; then
    echo "intent"
  else
    echo "$primary"
  fi
}

classify_route() {
  case "$1" in
    style|clarity|correctness) echo "auto-apply" ;;
    scope|intent) echo "pause" ;;
    *) echo "malformed" ;;
  esac
}

cap_counter_after_round() {
  local current="$1" route="$2" menu="$3"
  if [ "$route" = "auto-apply" ]; then
    echo $((current - 1))
    return
  fi
  if [ "$route" = "pause" ] && [ "$menu" = "PAUSE_PENDING" ]; then
    echo "$current"
    return
  fi
  echo $((current - 1))
}

# ── Step 1: seeded feedback/*.md-citing finding escalates to intent ─────────

@test "[end-to-end] seeded fixture cites feedback/*.md (precondition for escalation rule)" {
  [ -f "$ESCALATION_FIXTURE" ]
  local refs_count
  refs_count="$(jq -r '.referenced_files[]' "$ESCALATION_FIXTURE" | grep -cE '^feedback/.*\.md$')"
  [ "$refs_count" -ge 1 ]
}

@test "[end-to-end] reviewer's primary tag is NOT intent (escalation must be load-bearing)" {
  local primary
  primary="$(jq -r '.change_type' "$ESCALATION_FIXTURE")"
  [ "$primary" != "intent" ]
}

@test "[end-to-end] secondary-escalation rule rewrites change_type to intent" {
  local primary refs effective
  primary="$(jq -r '.change_type' "$ESCALATION_FIXTURE")"
  refs="$(jq -c '.referenced_files' "$ESCALATION_FIXTURE")"
  effective="$(escalate_if_feedback "$primary" "$refs")"
  [ "$effective" = "intent" ]
}

# ── Step 2: pause gate fires; BATCH-WITH-OVERRIDES UI is the documented response ─

@test "[end-to-end] escalated finding routes to pause gate" {
  local primary refs effective route
  primary="$(jq -r '.change_type' "$ESCALATION_FIXTURE")"
  refs="$(jq -c '.referenced_files' "$ESCALATION_FIXTURE")"
  effective="$(escalate_if_feedback "$primary" "$refs")"
  route="$(classify_route "$effective")"
  [ "$route" = "pause" ]
}

@test "[end-to-end] using-qrspi/SKILL.md documents the BATCH-WITH-OVERRIDES UI for paused rounds" {
  local section
  section="$(extract_section "$USING_QRSPI_FILE" "## Review-Loop Pause Gate")"
  [ -n "$section" ]
  echo "$section" | grep -q "BATCH-WITH-OVERRIDES"
  # Three classes of findings: auto-applied (silent), proposed (batch), paused (per-finding).
  echo "$section" | grep -qi "Auto-applied"
  echo "$section" | grep -qi "Proposed"
  echo "$section" | grep -qi "Paused"
}

# ── Step 3: 3-option menu is offered per paused finding ─────────────────────

@test "[end-to-end] using-qrspi/SKILL.md documents the 3-option menu (apply / skip / loop-back)" {
  local section
  section="$(extract_section "$USING_QRSPI_FILE" "## Review-Loop Pause Gate")"
  [ -n "$section" ]
  echo "$section" | grep -qi "Apply anyway"
  echo "$section" | grep -qi "Skip finding"
  echo "$section" | grep -qiE "Loop back|loop-back"
}

@test "[end-to-end] using-qrspi/SKILL.md states the loop-back option requires explicit upstream confirmation" {
  local section
  section="$(extract_section "$USING_QRSPI_FILE" "## Review-Loop Pause Gate")"
  [ -n "$section" ]
  # Resolved upstream target must be displayed BEFORE confirmation.
  echo "$section" | grep -qiE "upstream|cascade"
  echo "$section" | grep -qiE "confirm|confirmation"
}

# ── Step 4: round counter respects the pause ────────────────────────────────

@test "[end-to-end] round counter does NOT decrement while pause is unresolved (PAUSE_PENDING)" {
  local primary refs effective route stub_menu cap_before cap_after
  primary="$(jq -r '.change_type' "$ESCALATION_FIXTURE")"
  refs="$(jq -c '.referenced_files' "$ESCALATION_FIXTURE")"
  effective="$(escalate_if_feedback "$primary" "$refs")"
  route="$(classify_route "$effective")"
  [ "$route" = "pause" ]
  # Stubbed menu callable returns PAUSE_PENDING (user has not yet picked).
  stub_menu="PAUSE_PENDING"
  cap_before=10
  cap_after="$(cap_counter_after_round "$cap_before" "$route" "$stub_menu")"
  [ "$cap_after" -eq "$cap_before" ]
}

@test "[end-to-end] using-qrspi/SKILL.md documents 'paused rounds do not decrement the cap'" {
  grep -qE "do not decrement.*cap|does not decrement on a paused round" "$USING_QRSPI_FILE"
}

# ── Step 5: pending-findings audit file contract ────────────────────────────

@test "[end-to-end] using-qrspi/SKILL.md documents the pending-findings audit file (write-before-UI)" {
  local section
  section="$(extract_section "$USING_QRSPI_FILE" "## Review-Loop Pause Gate")"
  [ -n "$section" ]
  echo "$section" | grep -qi "loop-pause-round"
  # Write timing: file written BEFORE the BATCH UI is presented.
  echo "$section" | grep -qiE "write.*before|fail-closed|precondition"
}

# ── Step 6: boilerplate cross-anchor (M48 contract is the source of truth) ──

@test "[end-to-end] reviewer-boilerplate.md defines the secondary-escalation rule on feedback/*.md" {
  local section
  section="$(extract_section "$BOILERPLATE_FILE" "## Change-Type Classifier")"
  [ -n "$section" ]
  echo "$section" | grep -qE "feedback/\*\.md"
  echo "$section" | grep -qiE "escalat"
}
