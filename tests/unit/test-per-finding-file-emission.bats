#!/usr/bin/env bats

# All 32 reviewer agent files: per-finding emission required.

setup() {
  all_reviewer_files=(
    # 14 #109-migrated reviewers
    agents/qrspi-goals-reviewer.md
    agents/qrspi-questions-reviewer.md
    agents/qrspi-research-reviewer.md
    agents/qrspi-design-reviewer.md
    agents/qrspi-phasing-reviewer.md
    agents/qrspi-structure-reviewer.md
    agents/qrspi-parallelize-reviewer.md
    agents/qrspi-replan-reviewer.md
    agents/qrspi-goals-scope-reviewer.md
    agents/qrspi-design-scope-reviewer.md
    agents/qrspi-phasing-scope-reviewer.md
    agents/qrspi-structure-scope-reviewer.md
    agents/qrspi-parallelize-scope-reviewer.md
    agents/qrspi-replan-scope-reviewer.md
    # 18 #125-migrated reviewers
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

@test "every reviewer agent body references per-finding emission (inline or via protocol deferral)" {
  # The per-finding filename pattern lives in skills/reviewer-protocol/first-party-emission.md
  # (post-G6 split — emission-contract prose moved out of SKILL.md core).
  # Each reviewer must EITHER reference the contract inline (finding-F<NN>.md pattern)
  # OR defer to the protocol skill ("disk-write contract from the reviewer-protocol skill").
  local protocol="skills/reviewer-protocol/SKILL.md"
  local first_party="skills/reviewer-protocol/first-party-emission.md"
  [[ -f "$protocol" ]] || { echo "missing protocol skill: $protocol"; return 1; }
  [[ -f "$first_party" ]] || { echo "missing first-party emission contract: $first_party"; return 1; }
  grep -qE 'finding-F[0-9]+\.md|finding-F<[Nn][Nn]>' "$first_party" \
    || { echo "per-finding pattern missing in $first_party"; return 1; }

  for f in "${all_reviewer_files[@]}"; do
    [[ -f "$f" ]] || { echo "missing reviewer agent file: $f"; return 1; }
    local frontmatter body
    frontmatter=$(awk '/^---$/{n++; if(n==2)exit; next} n==1{print}' "$f")
    body=$(awk '/^---$/{n++; next} n>=2{print}' "$f")
    echo "$frontmatter" | grep -qE '^skills:.*reviewer-protocol' \
      || { echo "reviewer-protocol skill not loaded via frontmatter in $f"; return 1; }
    if echo "$body" | grep -qE 'finding-F[0-9]+\.md|finding-F<[Nn][Nn]>'; then
      continue   # inline per-finding ref
    fi
    if echo "$body" | grep -qF 'disk-write contract from the reviewer-protocol skill'; then
      continue   # protocol-deferral language
    fi
    if echo "$body" | grep -qE 'Per-Finding Disk-Write Contract|reviewer-protocol'; then
      continue   # other protocol cross-reference
    fi
    echo "$f has neither inline per-finding ref nor protocol-deferral language"
    return 1
  done
}

@test "every reviewer agent body references the clean sentinel (inline or via protocol deferral)" {
  # The clean-sentinel pattern lives in skills/reviewer-protocol/first-party-emission.md
  # (post-G6 split — emission-contract prose moved out of SKILL.md core).
  # Each reviewer must EITHER reference the sentinel inline OR defer to the protocol.
  local protocol="skills/reviewer-protocol/SKILL.md"
  local first_party="skills/reviewer-protocol/first-party-emission.md"
  [[ -f "$protocol" ]] || { echo "missing protocol skill: $protocol"; return 1; }
  [[ -f "$first_party" ]] || { echo "missing first-party emission contract: $first_party"; return 1; }
  grep -qE '<reviewer_tag>\.clean\.md|\.clean\.md.*<reviewer_tag>|clean-round sentinel|clean sentinel' "$first_party" \
    || { echo "clean-sentinel pattern missing in $first_party"; return 1; }

  for f in "${all_reviewer_files[@]}"; do
    [[ -f "$f" ]] || { echo "missing reviewer agent file: $f"; return 1; }
    local body
    body=$(awk '/^---$/{n++; next} n>=2{print}' "$f")
    if echo "$body" | grep -qE 'clean\.md|clean-round sentinel|clean sentinel'; then
      continue   # inline sentinel ref
    fi
    if echo "$body" | grep -qF 'disk-write contract from the reviewer-protocol skill'; then
      continue   # protocol-deferral language
    fi
    echo "$f has neither inline clean-sentinel ref nor protocol-deferral language"
    return 1
  done
}

@test "first-party-emission.md exists with required headings and Write-tool path rules" {
  local f="skills/reviewer-protocol/first-party-emission.md"
  [[ -f "$f" ]] || { echo "missing: $f"; return 1; }
  grep -qE '^## First-Party Emission Contract' "$f" || { echo "missing ## First-Party Emission Contract"; return 1; }
  grep -qE '^### Write-Tool Requirements' "$f" || { echo "missing ### Write-Tool Requirements"; return 1; }
  grep -qE '^### Path Rules' "$f" || { echo "missing ### Path Rules"; return 1; }
  grep -qF '<round_subdir>/<reviewer_tag>.finding-F<NN>.md' "$f" \
    || { echo "first-party finding path not pinned"; return 1; }
  grep -qF '<round_subdir>/<reviewer_tag>.clean.md' "$f" \
    || { echo "first-party clean sentinel path not pinned"; return 1; }
  grep -qF 'expected tag produced no output' "$f" \
    || { echo "first-party wrong-channel diagnostic not pinned"; return 1; }
  grep -qE 'Write tool' "$f" \
    || { echo "first-party Write-tool reference missing"; return 1; }
}

@test "third-party-emission.md exists with stdout-boundary contract and splitter requirements" {
  local f="skills/reviewer-protocol/third-party-emission.md"
  [[ -f "$f" ]] || { echo "missing: $f"; return 1; }
  grep -qE '^## Third-Party Emission Contract' "$f" || { echo "missing ## Third-Party Emission Contract"; return 1; }
  grep -qE '^### Stdout Boundary' "$f" || { echo "missing ### Stdout Boundary"; return 1; }
  grep -qE '^### Splitter Requirements' "$f" || { echo "missing ### Splitter Requirements"; return 1; }
  grep -qF '<<<FINDING-BOUNDARY>>>' "$f" \
    || { echo "third-party FINDING-BOUNDARY token not pinned"; return 1; }
  grep -qF 'NO_FINDINGS' "$f" \
    || { echo "third-party NO_FINDINGS sentinel not pinned"; return 1; }
  grep -qF 'third-party-finding-splitter.sh' "$f" \
    || { echo "third-party-finding-splitter.sh not named"; return 1; }
  grep -qF 'expected tag produced no output' "$f" \
    || { echo "third-party wrong-channel diagnostic not pinned"; return 1; }
  if grep -qiE '\boverride\b' "$f"; then
    echo "third-party-emission.md must not use the word 'override'"
    return 1
  fi
}

@test "reviewer-protocol SKILL.md is emission-agnostic (no Write-tool or stdout-emission contract prose)" {
  local f="skills/reviewer-protocol/SKILL.md"
  [[ -f "$f" ]] || { echo "missing: $f"; return 1; }
  if grep -qE '^## Per-Finding Disk-Write Contract' "$f"; then
    echo "SKILL.md still carries ## Per-Finding Disk-Write Contract section"
    return 1
  fi
  if grep -qE 'Write tool|use the Write tool|Use the Write tool' "$f"; then
    echo "SKILL.md still references the Write tool (emission prose)"
    return 1
  fi
  if grep -qE 'emit (findings )?(on|to) stdout|stdout (only|emission)|on stdout' "$f"; then
    echo "SKILL.md still references stdout emission"
    return 1
  fi
}

@test "reviewer-protocol SKILL.md carries no pre-rename script/file references" {
  local f="skills/reviewer-protocol/SKILL.md"
  if grep -qE 'run-codex-review|codex-emission-override|codex-finding-splitter' "$f"; then
    grep -nE 'run-codex-review|codex-emission-override|codex-finding-splitter' "$f"
    echo "SKILL.md still carries pre-rename references"
    return 1
  fi
}

@test "no reviewer agent retains the legacy round-NN-{reviewer-tag}.md write" {
  for f in "${all_reviewer_files[@]}"; do
    [[ -f "$f" ]] || { echo "missing reviewer agent file: $f"; return 1; }
    local body
    body=$(awk '/^---$/{n++; next} n>=2{print}' "$f")
    if echo "$body" | grep -qE 'Write[^.]*round-NN-([a-z0-9-]+-)?(claude|codex)\.md'; then
      echo "legacy single-file Write still present in $f"
      return 1
    fi
  done
}
