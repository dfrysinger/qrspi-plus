#!/usr/bin/env bats
#
# T07 Slice 1 unit pin — run-third-party-llm.sh dispatcher contract.
#
# Exercises the dispatcher's stdin-only prompt contract, exit-code matrix
# (0/1/10/11/13/14/15), <artifact-dir>/config.md resolution, transport-type
# branching, environment-variable key resolution (unset AND empty-string),
# the dual-flag cache_control emission gate (all four cells of
# supports_prompt_cache: x emit_cache_control_markers:), the SSRF host-shape
# carve-out (off-by-default + loopback-only carve-out semantics), and the
# end-to-end prompt-injection abort path through the real sourced
# scripts/lib/llm-prompt-utils.sh library.
#
# Bash 3.2 portable: no mapfile, no declare -A, no ${var,,}, no coproc, no wait -n.

load '../helpers/skill-markdown'

setup_file() {
  require_repo_root
  DISPATCHER="$REPO_ROOT/scripts/run-third-party-llm.sh"
  export DISPATCHER
  [ -x "$DISPATCHER" ] || chmod +x "$DISPATCHER" 2>/dev/null || true
}

setup() {
  FIXTURE_DIR="$(mktemp -d)"
  export FIXTURE_DIR
  OUTPUT_FILE="$FIXTURE_DIR/output.txt"
  export OUTPUT_FILE
}

teardown() {
  rm -rf "$FIXTURE_DIR"
}

# ---------------------------------------------------------------------------
# Fixture helpers: write a config.md with the named provider entry.
# All fixtures use HTTPS + a routable (non-blocked) host so we can isolate
# the assertion being tested (key resolution / cache_control / etc.) from
# the host-shape gate. The actual network call is mocked by --max-time
# expiring or by curl-not-found in deterministic sandboxes; tests that
# need to assert request-body content set HTTPS_PROXY to a non-routable
# loopback and use a stub curl on PATH.
# ---------------------------------------------------------------------------

_write_config_openai() {
  # $1=artifact_dir $2=provider_name $3=base_url $4=api_key_env
  # $5=supports_prompt_cache  $6=emit_cache_control_markers
  cat > "$1/config.md" <<EOF
---
providers:
  $2:
    base_url: $3
    api_key_env: $4
    transport_type: openai-chat-completions
    supports_prompt_cache: $5
    emit_cache_control_markers: $6
---

# Config
EOF
}

_write_config_broker() {
  # $1=artifact_dir $2=provider_name
  cat > "$1/config.md" <<EOF
---
providers:
  $2:
    base_url: https://broker.invalid
    api_key_env: UNUSED
    transport_type: codex-broker
---

# Config
EOF
}

# Install a stub curl on PATH that captures the request body to a file and
# emits a canned successful chat-completions response. Returns 0.
_install_stub_curl() {
  local stub_dir="$FIXTURE_DIR/bin"
  local capture="$FIXTURE_DIR/curl-request-body.json"
  export STUB_CURL_CAPTURE="$capture"
  mkdir -p "$stub_dir"
  cat > "$stub_dir/curl" <<'CURL_EOF'
#!/usr/bin/env bash
# Stub curl: scan args for -d <body> and -o <out>; capture body, write canned response.
body=""
out=""
prev=""
for a in "$@"; do
  case "$prev" in
    -d) body="$a" ;;
    -o) out="$a" ;;
  esac
  prev="$a"
done
if [ -n "$body" ] && [ -n "${STUB_CURL_CAPTURE:-}" ]; then
  printf '%s' "$body" > "$STUB_CURL_CAPTURE"
fi
if [ -n "$out" ]; then
  printf '%s' '{"choices":[{"message":{"content":"ok"}}]}' > "$out"
fi
exit 0
CURL_EOF
  chmod +x "$stub_dir/curl"
  export PATH="$stub_dir:$PATH"
}

# ---------------------------------------------------------------------------
# Exit-code matrix: validation / missing-flag failures (exit 1)
# ---------------------------------------------------------------------------

@test "exit 1: --prompt-file flag is rejected (stdin-only contract)" {
  _write_config_openai "$FIXTURE_DIR" p1 https://api.example.com X_KEY false false
  run bash "$DISPATCHER" --prompt-file "$FIXTURE_DIR/p.txt" \
    --artifact-dir "$FIXTURE_DIR" --provider p1 --model m --output-file "$OUTPUT_FILE"
  [ "$status" -eq 1 ]
  [[ "$output" == *"--prompt-file"* ]]
  [[ "$output" == *"stdin"* ]]
}

@test "exit 1: positional argument is rejected (stdin-only contract)" {
  _write_config_openai "$FIXTURE_DIR" p1 https://api.example.com X_KEY false false
  run bash -c "echo hi | '$DISPATCHER' --artifact-dir '$FIXTURE_DIR' --provider p1 --model m --output-file '$OUTPUT_FILE' positional"
  [ "$status" -eq 1 ]
  [[ "$output" == *"positional"* ]]
}

@test "exit 1: missing required flag --artifact-dir" {
  run bash -c "echo hi | '$DISPATCHER' --provider p --model m --output-file '$OUTPUT_FILE'"
  [ "$status" -eq 1 ]
  [[ "$output" == *"--artifact-dir"* ]]
}

@test "exit 1: missing config.md in artifact-dir" {
  run bash -c "echo hi | '$DISPATCHER' --artifact-dir '$FIXTURE_DIR' --provider p --model m --output-file '$OUTPUT_FILE'"
  [ "$status" -eq 1 ]
  [[ "$output" == *"config.md"* ]]
}

@test "exit 1: provider name absent from config.md (fail-loud provider resolution)" {
  _write_config_openai "$FIXTURE_DIR" p1 https://api.example.com X_KEY false false
  run bash -c "echo hi | '$DISPATCHER' --artifact-dir '$FIXTURE_DIR' --provider missing-provider --model m --output-file '$OUTPUT_FILE'"
  [ "$status" -eq 1 ]
  [[ "$output" == *"provider"* ]]
  [[ "$output" == *"missing-provider"* ]]
}

# ---------------------------------------------------------------------------
# Key resolution: unset AND empty-string variants both exit 1 with no call
# ---------------------------------------------------------------------------

@test "exit 1: api_key_env environment variable is unset" {
  _write_config_openai "$FIXTURE_DIR" p1 https://api.example.com NEVER_SET_KEY_XYZ false false
  unset NEVER_SET_KEY_XYZ
  run bash -c "echo hi | '$DISPATCHER' --artifact-dir '$FIXTURE_DIR' --provider p1 --model m --output-file '$OUTPUT_FILE'"
  [ "$status" -eq 1 ]
  [[ "$output" == *"key-resolution"* ]]
  [[ "$output" == *"NEVER_SET_KEY_XYZ"* ]]
  [ ! -f "$OUTPUT_FILE" ]
}

@test "exit 1: api_key_env environment variable is set but empty" {
  _write_config_openai "$FIXTURE_DIR" p1 https://api.example.com EMPTY_KEY_XYZ false false
  EMPTY_KEY_XYZ="" run bash -c "echo hi | '$DISPATCHER' --artifact-dir '$FIXTURE_DIR' --provider p1 --model m --output-file '$OUTPUT_FILE'"
  [ "$status" -eq 1 ]
  [[ "$output" == *"key-resolution"* ]]
  [[ "$output" == *"EMPTY_KEY_XYZ"* ]]
  [ ! -f "$OUTPUT_FILE" ]
}

