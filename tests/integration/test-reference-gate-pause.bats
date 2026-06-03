#!/usr/bin/env bats
bats_require_minimum_version 1.5.0

# T30 (pin 5 of 5) — G10: Slice 5 reference-gate cross-skill integration pin.
#
# Exercises the cross-skill flow end-to-end against a seeded fixture plan:
#   - Parallelize-skill wave-termination rule (T26): a task carrying
#     reference_gate: true ends its Wave; dependents land in the next Wave;
#     parallelization.md carries the canonical `Reference gate: task-NN
#     ({name}) — dependents waiting: task-XX, ...` note.
#   - Implement-skill reference-gate pause (T27): dependents do not dispatch
#     until the approval file at `reviews/tasks/task-NN/reference-gate.md`
#     is recorded; a bypass attempt (dispatch before the file exists) is
#     blocked with the named `reference-gate-bypass:` diagnostic.
#
# This is the integration-tier pin (a real cross-skill exercise rather than
# a single-file markdown-section assertion). It assembles a fixture plan +
# parallelization.md on disk in a tmpdir, then asserts the documented
# contracts observably hold across skills/parallelize/SKILL.md and
# skills/implement/SKILL.md — including the canonical artifact paths,
# diagnostic strings, and ordering invariants the cross-skill flow depends on.
#
# Bash 3.2 portable. No live subagent dispatch; the integration boundary is
# the contract-shape integration (artifact-path + diagnostic naming) across
# the two skills, asserted against a fixture plan a runtime orchestrator
# would consume.

load '../helpers/skill-markdown'

setup_file() {
  require_repo_root
  PARALLELIZE_SKILL="$REPO_ROOT/skills/parallelize/SKILL.md"
  IMPLEMENT_SKILL="$REPO_ROOT/skills/implement/SKILL.md"
  PLAN_SKILL="$REPO_ROOT/skills/plan/SKILL.md"
  USING_QRSPI_SKILL="$REPO_ROOT/skills/using-qrspi/SKILL.md"
  PLAN_REVIEWER_AGENT="$REPO_ROOT/agents/qrspi-plan-reviewer.md"
  export PARALLELIZE_SKILL IMPLEMENT_SKILL PLAN_SKILL USING_QRSPI_SKILL PLAN_REVIEWER_AGENT
}

setup() {
  FIXTURE_DIR="$(mktemp -d)"
  export FIXTURE_DIR
  mkdir -p "$FIXTURE_DIR/tasks"
  mkdir -p "$FIXTURE_DIR/reviews/tasks/task-03"

  # Seed a reference-gated task spec.
  cat > "$FIXTURE_DIR/tasks/task-03.md" <<'EOF'
---
task: 3
status: approved
pipeline: full
task_type: code
model: sonnet
phase: 1
goal_ids: [G10]
dependencies: [T01, T02]
reference_gate: true
reference_artifact: reference/adapter-shape.png
loc_estimate: 80
---

# Task 3: Adapter contract doc (reference gate)
EOF

  # Seed a dependent task spec.
  cat > "$FIXTURE_DIR/tasks/task-04.md" <<'EOF'
---
task: 4
status: approved
pipeline: full
task_type: code
model: sonnet
phase: 1
goal_ids: [G10]
dependencies: [T03]
loc_estimate: 60
---

# Task 4: Apply adapter contract
EOF

  # Seed a parallelization.md carrying the canonical reference-gate note.
  cat > "$FIXTURE_DIR/parallelization.md" <<'EOF'
---
status: approved
---

## Branch Map

| Task | Dependencies | Files | Wave |
|------|--------------|-------|------|
| Task 1 | (none) | a.md | Wave 1 |
| Task 2 | (none) | b.md | Wave 1 |
| Task 3 | Task 1, Task 2 | c.md | Wave 2 (reference_gate: true) |
| Task 4 | Task 3 | d.md | Wave 3 |

Reference gate: task-03 (Adapter contract doc) — dependents waiting: task-04
EOF
}

teardown() {
  rm -rf "$FIXTURE_DIR"
}

# =============================================================================
# T26: Parallelize wave-termination rule + canonical note
# =============================================================================

@test "[T30-rg-pause] Parallelize documents reference_gate wave-termination rule" {
  extract_and_grep "$PARALLELIZE_SKILL" H2 "Branch Model (Symbolic — Resolved by Implement)" \
    "[Rr]eference-gate wave termination"
}

@test "[T30-rg-pause] Parallelize names dependents land in next Wave at the earliest" {
  extract_and_grep "$PARALLELIZE_SKILL" H2 "Branch Model (Symbolic — Resolved by Implement)" \
    "next Wave"
}

