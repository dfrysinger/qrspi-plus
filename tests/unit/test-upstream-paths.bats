#!/usr/bin/env bats
#
# Unit tests for scripts/upstream-paths.sh — the per-step upstream-artifact
# path-list emitter (CD-1 + G1 + G4).
#
# Contract under test:
#   - For every supported step, the script prints the documented per-step
#     upstream-artifact basenames (relative to the run's <abs_path>), followed
#     by the always-appended SKILL paths.
#   - The always-appended SKILL paths include skills/implementer-protocol/SKILL.md
#     (the canonical ID-hygiene authority introduced by G1).
#   - An unknown --step value emits the always-appended SKILL paths only and
#     exits 0 with no diagnostic on stderr (CD-1 fail-soft direction).
#   - The Plan branch reads `pipeline:` from <artifact-dir>/config.md and
#     branches between full and quick upstream sets (G4).
#   - A missing config.md on the Plan branch halts non-zero with the
#     `config-missing:` named diagnostic.
#   - A present-but-malformed config.md (no pipeline: line, or pipeline: value
#     not in {full, quick}) halts non-zero with the `config-malformed:` named
#     diagnostic.

setup() {
  cd "$BATS_TEST_DIRNAME/../.."
  SCRIPT="./scripts/upstream-paths.sh"
  TMPDIR_FIXTURE="$(mktemp -d)"
}

teardown() {
  [[ -n "${TMPDIR_FIXTURE:-}" && -d "$TMPDIR_FIXTURE" ]] && rm -rf "$TMPDIR_FIXTURE"
}

# Helper: assert stdout (passed as $1, joined with newlines) equals $2.
assert_lines_equal() {
  local actual="$1"
  local expected="$2"
  if [[ "$actual" != "$expected" ]]; then
    echo "expected:"; echo "$expected"
    echo "actual:";   echo "$actual"
    return 1
  fi
}

@test "goals step: only the always-appended SKILL paths" {
  run "$SCRIPT" --step goals
  [ "$status" -eq 0 ]
  expected=$(printf '%s\n' \
    "skills/goals/SKILL.md" \
    "skills/using-qrspi/SKILL.md" \
    "skills/implementer-protocol/SKILL.md")
  assert_lines_equal "$output" "$expected"
}

@test "questions step: goals.md plus appended SKILLs" {
  run "$SCRIPT" --step questions
  [ "$status" -eq 0 ]
  expected=$(printf '%s\n' \
    "goals.md" \
    "skills/questions/SKILL.md" \
    "skills/using-qrspi/SKILL.md" \
    "skills/implementer-protocol/SKILL.md")
  assert_lines_equal "$output" "$expected"
}

@test "research step: goals.md, questions.md plus appended SKILLs" {
  run "$SCRIPT" --step research
  [ "$status" -eq 0 ]
  expected=$(printf '%s\n' \
    "goals.md" \
    "questions.md" \
    "skills/research/SKILL.md" \
    "skills/using-qrspi/SKILL.md" \
    "skills/implementer-protocol/SKILL.md")
  assert_lines_equal "$output" "$expected"
}

@test "design step: goals.md, questions.md, research/summary.md plus appended SKILLs" {
  run "$SCRIPT" --step design
  [ "$status" -eq 0 ]
  expected=$(printf '%s\n' \
    "goals.md" \
    "questions.md" \
    "research/summary.md" \
    "skills/design/SKILL.md" \
    "skills/using-qrspi/SKILL.md" \
    "skills/implementer-protocol/SKILL.md")
  assert_lines_equal "$output" "$expected"
}

@test "phasing step: goals.md, design.md plus appended SKILLs" {
  run "$SCRIPT" --step phasing
  [ "$status" -eq 0 ]
  expected=$(printf '%s\n' \
    "goals.md" \
    "design.md" \
    "skills/phasing/SKILL.md" \
    "skills/using-qrspi/SKILL.md" \
    "skills/implementer-protocol/SKILL.md")
  assert_lines_equal "$output" "$expected"
}

@test "structure step: goals.md, design.md, phasing.md plus appended SKILLs" {
  run "$SCRIPT" --step structure
  [ "$status" -eq 0 ]
  expected=$(printf '%s\n' \
    "goals.md" \
    "design.md" \
    "phasing.md" \
    "skills/structure/SKILL.md" \
    "skills/using-qrspi/SKILL.md" \
    "skills/implementer-protocol/SKILL.md")
  assert_lines_equal "$output" "$expected"
}

@test "parallelize step: goals.md, design.md, structure.md plus appended SKILLs" {
  run "$SCRIPT" --step parallelize
  [ "$status" -eq 0 ]
  expected=$(printf '%s\n' \
    "goals.md" \
    "design.md" \
    "structure.md" \
    "skills/parallelize/SKILL.md" \
    "skills/using-qrspi/SKILL.md" \
    "skills/implementer-protocol/SKILL.md")
  assert_lines_equal "$output" "$expected"
}

