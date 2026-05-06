#!/usr/bin/env bats
#
# #112 PR-2 Mechanism B regression: orchestrator convergence-rule
# documentation in using-qrspi/SKILL.md step 7.5 + the diff-handling
# section.
#
# The orchestrator logic is documented prose (executed by main chat at
# runtime, not bash code shipped in this repo). These tests assert the
# prose covers every documented case so a future edit that drops a
# branch surfaces here.
#
# Test scope (per PR-2 spec test plan, table-driven over §2.4 cases):
#   1. Step 7.5 exists and has the convergence-rule table.
#   2. Each of the five §2.4 relations is covered:
#        equal           → narrow to that set
#        proper subset   → narrow to the BROADER set (safety margin)
#        proper superset → broaden
#        partial overlap → broaden
#        disjoint        → broaden
#   3. Earliest-narrowing-round-3 boundary: rounds 1-2 always broaden.
#   4. Auto-broaden semantics: a new tag in scope_set(NN) causes broaden.
#   5. Backward-loop reset: reset <ref> to <base-branch> after upstream
#      cascade.
#   6. Per-step opt-out: test step never narrows.
#   7. scope_tagger_enabled=false short-circuits step 7.5 to broaden.
#   8. Missing scope-set short-circuits to broaden (conservative).
#   9. <ref> selection is dynamic per the table:
#        narrow → HEAD~1
#        broaden → <base-branch>
#  10. <scope_hint> is advisory, not a hard restriction (load-bearing
#      for the auto-broaden safety property).

