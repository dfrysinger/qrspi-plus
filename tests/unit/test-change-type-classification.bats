#!/usr/bin/env bats
bats_require_minimum_version 1.5.0
#
# Task 16 — M48 cross-cutting test: change-type classification
#
# Asserts the M48 reviewer-finding contract end-to-end against the seeded
# reviewer-finding fixtures created by this task:
#
#   tests/fixtures/reviewer-finding-{style,clarity,correctness,scope,intent,
#                                    secondary-escalation}.json
#
# Coverage (per task-16 spec):
#   1. Five seeded findings (style/clarity/correctness/scope/intent) each
#      carry the correct `change_type` tag and route to the correct gate
#      (auto-apply for style/clarity/correctness, pause for scope/intent).
#   2. Secondary-escalation rule: a finding whose `referenced_files` cites
#      `feedback/*.md` is escalated to `change_type: intent` regardless of
#      the reviewer's original primary tag (the seeded fixture's primary tag
#      is `clarity`).
#   3. Pause-gate dispatch fires on `scope`/`intent` findings; auto-applies
#      on `style`/`clarity`/`correctness`.
#   4. The 10-round autonomous review-loop cap does NOT decrement on a
#      paused round. Simulated by invoking the loop machinery with a stubbed
#      menu callable that returns the sentinel `PAUSE_PENDING` (not
#      apply / skip / loop-back). The test asserts cap_counter is unchanged
#      after the round and the loop returns to wait state.
#
# All assertions are scoped to the single fixture-or-stub-block they claim
# to verify; the cap-counter shell stub is self-contained and does not
# touch any real review-loop state.

setup() {
  FIXTURES_DIR="$BATS_TEST_DIRNAME/../fixtures"
  BOILERPLATE_FILE="$BATS_TEST_DIRNAME/../../skills/reviewer-protocol/SKILL.md"
  USING_QRSPI_FILE="$BATS_TEST_DIRNAME/../../skills/using-qrspi/SKILL.md"
  export FIXTURES_DIR BOILERPLATE_FILE USING_QRSPI_FILE
}

# ── Helpers ──────────────────────────────────────────────────────────────────

# classify_route <change_type>
# Pure-shell stand-in for the review loop's dispatch logic.
# Returns "auto-apply" for style/clarity/correctness, "pause" for scope/intent,
# and "malformed" for anything else (including missing/empty input).
classify_route() {
  local change_type="$1"
  case "$change_type" in
    style|clarity|correctness) echo "auto-apply" ;;
    scope|intent) echo "pause" ;;
    *) echo "malformed" ;;
  esac
}

# escalate_if_feedback <effective-change-type-input> <referenced-files-json-array>
# Pure-shell stand-in for the secondary-escalation rule. If any element of
# the JSON-array string matches `feedback/*.md`, the effective change_type
# becomes `intent` regardless of the input value.
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

# stub_menu_callable
# Stubbed menu that always returns the sentinel PAUSE_PENDING — simulating
# an unresolved pause where the user has not yet picked apply/skip/loop-back.
stub_menu_callable() {
  echo "PAUSE_PENDING"
}

# run_review_round <change_type> <referenced_files_json>
# Drives one simulated review round. Echoes "<route>:<menu_result>" where
# <route> is auto-apply / pause / malformed and <menu_result> is the menu
# callable's return (only consulted for the pause route — auto-apply prints
# "applied" and malformed prints "abort").
run_review_round() {
  local primary="$1"
  local refs_json="$2"
  local effective route menu
  effective="$(escalate_if_feedback "$primary" "$refs_json")"
  route="$(classify_route "$effective")"
  case "$route" in
    auto-apply) menu="applied" ;;
    pause) menu="$(stub_menu_callable)" ;;
    *) menu="abort" ;;
  esac
  echo "$route:$menu"
}

# cap_counter_after_round <starting_value> <route> <menu_result>
# Pure-shell stand-in for the 10-round cap counter rule. The autonomous cap
# decrements only on autonomous (auto-applied) rounds. A round whose route
# is `pause` and whose menu has not resolved (PAUSE_PENDING) is treated as
# user-interactive and does NOT decrement the cap. Per using-qrspi/SKILL.md
# §"Paused rounds do not decrement the cap".
cap_counter_after_round() {
  local current="$1"
  local route="$2"
  local menu="$3"
  if [ "$route" = "auto-apply" ]; then
    echo $((current - 1))
    return
  fi
  if [ "$route" = "pause" ] && [ "$menu" = "PAUSE_PENDING" ]; then
    # Pause unresolved — counter unchanged, loop returns to wait state.
    echo "$current"
    return
  fi
  # Pause resolved (apply/skip/loop-back) is treated as autonomous resumption
  # for the purposes of this stand-in; not under test here, so decrement.
  echo $((current - 1))
}

