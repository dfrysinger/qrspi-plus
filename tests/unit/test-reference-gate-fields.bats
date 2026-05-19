#!/usr/bin/env bats
bats_require_minimum_version 1.5.0

# T30 (pin 1 of 5) — G10: Slice 5 reference-gate-fields contract pin.
#
# Asserts T24's paired-field contract in skills/plan/SKILL.md:
#   - `reference_gate: true` requires a paired `reference_artifact: <path>`
#   - Plan's Refuse-to-Write contract surfaces a named diagnostic on either
#     unpaired direction.
#   - A pre-Slice-5 task spec (no reference_gate, no reference_artifact, no
#     ui, no lift_source) is processed without diagnostic / pause / dispatch.
#   - The Red Flags table lists the paired-field violation as a STOP entry.
#
# And asserts T27's path-validation contract in skills/implement/SKILL.md:
#   - The reference-gate pause validates the `reference_artifact:` resolved
#     absolute path against the artifact-directory tree (or sibling-allowed
#     entries) BEFORE any render or Read; a path-traversal target
#     (e.g. /etc/shadow, ../../etc) is rejected with the named
#     `reference-gate-path-validation` diagnostic.
#   - Each declared `sibling_allowed_paths:` entry MUST itself resolve to
#     within the artifact-directory tree OR the worktree root; an out-of-tree
#     entry (e.g. /etc) is rejected with the named
#     `reference-gate-sibling-path-validation` diagnostic BEFORE the
#     `reference_artifact:` resolution is attempted.
#
# Image-artifact user-visible attachment (per T27 Step 2) is asserted by
# section-anchor extraction of the Step-2 prose so the contract is observably
# pinned without requiring a live SendUserFile harness in unit scope.
#
# Bash 3.2 portable: no mapfile, no declare -A, no ${var,,}, no coproc,
# no wait -n.

load '../helpers/skill-markdown'

setup_file() {
  require_repo_root
  PLAN_SKILL="$REPO_ROOT/skills/plan/SKILL.md"
  IMPLEMENT_SKILL="$REPO_ROOT/skills/implement/SKILL.md"
  export PLAN_SKILL IMPLEMENT_SKILL
}

# =============================================================================
# T24 paired-field contract (Plan skill)
# =============================================================================

@test "[T30-rg-fields] Plan Refuse-to-Write contract names the reference-gate pair" {
  extract_and_grep "$PLAN_SKILL" H3 "Refuse-to-Write Contract" \
    "reference_gate: true"
}

@test "[T30-rg-fields] Plan refuses reference_gate without reference_artifact (named diagnostic)" {
  extract_and_grep "$PLAN_SKILL" H3 "Refuse-to-Write Contract" \
    "without reference_artifact"
}

@test "[T30-rg-fields] Plan refuses reference_artifact without reference_gate (named diagnostic)" {
  extract_and_grep "$PLAN_SKILL" H3 "Refuse-to-Write Contract" \
    "reference_artifact without reference_gate"
}

@test "[T30-rg-fields] Plan refuse-to-write diagnostic names the offending task number" {
  extract_and_grep "$PLAN_SKILL" H3 "Refuse-to-Write Contract" \
    "task NN"
}

@test "[T30-rg-fields] Plan Red Flags lists paired-field violation as STOP entry" {
  extract_and_grep "$PLAN_SKILL" H2 "Red Flags — STOP" \
    "reference_gate: true.*without.*reference_artifact"
}

# =============================================================================
# Safe-default contract (pre-Slice-5 task spec — no fields, no fallout)
# =============================================================================

@test "[T30-rg-fields] Plan declares pre-Slice-5 task specs proceed without paired-field diagnostic" {
  # The safe-default contract is documented inside the Refuse-to-Write
  # section: a task spec with none of the four Slice-5 fields is processed
  # identically to a pre-Slice-5 spec — no paired-field diagnostic, no
  # reference-gate pause, no visual-fidelity reviewer dispatch.
  extract_and_grep "$PLAN_SKILL" H3 "Refuse-to-Write Contract" \
    "pre-Slice-5"
}

# =============================================================================
# T27 path-validation contract (Implement skill) — fixture-free section pins
# =============================================================================

@test "[T30-rg-fields] Implement reference-gate pause validates path BEFORE any render or Read" {
  extract_and_grep "$IMPLEMENT_SKILL" H3 "Reference-Gate Human Pause (per-task DONE handling)" \
    "before any render or Read"
}

@test "[T30-rg-fields] Implement names path-validation diagnostic (reference-gate-path-validation)" {
  extract_and_grep "$IMPLEMENT_SKILL" H3 "Reference-Gate Human Pause (per-task DONE handling)" \
    "reference-gate-path-validation"
}

@test "[T30-rg-fields] Implement path-validation rejects path-traversal escape attempts" {
  # The Step-1 prose enumerates path-traversal sub-cases (../, /etc/shadow,
  # ~/.ssh/id_rsa, symlink escape). At least one must be named so the pin
  # observably catches a regression that drops the traversal carve-out.
  extract_and_grep "$IMPLEMENT_SKILL" H3 "Reference-Gate Human Pause (per-task DONE handling)" \
    "/etc/shadow"
}

@test "[T30-rg-fields] Implement validates each sibling_allowed_paths entry first" {
  extract_and_grep "$IMPLEMENT_SKILL" H3 "Reference-Gate Human Pause (per-task DONE handling)" \
    "sibling_allowed_paths"
}

@test "[T30-rg-fields] Implement names sibling-allowed-path-validation diagnostic for out-of-tree entries" {
  extract_and_grep "$IMPLEMENT_SKILL" H3 "Reference-Gate Human Pause (per-task DONE handling)" \
    "reference-gate-sibling-path-validation"
}

@test "[T30-rg-fields] Implement rejects out-of-tree sibling_allowed_paths entries (named example)" {
  # Step-1 enumerates /etc, /var, ~/.ssh as canonical out-of-tree examples.
  # Pin asserts at least one canonical example survives.
  extract_and_grep "$IMPLEMENT_SKILL" H3 "Reference-Gate Human Pause (per-task DONE handling)" \
    "(/etc|/var|~/\\.ssh)"
}

# =============================================================================
# Image-artifact user-visible attachment (per T27 Step 2)
# =============================================================================

@test "[T30-rg-fields] Implement Step 2 renders image artifacts via SendUserFile (not path-only)" {
  extract_and_grep "$IMPLEMENT_SKILL" H3 "Reference-Gate Human Pause (per-task DONE handling)" \
    "SendUserFile"
}

@test "[T30-rg-fields] Implement Step 2 enumerates image extensions for SendUserFile path" {
  # Canonical image extension list per T27 (.png, .jpg, .jpeg, .gif, .webp).
  extract_and_grep "$IMPLEMENT_SKILL" H3 "Reference-Gate Human Pause (per-task DONE handling)" \
    "\\.png"
}

@test "[T30-rg-fields] Implement Step 2 enumerates PDF extension for SendUserFile path" {
  extract_and_grep "$IMPLEMENT_SKILL" H3 "Reference-Gate Human Pause (per-task DONE handling)" \
    "\\.pdf"
}

@test "[T30-rg-fields] Implement Step 2 surfaces text artifacts via inline Read" {
  extract_and_grep "$IMPLEMENT_SKILL" H3 "Reference-Gate Human Pause (per-task DONE handling)" \
    "inline Read"
}
