#!/usr/bin/env bats

setup() {
  TEST_DIR="$(mktemp -d)"
  export TEST_DIR
  cd "$TEST_DIR"
}

teardown() {
  cd /
  rm -rf "$TEST_DIR"
}

# Helper function to create a markdown file with frontmatter status
create_artifact() {
  local file="$1"
  local status="$2"
  local dir="$(dirname "$file")"

  mkdir -p "$dir"
  cat > "$file" <<EOF
---
status: $status
---
EOF
}

# Test: state_init_or_reconcile with approved goals.md + draft design.md
@test "state_init_or_reconcile: approved goals, draft design -> current_step=questions" {
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir"

  create_artifact "$artifact_dir/goals.md" "approved"
  create_artifact "$artifact_dir/design.md" "draft"

  source "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"
  run state_init_or_reconcile "$artifact_dir"

  [ "$status" -eq 0 ]

  # Verify current_step is "questions"
  local json
  json=$(state_read)
  [[ "$json" == *'"current_step":"questions"'* ]]

  # Verify artifact statuses
  [[ "$json" == *'"goals":"approved"'* ]]
  [[ "$json" == *'"design":"draft"'* ]]
}

# Test: state_init_or_reconcile with all approved through parallelization.md
# (T25 R2 I-N4: parallelize is now the 8th file-backed step; implement is next)
@test "state_init_or_reconcile: all approved through parallelize -> current_step=implement" {
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir"

  create_artifact "$artifact_dir/goals.md" "approved"
  create_artifact "$artifact_dir/questions.md" "approved"
  create_artifact "$artifact_dir/design.md" "approved"
  create_artifact "$artifact_dir/phasing.md" "approved"
  create_artifact "$artifact_dir/structure.md" "approved"
  create_artifact "$artifact_dir/plan.md" "approved"
  create_artifact "$artifact_dir/parallelization.md" "approved"

  # Create research/summary.md
  mkdir -p "$artifact_dir/research"
  create_artifact "$artifact_dir/research/summary.md" "approved"

  source "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"
  run state_init_or_reconcile "$artifact_dir"

  [ "$status" -eq 0 ]

  local json
  json=$(state_read)
  [[ "$json" == *'"current_step":"implement"'* ]]
}

# Test: state_init_or_reconcile with empty artifact dir
@test "state_init_or_reconcile: empty artifact dir -> all draft, current_step=goals" {
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir"

  source "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"
  run state_init_or_reconcile "$artifact_dir"

  [ "$status" -eq 0 ]

  local json
  json=$(state_read)
  [[ "$json" == *'"current_step":"goals"'* ]]
  [[ "$json" == *'"goals":"draft"'* ]]
  [[ "$json" == *'"questions":"draft"'* ]]
  [[ "$json" == *'"research":"draft"'* ]]
  [[ "$json" == *'"design":"draft"'* ]]
  [[ "$json" == *'"structure":"draft"'* ]]
  [[ "$json" == *'"plan":"draft"'* ]]
  [[ "$json" == *'"implement":"draft"'* ]]
  [[ "$json" == *'"test":"draft"'* ]]
}

# Test: state_init_or_reconcile with missing artifact dir
@test "state_init_or_reconcile: missing artifact dir -> returns 1" {
  source "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"
  run state_init_or_reconcile "$TEST_DIR/nonexistent"

  [ "$status" -eq 1 ]
}

# Test: state_read when state exists
@test "state_read: state exists -> outputs valid JSON, returns 0" {
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir"
  create_artifact "$artifact_dir/goals.md" "draft"

  source "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"
  state_init_or_reconcile "$artifact_dir" > /dev/null

  run state_read
  [ "$status" -eq 0 ]

  # Verify it's valid JSON by checking with jq
  echo "$output" | jq . > /dev/null
}

# Test: state_read when no state exists
@test "state_read: no state -> returns 1" {
  source "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"
  run state_read

  [ "$status" -eq 1 ]
}