@test "[T30-rg-pause] Parallelize template documents canonical Reference-gate note shape" {
  extract_and_grep "$PARALLELIZE_SKILL" H2 "Artifact" \
    "Reference gate: task-NN"
}

@test "[T30-rg-pause] Parallelize Red Flags catches missing canonical note" {
  extract_and_grep "$PARALLELIZE_SKILL" H2 "Red Flags — STOP" \
    "reference_gate: true.*Reference gate: task-NN"
}

@test "[T30-rg-pause] Parallelize Red Flags catches dependent in same Wave as gate" {
  extract_and_grep "$PARALLELIZE_SKILL" H2 "Red Flags — STOP" \
    "same [Ww]ave"
}

# =============================================================================
# Fixture plan carries canonical note for the gated task
# =============================================================================

@test "[T30-rg-pause] Fixture parallelization.md emits canonical Reference-gate note for task-03" {
  grep -E "^Reference gate: task-03 \(Adapter contract doc\) — dependents waiting: task-04$" \
    "$FIXTURE_DIR/parallelization.md"
}

@test "[T30-rg-pause] Fixture task-03 carries reference_gate + reference_artifact pair" {
  grep -E "^reference_gate: true$" "$FIXTURE_DIR/tasks/task-03.md"
  grep -E "^reference_artifact: " "$FIXTURE_DIR/tasks/task-03.md"
}

# =============================================================================
# T27: Implement reference-gate pause names approval-file path + bypass diagnostic
# =============================================================================

@test "[T30-rg-pause] Implement names canonical approval file path reviews/tasks/task-NN/reference-gate.md" {
  extract_and_grep "$IMPLEMENT_SKILL" H3 "Reference-Gate Human Pause (per-task DONE handling)" \
    "reviews/tasks/task-NN/reference-gate.md"
}

@test "[T30-rg-pause] Implement requires explicit reference approved confirmation" {
  extract_and_grep "$IMPLEMENT_SKILL" H3 "Reference-Gate Human Pause (per-task DONE handling)" \
    "reference approved"
}

@test "[T30-rg-pause] Implement names reference-gate-bypass diagnostic on bypass attempt" {
  extract_and_grep "$IMPLEMENT_SKILL" H3 "Reference-Gate Human Pause (per-task DONE handling)" \
    "reference-gate-bypass"
}

@test "[T30-rg-pause] Implement bypass diagnostic names blocked-dependent field" {
  extract_and_grep "$IMPLEMENT_SKILL" H3 "Reference-Gate Human Pause (per-task DONE handling)" \
    "blocked-dependent=task-MM"
}

@test "[T30-rg-pause] Implement records approval with timestamp, run_slug, task_id, reference_artifact" {
  extract_and_grep "$IMPLEMENT_SKILL" H3 "Reference-Gate Human Pause (per-task DONE handling)" \
    "timestamp"
  extract_and_grep "$IMPLEMENT_SKILL" H3 "Reference-Gate Human Pause (per-task DONE handling)" \
    "run_slug"
  extract_and_grep "$IMPLEMENT_SKILL" H3 "Reference-Gate Human Pause (per-task DONE handling)" \
    "task_id"
  extract_and_grep "$IMPLEMENT_SKILL" H3 "Reference-Gate Human Pause (per-task DONE handling)" \
    "approver_acknowledgment"
}

# =============================================================================
# Bypass simulation: dependent dispatch attempted without approval file present
# =============================================================================
#
# The fixture stages task-03 (reference_gate: true) and task-04 (depends on T03)
# WITHOUT writing reviews/tasks/task-03/reference-gate.md. Per T27's pause
# contract, an orchestrator MUST NOT dispatch task-04 until that file exists.
# This pin asserts the bypass-detection contract is observable from the fixture
# state: the approval file does not exist, and the documented Implement-skill
# diagnostic names the precondition (`approval-file-absent`).

@test "[T30-rg-pause] Bypass simulation: approval file is absent in fixture state" {
  [ ! -e "$FIXTURE_DIR/reviews/tasks/task-03/reference-gate.md" ]
}

@test "[T30-rg-pause] Implement diagnostic names approval-file-absent as bypass reason" {
  extract_and_grep "$IMPLEMENT_SKILL" H3 "Reference-Gate Human Pause (per-task DONE handling)" \
    "approval-file-absent"
}

# =============================================================================
# Approval simulation: writing the approval file releases the pause
# =============================================================================

@test "[T30-rg-pause] Approval simulation: writing reference-gate.md satisfies path-existence precondition" {
  cat > "$FIXTURE_DIR/reviews/tasks/task-03/reference-gate.md" <<'EOF'
timestamp: 2026-05-19T00:00:00Z
run_slug: t30-fixture
task_id: 3
reference_artifact: reference/adapter-shape.png
approver_acknowledgment: "reference approved"
EOF
  [ -e "$FIXTURE_DIR/reviews/tasks/task-03/reference-gate.md" ]
  grep -F 'approver_acknowledgment: "reference approved"' \
    "$FIXTURE_DIR/reviews/tasks/task-03/reference-gate.md"
}