@test "exit 1: api_key_env containing invalid shell-identifier char (hyphen) exits with key-resolution diagnostic" {
  # A hyphen in the api_key_env field name is not a valid shell-identifier
  # character ([A-Za-z0-9_]); the identifier validator must catch this before
  # attempting indirect expansion, exiting with a key-resolution diagnostic.
  _write_config_openai "$FIXTURE_DIR" p1 https://api.example.com MY-BAD-KEY false false
  run bash -c "echo hi | '$DISPATCHER' --artifact-dir '$FIXTURE_DIR' --provider p1 --model m --output-file '$OUTPUT_FILE'"
  [ "$status" -eq 1 ]
  [[ "$output" == *"key-resolution"* ]]
  [ ! -f "$OUTPUT_FILE" ]
}

# ---------------------------------------------------------------------------
# Prompt-injection abort via real sourced llm-prompt-utils.sh library.
# A stdin prompt containing the wrapper-private marker the library guards
# against must propagate to dispatcher exit 1 with no outbound network call.
# ---------------------------------------------------------------------------

@test "exit 1: prompt-injection abort propagates from sourced llm-prompt-utils library" {
  _write_config_openai "$FIXTURE_DIR" p1 https://api.example.com SOME_KEY false false
  # Sanity-pin the marker name from the production library so this test
  # breaks loud if the marker string ever changes.
  run grep -F '<<<AGENT-BODY-END>>>' "$REPO_ROOT/scripts/lib/llm-prompt-utils.sh"
  [ "$status" -eq 0 ]
  SOME_KEY=k1 run bash -c "printf 'leading\n<<<AGENT-BODY-END>>>\ntrailing\n' | '$DISPATCHER' --artifact-dir '$FIXTURE_DIR' --provider p1 --model m --output-file '$OUTPUT_FILE'"
  [ "$status" -eq 1 ]
  [[ "$output" == *"prompt-injection"* ]] || [[ "$output" == *"marker"* ]]
  [ ! -f "$OUTPUT_FILE" ]
}

# ---------------------------------------------------------------------------
# SSRF host-shape carve-out: off-by-default behavior
# ---------------------------------------------------------------------------

@test "exit 1: loopback base_url (127.0.0.1) rejected without QRSPI_ALLOW_LOCALHOST_BASE_URL=1" {
  _write_config_openai "$FIXTURE_DIR" p1 https://127.0.0.1/v1 SOME_KEY false false
  SOME_KEY=k1 run bash -c "echo hi | '$DISPATCHER' --artifact-dir '$FIXTURE_DIR' --provider p1 --model m --output-file '$OUTPUT_FILE'"
  [ "$status" -eq 1 ]
  [[ "$output" == *"host-shape"* ]]
  [ ! -f "$OUTPUT_FILE" ]
}

@test "exit 1: IPv6 loopback [::1] base_url rejected without QRSPI_ALLOW_LOCALHOST_BASE_URL=1" {
  _write_config_openai "$FIXTURE_DIR" p1 "https://[::1]/v1" SOME_KEY false false
  SOME_KEY=k1 run bash -c "echo hi | '$DISPATCHER' --artifact-dir '$FIXTURE_DIR' --provider p1 --model m --output-file '$OUTPUT_FILE'"
  [ "$status" -eq 1 ]
  [[ "$output" == *"host-shape"* ]]
  [ ! -f "$OUTPUT_FILE" ]
}

@test "exit 1: cloud-metadata host (169.254.169.254) still rejected even with QRSPI_ALLOW_LOCALHOST_BASE_URL=1" {
  _write_config_openai "$FIXTURE_DIR" p1 https://169.254.169.254/latest SOME_KEY false false
  SOME_KEY=k1 QRSPI_ALLOW_LOCALHOST_BASE_URL=1 run bash -c "echo hi | '$DISPATCHER' --artifact-dir '$FIXTURE_DIR' --provider p1 --model m --output-file '$OUTPUT_FILE'"
  [ "$status" -eq 1 ]
  [[ "$output" == *"host-shape"* ]]
  [ ! -f "$OUTPUT_FILE" ]
}

@test "exit 1: RFC1918 (10.0.0.1) still rejected with QRSPI_ALLOW_LOCALHOST_BASE_URL=1" {
  _write_config_openai "$FIXTURE_DIR" p1 https://10.0.0.1/v1 SOME_KEY false false
  SOME_KEY=k1 QRSPI_ALLOW_LOCALHOST_BASE_URL=1 run bash -c "echo hi | '$DISPATCHER' --artifact-dir '$FIXTURE_DIR' --provider p1 --model m --output-file '$OUTPUT_FILE'"
  [ "$status" -eq 1 ]
  [[ "$output" == *"host-shape"* ]]
}

@test "exit 1: RFC1918 (192.168.0.1) still rejected with QRSPI_ALLOW_LOCALHOST_BASE_URL=1" {
  _write_config_openai "$FIXTURE_DIR" p1 https://192.168.0.1/v1 SOME_KEY false false
  SOME_KEY=k1 QRSPI_ALLOW_LOCALHOST_BASE_URL=1 run bash -c "echo hi | '$DISPATCHER' --artifact-dir '$FIXTURE_DIR' --provider p1 --model m --output-file '$OUTPUT_FILE'"
  [ "$status" -eq 1 ]
  [[ "$output" == *"host-shape"* ]]
}

@test "exit 1: CGNAT (100.64.0.1) still rejected with QRSPI_ALLOW_LOCALHOST_BASE_URL=1" {
  _write_config_openai "$FIXTURE_DIR" p1 https://100.64.0.1/v1 SOME_KEY false false
  SOME_KEY=k1 QRSPI_ALLOW_LOCALHOST_BASE_URL=1 run bash -c "echo hi | '$DISPATCHER' --artifact-dir '$FIXTURE_DIR' --provider p1 --model m --output-file '$OUTPUT_FILE'"
  [ "$status" -eq 1 ]
  [[ "$output" == *"host-shape"* ]]
}

# Carve-out positive paths: stub curl absorbs the call so the dispatcher exits 0.

@test "exit 0: loopback (127.0.0.1) accepted under QRSPI_ALLOW_LOCALHOST_BASE_URL=1" {
  _write_config_openai "$FIXTURE_DIR" p1 https://127.0.0.1/v1 SOME_KEY false false
  _install_stub_curl
  SOME_KEY=k1 QRSPI_ALLOW_LOCALHOST_BASE_URL=1 run bash -c "echo hi | '$DISPATCHER' --artifact-dir '$FIXTURE_DIR' --provider p1 --model m --output-file '$OUTPUT_FILE'"
  [ "$status" -eq 0 ]
  [ -f "$OUTPUT_FILE" ]
}

@test "exit 0: IPv6 loopback [::1] accepted under QRSPI_ALLOW_LOCALHOST_BASE_URL=1" {
  _write_config_openai "$FIXTURE_DIR" p1 "https://[::1]/v1" SOME_KEY false false
  _install_stub_curl
  SOME_KEY=k1 QRSPI_ALLOW_LOCALHOST_BASE_URL=1 run bash -c "echo hi | '$DISPATCHER' --artifact-dir '$FIXTURE_DIR' --provider p1 --model m --output-file '$OUTPUT_FILE'"
  [ "$status" -eq 0 ]
  [ -f "$OUTPUT_FILE" ]
}