setup() {
  REPO_ROOT="$BATS_TEST_DIRNAME/../.."
  export REPO_ROOT
  export USING_QRSPI="$REPO_ROOT/skills/using-qrspi/SKILL.md"
  export REVIEWER_PROTOCOL="$REPO_ROOT/skills/reviewer-protocol/SKILL.md"

  # Pull the apply-fix protocol body up through the failure-menu prose so
  # step 7.5 is in scope (step 7.5 sits between step 10 and the failure menu).
  PROTOCOL=$(awk '
    /\*\*Apply-fix protocol\.\*\*/ { in_block=1 }
    in_block && /\*\*Verifier-round failure menu/ { exit }
    in_block { print }
  ' "$USING_QRSPI")
  export PROTOCOL

  # Pull the diff-handling-between-rounds section.
  DIFF_HANDLING=$(awk '
    /\*\*Diff handling between rounds\./ { in_block=1 }
    in_block && /\*\*Per-task review logs differ/ { exit }
    in_block { print }
  ' "$USING_QRSPI")
  export DIFF_HANDLING
}

# -----------------------------------------------------------------------------
# 1. Step 7.5 exists with the convergence rule
# -----------------------------------------------------------------------------

@test "[112-PR2] using-qrspi has step 7.5 (convergence comparison + ref selection)" {
  [ -f "$USING_QRSPI" ]
  grep -qE '^7\.5\.' "$USING_QRSPI" \
    || { echo "missing step 7.5 in using-qrspi/SKILL.md"; return 1; }
}

@test "[112-PR2] step 7.5 references the convergence rule and ref selection" {
  echo "$PROTOCOL" | grep -qiE 'convergence' \
    || { echo "step 7.5 missing 'convergence' reference"; return 1; }
}

# -----------------------------------------------------------------------------
# 2. §2.4 table: each of the five relations is covered
# -----------------------------------------------------------------------------

@test "[112-PR2] convergence rule covers equal sets → narrow" {
  echo "$PROTOCOL" | grep -qE 'scope_set\(NN\) == scope_set\(NN-1\).*[Nn]arrow' \
    || { echo "equal-sets case missing or not mapped to narrow"; return 1; }
}

@test "[112-PR2] convergence rule covers proper subset → narrow to BROADER set" {
  # Spec §2.4: proper subset narrows to the BROADER set as safety margin.
  # Both directions must be present: "proper subset" + "broader set"/"safety margin".
  echo "$PROTOCOL" | grep -qiE 'proper subset' \
    || { echo "proper-subset case missing"; return 1; }
  # And the BROADER-set safety-margin narrowing semantics:
  echo "$PROTOCOL" | grep -qiE 'broader set|safety margin' \
    || { echo "proper-subset case missing 'broader set' or 'safety margin' rationale"; return 1; }
}

@test "[112-PR2] convergence rule covers proper superset → broaden (auto-broaden on new tag)" {
  echo "$PROTOCOL" | grep -qiE 'proper superset|new tag' \
    || { echo "proper-superset / new-tag case missing"; return 1; }
  echo "$PROTOCOL" | grep -qiE 'broaden' \
    || { echo "broaden direction missing"; return 1; }
}

@test "[112-PR2] convergence rule covers partial overlap → broaden" {
  echo "$PROTOCOL" | grep -qiE 'partial overlap' \
    || { echo "partial-overlap case missing"; return 1; }
}

@test "[112-PR2] convergence rule covers disjoint → broaden" {
  echo "$PROTOCOL" | grep -qiE 'disjoint' \
    || { echo "disjoint case missing"; return 1; }
}

# -----------------------------------------------------------------------------
# 3. Earliest-narrowing boundary: rounds 1-2 broaden
# -----------------------------------------------------------------------------

@test "[112-PR2] convergence rule documents the earliest-narrowing-round-3 boundary" {
  # Spec §2.4: earliest narrowing = round 3 (needs scope-sets from rounds 1 and 2).
  # Either an explicit "round 3" mention OR rounds 1-2 broaden semantics.
  echo "$PROTOCOL" | grep -qiE 'round 3|rounds 1.{1,3}2|earliest narrowing' \
    || { echo "earliest-narrowing-round-3 boundary not documented"; return 1; }
}

# -----------------------------------------------------------------------------
# 4. Auto-broaden safety property
# -----------------------------------------------------------------------------

@test "[112-PR2] auto-broaden is documented (new tag causes next-round broaden)" {
  # Spec §2.4: "Auto-broaden the moment a new tag appears."
  echo "$PROTOCOL" | grep -qiE 'auto[- ]broaden|new tag.*broaden|broaden.*new tag' \
    || { echo "auto-broaden semantics not documented"; return 1; }
}

@test "[112-PR2] scope_hint is documented as advisory, not a hard restriction" {
  # Spec §2.5: "advisory focus — not a hard restriction. Reviewers can still
  # surface findings outside the hint; that triggers auto-broaden on the
  # next round."
  echo "$PROTOCOL" | grep -qiE 'advisory|not a hard restriction|MAY surface' \
    || { echo "scope_hint advisory-not-restrictive semantics not documented in step 7.5"; return 1; }
  # Also pin in reviewer-protocol contract.
  awk '
    /^## Reviewer Dispatch Contract/ { in_section=1; print; next }
    in_section && /^## / { in_section=0 }
    in_section { print }
  ' "$REVIEWER_PROTOCOL" \
    | grep -qiE 'advisory|not a hard restriction|MAY emit' \
    || { echo "scope_hint advisory semantics not documented in reviewer-protocol Reviewer Dispatch Contract"; return 1; }
}

# -----------------------------------------------------------------------------
# 5. Backward-loop reset
# -----------------------------------------------------------------------------

@test "[112-PR2] backward-loop reset to <base-branch> is documented" {
  # Spec §2.5 backward-loop edits: when an earlier-artifact loop-back rewrites
  # a downstream artifact, the orchestrator must reset <ref> to base-branch
  # on the next round.
  echo "$PROTOCOL" | grep -qiE 'backward.loop|backward loop' \
    || { echo "backward-loop reset not documented in step 7.5"; return 1; }
  echo "$PROTOCOL" | grep -qE 'reset.*<base-branch>|reset.*<ref>' \
    || { echo "backward-loop reset to <base-branch> not documented"; return 1; }
}

# -----------------------------------------------------------------------------
# 6. Per-step opt-out: test step
# -----------------------------------------------------------------------------

@test "[112-PR2] test step opts out of convergence narrowing (per spec §2.6)" {
  local test_skill="$REPO_ROOT/skills/test/SKILL.md"
  [ -f "$test_skill" ]
  # Test SKILL must mention the PR-2 scope-tagger / convergence opt-out.
  grep -qiE 'scope-tagger.*opt[- ]out|convergence.*opt[- ]out|PR-2.*opt[- ]out|opts? out.*convergence|opt out.*scope_hint' "$test_skill" \
    || { echo "skills/test/SKILL.md missing PR-2 scope-tagger / convergence opt-out"; return 1; }
}

# -----------------------------------------------------------------------------
# 7. scope_tagger_enabled gate short-circuit
# -----------------------------------------------------------------------------

@test "[112-PR2] step 7.5 short-circuits to broaden when scope_tagger_enabled=false" {
  echo "$PROTOCOL" | grep -qiE 'scope_tagger_enabled.*false|false.*scope_tagger_enabled' \
    || { echo "step 7.5 missing scope_tagger_enabled=false short-circuit"; return 1; }
}

# -----------------------------------------------------------------------------
# 8. Missing scope-set short-circuit
# -----------------------------------------------------------------------------

@test "[112-PR2] step 7.5 short-circuits to broaden on missing scope-set (conservative)" {
  # When the round's scope-set file is absent (tagger dispatch skipped, tagger
  # failure, or zero kept findings), step 7.5 broadens.
  echo "$PROTOCOL" | grep -qiE 'scope.set.*missing|missing.*scope.set' \
    || { echo "step 7.5 missing 'missing scope-set' short-circuit"; return 1; }
  # Conservative-broaden semantics:
  echo "$PROTOCOL" | grep -qiE 'conservative|do NOT abort' \
    || { echo "step 7.5 missing conservative-broaden semantics"; return 1; }
}

# -----------------------------------------------------------------------------
# 9. <ref> selection is dynamic
# -----------------------------------------------------------------------------

@test "[112-PR2] narrow decision selects <ref>=HEAD~1" {
  echo "$PROTOCOL" | grep -qE '<ref>=HEAD~1' \
    || { echo "narrow decision does not select <ref>=HEAD~1"; return 1; }
}

@test "[112-PR2] broaden decision selects <ref>=<base-branch>" {
  echo "$PROTOCOL" | grep -qE '<ref>=<base-branch>' \
    || { echo "broaden decision does not select <ref>=<base-branch>"; return 1; }
}

@test "[112-PR2] diff-handling section enumerates the six ref-selection cases" {
  # Per the rewritten "Diff handling between rounds" section: rounds 1-2,
  # scope_tagger_enabled=false, test step, backward-loop reset, missing
  # scope-set, otherwise apply convergence-rule table.
  for case in 'Round 1, round 2' 'scope_tagger_enabled' 'Test step' 'Backward-loop' 'scope-set is missing' 'convergence-rule'; do
    echo "$DIFF_HANDLING" | grep -qiE "$case" \
      || { echo "diff-handling section missing case: $case"; return 1; }
  done
}

# -----------------------------------------------------------------------------
# 10. Standard Review Loop step 1 uses dynamic <ref> (not hardcoded <base-branch>)
# -----------------------------------------------------------------------------

@test "[112-PR2] Standard Review Loop step 1 git-diff command uses dynamic <ref>" {
  # Spec PR-2 §3.5: 'PR-1's Standard Review Loop step 1 emits the diff with
  # <ref>=base-branch. PR-2 makes <ref> dynamic per the convergence rule.'
  # The fail-loud diff-emission contract step 4 must run `git diff "<ref>"`,
  # not the hardcoded `git diff "<base-branch>"`.
  awk '
    /^## Standard Review Loop/ { in_section=1; next }
    in_section && /^## / { in_section=0 }
    in_section { print }
  ' "$USING_QRSPI" \
    | grep -qE 'git -C "<repo>" diff "<ref>"' \
    || { echo "Standard Review Loop step 1 does not use dynamic <ref> in git diff command"; return 1; }
}