# =============================================================================
# Coordination: reference-gate pause coordinates with ui:true visual-fidelity
# dispatch — the gate fires at DONE before any dependent (including sibling
# UI tasks in later waves) is dispatched.
# =============================================================================

@test "[T30-rg-pause] Implement coordinates reference-gate with ui:true visual-fidelity dispatch" {
  extract_and_grep "$IMPLEMENT_SKILL" H3 "Reference-Gate Human Pause (per-task DONE handling)" \
    "ui: true"
}

# =============================================================================
# G15: Plan Sweep Task Contract — dependent_tests: scope at plan time
# =============================================================================
#
# Pins that the Plan skill, Plan reviewer agent, and shared pipeline guidance
# carry the sweep-task contract surface that closes the v0.7.1 stale-test
# integration gap. The pins are file-content + section-extract assertions —
# the sweep contract is documentation + reviewer rubric, not runtime code.

@test "[G15-sweep] Plan SKILL Test Expectations section carries Sweep Task Contract subsection" {
  extract_and_grep "$PLAN_SKILL" H2 "Test Expectations" \
    "### Sweep Task Contract"
}

@test "[G15-sweep] Plan SKILL Sweep Task Contract defines sweep task" {
  extract_and_grep "$PLAN_SKILL" H3 "Sweep Task Contract" \
    "[Ss]weep task"
}

@test "[G15-sweep] Plan SKILL Sweep Task Contract names the dependent_tests: field" {
  extract_and_grep "$PLAN_SKILL" H3 "Sweep Task Contract" \
    "dependent_tests:"
}

@test "[G15-sweep] Plan SKILL Sweep Task Contract documents the path-list shape" {
  extract_and_grep "$PLAN_SKILL" H3 "Sweep Task Contract" \
    "list of test file paths"
}

@test "[G15-sweep] Plan SKILL Sweep Task Contract documents the none + grep proof shape" {
  extract_and_grep "$PLAN_SKILL" H3 "Sweep Task Contract" \
    "dependent_tests: none"
  extract_and_grep "$PLAN_SKILL" H3 "Sweep Task Contract" \
    "grep -rn -- '.+' tests/"
}

@test "[G15-sweep] Plan SKILL Sweep Task Contract carries worked example with explicit path list" {
  extract_and_grep "$PLAN_SKILL" H3 "Sweep Task Contract" \
    "tests/.+\\.bats"
}

@test "[G15-sweep] Plan SKILL Sweep Task Contract carries worked example with none + grep" {
  # The grep example must use the literal `tests/` directory argument so the
  # reviewer can re-run the exact command shape the contract specifies.
  # Updated in R4: canonical shape now includes the -- argument separator.
  extract_and_grep "$PLAN_SKILL" H3 "Sweep Task Contract" \
    "grep -rn -- '\\^model:' tests/"
}

@test "[G15-sweep] Plan reviewer agent body declares sweep-task detection rubric" {
  grep -E "[Ss]weep-task detection" "$PLAN_REVIEWER_AGENT"
}

@test "[G15-sweep] Plan reviewer agent body uses strict >5 same-extension threshold" {
  # Strict greater-than five files of the same extension — the design pins
  # the >5 boundary deliberately (not >=5) so a 5-file task does NOT trip.
  grep -E ">5|more than (five|5)|strictly greater than (five|5)" "$PLAN_REVIEWER_AGENT"
}

@test "[G15-sweep] Plan reviewer agent body lists the eight sweep keywords" {
  # Section-scoped: verify each keyword appears inside the Sweep-task detection
  # rubric itself, not just anywhere in the file (prevents false-positive from
  # counter-example or other section mentions).
  for kw in all every strip remove rename replace delete sweep; do
    extract_and_grep "$PLAN_REVIEWER_AGENT" H3 "Sweep-task detection" "\`$kw\`" || {
      echo "Missing sweep keyword in Sweep-task detection section: $kw" >&2
      return 1
    }
  done
}

@test "[G15-sweep] Plan reviewer agent body specifies case-insensitive word-boundary matching" {
  grep -E "case-insensitive" "$PLAN_REVIEWER_AGENT"
  grep -E "word-boundary" "$PLAN_REVIEWER_AGENT"
}

@test "[G15-sweep] Plan reviewer agent body emits high-severity correctness finding for missing dependent_tests:" {
  # Missing `dependent_tests:` on a sweep-shaped task is a plan-spec defect —
  # the reviewer surfaces a `severity: high, change_type: correctness` finding.
  grep -E "severity: high" "$PLAN_REVIEWER_AGENT"
  grep -E "change_type: correctness" "$PLAN_REVIEWER_AGENT"
}

