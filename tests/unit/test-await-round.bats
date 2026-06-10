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

  # Stubs in test fixtures live under TEST_ROOT (outside the repo's scripts/
  # tree); register TEST_ROOT as an additional permitted exec root so the
  # realpath-bounds check accepts test stubs while still rejecting paths
  # outside it (e.g. /bin/sh, /usr/bin/touch, ../../../tmp/x).
  export QRSPI_AWAIT_EXEC_ROOTS="$TEST_ROOT"
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
  # Stub split materializes a per-finding file so the universal stdout-
  # fallback (Bug 3, v0.7.2.5) sees finding artifacts on disk for the tag
  # and short-circuits — the focus of THIS test is the output-bound
  # contract, not the fallback path (covered by
  # test-await-round-stdout-fallback.bats).
  STUB_SPLIT="$TEST_ROOT/stub-split.sh"
  cat > "$STUB_SPLIT" <<EOF
#!/usr/bin/env bash
echo "finding body" > "$ROUND_DIR/big.finding-F01.md"
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

# ── Command-injection regression guards ──────────────────────────────────────
# Behavioral coverage for the trust-boundary contract: manifest fields
# `await_cmd` and `split_cmd` are read verbatim from disk, parsed via
# shlex.split, never passed to a shell, and argv[0] is bounded by the
# realpath-under-permitted-exec-roots check (or the bare-name allowlist).

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