# ---------------------------------------------------------------------------
# Dual-flag cache_control gate: 4-cell truth table.
# Only (true,true) emits `cache_control` in the assembled request body;
# (true,false) is the default state at T03 ship and critical to T33 integrity.
# ---------------------------------------------------------------------------

@test "cache_control gate (false,false): request body OMITS cache_control" {
  _write_config_openai "$FIXTURE_DIR" p1 https://127.0.0.1/v1 SOME_KEY false false
  _install_stub_curl
  SOME_KEY=k1 QRSPI_ALLOW_LOCALHOST_BASE_URL=1 run bash -c "echo hi | '$DISPATCHER' --artifact-dir '$FIXTURE_DIR' --provider p1 --model m --output-file '$OUTPUT_FILE'"
  [ "$status" -eq 0 ]
  [ -f "$STUB_CURL_CAPTURE" ]
  body="$(cat "$STUB_CURL_CAPTURE")"
  [[ "$body" != *"cache_control"* ]]
}

@test "cache_control gate (true,false): default state — request body OMITS cache_control" {
  _write_config_openai "$FIXTURE_DIR" p1 https://127.0.0.1/v1 SOME_KEY true false
  _install_stub_curl
  SOME_KEY=k1 QRSPI_ALLOW_LOCALHOST_BASE_URL=1 run bash -c "echo hi | '$DISPATCHER' --artifact-dir '$FIXTURE_DIR' --provider p1 --model m --output-file '$OUTPUT_FILE'"
  [ "$status" -eq 0 ]
  body="$(cat "$STUB_CURL_CAPTURE")"
  [[ "$body" != *"cache_control"* ]]
}

@test "cache_control gate (false,true): request body OMITS cache_control (capability gate)" {
  _write_config_openai "$FIXTURE_DIR" p1 https://127.0.0.1/v1 SOME_KEY false true
  _install_stub_curl
  SOME_KEY=k1 QRSPI_ALLOW_LOCALHOST_BASE_URL=1 run bash -c "echo hi | '$DISPATCHER' --artifact-dir '$FIXTURE_DIR' --provider p1 --model m --output-file '$OUTPUT_FILE'"
  [ "$status" -eq 0 ]
  body="$(cat "$STUB_CURL_CAPTURE")"
  [[ "$body" != *"cache_control"* ]]
}

@test "cache_control gate (true,true): request body CONTAINS cache_control (ephemeral)" {
  _write_config_openai "$FIXTURE_DIR" p1 https://127.0.0.1/v1 SOME_KEY true true
  _install_stub_curl
  SOME_KEY=k1 QRSPI_ALLOW_LOCALHOST_BASE_URL=1 run bash -c "echo hi | '$DISPATCHER' --artifact-dir '$FIXTURE_DIR' --provider p1 --model m --output-file '$OUTPUT_FILE'"
  [ "$status" -eq 0 ]
  body="$(cat "$STUB_CURL_CAPTURE")"
  [[ "$body" == *"cache_control"* ]]
  [[ "$body" == *"ephemeral"* ]]
}

# ---------------------------------------------------------------------------
# Transport branching: unknown transport_type fail-loud.
# codex-broker branch presence is asserted via the script source so the
# pin holds even when the broker subprocess is unavailable in this sandbox.
# ---------------------------------------------------------------------------

@test "transport branching: unknown transport_type exits 1 with diagnostic" {
  cat > "$FIXTURE_DIR/config.md" <<EOF
---
providers:
  p1:
    base_url: https://api.example.com
    api_key_env: K
    transport_type: bogus-transport
---
EOF
  K=k run bash -c "echo hi | '$DISPATCHER' --artifact-dir '$FIXTURE_DIR' --provider p1 --model m --output-file '$OUTPUT_FILE'"
  [ "$status" -eq 1 ]
  [[ "$output" == *"transport_type"* ]] || [[ "$output" == *"bogus-transport"* ]]
}

