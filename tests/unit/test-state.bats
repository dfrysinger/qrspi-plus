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

# Test: state_init_or_reconcile with all approved through plan.md
@test "state_init_or_reconcile: all approved through plan -> current_step=implement" {
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir"

  create_artifact "$artifact_dir/goals.md" "approved"
  create_artifact "$artifact_dir/questions.md" "approved"
  create_artifact "$artifact_dir/design.md" "approved"
  create_artifact "$artifact_dir/phasing.md" "approved"
  create_artifact "$artifact_dir/structure.md" "approved"
  create_artifact "$artifact_dir/plan.md" "approved"

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
  # T24 fix-cycle 2: state_init_or_reconcile now does its own locked write
  # (no longer delegates to state_write_atomic for the write step). When
  # .qrspi/ is read-only, the failure surfaces at lock-acquire time
  # (cannot create lock dir/file) or at temp-file write time. Either
  # diagnostic is acceptable as a fail-closed signal; both contain "state".
  [[ "$output" == *"failed"* ]]
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

@test "[T04-PHASING-4Sb] state_compute_current_step: returns implement when all 7 file-backed steps approved (matches state_init_or_reconcile)" {
  # Semantic-equivalence guard: state_compute_current_step's terminal default
  # must match state_init_or_reconcile's all-approved branch. Per QRSPI
  # semantics, after plan is approved, the next step is implement (since
  # implement_status defaults to "draft" and implement comes before test in
  # pipeline order). The helper previously returned "test" — wrong because it
  # diverged from state_init_or_reconcile's inline logic which yields
  # "implement". See state.sh state_init_or_reconcile lines ~101-102.
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir/research"

  create_artifact "$artifact_dir/goals.md" "approved"
  create_artifact "$artifact_dir/questions.md" "approved"
  create_artifact "$artifact_dir/research/summary.md" "approved"
  create_artifact "$artifact_dir/design.md" "approved"
  create_artifact "$artifact_dir/phasing.md" "approved"
  create_artifact "$artifact_dir/structure.md" "approved"
  create_artifact "$artifact_dir/plan.md" "approved"

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
  for util in mkdir mv mktemp rm cat echo dirname basename sh chmod date kill sleep flock; do
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
  for util in mkdir mv mktemp rm cat echo dirname basename sh chmod date kill sleep flock; do
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
# terminal "implement" default. The other 6 reachable values (goals, questions,
# research, design, structure, plan) were unverified at the helper level — a
# mutation reordering the helper's loop (e.g., swapping `research` and `design`)
# would not have been caught. This test walks every step S in the file-backed
# sequence and the all-approved terminal case, asserting state_compute_current_step
# echoes exactly S.
@test "[T04-PHASING-4Sc] state_compute_current_step: table-driven coverage of every reachable return value" {
  source "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"

  # Each iteration: build a fresh fixture where every step BEFORE S is
  # approved, S itself is draft, then assert helper echoes S exactly.
  local target steps_before s out
  for target in goals questions research design phasing structure plan; do
    # Fresh artifact dir per iteration to avoid leakage from prior fixtures
    local artifact_dir="$TEST_DIR/artifacts-$target"
    mkdir -p "$artifact_dir/research"

    # Build the upstream-approved prefix
    local hit_target=false
    for s in goals questions research design phasing structure plan; do
      if [[ "$s" == "$target" ]]; then
        hit_target=true
        # S itself: draft (explicit file with draft frontmatter)
        case "$s" in
          research) create_artifact "$artifact_dir/research/summary.md" "draft" ;;
          *) create_artifact "$artifact_dir/$s.md" "draft" ;;
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
        research) create_artifact "$artifact_dir/research/summary.md" "approved" ;;
        *) create_artifact "$artifact_dir/$s.md" "approved" ;;
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

