#!/usr/bin/env bash
# run-third-party-llm.sh — Universal stdin-prompt dispatcher for QRSPI.
#
# Reads the prompt from stdin ONLY; any positional argument or --prompt-file
# exits 1 with a validation diagnostic.  Resolves the named provider from
# <artifact-dir>/config.md, branches on transport_type:, blocks until the
# result is written to --output-file, and emits numbered exit codes.
#
# Usage:
#   run-third-party-llm.sh \
#     --artifact-dir <path>      # required; absolute path to artifact directory
#     --provider <name>          # required; matches a providers: entry in config.md
#     --model <id>               # required; concrete model identifier
#     --output-file <path>       # required; absolute path; populated atomically on exit 0
#     [--scope-hint <text>]      # optional; passthrough to reviewer adapters
#     [--timeout-seconds <int>]  # optional; transport adapter default applies when absent
#
# Exit codes:
#   0   success; --output-file populated
#   1   validation / argument / missing-key failure
#   10  upstream timeout
#   11  job not found (broker disk-state fallback exhausted)
#   13  result hard-error from upstream
#   14  malformed result body
#   15  phantom-launch (broker returned jobId with no backing job)
#
# Bash 3.2 portability contract (macOS system /bin/bash):
#   - No mapfile / readarray
#   - No declare -A (associative arrays)
#   - No ${var,,} or ${var^^} (case conversion)
#   - No coproc
#   - No wait -n

set -u

# Resolve the directory containing this script so we can source lib/ reliably.
_SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Source shared prompt-utils library.
# shellcheck source=scripts/lib/llm-prompt-utils.sh
. "$_SCRIPT_DIR/lib/llm-prompt-utils.sh"

# ---------------------------------------------------------------------------
# die <message>  — write message to stderr and exit 1
die() {
  printf 'run-third-party-llm: %s\n' "$1" >&2
  exit 1
}

# ---------------------------------------------------------------------------
# parse_provider_block <config_file> <provider_name>
#
# Extracts the named provider entry from the config.md YAML frontmatter.
# Outputs tab-separated records of three fields each:
#   field  <key>  <value>
#   header <header-name>  <header-value>
#
# Exits awk 1 if the provider name is not found.
parse_provider_block() {
  local config_file="$1" provider_name="$2"
  awk -v want="$provider_name" '
    BEGIN { in_fm=0; fm_count=0; in_providers=0; in_target=0; in_headers=0; found=0 }
    /^---$/ {
      fm_count++
      if (fm_count == 1) { in_fm=1; next }
      if (fm_count == 2) { in_fm=0; exit 0 }
    }
    !in_fm { next }
    /^providers:[[:space:]]*$/ { in_providers=1; next }
    /^[^ ]/ { in_providers=0; in_target=0; in_headers=0; next }
    in_providers && /^  [^ ]/ {
      key=$0
      sub(/^[[:space:]]+/, "", key)
      sub(/:.*$/, "", key)
      if (key == want) {
        in_target=1; in_headers=0; found=1
      } else {
        in_target=0; in_headers=0
      }
      next
    }
    in_target && /^    default_headers:[[:space:]]*$/ { in_headers=1; next }
    in_target && in_headers && /^      [^ ]/ {
      line=$0
      sub(/^[[:space:]]+/, "", line)
      colon=index(line, ":")
      if (colon > 0) {
        hname=substr(line, 1, colon-1)
        hval=substr(line, colon+1)
        sub(/^[[:space:]]+/, "", hval)
        sub(/[[:space:]]+$/, "", hval)
        print "header\t" hname "\t" hval
      }
      next
    }
    in_target && /^    [^ ]/ {
      in_headers=0
      line=$0
      sub(/^[[:space:]]+/, "", line)
      colon=index(line, ":")
      if (colon > 0) {
        k=substr(line, 1, colon-1)
        v=substr(line, colon+1)
        sub(/^[[:space:]]+/, "", v)
        sub(/[[:space:]]+$/, "", v)
        print "field\t" k "\t" v
      }
      next
    }
    in_target { next }
    END { if (!found) exit 1 }
  ' "$config_file"
}