@test "replan step: plan.md, replan-trigger-source plus appended SKILLs" {
  run "$SCRIPT" --step replan
  [ "$status" -eq 0 ]
  expected=$(printf '%s\n' \
    "plan.md" \
    "replan-trigger-source" \
    "skills/replan/SKILL.md" \
    "skills/using-qrspi/SKILL.md" \
    "skills/implementer-protocol/SKILL.md")
  assert_lines_equal "$output" "$expected"
}

@test "unknown step: always-appended SKILL paths only, exit 0, no stderr diagnostic" {
  run "$SCRIPT" --step bogus-step-name
  [ "$status" -eq 0 ]
  expected=$(printf '%s\n' \
    "skills/bogus-step-name/SKILL.md" \
    "skills/using-qrspi/SKILL.md" \
    "skills/implementer-protocol/SKILL.md")
  assert_lines_equal "$output" "$expected"

  # Confirm no diagnostic on stderr (fail-soft direction).
  run bash -c "$SCRIPT --step bogus-step-name 2>&1 1>/dev/null"
  [ -z "$output" ]
}

@test "always-appended array contains skills/implementer-protocol/SKILL.md (G1)" {
  # Spot-check across one step from each "shape" (no-upstream, single-upstream,
  # multi-upstream, and unknown) that the implementer-protocol path is appended.
  for step in goals questions design unknown-xxx; do
    run "$SCRIPT" --step "$step"
    [ "$status" -eq 0 ]
    echo "$output" | grep -qx "skills/implementer-protocol/SKILL.md" \
      || { echo "missing implementer-protocol path for step=$step"; echo "$output"; return 1; }
  done
}

@test "plan step (full pipeline): goals.md, research/summary.md, design.md, phasing.md, structure.md plus appended SKILLs" {
  printf 'pipeline: full\n' > "$TMPDIR_FIXTURE/config.md"
  run "$SCRIPT" --step plan --artifact-dir "$TMPDIR_FIXTURE"
  [ "$status" -eq 0 ]
  expected=$(printf '%s\n' \
    "goals.md" \
    "research/summary.md" \
    "design.md" \
    "phasing.md" \
    "structure.md" \
    "skills/plan/SKILL.md" \
    "skills/using-qrspi/SKILL.md" \
    "skills/implementer-protocol/SKILL.md")
  assert_lines_equal "$output" "$expected"
}

@test "plan step (quick pipeline): goals.md, research/summary.md plus appended SKILLs" {
  printf 'pipeline: quick\n' > "$TMPDIR_FIXTURE/config.md"
  run "$SCRIPT" --step plan --artifact-dir "$TMPDIR_FIXTURE"
  [ "$status" -eq 0 ]
  expected=$(printf '%s\n' \
    "goals.md" \
    "research/summary.md" \
    "skills/plan/SKILL.md" \
    "skills/using-qrspi/SKILL.md" \
    "skills/implementer-protocol/SKILL.md")
  assert_lines_equal "$output" "$expected"
}

@test "plan step: missing config.md halts with config-missing: diagnostic and non-zero exit" {
  # Note: artifact-dir exists, config.md does not.
  run "$SCRIPT" --step plan --artifact-dir "$TMPDIR_FIXTURE"
  [ "$status" -ne 0 ]
  echo "$output" | grep -q "config-missing:" \
    || { echo "expected config-missing: diagnostic"; echo "$output"; return 1; }
}

@test "plan step: --artifact-dir omitted halts with config-missing: diagnostic" {
  run "$SCRIPT" --step plan
  [ "$status" -ne 0 ]
  echo "$output" | grep -q "config-missing:" \
    || { echo "expected config-missing: diagnostic"; echo "$output"; return 1; }
}

@test "plan step: config.md with no pipeline: line halts with config-malformed: diagnostic" {
  printf 'something_else: value\n' > "$TMPDIR_FIXTURE/config.md"
  run "$SCRIPT" --step plan --artifact-dir "$TMPDIR_FIXTURE"
  [ "$status" -ne 0 ]
  echo "$output" | grep -q "config-malformed:" \
    || { echo "expected config-malformed: diagnostic"; echo "$output"; return 1; }
}

@test "plan step: config.md with empty body halts with config-malformed: diagnostic" {
  : > "$TMPDIR_FIXTURE/config.md"
  run "$SCRIPT" --step plan --artifact-dir "$TMPDIR_FIXTURE"
  [ "$status" -ne 0 ]
  echo "$output" | grep -q "config-malformed:" \
    || { echo "expected config-malformed: diagnostic"; echo "$output"; return 1; }
}

@test "plan step: config.md with unrecognised pipeline value halts with config-malformed: diagnostic" {
  printf 'pipeline: bogus\n' > "$TMPDIR_FIXTURE/config.md"
  run "$SCRIPT" --step plan --artifact-dir "$TMPDIR_FIXTURE"
  [ "$status" -ne 0 ]
  echo "$output" | grep -q "config-malformed:" \
    || { echo "expected config-malformed: diagnostic"; echo "$output"; return 1; }
}

@test "missing --step argument exits non-zero" {
  run "$SCRIPT"
  [ "$status" -ne 0 ]
}
