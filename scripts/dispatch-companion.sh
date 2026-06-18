#!/usr/bin/env bash
# dispatch-companion.sh — universal stdin-prompt dispatcher for QRSPI.
#
# Renamed from dispatch-companion.sh (CD-1 vendor-neutral dispatch rename).
# Reads the prompt from stdin ONLY; any positional argument or --prompt-file
# exits 1 with a validation diagnostic.  Resolves the named provider from
# <artifact-dir>/config.md, branches on transport_type:, blocks until the
# result is written to --output-file, and emits numbered exit codes.
#
# Usage:
#   dispatch-companion.sh \
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
set -o pipefail

# Resolve the directory containing this script so we can source lib/ reliably.
_SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Source shared prompt-utils library.
# shellcheck source=scripts/lib/llm-prompt-utils.sh
. "$_SCRIPT_DIR/lib/llm-prompt-utils.sh"

# Repo-boundary guard for raw file-path surfaces.
#
# The legacy `--provider/--artifact-dir` form below is stdin-only: the prompt
# body never enters this script as a file path argument (positional args and
# `--prompt-file` are explicitly rejected with non-zero exit). It receives
# only assembled prompt data on stdin, so no `assert_path_under_repo_root`
# call is needed there.
#
# The vendor-neutral `launch` subcommand DOES accept a raw `--prompt-file`
# path that is later piped to the upstream transport — that path is a
# sanctioned-channel exfil surface, so it shares the same canonical-
# $REPO_ROOT/ guard that `dispatch-agent.sh` enforces on every prompt-
# ingested path. The shared library is sourced unconditionally so the guard
# is available for both the launch-mode and any future raw-path entry point.
#
# REPO_ROOT defaults to this script's parent directory (one level above
# scripts/), with a `QRSPI_REPO_ROOT` env override for tests.
# Two-root topology — see scripts/dispatch-agent.sh and
# skills/using-qrspi/SKILL.md § Topology Contract. PLUGIN_ROOT carries
# script-asset paths; ARTIFACT_ROOT carries user-supplied paths
# (round-dir, prompt-file). Both default to the same place for vendored-
# submodule installs; they diverge under plugin-install topology.
REPO_ROOT="${QRSPI_REPO_ROOT:-$(cd "$_SCRIPT_DIR/.." && pwd -P)}"
PLUGIN_ROOT="$REPO_ROOT"
export REPO_ROOT PLUGIN_ROOT
# shellcheck source=scripts/lib/path-guard.sh
. "$_SCRIPT_DIR/lib/path-guard.sh"
command -v assert_path_under_repo_root >/dev/null 2>&1 \
  || { echo "error: assert_path_under_repo_root not defined after sourcing path-guard.sh; aborting (fail-closed)" >&2; exit 1; }
command -v assert_ancestor_under_repo_root >/dev/null 2>&1 \
  || { echo "error: assert_ancestor_under_repo_root not defined after sourcing path-guard.sh; aborting (fail-closed)" >&2; exit 1; }
command -v assert_path_under_artifact_root >/dev/null 2>&1 \
  || { echo "error: assert_path_under_artifact_root not defined after sourcing path-guard.sh; aborting (fail-closed)" >&2; exit 1; }
command -v assert_ancestor_under_artifact_root >/dev/null 2>&1 \
  || { echo "error: assert_ancestor_under_artifact_root not defined after sourcing path-guard.sh; aborting (fail-closed)" >&2; exit 1; }

# Derive ARTIFACT_ROOT lazily inside the launch/await subcommands once the
# user-supplied path (round-dir, prompt-file) is known. Precedence mirrors
# dispatch-agent.sh: $QRSPI_ARTIFACT_ROOT env > git toplevel from supplied
# path > fall back to $PLUGIN_ROOT (preserves vendored-submodule behavior).
_derive_artifact_root_companion() {
  local probe_dir="$1"
  if [[ -n "${QRSPI_ARTIFACT_ROOT:-}" ]]; then
    printf '%s\n' "$QRSPI_ARTIFACT_ROOT"
    return
  fi
  if [[ -n "$probe_dir" ]]; then
    local probe="$probe_dir"
    while [[ ! -e "$probe" ]]; do
      local _parent
      _parent="$(dirname "$probe")"
      if [[ "$_parent" == "$probe" || "$_parent" == "/" || "$_parent" == "." ]]; then
        probe=""; break
      fi
      probe="$_parent"
    done
    if [[ -n "$probe" ]]; then
      local toplevel
      toplevel="$(git -C "$probe" rev-parse --show-toplevel 2>/dev/null || true)"
      if [[ -n "$toplevel" ]]; then
        printf '%s\n' "$toplevel"
        return
      fi
    fi
  fi
  printf '%s\n' "$PLUGIN_ROOT"
}