@test "command-injection: absolute-path /usr/bin/touch outside permitted exec roots is rejected" {
  # Replaces the previous metachar test which was vacuous: shell=False alone
  # made `evil-no-such-binary;` unresolvable regardless of any guard, so the
  # test asserted nothing about parse_and_validate. This rewrite uses a real
  # absolute-path binary (/usr/bin/touch) whose argv[0] would be accepted by
  # any guard that only checks bare names — only the realpath-under-exec-roots
  # check rejects it. Removing the path-shaped bound would let touch run and
  # create the file.
  PWN_PATH="/tmp/qrspi-await-round-abspath-$$-$RANDOM"
  rm -f "$PWN_PATH"
  if [ ! -x /usr/bin/touch ] && [ ! -x /bin/touch ]; then
    skip "no /usr/bin/touch or /bin/touch available"
  fi
  TOUCH_BIN=/usr/bin/touch
  [ -x "$TOUCH_BIN" ] || TOUCH_BIN=/bin/touch

  python3 - <<EOF
import json
m = [{
  "tag": "abs-evil",
  "agent": "x",
  "mode": "background",
  "status": "pending",
  "job_id": "j",
  "await_cmd": "$TOUCH_BIN $PWN_PATH",
  "split_cmd": "true"
}]
open("$ROUND_DIR/.dispatch-manifest.json","w").write(json.dumps(m))
EOF

  run "$AWAIT" --round-dir "$ROUND_DIR"
  [ "$status" -ne 0 ]
  [ ! -e "$PWN_PATH" ]
  [[ "$output" == *"outside"* ]] || [[ "$output" == *"exec roots"* ]] || [[ "$output" == *"rejected"* ]]
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

@test "command-injection: absolute-path shell interpreter '/bin/sh -c ...' is rejected" {
  # An attacker with manifest-write only could set await_cmd to
  # "/bin/sh -c 'touch /tmp/pwn'". argv[0] is path-shaped, so a guard that
  # only checks bare names against an allowlist accepts it; subprocess.run
  # with shell=False then invokes /bin/sh EXPLICITLY as argv[0] and -c is
  # interpreted by sh, not Python. The realpath-bounds check must reject
  # /bin/sh because it does not resolve under any permitted exec root.
  PWN_PATH="/tmp/qrspi-await-round-shellrce-$$-$RANDOM"
  rm -f "$PWN_PATH"

  python3 - <<EOF
import json
m = [{
  "tag": "shrce",
  "agent": "x",
  "mode": "background",
  "status": "pending",
  "job_id": "j",
  "await_cmd": "/bin/sh -c 'touch $PWN_PATH'",
  "split_cmd": "true"
}]
open("$ROUND_DIR/.dispatch-manifest.json","w").write(json.dumps(m))
EOF

  run "$AWAIT" --round-dir "$ROUND_DIR"
  [ "$status" -ne 0 ]
  [ ! -e "$PWN_PATH" ]
  [[ "$output" == *"rejected"* ]] || [[ "$output" == *"outside"* ]] || [[ "$output" == *"exec roots"* ]]
  rm -f "$PWN_PATH"
}

@test "command-injection: parent-traversal '../../../tmp/x' escapes confinement and is rejected" {
  # Path-shaped argv[0] containing ../ traversal can climb out of
  # DISPATCH_CWD into world-writable directories. The realpath bounds check
  # must reject any argv[0] whose resolved path is not under a permitted
  # exec root.
  PWN_DIR="/tmp/qrspi-await-traversal-$$-$RANDOM"
  mkdir -p "$PWN_DIR"
  cat > "$PWN_DIR/attack.sh" <<'EOS'
#!/usr/bin/env bash
echo pwned > "$0.ran"
EOS
  chmod +x "$PWN_DIR/attack.sh"
  # Build a relative path that climbs out of $ROUND_DIR/.dispatch up to /tmp.
  # Count of "../" segments needed: depth from $ROUND_DIR/.dispatch to / is
  # variable across systems, so we use absolute-path content with embedded
  # "../" — realpath collapses it the same way cwd-relative resolution does.
  REL_PATH="../../../../../../../../../../../../$PWN_DIR/attack.sh"

  python3 - <<EOF
import json
m = [{
  "tag": "trav",
  "agent": "x",
  "mode": "background",
  "status": "pending",
  "job_id": "j",
  "await_cmd": "$REL_PATH",
  "split_cmd": "true"
}]
open("$ROUND_DIR/.dispatch-manifest.json","w").write(json.dumps(m))
EOF

  run "$AWAIT" --round-dir "$ROUND_DIR"
  [ "$status" -ne 0 ]
  [ ! -e "$PWN_DIR/attack.sh.ran" ]
  rm -rf "$PWN_DIR"
}

@test "command-injection: './codex' relative-cwd masquerade is rejected" {
  # Bare-name "codex" is allowlisted (resolved via $PATH to the system codex
  # CLI). "./codex" is path-shaped and would resolve under DISPATCH_CWD —
  # i.e. <round-dir>/.dispatch/codex — bypassing the system PATH. The
  # realpath-bounds check rejects it because the dispatch dir is not a
  # permitted exec root.
  PWN_PATH="/tmp/qrspi-await-codex-masq-$$-$RANDOM"
  rm -f "$PWN_PATH"
  cat > "$ROUND_DIR/.dispatch/codex" <<EOS
#!/usr/bin/env bash
echo pwned > "$PWN_PATH"
EOS
  chmod +x "$ROUND_DIR/.dispatch/codex"

  python3 - <<EOF
import json
m = [{
  "tag": "masq",
  "agent": "x",
  "mode": "background",
  "status": "pending",
  "job_id": "j",
  "await_cmd": "./codex --reviewer-tag x out.json",
  "split_cmd": "true"
}]
open("$ROUND_DIR/.dispatch-manifest.json","w").write(json.dumps(m))
EOF

  run "$AWAIT" --round-dir "$ROUND_DIR"
  [ "$status" -ne 0 ]
  [ ! -e "$PWN_PATH" ]
  rm -f "$PWN_PATH"
}

@test "command-injection: split_cmd is independently validated when await_cmd succeeds" {
  # Coverage gap closed: previous tests put the malicious payload in
  # await_cmd and short-circuited before split_cmd validation ever ran. A
  # legitimate stub await_cmd that exits 0 forces parse_and_validate to be
  # invoked on split_cmd; a bare-name `touch` payload there must be
  # rejected by the bare-name allowlist guard. This test would fail if the
  # parse_and_validate call on split_cmd were ever removed.
  PWN_PATH="/tmp/qrspi-await-split-pwn-$$-$RANDOM"
  rm -f "$PWN_PATH"

  STUB_AWAIT="$TEST_ROOT/stub-await-ok.sh"
  cat > "$STUB_AWAIT" <<'EOS'
#!/usr/bin/env bash
exit 0
EOS
  chmod +x "$STUB_AWAIT"

  python3 - <<EOF
import json
m = [{
  "tag": "splitevil",
  "agent": "x",
  "mode": "background",
  "status": "pending",
  "job_id": "j",
  "await_cmd": "$STUB_AWAIT",
  "split_cmd": "touch $PWN_PATH"
}]
open("$ROUND_DIR/.dispatch-manifest.json","w").write(json.dumps(m))
EOF

  run "$AWAIT" --round-dir "$ROUND_DIR"
  [ "$status" -ne 0 ]
  [ ! -e "$PWN_PATH" ]
  # Diagnostic must mention split_cmd so an operator knows which field
  # carried the injection (await_cmd-only diagnostics would imply the
  # split_cmd guard never ran).
  [[ "$output" == *"split_cmd"* ]]
  rm -f "$PWN_PATH"
}

@test "command-injection: shlex parse error surfaces the actual shlex message" {
  # An unbalanced quote in await_cmd raises shlex.ValueError. The diagnostic
  # must include the actual shlex error message (e.g. "No closing quotation")
  # so a manifest author can self-diagnose; emitting only the type name
  # ("ValueError") would force every malformed input to look identical.
  python3 - <<EOF
import json
m = [{
  "tag": "badquote",
  "agent": "x",
  "mode": "background",
  "status": "pending",
  "job_id": "j",
  "await_cmd": "echo 'unbalanced",
  "split_cmd": "true"
}]
open("$ROUND_DIR/.dispatch-manifest.json","w").write(json.dumps(m))
EOF

  run "$AWAIT" --round-dir "$ROUND_DIR"
  [ "$status" -ne 0 ]
  [[ "$output" == *"parse error"* ]]
  # The actual shlex message must be present, not just the type name.
  [[ "$output" == *"closing"* ]] || [[ "$output" == *"quotation"* ]]
}