# Test: state_write_atomic writes valid JSON
@test "state_write_atomic: writes valid JSON -> file exists with correct content" {
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir"

  cd "$artifact_dir"

  source "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"

  local test_json='{"version":1,"current_step":"goals"}'
  run state_write_atomic "$test_json"

  [ "$status" -eq 0 ]

  # Verify file exists
  [ -f "$artifact_dir/.qrspi/state.json" ]

  # Verify content
  local content
  content=$(cat "$artifact_dir/.qrspi/state.json")
  [[ "$content" == *'"version":1'* ]]
  [[ "$content" == *'"current_step":"goals"'* ]]
}

# Test: state_write_atomic creates .qrspi/ if needed
@test "state_write_atomic: creates .qrspi/ if needed" {
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir"

  cd "$artifact_dir"

  source "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"

  local test_json='{"version":1}'
  run state_write_atomic "$test_json"

  [ "$status" -eq 0 ]
  [ -d "$artifact_dir/.qrspi" ]
}

# Test: State has version=1
@test "state_init_or_reconcile: state has version=1" {
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir"

  source "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"
  state_init_or_reconcile "$artifact_dir" > /dev/null

  local json
  json=$(state_read)
  [[ "$json" == *'"version":1'* ]]
}

# Test: State has correct artifact_dir
@test "state_init_or_reconcile: state has correct artifact_dir" {
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir"

  source "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"
  state_init_or_reconcile "$artifact_dir" > /dev/null

  local json
  json=$(state_read)
  # artifact_dir should be set to the absolute path
  [[ "$json" == *'"artifact_dir"'* ]]
}

# Test: State has wireframe_requested=false
@test "state_init_or_reconcile: state has wireframe_requested=false" {
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir"

  source "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"
  state_init_or_reconcile "$artifact_dir" > /dev/null

  local json
  json=$(state_read)
  [[ "$json" == *'"wireframe_requested":false'* ]]
}

# Test: State has no active_task field (removed in 2026-04-26 implement-runtime-fix)
@test "state_init_or_reconcile: state has no active_task field" {
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir"

  source "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"
  state_init_or_reconcile "$artifact_dir" > /dev/null

  local json
  json=$(state_read)
  [[ "$json" != *'active_task'* ]]
}

# Test: Recognizes all 8 artifacts
@test "state_init_or_reconcile: recognizes all 8 artifacts" {
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir"

  source "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"
  state_init_or_reconcile "$artifact_dir" > /dev/null

  local json
  json=$(state_read)

  # All 8 should be present
  [[ "$json" == *'"goals"'* ]]
  [[ "$json" == *'"questions"'* ]]
  [[ "$json" == *'"research"'* ]]
  [[ "$json" == *'"design"'* ]]
  [[ "$json" == *'"structure"'* ]]
  [[ "$json" == *'"plan"'* ]]
  [[ "$json" == *'"implement"'* ]]
  [[ "$json" == *'"test"'* ]]
}

# Test: Maps research/summary.md to "research" key
@test "state_init_or_reconcile: maps research/summary.md to research key" {
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir/research"

  create_artifact "$artifact_dir/research/summary.md" "approved"

  source "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"
  state_init_or_reconcile "$artifact_dir" > /dev/null

  local json
  json=$(state_read)
  [[ "$json" == *'"research":"approved"'* ]]
}

# Test: Library uses set -euo pipefail
@test "state.sh: starts with #!/usr/bin/env bash" {
  head -1 "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh" | grep -q '^#!/usr/bin/env bash'
}

@test "state.sh: has 'set -euo pipefail' as early line" {
  head -2 "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh" | tail -1 | grep -q '^set -euo pipefail'
}