# ---------------------------------------------------------------------------
# _is_rejected_host <host>
#
# Returns 0 (rejected) if the host falls in any of the blocked address ranges:
#   127.0.0.0/8  — IPv4 loopback
#   ::1          — IPv6 loopback
#   169.254.0.0/16 — link-local (includes cloud-metadata 169.254.169.254)
#   10.0.0.0/8   — RFC1918
#   172.16.0.0/12 — RFC1918
#   192.168.0.0/16 — RFC1918
#   100.64.0.0/10 — CGNAT
#   fe80::/10    — IPv6 link-local
#   fc00::/7     — IPv6 unique-local
#   localhost    — hostname
# Returns 1 if not in any rejected range.
_is_rejected_host() {
  local h="$1"
  h="${h%.}"
  h=$(printf '%s' "$h" | tr 'A-Z' 'a-z')
  case "$h" in
    localhost) return 0 ;;
    "::1"|"0:0:0:0:0:0:0:1") return 0 ;;
  esac
  local o1 o2 o3 o4 rest
  IFS="." read -r o1 o2 o3 o4 rest <<IPEOF
$h
IPEOF
  case "$o1.$o2.$o3.$o4" in
    [0-9]*.[0-9]*.[0-9]*.[0-9]*)
      if printf '%s\n%s\n%s\n%s\n' "$o1" "$o2" "$o3" "$o4" | grep -qv '^[0-9][0-9]*$'; then
        : # not a valid numeric quad, fall through
      else
        [ "$o1" -eq 127 ] && return 0
        [ "$o1" -eq 169 ] && [ "$o2" -eq 254 ] && return 0
        [ "$o1" -eq 10 ] && return 0
        [ "$o1" -eq 172 ] && [ "$o2" -ge 16 ] && [ "$o2" -le 31 ] && return 0
        [ "$o1" -eq 192 ] && [ "$o2" -eq 168 ] && return 0
        [ "$o1" -eq 100 ] && [ "$o2" -ge 64 ] && [ "$o2" -le 127 ] && return 0
        return 1
      fi ;;
  esac
  case "$h" in
    fe8*|fe9*|fea*|feb*) return 0 ;;
    fc*|fd*)             return 0 ;;
  esac
  return 1
}

# ---------------------------------------------------------------------------
# _is_loopback_only <host>
#
# Returns 0 only if the host is a loopback address:
#   127.0.0.0/8, ::1, 0:0:0:0:0:0:0:1, or localhost.
# Used by the carve-out gate: QRSPI_ALLOW_LOCALHOST_BASE_URL=1 allows ONLY
# these addresses; all other rejected ranges remain blocked.
_is_loopback_only() {
  local h="$1"
  h="${h%.}"
  h=$(printf '%s' "$h" | tr 'A-Z' 'a-z')
  case "$h" in
    localhost|"::1"|"0:0:0:0:0:0:0:1") return 0 ;;
  esac
  local o1 o2 o3 o4 rest
  IFS="." read -r o1 o2 o3 o4 rest <<IPEOF2
$h
IPEOF2
  case "$o1.$o2.$o3.$o4" in
    [0-9]*.[0-9]*.[0-9]*.[0-9]*)
      if printf '%s\n%s\n%s\n%s\n' "$o1" "$o2" "$o3" "$o4" | grep -qv '^[0-9][0-9]*$'; then
        return 1
      fi
      [ "$o1" -eq 127 ] && return 0
      ;;
  esac
  return 1
}