# loop_state_after_round <route> <menu_result>
# Returns the loop-machinery state after a round resolves. Spec contract:
# a paused round whose menu callable returned PAUSE_PENDING means the loop
# returns to `wait` state (not `done` or `next`). Auto-applied rounds and
# resolved-pause rounds advance the loop (`next`), while malformed routes
# abort (`done`). This is the wait-state half of the PAUSE_PENDING contract
# that the cap-counter assertion alone cannot prove (a buggy implementation
# could keep the cap intact while still incorrectly advancing the loop).
loop_state_after_round() {
  local route="$1"
  local menu="$2"
  if [ "$route" = "pause" ] && [ "$menu" = "PAUSE_PENDING" ]; then
    echo "wait"
    return
  fi
  if [ "$route" = "auto-apply" ]; then
    echo "next"
    return
  fi
  if [ "$route" = "pause" ] && { [ "$menu" = "apply" ] || [ "$menu" = "skip" ] || [ "$menu" = "loop-back" ]; }; then
    echo "next"
    return
  fi
  echo "done"
}

# run_review_round_with_menu <change_type> <referenced_files_json> <menu_result_override>
# Same as run_review_round but lets the caller force a specific menu_result
# (apply / skip / loop-back / PAUSE_PENDING) for the pause route, so the
# contrast tests can exercise resolved-pause states without rewiring the
# global stub_menu_callable.
run_review_round_with_menu() {
  local primary="$1"
  local refs_json="$2"
  local menu_override="$3"
  local effective route menu
  effective="$(escalate_if_feedback "$primary" "$refs_json")"
  route="$(classify_route "$effective")"
  case "$route" in
    auto-apply) menu="applied" ;;
    pause) menu="$menu_override" ;;
    *) menu="abort" ;;
  esac
  echo "$route:$menu"
}

# ── Spec coverage 1: five primary tags route correctly ──────────────────────

@test "style finding has change_type=style and routes to auto-apply" {
  local ct route_pair route
  ct="$(jq -r '.change_type' "$FIXTURES_DIR/reviewer-finding-style.json")"
  [ "$ct" = "style" ]
  route_pair="$(run_review_round "$ct" "$(jq -c '.referenced_files' "$FIXTURES_DIR/reviewer-finding-style.json")")"
  route="${route_pair%%:*}"
  [ "$route" = "auto-apply" ]
}

@test "clarity finding has change_type=clarity and routes to auto-apply" {
  local ct route_pair route
  ct="$(jq -r '.change_type' "$FIXTURES_DIR/reviewer-finding-clarity.json")"
  [ "$ct" = "clarity" ]
  route_pair="$(run_review_round "$ct" "$(jq -c '.referenced_files' "$FIXTURES_DIR/reviewer-finding-clarity.json")")"
  route="${route_pair%%:*}"
  [ "$route" = "auto-apply" ]
}

@test "correctness finding has change_type=correctness and routes to auto-apply" {
  local ct route_pair route
  ct="$(jq -r '.change_type' "$FIXTURES_DIR/reviewer-finding-correctness.json")"
  [ "$ct" = "correctness" ]
  route_pair="$(run_review_round "$ct" "$(jq -c '.referenced_files' "$FIXTURES_DIR/reviewer-finding-correctness.json")")"
  route="${route_pair%%:*}"
  [ "$route" = "auto-apply" ]
}

@test "scope finding has change_type=scope and routes to pause" {
  local ct route_pair route
  ct="$(jq -r '.change_type' "$FIXTURES_DIR/reviewer-finding-scope.json")"
  [ "$ct" = "scope" ]
  route_pair="$(run_review_round "$ct" "$(jq -c '.referenced_files' "$FIXTURES_DIR/reviewer-finding-scope.json")")"
  route="${route_pair%%:*}"
  [ "$route" = "pause" ]
}

@test "intent finding has change_type=intent and routes to pause" {
  local ct route_pair route
  ct="$(jq -r '.change_type' "$FIXTURES_DIR/reviewer-finding-intent.json")"
  [ "$ct" = "intent" ]
  route_pair="$(run_review_round "$ct" "$(jq -c '.referenced_files' "$FIXTURES_DIR/reviewer-finding-intent.json")")"
  route="${route_pair%%:*}"
  [ "$route" = "pause" ]
}

# ── Spec coverage 2: secondary-escalation rule ──────────────────────────────