# ---------------------------------------------------------------------------
# die <message>  — write message to stderr and exit 1
die() {
  printf 'dispatch-companion: %s\n' "$1" >&2
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
# _control_char_check <header-name> <header-value>
#
# Rejects any header name or value that contains a control byte.
# Covered byte ranges: C0 (0x00-0x1F) and DEL (0x7F).
# Non-ASCII bytes (0x80-0xFF) are outside spec scope and are not flagged.
#
# Detection method: LC_ALL=C tr deletes printable-ASCII bytes (0x20-0x7E,
# octal \040-\176) and non-ASCII bytes (0x80-0xFF, octal \200-\377).
# Anything remaining after deletion is a C0 or DEL control byte.
# The byte count is taken by wc -c on the same pipeline so
# command-substitution trailing-newline stripping does not affect the
# count -- LF inside an argument is correctly detected this way.
#
# No grep -P is used; the implementation is POSIX-clean and works on
# macOS system grep (BSD grep, no PCRE) and GNU grep alike.
#
# Reads the global PROVIDER variable for the die-path diagnostic.
# Caller must have die() in scope.
_control_char_check() {
  local _cc_hname="$1" _cc_hval="$2"
  local _cc_count
  # Delete printable-ASCII bytes (space through tilde, octal \040-\176) and
  # non-ASCII bytes (0x80-0xFF, octal \200-\377) so only C0 control bytes
  # (0x00-0x1F) and DEL (0x7F) survive.  LF inside the argument also
  # survives; wc -c counts it before command substitution strips newlines.
  _cc_count=$(printf '%s' "$_cc_hname$_cc_hval" \
    | LC_ALL=C tr -d '\040-\176\200-\377' \
    | wc -c \
    | tr -d ' \t')
  # Sanitise the header name before embedding in any die message to prevent
  # raw control bytes (e.g. ESC sequences) from manipulating the operator's
  # terminal and hiding the security abort notification.
  local _cc_safe_hname
  _cc_safe_hname=$(printf '%s' "$_cc_hname" | LC_ALL=C tr '\000-\037\177' '?') \
    || _cc_safe_hname="(field name unavailable — sanitisation pipeline failed)"
  # Fail closed: if the pipeline returns empty or non-numeric output (e.g.
  # due to SIGPIPE or tool failure), die immediately rather than silently
  # bypassing control-char detection (fail-open via [ "" -eq 0 ]).
  case "$_cc_count" in
    ''|*[!0-9]*) die "header-validation: failed to compute byte count for header '$_cc_safe_hname' on provider '${PROVIDER:-}' (pipeline/tool failure)" ;;
  esac
  if [ "$_cc_count" -ne 0 ]; then
    die "header-validation: provider '${PROVIDER:-}' — control character in header/key field '$_cc_safe_hname'"
  fi
}