# ---------------------------------------------------------------------------
# _dispatch_openai_chat
#
# Issues a blocking POST to <base_url>/chat/completions using curl.
# Emits cache_control ONLY when BOTH supports_prompt_cache AND
# emit_cache_control_markers are "true" on the resolved provider entry.
# Writes the response body atomically to OUTPUT_FILE on success.
# Reads: BASE_URL, MODEL, PROVIDER, OUTPUT_FILE, SUPPORTS_PROMPT_CACHE,
#        EMIT_CACHE_CONTROL_MARKERS, _API_KEY, HEADER_NAMES, HEADER_VALUES,
#        TIMEOUT_SECONDS, STDIN_TEMP.
_dispatch_openai_chat() {
  # Dual-flag cache-control gate.
  local emit_cache="false"
  if [ "$SUPPORTS_PROMPT_CACHE" = "true" ] && [ "$EMIT_CACHE_CONTROL_MARKERS" = "true" ]; then
    emit_cache="true"
  fi

  # Read prompt content from STDIN_TEMP.
  local prompt_content
  prompt_content=$(cat "$STDIN_TEMP")

  # Build request JSON via node (correct escaping of arbitrary prompt content).
  local request_json
  request_json=$(node -e "
const emitCache = process.argv[1] === 'true';
const model     = process.argv[2];
const prompt    = process.argv[3];
const msg = { role: 'user', content: prompt };
if (emitCache) {
  msg.cache_control = { type: 'ephemeral' };
}
const body = { model: model, messages: [msg] };
process.stdout.write(JSON.stringify(body));
" -- "$emit_cache" "$MODEL" "$prompt_content") || {
    rm -f "$STDIN_TEMP"
    die "failed to build request JSON"
  }

  local chat_url="${BASE_URL%/}/chat/completions"
  local tmp_response tmp_stderr
  tmp_response=$(mktemp -t run-third-party-llm-resp.XXXXXX) || { rm -f "$STDIN_TEMP"; die "mktemp failed"; }
  tmp_stderr=$(mktemp -t run-third-party-llm-err.XXXXXX) || { rm -f "$STDIN_TEMP" "$tmp_response"; die "mktemp failed"; }

  local timeout_val="120"
  if [ -n "$TIMEOUT_SECONDS" ]; then
    timeout_val="$TIMEOUT_SECONDS"
  fi

  # Build extra-header arguments.  We populate a parallel array and pass each
  # as explicit curl -H flags.  No eval; no here-doc with secrets.
  local CURL_EXTRA_HEADERS=()
  local _j=0
  while [ "$_j" -lt "${#HEADER_NAMES[@]}" ]; do
    CURL_EXTRA_HEADERS+=("${HEADER_NAMES[$_j]}: ${HEADER_VALUES[$_j]}")
    _j=$((_j + 1))
  done

  local curl_rc=0

  if [ "${#CURL_EXTRA_HEADERS[@]}" -gt 0 ]; then
    local _h_args=()
    local _k=0
    while [ "$_k" -lt "${#CURL_EXTRA_HEADERS[@]}" ]; do
      _h_args+=("-H" "${CURL_EXTRA_HEADERS[$_k]}")
      _k=$((_k + 1))
    done
    curl --silent --show-error --fail-with-body \
      --max-time "$timeout_val" \
      -X POST "$chat_url" \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $_API_KEY" \
      "${_h_args[@]}" \
      -d "$request_json" \
      -o "$tmp_response" \
      2>"$tmp_stderr" || curl_rc=$?
  else
    curl --silent --show-error --fail-with-body \
      --max-time "$timeout_val" \
      -X POST "$chat_url" \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $_API_KEY" \
      -d "$request_json" \
      -o "$tmp_response" \
      2>"$tmp_stderr" || curl_rc=$?
  fi

  rm -f "$STDIN_TEMP"

  # Emit stderr from curl — never include the API key value.
  # We filter any line containing the key value before emitting.
  if [ -s "$tmp_stderr" ]; then
    grep -vF "$_API_KEY" "$tmp_stderr" >&2 2>/dev/null || true
  fi
  rm -f "$tmp_stderr"

  # Map curl exit codes to dispatcher exit codes.
  if [ "$curl_rc" -eq 28 ]; then
    rm -f "$tmp_response"
    printf 'run-third-party-llm: upstream timeout (curl exit 28) for provider %s\n' "$PROVIDER" >&2
    exit 10
  fi

  if [ "$curl_rc" -ne 0 ]; then
    rm -f "$tmp_response"
    printf 'run-third-party-llm: upstream hard-error from provider %s (curl exit %d)\n' "$PROVIDER" "$curl_rc" >&2
    exit 13
  fi

  # Validate and extract result from response body.
  local resp_body
  resp_body=$(cat "$tmp_response" 2>/dev/null)
  rm -f "$tmp_response"

  local extracted_content=""
  local node_rc=0
  extracted_content=$(printf '%s' "$resp_body" | node -e "
let chunks = [];
process.stdin.on('data', c => chunks.push(c));
process.stdin.on('end', () => {
  let data;
  try { data = JSON.parse(Buffer.concat(chunks).toString('utf8')); }
  catch (e) {
    process.stderr.write('malformed JSON: ' + e.message + '\n');
    process.exit(14);
  }
  if (!data.choices || !Array.isArray(data.choices) || data.choices.length === 0) {
    process.stderr.write('malformed result: choices array absent or empty\n');
    process.exit(14);
  }
  const msg = data.choices[0].message;
  if (!msg || typeof msg.content !== 'string') {
    process.stderr.write('malformed result: choices[0].message.content missing or not a string\n');
    process.exit(14);
  }
  process.stdout.write(msg.content);
});
" 2>&1) || node_rc=$?

  if [ "$node_rc" -ne 0 ]; then
    # The node script may output both the extracted content and an error message
    # to the same variable (stdout+stderr merged above).  On error we discard
    # the variable content and emit the fixed diagnostic.
    printf 'run-third-party-llm: malformed result body from provider %s\n' "$PROVIDER" >&2
    exit 14
  fi

  # Write atomically to --output-file.
  local tmp_out
  tmp_out=$(mktemp -t run-third-party-llm-out.XXXXXX) || die "mktemp failed for output"
  printf '%s' "$extracted_content" > "$tmp_out"
  mv "$tmp_out" "$OUTPUT_FILE" || {
    rm -f "$tmp_out"
    die "failed to write output file: $OUTPUT_FILE"
  }
  exit 0
}

# ---------------------------------------------------------------------------
# _dispatch_codex_broker
#
# Chains codex-companion-bg.sh launch + await and writes the result to
# OUTPUT_FILE on success.  Exit codes mirror codex-companion-bg.sh.
# Reads: STDIN_TEMP, OUTPUT_FILE, PROVIDER, TIMEOUT_SECONDS, _SCRIPT_DIR.
_dispatch_codex_broker() {
  local companion_script="$_SCRIPT_DIR/codex-companion-bg.sh"

  if [ ! -f "$companion_script" ]; then
    rm -f "$STDIN_TEMP"
    die "codex-broker transport: codex-companion-bg.sh not found at $companion_script"
  fi

  # Launch: pipe the prompt from STDIN_TEMP into codex-companion-bg.sh launch.
  local job_id=""
  local launch_rc=0
  job_id=$(bash "$companion_script" launch < "$STDIN_TEMP") || launch_rc=$?
  rm -f "$STDIN_TEMP"

  if [ "$launch_rc" -eq 15 ]; then
    printf 'run-third-party-llm: phantom-launch from codex-broker (LAUNCH_PHANTOM)\n' >&2
    exit 15
  fi
  if [ "$launch_rc" -ne 0 ]; then
    printf 'run-third-party-llm: codex-broker launch failed (exit %d)\n' "$launch_rc" >&2
    exit 1
  fi
  if [ -z "$job_id" ]; then
    printf 'run-third-party-llm: codex-broker launch returned empty jobId\n' >&2
    exit 1
  fi

  # Await: write result markdown to a temp file, then move atomically.
  local tmp_out
  tmp_out=$(mktemp -t run-third-party-llm-out.XXXXXX) || die "mktemp failed for output"

  local await_rc=0
  if [ -n "$TIMEOUT_SECONDS" ]; then
    QRSPI_CODEX_CEILING_SECONDS="$TIMEOUT_SECONDS" \
      bash "$companion_script" await "$job_id" > "$tmp_out" || await_rc=$?
  else
    bash "$companion_script" await "$job_id" > "$tmp_out" || await_rc=$?
  fi

  case "$await_rc" in
    0)
      mv "$tmp_out" "$OUTPUT_FILE" || {
        rm -f "$tmp_out"
        die "failed to write output file: $OUTPUT_FILE"
      }
      exit 0 ;;
    10)
      rm -f "$tmp_out"
      printf 'run-third-party-llm: codex-broker await timeout (exit 10)\n' >&2
      exit 10 ;;
    11)
      rm -f "$tmp_out"
      printf 'run-third-party-llm: codex-broker job not found (exit 11)\n' >&2
      exit 11 ;;
    14)
      rm -f "$tmp_out"
      printf 'run-third-party-llm: codex-broker malformed result body (exit 14)\n' >&2
      exit 14 ;;
    15)
      rm -f "$tmp_out"
      printf 'run-third-party-llm: codex-broker phantom-launch (exit 15)\n' >&2
      exit 15 ;;
    *)
      rm -f "$tmp_out"
      printf 'run-third-party-llm: codex-broker hard-error (exit %d)\n' "$await_rc" >&2
      exit 13 ;;
  esac
}