@test "[T19-FU1-2] state_init_or_reconcile delegates to state_compute_current_step (mock returns transition-state value unreachable from inline logic)" {
  # Stronger variant: mock returns a value that is in the allowlist but
  # CANNOT be produced by state_compute_current_step's inline logic for
  # the all-approved fixture (which would yield "implement"). The
  # transition states (parallelize, integrate, replan) are documented
  # current_step values per skills/using-qrspi/SKILL.md:223 — they are
  # in the T24 allowlist but are never returned by
  # state_compute_current_step (it only emits the 9 file-backed steps).
  # If state.json's current_step contains "replan", we have proof that
  # the value flowed from the mock, NOT from any inline computation.
  #
  # T24 update: the original test used "T19-DELEGATED-MARKER" which is
  # now correctly rejected by the post-T24 allowlist. The delegation
  # property the test was designed to verify is preserved by switching
  # to a transition-state sentinel that is allowlisted-but-unreachable.

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

  # Mock returns "replan" — a documented transition state that
  # state_compute_current_step never emits, distinguishing delegation
  # from any inline pipeline-step computation.
  state_compute_current_step() {
    echo "replan"
    return 0
  }

  state_init_or_reconcile "$artifact_dir" > /dev/null

  local json
  json=$(state_read)

  [[ "$json" == *'"current_step":"replan"'* ]] || {
    echo "FAIL: state_init_or_reconcile did not delegate; got JSON: $json" >&2
    return 1
  }
}

# ============================================================================
# [T24] state.sh hardening: current_step allowlist + phase_start_commit preserve
#       + flock TOCTOU serialization
# ============================================================================
# Source-of-truth references:
#   - Allowlist (12 values): the 9 file-backed pipeline steps emitted by the
#     hook layer (goals, questions, research, design, phasing, structure, plan,
#     implement, test) PLUS the 3 transition states documented in
#     skills/using-qrspi/SKILL.md:223 (parallelize, integrate, replan). External
#     writers (Implement, Replan) persist transition states even though
#     state_compute_current_step never emits them.
#   - phase_start_commit preserve: state.sh:107 hardcodes null on every
#     reconcile call. Must read existing state and preserve a non-null value.
#   - flock TOCTOU: state_write_atomic must serialize concurrent callers via
#     a portable file lock primitive (flock when present; mkdir-mutex
#     fallback on macOS where flock(1) is absent).

# ---- T24-A: current_step allowlist on state_write_atomic ----

@test "[T24-A1] state_write_atomic: out-of-allowlist current_step returns non-zero, leaves state.json unchanged" {
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir"
  cd "$artifact_dir"

  source "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"

  # Seed a valid baseline state.json
  state_write_atomic '{"version":1,"current_step":"goals"}'
  local baseline
  baseline=$(cat "$artifact_dir/.qrspi/state.json")

  # Attempt write with bogus current_step
  run state_write_atomic '{"version":1,"current_step":"BOGUS_STEP_XYZ"}'
  [ "$status" -ne 0 ]
  [[ "$output" == *"current_step"* ]] || [[ "$output" == *"allowlist"* ]] || [[ "$output" == *"invalid"* ]]

  # File contents unchanged
  local after
  after=$(cat "$artifact_dir/.qrspi/state.json")
  [[ "$after" == "$baseline" ]]
}

@test "[T24-A2] state_write_atomic: every documented current_step value is accepted (12-value enum round-trip)" {
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir"
  cd "$artifact_dir"

  source "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"

  local v
  for v in goals questions research design phasing structure plan parallelize implement integrate test replan; do
    run state_write_atomic "{\"version\":1,\"current_step\":\"$v\"}"
    [ "$status" -eq 0 ] || {
      echo "FAIL: state_write_atomic rejected legal current_step=$v (output: $output)" >&2
      return 1
    }
    # Verify on-disk
    local content
    content=$(cat "$artifact_dir/.qrspi/state.json")
    [[ "$content" == *"\"current_step\":\"$v\""* ]] || {
      echo "FAIL: state.json missing current_step=$v after write (content: $content)" >&2
      return 1
    }
  done
}

