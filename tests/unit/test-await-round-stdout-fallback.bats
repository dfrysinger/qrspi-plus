#!/usr/bin/env bats
# ============================================================================
# Bug 3 (v0.7.2.5 hotfix) — universal stdout-fallback in await-round.sh.
#
# Pre-fix behavior: the splitter ran only for `mode: third_party` (later
# `mode: background`) manifest entries. First-party entries — the Copilot-
# CLI Task-tool path — were assumed to have already written per-finding
# files via the subagent's Write tool at dispatch time. When the subagent
# could not write (e.g., the Bug 2 frontmatter mismatch denied write
# capability), its stdout payload (FINDING-BOUNDARY format) reached the
# orchestrator via the Task return value but never landed on disk; the
# round looked clean but actually held findings.
#
# Post-fix behavior: regardless of mode, if per-finding files are absent
# for a tag but a raw stdout capture exists at <round-dir>/.dispatch/
# <tag>.raw, await-round invokes third-party-finding-splitter.sh on it
# so per-finding files materialize on disk. The orchestrator captures
# each Task return value to that path before invoking await-round.
# ============================================================================

setup() {
  TEST_ROOT=$(mktemp -d)
  export TEST_ROOT
  REPO_ROOT=$(cd "$BATS_TEST_DIRNAME/../.." && pwd)
  export REPO_ROOT
  AWAIT="$REPO_ROOT/scripts/await-round.sh"
  export AWAIT

  ROUND_DIR="$TEST_ROOT/round-01"
  mkdir -p "$ROUND_DIR/.dispatch"
  export ROUND_DIR

  # In production the round_dir is inside the qrspi-plus repo, so
  # _compute_exec_roots() picks up <repo>/scripts via `git rev-parse
  # --show-toplevel`. Tests stage round_dir under /tmp (outside any git
  # workspace), so we must explicitly add the repo's scripts/ root in
  # addition to TEST_ROOT.
  export QRSPI_AWAIT_EXEC_ROOTS="$TEST_ROOT:$REPO_ROOT/scripts"
}

teardown() {
  rm -rf "$TEST_ROOT"
}

# ── First-party stdout-fallback ─────────────────────────────────────────────

@test "first_party entry with stdout capture: splitter runs and per-finding files materialize" {
  # Simulate the Copilot-CLI Task-tool path: orchestrator captured the Task
  # return value (a FINDING-BOUNDARY-shaped payload) to .dispatch/<tag>.raw
  # because the subagent emitted via stdout rather than writing files.
  TAG="quality-claude"
  cat > "$ROUND_DIR/.dispatch/${TAG}.raw" <<'RAW'
<<<FINDING-BOUNDARY>>>
---
reviewer: quality-claude
artifact: design
severity: high
---
First stdout-emitted finding body.
<<<FINDING-BOUNDARY>>>
---
reviewer: quality-claude
artifact: design
severity: medium
---
Second stdout-emitted finding body.
RAW

  python3 - <<EOF
import json
m = [{
  "tag": "${TAG}",
  "agent": "qrspi-design-reviewer",
  "mode": "first_party",
  "status": "dispatched",
  "dispatch_spec": {"subagent_type": "qrspi-design-reviewer", "host": "copilot-cli",
                    "vendor": "claude", "model": "claude-opus-4.7-high"}
}]
open("$ROUND_DIR/.dispatch-manifest.json","w").write(json.dumps(m))
EOF

  run "$AWAIT" --round-dir "$ROUND_DIR"
  [ "$status" -eq 0 ]
  # Both findings should have materialized as per-finding files.
  [ -f "$ROUND_DIR/${TAG}.finding-F01.md" ]
  [ -f "$ROUND_DIR/${TAG}.finding-F02.md" ]
  # Summary should reflect the entry as complete-with-findings.
  python3 -c "
import json
s = json.load(open('$ROUND_DIR/.round-complete.json'))
assert s['with_findings'] == 1, s
assert s['entries'][0]['status'] == 'complete-with-findings', s
"
}

