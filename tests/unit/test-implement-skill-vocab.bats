#!/usr/bin/env bats
bats_require_minimum_version 1.5.0

# fix-int-w23-r01-t01 — implement/SKILL.md ↔ parallelize/SKILL.md (T4 reshape) contract pin
#
# T4 (Wave 3) reshaped skills/parallelize/SKILL.md so wave ordering is read
# from `### Wave N` sub-section headings under Branch Map and removed the
# standalone `## Execution Order` section. This pin asserts the consumer side
# (skills/implement/SKILL.md) tracks that reshape:
#
#   1. implement/SKILL.md MUST NOT reference "Execution Order narrative" or
#      "in the Execution Order" — these phrases describe a parallelization-level
#      section T4 removed. The phrase "Execution order" (lowercase o) remains
#      acceptable in OTHER domains (e.g. reviewer fan-out ordering at L488),
#      so the test pins only the two specific producer-contract phrases.
#
#   2. implement/SKILL.md MUST anchor its wave-dispatch prose to the new
#      `### Wave N` sub-section vocabulary so future drift fails loudly.
#
# Bash 3.2 portable (no mapfile, no declare -A, no ${var,,}, no coproc).

load '../helpers/skill-markdown'

setup_file() {
  require_repo_root
  SKILL_MD="$REPO_ROOT/skills/implement/SKILL.md"
  export SKILL_MD
}

# ---------------------------------------------------------------------------
# Pin 1: no stale parallelization-level "Execution Order" producer references
# ---------------------------------------------------------------------------
@test "[fix-int-w23-r01-t01] implement/SKILL.md does not reference a standalone parallelization-level \"Execution Order\" section or narrative" {
  # The producer (skills/parallelize/SKILL.md, post-T4) emits neither an
  # "Execution Order narrative" section nor any other field whose dispatch
  # consumer would phrase as "in the Execution Order". Either phrase in
  # implement/SKILL.md is a stale cross-skill contract reference.
  if grep -nE 'Execution Order narrative|in the Execution Order' "$SKILL_MD"; then
    printf 'FAIL: implement/SKILL.md still references the parallelization-level "Execution Order" producer contract removed by T4\n' >&2
    return 1
  fi
}

# ---------------------------------------------------------------------------
# Pin 2: wave-dispatch prose anchors to the new `### Wave N` sub-section vocab
# ---------------------------------------------------------------------------
@test "[fix-int-w23-r01-t01] implement/SKILL.md reads wave ordering from Branch Map \`### Wave N\` sub-sections" {
  # The consumer's wave-dispatch step must name the new producer anchor:
  # the literal substring "`### Wave N` sub-section" (backtick-fenced
  # heading shape followed by the word "sub-section"). This catches a
  # future re-edit that drops the new vocabulary.
  if ! grep -nE '`### Wave N` sub-section' "$SKILL_MD"; then
    printf 'FAIL: implement/SKILL.md does not anchor wave-dispatch prose to the `### Wave N` sub-section vocabulary introduced by T4\n' >&2
    return 1
  fi
}