@test "[T24-A3] state_write_atomic: payload without current_step is accepted (allowlist only constrains the field when present)" {
  # Some callers (e.g., partial state update for wireframe_requested only) may
  # produce a JSON blob that does not include current_step. Allowlist
  # validation must not break those; it must only apply when current_step is
  # present in the payload.
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir"
  cd "$artifact_dir"

  source "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"

  run state_write_atomic '{"version":1,"wireframe_requested":true}'
  [ "$status" -eq 0 ]
}

@test "[T24-A1b] state_write_atomic: allowlist cannot be bypassed via JSON unicode-escape of current_step key" {
  # Round-2 silent-failure-hunter finding 1 + security-reviewer finding 2:
  # the allowlist gate must not be implemented as a raw substring match
  # for `"current_step"`, because JSON permits escaped key names. The
  # payload `{"current_step":"BOGUS"}` parses as a real `current_step`
  # key but fails a literal substring check. After fix-cycle 2, allowlist
  # validation uses jq -r '.current_step // empty' on the parsed payload,
  # so escaped-key bypass is closed.
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir"
  cd "$artifact_dir"

  source "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"

  # Seed a known-good baseline
  state_write_atomic '{"version":1,"current_step":"goals"}'
  local baseline
  baseline=$(cat "$artifact_dir/.qrspi/state.json")

  # Attempt allowlist bypass via unicode escape on the key
  run state_write_atomic '{"version":1,"current_step":"BOGUS_STEP_XYZ"}'
  [ "$status" -ne 0 ]

  # Baseline must be unchanged
  local after
  after=$(cat "$artifact_dir/.qrspi/state.json")
  [[ "$after" == "$baseline" ]]
}

@test "[T24-A4] state_init_or_reconcile rejects when delegated helper returns out-of-allowlist value" {
  # Defense in depth: if state_compute_current_step is mutated/shadowed to
  # return something not in the allowlist, state_init_or_reconcile must fail
  # closed (returning non-zero, writing nothing) rather than persist garbage.
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir"
  cd "$TEST_DIR"

  source "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"

  # Shadow the helper to return a bogus value
  state_compute_current_step() {
    echo "BOGUS_STEP_XYZ"
    return 0
  }

  rm -f "$TEST_DIR/.qrspi/state.json"
  run state_init_or_reconcile "$artifact_dir"
  [ "$status" -ne 0 ]
  [ ! -f "$TEST_DIR/.qrspi/state.json" ]
}

# ---- T24-B: phase_start_commit preserve across reconcile ----

@test "[T24-B1] state_init_or_reconcile preserves non-null phase_start_commit when state.json already exists" {
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir"
  cd "$TEST_DIR"

  create_artifact "$artifact_dir/goals.md" "approved"

  source "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"

  # First reconcile: phase_start_commit starts null
  state_init_or_reconcile "$artifact_dir"
  local existing
  existing=$(state_read)
  local before_psc
  before_psc=$(echo "$existing" | jq -r '.phase_start_commit')
  [[ "$before_psc" == "null" ]]

  # Plan's narrow direct-write sets phase_start_commit on the in-place file
  local updated
  updated=$(echo "$existing" | jq '.phase_start_commit = "abc123def456"')
  state_write_atomic "$updated"

  # Confirm seed took effect
  local seeded
  seeded=$(state_read | jq -r '.phase_start_commit')
  [[ "$seeded" == "abc123def456" ]]

  # Now reconcile again — must NOT wipe phase_start_commit
  state_init_or_reconcile "$artifact_dir"
  local after
  after=$(state_read | jq -r '.phase_start_commit')
  [[ "$after" == "abc123def456" ]] || {
    echo "FAIL: phase_start_commit wiped by state_init_or_reconcile (got: $after)" >&2
    return 1
  }
}