@test "first_party entry with NO_FINDINGS stdout capture: clean sentinel materializes" {
  TAG="quality-codex"
  printf 'NO_FINDINGS' > "$ROUND_DIR/.dispatch/${TAG}.raw"

  python3 - <<EOF
import json
m = [{
  "tag": "${TAG}",
  "agent": "qrspi-design-reviewer",
  "mode": "first_party",
  "status": "dispatched",
  "dispatch_spec": {"subagent_type": "qrspi-design-reviewer", "host": "copilot-cli",
                    "vendor": "codex", "model": "gpt-5.3-codex"}
}]
open("$ROUND_DIR/.dispatch-manifest.json","w").write(json.dumps(m))
EOF

  run "$AWAIT" --round-dir "$ROUND_DIR"
  [ "$status" -eq 0 ]
  [ -f "$ROUND_DIR/${TAG}.clean.md" ]
  python3 -c "
import json
s = json.load(open('$ROUND_DIR/.round-complete.json'))
assert s['clean'] == 1, s
"
}

@test "first_party entry that already wrote per-finding files: fallback is skipped" {
  # Subagent succeeded at Write (post-Bug-2 happy path). Per-finding files
  # already exist; the fallback must NOT clobber or re-process them. A raw
  # capture is also present (orchestrator captured the Task return for
  # symmetry) — the fallback must skip it because finding files exist.
  TAG="quality-claude"
  printf 'pre-existing finding body\n' > "$ROUND_DIR/${TAG}.finding-F01.md"
  cat > "$ROUND_DIR/.dispatch/${TAG}.raw" <<'RAW'
<<<FINDING-BOUNDARY>>>
should-not-be-split
RAW

  python3 - <<EOF
import json
m = [{
  "tag": "${TAG}",
  "agent": "qrspi-design-reviewer",
  "mode": "first_party",
  "status": "dispatched",
  "dispatch_spec": {"subagent_type": "qrspi-design-reviewer", "host": "copilot-cli",
                    "vendor": "claude", "model": "claude-opus-4.7-high"}
}]
open("$ROUND_DIR/.dispatch-manifest.json","w").write(json.dumps(m))
EOF

  run "$AWAIT" --round-dir "$ROUND_DIR"
  [ "$status" -eq 0 ]
  # The pre-existing file must remain untouched.
  grep -q 'pre-existing finding body' "$ROUND_DIR/${TAG}.finding-F01.md"
  # No F02 file should have been produced by the fallback.
  [ ! -f "$ROUND_DIR/${TAG}.finding-F02.md" ]
}

@test "first_party entry with no raw capture and no finding files: counted clean (no false failure)" {
  # The subagent wrote no files AND the orchestrator captured no stdout
  # (e.g., a NO_FINDINGS reply via Codex emission contract was not
  # captured, or the subagent silently produced nothing). await-round
  # must not fail loudly — the missing-output condition is surfaced by
  # the downstream apply-fix step's "expected tag produced no output"
  # diagnostic, not by await-round itself.
  TAG="quality-claude"

  python3 - <<EOF
import json
m = [{
  "tag": "${TAG}",
  "agent": "qrspi-design-reviewer",
  "mode": "first_party",
  "status": "dispatched"
}]
open("$ROUND_DIR/.dispatch-manifest.json","w").write(json.dumps(m))
EOF

  run "$AWAIT" --round-dir "$ROUND_DIR"
  [ "$status" -eq 0 ]
  python3 -c "
import json
s = json.load(open('$ROUND_DIR/.round-complete.json'))
# Entry counted in summary even though no findings + no fallback ran.
assert len(s['entries']) == 1, s
"
}

# ── Background-mode parity ──────────────────────────────────────────────────

@test "background entry where split_cmd produces nothing: stdout-fallback rescues from .raw" {
  # Edge case: a background reviewer's split_cmd is buggy or no-op, but the
  # await_cmd correctly populated .dispatch/<tag>.raw. The universal
  # stdout-fallback should still produce per-finding files from the raw.
  TAG="codex-quality"
  STUB_AWAIT="$TEST_ROOT/stub-await.sh"
  STUB_SPLIT="$TEST_ROOT/stub-split-noop.sh"

  cat > "$STUB_AWAIT" <<EOF
#!/usr/bin/env bash
cat > "$ROUND_DIR/.dispatch/${TAG}.raw" <<'RAW'
<<<FINDING-BOUNDARY>>>
---
reviewer: codex-quality
artifact: design
severity: medium
---
Background-mode rescued finding.
RAW
exit 0
EOF
  cat > "$STUB_SPLIT" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
  chmod +x "$STUB_AWAIT" "$STUB_SPLIT"

  python3 - <<EOF
import json
m = [{
  "tag": "${TAG}",
  "agent": "qrspi-x",
  "mode": "background",
  "status": "pending",
  "job_id": "j-1",
  "await_cmd": "$STUB_AWAIT",
  "split_cmd": "$STUB_SPLIT"
}]
open("$ROUND_DIR/.dispatch-manifest.json","w").write(json.dumps(m))
EOF

  run "$AWAIT" --round-dir "$ROUND_DIR"
  [ "$status" -eq 0 ]
  # Universal fallback should have produced the finding file the no-op
  # split_cmd failed to produce.
  [ -f "$ROUND_DIR/${TAG}.finding-F01.md" ]
}

