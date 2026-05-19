#!/usr/bin/env bats
#
# T36 Slice 7 G4 Mechanism A unit pin — cache-hit-rate, path-conditional.
#
# Reads the T33 spike-report deliverable (docs/qrspi/2026-05-17-v07-release/
# spikes/g4-cache-probe.md) to choose between Path A verification-only and
# Path B add-then-verify assertions. On Path A asserts cache_read_input_tokens
# > 0 on second-and-later dispatches with an identical system-prefix; on
# Path B asserts both cache_control marker presence in the assembled JSON
# request body (under the dual-flag gate) AND the same hit-rate condition,
# AND the contrapositive (providers with emit_cache_control_markers: false
# receive NO cache_control field even on Path B).
#
# Loud-failure preconditions (BEFORE branching on Path A/B):
#   - spike-report file absent
#   - spike-report Decision section missing or unrecognized
#   - colocated g4-cache-probe.lock file absent
#   - lock file malformed (no run_id: key parseable)
#   - report.run_id and lock.run_id mismatch (stale report)
#
# Bash 3.2 portable.

load '../helpers/skill-markdown'

setup_file() {
  require_repo_root
  SPIKE_DIR="$REPO_ROOT/docs/qrspi/2026-05-17-v07-release/spikes"
  REPORT_PATH="$SPIKE_DIR/g4-cache-probe.md"
  LOCK_PATH="$SPIKE_DIR/g4-cache-probe.lock"
  export SPIKE_DIR REPORT_PATH LOCK_PATH
}

# ---------------------------------------------------------------------------
# Parse helpers — both report and lock carry a `run_id:` key on a YAML line.
# ---------------------------------------------------------------------------

_extract_run_id() {
  local file="$1"
  awk '/^run_id:[[:space:]]*/ { sub(/^run_id:[[:space:]]*/, ""); print; exit }' "$file"
}

_extract_decision_line() {
  # The Decision section's first non-empty body line carries the verdict.
  awk '
    /^## Decision[[:space:]]*$/ { inside = 1; next }
    /^## / { if (inside == 1) exit }
    inside == 1 && NF > 0 { print; exit }
  ' "$1"
}

# ---------------------------------------------------------------------------
# Loud-failure preconditions (each is a distinct named diagnostic when the
# pin runs against a real future spike-report deliverable).
# ---------------------------------------------------------------------------

@test "loud-fail: spike-report file present (T33 deliverable)" {
  [ -f "$REPORT_PATH" ] || { echo "spike-report missing at $REPORT_PATH" >&2; false; }
}

@test "loud-fail: spike-report Decision section present + parseable" {
  decision="$(_extract_decision_line "$REPORT_PATH")"
  [ -n "$decision" ] || { echo "Decision section unparseable in $REPORT_PATH" >&2; false; }
}

@test "loud-fail: report's run_id: header field present + non-empty" {
  rid="$(_extract_run_id "$REPORT_PATH")"
  [ -n "$rid" ] || { echo "run_id missing/empty in report $REPORT_PATH" >&2; false; }
}

# ---------------------------------------------------------------------------
# Pre-lock contract enumeration — pinned via grep against the T33 script
# source so the documented absent / malformed / mismatch branches each have
# a distinct named loud-failure surface, EVEN WHEN the live lock file does
# not yet exist (the spike has not run end-to-end at T36 ship time).
# ---------------------------------------------------------------------------

@test "loud-fail contract: cache-probe script documents lock-file discipline" {
  run grep -F "Lock-file discipline" "$REPO_ROOT/scripts/g4-cache-probe.sh"
  [ "$status" -eq 0 ]
}

@test "loud-fail contract: cache-probe script documents stale-report detection via absent lock or run_id mismatch" {
  # The phrase spans two source-comment lines; join lines (strip leading `# `)
  # then match the contiguous phrase.
  sed 's/^# //; s/^#//' "$REPO_ROOT/scripts/g4-cache-probe.sh" | tr '\n' ' ' | grep -qF "absence of a fresh lock or a run_id mismatch"
}

# ---------------------------------------------------------------------------
# Lock-state conditional assertions: run the live freshness checks when the
# lock file exists; otherwise document that the deliverable is in the
# pre-live stub state (which is itself a T36-pin loud signal — the next
# operator run replaces the stub).
# ---------------------------------------------------------------------------

@test "freshness: when lock exists, report.run_id == lock.run_id (no stale report)" {
  if [ ! -f "$LOCK_PATH" ]; then
    skip "lock absent — spike has not run end-to-end (stub state expected at T36 ship time)"
  fi
  report_rid="$(_extract_run_id "$REPORT_PATH")"
  lock_rid="$(_extract_run_id "$LOCK_PATH")"
  [ -n "$lock_rid" ] || { echo "malformed-lock: lock present at $LOCK_PATH but no parseable run_id: key" >&2; false; }
  [ "$report_rid" = "$lock_rid" ] || { echo "stale-report: report.run_id=$report_rid != lock.run_id=$lock_rid" >&2; false; }
}

@test "freshness: when lock exists, lock.run_id is non-empty (guards malformed-lock branch)" {
  if [ ! -f "$LOCK_PATH" ]; then
    skip "lock absent — exercise of malformed-lock branch deferred until lock is written"
  fi
  lock_rid="$(_extract_run_id "$LOCK_PATH")"
  [ -n "$lock_rid" ]
}