@test "[G15-sweep] Plan reviewer agent body covers malformed dependent_tests: variants" {
  # Malformed shapes named in the contract: missing-field, no paths,
  # `none` without a grep command, and `none` with a grep returning >=1 hit.
  grep -E "[Mm]issing.*field|missing.*\`dependent_tests" "$PLAN_REVIEWER_AGENT"
  grep -E "[Mm]alformed|no paths|no .none." "$PLAN_REVIEWER_AGENT"
  grep -E "(returns? )?(>=|≥|>= ?1|one or more|≥ ?1) hit" "$PLAN_REVIEWER_AGENT"
}

@test "[G15-sweep] using-qrspi SKILL backstop note routes sweep findings through normal Plan re-spec loop" {
  grep -E "[Ss]weep" "$USING_QRSPI_SKILL"
  grep -E "[Pp]lan re-spec|plan review.*re-spec|normal [Pp]lan review" "$USING_QRSPI_SKILL"
}

@test "[G15-sweep] using-qrspi SKILL backstop note disclaims a new gate / runner change" {
  # The backstop must explicitly state no new implementation gate or
  # test-runner behavior is introduced — sweep findings ride the existing loop.
  grep -E "[Nn]o new (implementation )?gate|without (a )?new gate|no test-runner" "$USING_QRSPI_SKILL"
}

@test "[G15-sweep] Plan reviewer agent word-boundary example uses valid prefix-extension (removes, not removal)" {
  # `removes` IS a prefix-extension of `remove` — \bremove matches it.
  # `removal` is NOT (diverges at char 6) — using `removal` as the positive
  # example is factually wrong and would encourage over-broad stem matching.
  extract_and_grep "$PLAN_REVIEWER_AGENT" H3 "Sweep-task detection" \
    "\`removes\`.*match.*\`remove\`|\`remove\`.*\`removes\`"
}

@test "[G15-sweep] Plan reviewer agent grep-proof rubric validates command shape before execution" {
  # Security: the rubric must say to validate the command first, not execute
  # verbatim from untrusted plan.md (prevents shell injection via dependent_tests:).
  extract_and_grep "$PLAN_REVIEWER_AGENT" H3 "Sweep-task detection" \
    "[Vv]alidat"
}

@test "[G15-sweep] Plan reviewer agent grep-proof rubric names the rejected shell metacharacters" {
  # Threat model must be visible: the rubric must name the metacharacters that
  # are forbidden in the grep pattern argument so future reviewers can enforce it.
  # Tightened in R4: assert the three highest-risk characters are explicitly named,
  # not just that the word "metachar" appears.
  local section
  section="$(extract_section "$PLAN_REVIEWER_AGENT" H3 "Sweep-task detection")"
  for char in ';' '|' '&'; do
    echo "$section" | grep -qF "$char" \
      || { echo "Missing rejected metachar '$char' in Sweep-task detection section" >&2; return 1; }
  done
}

@test "[G15-sweep] Plan reviewer agent grep-proof rubric explicitly names single-quote as rejected" {
  # Defense-in-depth: single-quote enables extra-path injection (F01 sec-claude).
  # The rubric must explicitly name single-quote in its forbidden-character list
  # (not just use it as a shell delimiter in examples).
  extract_and_grep "$PLAN_REVIEWER_AGENT" H3 "Sweep-task detection" \
    "single.quote"
}

@test "[G15-sweep] Plan reviewer agent grep-proof rubric requires -- argument separator" {
  # Flag-injection hardening (F01 sec-codex): the rubric must require the --
  # argument separator between -rn and the quoted pattern so flag-shaped
  # patterns cannot be passed to grep as options.
  extract_and_grep "$PLAN_REVIEWER_AGENT" H3 "Sweep-task detection" \
    "-- '"
}

@test "[G15-sweep] Plan reviewer agent grep-proof rubric rejects patterns starting with -" {
  # Defense-in-depth: even with --, a pattern starting with - is almost certainly
  # malformed (not a real test-reference pattern); the rubric must say to reject it.
  extract_and_grep "$PLAN_REVIEWER_AGENT" H3 "Sweep-task detection" \
    "start"
}

@test "[G15-sweep] Plan SKILL Sweep Task Contract prose names tests/ root with <pattern> placeholder" {
  # Pins the literal shape of the zero-match proof command as written in the
  # prose contract — independent of the worked example grep arguments.
  # Updated in R4: canonical shape now includes the -- argument separator.
  extract_and_grep "$PLAN_SKILL" H3 "Sweep Task Contract" \
    "grep -rn -- '<pattern>' tests/"
}
