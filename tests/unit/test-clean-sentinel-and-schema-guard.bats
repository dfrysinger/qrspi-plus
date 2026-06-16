#!/usr/bin/env bats

@test "reviewer-protocol defines <reviewer_tag>.clean.md sentinel format" {
  # The clean-round sentinel format is defined in the unified emission
  # contract (emission.md). SKILL.md may also reference it; either file
  # carrying a recognizable definition counts.
  local hits=0
  if grep -qE '<reviewer_tag>\.clean\.md' skills/reviewer-protocol/emission.md \
     && grep -qE 'frontmatter-only|reviewer:.*round:.*findings: 0|findings: 0' \
          skills/reviewer-protocol/emission.md; then
    hits=$((hits+1))
  fi
  if grep -qE '<reviewer_tag>\.clean\.md' skills/reviewer-protocol/SKILL.md \
     && awk '
          /^## Per-Finding Disk-Write Contract/ { in_block=1 }
          in_block && /^## / && !/Per-Finding Disk-Write Contract/ { exit }
          in_block { print }
        ' skills/reviewer-protocol/SKILL.md \
       | grep -qE 'frontmatter-only|reviewer:.*round:.*findings: 0|findings: 0'; then
    hits=$((hits+1))
  fi
  [ "$hits" -ge 1 ]
}

@test "schema-violation guard fails loud on expected tag with zero finding/clean files" {
  awk '
    /\*\*Apply-fix protocol\.\*\*/ { in_block=1 }
    in_block && /\*\*Diff handling between rounds/ { exit }
    in_block { print }
  ' skills/using-qrspi/SKILL.md \
    | grep -qiE 'expected tag.*no output|expected tag.*zero|fail loud.*§3 menu|§3 menu.*expected tag'
}

@test "Expected-Reviewer Matrix exists in reviewer-protocol" {
  grep -qE '^## Expected-Reviewer Matrix' skills/reviewer-protocol/SKILL.md
}

@test "Expected-Reviewer Matrix enumerates the four #109 role-distinct tags" {
  # The Routing Table was folded into the Expected-Reviewer Matrix
  # post-#125 cutover (see test "reviewer-protocol skill carries no
  # Reviewer-Tag Routing Table" in test-no-legacy-disk-write-references).
  # All four role-distinct tags must remain enumerated under the Matrix.
  awk '
    /^## Expected-Reviewer Matrix/ { in_block=1 }
    in_block && /^## / && !/Expected-Reviewer Matrix/ { exit }
    in_block { print }
  ' skills/reviewer-protocol/SKILL.md > /tmp/routing.txt
  grep -qF 'quality-claude' /tmp/routing.txt
  grep -qF 'scope-claude' /tmp/routing.txt
  grep -qF 'quality-codex' /tmp/routing.txt
  grep -qF 'scope-codex' /tmp/routing.txt
}

@test "fixture-backed schema-guard: missing-tag fixture would surface §3 menu" {
  # Spec §5 test #10: "Negative fixtures assert the failure path." The
  # missing-tag fixture has zero quality-codex.* and zero scope-codex.* files.
  # Per the Expected-Reviewer Matrix for the Goals/Design step under
  # second_reviewer:true, both tags are required. A simulated schema-guard
  # invocation against this fixture must detect at least one missing expected
  # tag (the actual guard is implemented in skills/using-qrspi/SKILL.md and
  # validated in test #4 — this fixture-backed assertion verifies the negative
  # fixture exhibits the file shape that triggers the guard).
  local D=tests/fixtures/issue-109/round-missing-tag/round-05
  local found_missing=0
  for tag in quality-claude scope-claude quality-codex scope-codex; do
    if ! ls "$D/${tag}".finding-*.md "$D/${tag}.clean.md" 2>/dev/null | grep -q .; then
      echo "missing expected tag: $tag (would surface §3 menu)"
      found_missing=1
    fi
  done
  [[ "$found_missing" -eq 1 ]] || { echo "negative fixture did not exhibit a missing tag"; return 1; }
}