# Test: state_init_or_reconcile reads frontmatter correctly from all artifacts
@test "state_init_or_reconcile: reads frontmatter status from all artifact types" {
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir/research"

  create_artifact "$artifact_dir/goals.md" "approved"
  create_artifact "$artifact_dir/questions.md" "approved"
  create_artifact "$artifact_dir/research/summary.md" "approved"
  create_artifact "$artifact_dir/design.md" "approved"
  create_artifact "$artifact_dir/structure.md" "draft"
  create_artifact "$artifact_dir/plan.md" "draft"

  source "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"
  state_init_or_reconcile "$artifact_dir" > /dev/null

  local json
  json=$(state_read)

  [[ "$json" == *'"goals":"approved"'* ]]
  [[ "$json" == *'"questions":"approved"'* ]]
  [[ "$json" == *'"research":"approved"'* ]]
  [[ "$json" == *'"design":"approved"'* ]]
  [[ "$json" == *'"structure":"draft"'* ]]
  [[ "$json" == *'"plan":"draft"'* ]]
}

# Test: current_step is first non-approved artifact in pipeline order
@test "state_init_or_reconcile: current_step is first non-approved in pipeline order" {
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir/research"

  create_artifact "$artifact_dir/goals.md" "approved"
  create_artifact "$artifact_dir/questions.md" "approved"
  create_artifact "$artifact_dir/research/summary.md" "draft"
  create_artifact "$artifact_dir/design.md" "approved"

  source "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"
  state_init_or_reconcile "$artifact_dir" > /dev/null

  local json
  json=$(state_read)

  # research is draft, so it should be current_step
  [[ "$json" == *'"current_step":"research"'* ]]
}

# ============================================================================
# [T04] Fail-closed error handling tests
# ============================================================================

@test "[T04-S1] state_init_or_reconcile: jq failure returns exit 1 with stderr diagnostic" {
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir"

  source "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"

  # Sabotage jq by putting a fake jq first in PATH
  local fake_bin="$TEST_DIR/fake-bin"
  mkdir -p "$fake_bin"
  printf '#!/bin/sh\nexit 1\n' > "$fake_bin/jq"
  chmod +x "$fake_bin/jq"

  PATH="$fake_bin:$PATH" run state_init_or_reconcile "$artifact_dir"
  [ "$status" -eq 1 ]
  [[ "$output" == *"jq failed"* ]]
}

@test "[T04-S2] state_write_atomic: no-write .qrspi/ returns exit 1 with stderr diagnostic" {
  source "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"

  mkdir -p "$TEST_DIR/.qrspi"
  chmod 555 "$TEST_DIR/.qrspi"

  run state_write_atomic '{"version":1}'
  chmod 755 "$TEST_DIR/.qrspi" 2>/dev/null || true
  [ "$status" -eq 1 ]
  [[ "$output" == *"failed"* ]]
}

@test "[T04-S3] state_init_or_reconcile: binary goals.md defaults to draft with stderr WARNING" {
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir"

  # Write binary content to goals.md
  printf '\x00\x01\x02\x03' > "$artifact_dir/goals.md"

  source "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"

  local stderr_file="$TEST_DIR/stderr.txt"
  state_init_or_reconcile "$artifact_dir" 2>"$stderr_file"
  local exit_code=$?

  [ "$exit_code" -eq 0 ]

  local json
  json=$(state_read)
  [[ "$json" == *'"goals":"draft"'* ]]

  local stderr_content
  stderr_content=$(cat "$stderr_file")
  [[ "$stderr_content" == *"WARNING"* ]]
  [[ "$stderr_content" == *"cannot read status"* ]]
}

@test "[T04-S4] state_init_or_reconcile: no-write .qrspi/ returns exit 1 with stderr diagnostic" {
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir"

  source "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"

  mkdir -p "$TEST_DIR/.qrspi"
  chmod 555 "$TEST_DIR/.qrspi"

  run state_init_or_reconcile "$artifact_dir"
  chmod 755 "$TEST_DIR/.qrspi" 2>/dev/null || true
  [ "$status" -eq 1 ]
  [[ "$output" == *"state_write_atomic failed"* ]]
}

# ============================================================================
# [T14] State bootstrap and cascade reset tests
# ============================================================================

