#!/usr/bin/env bats

REPO_ROOT="${BATS_TEST_DIRNAME}/../.."
IMPLEMENT_SKILL="${REPO_ROOT}/skills/implement/SKILL.md"
VFR_AGENT="${REPO_ROOT}/agents/qrspi-visual-fidelity-reviewer.md"
PLAN_SKILL="${REPO_ROOT}/skills/plan/SKILL.md"
USING_QRSPI="${REPO_ROOT}/skills/using-qrspi/SKILL.md"

assert_file_contains() {
  local file="$1"
  local needle="$2"

  if ! grep -Fq -- "$needle" "$file"; then
    echo "Expected ${file} to contain: ${needle}" >&2
    return 1
  fi
}

assert_file_matches() {
  local file="$1"
  local pattern="$2"
  local description="$3"

  if ! grep -Eiq -- "$pattern" "$file"; then
    echo "Expected ${file} to document: ${description}" >&2
    echo "Pattern: ${pattern}" >&2
    return 1
  fi
}

assert_file_not_contains() {
  local file="$1"
  local needle="$2"

  if grep -Fq -- "$needle" "$file"; then
    echo "Expected ${file} not to contain obsolete contract token: ${needle}" >&2
    return 1
  fi
}

@test "visual fidelity acceptance: dispatch contract reaches reviewer output surface" {
  assert_file_contains "$USING_QRSPI" "visual_fidelity_required: false"
  assert_file_contains "$IMPLEMENT_SKILL" "visual_fidelity_required"
  assert_file_contains "$IMPLEMENT_SKILL" "qrspi-visual-fidelity-reviewer"
  assert_file_contains "$IMPLEMENT_SKILL" "wireframe_paths"
  assert_file_contains "$IMPLEMENT_SKILL" "visual-fidelity-claude.skipped.md"
  assert_file_contains "$IMPLEMENT_SKILL" "visual-fidelity-claude.path-filtered.md"
  assert_file_contains "$IMPLEMENT_SKILL" "visual-fidelity-claude.bypass-attempt"

  assert_file_contains "$VFR_AGENT" "tools: Read, Write"
  assert_file_contains "$VFR_AGENT" "skills: [reviewer-protocol]"
  assert_file_contains "$VFR_AGENT" "wireframe_paths"
  assert_file_contains "$VFR_AGENT" "multimodal Read"
  assert_file_contains "$VFR_AGENT" "clean sentinel"
  assert_file_contains "$VFR_AGENT" "finding"
}

@test "visual fidelity acceptance: contract is wireframe-only" {
  assert_file_contains "$IMPLEMENT_SKILL" "wireframe-reference fidelity only"
  assert_file_contains "$VFR_AGENT" "wireframe-reference fidelity review only"
  assert_file_not_contains "$IMPLEMENT_SKILL" "screenshot_paths"
  assert_file_not_contains "$IMPLEMENT_SKILL" "empty_screenshot_paths"
  assert_file_not_contains "$VFR_AGENT" "screenshot_paths"
  assert_file_not_contains "$VFR_AGENT" "empty_screenshot_paths"
}

@test "integration regression: plan hard-gate requires wireframe refs for UI-producing tasks" {
  assert_file_contains "$PLAN_SKILL" "visual_fidelity_check.wireframe_refs"
  assert_file_contains "$PLAN_SKILL" "visual_fidelity_check.ui_producing"
  assert_file_contains "$PLAN_SKILL" 'non-empty `visual_fidelity_check.wireframe_refs` list'
  assert_file_contains "$PLAN_SKILL" "HARD parse error"
  assert_file_not_contains "$PLAN_SKILL" "screenshot_refs"
}

@test "integration regression: phase backfill scans phase-bearing artifacts" {
  assert_file_contains "$IMPLEMENT_SKILL" ".smoke-probe-NN"
  assert_file_contains "$IMPLEMENT_SKILL" "reviews/integration/round-NN-commit.txt"
  assert_file_contains "$IMPLEMENT_SKILL" "phase-bearing artifacts"
  assert_file_contains "$IMPLEMENT_SKILL" 'If no phase-bearing artifacts exist in any scanned source, choose `1`.'
  assert_file_contains "$IMPLEMENT_SKILL" "malformed"
  assert_file_contains "$IMPLEMENT_SKILL" "ambiguous"
  assert_file_contains "$IMPLEMENT_SKILL" "sources conflict"
}

@test "integration regression: phase backfill fails loud on unsafe state" {
  assert_file_contains "$IMPLEMENT_SKILL" 'Write `phase: NN` back to `config.md`'
  assert_file_contains "$IMPLEMENT_SKILL" 're-read `config.md`'
  assert_file_contains "$IMPLEMENT_SKILL" "could not backfill missing phase field to config.md"
  assert_file_contains "$IMPLEMENT_SKILL" "Field present but non-integer or < 1"
  assert_file_contains "$IMPLEMENT_SKILL" 'stale `reviews/tasks/.smoke-probe-NN`'
}