# ---------------------------------------------------------------------------
# _dispatch_openai_chat
#
# Issues a blocking POST to <base_url>/chat/completions using curl.
# Writes the response body atomically to OUTPUT_FILE on success.
# Reads: BASE_URL, MODEL, PROVIDER, OUTPUT_FILE, _API_KEY, HEADER_NAMES,
#        HEADER_VALUES, TIMEOUT_SECONDS, STDIN_TEMP.
_dispatch_openai_chat() {
  # Read prompt content from STDIN_TEMP.
  local prompt_content
  prompt_content=$(cat "$STDIN_TEMP")

  # Build request JSON via node (correct escaping of arbitrary prompt content).
  local request_json
  request_json=$(node -e "
const model     = process.argv[1];
const prompt    = process.argv[2];
const msg = { role: 'user', content: prompt };
const body = { model: model, messages: [msg] };
process.stdout.write(JSON.stringify(body));
" -- "$MODEL" "$prompt_content") || {
    rm -f "$STDIN_TEMP"
    die "failed to build request JSON"
  }

  local chat_url="${BASE_URL%/}/chat/completions"
  local tmp_response tmp_stderr
  tmp_response=$(mktemp -t dispatch-companion-resp.XXXXXX) || { rm -f "$STDIN_TEMP"; die "mktemp failed"; }
  tmp_stderr=$(mktemp -t dispatch-companion-err.XXXXXX) || { rm -f "$STDIN_TEMP" "$tmp_response"; die "mktemp failed"; }

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
    printf 'dispatch-companion: upstream timeout (curl exit 28) for provider %s\n' "$PROVIDER" >&2
    exit 10
  fi

  if [ "$curl_rc" -ne 0 ]; then
    rm -f "$tmp_response"
    printf 'dispatch-companion: upstream hard-error from provider %s (curl exit %d)\n' "$PROVIDER" "$curl_rc" >&2
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
    printf 'dispatch-companion: malformed result body from provider %s\n' "$PROVIDER" >&2
    exit 14
  fi

  # Write atomically to --output-file.
  local tmp_out
  tmp_out=$(mktemp -t dispatch-companion-out.XXXXXX) || die "mktemp failed for output"
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
    printf 'dispatch-companion: phantom-launch from codex-broker (LAUNCH_PHANTOM)\n' >&2
    exit 15
  fi
  if [ "$launch_rc" -ne 0 ]; then
    printf 'dispatch-companion: codex-broker launch failed (exit %d)\n' "$launch_rc" >&2
    exit 1
  fi
  if [ -z "$job_id" ]; then
    printf 'dispatch-companion: codex-broker launch returned empty jobId\n' >&2
    exit 1
  fi

  # Await: write result markdown to a temp file, then move atomically.
  local tmp_out
  tmp_out=$(mktemp -t dispatch-companion-out.XXXXXX) || die "mktemp failed for output"

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
      printf 'dispatch-companion: codex-broker await timeout (exit 10)\n' >&2
      exit 10 ;;
    11)
      rm -f "$tmp_out"
      printf 'dispatch-companion: codex-broker job not found (exit 11)\n' >&2
      exit 11 ;;
    14)
      rm -f "$tmp_out"
      printf 'dispatch-companion: codex-broker malformed result body (exit 14)\n' >&2
      exit 14 ;;
    15)
      rm -f "$tmp_out"
      printf 'dispatch-companion: codex-broker phantom-launch (exit 15)\n' >&2
      exit 15 ;;
    *)
      rm -f "$tmp_out"
      printf 'dispatch-companion: codex-broker hard-error (exit %d)\n' "$await_rc" >&2
      exit 13 ;;
  esac
}

# ===========================================================================
# MAIN — argument parsing and dispatch
# ===========================================================================

# ---------------------------------------------------------------------------
# Vendor-neutral launch/await interface (CD-1 #5 dispatch-companion contract).
#
# Two subcommand shapes are recognised in addition to the legacy stdin
# dispatcher form below:
#
#   dispatch-companion.sh --vendor <v> --model <m> --prompt-file <f> \
#       --round-dir <d> --tag <t>
#       Launches a background third-party dispatch. Writes ONLY `JOB_ID=<id>`
#       to stdout; the prompt body is never echoed (output-bound contract).
#
#   dispatch-companion.sh await <job-id>
#       Resolves a previously-launched job and captures its raw reviewer output
#       to <round-dir>/.dispatch/<tag>.raw, payload-silently (no stdout/stderr
#       payload echo). Drained by await-round.sh.
#
# These two shapes are detected BEFORE the legacy `--provider/--artifact-dir`
# stdin dispatcher so the universal dispatch chain (dispatch-agent ->
# dispatch-companion -> await-round -> third-party-finding-splitter) routes
# through a single vendor-neutral entry point.
# ---------------------------------------------------------------------------