@test "[T14-S1] state_init_or_reconcile: approved goals + draft questions + no state.json -> creates state" {
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir"

  create_artifact "$artifact_dir/goals.md" "approved"
  create_artifact "$artifact_dir/questions.md" "draft"

  # Ensure no state.json exists
  [ ! -f "$TEST_DIR/.qrspi/state.json" ]

  source "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"
  run state_init_or_reconcile "$artifact_dir"

  [ "$status" -eq 0 ]

  local json
  json=$(state_read)
  [[ "$json" == *'"current_step":"questions"'* ]]
  [[ "$json" == *'"goals":"approved"'* ]]
  [[ "$json" == *'"questions":"draft"'* ]]
}

@test "[T14-S2] state_init_or_reconcile: existing state with goals=approved but goals.md now draft -> reconciles to goals=draft" {
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir"

  create_artifact "$artifact_dir/goals.md" "approved"

  source "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"

  # First init: goals=approved
  state_init_or_reconcile "$artifact_dir"
  local json
  json=$(state_read)
  [[ "$json" == *'"goals":"approved"'* ]]

  # Now change goals.md frontmatter to draft
  create_artifact "$artifact_dir/goals.md" "draft"

  # Re-reconcile
  state_init_or_reconcile "$artifact_dir"

  json=$(state_read)
  [[ "$json" == *'"goals":"draft"'* ]]
  [[ "$json" == *'"current_step":"goals"'* ]]
}

@test "[T14-S3] state_init_or_reconcile: called twice -> identical result (idempotency)" {
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir/research"

  create_artifact "$artifact_dir/goals.md" "approved"
  create_artifact "$artifact_dir/questions.md" "approved"
  create_artifact "$artifact_dir/research/summary.md" "draft"

  source "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"

  state_init_or_reconcile "$artifact_dir"
  local json1
  json1=$(state_read)

  state_init_or_reconcile "$artifact_dir"
  local json2
  json2=$(state_read)

  # Compare key fields (artifact_dir may differ in whitespace but content should match)
  local step1 step2 goals1 goals2 questions1 questions2 research1 research2
  step1=$(echo "$json1" | jq -r '.current_step')
  step2=$(echo "$json2" | jq -r '.current_step')
  goals1=$(echo "$json1" | jq -r '.artifacts.goals')
  goals2=$(echo "$json2" | jq -r '.artifacts.goals')
  questions1=$(echo "$json1" | jq -r '.artifacts.questions')
  questions2=$(echo "$json2" | jq -r '.artifacts.questions')
  research1=$(echo "$json1" | jq -r '.artifacts.research')
  research2=$(echo "$json2" | jq -r '.artifacts.research')

  [[ "$step1" == "$step2" ]]
  [[ "$goals1" == "$goals2" ]]
  [[ "$questions1" == "$questions2" ]]
  [[ "$research1" == "$research2" ]]
}

@test "[T14-S4] state_init_or_reconcile: jq produces invalid JSON -> returns non-zero, no state written" {
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir"

  source "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"

  # Sabotage jq to output invalid JSON (non-empty but not valid)
  local fake_bin="$TEST_DIR/fake-bin"
  mkdir -p "$fake_bin"
  printf '#!/bin/sh\necho "not-valid-json{"\nexit 0\n' > "$fake_bin/jq"
  chmod +x "$fake_bin/jq"

  PATH="$fake_bin:$PATH" run state_init_or_reconcile "$artifact_dir"
  [ "$status" -ne 0 ]

  # No state file should have been written (or if one existed, it should not be valid)
  [ ! -f "$TEST_DIR/.qrspi/state.json" ]
}

# ============================================================================
# [T04-PHASING] Phasing-step state integration tests (M54)
# ============================================================================

@test "[T04-PHASING-1S] state_init_or_reconcile: includes phasing artifact field with status draft when phasing.md absent" {
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir"

  source "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"
  state_init_or_reconcile "$artifact_dir"

  local json
  json=$(state_read)
  [[ "$json" == *'"phasing":"draft"'* ]]
}

@test "[T04-PHASING-2S] state_init_or_reconcile: reads phasing.md frontmatter status into artifacts.phasing" {
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir"

  create_artifact "$artifact_dir/phasing.md" "approved"

  source "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"
  state_init_or_reconcile "$artifact_dir"

  local json
  json=$(state_read)
  [[ "$json" == *'"phasing":"approved"'* ]]
}