@test "transport branching: both openai-chat-completions and codex-broker branches exist in source" {
  run grep -F "openai-chat-completions)" "$DISPATCHER"
  [ "$status" -eq 0 ]
  run grep -F "codex-broker)" "$DISPATCHER"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Exit-code matrix: numeric codes 10/11/13/14/15 documented in source.
# Concrete invocation pins for 10/13/14/15 require a live broker subprocess;
# we pin the documented contract here and the broker-driven paths in
# integration tests.
# ---------------------------------------------------------------------------

@test "exit-code matrix: 0/1/10/11/13/14/15 all named in source contract" {
  for code in 0 1 10 11 13 14 15; do
    run grep -E "^#[[:space:]]+$code[[:space:]]" "$DISPATCHER"
    [ "$status" -eq 0 ] || { echo "missing documented exit code: $code"; false; }
  done
}

# =============================================================================
# Task 1 — Control-character detection: _control_char_check helper
#
# Covers all 12 Test Expectations bullets from tasks/task-01.md:
#   1. Every C0 byte (0x00–0x1F) in a header VALUE causes exit
#   2. Every C0 byte in a header NAME causes exit
#   3. DEL (0x7F) in header VALUE causes exit
#   4. DEL (0x7F) in header NAME causes exit
#   5. LF (0x0A) regression guard — grep record-delimiter false-negative
#   6. NUL (0x00) causes exit, not silent skip
#   7. Empty name/value — no false-positive die
#   8. Printable ASCII (0x20–0x7E) — no false-positive die
#   9. Canonical header-injection payload in VALUE causes exit
#  10. Canonical header-injection payload in NAME causes exit
#  11. _control_char_check body has no grep -P (structural/POSIX-clean assertion)
#  12. Die message identifies offending provider and header name
#
# RED rationale: the current code uses `grep -qP '[\x00-\x1f\x7f]' 2>/dev/null`
# which is silently suppressed on macOS system grep (no PCRE support), making
# header-validation a no-op.  On GNU grep, LF is missed because it is grep's
# own record delimiter.
# =============================================================================

# ---------------------------------------------------------------------------
# Local fixture helpers for control-char tests
# ---------------------------------------------------------------------------

# Write config.md for provider 'ctrl-test-prov' with a single default_header.
# base_url is loopback so a stub curl can absorb any network call that leaks
# through when detection is broken.  Callers must pass
# QRSPI_ALLOW_LOCALHOST_BASE_URL=1 (done by _run_ctrl_check below).
_write_ctrl_config() {
  local adir="$1" hname="$2" hval="$3"
  printf '%s\n' '---'                                    > "$adir/config.md"
  printf '%s\n' 'providers:'                            >> "$adir/config.md"
  printf '%s\n' '  ctrl-test-prov:'                     >> "$adir/config.md"
  printf '%s\n' '    base_url: https://127.0.0.1/v1'   >> "$adir/config.md"
  printf '%s\n' '    api_key_env: CTRL_TEST_KEY'        >> "$adir/config.md"
  printf '%s\n' '    transport_type: openai-chat-completions' >> "$adir/config.md"
  printf '%s\n' '    supports_prompt_cache: false'      >> "$adir/config.md"
  printf '%s\n' '    emit_cache_control_markers: false' >> "$adir/config.md"
  printf '%s\n' '    default_headers:'                  >> "$adir/config.md"
  printf '      %s: %s\n' "$hname" "$hval"              >> "$adir/config.md"
  printf '%s\n' '---' '' '# Config'                     >> "$adir/config.md"
}

# Run the dispatcher for ctrl-test-prov with a stub curl absorbing any
# network call that leaks through when header-validation is broken.
# Tests asserting exit 1 + "header-validation" are RED when broken detection
# permits the stub curl to succeed (exit 0).
_run_ctrl_check() {
  local adir="$1"
  _install_stub_curl
  CTRL_TEST_KEY=dummykey QRSPI_ALLOW_LOCALHOST_BASE_URL=1 run bash -c \
    "printf 'test-prompt\n' | '$DISPATCHER' \
       --artifact-dir '$adir' \
       --provider ctrl-test-prov \
       --model test-model \
       --output-file '$adir/out.txt'"
}

# Extract the _control_char_check function body from the dispatcher into a
# temp file.  Leaves the file empty when the function is not yet defined.
_extract_ctrl_check_fn() {
  local out_file="$1"
  awk '/^_control_char_check[[:space:]]*\(\)/{p=1} p{print} p && /^\}[[:space:]]*$/{p=0; exit}' \
    "$DISPATCHER" > "$out_file"
}

# ---------------------------------------------------------------------------
# Bullet 1 — Every C0 control byte (0x00–0x1F) in a header VALUE causes exit.
# Representative bytes: SOH (0x01), VT (0x0B), ESC (0x1B), US (0x1F).
# NUL (0x00) and LF (0x0A) are covered by their own dedicated bullets.
# ---------------------------------------------------------------------------

@test "[control-char-detect] C0 SOH (0x01) in header value causes exit before network dispatch" {
  # Test expectation: Every C0 control byte (0x00 through 0x1F) supplied as a
  # header value causes the script to exit before reaching any network dispatch call
  _write_ctrl_config "$FIXTURE_DIR" "X-Probe" "safe$(printf '\001')value"
  _run_ctrl_check "$FIXTURE_DIR"
  [ "$status" -eq 1 ]
  [[ "$output" == *"header-validation"* ]]
}

@test "[control-char-detect] C0 VT (0x0B) in header value causes exit before network dispatch" {
  # Test expectation: Every C0 control byte (0x00 through 0x1F) supplied as a
  # header value causes the script to exit before reaching any network dispatch call
  _write_ctrl_config "$FIXTURE_DIR" "X-Probe" "safe$(printf '\013')value"
  _run_ctrl_check "$FIXTURE_DIR"
  [ "$status" -eq 1 ]
  [[ "$output" == *"header-validation"* ]]
}

@test "[control-char-detect] C0 ESC (0x1B) in header value causes exit before network dispatch" {
  # Test expectation: Every C0 control byte (0x00 through 0x1F) supplied as a
  # header value causes the script to exit before reaching any network dispatch call
  _write_ctrl_config "$FIXTURE_DIR" "X-Probe" "safe$(printf '\033')value"
  _run_ctrl_check "$FIXTURE_DIR"
  [ "$status" -eq 1 ]
  [[ "$output" == *"header-validation"* ]]
}

@test "[control-char-detect] C0 US (0x1F) in header value causes exit before network dispatch" {
  # Test expectation: Every C0 control byte (0x00 through 0x1F) supplied as a
  # header value causes the script to exit before reaching any network dispatch call
  _write_ctrl_config "$FIXTURE_DIR" "X-Probe" "safe$(printf '\037')value"
  _run_ctrl_check "$FIXTURE_DIR"
  [ "$status" -eq 1 ]
  [[ "$output" == *"header-validation"* ]]
}

# ---------------------------------------------------------------------------
# Bullet 2 — Every C0 control byte in a header NAME causes exit.
# ---------------------------------------------------------------------------

@test "[control-char-detect] C0 SOH (0x01) in header NAME causes exit before network dispatch" {
  # Test expectation: Every C0 control byte supplied as a header name causes the
  # script to exit before reaching any network dispatch call
  _write_ctrl_config "$FIXTURE_DIR" "X-Probe$(printf '\001')Name" "safe-value"
  _run_ctrl_check "$FIXTURE_DIR"
  [ "$status" -eq 1 ]
  [[ "$output" == *"header-validation"* ]]
}

@test "[control-char-detect] C0 CR (0x0D) in header NAME causes exit before network dispatch" {
  # Test expectation: Every C0 control byte supplied as a header name causes the
  # script to exit before reaching any network dispatch call
  _write_ctrl_config "$FIXTURE_DIR" "X-Probe$(printf '\015')Name" "safe-value"
  _run_ctrl_check "$FIXTURE_DIR"
  [ "$status" -eq 1 ]
  [[ "$output" == *"header-validation"* ]]
}

# ---------------------------------------------------------------------------
# Bullet 3 — DEL (0x7F) in header VALUE causes exit before network dispatch.
# ---------------------------------------------------------------------------

@test "[control-char-detect] DEL (0x7F) in header value causes exit before network dispatch" {
  # Test expectation: DEL (0x7F) in a header value causes the script to exit
  # before any network dispatch
  _write_ctrl_config "$FIXTURE_DIR" "X-Probe" "safe$(printf '\177')value"
  _run_ctrl_check "$FIXTURE_DIR"
  [ "$status" -eq 1 ]
  [[ "$output" == *"header-validation"* ]]
}

# ---------------------------------------------------------------------------
# Bullet 4 — DEL (0x7F) in header NAME causes exit before network dispatch.
# ---------------------------------------------------------------------------

@test "[control-char-detect] DEL (0x7F) in header NAME causes exit before network dispatch" {
  # Test expectation: DEL (0x7F) in a header NAME (not just value) causes the
  # script to exit before any network dispatch
  _write_ctrl_config "$FIXTURE_DIR" "X-Probe$(printf '\177')Name" "safe-value"
  _run_ctrl_check "$FIXTURE_DIR"
  [ "$status" -eq 1 ]
  [[ "$output" == *"header-validation"* ]]
}

# ---------------------------------------------------------------------------
# tc.F01 — Parametric: every C0 byte (0x00–0x1F) in header VALUE causes exit.
# Routes each byte through the appropriate exercise path:
#   NUL (0x00): raw-byte fixture-file pre-flight scan (bash strips NUL at
#               variable assignment, so it never reaches HEADER_VALUES).
#   LF  (0x0A): _extract_ctrl_check_fn function-extraction path (LF is awk's
#               record delimiter and splits the config line during parsing).
#   All other C0 bytes: _write_ctrl_config + _run_ctrl_check integration path.
# Iterates all 32 bytes; each iteration asserts exit-code 1 AND presence of
# "header-validation" in output, with the byte hex printed on failure to
# pinpoint regressions. Pins the contract that the tr deletion range cannot
# silently regress (e.g. widening \040 to \020 would unblock 0x10-0x1F).
# ---------------------------------------------------------------------------

@test "[control-char-detect] parametric: every C0 byte (0x00-0x1F) in header VALUE causes exit" {
  # Test expectation: Every C0 control byte (0x00 through 0x1F) supplied as a
  # header value causes the script to exit before reaching any network dispatch
  # call. Routes each byte through the exercise path that can carry it intact.
  local _byte_octal _byte_hex
  for _byte_octal in \
      000 001 002 003 004 005 006 007 \
      010 011 012 013 014 015 016 017 \
      020 021 022 023 024 025 026 027 \
      030 031 032 033 034 035 036 037; do
    _byte_hex=$(printf '%02x' "0$_byte_octal")
    case "$_byte_octal" in
      000)
        # NUL: bash strips it at variable assignment; must use raw fixture
        # pre-flight scan — the same approach as Bullet 6 (line 560).
        {
          printf '%s\n' '---'
          printf '%s\n' 'providers:'
          printf '%s\n' '  ctrl-test-prov:'
          printf '%s\n' '    base_url: https://127.0.0.1/v1'
          printf '%s\n' '    api_key_env: CTRL_TEST_KEY'
          printf '%s\n' '    transport_type: openai-chat-completions'
          printf '%s\n' '    supports_prompt_cache: false'
          printf '%s\n' '    emit_cache_control_markers: false'
          printf '%s\n' '    default_headers:'
          printf '      X-Param-Test: safe'
          printf '\000'
          printf 'value\n'
          printf '%s\n' '---' '' '# Config'
        } > "$FIXTURE_DIR/config.md"
        _run_ctrl_check "$FIXTURE_DIR"
        [ "$status" -eq 1 ] \
          || { printf 'FAIL: NUL (0x%s) in VALUE did not cause exit 1\n' "$_byte_hex" >&2; return 1; }
        [[ "$output" == *"header-validation"* ]] \
          || { printf 'FAIL: 0x%s in VALUE — missing header-validation in output\n' "$_byte_hex" >&2; return 1; }
        ;;
      012)
        # LF: cannot survive awk line-based config parse into HEADER_VALUES;
        # exercise _control_char_check directly via function-extraction path.
        local _fn_file_val="$FIXTURE_DIR/ctrl_fn_val_${_byte_hex}.sh"
        _extract_ctrl_check_fn "$_fn_file_val"
        [ -s "$_fn_file_val" ] \
          || { printf 'FAIL: could not extract _control_char_check for 0x%s\n' "$_byte_hex" >&2; return 1; }
        local _ts_val="$FIXTURE_DIR/byte_val_test_${_byte_hex}.sh"
        {
          printf '%s\n' '#!/usr/bin/env bash'
          printf 'die() { printf "%%s\n" "$1" >&2; exit 1; }\n'
          printf '. %s\n' "'$_fn_file_val'"
          printf '_control_char_check %s ' "'x-param-val-header'"
          printf "'"
          printf 'safe'
          printf '\012'
          printf "injected'\n"
        } > "$_ts_val"
        run bash "$_ts_val"
        [ "$status" -eq 1 ] \
          || { printf 'FAIL: LF (0x%s) in VALUE did not cause exit 1\n' "$_byte_hex" >&2; return 1; }
        [[ "$output" == *"header-validation"* ]] \
          || { printf 'FAIL: 0x%s in VALUE — missing header-validation in output\n' "$_byte_hex" >&2; return 1; }
        ;;
      *)
        # All other C0 bytes: end-to-end integration path via _write_ctrl_config.
        _write_ctrl_config "$FIXTURE_DIR" "X-Param-Test" "safe$(printf "\\$_byte_octal")value"
        _run_ctrl_check "$FIXTURE_DIR"
        [ "$status" -eq 1 ] \
          || { printf 'FAIL: byte 0x%s in VALUE did not cause exit 1\n' "$_byte_hex" >&2; return 1; }
        [[ "$output" == *"header-validation"* ]] \
          || { printf 'FAIL: byte 0x%s in VALUE — missing header-validation in output\n' "$_byte_hex" >&2; return 1; }
        ;;
    esac
  done
}

