#!/usr/bin/env bats
# Tests for Task 25 round-01 review findings (fix pass).
# Findings addressed:
#   security-claude F02 + silent-failure-claude F01: /tmp/ reference in prompt-design-rules.md
#   silent-failure-claude F02: no fail-loud guard in writer/reviewer addition Read
#   silent-failure-claude F03: writer addition lacks sub-block detection guidance
#   code-quality-claude F01: goal IDs (G31, G1, G30) in runtime strings

setup_file() {
  REPO_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../.." && pwd -P)"
  export REPO_ROOT
  RULES="$REPO_ROOT/skills/_shared/prompt-design-rules.md"
  WRITER="$REPO_ROOT/skills/_shared/prompt-prose-writer-addition.md"
  REVIEWER="$REPO_ROOT/skills/_shared/prompt-prose-reviewer-addition.md"
  export RULES WRITER REVIEWER
}

# ── security-claude F02 + silent-failure-claude F01 ──────────────────────────

@test "prompt-design-rules.md contains no /tmp/ path references" {
  run grep -F '/tmp/' "$RULES"
  [ "$status" -ne 0 ]
}

# ── silent-failure-claude F02 — fail-loud guard on Read ──────────────────────

@test "prompt-prose-writer-addition.md has fail-loud guard when Read fails" {
  # Must instruct the agent to stop and surface an error if the Read fails —
  # not proceed silently without the rules loaded.
  run grep -iE 'if.*(read|the read) fails' "$WRITER"
  [ "$status" -eq 0 ]
}

@test "prompt-prose-reviewer-addition.md has fail-loud guard when Read fails" {
  run grep -iE 'if.*(read|the read) fails' "$REVIEWER"
  [ "$status" -eq 0 ]
}

@test "prompt-prose-writer-addition.md stop-guard says NOT to proceed when Read fails" {
  # Must explicitly say do NOT proceed / stop.
  run grep -iE '(do not|do NOT|stop).*(proceed|authoring|drafting|continue)|NOT.*proceed' "$WRITER"
  [ "$status" -eq 0 ]
}

@test "prompt-prose-reviewer-addition.md stop-guard says NOT to emit findings when Read fails" {
  run grep -iE '(do not|do NOT|stop).*(emit|findings|proceed|continue)|NOT.*emit' "$REVIEWER"
  [ "$status" -eq 0 ]
}

# ── silent-failure-claude F03 — sub-block guidance in writer addition ─────────

@test "prompt-prose-writer-addition.md mentions sub-block detection" {
  # Reviewer addition explicitly covers sub-blocks; writer addition must match.
  run grep -iE 'sub-block|sub block' "$WRITER"
  [ "$status" -eq 0 ]
}

# ── code-quality-claude F01 — no goal IDs in runtime strings ─────────────────

@test "prompt-design-rules.md Last-applied line has no internal goal ID" {
  # The Last applied: header must not reference G31 or similar IDs.
  run grep -E 'Last applied:.*\bG[0-9]+\b' "$RULES"
  [ "$status" -ne 0 ]
}

@test "prompt-design-rules.md cross-cutting section has no inline (Sources: ...) parentheticals" {
  # The Sources: G1 and Sources: G30 parentheticals must be removed (inside baseball, R1-cuttable).
  run grep -E '\(Sources:' "$RULES"
  [ "$status" -ne 0 ]
}