@test "[T04-PHASING-3S] state_init_or_reconcile: current_step is phasing when goals/questions/research/design approved and phasing draft" {
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir/research"

  create_artifact "$artifact_dir/goals.md" "approved"
  create_artifact "$artifact_dir/questions.md" "approved"
  create_artifact "$artifact_dir/research/summary.md" "approved"
  create_artifact "$artifact_dir/design.md" "approved"
  create_artifact "$artifact_dir/phasing.md" "draft"

  source "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"
  state_init_or_reconcile "$artifact_dir"

  local json
  json=$(state_read)
  [[ "$json" == *'"current_step":"phasing"'* ]]
}

@test "[T04-PHASING-4S] state_compute_current_step: returns phasing for fixture with phasing draft and upstream approved" {
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir/research"

  create_artifact "$artifact_dir/goals.md" "approved"
  create_artifact "$artifact_dir/questions.md" "approved"
  create_artifact "$artifact_dir/research/summary.md" "approved"
  create_artifact "$artifact_dir/design.md" "approved"
  create_artifact "$artifact_dir/phasing.md" "draft"

  source "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"
  local out
  out=$(state_compute_current_step "$artifact_dir")
  [[ "$out" == "phasing" ]]
}

@test "[T04-PHASING-4Sb] state_compute_current_step: returns implement when all 8 file-backed steps approved (matches state_init_or_reconcile)" {
  # Semantic-equivalence guard: state_compute_current_step's terminal default
  # must match state_init_or_reconcile's all-approved branch. Per QRSPI
  # semantics, after parallelize is approved, the next step is implement
  # (since implement_status defaults to "draft" and implement comes before
  # test in pipeline order). T25 R2 I-N4 added parallelize as the 8th
  # file-backed step.
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir/research"

  create_artifact "$artifact_dir/goals.md" "approved"
  create_artifact "$artifact_dir/questions.md" "approved"
  create_artifact "$artifact_dir/research/summary.md" "approved"
  create_artifact "$artifact_dir/design.md" "approved"
  create_artifact "$artifact_dir/phasing.md" "approved"
  create_artifact "$artifact_dir/structure.md" "approved"
  create_artifact "$artifact_dir/plan.md" "approved"
  create_artifact "$artifact_dir/parallelization.md" "approved"

  source "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"
  local helper_out
  helper_out=$(state_compute_current_step "$artifact_dir")
  [[ "$helper_out" == "implement" ]]

  # Cross-check: state_init_or_reconcile produces matching current_step
  state_init_or_reconcile "$artifact_dir" > /dev/null
  local json
  json=$(state_read)
  [[ "$json" == *'"current_step":"implement"'* ]]
}

@test "[T04-PHASING-5] state_init_or_reconcile fails closed when jq missing and writes no state.json" {
  source "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"

  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir"

  # Build a minimal PATH containing every shell utility state.sh legitimately
  # uses (mkdir, mv, mktemp, rm, cat, echo, dirname, basename, sh) EXCEPT jq.
  # This isolates the fail-closed-on-jq behavior from any other utility's
  # absence; if PATH were empty, mkdir/mv would also fail and the test could
  # pass for the wrong reason (state_write_atomic failure instead of jq
  # detection).
  local stub_dir="$TEST_DIR/stub-no-jq"
  mkdir -p "$stub_dir"
  local util util_path
  for util in mkdir mv mktemp rm cat echo dirname basename sh chmod; do
    util_path=$(command -v "$util" 2>/dev/null) || true
    if [ -n "$util_path" ]; then
      ln -sf "$util_path" "$stub_dir/$util"
    fi
  done
  # Verify jq is NOT in stub_dir
  [ ! -e "$stub_dir/jq" ]

  # Ensure no state.json initially
  rm -f "$TEST_DIR/.qrspi/state.json"

  PATH="$stub_dir" run state_init_or_reconcile "$artifact_dir"
  [ "$status" -ne 0 ]
  [ ! -f "$TEST_DIR/.qrspi/state.json" ]
}