@test "[T24-B2] state_init_or_reconcile initializes phase_start_commit to null when state.json does not exist (existing behavior preserved)" {
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir"
  cd "$TEST_DIR"

  source "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"

  # Ensure no prior state
  rm -f "$TEST_DIR/.qrspi/state.json"

  state_init_or_reconcile "$artifact_dir"
  local psc
  psc=$(state_read | jq -r '.phase_start_commit')
  [[ "$psc" == "null" ]]
}

@test "[T24-B3] state_init_or_reconcile preserves phase_start_commit even when reconciling other field changes (artifact statuses)" {
  # Stress: artifact frontmatter changes (which trigger reconcile) must not
  # wipe phase_start_commit alongside the legitimate status update.
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir"
  cd "$TEST_DIR"

  source "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"

  create_artifact "$artifact_dir/goals.md" "draft"
  state_init_or_reconcile "$artifact_dir"

  # Seed phase_start_commit
  local seeded
  seeded=$(state_read | jq '.phase_start_commit = "deadbeef00"')
  state_write_atomic "$seeded"

  # Approve goals.md and reconcile
  create_artifact "$artifact_dir/goals.md" "approved"
  state_init_or_reconcile "$artifact_dir"

  # Status reconciled, phase_start_commit preserved
  local final
  final=$(state_read)
  [[ "$final" == *'"goals":"approved"'* ]]
  local psc
  psc=$(echo "$final" | jq -r '.phase_start_commit')
  [[ "$psc" == "deadbeef00" ]]
}

# ---- T24-C: flock / TOCTOU serialization on state_write_atomic ----

@test "[T24-C1] state_write_atomic + state_init_or_reconcile: concurrent reconcile vs direct-write race preserves phase_start_commit (TOCTOU serialization)" {
  # Threat model from R2 S-N4: Plan's narrow-direct-write sets
  # phase_start_commit while PostToolUse hook reconciliation runs. Both
  # callers do read-modify-write on .qrspi/state.json. Without serialization,
  # the reconciler reads BEFORE the direct write, then overwrites it AFTER —
  # silently destroying phase_start_commit.
  #
  # This test races N reconcile calls (which now read+preserve
  # phase_start_commit) against N direct-writes setting phase_start_commit.
  # With proper flock/lock, the final state must contain the most-recent
  # phase_start_commit value (no R-M-W tearing).
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir"
  cd "$TEST_DIR"

  create_artifact "$artifact_dir/goals.md" "approved"

  source "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"

  # Initial reconcile to seed state.json with phase_start_commit=null
  state_init_or_reconcile "$artifact_dir"

  # Background process A: continuously call state_init_or_reconcile (read +
  # rebuild + write). Each call MUST preserve phase_start_commit.
  # NOTE: set +e + `|| true` ensures the subshell exits 0 regardless of
  # individual iteration outcome — we measure global state correctness
  # below, not per-iteration success rate.
  ( set +e
    for i in $(seq 1 30); do
      state_init_or_reconcile "$artifact_dir" 2>/dev/null || true
    done
    exit 0 ) &
  local pid_a=$!

  # Background process B: continuously direct-write phase_start_commit.
  # Pattern: each iteration reads current state, sets phase_start_commit,
  # writes via state_write_atomic (mirrors Plan's narrow-direct-write).
  ( set +e
    for i in $(seq 1 30); do
      current=$(state_read 2>/dev/null) || continue
      updated=$(echo "$current" | jq ".phase_start_commit = \"commit-iter-$i\"" 2>/dev/null) || continue
      state_write_atomic "$updated" 2>/dev/null || true
    done
    exit 0 ) &
  local pid_b=$!

  wait "$pid_a" || true
  wait "$pid_b" || true

  # File must be valid JSON (atomic mv guarantees this; included as sanity)
  local final
  final=$(cat "$TEST_DIR/.qrspi/state.json")
  echo "$final" | jq . > /dev/null || {
    echo "FAIL: state.json is not valid JSON after concurrent R-M-W (content: $final)" >&2
    return 1
  }

  # Critical assertion: phase_start_commit must be one of writer-B's values,
  # NOT null. If reconciler raced and won the last write, it would have
  # wiped phase_start_commit because the snapshot it read was stale.
  # Under proper locking, every reconciler read+write is atomic w.r.t.
  # writer-B's writes, so the last-writer-wins value of phase_start_commit
  # is whichever caller wrote last — and BOTH (when locked) preserve the
  # commit value (writer-B sets it; reconciler now preserves it).
  local psc
  psc=$(echo "$final" | jq -r '.phase_start_commit')
  [[ "$psc" =~ ^commit-iter-[0-9]+$ ]] || {
    echo "FAIL: phase_start_commit is '$psc' — expected 'commit-iter-N'. TOCTOU race destroyed value." >&2
    echo "Final state: $final" >&2
    return 1
  }
}

