#!/usr/bin/env bats
bats_require_minimum_version 1.5.0

# T30 (pin 2 of 5) — G11 + G14: Slice 5 ui-task-fields contract pin.
#
# Asserts T24's UI-field contract in skills/plan/SKILL.md:
#   - `ui: true` and `lift_source: <path>` are documented frontmatter fields.
#   - When both are present, the task body MUST contain a
#     `SPEC OVERRIDES SOURCE` section; Plan refuses to write the spec
#     otherwise with a named diagnostic.
#   - The Red Flags table lists the missing-SPEC-OVERRIDES-SOURCE-section
#     condition as a STOP entry.
#   - The Migration step rewrites `visual_fidelity_check.ui_producing: true`
#     to top-level `ui: true`.
#
# Asserts T27's dispatch contract in skills/implement/SKILL.md:
#   - `ui: true` triggers `qrspi-visual-fidelity-reviewer` dispatch as part
#     of the per-task reviewer set, with reviewer_tag `visual-fidelity-claude`.
#
# Uses skill-markdown.bash per task spec (helper-load is load-bearing).
#
# Bash 3.2 portable.

load '../helpers/skill-markdown'

setup_file() {
  require_repo_root
  PLAN_SKILL="$REPO_ROOT/skills/plan/SKILL.md"
  IMPLEMENT_SKILL="$REPO_ROOT/skills/implement/SKILL.md"
  export PLAN_SKILL IMPLEMENT_SKILL
}

# =============================================================================
# T24 UI-field contract (Plan skill)
# =============================================================================

@test "[T30-ui-fields] Plan SPEC OVERRIDES SOURCE authority section names the contract" {
  extract_and_grep "$PLAN_SKILL" H3 "SPEC OVERRIDES SOURCE authority" \
    "spec wins"
}

@test "[T30-ui-fields] Plan Refuse-to-Write contract names the UI+lift_source pair" {
  extract_and_grep "$PLAN_SKILL" H3 "Refuse-to-Write Contract" \
    "ui: true.*lift_source"
}

@test "[T30-ui-fields] Plan refuses ui+lift_source without SPEC OVERRIDES SOURCE body section" {
  extract_and_grep "$PLAN_SKILL" H3 "Refuse-to-Write Contract" \
    "SPEC OVERRIDES SOURCE body section"
}

@test "[T30-ui-fields] Plan Red Flags lists missing SPEC OVERRIDES SOURCE section as STOP entry" {
  extract_and_grep "$PLAN_SKILL" H2 "Red Flags — STOP" \
    "ui: true.*lift_source.*SPEC OVERRIDES SOURCE"
}

@test "[T30-ui-fields] Plan Migration step promotes visual_fidelity_check.ui_producing to top-level ui" {
  extract_and_grep "$PLAN_SKILL" H3 "Migration: \`visual_fidelity_check.ui_producing\` → top-level \`ui:\`" \
    "ui: true"
}

@test "[T30-ui-fields] Plan Migration step drops the nested ui_producing field" {
  # Canonical step 2: "Remove the `ui_producing` field from inside the
  # `visual_fidelity_check:` block."
  extract_and_grep "$PLAN_SKILL" H3 "Migration: \`visual_fidelity_check.ui_producing\` → top-level \`ui:\`" \
    "Remove the .ui_producing. field"
}

# =============================================================================
# T27 visual-fidelity reviewer dispatch contract (Implement skill)
# =============================================================================

@test "[T30-ui-fields] Implement dispatches qrspi-visual-fidelity-reviewer on ui:true" {
  extract_and_grep "$IMPLEMENT_SKILL" H2 "Dispatch parameters" \
    "qrspi-visual-fidelity-reviewer"
}

@test "[T30-ui-fields] Implement dispatch uses reviewer_tag visual-fidelity-claude" {
  extract_and_grep "$IMPLEMENT_SKILL" H2 "Dispatch parameters" \
    "visual-fidelity-claude"
}

@test "[T30-ui-fields] Implement dispatch parallel with per-task reviewers" {
  extract_and_grep "$IMPLEMENT_SKILL" H2 "Dispatch parameters" \
    "parallel"
}

@test "[T30-ui-fields] Implement activation condition is ui:true alone (no visual_fidelity_required)" {
  # Pin asserts the activation contract: ui:true is the sole signal on this
  # second activation path, distinct from the visual_fidelity_check gate.
  extract_and_grep "$IMPLEMENT_SKILL" H2 "Dispatch parameters" \
    "sole activation signal"
}