@test "[T04-PHASING-5b] state_init_or_reconcile emits state.sh stderr diagnostic when jq fails (mutation-resistant)" {
  # This test strengthens [T04-PHASING-5] by verifying that state.sh's EXPLICIT
  # fail-closed code path fires on jq error — not merely that bash propagates
  # jq's non-zero exit. A regression replacing the explicit `if ! json=$(jq ...);
  # then echo "...jq failed..." >&2; return 1; fi` with a non-checking variant
  # like `json=$(jq ... 2>/dev/null) || true` would still produce non-zero exit
  # via set -euo pipefail downstream, but would NOT emit state.sh's own
  # "state_init_or_reconcile: jq failed" stderr message. This test catches
  # exactly that mutation by asserting the state.sh-emitted message appears.
  source "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"

  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir"

  # Build minimal PATH with all utilities state.sh uses, plus a stub jq that
  # FAILS with stderr (rather than being absent). This isolates the
  # "jq exists but errors" code path from the "jq missing" code path.
  local stub_dir="$TEST_DIR/stub-failing-jq"
  mkdir -p "$stub_dir"
  local util util_path
  for util in mkdir mv mktemp rm cat echo dirname basename sh chmod; do
    util_path=$(command -v "$util" 2>/dev/null) || true
    if [ -n "$util_path" ]; then
      ln -sf "$util_path" "$stub_dir/$util"
    fi
  done

  # Stub jq: prints to stderr and exits 1 (simulating real jq error).
  # Using printf (not heredoc) per Daniel's tooling constraints.
  printf '#!/bin/sh\necho "fake jq failure" >&2\nexit 1\n' > "$stub_dir/jq"
  chmod +x "$stub_dir/jq"

  # Ensure no state.json exists initially
  rm -f "$TEST_DIR/.qrspi/state.json"

  PATH="$stub_dir" run state_init_or_reconcile "$artifact_dir"

  # Assertion 1: non-zero exit (fail-closed)
  [ "$status" -ne 0 ]

  # Assertion 2: no state.json written (fail-closed: don't persist on error)
  [ ! -f "$TEST_DIR/.qrspi/state.json" ]

  # Assertion 3 (mutation-distinguishing): state.sh's OWN stderr diagnostic
  # appears in output. The explicit `echo "state_init_or_reconcile: jq failed
  # to build state JSON" >&2` at state.sh:146 must fire. If a regression
  # removes that explicit error handling, this assertion fails — distinguishing
  # state.sh's fail-closed code path from incidental bash exit propagation.
  [[ "$output" == *"state_init_or_reconcile"* ]]
  [[ "$output" == *"jq failed"* ]]
}

