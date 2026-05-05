#!/usr/bin/env bats

# #109-scope reviewer agent files (14): per-finding emission required.
# Deferred reviewers are skipped per the follow-up issue (see body comment).
# When the follow-up issue (#125) lands, extend this test to
# cover the deferred reviewers too.

setup() {
  scope_files=(
    agents/qrspi-{goals,questions,research,design,phasing,structure,parallelize,replan}-reviewer.md
    agents/qrspi-{goals,design,phasing,structure,parallelize,replan}-scope-reviewer.md
  )
  deferred_files=(
    agents/qrspi-plan-reviewer.md
    agents/qrspi-plan-scope-reviewer.md
    agents/qrspi-plan-spec-reviewer.md
    agents/qrspi-plan-security-reviewer.md
    agents/qrspi-plan-silent-failure-hunter.md
    agents/qrspi-plan-goal-traceability-reviewer.md
    agents/qrspi-plan-test-coverage-reviewer.md
    agents/qrspi-spec-reviewer.md
    agents/qrspi-code-quality-reviewer.md
    agents/qrspi-security-reviewer.md
    agents/qrspi-silent-failure-hunter.md
    agents/qrspi-goal-traceability-reviewer.md
    agents/qrspi-test-coverage-reviewer.md
    agents/qrspi-type-design-analyzer.md
    agents/qrspi-code-simplifier.md
    agents/qrspi-implement-gate-reviewer.md
    agents/qrspi-integration-reviewer.md
    agents/qrspi-security-integration-reviewer.md
  )
}

@test "every #109-scope reviewer agent body specifies per-finding filename pattern" {
  for f in "${scope_files[@]}"; do
    [[ -f "$f" ]] || { echo "missing #109-scope agent file: $f"; return 1; }
    local body
    body=$(awk '/^---$/{n++; next} n>=2{print}' "$f")
    echo "$body" | grep -qE 'finding-F[0-9]+\.md|finding-F<[Nn][Nn]>' \
      || { echo "per-finding pattern missing in $f"; return 1; }
  done
}

@test "every #109-scope reviewer agent body specifies the clean sentinel pattern" {
  for f in "${scope_files[@]}"; do
    [[ -f "$f" ]] || { echo "missing #109-scope agent file: $f"; return 1; }
    local body
    body=$(awk '/^---$/{n++; next} n>=2{print}' "$f")
    echo "$body" | grep -qE '<reviewer_tag>\.clean\.md|\.clean\.md.*<reviewer_tag>|clean-round sentinel' \
      || { echo "clean-sentinel pattern missing in $f"; return 1; }
  done
}

@test "no #109-scope reviewer agent retains the legacy round-NN-{reviewer-tag}.md write" {
  for f in "${scope_files[@]}"; do
    [[ -f "$f" ]] || { echo "missing #109-scope agent file: $f"; return 1; }
    local body
    body=$(awk '/^---$/{n++; next} n>=2{print}' "$f")
    # Look for the literal legacy filename pattern as a Write target.
    ! echo "$body" | grep -qE 'Write[^.]*round-NN-(claude|codex|scope-(claude|codex))\.md' \
      || { echo "legacy single-file Write still present in $f"; return 1; }
  done
}

@test "deferred reviewer agent files remain on the legacy contract (per follow-up issue)" {
  # Deferred reviewers (18) — see spec §1 "Files NOT modified by #109". Migration
  # is tracked in the follow-up issue. When that lands, this test extends.
  for f in "${deferred_files[@]}"; do
    [[ -f "$f" ]] || continue   # tolerate missing optional reviewers in #110-only main
    local body
    body=$(awk '/^---$/{n++; next} n>=2{print}' "$f")
    # Deferred reviewers must NOT have been migrated to per-finding emission.
    # Acceptable: legacy round-NN-{tag}.md mention OR no Write directive at all
    # (some agent files have their disk-write semantics in the protocol skill only).
    if echo "$body" | grep -qE 'finding-F[0-9]+\.md'; then
      echo "deferred reviewer $f appears to use per-finding pattern — should be on legacy contract"
      return 1
    fi
  done
}
