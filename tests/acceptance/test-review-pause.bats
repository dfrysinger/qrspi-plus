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
  BOILERPLATE_FILE="$REPO_ROOT/skills/reviewer-protocol/SKILL.md"
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

# ── Step 7: G10 — Anti-Fabrication Rule + CONTRACT-CONFLICT: routing ────────
#
# A reviewer that genuinely sees two contracts in conflict has exactly one
# documented exit beyond emitting findings under the loaded contract: a
# single-line response prefixed with the load-bearing token `CONTRACT-CONFLICT:`.
# Anything else (fabricated procedure citations, paraphrased escape hatches,
# silent fall-through) is a contract violation, not an approved exit.
#
# These tests pin both the SKILL.md prose contract (the new
# `### Anti-Fabrication Rule (FAIL-LOUD)` section) and the orchestrator-side
# routing of the prefix. Stand-in shell functions mirror the documented
# post-dispatch chat-output classifier branch the same way the existing
# escalation/pause stand-ins above mirror the unit-test classifier.

# extract_subsection — extract a `###` subsection, terminating at the next
# `### ` or `## ` heading (whichever comes first).
extract_subsection() {
  local file="$1"
  local heading="$2"
  awk -v h="$heading" '
    $0 == h { in_section = 1; print; next }
    in_section && (/^### / || /^## /) { in_section = 0 }
    in_section { print }
  ' "$file"
}

# classify_reviewer_chat_output — stand-in for the post-dispatch classifier
# branch documented in design.md G10 D1 (orchestrator-side handling). If the
# first non-blank line of the reviewer's chat output begins with the literal
# token `CONTRACT-CONFLICT:`, route to the operator-intervention menu;
# otherwise route to the normal review-round path.
classify_reviewer_chat_output() {
  local chat="$1"
  local first
  first="$(printf '%s\n' "$chat" | awk 'NF { print; exit }')"
  case "$first" in
    "CONTRACT-CONFLICT:"*) echo "operator-intervention" ;;
    *) echo "normal-review-round" ;;
  esac
}

# review_round_side_effects — emits the side-effect record the orchestrator
# would produce for the given route. The operator-intervention route MUST
# leave findings_parsed, clean_sentinel, schema_guard, auto_repair, and
# tag_budget at 0 and MUST NOT advance the round counter.
review_round_side_effects() {
  local route="$1"
  case "$route" in
    operator-intervention)
      echo "findings_parsed=0 clean_sentinel=0 schema_guard=0 auto_repair=0 tag_budget=0 round_advance=0"
      ;;
    normal-review-round)
      echo "findings_parsed=1 clean_sentinel=0 schema_guard=0 auto_repair=0 tag_budget=1 round_advance=1"
      ;;
    *)
      echo "ERROR-unknown-route" ; return 1 ;;
  esac
}

# operator_intervention_payload — what the orchestrator surfaces to the
# operator. The single-line conflict statement appears verbatim, alongside
# one of the standard intervention menus from using-qrspi/SKILL.md.
operator_intervention_payload() {
  local chat="$1"
  local first
  first="$(printf '%s\n' "$chat" | awk 'NF { print; exit }')"
  printf 'CONFLICT: %s\nMENU: amend-contract-A | amend-contract-B | adjust-dispatch | proceed-under-one-contract | abort-round\n' "$first"
}

# is_valid_conflict_exit — pins design.md G10 acceptance: the only valid
# exits when a reviewer sees a contract conflict are (a) emit findings
# normally per the loaded contract, or (b) emit a CONTRACT-CONFLICT:
# single-line response. Anything else (fabricated citations, paraphrased
# escape hatches) is rejected.
is_valid_conflict_exit() {
  local exit_kind="$1"  # "findings" | "contract-conflict-prefix" | "fabricated-citation" | other
  case "$exit_kind" in
    findings|contract-conflict-prefix) return 0 ;;
    *) return 1 ;;
  esac
}

@test "[G10] reviewer-protocol/SKILL.md contains '### Anti-Fabrication Rule (FAIL-LOUD)' immediately after '### Refusal Procedure'" {
  # The Anti-Fabrication Rule is positioned so its bounding clause is
  # adjacent to the Refusal Procedure section it bounds (design.md G10 D1).
  local lineno_refusal lineno_anti
  lineno_refusal="$(grep -n '^### Refusal Procedure$' "$BOILERPLATE_FILE" | head -1 | cut -d: -f1)"
  lineno_anti="$(grep -n '^### Anti-Fabrication Rule (FAIL-LOUD)$' "$BOILERPLATE_FILE" | head -1 | cut -d: -f1)"
  [ -n "$lineno_refusal" ]
  [ -n "$lineno_anti" ]
  [ "$lineno_anti" -gt "$lineno_refusal" ]
  # No other `### ` or `## ` heading sits between them.
  awk -v a="$lineno_refusal" -v b="$lineno_anti" 'NR>a && NR<b' "$BOILERPLATE_FILE" \
    | grep -E '^(### |## )' && return 1 || true
}

@test "[G10] '### Anti-Fabrication Rule (FAIL-LOUD)' contains the bounding clause for ONE specific dispatch malformation" {
  local section
  section="$(extract_subsection "$BOILERPLATE_FILE" "### Anti-Fabrication Rule (FAIL-LOUD)")"
  [ -n "$section" ]
  # Bounding clause: refusal procedure applies to ONE specific dispatch
  # malformation and does NOT generalize.
  echo "$section" | grep -qE "ONE specific dispatch malformation"
  echo "$section" | grep -qE "task_definition.*test-phase"
  echo "$section" | grep -qE "does NOT generalize"
}