# ── Pre-existing failed status preservation (R1-F02 dual-review finding) ────

@test "entry already marked failed by upstream is preserved and exits non-zero" {
  TAG="quality-broken"

  python3 - <<PY
import json
m = [{
  "tag": "${TAG}",
  "agent": "qrspi-design-reviewer",
  "mode": "background",
  "status": "failed",
  "dispatch_spec": {"subagent_type": "qrspi-design-reviewer", "host": "third-party",
                    "vendor": "codex", "model": "gpt-5.3-codex"}
}]
open("$ROUND_DIR/.dispatch-manifest.json","w").write(json.dumps(m))
PY

  run "$AWAIT" --round-dir "$ROUND_DIR"
  [ "$status" -ne 0 ]
  python3 -c "
import json
m = json.load(open('$ROUND_DIR/.dispatch-manifest.json'))
assert m[0]['status'] == 'failed', m
s = json.load(open('$ROUND_DIR/.round-complete.json'))
assert s['clean'] == 0, s
assert s['with_findings'] == 0, s
"
}

@test "entry marked failed by upstream but rescued via stdout-fallback flips to complete-with-findings" {
  TAG="quality-rescued"
  cat > "$ROUND_DIR/.dispatch/${TAG}.raw" <<RAW
<<<FINDING-BOUNDARY>>>
---
reviewer: quality-rescued
artifact: design
severity: high
---
Rescued finding body from raw stdout capture.
RAW

  python3 - <<PY
import json
m = [{
  "tag": "${TAG}",
  "agent": "qrspi-design-reviewer",
  "mode": "background",
  "status": "failed",
  "dispatch_spec": {"subagent_type": "qrspi-design-reviewer", "host": "third-party",
                    "vendor": "codex", "model": "gpt-5.3-codex"}
}]
open("$ROUND_DIR/.dispatch-manifest.json","w").write(json.dumps(m))
PY

  run "$AWAIT" --round-dir "$ROUND_DIR"
  [ "$status" -eq 0 ]
  [ -f "$ROUND_DIR/${TAG}.finding-F01.md" ]
  python3 -c "
import json
m = json.load(open('$ROUND_DIR/.dispatch-manifest.json'))
assert m[0]['status'] == 'complete-with-findings', m
s = json.load(open('$ROUND_DIR/.round-complete.json'))
assert s['with_findings'] == 1, s
"
}

# ── Stdout-fallback splitter failure path (R2-B1 dual-review finding) ──────

@test "raw capture present but splitter fails: entry is marked failed and exits non-zero" {
  # If .dispatch/<tag>.raw exists but the splitter cannot produce per-finding
  # files (malformed payload, splitter rejects), await-round must surface a
  # failure rather than silently flowing the entry to clean. The reviewer
  # emitted something — the orchestrator must not discard it without notice.
  TAG="quality-malformed"
  # Splitter is sensitive to a fence-less payload that contains neither the
  # FINDING-BOUNDARY marker nor the NO_FINDINGS sentinel. The real splitter
  # treats this as schema violation and exits non-zero.
  printf 'this is not a valid emission format\nno boundary marker here\n' \
    > "$ROUND_DIR/.dispatch/${TAG}.raw"

  python3 - <<EOF
import json
m = [{
  "tag": "${TAG}",
  "agent": "qrspi-design-reviewer",
  "mode": "first_party",
  "status": "dispatched",
  "dispatch_spec": {"subagent_type": "qrspi-design-reviewer", "host": "copilot-cli",
                    "vendor": "claude", "model": "claude-opus-4.7-high"}
}]
open("$ROUND_DIR/.dispatch-manifest.json","w").write(json.dumps(m))
EOF

  run "$AWAIT" --round-dir "$ROUND_DIR"
  [ "$status" -ne 0 ]
  python3 -c "
import json
m = json.load(open('$ROUND_DIR/.dispatch-manifest.json'))
assert m[0]['status'] == 'failed', m
s = json.load(open('$ROUND_DIR/.round-complete.json'))
assert s['clean'] == 0, 'silently-clean regression: %r' % (s,)
"
}
