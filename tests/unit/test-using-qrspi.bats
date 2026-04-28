#!/usr/bin/env bats
bats_require_minimum_version 1.5.0

# Contract tests for skills/using-qrspi/SKILL.md.
#
# task-33 (integration-round-01, Wave B): docs reconciliation across three
# upstream contracts:
#
#   1. R1 Codex-I1 (docs piece) — `current_step` enum.
#      task-24 made `hooks/lib/state.sh` enforce a 12-value allowlist:
#      9 file-backed steps (goals, questions, research, design, phasing,
#      structure, plan, implement, test) + 3 transition states
#      (parallelize, integrate, replan). using-qrspi:223 must document
#      exactly this 12-value enum and must NOT carry the stale "current
#      hook code may lag the contract" caveat — the hook layer now
#      accepts every value the docs declare.
#
#   2. R2 I-N2 (docs piece) — SessionStart hook contract.
#      task-30 locked the canonical contract in hooks/session-start: the
#      hook injects using-qrspi/SKILL.md content as additionalContext
#      and does NOT initialize state.json or reconcile against artifact
#      frontmatter. using-qrspi:204 must reflect that. State bootstrap is
#      skill-driven (Goals on first invocation; PostToolUse for
#      subsequent updates).
#
#   3. Audit-naming reconciliation — using-qrspi:161 currently lists
#      `audit-task-NN.jsonl`, which no hook actually writes.
#      `hooks/lib/audit.sh` writes `audit.jsonl`; `scripts/codex-companion-bg.sh`
#      writes `audit-codex-review.jsonl`. The artifact-tree section must
#      list the canonical names that match the runtime.

setup() {
  export PLUGIN_ROOT
  PLUGIN_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  export USING_QRSPI="$PLUGIN_ROOT/skills/using-qrspi/SKILL.md"
  export STATE_SH="$PLUGIN_ROOT/hooks/lib/state.sh"
  export SESSION_START="$PLUGIN_ROOT/hooks/session-start"
  export AUDIT_SH="$PLUGIN_ROOT/hooks/lib/audit.sh"
  export CODEX_BG="$PLUGIN_ROOT/scripts/codex-companion-bg.sh"
}

# extract_h2_section <file> <h2-heading>
# Print the section starting at the given exact H2 heading up to but not
# including the next `^## ` heading.
extract_h2_section() {
  local file="$1"
  local heading="$2"
  awk -v h="$heading" '
    $0 == h { in_b = 1; print; next }
    in_b && /^## / { exit }
    in_b { print }
  ' "$file"
}