# ===========================================================================
# MAIN — argument parsing and dispatch
# ===========================================================================

# ---------------------------------------------------------------------------
# Argument parsing — no positional arguments, no --prompt-file accepted.
ARTIFACT_DIR=""
PROVIDER=""
MODEL=""
OUTPUT_FILE=""
SCOPE_HINT=""
TIMEOUT_SECONDS=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --artifact-dir)
      [ "$#" -ge 2 ] || die "missing value for --artifact-dir"
      ARTIFACT_DIR="$2"; shift 2 ;;
    --provider)
      [ "$#" -ge 2 ] || die "missing value for --provider"
      PROVIDER="$2"; shift 2 ;;
    --model)
      [ "$#" -ge 2 ] || die "missing value for --model"
      MODEL="$2"; shift 2 ;;
    --output-file)
      [ "$#" -ge 2 ] || die "missing value for --output-file"
      OUTPUT_FILE="$2"; shift 2 ;;
    --scope-hint)
      [ "$#" -ge 2 ] || die "missing value for --scope-hint"
      SCOPE_HINT="$2"; shift 2 ;;
    --timeout-seconds)
      [ "$#" -ge 2 ] || die "missing value for --timeout-seconds"
      TIMEOUT_SECONDS="$2"; shift 2 ;;
    --prompt-file)
      printf 'run-third-party-llm: --prompt-file is not accepted; pipe the prompt on stdin\n' >&2
      exit 1 ;;
    --)
      shift
      if [ "$#" -gt 0 ]; then
        printf 'run-third-party-llm: positional arguments are not accepted; pipe the prompt on stdin (got: %s)\n' "$1" >&2
        exit 1
      fi
      break ;;
    -*)
      die "unrecognised flag: $1" ;;
    *)
      printf 'run-third-party-llm: positional arguments are not accepted; pipe the prompt on stdin (got: %s)\n' "$1" >&2
      exit 1 ;;
  esac
