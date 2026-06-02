#!/usr/bin/env bats
# ============================================================================
# Unit tests for scripts/await-round.sh — G3/G4.
#
# Pins behaviors enumerated in task-12.md "Test expectations":
#   - Manifest-driven async drain: pending background entries are awaited via
#     await_cmd, split via split_cmd, and have status updated.
#   - <round-dir>/.round-complete.json is written.
#   - Round-scoped <round-dir>/.dispatch/ subdir is removed after completion.
#   - Zero-background-entry rounds succeed (no-op-safe).
#   - Output-bound contract: combined stdout+stderr stays bounded (≤ 2 KiB)
#     even when the underlying captured payload is large; no captured payload
#     fragment is echoed.
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
}

teardown() {
  rm -rf "$TEST_ROOT"
}

# ── Existence ───────────────────────────────────────────────────────────────

@test "await-round.sh exists and is executable" {
  [ -f "$AWAIT" ]
  [ -x "$AWAIT" ]
}

# ── Zero-background no-op-safe ──────────────────────────────────────────────

@test "zero background entries: succeeds and writes .round-complete.json" {
  printf '[]' > "$ROUND_DIR/.dispatch-manifest.json"
  run "$AWAIT" --round-dir "$ROUND_DIR"
  [ "$status" -eq 0 ]
  [ -f "$ROUND_DIR/.round-complete.json" ]
}

@test "zero background entries: removes .dispatch/ subdir after summary" {
  printf '[]' > "$ROUND_DIR/.dispatch-manifest.json"
  run "$AWAIT" --round-dir "$ROUND_DIR"
  [ "$status" -eq 0 ]
  [ ! -d "$ROUND_DIR/.dispatch" ]
}

# ── Pending background entries: drain + split + status update ───────────────

