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
  # B10: bind relation+decision in a single regex per row so a regression
  # that flips "Proper subset | Narrow" -> "Proper subset | Broaden" fails.
  echo "$PROTOCOL" | grep -qiE 'proper subset.*\*\*[Nn]arrow' \
    || { echo "proper-subset case missing or not bound to **Narrow** in same row"; return 1; }
  # And the BROADER-set safety-margin narrowing semantics:
  echo "$PROTOCOL" | grep -qiE 'broader set|safety margin' \
    || { echo "proper-subset case missing 'broader set' or 'safety margin' rationale"; return 1; }
}

@test "[112-PR2] convergence rule covers proper superset → broaden (auto-broaden on new tag)" {
  # B10: bind relation+decision per row.
  echo "$PROTOCOL" | grep -qiE 'proper superset.*\*\*[Bb]roaden|new tags.*\*\*[Bb]roaden' \
    || { echo "proper-superset case missing or not bound to **Broaden** in same row"; return 1; }
}

@test "[112-PR2] convergence rule covers partial overlap → broaden" {
  # B10: bind relation+decision per row.
  echo "$PROTOCOL" | grep -qiE 'partial overlap.*\*\*[Bb]roaden' \
    || { echo "partial-overlap case missing or not bound to **Broaden** in same row"; return 1; }
}

@test "[112-PR2] convergence rule covers disjoint → broaden" {
  # B10: bind relation+decision per row. A regression that flips
  # "Disjoint | Broaden" to "Disjoint | Narrow" would silently pass under
  # the old loose grep; this regex requires both tokens in the same line.
  echo "$PROTOCOL" | grep -qiE 'disjoint.*\*\*[Bb]roaden' \
    || { echo "disjoint case missing or not bound to **Broaden** in same row"; return 1; }
}

# -----------------------------------------------------------------------------
# 11. <full> reserved-token invariant (B3 + I8)
# -----------------------------------------------------------------------------

@test "[112-PR2] <full> is documented as a reserved literal token" {
  echo "$PROTOCOL" | grep -qE '<full>' \
    || { echo "step 7.5 missing <full> reference"; return 1; }
  echo "$PROTOCOL" | grep -qiE 'reserved literal token|reserved.*token|literal token' \
    || { echo "step 7.5 missing 'reserved literal token' invariant"; return 1; }
}

@test "[112-PR2] <full> in either set forces broaden (B3 precondition row)" {
  # Either set containing <full> -> broaden, regardless of relation.
  echo "$PROTOCOL" | grep -qE '<full>.*\*\*[Bb]roaden' \
    || { echo "step 7.5 missing '<full> in either set -> broaden' precondition row"; return 1; }
}

# -----------------------------------------------------------------------------
# 12. Empty-set precondition (I3)
# -----------------------------------------------------------------------------

@test "[112-PR2] either set empty -> broaden precondition row (I3)" {
  echo "$PROTOCOL" | grep -qiE 'empty.*\*\*[Bb]roaden|either.*empty|set.*empty' \
    || { echo "step 7.5 missing 'either set empty -> broaden' precondition row"; return 1; }
}

# -----------------------------------------------------------------------------
# 13. Comment-skip parser preserves H2 tags (B1)
# -----------------------------------------------------------------------------

@test "[112-PR2] comment-skip parser rule preserves H2 tags (B1)" {
  # The parser MUST skip "# " (single hash + space) but PRESERVE "## " H2
  # heading lines. Documented as "lines NOT starting with # " (with space).
  echo "$PROTOCOL" | grep -qE 'NOT starting with .#' \
    || { echo "step 7.5 missing comment-skip parser rule"; return 1; }
  # Must explicitly note H2 (## ) tags are preserved.
  echo "$PROTOCOL" | grep -qiE '## .*PRESERVED|preserve.*## |H2 heading tags begin' \
    || { echo "step 7.5 parser rule does not explicitly preserve H2 tags (## )"; return 1; }
}