# [T04-PHASING-4Sc] Table-driven coverage of every reachable return value of
# state_compute_current_step. Round-4 thoroughness gap: prior tests (4S, 4Sb)
# only verified the helper for "phasing" (one mid-pipeline case) and the
# terminal "implement" default. The other file-backed values (goals, questions,
# research, design, structure, plan, parallelize) were unverified at the helper
# level — a mutation reordering the helper's loop (e.g., swapping `research`
# and `design`) would not have been caught. This test walks every step S in
# the file-backed sequence and the all-approved terminal case, asserting
# state_compute_current_step echoes exactly S.
# (T25 R2 I-N4 added parallelize as the 8th file-backed step.)
@test "[T04-PHASING-4Sc] state_compute_current_step: table-driven coverage of every reachable return value" {
  source "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"

  # Each iteration: build a fresh fixture where every step BEFORE S is
  # approved, S itself is draft, then assert helper echoes S exactly.
  local target steps_before s out
  for target in goals questions research design phasing structure plan parallelize; do
    # Fresh artifact dir per iteration to avoid leakage from prior fixtures
    local artifact_dir="$TEST_DIR/artifacts-$target"
    mkdir -p "$artifact_dir/research"

    # Build the upstream-approved prefix
    local hit_target=false
    for s in goals questions research design phasing structure plan parallelize; do
      if [[ "$s" == "$target" ]]; then
        hit_target=true
        # S itself: draft (explicit file with draft frontmatter)
        case "$s" in
          research)    create_artifact "$artifact_dir/research/summary.md" "draft" ;;
          parallelize) create_artifact "$artifact_dir/parallelization.md" "draft" ;;
          *)           create_artifact "$artifact_dir/$s.md" "draft" ;;
        esac
        continue
      fi
      if [[ "$hit_target" == "true" ]]; then
        # Steps after target — leave absent (helper only inspects up to first
        # non-approved, so post-target state doesn't affect outcome)
        continue
      fi
      # Steps before target: approved
      case "$s" in
        research)    create_artifact "$artifact_dir/research/summary.md" "approved" ;;
        parallelize) create_artifact "$artifact_dir/parallelization.md" "approved" ;;
        *)           create_artifact "$artifact_dir/$s.md" "approved" ;;
      esac
    done

    out=$(state_compute_current_step "$artifact_dir")
    [[ "$out" == "$target" ]] || {
      echo "expected '$target', got '$out' (artifact_dir=$artifact_dir)" >&2
      return 1
    }
  done

  # All-approved terminal case → "implement"
  local all_approved_dir="$TEST_DIR/artifacts-all-approved"
  mkdir -p "$all_approved_dir/research"
  create_artifact "$all_approved_dir/goals.md" "approved"
  create_artifact "$all_approved_dir/questions.md" "approved"
  create_artifact "$all_approved_dir/research/summary.md" "approved"
  create_artifact "$all_approved_dir/design.md" "approved"
  create_artifact "$all_approved_dir/phasing.md" "approved"
  create_artifact "$all_approved_dir/structure.md" "approved"
  create_artifact "$all_approved_dir/plan.md" "approved"
  create_artifact "$all_approved_dir/parallelization.md" "approved"

  out=$(state_compute_current_step "$all_approved_dir")
  [[ "$out" == "implement" ]]
}

@test "[T04-PHASING-6S] state_init_or_reconcile recognizes all 9 artifacts including phasing" {
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir"

  source "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"
  state_init_or_reconcile "$artifact_dir" > /dev/null

  local json
  json=$(state_read)

  [[ "$json" == *'"goals"'* ]]
  [[ "$json" == *'"questions"'* ]]
  [[ "$json" == *'"research"'* ]]
  [[ "$json" == *'"design"'* ]]
  [[ "$json" == *'"phasing"'* ]]
  [[ "$json" == *'"structure"'* ]]
  [[ "$json" == *'"plan"'* ]]
  [[ "$json" == *'"implement"'* ]]
  [[ "$json" == *'"test"'* ]]
}

# ============================================================================
# [T19-FU1] state_init_or_reconcile delegates to state_compute_current_step
# ============================================================================
# These tests prove that state_init_or_reconcile no longer carries an inline
# copy of the "first non-approved step" logic but instead delegates to
# state_compute_current_step. Strategy: override state_compute_current_step
# after sourcing state.sh with a mock that returns a value the inline logic
# would never produce on the fixture; then assert the resulting state.json's
# current_step matches the mock's return value. If the inline duplicate logic
# is still present, current_step will reflect the inline computation (NOT the
# mock), and the test fails.

@test "[T19-FU1-1] state_init_or_reconcile delegates to state_compute_current_step (mock returns sentinel)" {
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir"

  # Fixture: empty artifact dir. Inline logic would compute current_step="goals".
  # Mock returns a sentinel ("phasing") that inline logic would never produce
  # for this fixture, so any current_step != "phasing" proves delegation
  # failed.

  source "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"

  # Override the helper after sourcing. Bash function lookup is dynamic, so
  # the override applies to subsequent calls — including from
  # state_init_or_reconcile if it delegates.
  state_compute_current_step() {
    echo "phasing"
    return 0
  }

  state_init_or_reconcile "$artifact_dir" > /dev/null

  local json
  json=$(state_read)

  # If delegation works, current_step is the mock's value ("phasing").
  # If duplicate inline logic survives, current_step would be "goals" (since
  # all artifacts are draft on this fixture).
  [[ "$json" == *'"current_step":"phasing"'* ]] || {
    echo "FAIL: state_init_or_reconcile did not delegate to state_compute_current_step." >&2
    echo "Expected current_step=phasing (from mock), got JSON: $json" >&2
    return 1
  }
}