@test "pending background entry: invokes await_cmd, split_cmd, marks done" {
  # Stub await_cmd captures into the raw file; stub split_cmd writes a finding.
  STUB_AWAIT="$TEST_ROOT/stub-await.sh"
  STUB_SPLIT="$TEST_ROOT/stub-split.sh"
  cat > "$STUB_AWAIT" <<EOF
#!/usr/bin/env bash
echo "raw payload" > "$ROUND_DIR/.dispatch/codex-quality.raw"
exit 0
EOF
  cat > "$STUB_SPLIT" <<EOF
#!/usr/bin/env bash
printf 'finding body\n' > "$ROUND_DIR/codex-quality.finding-F01.md"
exit 0
EOF
  chmod +x "$STUB_AWAIT" "$STUB_SPLIT"

  python3 - <<EOF
import json
m = [{
  "tag": "codex-quality",
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
  [ -f "$ROUND_DIR/codex-quality.finding-F01.md" ]
  [ -f "$ROUND_DIR/.round-complete.json" ]
  # Manifest entry status should have advanced past "pending".
  python3 -c "
import json
m=json.load(open('$ROUND_DIR/.dispatch-manifest.json'))
assert m[0]['status'] != 'pending', m
"
  [ ! -d "$ROUND_DIR/.dispatch" ]
}

# ── Output-bound contract ───────────────────────────────────────────────────

@test "output-bound: large captured payload is NOT echoed; combined output ≤ 2KiB" {
  # Stub await writes a 50KB payload containing a recognisable sentinel.
  STUB_AWAIT="$TEST_ROOT/stub-await.sh"
  cat > "$STUB_AWAIT" <<EOF
#!/usr/bin/env bash
python3 -c "open('$ROUND_DIR/.dispatch/big.raw','w').write('SECRET-PAYLOAD-XYZZY '*2500)"
exit 0
EOF
  STUB_SPLIT="$TEST_ROOT/stub-split.sh"
  cat > "$STUB_SPLIT" <<EOF
#!/usr/bin/env bash
exit 0
EOF
  chmod +x "$STUB_AWAIT" "$STUB_SPLIT"

  python3 - <<EOF
import json
m = [{"tag":"big","agent":"x","mode":"background","status":"pending","job_id":"j",
      "await_cmd":"$STUB_AWAIT","split_cmd":"$STUB_SPLIT"}]
open("$ROUND_DIR/.dispatch-manifest.json","w").write(json.dumps(m))
EOF

  out_file="$TEST_ROOT/combined.out"
  "$AWAIT" --round-dir "$ROUND_DIR" >"$out_file" 2>&1
  status=$?
  [ "$status" -eq 0 ]
  byte_count=$(wc -c < "$out_file")
  [ "$byte_count" -le 2048 ]
  ! grep -q 'SECRET-PAYLOAD-XYZZY' "$out_file"
}

# ── Failure path ────────────────────────────────────────────────────────────

@test "missing --round-dir argument: fails loud with diagnostic" {
  run "$AWAIT"
  [ "$status" -ne 0 ]
  [[ "$output" == *"--round-dir"* ]]
}

@test "output-bound: prompt-body fixture in .dispatch is NOT echoed" {
  # Per task-12.md "Test expectations" bullet 9: combined stdout+stderr must
  # not echo prompt-body fragments either. This fixture stages a dispatch
  # prompt file under <round-dir>/.dispatch/ containing a recognisable
  # sentinel; await-round consumes and removes the directory but must never
  # surface the sentinel string.
  STUB_AWAIT="$TEST_ROOT/stub-await.sh"
  STUB_SPLIT="$TEST_ROOT/stub-split.sh"
  cat > "$STUB_AWAIT" <<EOS
#!/usr/bin/env bash
exit 0
EOS
  cat > "$STUB_SPLIT" <<EOS
#!/usr/bin/env bash
exit 0
EOS
  chmod +x "$STUB_AWAIT" "$STUB_SPLIT"

  # Stage a dispatch prompt body with a unique sentinel.
  python3 -c "open('$ROUND_DIR/.dispatch/prompt-codex-quality.txt','w').write('SECRET-PROMPT-BODY-QFXBR '*5000)"

  python3 - <<EOS
import json
m=[{"tag":"codex-quality","agent":"x","mode":"background","status":"pending","job_id":"j",
    "await_cmd":"$STUB_AWAIT","split_cmd":"$STUB_SPLIT"}]
open("$ROUND_DIR/.dispatch-manifest.json","w").write(json.dumps(m))
EOS

  out_file="$TEST_ROOT/combined.out"
  "$AWAIT" --round-dir "$ROUND_DIR" >"$out_file" 2>&1
  status=$?
  [ "$status" -eq 0 ]
  byte_count=$(wc -c < "$out_file")
  [ "$byte_count" -le 2048 ]
  ! grep -q 'SECRET-PROMPT-BODY-QFXBR' "$out_file"
  # And the round-scoped dispatch dir must be gone after completion.
  [ ! -d "$ROUND_DIR/.dispatch" ]
}

# ── Command-injection guards (R2 security-claude R2-F01/F02) ─────────────────

@test "command-injection: malicious await_cmd 'touch /tmp/pwned-...' is rejected" {
  # Pre-fix this manifest entry would execute `touch /tmp/pwned-<pid>` via
  # subprocess.run(shell=True), creating the file as the current user. The
  # parse_and_validate() guard rejects bare-name executables not in the
  # allowlist, so /tmp/<sentinel> must NOT be created.
  PWN_PATH="/tmp/qrspi-await-round-pwned-$$-$RANDOM"
  rm -f "$PWN_PATH"

  python3 - <<EOF
import json
m = [{
  "tag": "evil",
  "agent": "x",
  "mode": "background",
  "status": "pending",
  "job_id": "j",
  "await_cmd": "touch $PWN_PATH",
  "split_cmd": "true"
}]
open("$ROUND_DIR/.dispatch-manifest.json","w").write(json.dumps(m))
EOF

  run "$AWAIT" --round-dir "$ROUND_DIR"
  # Drain reports failure (rc != 0) because the entry was rejected.
  [ "$status" -ne 0 ]
  # The malicious file MUST NOT have been created.
  [ ! -e "$PWN_PATH" ]
  # The diagnostic should explain why (bare-name executable rejected).
  [[ "$output" == *"rejected"* ]] || [[ "$output" == *"allowlist"* ]]
  rm -f "$PWN_PATH"
}

@test "command-injection: shell-metacharacter await_cmd does NOT spawn a shell" {
  # `; rm -rf /` past a real binary would execute under shell=True. With
  # shell=False + shlex.split, the entire string becomes argv and the
  # nonexistent binary 'evil;' fails fast — no shell metachar interpretation.
  PWN_PATH="/tmp/qrspi-await-round-shellmeta-$$-$RANDOM"
  rm -f "$PWN_PATH"

  python3 - <<EOF
import json
m = [{
  "tag": "evil2",
  "agent": "x",
  "mode": "background",
  "status": "pending",
  "job_id": "j",
  "await_cmd": "evil-no-such-binary; touch $PWN_PATH",
  "split_cmd": "true"
}]
open("$ROUND_DIR/.dispatch-manifest.json","w").write(json.dumps(m))
EOF

  run "$AWAIT" --round-dir "$ROUND_DIR"
  [ "$status" -ne 0 ]
  [ ! -e "$PWN_PATH" ]
  rm -f "$PWN_PATH"
}

@test "command-injection: option-shaped await_cmd argv[0] is rejected" {
  # An await_cmd starting with '--something' would be rejected as a
  # defensive guard (argv[0] starting with '-' is never a real executable).
  python3 - <<EOF
import json
m = [{
  "tag": "evil3",
  "agent": "x",
  "mode": "background",
  "status": "pending",
  "job_id": "j",
  "await_cmd": "--no-such-option=value",
  "split_cmd": "true"
}]
open("$ROUND_DIR/.dispatch-manifest.json","w").write(json.dumps(m))
EOF

  run "$AWAIT" --round-dir "$ROUND_DIR"
  [ "$status" -ne 0 ]
  [[ "$output" == *"must not start with"* ]]
}