@test "[T24-C2] state_write_atomic: lock is released even on validation failure (no deadlock)" {
  # If allowlist rejection or other validation failure leaves the lock held,
  # subsequent legitimate writers would block forever. This test runs an
  # invalid write (allowlist rejection) followed by a valid write and
  # asserts the second one completes promptly.
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir"
  cd "$artifact_dir"

  source "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"

  # Seed valid baseline so the rejected write has something to compare against
  state_write_atomic '{"version":1,"current_step":"goals"}'

  run state_write_atomic '{"version":1,"current_step":"NOT_A_STEP"}'
  [ "$status" -ne 0 ]

  # Now legitimate write must complete (would hang if lock held)
  run timeout 5 bash -c "
    source '$BATS_TEST_DIRNAME/../../hooks/lib/state.sh'
    state_write_atomic '{\"version\":1,\"current_step\":\"questions\"}'
  "
  [ "$status" -eq 0 ]
  local final
  final=$(cat "$artifact_dir/.qrspi/state.json")
  [[ "$final" == *'"current_step":"questions"'* ]]
}

@test "[T24-C1b] state_update: two concurrent R-M-W writers — last-writer-wins on protected field, unrelated fields preserved (literal spec test expectation)" {
  # Spec finding R2 S-N4 test expectation, verbatim: "two concurrent
  # state_write_atomic calls (simulated via background process) produce a
  # deterministic last-writer-wins on the protected field; neither write
  # tears or loses unrelated fields."
  #
  # The spec's recommendation 2 says: "convert to a JSON-merge that
  # re-reads under lock." That is the new state_update API — read-modify-
  # write under lock via a jq filter. This test exercises state_update,
  # which is the spec-compliant primitive for serialized R-M-W.
  # state_write_atomic by itself only protects torn writes (atomic mv);
  # callers that R-M-W via state_write_atomic must use state_update or
  # acquire the lock externally.
  #
  # Test design: two callers each mutate a different field via
  # state_update. Without serialization, each writer's R-M-W window is
  # open and the other's prior write is lost when its snapshot was stale.
  # Under proper locking, both fields persist (each writer reads the most
  # recent committed state before its update).
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir"
  cd "$artifact_dir"

  source "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"

  # Seed baseline with both fields present
  state_write_atomic '{"version":1,"current_step":"goals","phase_start_commit":null,"writer_a_field":"initial"}'

  # Writer A: updates writer_a_field via state_update (read+modify+write
  # all serialized under lock). Each iteration sets writer_a_field=A-iter-N.
  ( set +e
    for i in $(seq 1 30); do
      state_update ".writer_a_field = \"A-iter-$i\"" 2>/dev/null || true
    done
    exit 0 ) &
  local pid_a=$!

  # Writer B: updates phase_start_commit via state_update.
  ( set +e
    for i in $(seq 1 30); do
      state_update ".phase_start_commit = \"B-iter-$i\"" 2>/dev/null || true
    done
    exit 0 ) &
  local pid_b=$!

  wait "$pid_a" || true
  wait "$pid_b" || true

  # Validate no torn JSON
  local final
  final=$(cat "$artifact_dir/.qrspi/state.json")
  echo "$final" | jq . > /dev/null || {
    echo "FAIL: state.json torn under concurrent state_update (content: $final)" >&2
    return 1
  }

  # phase_start_commit must be one of B's values (B was the only writer
  # of that field after the seed).
  local final_psc
  final_psc=$(echo "$final" | jq -r '.phase_start_commit')
  [[ "$final_psc" =~ ^B-iter-[0-9]+$ ]] || {
    echo "FAIL: phase_start_commit lost — expected 'B-iter-N', got '$final_psc'. Concurrent R-M-W race destroyed the field." >&2
    echo "Final state: $final" >&2
    return 1
  }

  # writer_a_field must be one of A's values (A was the only writer after
  # the seed). If it's still "initial", writer A's updates were
  # overwritten by stale snapshots from writer B — exactly the TOCTOU
  # bug the spec is fixing.
  local final_waf
  final_waf=$(echo "$final" | jq -r '.writer_a_field')
  [[ "$final_waf" =~ ^A-iter-[0-9]+$ ]] || {
    echo "FAIL: writer_a_field lost — expected 'A-iter-N', got '$final_waf'. Concurrent R-M-W race destroyed the unrelated field (this is the bug R2 S-N4 fixes)." >&2
    echo "Final state: $final" >&2
    return 1
  }
}