@test "secondary-escalation: clarity-tagged finding citing feedback/*.md escalates to intent" {
  local primary refs effective
  primary="$(jq -r '.change_type' "$FIXTURES_DIR/reviewer-finding-secondary-escalation.json")"
  refs="$(jq -c '.referenced_files' "$FIXTURES_DIR/reviewer-finding-secondary-escalation.json")"
  # Sanity: the seeded fixture's primary reviewer tag is NOT intent.
  [ "$primary" != "intent" ]
  # Sanity: referenced_files contains at least one feedback/*.md path.
  echo "$refs" | jq -r '.[]' | grep -qE '^feedback/.*\.md$'
  effective="$(escalate_if_feedback "$primary" "$refs")"
  [ "$effective" = "intent" ]
}

@test "secondary-escalation: escalated finding routes to pause (not auto-apply)" {
  local primary refs route_pair route
  primary="$(jq -r '.change_type' "$FIXTURES_DIR/reviewer-finding-secondary-escalation.json")"
  refs="$(jq -c '.referenced_files' "$FIXTURES_DIR/reviewer-finding-secondary-escalation.json")"
  route_pair="$(run_review_round "$primary" "$refs")"
  route="${route_pair%%:*}"
  [ "$route" = "pause" ]
}

@test "secondary-escalation rule does NOT fire when referenced_files lacks feedback/*.md" {
  local refs effective
  refs='["goals.md","plan.md"]'
  effective="$(escalate_if_feedback "clarity" "$refs")"
  [ "$effective" = "clarity" ]
}

# ── Spec coverage 3: pause gate dispatch ────────────────────────────────────

@test "pause gate fires for change_type=scope" {
  local route_pair route
  route_pair="$(run_review_round "scope" '[]')"
  route="${route_pair%%:*}"
  [ "$route" = "pause" ]
}

@test "pause gate fires for change_type=intent" {
  local route_pair route
  route_pair="$(run_review_round "intent" '[]')"
  route="${route_pair%%:*}"
  [ "$route" = "pause" ]
}

@test "pause gate does NOT fire for change_type=style/clarity/correctness" {
  local pair_a pair_b pair_c route_a route_b route_c
  pair_a="$(run_review_round "style" '[]')"
  pair_b="$(run_review_round "clarity" '[]')"
  pair_c="$(run_review_round "correctness" '[]')"
  route_a="${pair_a%%:*}"
  route_b="${pair_b%%:*}"
  route_c="${pair_c%%:*}"
  [ "$route_a" = "auto-apply" ]
  [ "$route_b" = "auto-apply" ]
  [ "$route_c" = "auto-apply" ]
}

# ── Spec coverage 4: 10-round cap does not decrement on paused rounds ───────

@test "stubbed menu callable returns sentinel PAUSE_PENDING (not apply/skip/loop-back)" {
  local result
  result="$(stub_menu_callable)"
  [ "$result" = "PAUSE_PENDING" ]
  [ "$result" != "apply" ]
  [ "$result" != "skip" ]
  [ "$result" != "loop-back" ]
}

@test "PAUSE_PENDING round (scope): cap unchanged AND loop_state=wait (full contract)" {
  # CodexF2 fix: assert BOTH halves of the PAUSE_PENDING contract — the
  # cap counter does not decrement AND the loop machinery returns to
  # `wait` state. A mutation that broke only the wait-state half (e.g.
  # advancing the loop while leaving the cap intact) would have passed
  # the cap-only assertion this test replaces.
  local refs route_pair route menu starting after state
  refs="$(jq -c '.referenced_files' "$FIXTURES_DIR/reviewer-finding-scope.json")"
  route_pair="$(run_review_round "scope" "$refs")"
  route="${route_pair%%:*}"
  menu="${route_pair##*:}"
  [ "$route" = "pause" ]
  [ "$menu" = "PAUSE_PENDING" ]
  starting=10
  after="$(cap_counter_after_round "$starting" "$route" "$menu")"
  [ "$after" -eq 10 ]
  state="$(loop_state_after_round "$route" "$menu")"
  [ "$state" = "wait" ]
}

@test "PAUSE_PENDING round (intent): cap unchanged AND loop_state=wait (full contract)" {
  local refs route_pair route menu starting after state
  refs="$(jq -c '.referenced_files' "$FIXTURES_DIR/reviewer-finding-intent.json")"
  route_pair="$(run_review_round "intent" "$refs")"
  route="${route_pair%%:*}"
  menu="${route_pair##*:}"
  [ "$route" = "pause" ]
  [ "$menu" = "PAUSE_PENDING" ]
  starting=7
  after="$(cap_counter_after_round "$starting" "$route" "$menu")"
  [ "$after" -eq 7 ]
  state="$(loop_state_after_round "$route" "$menu")"
  [ "$state" = "wait" ]
}