# ---------------------------------------------------------------------------
# tc.F01 — Parametric: every C0 byte (0x00–0x1F) in header NAME causes exit.
# Routes each byte through the appropriate exercise path:
#   NUL (0x00): raw-byte fixture-file pre-flight scan (bash strips NUL at
#               variable assignment, so it never reaches the awk config parse).
#   LF  (0x0A): _extract_ctrl_check_fn function-extraction path (LF is awk's
#               record delimiter and splits the config line during parsing).
#   CR  (0x0D): _extract_ctrl_check_fn function-extraction path (CR in a header
#               name disrupts awk record splitting on some platforms).
#   All other C0 bytes: _write_ctrl_config + _run_ctrl_check integration path.
# Iterates all 32 bytes; each iteration asserts exit-code 1 AND presence of
# "header-validation" in output, with the byte hex printed on failure.
# ---------------------------------------------------------------------------

@test "[control-char-detect] parametric: every C0 byte (0x00-0x1F) in header NAME causes exit" {
  # Test expectation: Every C0 control byte (0x00 through 0x1F) supplied as a
  # header name causes the script to exit before reaching any network dispatch
  # call. Routes each byte through the exercise path that can carry it intact.
  local _byte_octal _byte_hex
  for _byte_octal in \
      000 001 002 003 004 005 006 007 \
      010 011 012 013 014 015 016 017 \
      020 021 022 023 024 025 026 027 \
      030 031 032 033 034 035 036 037; do
    _byte_hex=$(printf '%02x' "0$_byte_octal")
    case "$_byte_octal" in
      000)
        # NUL: bash strips it at variable assignment; use raw fixture
        # pre-flight scan with NUL embedded in the header name area.
        {
          printf '%s\n' '---'
          printf '%s\n' 'providers:'
          printf '%s\n' '  ctrl-test-prov:'
          printf '%s\n' '    base_url: https://127.0.0.1/v1'
          printf '%s\n' '    api_key_env: CTRL_TEST_KEY'
          printf '%s\n' '    transport_type: openai-chat-completions'
          printf '%s\n' '    supports_prompt_cache: false'
          printf '%s\n' '    emit_cache_control_markers: false'
          printf '%s\n' '    default_headers:'
          printf '      X-Nul'
          printf '\000'
          printf 'Name: safe-value\n'
          printf '%s\n' '---' '' '# Config'
        } > "$FIXTURE_DIR/config.md"
        _run_ctrl_check "$FIXTURE_DIR"
        [ "$status" -eq 1 ] \
          || { printf 'FAIL: NUL (0x%s) in NAME did not cause exit 1\n' "$_byte_hex" >&2; return 1; }
        [[ "$output" == *"header-validation"* ]] \
          || { printf 'FAIL: 0x%s in NAME — missing header-validation in output\n' "$_byte_hex" >&2; return 1; }
        ;;
      012|015)
        # LF/CR: cannot survive awk record splitting cleanly; exercise
        # _control_char_check directly via function-extraction path.
        local _fn_file_name="$FIXTURE_DIR/ctrl_fn_name_${_byte_hex}.sh"
        _extract_ctrl_check_fn "$_fn_file_name"
        [ -s "$_fn_file_name" ] \
          || { printf 'FAIL: could not extract _control_char_check for 0x%s\n' "$_byte_hex" >&2; return 1; }
        local _ts_name="$FIXTURE_DIR/byte_name_test_${_byte_hex}.sh"
        {
          printf '%s\n' '#!/usr/bin/env bash'
          printf 'die() { printf "%%s\n" "$1" >&2; exit 1; }\n'
          printf '. %s\n' "'$_fn_file_name'"
          printf '_control_char_check '
          printf "'"
          printf 'X-Param'
          printf "\\$_byte_octal"
          printf "Name'"
          printf ' '
          printf "'safe-value'\n"
        } > "$_ts_name"
        run bash "$_ts_name"
        [ "$status" -eq 1 ] \
          || { printf 'FAIL: byte 0x%s in NAME did not cause exit 1\n' "$_byte_hex" >&2; return 1; }
        [[ "$output" == *"header-validation"* ]] \
          || { printf 'FAIL: byte 0x%s in NAME — missing header-validation in output\n' "$_byte_hex" >&2; return 1; }
        ;;
      *)
        # All other C0 bytes: end-to-end integration path via _write_ctrl_config.
        _write_ctrl_config "$FIXTURE_DIR" "X-Param$(printf "\\$_byte_octal")Name" "safe-value"
        _run_ctrl_check "$FIXTURE_DIR"
        [ "$status" -eq 1 ] \
          || { printf 'FAIL: byte 0x%s in NAME did not cause exit 1\n' "$_byte_hex" >&2; return 1; }
        [[ "$output" == *"header-validation"* ]] \
          || { printf 'FAIL: byte 0x%s in NAME — missing header-validation in output\n' "$_byte_hex" >&2; return 1; }
        ;;
    esac
  done
}