# -----------------------------------------------------------------------------
# 14. Byte-exact + trailing-whitespace strip rule (I2)
# -----------------------------------------------------------------------------

@test "[112-PR2] convergence comparison is byte-exact with trailing-ws strip (I2)" {
  echo "$PROTOCOL" | grep -qiE 'byte-exact|byte exact' \
    || { echo "step 7.5 missing byte-exact comparison rule"; return 1; }
  echo "$PROTOCOL" | grep -qiE 'trailing whitespace|strip.*whitespace' \
    || { echo "step 7.5 missing trailing-whitespace-strip rule"; return 1; }
}

# -----------------------------------------------------------------------------
# 15. HEAD~1 anchor invariant (B5)
# -----------------------------------------------------------------------------

@test "[112-PR2] step 10 captures per-round commit SHA for HEAD~1 anchor (B5)" {
  # Step 10's per-round commit must capture the SHA into round-NN-commit.txt
  # so step 7.5 can assert HEAD~1 matches before narrowing.
  echo "$PROTOCOL" | grep -qE 'round-NN-commit\.txt|round-.*-commit\.txt' \
    || { echo "step 10 does not capture per-round commit SHA into round-NN-commit.txt"; return 1; }
}

@test "[112-PR2] step 7.5 narrow decision asserts HEAD~1 matches the captured anchor (B5)" {
  echo "$PROTOCOL" | grep -qiE 'rev-parse HEAD~1|HEAD~1.*anchor|anchor.*HEAD~1' \
    || { echo "step 7.5 narrow decision missing HEAD~1 anchor assertion"; return 1; }
}

# -----------------------------------------------------------------------------
# 16. Backward-loop persistent flag (B6)
# -----------------------------------------------------------------------------

@test "[112-PR2] backward-loop reset uses a persistent on-disk flag file (B6)" {
  # The pause-gate option-3 cascade writes round-NN-backward-loop.flag;
  # step 7.5 reads + deletes the flag (consume-once).
  echo "$PROTOCOL" | grep -qE 'round-NN-backward-loop\.flag|backward-loop\.flag' \
    || { echo "step 7.5 missing backward-loop.flag file mention"; return 1; }
  echo "$PROTOCOL" | grep -qiE 'consume-once|delete the flag|deletes the flag' \
    || { echo "step 7.5 missing consume-once / delete-flag semantics"; return 1; }
}

# -----------------------------------------------------------------------------
# 17. Tagger malformed-output fail-loud (B4)
# -----------------------------------------------------------------------------

@test "[112-PR2] step 5.5 structurally validates the scope-set file (B4 fail-loud)" {
  echo "$PROTOCOL" | grep -qiE 'structural validation|structurally valid|malformed scope-set' \
    || { echo "step 5.5 missing structural-validation block"; return 1; }
  echo "$PROTOCOL" | grep -qiE 'failure menu|verifier-round failure' \
    || { echo "step 5.5 structural failure does not route to verifier-round failure menu"; return 1; }
}

# -----------------------------------------------------------------------------
# 18. <full> fallback transcript diagnostic (B8)
# -----------------------------------------------------------------------------

@test "[112-PR2] step 5.5 emits transcript diagnostic on <full> fallback (B8)" {
  echo "$PROTOCOL" | grep -qiE 'fell back to <full>|<full>.*fall.*back|<full> for.*finding' \
    || { echo "step 5.5 missing <full>-fallback transcript diagnostic"; return 1; }
}

@test "[112-PR2] B8 diagnostic covers both line-range-omitted and no-H2 causes" {
  # The diagnostic must distinguish/cover both root causes — a regression that
  # loses H2 headings from an artifact would otherwise silently broaden.
  echo "$PROTOCOL" | grep -qF 'no H2 headings' \
    || { echo "B8 diagnostic does not cover the no-H2-headings cause"; return 1; }
}

# -----------------------------------------------------------------------------
# 18b. Literal-token diagnostic pinning (anchor mismatch, I10 distinguish, backward-loop delete-fail)
# -----------------------------------------------------------------------------

