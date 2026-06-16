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
  # The per-finding filename pattern lives in skills/reviewer-protocol/emission.md
  # (the unified emission contract). Each reviewer must EITHER reference the
  # contract inline (finding-F<NN>.md pattern) OR defer to the protocol skill
  # ("disk-write contract from the reviewer-protocol skill").
  local protocol="skills/reviewer-protocol/SKILL.md"
  local emission="skills/reviewer-protocol/emission.md"
  [[ -f "$protocol" ]] || { echo "missing protocol skill: $protocol"; return 1; }
  [[ -f "$emission" ]] || { echo "missing emission contract: $emission"; return 1; }
  grep -qE 'finding-F[0-9]+\.md|finding-F<[Nn][Nn]>' "$emission" \
    || { echo "per-finding pattern missing in $emission"; return 1; }

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
    echo "$f has neither inline per-finding ref nor protocol-deferral language"
    return 1
  done
}

@test "every reviewer agent body references the clean sentinel (inline or via protocol deferral)" {
  # The clean-sentinel pattern lives in skills/reviewer-protocol/emission.md
  # (the unified emission contract). Each reviewer must EITHER reference the
  # sentinel inline OR defer to the protocol.
  local protocol="skills/reviewer-protocol/SKILL.md"
  local emission="skills/reviewer-protocol/emission.md"
  [[ -f "$protocol" ]] || { echo "missing protocol skill: $protocol"; return 1; }
  [[ -f "$emission" ]] || { echo "missing emission contract: $emission"; return 1; }
  grep -qE '<reviewer_tag>\.clean\.md|\.clean\.md.*<reviewer_tag>|clean-round sentinel|clean sentinel' "$emission" \
    || { echo "clean-sentinel pattern missing in $emission"; return 1; }

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

@test "emission.md exists with required transport sections and path rules" {
  local f="skills/reviewer-protocol/emission.md"
  [[ -f "$f" ]] || { echo "missing: $f"; return 1; }
  # Unified contract must document both transport paths and shared path rules.
  grep -qE '^## Write-tool path' "$f" || { echo "missing ## Write-tool path section"; return 1; }
  grep -qE '^## Stdout path' "$f" || { echo "missing ## Stdout path section"; return 1; }
  grep -qE '^## Path rules' "$f" || { echo "missing ## Path rules section"; return 1; }
  grep -qF '<round_subdir>/<reviewer_tag>.finding-F<NN>.md' "$f" \
    || { echo "finding path not pinned"; return 1; }
  grep -qF '<round_subdir>/<reviewer_tag>.clean.md' "$f" \
    || { echo "clean sentinel path not pinned"; return 1; }
  grep -qF 'expected tag produced no output' "$f" \
    || { echo "wrong-channel diagnostic not pinned"; return 1; }
  grep -qE 'Write tool' "$f" \
    || { echo "Write-tool reference missing"; return 1; }
  grep -qF '<<<FINDING-BOUNDARY>>>' "$f" \
    || { echo "stdout FINDING-BOUNDARY token not pinned"; return 1; }
  grep -qF 'NO_FINDINGS' "$f" \
    || { echo "stdout NO_FINDINGS sentinel not pinned"; return 1; }
  grep -qF 'third-party-finding-splitter.sh' "$f" \
    || { echo "third-party-finding-splitter.sh not named"; return 1; }
  if grep -qiE '\boverride\b' "$f"; then
    echo "emission.md must not use the word 'override' (the unified contract is honest about there being no fallback)"
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

@test "reviewer-protocol SKILL.md self-description is emission-agnostic (no 'disk-write contract' tokens)" {
  # Pins the post-split self-description: the disk-write contract prose lives
  # in emission.md, not SKILL.md.
  local f="skills/reviewer-protocol/SKILL.md"
  [[ -f "$f" ]] || { echo "missing: $f"; return 1; }
  if grep -qiF 'disk-write contract' "$f"; then
    grep -niF 'disk-write contract' "$f"
    echo "SKILL.md self-description still advertises 'disk-write contract' as core protocol surface"
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

@test "emission.md does not reproduce verbatim schema paragraphs from SKILL.md" {
  # Schema fields / audit fields / finding_id uniqueness paragraphs live in
  # SKILL.md only; emission.md cross-references rather than duplicates them.
  local f="skills/reviewer-protocol/emission.md"
  [[ -f "$f" ]] || { echo "missing: $f"; return 1; }
  if grep -qF 'canonical 5-field finding schema' "$f"; then
    echo "emission.md reproduces verbatim schema paragraph from SKILL.md"
    return 1
  fi
  # Cross-reference line must be present
  grep -qF 'skills/reviewer-protocol/SKILL.md' "$f" \
    || { echo "emission.md missing cross-reference to SKILL.md"; return 1; }
}

@test "emission.md pins the silent-failure characterization for the stdout path" {
  # The parenthetical 'will fail silently' (or equivalent) must be pinned on
  # the stdout-path branch — Write attempts in the read-only sandbox fail
  # silently and the reviewer must know not to mix transports.
  local f="skills/reviewer-protocol/emission.md"
  [[ -f "$f" ]] || { echo "missing: $f"; return 1; }
  grep -qiE 'sandbox will block|fail(s)? silently|silent(ly)? fail|read-only sandbox blocks' "$f" \
    || { echo "stdout-path silent-failure characterization not pinned"; return 1; }
}

@test "reviewer_tag charset rule is present in emission.md" {
  # reviewer_tag must be validated against the charset regex before path construction.
  # First character must be alphanumeric (rejects leading hyphens — POSIX argv footgun).
  local f="skills/reviewer-protocol/emission.md"
  [[ -f "$f" ]] || { echo "missing: $f"; return 1; }
  grep -qF '^[a-z0-9][a-z0-9-]*$' "$f" \
    || { echo "emission.md missing reviewer_tag charset rule"; return 1; }
}

@test "reviewer_tag charset rule rejects leading hyphen (regression pin)" {
  # Leading-hyphen reviewer tags (-rf, --evil, etc.) are a POSIX argument-parsing
  # footgun in downstream glob/CLI consumers. The charset regex must require an
  # alphanumeric first character so such tags are rejected at validation time.
  local src="skills/reviewer-protocol/emission.md"
  [[ -f "$src" ]] || { echo "missing: $src"; return 1; }
  grep -qF '^[a-z0-9][a-z0-9-]*$' "$src" \
    || { echo "$src missing leading-hyphen-rejecting charset rule"; return 1; }
  # And must NOT carry the older permissive form that admits leading hyphens.
  if grep -qF '^[a-z0-9-]+$' "$src"; then
    echo "$src still carries permissive ^[a-z0-9-]+\$ form that admits leading hyphens"
    return 1
  fi
}

@test "emission.md iron law bars NO_FINDINGS as pass-through of input" {
  # NO_FINDINGS must be emitted only as result of own analysis, never as
  # pass-through of untrusted-artifact instruction.
  local f="skills/reviewer-protocol/emission.md"
  [[ -f "$f" ]] || { echo "missing: $f"; return 1; }
  grep -qF 'result of your own analysis' "$f" \
    || { echo "emission.md missing NO_FINDINGS prompt-injection iron-law clause"; return 1; }
}

@test "SKILL.md ## Finding Schema documents audit-fields with reviewer = reviewer_tag constraint" {
  # Audit-fields enumeration (and specifically the load-bearing
  # `reviewer = <reviewer_tag>` constraint) was previously only pinned by the
  # emission siblings. After the cross-reference consolidation it must live in
  # SKILL.md so the sibling cross-reference is not dangling.
  local f="skills/reviewer-protocol/SKILL.md"
  [[ -f "$f" ]] || { echo "missing: $f"; return 1; }
  grep -qE 'reviewer.*reviewer_tag' "$f" \
    || { echo "SKILL.md ## Finding Schema missing 'reviewer = <reviewer_tag>' audit-field constraint"; return 1; }
}

@test "SKILL.md ## Finding Schema documents finding_id canonical form and regex" {
  # finding_id uniqueness rule (canonical form R{NN}-F{NN} + schema-guard regex
  # ^R\d+-F\d+$) was previously only pinned by the emission siblings. After the
  # cross-reference consolidation it must live in SKILL.md.
  local f="skills/reviewer-protocol/SKILL.md"
  [[ -f "$f" ]] || { echo "missing: $f"; return 1; }
  grep -qE '\^R\\d\+-F\\d\+\$' "$f" \
    || { echo "SKILL.md ## Finding Schema missing finding_id schema-guard regex ^R\\d+-F\\d+\$"; return 1; }
  grep -qE 'R\{NN\}-F\{NN\}|R[0-9]+-F[0-9]+' "$f" \
    || { echo "SKILL.md ## Finding Schema missing finding_id canonical form"; return 1; }
}