# ---------------------------------------------------------------------------
# Bullet 5 — LF (0x0A) regression guard.
# LF is grep's record delimiter: `printf 'a\nb' | grep -qP '[\x0a]'` returns
# false-negative on GNU grep even when -P is available.  On macOS the entire
# grep -P call is silently suppressed by 2>/dev/null.
# LF cannot survive the awk line-based config parse into HEADER_VALUES so
# _control_char_check is exercised directly via function extraction.
# ---------------------------------------------------------------------------

@test "[control-char-detect] LF (0x0A) caught by _control_char_check - regression guard for grep record-delimiter gap" {
  # Test expectation: LF (0x0A / 0x0a) in a header value causes the script to
  # exit -- this is the explicit regression guard for the prior grep gap where
  # LF was silently missed because it is grep's record delimiter
  local fn_file="$FIXTURE_DIR/ctrl_fn.sh"
  _extract_ctrl_check_fn "$fn_file"
  # Guard: function must be extractable — fails loud if accidentally removed.
  [ -s "$fn_file" ]

  # Build a test script that passes a literal LF-containing string to the
  # function.  Single-quoted strings spanning newlines are valid bash.
  # A die() stub ensures the function's die call exits non-zero even when
  # the die helper is not in scope.
  local test_script="$FIXTURE_DIR/lf_test.sh"
  {
    printf '%s\n' '#!/usr/bin/env bash'
    printf 'die() { exit 1; }\n'
    printf '. %s\n' "'$fn_file'"
    printf '_control_char_check %s ' "'x-lf-header'"
    printf "'"
    printf 'safe'
    printf '\012'
    printf "injected'\n"
  } > "$test_script"

  run bash "$test_script"
  [ "$status" -eq 1 ]
}

# ---------------------------------------------------------------------------
# Bullet 6 — NUL (0x00) causes exit, not silent skip.
# NUL is stripped by bash variable assignment so it never reaches HEADER_VALUES
# via the normal awk-to-bash path.  The implementation detects it via a
# raw-byte scan of the config file that runs before the awk parse.
# ---------------------------------------------------------------------------

@test "[control-char-detect] NUL (0x00) in header value causes exit not silent skip or binary false-negative" {
  # Test expectation: NUL (0x00) in a header value causes exit, not a silent
  # skip or binary-mode false negative
  {
    printf '%s\n' '---'
    printf '%s\n' 'providers:'
    printf '%s\n' '  ctrl-test-prov:'
    printf '%s\n' '    base_url: https://127.0.0.1/v1'
    printf '%s\n' '    api_key_env: CTRL_TEST_KEY'
    printf '%s\n' '    transport_type: openai-chat-completions'
    printf '%s\n' '    supports_prompt_cache: false'
    printf '%s\n' '    emit_cache_control_markers: false'
    printf '%s\n' '    default_headers:'
    printf '      X-Nul-Test: safe'
    printf '\000'
    printf 'injected\n'
    printf '%s\n' '---' '' '# Config'
  } > "$FIXTURE_DIR/config.md"
  _run_ctrl_check "$FIXTURE_DIR"
  [ "$status" -eq 1 ]
  [[ "$output" == *"header-validation"* ]]
  # Diagnostic precision: NUL die message names the provider but is carved out
  # from the header-name requirement, because bash strips NUL at variable
  # assignment so the file-scope pre-flight scan runs before the awk parse can
  # extract header names. See task-01.md test-expectations bullet on die
  # message format for the NUL carve-out rationale.
  [[ "$output" == *"ctrl-test-prov"* ]]
  [[ "$output" == *"NUL"* ]]
}

# ---------------------------------------------------------------------------
# Bullet 7 — Empty header name and empty value do NOT trigger false-positive.
# Tested via direct _control_char_check call.
# ---------------------------------------------------------------------------