@test "[112-PR2] anchor-mismatch broaden-fallback pins literal diagnostic" {
  echo "$PROTOCOL" | grep -qF 'is not the prior per-round commit' \
    || { echo "step 7.5 missing anchor-mismatch literal diagnostic"; return 1; }
}

@test "[112-PR2] I10 distinguishability emits a 'resumed run pre-tagger?' diagnostic" {
  echo "$PROTOCOL" | grep -qF 'resumed run pre-tagger?' \
    || { echo "step 7.5 missing I10 'resumed run pre-tagger' literal diagnostic"; return 1; }
}

@test "[112-PR2] I10 distinguishability emits a 'scope-set absent' diagnostic" {
  echo "$PROTOCOL" | grep -qF 'scope-set absent' \
    || { echo "step 7.5 missing I10 'scope-set absent' literal diagnostic"; return 1; }
}

@test "[112-PR2] I10 fires on rounds 1-2 too (round-1/2 silent fall-through fix)" {
  # Codex round-2 review: tagger failure on rounds 1 or 2 must surface a
  # diagnostic; it cannot rely on the round-3-only branch.
  echo "$PROTOCOL" | grep -qF 'rounds 1–2 broaden by default' \
    || { echo "step 7.5 missing rounds 1-2 missing-scope-set diagnostic"; return 1; }
}