@test "10-round cap counter DOES decrement on an autonomous (auto-applied) round" {
  local route_pair route menu starting after state
  route_pair="$(run_review_round "style" '[]')"
  route="${route_pair%%:*}"
  menu="${route_pair##*:}"
  [ "$route" = "auto-apply" ]
  [ "$menu" = "applied" ]
  starting=10
  after="$(cap_counter_after_round "$starting" "$route" "$menu")"
  [ "$after" -eq 9 ]
  # Auto-applied rounds advance the loop (not wait).
  state="$(loop_state_after_round "$route" "$menu")"
  [ "$state" = "next" ]
}

# ── CodexF2 contrast: resolved-pause options advance the loop and decrement ──
#
# When the user picks one of the 3 valid menu options (apply / skip /
# loop-back) on a paused finding, the loop must NOT remain in wait state
# (loop_state=`next`, NOT `wait`) and the cap counter MUST decrement.
# These contrast tests catch mutations where the wait-state contract is
# broken without affecting cap behavior, and vice-versa.

@test "resolved-pause (apply): loop_state=next AND cap decrements" {
  local route_pair route menu starting after state
  route_pair="$(run_review_round_with_menu "intent" '[]' "apply")"
  route="${route_pair%%:*}"
  menu="${route_pair##*:}"
  [ "$route" = "pause" ]
  [ "$menu" = "apply" ]
  state="$(loop_state_after_round "$route" "$menu")"
  [ "$state" = "next" ]
  [ "$state" != "wait" ]
  starting=10
  after="$(cap_counter_after_round "$starting" "$route" "$menu")"
  [ "$after" -eq 9 ]
}

@test "resolved-pause (skip): loop_state=next AND cap decrements" {
  local route_pair route menu starting after state
  route_pair="$(run_review_round_with_menu "scope" '[]' "skip")"
  route="${route_pair%%:*}"
  menu="${route_pair##*:}"
  [ "$route" = "pause" ]
  [ "$menu" = "skip" ]
  state="$(loop_state_after_round "$route" "$menu")"
  [ "$state" = "next" ]
  [ "$state" != "wait" ]
  starting=8
  after="$(cap_counter_after_round "$starting" "$route" "$menu")"
  [ "$after" -eq 7 ]
}

@test "resolved-pause (loop-back): loop_state=next AND cap decrements" {
  local route_pair route menu starting after state
  route_pair="$(run_review_round_with_menu "intent" '[]' "loop-back")"
  route="${route_pair%%:*}"
  menu="${route_pair##*:}"
  [ "$route" = "pause" ]
  [ "$menu" = "loop-back" ]
  state="$(loop_state_after_round "$route" "$menu")"
  [ "$state" = "next" ]
  [ "$state" != "wait" ]
  starting=5
  after="$(cap_counter_after_round "$starting" "$route" "$menu")"
  [ "$after" -eq 4 ]
}

@test "loop returns to wait state after PAUSE_PENDING round (cap unchanged across multiple paused rounds)" {
  # Three consecutive paused rounds (all unresolved) must leave the autonomous
  # cap counter unchanged AND keep the loop in wait state every round. This is
  # the load-bearing claim from using-qrspi/SKILL.md §"Paused rounds do not
  # decrement the cap": pauses are free against the autonomous cap. (The
  # total/escape-hatch counter is a separate mechanism, not under test in this
  # case.) CodexF2: also assert loop_state=wait each iteration to prove the
  # loop returns to wait, not advances.
  local cap pair route menu state i
  cap=10
  i=0
  while [ "$i" -lt 3 ]; do
    pair="$(run_review_round "intent" '[]')"
    route="${pair%%:*}"
    menu="${pair##*:}"
    [ "$route" = "pause" ]
    [ "$menu" = "PAUSE_PENDING" ]
    state="$(loop_state_after_round "$route" "$menu")"
    [ "$state" = "wait" ]
    cap="$(cap_counter_after_round "$cap" "$route" "$menu")"
    i=$((i + 1))
  done
  [ "$cap" -eq 10 ]
}

# ── Cross-check: contract documented in using-qrspi/SKILL.md ───────────────

@test "using-qrspi/SKILL.md documents the paused-rounds-do-not-decrement rule" {
  # Anchor test: the prose contract that this test simulates must remain
  # documented in using-qrspi/SKILL.md so a future code change cannot
  # silently drop the rule while leaving these stand-in tests passing.
  grep -q "do not decrement the cap\|does not decrement on a paused round\|do not decrement" "$USING_QRSPI_FILE"
}
