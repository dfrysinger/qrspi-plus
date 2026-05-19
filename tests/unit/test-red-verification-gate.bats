#!/usr/bin/env bats
#
# T13 Slice-2 pin: RED-verification gate end-to-end behavior.
#
# Asserts both layers of the gate contract:
#   (A) Orchestrator-side documentation in skills/implement/SKILL.md §
#       Pre-Implementer Test-Writer Dispatch + RED-Verification Gate names all
#       five classification outcomes — assertion-failure (proceed, includes
#       mixed suites), infrastructure-failure (pause), vacuous-RED (pause),
#       adapter-classification-failure (pause), and test-writer dispatch-
#       failure (pause).
#   (B) Each of the four T10 adapters classifies fixture runner outputs into
#       the expected token (or exits 1 for unrecognized output), exercising
#       the pause-case (adapter-exit-1) path that T11 declares at the
#       orchestrator level — observable here as adapter exit 1 with a
#       distinguishing stderr diagnostic distinct from infrastructure-failure
#       (no implementer dispatch occurs because the gate paused).

load '../helpers/skill-markdown'

setup() {
  require_repo_root
  SKILL_FILE="$REPO_ROOT/skills/implement/SKILL.md"
  ADAPTER_DIR="$REPO_ROOT/scripts/red-verify"
  FIXTURE_DIR="$(mktemp -d)"
  export SKILL_FILE ADAPTER_DIR FIXTURE_DIR
}

teardown() {
  rm -rf "$FIXTURE_DIR"
}

# Helper: write stdout/stderr fixtures and invoke an adapter, capturing
# classification token + adapter exit code.
_run_adapter() {
  local adapter="$1"
  local runner_exit="$2"
  local stdout_content="$3"
  local stderr_content="$4"
  local so="$FIXTURE_DIR/stdout.txt"
  local se="$FIXTURE_DIR/stderr.txt"
  printf '%s' "$stdout_content" > "$so"
  printf '%s' "$stderr_content" > "$se"
  bash "$ADAPTER_DIR/$adapter" --runner-exit "$runner_exit" --stdout-file "$so" --stderr-file "$se"
}

# =============================================================================
# (A) Orchestrator documentation pins — five named pause/proceed outcomes
# =============================================================================

@test "implement skill documents the RED-verification gate H3 section" {
  out="$(extract_section "$SKILL_FILE" H3 "Pre-Implementer Test-Writer Dispatch + RED-Verification Gate")"
  [ -n "$out" ]
}

@test "gate doc: assertion-failure → Proceed (includes mixed suites)" {
  run assert_section_contains "$SKILL_FILE" H3 \
    "Pre-Implementer Test-Writer Dispatch + RED-Verification Gate" \
    "assertion-failure.*[Pp]roceed|mixed"
  [ "$status" -eq 0 ]
}

@test "gate doc: infrastructure-failure → Pause with named diagnostic" {
  run assert_section_contains "$SKILL_FILE" H3 \
    "Pre-Implementer Test-Writer Dispatch + RED-Verification Gate" \
    "infrastructure-failure.*[Pp]ause"
  [ "$status" -eq 0 ]
}

@test "gate doc: vacuous-RED → Pause with named diagnostic" {
  run assert_section_contains "$SKILL_FILE" H3 \
    "Pre-Implementer Test-Writer Dispatch + RED-Verification Gate" \
    "vacuous-RED"
  [ "$status" -eq 0 ]
}

@test "gate doc: adapter-classification-failure → Pause (distinct from infrastructure-failure)" {
  run assert_section_contains "$SKILL_FILE" H3 \
    "Pre-Implementer Test-Writer Dispatch + RED-Verification Gate" \
    "adapter-classification-failure"
  [ "$status" -eq 0 ]
}

@test "gate doc: test-writer dispatch failure pauses the gate" {
  run assert_section_contains "$SKILL_FILE" H3 \
    "Pre-Implementer Test-Writer Dispatch + RED-Verification Gate" \
    "test-writer dispatch.*fail|dispatch-failure"
  [ "$status" -eq 0 ]
}

@test "gate doc: lightweight tasks bypass the test-writer and RED gate" {
  run assert_section_contains "$SKILL_FILE" H3 \
    "Pre-Implementer Test-Writer Dispatch + RED-Verification Gate" \
    "lightweight.*(bypass|skip)"
  [ "$status" -eq 0 ]
}

# =============================================================================
# (B) Adapter behavioral pins — bats adapter
# =============================================================================

@test "bats-adapter: pass-case all-fail → assertion-failure" {
  out="$(_run_adapter bats-adapter.sh 1 "1..2
ok 1 alpha
not ok 2 beta
" "")"
  [ "$?" -eq 0 ]
  [ "$out" = "assertion-failure" ]
}

@test "bats-adapter: pass-case mixed → assertion-failure" {
  out="$(_run_adapter bats-adapter.sh 1 "1..3
ok 1 alpha
not ok 2 beta
ok 3 gamma
" "")"
  [ "$?" -eq 0 ]
  [ "$out" = "assertion-failure" ]
}

@test "bats-adapter: vacuous-RED case → pass token (orchestrator interprets as vacuous-RED)" {
  out="$(_run_adapter bats-adapter.sh 0 "1..1
ok 1 vacuous
" "")"
  [ "$?" -eq 0 ]
  [ "$out" = "pass" ]
}

@test "bats-adapter: infrastructure-failure → infrastructure-failure token" {
  out="$(_run_adapter bats-adapter.sh 2 "" "bats: parse error in test file")"
  [ "$?" -eq 0 ]
  [ "$out" = "infrastructure-failure" ]
}