if [ "$#" -gt 0 ] && [ "$1" = "await" ]; then
  shift
  _await_job="${1:-}"
  if [ -z "$_await_job" ]; then
    die "await: missing <job-id> argument"
  fi
  # Validate the job-id grammar (defense against path traversal in the record
  # lookup below); a crafted job-id must not escape the dispatch directory.
  case "$_await_job" in
    */*|*..*|"")
      die "await: invalid job-id: $_await_job" ;;
  esac
  # Job records are written by `launch` under the round-scoped
  # <round-dir>/.dispatch/.jobs/<job-id>. await-round.sh runs this command with
  # cwd=<round-dir>/.dispatch/, so resolve the record relative to cwd.
  _job_record="./.jobs/${_await_job}"
  if [ ! -f "$_job_record" ]; then
    printf 'dispatch-companion: await: job not found: %s\n' "$_await_job" >&2
    exit 11
  fi
  # A found record carries vendor/model/prompt-file/tag/round-dir lines. The
  # concrete vendor-transport capture wires through codex-companion-bg.sh for
  # the codex vendor; other vendors fail loudly rather than silently producing
  # an empty raw file. The vendor-output is captured payload-silently to
  # <round-dir>/.dispatch/<tag>.raw so await-round.sh can hand it to the
  # third-party-finding-splitter without any payload appearing on stdout/stderr.
  _job_vendor="$(sed -n 's/^vendor=//p' "$_job_record" | head -1)"
  _job_tag="$(sed -n 's/^tag=//p' "$_job_record" | head -1)"
  _job_round_dir="$(sed -n 's/^round_dir=//p' "$_job_record" | head -1)"
  _job_codex_id="$(sed -n 's/^codex_job_id=//p' "$_job_record" | head -1)"

  if [ -z "$_job_tag" ] || [ -z "$_job_round_dir" ]; then
    printf 'dispatch-companion: await: malformed job record for %s (missing tag or round_dir)\n' \
      "$_await_job" >&2
    exit 13
  fi

  # Re-validate tag from job record: mirrors the [a-z][a-z0-9_-]* allowlist
  # enforced at launch time. A crafted job record with a traversal tag
  # like '../../other-task/evil' would otherwise redirect the raw-capture file
  # outside the intended task tree.
  case "$_job_tag" in
    *[!a-z0-9_-]*|[^a-z]*)
      printf 'dispatch-companion: await: invalid tag in job record %s\n' "$_await_job" >&2
      exit 1 ;;
  esac
  # Re-validate round_dir from job record: a crafted job record with
  # round_dir=/tmp/... or any out-of-repo path would write raw LLM output
  # outside the repo tree. Reject before constructing _raw_dir.
  ARTIFACT_ROOT="$(_derive_artifact_root_companion "$_job_round_dir")"
  export ARTIFACT_ROOT
  assert_path_under_artifact_root "await:round_dir" "$_job_round_dir"

  _raw_dir="$_job_round_dir/.dispatch"
  mkdir -p "$_raw_dir" || {
    printf 'dispatch-companion: await: cannot create raw-capture dir: %s\n' "$_raw_dir" >&2
    exit 13
  }
  _raw_file="$_raw_dir/${_job_tag}.raw"

  case "$_job_vendor" in
    codex)
      if [ -z "$_job_codex_id" ]; then
        printf 'dispatch-companion: await: codex job record %s missing codex_job_id (launch did not capture broker id)\n' \
          "$_await_job" >&2
        exit 13
      fi
      # Delegate to the existing codex transport.  Stdout is the reviewer
      # markdown — redirect it to the raw-capture file payload-silently.
      # Stderr from codex-companion-bg.sh is diagnostic (not payload) and is
      # forwarded to our own stderr; await-round.sh runs us with stderr=DEVNULL,
      # so it never reaches the orchestrator context either way.
      "$_SCRIPT_DIR/codex-companion-bg.sh" await "$_job_codex_id" >"$_raw_file"
      _await_rc=$?
      if [ "$_await_rc" -ne 0 ]; then
        printf 'dispatch-companion: await: codex transport returned rc=%d for job %s (codex_job_id=%s)\n' \
          "$_await_rc" "$_await_job" "$_job_codex_id" >&2
        # Leave any partial output in the raw file for diagnostic inspection
        # but propagate the failure so await-round.sh marks the entry failed.
        exit "$_await_rc"
      fi
      exit 0
      ;;
    *)
      printf 'dispatch-companion: await: vendor %s transport capture for job %s is not wired in this build\n' \
        "${_job_vendor:-unknown}" "$_await_job" >&2
      exit 13
      ;;
  esac
fi

_has_vendor_flag=false
for _a in "$@"; do
  case "$_a" in --vendor) _has_vendor_flag=true; break ;; esac
done

if [ "$_has_vendor_flag" = "true" ]; then
  L_VENDOR=""
  L_MODEL=""
  L_PROMPT_FILE=""
  L_ROUND_DIR=""
  L_TAG=""
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --vendor)      [ "$#" -ge 2 ] || die "launch: missing value for --vendor";      L_VENDOR="$2"; shift 2 ;;
      --model)       [ "$#" -ge 2 ] || die "launch: missing value for --model";       L_MODEL="$2"; shift 2 ;;
      --prompt-file) [ "$#" -ge 2 ] || die "launch: missing value for --prompt-file"; L_PROMPT_FILE="$2"; shift 2 ;;
      --round-dir)   [ "$#" -ge 2 ] || die "launch: missing value for --round-dir";   L_ROUND_DIR="$2"; shift 2 ;;
      --tag)         [ "$#" -ge 2 ] || die "launch: missing value for --tag";         L_TAG="$2"; shift 2 ;;
      *) die "launch: unrecognised flag: $1" ;;
    esac
  done
  [ -n "$L_VENDOR" ]      || die "launch: missing required flag: --vendor"
  [ -n "$L_MODEL" ]       || die "launch: missing required flag: --model"
  [ -n "$L_PROMPT_FILE" ] || die "launch: missing required flag: --prompt-file"
  [ -n "$L_ROUND_DIR" ]   || die "launch: missing required flag: --round-dir"
  [ -n "$L_TAG" ]         || die "launch: missing required flag: --tag"
  # Job-record line-injection guard: every value below is later written into
  # the per-job record as `key=<value>\n` and parsed line-by-line at await
  # time. A value carrying an embedded newline or carriage-return could
  # synthesize additional record lines (e.g., a forged codex_job_id= or
  # tag=) and divert await to an attacker-chosen broker job or output path.
  # Reject any control characters in raw arg values up front.
  for _pair in "vendor:$L_VENDOR" "model:$L_MODEL" "prompt-file:$L_PROMPT_FILE" "round-dir:$L_ROUND_DIR" "tag:$L_TAG"; do
    case "${_pair#*:}" in
      *$'\n'*|*$'\r'*)
        die "launch: --${_pair%%:*} value contains an embedded newline/carriage-return; reject" ;;
    esac
  done
  unset _pair
  # Tag allowlist: _job_id is constructed from L_TAG and used as a filename.
  # Restricting to safe token grammar prevents path traversal via crafted tags.
  if [[ ! "$L_TAG" =~ ^[a-z][a-z0-9_-]*$ ]]; then
    die "launch: --tag must match [a-z][a-z0-9_-]* (got: $L_TAG)"
  fi
  [ -f "$L_PROMPT_FILE" ] || die "launch: --prompt-file not found: $L_PROMPT_FILE"
  # Derive ARTIFACT_ROOT from --round-dir for the launch-mode boundary
  # checks below. Falls back to PLUGIN_ROOT for vendored-submodule installs.
  ARTIFACT_ROOT="$(_derive_artifact_root_companion "$L_ROUND_DIR")"
  export ARTIFACT_ROOT
  # Boundary guard: the prompt-file path is a raw user-supplied file
  # surface that is later piped to the upstream transport. Reject any path
  # whose canonical target falls outside the artifact tree.
  assert_path_under_artifact_root "launch:--prompt-file" "$L_PROMPT_FILE"
  # Boundary guard for --round-dir, in two stages to avoid creating
  # filesystem state outside the repo on rejected inputs:
  #   (1) Pre-mkdir: walk --round-dir upward to its deepest existing
  #       ancestor and assert that ancestor is under the artifact tree.
  #       This prevents `mkdir -p` from materializing directories outside
  #       the repo when the leaf path would later be rejected.
  #   (2) Post-mkdir: run the full canonical (realpath-resolved) boundary
  #       check on the now-existing leaf to catch symlink-resolution
  #       attacks where a freshly created path's canonical target points
  #       outside the repo.
  assert_ancestor_under_artifact_root "launch:--round-dir" "$L_ROUND_DIR"
  _jobs_dir="$L_ROUND_DIR/.dispatch/.jobs"
  mkdir -p "$_jobs_dir" || die "launch: cannot create jobs dir: $_jobs_dir"
  assert_path_under_artifact_root "launch:--round-dir" "$L_ROUND_DIR"
  # Canonicalize once after the boundary check so the stored round_dir value
  # is always an absolute path regardless of how the caller supplied
  # --round-dir. Using the same _qrspi_canonicalize helper that
  # the boundary check uses internally ensures the stored form matches
  # what await re-validates even when the cwd differs at await time.
  _canon_round_dir="$(_qrspi_canonicalize "$L_ROUND_DIR")" \
    || die "launch: cannot canonicalize --round-dir after boundary check: $L_ROUND_DIR"
  # The newline/CR check above validated the raw --round-dir arg, but the
  # value persisted to the job record below is the canonical (realpath)
  # form. realpath will faithfully return any byte present in an on-disk
  # directory name (POSIX permits any byte except '/' and NUL). A symlink
  # under the repo whose target directory has a literal '\n' in its name
  # would let the canonical form synthesize forged record lines even
  # though the raw input was clean. Re-check post-canonicalization.
  case "$_canon_round_dir" in
    *$'\n'*|*$'\r'*)
      die "launch: canonical --round-dir contains an embedded newline/carriage-return; reject (job-record injection via on-disk directory name)" ;;
  esac
  _jobs_dir="$_canon_round_dir/.dispatch/.jobs"

  # Generate a round-unique job id and persist a job record so a later
  # `await <job-id>` can resolve the vendor/model/prompt-file/tag. The prompt
  # body is NEVER read into a variable here — only its path is recorded — so it
  # cannot leak onto stdout (output-bound contract).
  _job_id="${L_TAG}-$$-$(date +%s)"

  # Vendor-specific launch: for codex, invoke the existing background
  # transport (codex-companion-bg.sh launch) by piping the prompt file on
  # stdin, capture the broker job-id (printed alone on stdout), and persist
  # it in the job record so `await` can recover it. Other vendors retain the
  # synthetic-id flow (no real backend launch) — they will fail loudly at
  # await time with a clear diagnostic until their transport is wired.
  _codex_job_id=""
  if [ "$L_VENDOR" = "codex" ]; then
    # codex-companion-bg.sh prints exactly the broker job id on stdout on
    # success; its stderr carries diagnostics only. We deliberately do NOT
    # echo its stdout to our own stdout (output-bound: only `JOB_ID=<id>`
    # may reach our caller's stdout).
    _codex_job_id="$("$_SCRIPT_DIR/codex-companion-bg.sh" launch <"$L_PROMPT_FILE")" \
      || die "launch: codex transport failed for tag $L_TAG (rc=$?)"
    if [ -z "$_codex_job_id" ]; then
      die "launch: codex transport returned empty job id for tag $L_TAG"
    fi
    # Use the broker id as the dispatch-companion job id so the await record
    # path is unambiguous. Re-validate against the await-side grammar to
    # defend against unexpected broker-id shapes reaching our path lookup.
    case "$_codex_job_id" in
      */*|*..*|"")
        die "launch: codex transport returned invalid job id: $_codex_job_id" ;;
      *$'\n'*|*$'\r'*)
        die "launch: codex transport returned job id with embedded newline/carriage-return; reject (job-record injection via subprocess stdout)" ;;
    esac
    _job_id="$_codex_job_id"
  fi

  {
    printf 'vendor=%s\n' "$L_VENDOR"
    printf 'model=%s\n' "$L_MODEL"
    printf 'prompt_file=%s\n' "$L_PROMPT_FILE"
    printf 'round_dir=%s\n' "$_canon_round_dir"
    printf 'tag=%s\n' "$L_TAG"
    if [ -n "$_codex_job_id" ]; then
      printf 'codex_job_id=%s\n' "$_codex_job_id"
    fi
  } > "$_jobs_dir/$_job_id" || die "launch: cannot write job record"

  # Emit ONLY the job id to stdout.
  printf 'JOB_ID=%s\n' "$_job_id"
  exit 0