@test "[112-PR2] backward-loop flag delete-failure surfaces a diagnostic" {
  echo "$PROTOCOL" | grep -qF 'backward-loop flag delete failed' \
    || { echo "step 7.5 missing backward-loop delete-fail diagnostic"; return 1; }
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

# -----------------------------------------------------------------------------
# 19. #140 — per-task Implement convergence narrowing
# -----------------------------------------------------------------------------
#
# These assertions ground on the per-task ref-selection contract: default
# <ref>=<task-base-commit> (worktree-relative); narrow → HEAD~1 with anchor
# verification against the prior round's commit-SHA file.

@test "[140] per-task Implement default <ref> is <task-base-commit>" {
  local impl="$REPO_ROOT/skills/implement/SKILL.md"
  [ -f "$impl" ]
  grep -qE '<ref>.*<task-base-commit>|<task-base-commit>.*default|default.*<task-base-commit>' "$impl" \
    || { echo "implement/SKILL.md does not document <task-base-commit> as the per-task default <ref>"; return 1; }
}

@test "[140] per-task Implement narrow decision selects <ref>=HEAD~1" {
  local impl="$REPO_ROOT/skills/implement/SKILL.md"
  grep -qF '<ref>=HEAD~1' "$impl" \
    || { echo "implement/SKILL.md narrow decision does not select literal <ref>=HEAD~1"; return 1; }
}

@test "[140] per-task Implement anchor file path is reviews/tasks/task-NN/round-NN-commit.txt" {
  local impl="$REPO_ROOT/skills/implement/SKILL.md"
  grep -qF 'reviews/tasks/task-NN/round-NN-commit.txt' "$impl" \
    || { echo "implement/SKILL.md missing per-task per-round commit anchor path"; return 1; }
}

@test "[140] per-task Implement narrow decision verifies HEAD~1 against the anchor file" {
  local impl="$REPO_ROOT/skills/implement/SKILL.md"
  # The narrow path must mention rev-parse HEAD~1 against the prior round's
  # round-(NN-1)-commit.txt anchor.
  grep -qiE 'rev-parse HEAD~1|HEAD~1.*anchor|anchor.*HEAD~1' "$impl" \
    || { echo "implement/SKILL.md narrow decision missing HEAD~1 anchor verification"; return 1; }
  # And must reference the prior-round commit file.
  grep -qE 'round-\(NN-1\)-commit\.txt|round-NN-commit\.txt' "$impl" \
    || { echo "implement/SKILL.md narrow decision missing prior-round commit file reference"; return 1; }
}

@test "[140] per-task Implement broaden fallback fires on anchor mismatch" {
  local impl="$REPO_ROOT/skills/implement/SKILL.md"
  # When HEAD~1 mismatches the anchor, the narrow decision falls through to
  # broaden with a one-line diagnostic. Pin to the literal phrase emitted in
  # both SKILL.md files so the assertion catches phrasing drift.
  grep -qF 'is not the prior per-round commit' "$impl" \
    || { echo "implement/SKILL.md missing anchor-mismatch broaden fallback diagnostic"; return 1; }
}

@test "[140] per-task Implement backward-loop flag path is reviews/tasks/task-NN/round-NN-backward-loop.flag" {
  local impl="$REPO_ROOT/skills/implement/SKILL.md"
  grep -qF 'reviews/tasks/task-NN/round-NN-backward-loop.flag' "$impl" \
    || { echo "implement/SKILL.md missing per-task backward-loop flag path"; return 1; }
}

@test "[140] per-task Implement respects scope_tagger_enabled=false opt-out" {
  local impl="$REPO_ROOT/skills/implement/SKILL.md"
  grep -qiE 'scope_tagger_enabled.*false|scope_tagger_enabled: false|no-op.*scope_tagger_enabled' "$impl" \
    || { echo "implement/SKILL.md does not document scope_tagger_enabled=false opt-out"; return 1; }
}

@test "[140] per-task Implement defers to using-qrspi convergence rule table" {
  # Per-task uses the SAME convergence rule table from using-qrspi step 7.5;
  # implement.SKILL.md must reference that contract rather than restate the
  # full table.
  local impl="$REPO_ROOT/skills/implement/SKILL.md"
  grep -qE 'using-qrspi.*step 7\.5|step 7\.5.*using-qrspi|convergence-rule table from using-qrspi|using-qrspi/SKILL\.md.*7\.5' "$impl" \
    || { echo "implement/SKILL.md does not reference using-qrspi step 7.5 convergence rule"; return 1; }
}

@test "[140] per-task Implement \$SCOPE_HINT is populated from scope_set on narrow" {
  local impl="$REPO_ROOT/skills/implement/SKILL.md"
  # Variable population: SCOPE_HINT carries the comma-separated tag list when
  # narrowed, empty when broadened.
  grep -qE '\$SCOPE_HINT' "$impl" \
    || { echo "implement/SKILL.md missing \$SCOPE_HINT shell variable"; return 1; }
  grep -qiE 'comma-separated|comma.separated|joined with.*,' "$impl" \
    || { echo "implement/SKILL.md missing comma-separated \$SCOPE_HINT format"; return 1; }
}

@test "[140] per-task Implement convergence subsection asserts no-silent-broaden / fail-loud" {
  # Negative-case assertion: the convergence subsection must contain at least
  # one explicit no-silent-broaden / fail-loud signal so a future edit cannot
  # silently regress to "broaden anyway, swallow the error".
  local impl="$REPO_ROOT/skills/implement/SKILL.md"
  local section
  section=$(awk '
    /^### Per-Task Convergence Narrowing/ { in_section=1; print; next }
    in_section && /^### / { in_section=0 }
    in_section { print }
  ' "$impl")
  echo "$section" | grep -qE 'do NOT silently broaden|fail-loud|Fail-loud' \
    || { echo "implement/SKILL.md per-task convergence subsection missing fail-loud / no-silent-broaden assertion"; return 1; }
}

@test "[140] per-task Implement convergence subsection preserves I10 distinguishability with per-task paths" {
  # I10: when broadening due to a missing scope-set, the diagnostic must
  # distinguish "round NN-1 missing" from "round NN missing" using the
  # per-task literal paths (NOT the artifact-level using-qrspi paths).
  local impl="$REPO_ROOT/skills/implement/SKILL.md"
  local section
  section=$(awk '
    /^### Per-Task Convergence Narrowing/ { in_section=1; print; next }
    in_section && /^### / { in_section=0 }
    in_section { print }
  ' "$impl")
  echo "$section" | grep -qE 'I10|distinguishability' \
    || { echo "implement/SKILL.md per-task convergence subsection missing I10 / distinguishability reference"; return 1; }
  echo "$section" | grep -qE 'reviews/tasks/task-NN' \
    || { echo "implement/SKILL.md per-task convergence subsection missing per-task reviews/tasks/task-NN paths in I10 context"; return 1; }
}

# -----------------------------------------------------------------------------
# 20. #140 — Integrate convergence narrowing
# -----------------------------------------------------------------------------

@test "[140] Integrate default <ref> is <base-branch>" {
  local intg="$REPO_ROOT/skills/integrate/SKILL.md"
  [ -f "$intg" ]
  grep -qE '<ref>.*<base-branch>|<base-branch>.*default|default.*<base-branch>' "$intg" \
    || { echo "integrate/SKILL.md does not document <base-branch> as the default <ref>"; return 1; }
}

@test "[140] Integrate narrow decision selects <ref>=HEAD~1" {
  local intg="$REPO_ROOT/skills/integrate/SKILL.md"
  grep -qF '<ref>=HEAD~1' "$intg" \
    || { echo "integrate/SKILL.md narrow decision does not select literal <ref>=HEAD~1"; return 1; }
}

@test "[140] Integrate anchor file path is reviews/integration/round-NN-commit.txt" {
  local intg="$REPO_ROOT/skills/integrate/SKILL.md"
  grep -qF 'reviews/integration/round-NN-commit.txt' "$intg" \
    || { echo "integrate/SKILL.md missing per-round commit anchor path"; return 1; }
}

@test "[140] Integrate narrow decision verifies HEAD~1 against the anchor file" {
  local intg="$REPO_ROOT/skills/integrate/SKILL.md"
  grep -qiE 'rev-parse HEAD~1|HEAD~1.*anchor|anchor.*HEAD~1' "$intg" \
    || { echo "integrate/SKILL.md narrow decision missing HEAD~1 anchor verification"; return 1; }
  grep -qE 'round-\(NN-1\)-commit\.txt|round-NN-commit\.txt' "$intg" \
    || { echo "integrate/SKILL.md narrow decision missing prior-round commit file reference"; return 1; }
}

@test "[140] Integrate broaden fallback fires on anchor mismatch" {
  local intg="$REPO_ROOT/skills/integrate/SKILL.md"
  grep -qF 'is not the prior per-round commit' "$intg" \
    || { echo "integrate/SKILL.md missing anchor-mismatch broaden fallback diagnostic"; return 1; }
}

@test "[140] Integrate backward-loop flag path is reviews/integration/round-NN-backward-loop.flag" {
  local intg="$REPO_ROOT/skills/integrate/SKILL.md"
  grep -qF 'reviews/integration/round-NN-backward-loop.flag' "$intg" \
    || { echo "integrate/SKILL.md missing backward-loop flag path"; return 1; }
}

@test "[140] Integrate respects scope_tagger_enabled=false opt-out" {
  local intg="$REPO_ROOT/skills/integrate/SKILL.md"
  grep -qiE 'scope_tagger_enabled.*false|scope_tagger_enabled: false|no-op.*scope_tagger_enabled' "$intg" \
    || { echo "integrate/SKILL.md does not document scope_tagger_enabled=false opt-out"; return 1; }
}

@test "[140] Integrate defers to using-qrspi convergence rule table" {
  local intg="$REPO_ROOT/skills/integrate/SKILL.md"
  grep -qE 'using-qrspi.*step 7\.5|step 7\.5.*using-qrspi|convergence-rule table from using-qrspi|using-qrspi/SKILL\.md.*7\.5' "$intg" \
    || { echo "integrate/SKILL.md does not reference using-qrspi step 7.5 convergence rule"; return 1; }
}

@test "[140] Integrate \$SCOPE_HINT is populated from scope_set on narrow" {
  local intg="$REPO_ROOT/skills/integrate/SKILL.md"
  grep -qE '\$SCOPE_HINT' "$intg" \
    || { echo "integrate/SKILL.md missing \$SCOPE_HINT shell variable"; return 1; }
  grep -qiE 'comma-separated|comma.separated|joined with.*,' "$intg" \
    || { echo "integrate/SKILL.md missing comma-separated \$SCOPE_HINT format"; return 1; }
}

@test "[140] Integrate convergence subsection asserts no-silent-broaden / fail-loud" {
  # Negative-case assertion: the convergence subsection must contain at least
  # one explicit no-silent-broaden / fail-loud signal so a future edit cannot
  # silently regress to "broaden anyway, swallow the error". Integrate's
  # convergence subsection is indented (nested under a numbered list); the
  # awk pattern strips leading whitespace before matching the heading.
  local intg="$REPO_ROOT/skills/integrate/SKILL.md"
  local section
  section=$(awk '
    /^[[:space:]]*### Integrate Convergence Narrowing/ { in_section=1; print; next }
    in_section && /^[[:space:]]*### / { in_section=0 }
    in_section && /^[[:space:]]*## / { in_section=0 }
    in_section && /^[0-9]+\. \*\*/ { in_section=0 }
    in_section { print }
  ' "$intg")
  echo "$section" | grep -qE 'do NOT silently broaden|fail-loud|Fail-loud' \
    || { echo "integrate/SKILL.md Integrate convergence subsection missing fail-loud / no-silent-broaden assertion"; return 1; }
}

@test "[140] Integrate convergence subsection preserves I10 distinguishability with Integrate paths" {
  # I10: when broadening due to a missing scope-set, the diagnostic must
  # distinguish "round NN-1 missing" from "round NN missing" using the
  # Integrate literal paths (NOT the artifact-level using-qrspi paths).
  local intg="$REPO_ROOT/skills/integrate/SKILL.md"
  local section
  section=$(awk '
    /^[[:space:]]*### Integrate Convergence Narrowing/ { in_section=1; print; next }
    in_section && /^[[:space:]]*### / { in_section=0 }
    in_section && /^[[:space:]]*## / { in_section=0 }
    in_section && /^[0-9]+\. \*\*/ { in_section=0 }
    in_section { print }
  ' "$intg")
  echo "$section" | grep -qE 'I10|distinguishability' \
    || { echo "integrate/SKILL.md Integrate convergence subsection missing I10 / distinguishability reference"; return 1; }
  echo "$section" | grep -qE 'reviews/integration' \
    || { echo "integrate/SKILL.md Integrate convergence subsection missing reviews/integration paths in I10 context"; return 1; }
}

# -----------------------------------------------------------------------------
# 21. #140 — both flows use the same convergence rule cases
# -----------------------------------------------------------------------------

@test "[140] both per-task and Integrate reference the equal/subset/superset/partial/disjoint rule cases" {
  # Both flows defer to using-qrspi step 7.5's table — no rule restatement
  # required, but the prose must at least cite the rule cases (equal,
  # proper-subset, superset, partial, disjoint, <full>, empty).
  for skill in implement integrate; do
    local skill_path="$REPO_ROOT/skills/$skill/SKILL.md"
    grep -qiE 'equal.*proper-subset|proper-subset.*narrow|equal.*subset.*narrow' "$skill_path" \
      || { echo "skill $skill: missing equal/proper-subset narrow case"; return 1; }
    grep -qiE 'superset.*broaden|partial.*broaden|disjoint.*broaden' "$skill_path" \
      || { echo "skill $skill: missing superset/partial/disjoint broaden cases"; return 1; }
    grep -qE '<full>' "$skill_path" \
      || { echo "skill $skill: missing <full> reserved-token case"; return 1; }
    grep -qiE 'either set empty|set empty.*broaden|empty.*broaden' "$skill_path" \
      || { echo "skill $skill: missing 'either set empty -> broaden' case"; return 1; }
  done
}