@test "[T24-C1c] state_init_or_reconcile racing state_update preserves the latest phase_start_commit (round-2 spec finding)" {
  # Round-2 spec-reviewer finding (blocker): the round-1 fix moved the
  # lock inside state_write_atomic, but state_init_or_reconcile was
  # still reading phase_start_commit OUTSIDE the lock. A concurrent
  # state_update could commit a newer phase_start_commit between the
  # read and the write, and reconcile would silently overwrite it.
  # Fix-cycle 2 brings the read AND the rebuild+write under the same
  # lock that state_update uses. This test exercises that end-to-end.
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir"
  cd "$TEST_DIR"

  create_artifact "$artifact_dir/goals.md" "approved"

  source "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"

  # Seed initial state
  state_init_or_reconcile "$artifact_dir"

  # Race: process A repeatedly calls state_init_or_reconcile (full
  # rebuild path); process B repeatedly state_updates phase_start_commit.
  ( set +e
    for i in $(seq 1 20); do
      state_init_or_reconcile "$artifact_dir" 2>/dev/null || true
    done
    exit 0 ) &
  local pid_a=$!

  ( set +e
    for i in $(seq 1 20); do
      state_update ".phase_start_commit = \"reconcile-race-$i\"" 2>/dev/null || true
    done
    exit 0 ) &
  local pid_b=$!

  wait "$pid_a" || true
  wait "$pid_b" || true

  # Final state must be valid JSON and must contain one of B's
  # phase_start_commit values — NOT null. If reconcile (A) won the last
  # write but had a stale snapshot, phase_start_commit would be null.
  local final
  final=$(cat "$TEST_DIR/.qrspi/state.json")
  echo "$final" | jq . > /dev/null || {
    echo "FAIL: state.json torn (content: $final)" >&2
    return 1
  }

  local final_psc
  final_psc=$(echo "$final" | jq -r '.phase_start_commit')
  [[ "$final_psc" =~ ^reconcile-race-[0-9]+$ ]] || {
    echo "FAIL: phase_start_commit=$final_psc — reconcile race destroyed the value (expected reconcile-race-N)." >&2
    echo "Final: $final" >&2
    return 1
  }
}