@test "[T19-FU1-2] state_init_or_reconcile delegates to state_compute_current_step (mock returns out-of-pipeline value)" {
  # Stronger variant: mock returns a value that is NOT one of the 9
  # pipeline steps. Inline duplicate logic is hard-coded to a 9-way
  # if/elif chain over the pipeline steps and could never produce
  # "T19-DELEGATED-MARKER". If the test's resulting current_step
  # contains that string, we have proof that the value flowed from the
  # mock, NOT from any inline computation.

  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir/research"

  # Approved through plan: inline logic would yield "implement".
  create_artifact "$artifact_dir/goals.md" "approved"
  create_artifact "$artifact_dir/questions.md" "approved"
  create_artifact "$artifact_dir/research/summary.md" "approved"
  create_artifact "$artifact_dir/design.md" "approved"
  create_artifact "$artifact_dir/phasing.md" "approved"
  create_artifact "$artifact_dir/structure.md" "approved"
  create_artifact "$artifact_dir/plan.md" "approved"

  source "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"

  # Mock returns a sentinel string that no inline pipeline-step computation
  # could produce.
  state_compute_current_step() {
    echo "T19-DELEGATED-MARKER"
    return 0
  }

  state_init_or_reconcile "$artifact_dir" > /dev/null

  local json
  json=$(state_read)

  [[ "$json" == *'"current_step":"T19-DELEGATED-MARKER"'* ]] || {
    echo "FAIL: state_init_or_reconcile did not delegate; got JSON: $json" >&2
    return 1
  }
}

@test "[T19-FU1-3] state.sh: state_init_or_reconcile body has no inline first-non-approved if/elif chain" {
  # Structural test: scan state_init_or_reconcile's body for the duplicate
  # if/elif chain that previously branched on every <step>_status variable.
  # After the FU-1 refactor, that chain should be gone — replaced by a single
  # call to state_compute_current_step. We assert the body contains a call to
  # state_compute_current_step AND does NOT contain the elif chain over
  # *_status variables that characterized the duplicated logic.

  local state_sh="$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"

  # Extract the body of state_init_or_reconcile (between its opening
  # "state_init_or_reconcile() {" and the matching closing brace at start of
  # line). awk: print between the function header and the next sole "}" at
  # column 1.
  local body
  body=$(awk '
    /^state_init_or_reconcile\(\) \{/ { in_fn=1; next }
    in_fn && /^\}/ { in_fn=0 }
    in_fn { print }
  ' "$state_sh")

  # Assertion 1: body delegates by calling state_compute_current_step
  echo "$body" | grep -q "state_compute_current_step" || {
    echo "FAIL: state_init_or_reconcile body does not call state_compute_current_step" >&2
    echo "Body was:" >&2
    echo "$body" >&2
    return 1
  }

  # Assertion 2: body does NOT contain the duplicate elif chain over _status
  # variables. The pre-refactor body had `elif [[ "$questions_status" !=
  # "approved" ]]` etc. — count occurrences of `_status" != "approved"` in
  # the body; the refactored version should have ZERO such occurrences (the
  # per-artifact status vars are read but no longer consulted in a
  # current_step decision chain).
  local elif_chain_hits
  elif_chain_hits=$(echo "$body" | grep -c '_status" != "approved"' || true)
  [ "$elif_chain_hits" -eq 0 ] || {
    echo "FAIL: state_init_or_reconcile body still contains $elif_chain_hits inline '_status != approved' branch(es)" >&2
    echo "Body was:" >&2
    echo "$body" >&2
    return 1
  }
}