# extract_h3_section <file> <h3-heading>
extract_h3_section() {
  local file="$1"
  local heading="$2"
  awk -v h="$heading" '
    $0 == h { in_b = 1; print; next }
    in_b && /^(## |### )/ { exit }
    in_b { print }
  ' "$file"
}

# ──────────────────────────────────────────────────────────────
# 1. current_step enum (task-24 12-value allowlist)
# ──────────────────────────────────────────────────────────────

@test "using-qrspi documents every allowlist current_step value" {
  [ -f "$USING_QRSPI" ]
  local section
  section=$(extract_h3_section "$USING_QRSPI" "### \`state.json\` field semantics (for human and agent readers)")
  [ -n "$section" ]
  # All 12 allowlist values must be backtick-quoted in the field-semantics section.
  for v in goals questions research design phasing structure plan parallelize implement integrate test replan; do
    grep -qF "\`$v\`" <<<"$section" || {
      echo "missing current_step value '$v' in using-qrspi field-semantics section" >&2
      return 1
    }
  done
}

@test "using-qrspi current_step values are all in the state.sh allowlist" {
  # Cross-reference: every backtick-quoted single-word identifier in the
  # current_step row must be in the state.sh allowlist case statement.
  [ -f "$STATE_SH" ]
  # Extract the allowlist case-pattern line.
  local allowed
  allowed=$(awk '/_state_current_step_is_allowed/{found=1} found && /goals\|questions/{print; exit}' "$STATE_SH")
  [ -n "$allowed" ]
  # Each documented value must appear in the allowlist line.
  for v in goals questions research design phasing structure plan parallelize implement integrate test replan; do
    grep -qE "(^|[[:space:]]|\|)$v(\||\))" <<<"$allowed" || {
      echo "documented current_step value '$v' not in state.sh allowlist" >&2
      return 1
    }
  done
}

@test "using-qrspi does not carry the stale 'hook code may lag' caveat" {
  # Pre-task-24 the docs hedged that hook implementation lagged the
  # documented enum. After task-24 enforcement, the caveat is misleading.
  run grep -F "Current hook code may lag the contract" "$USING_QRSPI"
  [ "$status" -ne 0 ]
}

# ──────────────────────────────────────────────────────────────
# 2. SessionStart hook contract (task-30 canonical)
# ──────────────────────────────────────────────────────────────

@test "using-qrspi does not claim SessionStart initializes state.json" {
  # The pre-task-30 wording was: "SessionStart hook — initializes
  # state.json in the main project's artifact dir at session start by
  # reconciling against artifact frontmatter on disk." That is FALSE per
  # the canonical hook contract.
  run grep -F "initializes \`state.json\` in the main project's artifact dir" "$USING_QRSPI"
  [ "$status" -ne 0 ]
}

@test "using-qrspi does not claim SessionStart reconciles artifact frontmatter" {
  run grep -F "reconciling against artifact frontmatter" "$USING_QRSPI"
  [ "$status" -ne 0 ]
}

@test "using-qrspi documents the canonical SessionStart contract (read-only, skill-driven bootstrap)" {
  # Must mention that SessionStart injects using-qrspi content as
  # additionalContext.
  run grep -F "additionalContext" "$USING_QRSPI"
  [ "$status" -eq 0 ]
}

@test "using-qrspi attributes state bootstrap to Goals + PostToolUse, not SessionStart" {
  # The narrative around the SessionStart bullet must clearly state that
  # state bootstrap is skill-driven (Goals on first run; PostToolUse for
  # subsequent updates).
  local section
  section=$(extract_h2_section "$USING_QRSPI" "## Hook-Managed State (\`.qrspi/\`)")
  [ -n "$section" ]
  grep -qF "skill-driven" <<<"$section"
  grep -qF "Goals" <<<"$section"
  grep -qF "PostToolUse" <<<"$section"
}

@test "session-start hook actually does NOT source state.sh (parity with using-qrspi docs)" {
  # Lock parity: docs only stay correct as long as the hook stays
  # read-only w.r.t. state. If anyone re-adds state sourcing to the
  # hook, this test fails and forces a doc update too.
  [ -f "$SESSION_START" ]
  run grep -E '^[[:space:]]*(source|\.)[[:space:]]+.*state\.sh' "$SESSION_START"
  [ "$status" -ne 0 ]
}

# ──────────────────────────────────────────────────────────────
# 3. Audit-jsonl filename reconciliation
# ──────────────────────────────────────────────────────────────

@test "using-qrspi artifact tree lists audit.jsonl (canonical hook audit)" {
  # hooks/lib/audit.sh writes <artifact_dir>/.qrspi/audit.jsonl.
  [ -f "$AUDIT_SH" ]
  grep -qF '/.qrspi/audit.jsonl' "$AUDIT_SH"
  # using-qrspi must list audit.jsonl in the artifact tree.
  run grep -F "audit.jsonl" "$USING_QRSPI"
  [ "$status" -eq 0 ]
}

@test "using-qrspi artifact tree lists audit-codex-review.jsonl (canonical codex audit)" {
  # scripts/codex-companion-bg.sh writes audit-codex-review.jsonl.
  [ -f "$CODEX_BG" ]
  grep -qF 'audit-codex-review.jsonl' "$CODEX_BG"
  run grep -F "audit-codex-review.jsonl" "$USING_QRSPI"
  [ "$status" -eq 0 ]
}

@test "using-qrspi does not list the non-existent audit-task-NN.jsonl filename" {
  # Pre-task-33 the artifact tree listed audit-task-NN.jsonl, but no
  # hook writes that filename. Drift across docs/audit.sh/codex-bg.sh
  # was reconciled to the two canonical names.
  run grep -E "audit-task-(\*|N+)\.jsonl" "$USING_QRSPI"
  [ "$status" -ne 0 ]
}