done

# ---------------------------------------------------------------------------
# Required-flag validation — named diagnostics per the test expectations.
[ -n "$ARTIFACT_DIR"  ] || die "missing required flag: --artifact-dir"
[ -n "$PROVIDER"      ] || die "missing required flag: --provider"
[ -n "$MODEL"         ] || die "missing required flag: --model"
[ -n "$OUTPUT_FILE"   ] || die "missing required flag: --output-file"

# ---------------------------------------------------------------------------
# --artifact-dir path validation — before reading config.md.
[ -d "$ARTIFACT_DIR" ] || die "path validation: --artifact-dir does not exist or is not a directory: $ARTIFACT_DIR"

# ---------------------------------------------------------------------------
# Locate and parse config.md for the named provider entry.
CONFIG_MD="$ARTIFACT_DIR/config.md"
[ -f "$CONFIG_MD" ] || die "config.md not found in artifact directory: $ARTIFACT_DIR"

PROVIDER_BLOCK_OUTPUT=""
PROVIDER_BLOCK_OUTPUT=$(parse_provider_block "$CONFIG_MD" "$PROVIDER") || \
  die "provider resolution: provider '$PROVIDER' not found in $CONFIG_MD"

# Extract fields from the awk output using parallel arrays.
BASE_URL=""
API_KEY_ENV=""
TRANSPORT_TYPE=""
SUPPORTS_PROMPT_CACHE="false"
EMIT_CACHE_CONTROL_MARKERS="false"
HEADER_NAMES=()
HEADER_VALUES=()

while IFS="	" read -r rec_type rec_key rec_val; do
  case "$rec_type" in
    field)
      case "$rec_key" in
        base_url)                   BASE_URL="$rec_val" ;;
        api_key_env)                API_KEY_ENV="$rec_val" ;;
        transport_type)             TRANSPORT_TYPE="$rec_val" ;;
        supports_prompt_cache)      SUPPORTS_PROMPT_CACHE="$rec_val" ;;
        emit_cache_control_markers) EMIT_CACHE_CONTROL_MARKERS="$rec_val" ;;
      esac ;;
    header)
      HEADER_NAMES+=("$rec_key")
      HEADER_VALUES+=("$rec_val") ;;
  esac
done <<PARSE_EOF
$PROVIDER_BLOCK_OUTPUT
PARSE_EOF

# Validate required provider fields.
[ -n "$BASE_URL"       ] || die "provider '$PROVIDER': missing required field base_url"
[ -n "$API_KEY_ENV"    ] || die "provider '$PROVIDER': missing required field api_key_env"
[ -n "$TRANSPORT_TYPE" ] || die "provider '$PROVIDER': missing required field transport_type"