@test "[control-char-detect] empty header name and empty value do not trigger false-positive die" {
  # Test expectation: An empty header name and an empty header value do not
  # trigger the die path (no false positive on empty input)
  local fn_file="$FIXTURE_DIR/ctrl_fn.sh"
  _extract_ctrl_check_fn "$fn_file"
  # Guard: function must be extractable — fails loud if accidentally removed.
  [ -s "$fn_file" ]

  run bash -c "die() { exit 1; }; . '$fn_file'; _control_char_check '' ''"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Bullet 8 — Printable ASCII (0x20-0x7E) does NOT trigger die path.
# Tested via direct _control_char_check call.
# ---------------------------------------------------------------------------

@test "[control-char-detect] printable-ASCII-only header does not trigger die path" {
  # Test expectation: A header containing only printable ASCII characters
  # (0x20 through 0x7E) does not trigger the die path and allows execution
  # to continue
  local fn_file="$FIXTURE_DIR/ctrl_fn.sh"
  _extract_ctrl_check_fn "$fn_file"
  # Guard: function must be extractable — fails loud if accidentally removed.
  [ -s "$fn_file" ]

  run bash -c "die() { exit 1; }; . '$fn_file'; _control_char_check 'X-Custom-Header' 'Bearer safe-token_v1.2+ok!'"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Bullet 9 — Canonical header-injection payload in VALUE causes exit.
# CR (0x0D) immediately after printable text is the CRLF-injection vector.
# (LF would split the config.md line; CR alone stays on one line through
#  the awk parser and is sufficient to exercise the injection path.)
# ---------------------------------------------------------------------------

@test "[control-char-detect] CR-injection payload in header value causes exit before network dispatch" {
  # Test expectation: A header value containing printable text immediately
  # followed by a control byte (e.g., printable ASCII then CR or LF then more
  # printable text, representing a canonical header-injection payload) causes
  # the script to exit before any network dispatch
  _write_ctrl_config "$FIXTURE_DIR" "X-Auth" \
    "Bearer safe-token$(printf '\015')X-Injected: evil"
  _run_ctrl_check "$FIXTURE_DIR"
  [ "$status" -eq 1 ]
  [[ "$output" == *"header-validation"* ]]
}

# ---------------------------------------------------------------------------
# Bullet 10 — Canonical header-injection payload in NAME causes exit.
# CR in a header name is the name-side CRLF-injection vector.
# ---------------------------------------------------------------------------

@test "[control-char-detect] CR-injection payload in header NAME causes exit before network dispatch" {
  # Test expectation: A header NAME containing printable ASCII immediately
  # followed by a control byte then more printable ASCII (canonical name-side
  # injection payload like Header-Name\r\nInjected) causes the script to exit
  # before any network dispatch
  # Note: LF splits config.md lines; CR alone captures the injection vector.
  _write_ctrl_config "$FIXTURE_DIR" "X-Real$(printf '\015')X-Injected" "safe-value"
  _run_ctrl_check "$FIXTURE_DIR"
  [ "$status" -eq 1 ]
  [[ "$output" == *"header-validation"* ]]
}

# ---------------------------------------------------------------------------
# Bullet 11 — Structural: _control_char_check body must not use grep -P.
# PCRE (-P) is absent from macOS system grep; 2>/dev/null turned detection
# into a silent no-op there.  The replacement must be POSIX-clean.
# ---------------------------------------------------------------------------

@test "[control-char-detect] _control_char_check helper body contains no grep -P (POSIX-clean structural assertion)" {
  # Test expectation: The _control_char_check helper is implemented without any
  # grep -P invocation (structural code-pattern assertion)
  local fn_file="$FIXTURE_DIR/ctrl_fn.sh"
  _extract_ctrl_check_fn "$fn_file"
  # Guard: function must be extractable — fails loud if accidentally removed.
  [ -s "$fn_file" ]

  # The extracted function body must contain no grep -P flag in any form.
  run grep -E 'grep[[:space:]]+-[^[:space:]]*P' "$fn_file"
  [ "$status" -ne 0 ]
}

# ---------------------------------------------------------------------------
# Bullet 12 — Die message identifies offending provider and header name.
# ---------------------------------------------------------------------------

@test "[control-char-detect] die message identifies offending provider name and header name" {
  # Test expectation: The die message identifies the offending provider and
  # header name, matching the existing message format
  _write_ctrl_config "$FIXTURE_DIR" "X-Named-Header" "safe$(printf '\033')injected"
  _run_ctrl_check "$FIXTURE_DIR"
  [ "$status" -eq 1 ]
  [[ "$output" == *"header-validation"* ]]
  [[ "$output" == *"ctrl-test-prov"* ]]
  [[ "$output" == *"X-Named-Header"* ]]
}

# ---------------------------------------------------------------------------
# _control_char_check must NOT reject non-ASCII (0x80-0xFF).
# Spec covers C0 (0x00-0x1F) and DEL (0x7F) only; bytes 0x80-0xFF are not
# in scope and must not cause spurious abort (false-positive DoS).
# ---------------------------------------------------------------------------

@test "[control-char-detect] non-ASCII byte (0x80) in header value does NOT trigger false-positive die" {
  # Spec: covered byte ranges are C0 (0x00-0x1F) and DEL (0x7F).
  # Bytes 0x80-0xFF (UTF-8 continuation, Latin-1 extended, C1 controls) are
  # outside spec scope and must not trigger the die path.
  # Tested via direct function call because the awk config parser drops
  # non-ASCII bytes from config.md before they reach HEADER_VALUES.
  local fn_file="$FIXTURE_DIR/ctrl_fn.sh"
  _extract_ctrl_check_fn "$fn_file"
  [ -s "$fn_file" ]

  run bash -c "die() { exit 1; }; . '$fn_file'; _control_char_check 'X-Header' 'safe$(printf '\200')value'"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# NUL pre-flight must die when the byte-count pipeline returns empty
# (fail-closed on tool failure, not fail-open).  A stub wc that outputs
# nothing simulates a pipeline / tool failure.  Without the numeric guard
# the comparison is silently skipped (fail-open).  With the guard the script
# dies with a "failed to compute" diagnostic.  A config without
# default_headers is used so _control_char_check (which also calls wc) is
# never reached; only the NUL pre-flight uses wc here.
# ---------------------------------------------------------------------------

@test "[control-char-detect] NUL pre-flight fails closed when byte-count pipeline returns empty" {
  # Config with NUL bytes in the file body but no default_headers entry so
  # the header-loop wc call is never reached.
  {
    printf '%s\n' '---'
    printf '%s\n' 'providers:'
    printf '%s\n' '  ctrl-test-prov:'
    printf '%s\n' '    base_url: https://127.0.0.1/v1'
    printf '%s\n' '    api_key_env: CTRL_TEST_KEY'
    printf '%s\n' '    transport_type: openai-chat-completions'
    printf '%s\n' '    supports_prompt_cache: false'
    printf '%s\n' '    emit_cache_control_markers: false'
    printf '%s\n' '---'
    printf 'body with '
    printf '\000'
    printf ' nul byte\n'
    printf '%s\n' '# Config'
  } > "$FIXTURE_DIR/config.md"
  # Stub wc in the same bin dir that _install_stub_curl uses so PATH sees it.
  mkdir -p "$FIXTURE_DIR/bin"
  printf '%s\n' '#!/usr/bin/env bash' > "$FIXTURE_DIR/bin/wc"
  chmod +x "$FIXTURE_DIR/bin/wc"
  _install_stub_curl
  CTRL_TEST_KEY=dummykey QRSPI_ALLOW_LOCALHOST_BASE_URL=1 run bash -c \
    "printf 'test-prompt\n' | '$DISPATCHER' \
       --artifact-dir '$FIXTURE_DIR' \
       --provider ctrl-test-prov \
       --model test-model \
       --output-file '$FIXTURE_DIR/out.txt'"
  [ "$status" -eq 1 ]
  [[ "$output" == *"failed to compute"* ]]
}

# ---------------------------------------------------------------------------
# API key value must be screened for control characters before being placed
# into the Authorization header.  A clean config with no custom-header
# control chars is used so only the API key check is the failing gate.
# ---------------------------------------------------------------------------

@test "[control-char-detect] API key containing control character causes exit before network dispatch" {
  # API key is used verbatim in the Authorization header; a control char in
  # the key value must trigger the same die path as default_headers violations.
  _write_ctrl_config "$FIXTURE_DIR" "X-Safe" "safe-value"
  _install_stub_curl
  # CR (0x0D) embedded in the key is a canonical CRLF-injection vector.
  CTRL_TEST_KEY="sk-ok$(printf '\015')X-Injected: evil" QRSPI_ALLOW_LOCALHOST_BASE_URL=1 run bash -c \
    "printf 'test-prompt\n' | '$DISPATCHER' \
       --artifact-dir '$FIXTURE_DIR' \
       --provider ctrl-test-prov \
       --model test-model \
       --output-file '$FIXTURE_DIR/out.txt'"
  [ "$status" -eq 1 ]
  [[ "$output" == *"header-validation"* ]]
}

# ---------------------------------------------------------------------------
# set -o pipefail must appear in the dispatcher script so that intermediate
# pipeline failures are not silently masked by the final stage's exit code.
# Without pipefail, a crashed tool in the middle of a pipeline exits 0 if
# the final stage succeeds, silently hiding security-critical failures.
# ---------------------------------------------------------------------------

@test "[script-hygiene] set -o pipefail appears in dispatcher script" {
  # Guards against regressions that would remove pipefail and silently mask
  # intermediate pipeline failures in security-critical paths (e.g. the NUL
  # pre-flight and _control_char_check pipelines).
  run grep -F 'set -o pipefail' "$DISPATCHER"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# _control_char_check must fail closed when its byte-count pipeline returns
# empty or non-numeric output (e.g. due to SIGPIPE or tool failure).
# Without a numeric validity guard, [ "" -eq 0 ] silently succeeds and
# control characters pass through undetected (fail-open).  The case guard
# must die with a "failed to compute byte count" diagnostic instead.
# Structural assertion: the case guard pattern exists in the helper body.
# ---------------------------------------------------------------------------

@test "[control-char-detect] _control_char_check body contains numeric guard for empty/non-numeric byte count" {
  # Guards against a fail-open regression where a crashed pipeline emits no
  # output and the arithmetic test [ "" -eq 0 ] silently succeeds, allowing
  # control characters to pass through undetected.
  local fn_file="$FIXTURE_DIR/ctrl_fn.sh"
  _extract_ctrl_check_fn "$fn_file"
  [ -s "$fn_file" ]

  # The function body must contain the fail-closed numeric validity guard.
  run grep -F "''|*[!0-9]*)" "$fn_file"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Control bytes in a header name must be sanitised before embedding in the
# die message.  A raw ESC byte (0x1B) in a die message can trigger terminal
# escape sequences (e.g. erase-line, cursor-up) that hide the security abort
# notification from the operator.  All C0 and DEL bytes must be replaced with
# a safe substitute (e.g. '?') before the message is emitted.
# ---------------------------------------------------------------------------

@test "[control-char-detect] ESC byte in header name is sanitised in die message (no raw 0x1B in output)" {
  # Guards against terminal-manipulation via raw ESC sequences in die messages:
  # an attacker-controlled header name containing ESC sequences could erase
  # terminal output and hide the security abort notification.
  local fn_file="$FIXTURE_DIR/ctrl_fn.sh"
  _extract_ctrl_check_fn "$fn_file"
  [ -s "$fn_file" ]

  # Call _control_char_check with an ESC byte in the header name.
  # The die message must not contain the raw ESC byte (0x1B).
  local esc_byte
  esc_byte=$(printf '\033')
  run bash -c "
    die() { printf '%s\n' \"\$1\" >&2; exit 1; }
    . '$fn_file'
    _control_char_check 'X-Header${esc_byte}ESC' 'safe-value'
  "
  [ "$status" -eq 1 ]
  # The output must still identify it as a header-validation failure.
  # (Use [[ ]] for positive glob match; [ ] is used for the ESC count below.)
  [[ "$output" == *"header-validation"* ]]
  # The raw ESC byte (0x1B) must NOT appear in the output.
  # Use [ ] (not [[ ]]) so a non-zero count properly fails the test via bats ERR trap.
  local _esc_count
  _esc_count=$(printf '%s' "$output" | LC_ALL=C tr -cd '\033' | wc -c | tr -d ' \t')
  [ "$_esc_count" -eq 0 ]
}

# ---------------------------------------------------------------------------
# die message for an API key control-char violation must NOT contain the
# text "default_headers".  The API key is checked via the same helper as
# default_headers, but the die message must not point operators at the wrong
# config block when the violation source is the API key field.
# ---------------------------------------------------------------------------

@test "[control-char-detect] die message for API-key control-char does not contain 'default_headers'" {
  # Guards against a misleading die message that says "default_headers" even
  # when the violation is in the API key, causing operators to waste time
  # inspecting the wrong config block.
  _write_ctrl_config "$FIXTURE_DIR" "X-Safe" "safe-value"
  _install_stub_curl
  # CR (0x0D) embedded in the key is a canonical CRLF-injection vector.
  CTRL_TEST_KEY="sk-ok$(printf '\015')injected" QRSPI_ALLOW_LOCALHOST_BASE_URL=1 run bash -c \
    "printf 'test-prompt\n' | '$DISPATCHER' \
       --artifact-dir '$FIXTURE_DIR' \
       --provider ctrl-test-prov \
       --model test-model \
       --output-file '$FIXTURE_DIR/out.txt'"
  [ "$status" -eq 1 ]
  [[ "$output" == *"header-validation"* ]]
  # Must NOT blame the wrong config block.
  # Save $output before overwriting with a second run; use [ ] so failures are caught.
  local _saved_output="$output"
  run grep -F 'default_headers' <<< "$_saved_output"
  [ "$status" -ne 0 ]
}

# ---------------------------------------------------------------------------
# _cc_safe_hname variable must follow the _cc_ prefix convention used by all
# other locals in _control_char_check (_cc_hname, _cc_hval, _cc_count), and
# the sanitisation assignment must include a fallback clause so that a
# tr-pipeline failure (SIGPIPE, locale fault, resource exhaustion) produces a
# meaningful diagnostic rather than silently producing an empty string.
# ---------------------------------------------------------------------------

@test "[script-hygiene] _cc_safe_hname assignment has fallback clause for tr-pipeline failure" {
  # Guards against two regressions:
  # 1. The local variable must be named _cc_safe_hname (not _safe_hname) to
  #    match the _cc_ prefix convention used by the other locals in the helper.
  # 2. The assignment must have a fallback (|| ...) so that a tr-pipeline
  #    failure does not silently produce an empty string in the die message.
  run grep -F '_cc_safe_hname=$(printf' "$BATS_TEST_DIRNAME/../../scripts/run-third-party-llm.sh"
  [ "$status" -eq 0 ]
  run grep -E '\|\| _cc_safe_hname=' "$BATS_TEST_DIRNAME/../../scripts/run-third-party-llm.sh"
  [ "$status" -eq 0 ]
}

@test "[control-char-detect] tr-pipeline failure in _cc_safe_hname assignment produces fallback diagnostic string" {
  # Guards against silent loss of the field name in die messages when the
  # sanitisation pipeline fails (SIGPIPE, locale fault, resource exhaustion).
  # Without the fallback, set -o pipefail + assignment failure leaves
  # _cc_safe_hname empty, stripping the field name from the operator message.
  local fn_file="$FIXTURE_DIR/ctrl_fn.sh"
  _extract_ctrl_check_fn "$fn_file"
  [ -s "$fn_file" ]

  # Stub tr to exit 1 (simulates pipeline failure) via a PATH-prepended shim.
  local stub_dir="$FIXTURE_DIR/stubs"
  mkdir -p "$stub_dir"
  printf '#!/bin/sh\nexit 1\n' > "$stub_dir/tr"
  chmod +x "$stub_dir/tr"

  # Invoke _control_char_check with a control byte in the value so the helper
  # reaches the die path.  The stubbed tr will fail the sanitisation pipeline.
  # The fallback string must appear in the die output.
  run bash -c "
    die() { printf '%s\n' \"\$1\" >&2; exit 1; }
    export PATH='$stub_dir:\$PATH'
    . '$fn_file'
    _control_char_check 'X-Header' \"\$(printf 'bad\001val')\"
  "
  [ "$status" -eq 1 ]
  # The fallback message must appear in the output (either fragment suffices).
  local _found=0
  printf '%s' "$output" | grep -qF '(field name unavailable' && _found=1
  printf '%s' "$output" | grep -qF 'sanitisation pipeline failed' && _found=1
  [ "$_found" -eq 1 ]
}