fi

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
      printf 'dispatch-companion: --prompt-file is not accepted; pipe the prompt on stdin\n' >&2
      exit 1 ;;
    --)
      shift
      if [ "$#" -gt 0 ]; then
        printf 'dispatch-companion: positional arguments are not accepted; pipe the prompt on stdin (got: %s)\n' "$1" >&2
        exit 1
      fi
      break ;;
    -*)
      die "unrecognised flag: $1" ;;
    *)
      printf 'dispatch-companion: positional arguments are not accepted; pipe the prompt on stdin (got: %s)\n' "$1" >&2
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
HEADER_NAMES=()
HEADER_VALUES=()

while IFS="	" read -r rec_type rec_key rec_val; do
  case "$rec_type" in
    field)
      case "$rec_key" in
        base_url)                   BASE_URL="$rec_val" ;;
        api_key_env)                API_KEY_ENV="$rec_val" ;;
        transport_type)             TRANSPORT_TYPE="$rec_val" ;;
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

  # 4. Raw-byte pre-flight: NUL bytes (0x00) are stripped by bash on variable
  #    assignment and never reach HEADER_NAMES/HEADER_VALUES through the awk
  #    parser. Compare the raw byte count of config.md to the count after NUL
  #    removal; any difference means NUL bytes are present in the file.
  _raw_file_bytes=$(wc -c < "$CONFIG_MD" | tr -d ' \t')
  _raw_no_nul_bytes=$(LC_ALL=C tr -d '\000' < "$CONFIG_MD" | wc -c | tr -d ' \t')
  # Fail closed: if either count is non-numeric (pipeline/tool failure), die
  # immediately rather than silently bypassing NUL detection (fail-open).
  case "$_raw_file_bytes" in
    ''|*[!0-9]*) die "header-validation: failed to compute byte counts for NUL pre-flight on config.md for provider '$PROVIDER'" ;;
  esac
  case "$_raw_no_nul_bytes" in
    ''|*[!0-9]*) die "header-validation: failed to compute byte counts for NUL pre-flight on config.md for provider '$PROVIDER'" ;;
  esac
  if [ "$_raw_file_bytes" -ne "$_raw_no_nul_bytes" ]; then
    die "header-validation: config.md for provider '$PROVIDER' contains NUL bytes (raw byte scan of entire file); NUL in header values is rejected because bash strips NUL at variable assignment"
  fi

  # 5. default_headers: no control characters in name or value.
  #    _control_char_check is POSIX-clean (no grep -P) and detects all 33
  #    control bytes (C0 0x00-0x1F and DEL 0x7F), including LF which was
  #    silently missed by the prior grep -qP 2>/dev/null implementation.
  _hi=0
  while [ "$_hi" -lt "${#HEADER_NAMES[@]}" ]; do
    _hname="${HEADER_NAMES[$_hi]}"
    _hval="${HEADER_VALUES[$_hi]}"
    _control_char_check "$_hname" "$_hval"
    _hi=$((_hi + 1))
  done