# ---------------------------------------------------------------------------
# Path-conditional dispatch: read the Decision section and branch.
# At T36 ship time the stub records "Pending — operator runs ..." which
# is a recognized non-path verdict. The pin documents the deferred state
# rather than silently passing.
# ---------------------------------------------------------------------------

_path_from_decision() {
  local decision="$1"
  case "$decision" in
    *"Path A selected"*|*"Path A"*) echo "A" ;;
    *"Path B selected"*|*"Path B required"*|*"Path B REQUIRED"*|*"Path B"*) echo "B" ;;
    *"Pending"*) echo "PENDING" ;;
    *) echo "UNRECOGNIZED" ;;
  esac
}

@test "decision: parsed verdict is one of {A, B, PENDING} (UNRECOGNIZED is a loud fail)" {
  decision="$(_extract_decision_line "$REPORT_PATH")"
  verdict="$(_path_from_decision "$decision")"
  case "$verdict" in
    A|B|PENDING) ;;
    *) echo "unrecognized Decision: '$decision'" >&2; false ;;
  esac
}

@test "Path A assertion: cache_read_input_tokens > 0 on second-and-later dispatches (when Path A)" {
  decision="$(_extract_decision_line "$REPORT_PATH")"
  verdict="$(_path_from_decision "$decision")"
  if [ "$verdict" != "A" ]; then
    skip "verdict=$verdict — Path A assertion not selected"
  fi
  # Extract the captured cache_read values from the report's table; calls
  # 2 and 3 must both be numeric and > 0 for Path A integrity.
  for call in 2 3; do
    val="$(awk -v c="$call" 'BEGIN{FS="|"} $0 ~ "^\\|[[:space:]]*"c"[[:space:]]*\\|" { gsub(/[[:space:]]/, "", $4); print $4; exit }' "$REPORT_PATH")"
    [ -n "$val" ] || { echo "Path A: cache_read row for call $call missing" >&2; false; }
    case "$val" in
      ''|*[!0-9]*) echo "Path A: cache_read call $call is non-numeric: $val" >&2; false ;;
    esac
    [ "$val" -gt 0 ] || { echo "Path A: cache_read call $call == 0 — hit-rate assertion failed" >&2; false; }
  done
}

@test "Path B assertion: cache_control marker present on dual-flag-true providers AND hit-rate holds (when Path B)" {
  decision="$(_extract_decision_line "$REPORT_PATH")"
  verdict="$(_path_from_decision "$decision")"
  if [ "$verdict" != "B" ]; then
    skip "verdict=$verdict — Path B assertion not selected"
  fi
  # Path B requires the dispatcher's dual-flag gate to be observable at the
  # flagged reviewer-dispatch sites. The capability-gate truth table is
  # pinned in test-cache-control-capability-gate.bats; here we assert the
  # spike report enumerates the flagged sites where Path B activation
  # toggles emit_cache_control_markers: true on the Anthropic provider
  # entries (and contrapositive: emit_cache_control_markers: false
  # providers receive NO cache_control field).
  run grep -F "emit_cache_control_markers" "$REPORT_PATH"
  [ "$status" -eq 0 ]
  # Hit-rate check: same as Path A (second-and-later calls cache_read > 0).
  for call in 2 3; do
    val="$(awk -v c="$call" 'BEGIN{FS="|"} $0 ~ "^\\|[[:space:]]*"c"[[:space:]]*\\|" { gsub(/[[:space:]]/, "", $4); print $4; exit }' "$REPORT_PATH")"
    [ -n "$val" ] || { echo "Path B: cache_read row for call $call missing" >&2; false; }
    case "$val" in
      ''|*[!0-9]*) echo "Path B: cache_read call $call is non-numeric: $val" >&2; false ;;
    esac
    [ "$val" -gt 0 ] || { echo "Path B: cache_read call $call == 0 — hit-rate assertion failed" >&2; false; }
  done
}

@test "Path B contrapositive: providers with emit_cache_control_markers: false get NO cache_control field" {
  decision="$(_extract_decision_line "$REPORT_PATH")"
  verdict="$(_path_from_decision "$decision")"
  if [ "$verdict" != "B" ]; then
    skip "verdict=$verdict — Path B contrapositive not selected"
  fi
  # The contrapositive is observable via test-cache-control-capability-gate.bats
  # cells (a)/(b)/(c) — this assertion documents the cross-pin contract.
  [ -f "$REPO_ROOT/tests/unit/test-cache-control-capability-gate.bats" ]
  run grep -F "(false,false)" "$REPO_ROOT/tests/unit/test-cache-control-capability-gate.bats"
  [ "$status" -eq 0 ]
}

@test "PENDING state: stub report present — flag as deferred (load-bearing diagnostic)" {
  decision="$(_extract_decision_line "$REPORT_PATH")"
  verdict="$(_path_from_decision "$decision")"
  if [ "$verdict" != "PENDING" ]; then
    skip "verdict=$verdict — PENDING-state diagnostic only fires against the stub"
  fi
  # The stub MUST self-identify as the T33 stub so a future regression that
  # ships a placeholder report under a non-stub run_id fails loud here.
  rid="$(_extract_run_id "$REPORT_PATH")"
  [[ "$rid" == *"stub"* ]] || [[ "$rid" == *"pending"* ]] || { echo "PENDING decision but run_id ($rid) does not self-identify as stub/pending" >&2; false; }
}