@test "bats-adapter: adapter-exit-1 unrecognized output → exit 1 with distinguishing stderr (NOT infrastructure-failure token)" {
  # Runner exited non-zero with ok lines but no "not ok" and no parse-error
  # marker — neither pass, nor assertion-failure, nor infrastructure (because
  # ok lines were emitted). The adapter's contract requires exit 1 here.
  run _run_adapter bats-adapter.sh 1 "1..1
ok 1 alpha
" ""
  [ "$status" -eq 1 ]
  # Distinguishing diagnostic: adapter prefix, distinct from the runtime
  # `infrastructure-failure: task=...` orchestrator diagnostic.
  [[ "$output" == *"bats-adapter:"* ]]
  [[ "$output" != "infrastructure-failure"* ]]
}

# =============================================================================
# Adapter behavioral pins — jest adapter
# =============================================================================

@test "jest-adapter: pass-case all-fail → assertion-failure" {
  out="$(_run_adapter jest-adapter.sh 1 " FAIL  src/foo.test.js
Tests:       2 failed, 0 passed, 2 total
" "")"
  [ "$?" -eq 0 ]
  [ "$out" = "assertion-failure" ]
}

@test "jest-adapter: pass-case mixed → assertion-failure" {
  out="$(_run_adapter jest-adapter.sh 1 " FAIL  src/foo.test.js
 PASS  src/bar.test.js
Tests:       1 failed, 1 passed, 2 total
" "")"
  [ "$?" -eq 0 ]
  [ "$out" = "assertion-failure" ]
}

@test "jest-adapter: vacuous-RED case → pass token" {
  out="$(_run_adapter jest-adapter.sh 0 " PASS  src/foo.test.js
Tests:       2 passed, 2 total
" "")"
  [ "$?" -eq 0 ]
  [ "$out" = "pass" ]
}

@test "jest-adapter: infrastructure-failure → infrastructure-failure token" {
  out="$(_run_adapter jest-adapter.sh 1 "" "Cannot find module 'missing-dep'")"
  [ "$?" -eq 0 ]
  [ "$out" = "infrastructure-failure" ]
}

@test "jest-adapter: adapter-exit-1 unrecognized output → exit 1 with distinguishing stderr" {
  run _run_adapter jest-adapter.sh 1 "garbage output with no PASS or FAIL or Tests: markers" ""
  [ "$status" -eq 1 ]
  [[ "$output" == *"jest-adapter:"* ]]
  [[ "$output" != "infrastructure-failure"* ]]
}

# =============================================================================
# Adapter behavioral pins — vitest adapter
# =============================================================================

@test "vitest-adapter: pass-case all-fail → assertion-failure" {
  out="$(_run_adapter vitest-adapter.sh 1 " FAIL  src/foo.test.ts
Tests  2 failed
" "")"
  [ "$?" -eq 0 ]
  [ "$out" = "assertion-failure" ]
}

@test "vitest-adapter: pass-case mixed → assertion-failure" {
  out="$(_run_adapter vitest-adapter.sh 1 " FAIL  src/foo.test.ts
 PASS  src/bar.test.ts
Tests  1 failed
Tests  1 passed
" "")"
  [ "$?" -eq 0 ]
  [ "$out" = "assertion-failure" ]
}

@test "vitest-adapter: vacuous-RED case → pass token" {
  out="$(_run_adapter vitest-adapter.sh 0 "Tests  2 passed
" "")"
  [ "$?" -eq 0 ]
  [ "$out" = "pass" ]
}

@test "vitest-adapter: infrastructure-failure → infrastructure-failure token" {
  out="$(_run_adapter vitest-adapter.sh 1 "" "Cannot find module './missing'")"
  [ "$?" -eq 0 ]
  [ "$out" = "infrastructure-failure" ]
}

@test "vitest-adapter: adapter-exit-1 unrecognized output → exit 1 with distinguishing stderr" {
  run _run_adapter vitest-adapter.sh 1 "garbage output no markers anywhere xyz" ""
  [ "$status" -eq 1 ]
  [[ "$output" == *"vitest-adapter:"* ]]
  [[ "$output" != "infrastructure-failure"* ]]
}

# =============================================================================
# Adapter behavioral pins — pytest adapter
# =============================================================================

@test "pytest-adapter: pass-case all-fail → assertion-failure" {
  out="$(_run_adapter pytest-adapter.sh 1 "FAILED test_foo.py::test_alpha
FAILED test_foo.py::test_beta
2 failed in 0.10s
" "")"
  [ "$?" -eq 0 ]
  [ "$out" = "assertion-failure" ]
}

@test "pytest-adapter: pass-case mixed → assertion-failure" {
  out="$(_run_adapter pytest-adapter.sh 1 "FAILED test_foo.py::test_alpha
1 failed, 1 passed in 0.10s
" "")"
  [ "$?" -eq 0 ]
  [ "$out" = "assertion-failure" ]
}

@test "pytest-adapter: vacuous-RED case → pass token" {
  out="$(_run_adapter pytest-adapter.sh 0 "2 passed in 0.10s
" "")"
  [ "$?" -eq 0 ]
  [ "$out" = "pass" ]
}

@test "pytest-adapter: infrastructure-failure → infrastructure-failure token" {
  out="$(_run_adapter pytest-adapter.sh 2 "" "ImportError: No module named missing")"
  [ "$?" -eq 0 ]
  [ "$out" = "infrastructure-failure" ]
}

@test "pytest-adapter: adapter-exit-1 unrecognized output → exit 1 with distinguishing stderr" {
  run _run_adapter pytest-adapter.sh 7 "garbage with no recognized markers" ""
  [ "$status" -eq 1 ]
  [[ "$output" == *"pytest-adapter:"* ]]
  [[ "$output" != "infrastructure-failure"* ]]
}