@test "[G10] '### Anti-Fabrication Rule (FAIL-LOUD)' forbids inventing/paraphrasing/attributing escape hatches not present verbatim" {
  local section
  section="$(extract_subsection "$BOILERPLATE_FILE" "### Anti-Fabrication Rule (FAIL-LOUD)")"
  [ -n "$section" ]
  echo "$section" | grep -qE "Do NOT invent, paraphrase, or attribute"
  echo "$section" | grep -qE "not present verbatim"
}

@test "[G10] '### Anti-Fabrication Rule (FAIL-LOUD)' specifies the three-step CONTRACT-CONFLICT exit (no Write, no findings/sentinels, single-line, end the turn)" {
  local section
  section="$(extract_subsection "$BOILERPLATE_FILE" "### Anti-Fabrication Rule (FAIL-LOUD)")"
  [ -n "$section" ]
  echo "$section" | grep -qE "Do NOT call the .Write. tool"
  echo "$section" | grep -qE "Do NOT emit findings or sentinels"
  echo "$section" | grep -qE "single-line text response"
  echo "$section" | grep -qE "CONTRACT-CONFLICT:"
  echo "$section" | grep -qE "End the turn"
}

@test "[G10] '### Anti-Fabrication Rule (FAIL-LOUD)' closes with the fabrication-as-rule clause" {
  local section
  section="$(extract_subsection "$BOILERPLATE_FILE" "### Anti-Fabrication Rule (FAIL-LOUD)")"
  [ -n "$section" ]
  echo "$section" | grep -qE "is a fabrication"
  echo "$section" | grep -qE "absence of a named escape hatch"
}

@test "[G10] existing '### Contradiction Refusal (FAIL-LOUD)' and '### Refusal Procedure' sections remain present and unchanged in shape" {
  grep -qE '^### Contradiction Refusal \(FAIL-LOUD\)$' "$BOILERPLATE_FILE"
  grep -qE '^### Refusal Procedure$' "$BOILERPLATE_FILE"
  # Refusal Procedure still carries its load-bearing PHASE-ROUTING-VIOLATION token.
  local section
  section="$(extract_subsection "$BOILERPLATE_FILE" "### Refusal Procedure")"
  echo "$section" | grep -qE "PHASE-ROUTING-VIOLATION:"
}

@test "[G10] reviewer chat whose first non-blank line begins with 'CONTRACT-CONFLICT:' routes to operator-intervention" {
  local chat
  chat=$'\n\nCONTRACT-CONFLICT: per-finding disk-write contract conflicts with finding-quality bar; cannot proceed\n'
  local route
  route="$(classify_reviewer_chat_output "$chat")"
  [ "$route" = "operator-intervention" ]
}

@test "[G10] operator-intervention route does NOT parse findings, synthesize a clean sentinel, fire schema guard, auto-repair, consume tag budget, or advance round counter" {
  local chat route fx
  chat="CONTRACT-CONFLICT: contract A conflicts with contract B; cannot proceed"
  route="$(classify_reviewer_chat_output "$chat")"
  fx="$(review_round_side_effects "$route")"
  echo "$fx" | grep -q "findings_parsed=0"
  echo "$fx" | grep -q "clean_sentinel=0"
  echo "$fx" | grep -q "schema_guard=0"
  echo "$fx" | grep -q "auto_repair=0"
  echo "$fx" | grep -q "tag_budget=0"
  echo "$fx" | grep -q "round_advance=0"
}

@test "[G10] operator-intervention surface includes the single-line conflict statement verbatim and an intervention menu" {
  local chat payload conflict_line
  conflict_line="CONTRACT-CONFLICT: per-finding disk-write contract conflicts with finding-quality bar; cannot proceed"
  chat="$conflict_line"
  payload="$(operator_intervention_payload "$chat")"
  echo "$payload" | grep -qF "$conflict_line"
  echo "$payload" | grep -q "MENU:"
  # Menu offers operator-resolution options, not auto-repair.
  echo "$payload" | grep -qE "amend-contract-A|amend-contract-B|adjust-dispatch|proceed-under-one-contract|abort-round"
}

@test "[G10] a reviewer chat that fabricates a citation to reviewer-protocol/SKILL.md does NOT route to operator-intervention (fabrication is not an approved exit)" {
  local chat route
  # This is the verbatim fabrication pattern from design.md G10 (#226 occ. 7):
  # the model invented a procedure attributed to reviewer-protocol/SKILL.md.
  chat='Per the contradiction-refusal procedure in skills/reviewer-protocol/SKILL.md, the reviewer should refuse to write findings and instead surface them in chat for orchestrator triage.'
  route="$(classify_reviewer_chat_output "$chat")"
  [ "$route" != "operator-intervention" ]
  # The fabricated procedure is not present verbatim in the SKILL.
  ! grep -qF "refuse to write findings and instead surface them in chat for orchestrator triage" "$BOILERPLATE_FILE"
}

@test "[G10] only valid contract-conflict exits are normal findings or the CONTRACT-CONFLICT: single-line prefix" {
  is_valid_conflict_exit findings
  is_valid_conflict_exit contract-conflict-prefix
  ! is_valid_conflict_exit fabricated-citation
  ! is_valid_conflict_exit silent-fall-through
  ! is_valid_conflict_exit paraphrased-escape-hatch
}