@test "[T24-B4] state_init_or_reconcile fails closed when existing state.json is corrupt JSON (does not silently overwrite)" {
  # Round-2 silent-failure-hunter finding 2: phase_start_commit
  # preservation must not silently destroy the value when existing
  # state.json is unparseable. Fix-cycle 2 changes the behavior to
  # fail-closed: refuse to overwrite a corrupt state file rather than
  # silently dropping its phase_start_commit.
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir"
  cd "$TEST_DIR"

  create_artifact "$artifact_dir/goals.md" "draft"

  source "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"

  # Place a corrupt state.json
  mkdir -p "$TEST_DIR/.qrspi"
  printf 'this is not valid JSON' > "$TEST_DIR/.qrspi/state.json"
  local before
  before=$(cat "$TEST_DIR/.qrspi/state.json")

  run state_init_or_reconcile "$artifact_dir"
  [ "$status" -ne 0 ]
  [[ "$output" == *"corrupt"* ]] || [[ "$output" == *"refusing"* ]] || [[ "$output" == *"jq parse failed"* ]]

  # Corrupt file must remain unchanged (no silent overwrite)
  local after
  after=$(cat "$TEST_DIR/.qrspi/state.json")
  [[ "$after" == "$before" ]]
}

@test "[T24-Sec1] _state_lock_acquire_flock refuses to follow a pre-existing symlink at the lock path" {
  # Round-2 security-reviewer finding 1: flock variant truncates lock
  # file via `: > "$lock_file"` without symlink defense, giving an
  # arbitrary file-clobber primitive if .qrspi/state.json.lock is a
  # pre-placed symlink. Fix-cycle 2 adds symlink detect-and-remove
  # guarding the touch.
  if ! command -v flock >/dev/null 2>&1; then
    skip "flock not available on this host (mkdir-mutex fallback in use); test does not apply"
  fi

  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir"
  cd "$artifact_dir"

  source "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"

  # Pre-place .qrspi/ + symlinked lock file pointing at a sentinel target
  mkdir -p "$artifact_dir/.qrspi"
  local target="$TEST_DIR/symlink-target.txt"
  echo "DO_NOT_CLOBBER" > "$target"
  ln -sf "$target" "$artifact_dir/.qrspi/state.json.lock"

  # Trigger a write — should not truncate the symlink target.
  run state_write_atomic '{"version":1,"current_step":"goals"}'

  # Either the write succeeded (and the symlink was replaced with a
  # regular file) OR it refused the symlink (returns non-zero with
  # diagnostic). Either way, the target file must NOT be truncated.
  local target_content
  target_content=$(cat "$target")
  [[ "$target_content" == "DO_NOT_CLOBBER" ]] || {
    echo "FAIL: symlink target was clobbered (now: '$target_content')" >&2
    return 1
  }
}

@test "[T24-C3] state_write_atomic: serialization across distinct shells (lock is filesystem-backed, not process-local)" {
  # A subshell launched separately must observe the same lock. If the lock
  # is implemented as a process-local construct (e.g., a bash variable), it
  # provides no protection across distinct shell invocations. Use a long-
  # running first writer (held inside the critical section briefly via a
  # CPU loop) and verify the second observes correct state.
  local artifact_dir="$TEST_DIR/artifacts"
  mkdir -p "$artifact_dir"
  cd "$artifact_dir"

  source "$BATS_TEST_DIRNAME/../../hooks/lib/state.sh"

  # Seed
  state_write_atomic '{"version":1,"current_step":"goals"}'

  # Launch 5 background bash subshells, each doing 20 writes.
  # NOTE: `set +e` + `|| true` so the subshell exits 0 regardless of
  # individual iteration outcome.
  local i
  local pids=()
  for i in 1 2 3 4 5; do
    bash -c "
      set +e
      source '$BATS_TEST_DIRNAME/../../hooks/lib/state.sh'
      cd '$artifact_dir'
      for n in \$(seq 1 20); do
        state_write_atomic '{\"version\":1,\"current_step\":\"plan\",\"writer\":'\$\$'}' 2>/dev/null || true
      done
      exit 0
    " &
    pids+=($!)
  done

  for pid in "${pids[@]}"; do wait "$pid" || true; done

  # File must remain valid JSON
  local final
  final=$(cat "$artifact_dir/.qrspi/state.json")
  echo "$final" | jq . > /dev/null || {
    echo "FAIL: state.json torn under cross-shell contention (content: $final)" >&2
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