fi

# ---------------------------------------------------------------------------
# API key resolution — before any network call.
# Applies to openai-chat-completions only; codex-broker manages its own auth.
_API_KEY=""
if [ "$TRANSPORT_TYPE" = "openai-chat-completions" ]; then
  # Defence-in-depth: validate api_key_env is a well-formed shell identifier
  # before using it in indirect expansion.  The env-var presence check below
  # would catch most malformed values but this guard makes the invariant
  # explicit and avoids any reliance on eval behaviour.
  case "$API_KEY_ENV" in
    ''|*[!A-Za-z0-9_]*) die "key-resolution: api_key_env must be a valid shell identifier (for provider '$PROVIDER')" ;;
  esac
  if ! env | grep -q "^${API_KEY_ENV}="; then
    die "key-resolution: environment variable '$API_KEY_ENV' (api_key_env for provider '$PROVIDER') is not set"
  fi
  # Use bash indirect expansion instead of eval to avoid any eval-injection
  # risk.  API_KEY_ENV is validated as a pure identifier above.
  _API_KEY="${!API_KEY_ENV:-}"
  if [ -z "$_API_KEY" ]; then
    die "key-resolution: environment variable '$API_KEY_ENV' (api_key_env for provider '$PROVIDER') is set but empty — fail-closed to prevent silent empty-Authorization-header"
  fi
  # Screen the API key for control characters: it is placed verbatim into the
  # Authorization header, so the same injection risk applies as for any other
  # header value.  Use the "api_key_env/<var>" label so the die message
  # identifies the source without leaking the key value itself.
  _control_char_check "api_key_env/${API_KEY_ENV}" "$_API_KEY"
fi

# ---------------------------------------------------------------------------
# Stdin validation.
if [ -t 0 ]; then
  die "stdin must not be a TTY (pipe the prompt on stdin)"
fi

STDIN_TEMP=""
STDIN_TEMP=$(mktemp -t dispatch-companion.XXXXXX) || die "mktemp failed for stdin capture"
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
  printf 'dispatch-companion: prompt-injection abort: stdin prompt contains the wrapper-private boundary marker; dispatch cancelled\n' >&2
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
