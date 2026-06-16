#!/usr/bin/env bats
#
# Plan-level acceptance tests for CD-3 (R8 prose-density rule in
# skills/_shared/prompt-design-rules.md).
#
# Maps to design.md § CD-3 Acceptance and plan.md Phase 1 Acceptance
# Criteria bullet 5 (prompt-design-rules.md carries R8 verbatim; the
# rule-violation finding-type gate row references the rule set generically).

setup_file() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")"/../../.. && pwd)"
  export REPO_ROOT
  export RULES="$REPO_ROOT/skills/_shared/prompt-design-rules.md"
}

@test "acceptance: skills/_shared/prompt-design-rules.md exists" {
  [ -f "$RULES" ]
}

@test "acceptance: R8 heading is present verbatim" {
  grep -qxF '### R8 — Prose density: short declarative sentences, full behavioral precision' "$RULES"
}

@test "acceptance: R8 tightening-pattern table header is present verbatim" {
  grep -qF '| Pattern in current prose | Tightened form | Why it works |' "$RULES"
}

@test "acceptance: R8 'What NOT to tighten' subheading is present" {
  grep -qiE '^#+ .*What NOT to tighten' "$RULES"
}

@test "acceptance: R8 reviewer-test sentence is present verbatim" {
  grep -qF 'Could this sentence be shorter without losing behavioral precision OR load-bearing rationale?' "$RULES"
}

@test "acceptance: rule-violation finding-type gate references the rule set generically (no hard rule range)" {
  # v0.7.4 audit item #3: replaced the brittle "R1-R8" hard-range pin
  # with rangeless framing — the gate row must reference the rule set
  # as a whole (e.g., "an R-rule defined in this file"), not pin a
  # specific count.
  row=$(grep -E -- '\| *\*\*rule-violation\*\* *\|' "$RULES" | head -n1)
  [ -n "$row" ]
  ! printf '%s\n' "$row" | grep -qE 'R[0-9]+-R[0-9]+'
  printf '%s\n' "$row" | grep -qiE 'R-rule|rule defined'
}

@test "acceptance: every cited R-ID (R1..R8) exists as a heading and none are duplicated" {
  for r in R1 R2 R3 R4 R5 R6 R7 R8; do
    cnt=$(grep -cE "^### ${r} " "$RULES" || true)
    [ "$cnt" = "1" ] || {
      echo "Expected exactly one '### ${r} ' heading in $RULES, found $cnt" >&2
      false
    }
  done
}
