#!/usr/bin/env bats
#
# T36 Slice 7 G4 Mechanism A unit pin — dual-flag cache_control emission gate
# observed via direct invocation of the T03 universal dispatcher.
#
# Invokes scripts/run-third-party-llm.sh against fixture providers exercising
# all four cells of the supports_prompt_cache: x emit_cache_control_markers:
# truth table:
#   (a) (false, false)  — request body OMITS cache_control
#   (b) (true, false)   — request body OMITS cache_control (default state at
#                         T03 ship; critical to T33 spike measurement integrity)
#   (c) (false, true)   — request body OMITS cache_control (capability gate)
#   (d) (true, true)    — request body CONTAINS cache_control (ephemeral)
#
# All four fixtures use transport_type: openai-chat-completions so the
# dispatcher assembles a chat-completions JSON body the test can observe
# directly. transport_type: codex-broker is NOT exercised here (broker
# defers JSON assembly to a subprocess, which would make the request-body
# assertion vacuous — that decision is documented in the T36 spec).
#
# Bash 3.2 portable.

load '../helpers/skill-markdown'

setup_file() {
  require_repo_root
  DISPATCHER="$REPO_ROOT/scripts/run-third-party-llm.sh"
  [ -f "$DISPATCHER" ] || { echo "dispatcher missing" >&2; return 1; }
  export DISPATCHER
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

_write_provider() {
  # $1=spc $2=ecmm
  cat > "$FIXTURE_DIR/config.md" <<EOF
---
providers:
  testprov:
    base_url: https://127.0.0.1/v1
    api_key_env: TEST_KEY
    transport_type: openai-chat-completions
    supports_prompt_cache: $1
    emit_cache_control_markers: $2
---
EOF
}

# Stub curl that captures the request body to $STUB_CURL_CAPTURE and returns
# a canned successful response so the dispatcher exits 0.
_install_stub_curl() {
  local stub_dir="$FIXTURE_DIR/bin"
  local capture="$FIXTURE_DIR/curl-request-body.json"
  export STUB_CURL_CAPTURE="$capture"
  mkdir -p "$stub_dir"
  cat > "$stub_dir/curl" <<'CURL_EOF'
#!/usr/bin/env bash
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

@test "cell (a) (false,false): request body OMITS cache_control" {
  _write_provider false false
  _install_stub_curl
  TEST_KEY=k QRSPI_ALLOW_LOCALHOST_BASE_URL=1 run bash -c "echo p | bash '$DISPATCHER' --artifact-dir '$FIXTURE_DIR' --provider testprov --model m --output-file '$OUTPUT_FILE'"
  [ "$status" -eq 0 ]
  body="$(cat "$STUB_CURL_CAPTURE")"
  [[ "$body" != *"cache_control"* ]]
}

@test "cell (b) (true,false): default state — request body OMITS cache_control (T33 spike-integrity)" {
  _write_provider true false
  _install_stub_curl
  TEST_KEY=k QRSPI_ALLOW_LOCALHOST_BASE_URL=1 run bash -c "echo p | bash '$DISPATCHER' --artifact-dir '$FIXTURE_DIR' --provider testprov --model m --output-file '$OUTPUT_FILE'"
  [ "$status" -eq 0 ]
  body="$(cat "$STUB_CURL_CAPTURE")"
  [[ "$body" != *"cache_control"* ]]
}

@test "cell (c) (false,true): capability gate — request body OMITS cache_control" {
  _write_provider false true
  _install_stub_curl
  TEST_KEY=k QRSPI_ALLOW_LOCALHOST_BASE_URL=1 run bash -c "echo p | bash '$DISPATCHER' --artifact-dir '$FIXTURE_DIR' --provider testprov --model m --output-file '$OUTPUT_FILE'"
  [ "$status" -eq 0 ]
  body="$(cat "$STUB_CURL_CAPTURE")"
  [[ "$body" != *"cache_control"* ]]
}

@test "cell (d) (true,true): emission ON — request body CONTAINS cache_control: ephemeral" {
  _write_provider true true
  _install_stub_curl
  TEST_KEY=k QRSPI_ALLOW_LOCALHOST_BASE_URL=1 run bash -c "echo p | bash '$DISPATCHER' --artifact-dir '$FIXTURE_DIR' --provider testprov --model m --output-file '$OUTPUT_FILE'"
  [ "$status" -eq 0 ]
  body="$(cat "$STUB_CURL_CAPTURE")"
  [[ "$body" == *"cache_control"* ]]
  [[ "$body" == *"ephemeral"* ]]
}

# ---------------------------------------------------------------------------
# Capability-gate-and-emission-gate co-located contract:
# both "capability gate" (no markers to providers without prompt-cache
# support, regardless of emission flag) AND "emission gate" (no markers
# by default even when the provider supports caching, preserving T33
# spike-measurement integrity) must hold simultaneously. The four cells
# above co-locate that observation: only (d) emits.
# ---------------------------------------------------------------------------

@test "co-located contract: only (true,true) emits — three other cells uniformly suppress" {
  # Re-run all four cells in-test to assert the truth table as a single
  # observation (one fixture set, one PATH, one stub curl).
  local cell_a_body cell_b_body cell_c_body cell_d_body
  for cell in a b c d; do
    rm -rf "$FIXTURE_DIR/bin"
    case "$cell" in
      a) _write_provider false false ;;
      b) _write_provider true false ;;
      c) _write_provider false true ;;
      d) _write_provider true true ;;
    esac
    _install_stub_curl
    TEST_KEY=k QRSPI_ALLOW_LOCALHOST_BASE_URL=1 bash -c "echo p | bash '$DISPATCHER' --artifact-dir '$FIXTURE_DIR' --provider testprov --model m --output-file '$OUTPUT_FILE'"
    rc=$?
    [ "$rc" -eq 0 ]
    case "$cell" in
      a) cell_a_body="$(cat "$STUB_CURL_CAPTURE")" ;;
      b) cell_b_body="$(cat "$STUB_CURL_CAPTURE")" ;;
      c) cell_c_body="$(cat "$STUB_CURL_CAPTURE")" ;;
      d) cell_d_body="$(cat "$STUB_CURL_CAPTURE")" ;;
    esac
  done
  [[ "$cell_a_body" != *"cache_control"* ]]
  [[ "$cell_b_body" != *"cache_control"* ]]
  [[ "$cell_c_body" != *"cache_control"* ]]
  [[ "$cell_d_body" == *"cache_control"* ]]
}