# ---------------------------------------------------------------------------
# Security pre-flight: validate base_url and default_headers before any
# network call.  Applies to openai-chat-completions only.
if [ "$TRANSPORT_TYPE" = "openai-chat-completions" ]; then

  # 1. URL scheme must be https.
  case "$BASE_URL" in
    https://*) : ;;
    *) die "url-scheme validation: base_url for provider '$PROVIDER' must use https (got: $BASE_URL)" ;;
  esac

  # 2. Extract host from URL for host-shape validation.
  local_url_after="${BASE_URL#*://}"
  local_url_host_port="${local_url_after%%/*}"
  local_url_host_port="${local_url_host_port%%\?*}"
  local_url_host_port="${local_url_host_port%%\#*}"
  case "$local_url_host_port" in
    \[*\]:*) url_host="${local_url_host_port%%]:*}"; url_host="${url_host#[}" ;;
    \[*\])   url_host="${local_url_host_port#[}";    url_host="${url_host%]}" ;;
    *)       url_host="${local_url_host_port%%:*}" ;;
  esac

  # 3. Host-shape validation: reject blocked ranges.
  if _is_rejected_host "$url_host"; then
    if [ "${QRSPI_ALLOW_LOCALHOST_BASE_URL:-0}" = "1" ] && _is_loopback_only "$url_host"; then
      : # carve-out active for loopback-only hosts
    else
      die "host-shape validation: base_url for provider '$PROVIDER' resolves to a rejected address (localhost/link-local/private/CGNAT; host: $url_host). Set QRSPI_ALLOW_LOCALHOST_BASE_URL=1 to allow loopback-only hosts in tests."
    fi
  fi

  # 4. default_headers: no control characters in name or value.
  _hi=0
  while [ "$_hi" -lt "${#HEADER_NAMES[@]}" ]; do
    _hname="${HEADER_NAMES[$_hi]}"
    _hval="${HEADER_VALUES[$_hi]}"
    # Use printf | grep -P for control-character detection.
    if printf '%s' "$_hname" | grep -qP '[\x00-\x1f\x7f]' 2>/dev/null || \
       printf '%s' "$_hval"  | grep -qP '[\x00-\x1f\x7f]' 2>/dev/null; then
      die "header-validation: default_headers for provider '$PROVIDER' contains a control character in header '$_hname'"
    fi
    _hi=$((_hi + 1))
  done

fi

# ---------------------------------------------------------------------------
# API key resolution — before any network call.
# Applies to openai-chat-completions only; codex-broker manages its own auth.
_API_KEY=""
if [ "$TRANSPORT_TYPE" = "openai-chat-completions" ]; then
  if ! env | grep -q "^${API_KEY_ENV}="; then
    die "key-resolution: environment variable '$API_KEY_ENV' (api_key_env for provider '$PROVIDER') is not set"
  fi
  eval '_API_KEY="${'"$API_KEY_ENV"':-}"'
  if [ -z "$_API_KEY" ]; then
    die "key-resolution: environment variable '$API_KEY_ENV' (api_key_env for provider '$PROVIDER') is set but empty — fail-closed to prevent silent empty-Authorization-header"
  fi
fi

# ---------------------------------------------------------------------------
# Stdin validation.
if [ -t 0 ]; then
  die "stdin must not be a TTY (pipe the prompt on stdin)"
fi

STDIN_TEMP=""
STDIN_TEMP=$(mktemp -t run-third-party-llm.XXXXXX) || die "mktemp failed for stdin capture"
cat > "$STDIN_TEMP"
if [ ! -s "$STDIN_TEMP" ]; then
  rm -f "$STDIN_TEMP"
  die "stdin was empty (no prompt received)"
fi

# ---------------------------------------------------------------------------
# Prompt-injection guard via sourced library.
# Non-zero return: abort dispatch with named diagnostic; no network call.
if ! guard_marker_injection "stdin-prompt" "$STDIN_TEMP"; then
  rm -f "$STDIN_TEMP"
  printf 'run-third-party-llm: prompt-injection abort: stdin prompt contains the wrapper-private boundary marker; dispatch cancelled\n' >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Dispatch by transport type.
case "$TRANSPORT_TYPE" in
  openai-chat-completions)
    _dispatch_openai_chat ;;
  codex-broker)
    _dispatch_codex_broker ;;
  *)
    rm -f "$STDIN_TEMP"
    die "unknown transport_type '$TRANSPORT_TYPE' for provider '$PROVIDER' (expected: openai-chat-completions or codex-broker)" ;;
esac
