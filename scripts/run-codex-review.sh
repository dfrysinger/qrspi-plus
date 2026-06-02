#!/usr/bin/env bash
# run-codex-review.sh — thin forwarder around scripts/run-third-party-llm.sh.
#
# Per T04 of the v0.7 release: this script no longer drives the Codex broker
# directly. It preserves its existing caller-facing flag surface (assembling
# the reviewer prompt from the reviewer-protocol body, the named agent body
# with frontmatter stripped, the codex-emission override, and a Dispatch
# parameters block), and then forwards the assembled prompt over stdin to
# `scripts/run-third-party-llm.sh` with `--provider codex --model <id>
# --output-file <path> --artifact-dir <dir>`. Transport selection
# (codex-broker) is config-driven via the `codex` entry in
# `<artifact-dir>/config.md`'s `providers:` block — this shim does NOT pass
# a transport flag. The dispatcher's exit code is propagated unchanged.
#
# Usage (existing flag surface preserved, three new required flags added
# for the dispatcher hand-off):
#   scripts/run-codex-review.sh \
#     --agent-file agents/qrspi-spec-reviewer.md \
#     --reviewer-tag spec-codex \
#     --output-dir <ABS>/reviews/tasks/task-NN/round-N/ \
#     --round N \
#     --model <codex-model-id> \                           # NEW: forwarded as --model
#     --output-file <ABS>/.../result.md \                  # NEW: forwarded as --output-file
#     --artifact-dir <ABS>/docs/qrspi/<run-id>/ \          # NEW: forwarded as --artifact-dir
#     (--subject-code <path> | --artifact-body <path>) \
#     [--subject-code <path> ...]
#     [--task-def tasks/task-NN.md]
#     [--companion NAME=PATH ...]
#     [--field NAME=VALUE ...]
#     [--diff-file <ABS>/reviews/tasks/task-NN/round-N.diff] \
#     [--scope-hint 'path/a.ts, path/b.ts'] \
#     [--timeout-seconds <int>] \
#     [--dry-run]
#
# Stdin is NOT consumed from the caller — the shim assembles the prompt
# itself from the named artifacts (per the existing caller contract) and
# pipes the assembled prompt to the dispatcher's stdin. The dispatcher's
# prompt-source contract (stdin-only) is preserved end-to-end.
#
# Exit codes (propagated unchanged from the dispatcher; no remapping):
#   0   success — --output-file populated
#   1   validation / argument failure (this shim or the dispatcher)
#   10  upstream timeout (forwarded from dispatcher)
#   11  job not found (forwarded from dispatcher)
#   13  upstream hard-error (forwarded from dispatcher)
#   14  malformed result body (forwarded from dispatcher)
#   15  phantom-launch (forwarded from dispatcher)

set -u
# NOT -e: we want to surface validation errors with our own diagnostics.
# pipefail is off because the dispatcher handles its own error contract.

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------

# Derive REPO_ROOT from the wrapper's own location (scripts/ is one level
# below repo root). Override via QRSPI_REPO_ROOT for tests.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT_DEFAULT="$(cd "$SCRIPT_DIR/.." && pwd -P)"
REPO_ROOT="${QRSPI_REPO_ROOT:-$REPO_ROOT_DEFAULT}"

AGENT_FILE=""
REVIEWER_TAG=""
OUTPUT_DIR=""
ROUND=""
TASK_DEF=""
DIFF_FILE=""
SCOPE_HINT=""
SCOPE_HINT_SET="false"
DRY_RUN="false"
MODEL=""
OUTPUT_FILE=""
ARTIFACT_DIR=""
TIMEOUT_SECONDS=""

SUBJECT_CODE_PATHS=()
ARTIFACT_BODY_PATHS=()

COMPANION_NAMES=()
COMPANION_PATHS=()

SCALAR_NAMES=()
SCALAR_VALUES=()

require_value() {
  if [[ "$2" -lt 2 ]]; then
    echo "error: $1 requires a value" >&2
    exit 1
  fi
}

# ---------------------------------------------------------------------------
# Host identification and Codex availability probes (added in v0.7.1 task-06)
# ---------------------------------------------------------------------------

# detect_host - emits either 'copilot-cli' or 'claude-code' to stdout.
# Examines COPILOT_CLI AND the reachability of the gh binary to prevent
# transport-marker spoofing via a user-supplied env var alone.
# COPILOT_CLI=1 selects copilot-cli ONLY when `gh` resolves to a path under
# a system-controlled prefix (/usr/*, /opt/*, /Applications/*).
# (process-spawn fingerprint: a real Copilot CLI session launches under gh).
# All other states (COPILOT_CLI unset/empty/non-"1", gh absent, or gh in an
# untrusted prefix) select claude-code.  Always exits 0.  Writes nothing to
# stderr under normal operation.
#
# Why the binary check is load-bearing: COPILOT_CLI is a user-settable env var,
# so the marker alone is forgeable.  Requiring `gh` to also resolve to a path
# under a system-controlled prefix (/usr/*, /opt/*, /Applications/*) raises the
# bar — an attacker would need both the env var AND a writable system prefix.
#
# Why prefix-matching on a normalized path: a raw `command -v` result can be
# bypassed via PATH injection (PATH=/usr/../tmp/fakebins:...) and via symlinks
# inside trusted prefixes that point at attacker-controlled binaries.  Resolve
# with realpath (BSD/macOS) or readlink -f (GNU/Linux) before the prefix check;
# both resolve `..` segments AND follow symlinks so the canonical filesystem
# path is compared.
#
# Why fail-closed when normalization is unavailable: if both realpath and
# readlink -f are absent or fail, `_gh_path` is forced to "" and the downstream
# -n guard short-circuits to the safe claude-code default.  No path
# normalization = no trusted-prefix check.
detect_host() {
  local _gh_path
  _gh_path="$(command -v gh 2>/dev/null)"
  # Normalize: resolve symlinks and .. segments so the prefix check operates on
  # the canonical filesystem path, not a PATH-constructed string.
  # Fail-closed: if both tools are absent/fail, _gh_path is set to ""; the -n
  # guard below then short-circuits to the safe claude-code default.
  if [[ -n "$_gh_path" ]]; then
    _gh_path="$(realpath "$_gh_path" 2>/dev/null || readlink -f "$_gh_path" 2>/dev/null)" || _gh_path=""
  fi
  if [[ "${COPILOT_CLI:-}" == "1" ]] && \
     [[ -n "$_gh_path" ]] && \
     [[ "$_gh_path" == /usr/* || "$_gh_path" == /opt/* || "$_gh_path" == /Applications/* ]]; then
    echo "copilot-cli"
  else
    echo "claude-code"
  fi
}

# check_codex_available <host> - exits 0 if Codex is usable for the given host.
#   copilot-cli: always exits 0 (Codex is natively routable; no filesystem probe).
#   claude-code:  probes the companion-script glob path; exits 0 when at least
#                 one matching file exists, non-zero otherwise.
#   other:        exits non-zero and emits a single-line diagnostic to stderr.
# bash-3.2 portable: no nameref, no declare -A, no ${var,,}, no mapfile.
check_codex_available() {
  local host="${1:-}"
  case "$host" in
    copilot-cli)
      return 0
      ;;
    claude-code)
      # Reject HOME values that contain '..' path components, are empty, or
      # contain newlines — any of these could allow filesystem probing outside
      # the expected ~/.claude/ tree.
      case "${HOME:-}" in
        *..* | "" | *$'\n'*)
          echo "check_codex_available: unsafe HOME value — must be an absolute path without '..' components" >&2
          return 1
          ;;
      esac
      # The case guard above does not check for a leading '/'.  A relative HOME
      # value (e.g. HOME=relative-dir) would pass all case arms and cause the
      # companion glob to expand relative to the process CWD.  Enforce that
      # HOME starts with '/' before any filesystem probe.
      if [[ "${HOME}" != /* ]]; then
        echo "check_codex_available: HOME must be an absolute path (got: relative path)" >&2
        return 1
      fi
      local found=0
      local f
      for f in "${HOME}/.claude/plugins/cache/openai-codex/codex"/*/scripts/codex-companion.mjs; do
        if [[ -f "$f" ]]; then
          found=1
          break
        fi
      done
      if [[ "$found" -eq 1 ]]; then
        return 0
      else
        return 1
      fi
      ;;
    *)
      echo "check_codex_available: unsupported host argument: $host" >&2
      return 1
      ;;
  esac
}

# ---------------------------------------------------------------------------
# Dispatch manifest persistence — per-dispatch provenance + job metadata
# under <round-dir>/.dispatch-manifest.json (CD-1 dispatch-manifest schema,
# structure.md §10).  Defined before the QRSPI_SOURCE_ONLY source guard so
# emit_first_party_manifest_entry is callable via source-only mode in tests.
# ---------------------------------------------------------------------------

# _validate_output_dir <value> — allowlist-validate OUTPUT_DIR.
# OUTPUT_DIR is interpolated into split_cmd stored in the manifest; downstream
# consumers eval-expand that field.  Restrict to an absolute path containing
# only characters safe in an unquoted shell word (letters, digits,
# . _ / : @ -).  Called from the --output-dir parse case and also internally
# before writing the manifest.
_validate_output_dir() {
  local v="$1"
  if [[ -z "$v" ]]; then echo "error: OUTPUT_DIR is empty" >&2; exit 1; fi
  if [[ "${v:0:1}" != "/" ]]; then echo "error: OUTPUT_DIR must be absolute: $v" >&2; exit 1; fi
  if ! [[ "$v" =~ ^/[A-Za-z0-9_./:@-]+$ ]]; then
    echo "error: OUTPUT_DIR contains disallowed characters: $v" >&2
    exit 1
  fi
}

# _validate_job_id <value> — allowlist-validate a captured JOB_ID.
# JOB_ID is interpolated into await_cmd stored in the manifest; downstream
# consumers eval-expand that field.  Restrict to characters safe in an
# unquoted shell word.  Only called when the value is non-empty.
_validate_job_id() {
  local v="$1"
  if [[ -z "$v" ]]; then echo "error: job_id is empty" >&2; exit 1; fi
  if ! [[ "$v" =~ ^[A-Za-z0-9_:@.-]+$ ]]; then
    echo "error: job_id contains disallowed characters: $v" >&2
    exit 1
  fi
}

# Script-level variable used by the _append_manifest_entry lock trap so the
# trap string can reference a non-local path when the EXIT trap fires after
# the function's stack frame has been torn down.  Lock is released by the
# EXIT/INT/TERM trap; SIGKILL still leaves stale lock but the 30s mtime probe
# will recover on next invocation.
_manifest_lock_dir=""
# Script-level relay for the manifest tmpfile created inside _append_manifest_entry.
# The EXIT/INT/TERM trap strings reference this so the tmpfile is cleaned up
# even when a signal fires after mktemp but before mv-promotion completes.
_manifest_tmp=""
# Script-level relay for the first-party prompt tmpfile (_fp_tmp) created in
# the copilot-cli dispatch path.  The trap installed after mktemp references
# this so the assembled prompt (containing subject code) is removed on signal.
_fp_tmp=""

# _append_manifest_entry <entry-json> — shared atomic JSON array append.
# Uses jq to parse and append so trailing-whitespace/newline variations in
# the existing manifest file cannot corrupt the output shape.
#
# Concurrency safety: uses a portable mkdir-as-mutex so concurrent invocations
# (e.g. multiple reviewer tags dispatched in the same wave) cannot interleave
# their reads and writes.  mkdir is atomic on POSIX filesystems; only one
# writer creates the lock dir at a time.  The loser spins with a 50 ms back-off
# for up to 100 attempts (~5 s) before aborting with a diagnostic.
# Lock is released by EXIT/INT/TERM trap; SIGKILL still leaves stale lock but
# the 30s mtime probe will recover on next invocation.
#
# NOTE: This function explicitly disables set -e / set -E / set -T on entry
# to isolate the lock mechanics from any inherited shell flags (e.g. bats
# test infrastructure sets -eET on its subshells). The flags are restored
# on return so callers are not affected.
_append_manifest_entry() {
  # Save and disable set -e/-E/-T so inherited flags from test harnesses (e.g.
  # bats -eET) cannot cause premature exits or cause $? to mutate inside the
  # lock mechanics or cause the rmdir cleanup to return non-0 to set -e.
  local _saved_opts; _saved_opts="$(set +o | grep -E 'errexit|errtrace|functrace')"
  set +eET

  local entry="$1"
  local manifest="$OUTPUT_DIR/.dispatch-manifest.json"
  mkdir -p "$OUTPUT_DIR" || { echo "error: _append_manifest_entry: cannot create OUTPUT_DIR $OUTPUT_DIR" >&2; eval "$_saved_opts"; exit 1; }
  # Acquire the lock: try to create the lock directory; spin on failure.
  local _lock_dir="${manifest}.lock"
  local _lock_attempt=0
  while true; do
    if mkdir "$_lock_dir" 2>/dev/null; then
      # Record in a script-level variable so the EXIT trap string can
      # reference it even after this function's stack frame is gone.
      _manifest_lock_dir="$_lock_dir"
      # Reset the manifest-tmp relay to "" at lock-acquisition time so the
      # trap's first reference is always "" rather than a stale path from a
      # prior interrupted call.  Eliminates the "stale path from prior call"
      # orphan hazard for the narrow window between mktemp and relay assignment.
      _manifest_tmp=""
      # EXIT: pure cleanup — just release the lock (no exit call so normal
      # completion paths are not affected).
      # INT/TERM: release the lock THEN exit so bash does not resume the
      # interrupted function body without holding the lock (which would race
      # concurrent writers).  exit 130 = 128+SIGINT(2); exit 143 = 128+SIGTERM(15).
      trap 'rm -f "$_manifest_tmp" 2>/dev/null || true; rmdir "$_manifest_lock_dir" 2>/dev/null || true' EXIT
      trap 'rm -f "$_manifest_tmp" 2>/dev/null || true; rmdir "$_manifest_lock_dir" 2>/dev/null || true; exit 130' INT
      trap 'rm -f "$_manifest_tmp" 2>/dev/null || true; rmdir "$_manifest_lock_dir" 2>/dev/null || true; exit 143' TERM
      break
    fi
    # Stale-lock probe: if the lockdir is older than 30s, attempt to remove
    # and retry rather than spinning indefinitely.  Use current time as fallback
    # when stat fails (TOCTOU: lock dir just released) so _lock_age stays 0,
    # avoiding a false-positive stale detection.
    if [[ -d "$_lock_dir" ]]; then
      local _now; _now=$(date +%s)
      local _mtime; _mtime=$(stat -f %m "$_lock_dir" 2>/dev/null || stat -c %Y "$_lock_dir" 2>/dev/null || echo "$_now")
      _lock_age=$(( _now - _mtime ))
      if (( _lock_age > 30 )); then
        rmdir "$_lock_dir" 2>/dev/null || true
        # Retry mkdir on next loop iteration.
        continue
      fi
    fi
    _lock_attempt=$((_lock_attempt + 1))
    if (( _lock_attempt >= 100 )); then
      echo "error: _append_manifest_entry: could not acquire lock at ${_lock_dir} after 100 attempts" >&2
      eval "$_saved_opts"
      exit 1
    fi
    sleep 0.05
  done
  # Use mktemp for the manifest tmpfile to avoid a predictable-name symlink
  # pre-placement attack: BASHPID/$$ are enumerable and an attacker can place
  # a symlink at ${manifest}.tmp.<predicted-pid> before the lock is acquired.
  # mktemp uses O_EXCL (symlink-safe); the mv -f below promotes atomically.
  local tmp
  if ! tmp="$(mktemp "${manifest}.tmp.XXXXXX")"; then
    echo "error: mktemp failed for manifest tmp" >&2
    trap - EXIT INT TERM
    rmdir "$_lock_dir" 2>/dev/null || true
    eval "$_saved_opts"
    exit 1
  fi
  # Mirror tmp into the script-level relay so the EXIT/INT/TERM traps can
  # clean it up if a signal fires before the mv-promotion completes.
  _manifest_tmp="$tmp"
  if [[ -f "$manifest" ]]; then
    if ! jq --argjson new "$entry" '. + [$new]' "$manifest" > "$tmp"; then
      echo "error: _append_manifest_entry: jq append failed" >&2
      rm -f "$tmp"; _manifest_tmp=""
      trap - EXIT INT TERM
      rmdir "$_lock_dir" 2>/dev/null || true
      eval "$_saved_opts"
      exit 1
    fi
  else
    if ! jq -n --argjson new "$entry" '[$new]' > "$tmp"; then
      echo "error: _append_manifest_entry: jq init failed" >&2
      rm -f "$tmp"; _manifest_tmp=""
      trap - EXIT INT TERM
      rmdir "$_lock_dir" 2>/dev/null || true
      eval "$_saved_opts"
      exit 1
    fi
  fi
  # Validate output is parseable JSON array before clobbering.
  if ! jq -e 'type == "array"' "$tmp" > /dev/null; then
    echo "error: _append_manifest_entry: produced non-array output" >&2
    rm -f "$tmp"; _manifest_tmp=""
    trap - EXIT INT TERM
    rmdir "$_lock_dir" 2>/dev/null || true
    eval "$_saved_opts"
    exit 1
  fi
  if ! mv "$tmp" "$manifest"; then
    echo "error: _append_manifest_entry: mv failed" >&2
    rm -f "$tmp"; _manifest_tmp=""
    trap - EXIT INT TERM
    rmdir "$_lock_dir" 2>/dev/null || true
    eval "$_saved_opts"
    exit 1
  fi
  # Release the lock and disarm the trap.  Clear the relay first so a
  # subsequent _append_manifest_entry call's trap installation starts clean.
  _manifest_tmp=""
  trap - EXIT INT TERM
  rmdir "$_lock_dir" 2>/dev/null || true
  eval "$_saved_opts"
}

# emit_dispatch_manifest_entry <job_id> [status] — write a third-party/
# background entry.  The dispatch_spec object carries
# subagent_type/host/vendor/model; top-level fields carry mode=background,
# status (default "pending"), agent, job_id, await_cmd, split_cmd.
# Pass status="failed" on the failure path so the manifest is auditable even
# when the dispatcher exits non-zero.
# jq --arg provides unconditional JSON string escaping (defense-in-depth
# alongside the argument-parse allowlist validators).
# The explicit jq-failure guard makes a missing or broken jq loud and aborts
# before any tmp-file write, preventing silent manifest corruption.
emit_dispatch_manifest_entry() {
  local job_id="${1:-}"
  local status="${2:-pending}"
  local detected_host
  detected_host="$(detect_host)"
  local agent_name
  agent_name="$(basename "${AGENT_FILE%.md}")"
  local entry
  entry="$(jq -nc \
    --arg tag       "$REVIEWER_TAG" \
    --arg agent     "$agent_name" \
    --arg mode      "background" \
    --arg status    "$status" \
    --arg job_id    "$job_id" \
    --arg subtype   "$agent_name" \
    --arg host      "$detected_host" \
    --arg vendor    "openai-codex" \
    --arg model     "$MODEL" \
    --arg await_cmd "scripts/run-third-party-llm.sh await $job_id" \
    --arg split_cmd "scripts/codex-finding-splitter.sh --round-dir $OUTPUT_DIR --tag $REVIEWER_TAG" \
    '{tag: $tag, agent: $agent, mode: $mode, status: $status, job_id: $job_id,
      dispatch_spec: {subagent_type: $subtype, host: $host, vendor: $vendor, model: $model},
      await_cmd: $await_cmd, split_cmd: $split_cmd}')" \
    || { echo "error: jq failed building dispatch-manifest entry (jq exit $?)" >&2; exit 1; }
  _append_manifest_entry "$entry"
}

# emit_first_party_manifest_entry <prompt_file> [vendor] [model] — write a
# first-party/dispatched entry.  The dispatch_spec object carries
# subagent_type/host/vendor/model/prompt_file; top-level fields carry
# mode=first_party, status=dispatched, agent.  Callable via
# QRSPI_SOURCE_ONLY=1 for schema-shape acceptance testing before the full
# first-party dispatch path ships in scripts/dispatch-agent.sh.
emit_first_party_manifest_entry() {
  local prompt_file="${1:-}"
  local vendor="${2:-claude}"
  local fp_model="${3:-${MODEL:-}}"
  local detected_host
  detected_host="$(detect_host)"
  local agent_name
  agent_name="$(basename "${AGENT_FILE%.md}")"
  local entry
  entry="$(jq -nc \
    --arg tag     "$REVIEWER_TAG" \
    --arg agent   "$agent_name" \
    --arg mode    "first_party" \
    --arg status  "dispatched" \
    --arg subtype "$agent_name" \
    --arg host    "$detected_host" \
    --arg vendor  "$vendor" \
    --arg model   "$fp_model" \
    --arg pf      "$prompt_file" \
    '{tag: $tag, agent: $agent, mode: $mode, status: $status,
      dispatch_spec: {subagent_type: $subtype, host: $host, vendor: $vendor, model: $model, prompt_file: $pf}}')" \
    || { echo "error: jq failed building first-party manifest entry (jq exit $?)" >&2; exit 1; }
  _append_manifest_entry "$entry"
}

# Source guard: when QRSPI_SOURCE_ONLY=1, return after loading function
# definitions so that function-isolation tests can source this file and call
# detect_host / check_codex_available directly without triggering argument
# parsing or validation.
#
# `return 0` is only valid in a sourced context.  When the script is executed
# directly (`bash run-codex-review.sh`) the failed `return` does not abort
# execution and would fall through into argument parsing.
# `return 0 2>/dev/null || exit 0` works in both modes: `return 0` succeeds
# when sourced; `exit 0` fires when executed directly.
if [[ "${QRSPI_SOURCE_ONLY:-}" == "1" ]]; then
  return 0 2>/dev/null || exit 0
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --agent-file)     require_value "--agent-file"   "$#"; AGENT_FILE="$2"; shift 2 ;;
    --reviewer-tag)
      require_value "--reviewer-tag" "$#"
      # Allowlist validation (T09 R2 fix): --reviewer-tag is concatenated
      # into the dispatch-manifest JSON entry. Restricting it to a safe
      # token grammar ([a-z][a-z0-9_-]*) is defense-in-depth alongside the
      # jq-based JSON construction below — it ensures crafted tags
      # carrying JSON-structural characters cannot reach the manifest
      # writer at all. The grammar mirrors the existing reviewer-tag
      # values used in this codebase (e.g. spec-codex, sec-claude).
      if [[ ! "$2" =~ ^[a-z][a-z0-9_-]*$ ]]; then
        echo "error: --reviewer-tag must match [a-z][a-z0-9_-]* (got: $2)" >&2
        exit 1
      fi
      REVIEWER_TAG="$2"; shift 2 ;;
    --output-dir)
      require_value "--output-dir" "$#"
      _validate_output_dir "$2"
      OUTPUT_DIR="$2"; shift 2 ;;
    --round)          require_value "--round"        "$#"; ROUND="$2"; shift 2 ;;
    --model)
      require_value "--model" "$#"
      # Allowlist validation (T09 R2 fix): --model is concatenated into
      # the dispatch-manifest JSON entry and into the reviewer-prompt
      # body. The grammar permits the punctuation real model IDs use
      # (dot, hyphen, underscore) but excludes JSON-structural characters
      # ('"', ',', ':', '{', '}', whitespace). Defense-in-depth alongside
      # the jq-based JSON construction below.
      if [[ ! "$2" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]]; then
        echo "error: --model must match [A-Za-z0-9][A-Za-z0-9._-]* (got: $2)" >&2
        exit 1
      fi
      MODEL="$2"; shift 2 ;;
    --output-file)    require_value "--output-file"  "$#"; OUTPUT_FILE="$2"; shift 2 ;;
    --artifact-dir)   require_value "--artifact-dir" "$#"; ARTIFACT_DIR="$2"; shift 2 ;;
    --timeout-seconds) require_value "--timeout-seconds" "$#"; TIMEOUT_SECONDS="$2"; shift 2 ;;
    --subject-code)   require_value "--subject-code" "$#"; SUBJECT_CODE_PATHS+=("$2"); shift 2 ;;
    --artifact-body)  require_value "--artifact-body" "$#"; ARTIFACT_BODY_PATHS+=("$2"); shift 2 ;;
    --task-def)       require_value "--task-def"     "$#"; TASK_DEF="$2"; shift 2 ;;
    --companion)
      require_value "--companion" "$#"
      if [[ "$2" != *=* ]]; then
        echo "error: --companion requires NAME=PATH (got: $2)" >&2
        exit 1
      fi
      cname="${2%%=*}"
      cpath="${2#*=}"
      if [[ -z "$cname" || -z "$cpath" ]]; then
        echo "error: --companion NAME=PATH must have non-empty NAME and PATH (got: $2)" >&2
        exit 1
      fi
      if [[ ! "$cname" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
        echo "error: --companion NAME must match [A-Za-z_][A-Za-z0-9_]* (got: $cname)" >&2
        exit 1
      fi
      COMPANION_NAMES+=("$cname")
      COMPANION_PATHS+=("$cpath")
      shift 2
      ;;
    --field)
      require_value "--field" "$#"
      if [[ "$2" != *=* ]]; then
        echo "error: --field requires NAME=VALUE (got: $2)" >&2
        exit 1
      fi
      fname="${2%%=*}"
      fvalue="${2#*=}"
      if [[ -z "$fname" ]]; then
        echo "error: --field NAME=VALUE must have non-empty NAME (got: $2)" >&2
        exit 1
      fi
      if [[ ! "$fname" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
        echo "error: --field NAME must match [A-Za-z_][A-Za-z0-9_]* (got: $fname)" >&2
        exit 1
      fi
      SCALAR_NAMES+=("$fname")
      SCALAR_VALUES+=("$fvalue")
      shift 2
      ;;
    --diff-file)      require_value "--diff-file"  "$#"; DIFF_FILE="$2"; shift 2 ;;
    --scope-hint)     require_value "--scope-hint" "$#"; SCOPE_HINT="$2"; SCOPE_HINT_SET="true"; shift 2 ;;
    --dry-run)        DRY_RUN="true"; shift ;;
    *)
      echo "error: unrecognized flag: $1" >&2
      exit 1
      ;;
  esac
done

# ---------------------------------------------------------------------------
# Validation
# ---------------------------------------------------------------------------

require_flag() {
  local name="$1"
  local val="$2"
  if [[ -z "$val" ]]; then
    echo "error: --${name} required" >&2
    exit 1
  fi
}

require_flag "agent-file"   "$AGENT_FILE"
require_flag "reviewer-tag" "$REVIEWER_TAG"
require_flag "output-dir"   "$OUTPUT_DIR"
require_flag "round"        "$ROUND"

# New required flags for the dispatcher hand-off. Without --artifact-dir
# the dispatcher would exit 1 per T03's required-flag contract — surface
# that as a shim-side diagnostic so callers see the missing flag clearly.
# Dispatch-only: --dry-run prints the assembled prompt and never invokes
# the dispatcher, so these flags are optional in that path.
if [[ "$DRY_RUN" != "true" ]]; then
  require_flag "model"        "$MODEL"
  require_flag "output-file"  "$OUTPUT_FILE"
  require_flag "artifact-dir" "$ARTIFACT_DIR"
fi

# --output-dir must be absolute (load-bearing for agent-side Phase Routing
# fail-loud substring check on /reviews/test/).
if [[ "$OUTPUT_DIR" != /* ]]; then
  echo "error: --output-dir must be absolute (got: $OUTPUT_DIR)" >&2
  exit 1
fi

if [[ ${#SUBJECT_CODE_PATHS[@]} -eq 0 && ${#ARTIFACT_BODY_PATHS[@]} -eq 0 ]]; then
  echo "error: at least one --subject-code or --artifact-body required" >&2
  exit 1
fi
if [[ ${#SUBJECT_CODE_PATHS[@]} -gt 0 && ${#ARTIFACT_BODY_PATHS[@]} -gt 0 ]]; then
  echo "error: --subject-code and --artifact-body are mutually exclusive (pick the per-step name)" >&2
  exit 1
fi
if [[ ${#SUBJECT_CODE_PATHS[@]} -gt 0 ]]; then
  PRIMARY_FIELD="subject_code"
  PRIMARY_PATHS=("${SUBJECT_CODE_PATHS[@]}")
else
  PRIMARY_FIELD="artifact_body"
  PRIMARY_PATHS=("${ARTIFACT_BODY_PATHS[@]}")
fi

resolve_path() {
  local p="$1"
  if [[ "$p" == /* ]]; then
    echo "$p"
  else
    echo "$REPO_ROOT/$p"
  fi
}

assert_file_exists() {
  local label="$1"
  local p="$2"
  if [[ ! -f "$p" ]]; then
    echo "error: ${label} not found: $p" >&2
    exit 1
  fi
}

AGENT_FILE_ABS="$(resolve_path "$AGENT_FILE")"
assert_file_exists "agent-file" "$AGENT_FILE_ABS"

REVIEWER_PROTOCOL_ABS="$REPO_ROOT/skills/reviewer-protocol/SKILL.md"
assert_file_exists "reviewer-protocol/SKILL.md" "$REVIEWER_PROTOCOL_ABS"

EMISSION_OVERRIDE_ABS="$REPO_ROOT/skills/reviewer-protocol/codex-emission-override.md"
assert_file_exists "codex-emission-override.md" "$EMISSION_OVERRIDE_ABS"

# Parse the agent's `skills:` frontmatter field to discover additional
# shared skills the agent depends on (load chain unchanged from pre-T04).
extract_skill_names() {
  awk '
    /^---$/ { n++; if (n == 2) exit; next }
    n == 1 && /^skills:/ {
      if ($0 !~ /^skills:[[:space:]]*\[/) {
        printf "error: skills: frontmatter must use inline-list form `skills: [a, b, c]`; other forms (block-list, scalar) are not supported.\n" > "/dev/stderr"
        exit 2
      }
      sub(/^skills:[[:space:]]*\[/, "")
      sub(/\].*$/, "")
      gsub(/[[:space:]"'\'']/, "")
      n_items = split($0, items, ",")
      for (i = 1; i <= n_items; i++) {
        if (items[i] != "") print items[i]
      }
    }
  ' "$1"
}

SKILL_NAMES_OUTPUT="$(extract_skill_names "$AGENT_FILE_ABS")"
extract_status=$?
if [ "$extract_status" -ne 0 ]; then
  exit "$extract_status"
fi

ADDITIONAL_SKILL_PATHS=()
while IFS= read -r skill_name; do
  if [[ -z "$skill_name" || "$skill_name" == "reviewer-protocol" ]]; then
    continue
  fi
  skill_path="$REPO_ROOT/skills/$skill_name/SKILL.md"
  assert_file_exists "skill[$skill_name]" "$skill_path"
  ADDITIONAL_SKILL_PATHS+=("$skill_path")
done <<< "$SKILL_NAMES_OUTPUT"

PRIMARY_ABS=()
for sc in "${PRIMARY_PATHS[@]}"; do
  abs="$(resolve_path "$sc")"
  assert_file_exists "$PRIMARY_FIELD" "$abs"
  PRIMARY_ABS+=("$abs")
done

TASK_DEF_ABS=""
if [[ -n "$TASK_DEF" ]]; then
  TASK_DEF_ABS="$(resolve_path "$TASK_DEF")"
  assert_file_exists "task-def" "$TASK_DEF_ABS"
fi

COMPANION_ABS=()
for i in "${!COMPANION_PATHS[@]}"; do
  cpath="${COMPANION_PATHS[$i]}"
  cname="${COMPANION_NAMES[$i]}"
  abs="$(resolve_path "$cpath")"
  assert_file_exists "companion[$cname]" "$abs"
  COMPANION_ABS+=("$abs")
done

if [[ -n "$DIFF_FILE" ]]; then
  if [[ ! -f "$DIFF_FILE" ]]; then
    echo "error: diff-file not found: $DIFF_FILE" >&2
    exit 1
  fi
fi

# ---------------------------------------------------------------------------
# Marker-injection guard (unchanged from pre-T04). The dispatcher applies
# its own boundary-marker guard on stdin; this shim's guard is an additional
# defense-in-depth layer on the per-flag inputs before the prompt is
# assembled.
MARKER_LITERAL="<<<AGENT-BODY-END>>>"

reject_if_contains_marker_file() {
  if grep -F -q -- "$MARKER_LITERAL" "$2" 2>/dev/null; then
    echo "error: ${1} contains the wrapper-private marker '${MARKER_LITERAL}' (path: $2). This would defeat the agent-body carve-out; reject the input." >&2
    exit 1
  fi
}

reject_if_contains_marker_value() {
  if [[ "$2" == *"$MARKER_LITERAL"* ]]; then
    echo "error: ${1} contains the wrapper-private marker '${MARKER_LITERAL}'. This would defeat the agent-body carve-out; reject the input." >&2
    exit 1
  fi
}

for p in "${PRIMARY_ABS[@]}"; do
  reject_if_contains_marker_file "${PRIMARY_FIELD}" "$p"
done
if [[ -n "$TASK_DEF_ABS" ]]; then
  reject_if_contains_marker_file "task-def" "$TASK_DEF_ABS"
fi
for i in "${!COMPANION_ABS[@]}"; do
  reject_if_contains_marker_file "companion[${COMPANION_NAMES[$i]}]" "${COMPANION_ABS[$i]}"
done
if [[ -n "$DIFF_FILE" ]]; then
  reject_if_contains_marker_file "diff-file" "$DIFF_FILE"
fi
if [[ "$SCOPE_HINT_SET" == "true" ]]; then
  reject_if_contains_marker_value "scope-hint" "$SCOPE_HINT"
fi
for i in "${!SCALAR_NAMES[@]}"; do
  reject_if_contains_marker_value "field[${SCALAR_NAMES[$i]}]" "${SCALAR_VALUES[$i]}"
done

# ---------------------------------------------------------------------------
# Prompt-assembly helpers (unchanged from pre-T04)
# ---------------------------------------------------------------------------

strip_frontmatter() {
  awk '/^---$/ && n<2 {n++; next} n>=2 {print}' "$1"
}

emit_untrusted_artifact() {
  local path="$1"
  local id="${2:-$1}"
  printf '<<<UNTRUSTED-ARTIFACT-START id=%s>>>\n' "$id"
  cat "$path"
  printf '\n<<<UNTRUSTED-ARTIFACT-END id=%s>>>\n' "$id"
}

emit_dispatch_parameters() {
  printf '\n\n## Dispatch parameters\n\n'

  printf '%s:\n' "$PRIMARY_FIELD"
  for i in "${!PRIMARY_ABS[@]}"; do
    emit_untrusted_artifact "${PRIMARY_ABS[$i]}" "${PRIMARY_PATHS[$i]}"
    printf '\n'
  done

  if [[ -n "$TASK_DEF_ABS" ]]; then
    printf 'task_definition:\n'
    emit_untrusted_artifact "$TASK_DEF_ABS" "$TASK_DEF"
    printf '\n'
  fi

  emitted_names=" "
  for i in "${!COMPANION_NAMES[@]}"; do
    name="${COMPANION_NAMES[$i]}"
    if [[ "$emitted_names" != *" $name "* ]]; then
      printf '%s:\n' "$name"
      emitted_names="${emitted_names}${name} "
      for j in "${!COMPANION_NAMES[@]}"; do
        if [[ "${COMPANION_NAMES[$j]}" == "$name" ]]; then
          emit_untrusted_artifact "${COMPANION_ABS[$j]}" "${COMPANION_PATHS[$j]}"
          printf '\n'
        fi
      done
    fi
  done

  for i in "${!SCALAR_NAMES[@]}"; do
    printf '%s: %s\n' "${SCALAR_NAMES[$i]}" "${SCALAR_VALUES[$i]}"
  done

  printf 'round_subdir: %s\n' "$OUTPUT_DIR"
  printf 'round: %s\n' "$ROUND"
  printf 'reviewer_tag: %s\n' "$REVIEWER_TAG"

  if [[ -n "$DIFF_FILE" ]]; then
    printf 'diff_file_path: %s\n' "$DIFF_FILE"
  fi

  if [[ "$SCOPE_HINT_SET" == "true" ]]; then
    printf 'scope_hint: <<<UNTRUSTED-SCOPE-HINT-START id=scope_hint>>>%s<<<UNTRUSTED-SCOPE-HINT-END id=scope_hint>>>\n' "$SCOPE_HINT"
  fi
}

compose_prompt() {
  strip_frontmatter "$REVIEWER_PROTOCOL_ABS"
  printf '\n\n---\n\n'
  if (( ${#ADDITIONAL_SKILL_PATHS[@]} > 0 )); then
    for skill_path in "${ADDITIONAL_SKILL_PATHS[@]}"; do
      strip_frontmatter "$skill_path"
      printf '\n\n---\n\n'
    done
  fi
  strip_frontmatter "$AGENT_FILE_ABS"
  printf '\n\n---\n\n'
  cat "$EMISSION_OVERRIDE_ABS"
  printf '\n\n<<<AGENT-BODY-END>>>\n'
  emit_dispatch_parameters
}

# ---------------------------------------------------------------------------
# Forward to the universal dispatcher.
# Per T04: this shim does NOT pass a transport flag — transport selection is
# config-driven through the `codex` entry in `<artifact-dir>/config.md`'s
# `providers:` block (which carries `transport_type: codex-broker`). The
# shim does NOT source or invoke `scripts/codex-companion-bg.sh` directly;
# the broker chaining happens inside the dispatcher's codex-broker branch.
# ---------------------------------------------------------------------------

if [[ "$DRY_RUN" == "true" ]]; then
  compose_prompt
  exit 0
fi


# Pipe the assembled prompt to the dispatcher's stdin and propagate its
# exit code unchanged (per the exit-code matrix above).
#
# Host detection and transport routing (added in v0.7.1 task-06):
# detect_host probes COPILOT_CLI to select the transport.  check_codex_available
# verifies availability.  A mismatch between availability and the codex_reviews
# config value emits a single-line warning to stderr (warning-only - does not
# block dispatch or override exit code).  The transport marker ([transport: ...])
# is emitted once to stderr at the call site that selects the transport path.

_detected_host="$(detect_host)"

# Read codex_reviews from the artifact-dir config.md frontmatter.
# Default to empty (treated as false) if the file is absent or the field is missing.
_codex_reviews=""
if [[ -f "$ARTIFACT_DIR/config.md" ]]; then
  _codex_reviews="$(awk '
    /^---$/ { n++; if (n == 2) exit; next }
    n == 1 && /^codex_reviews:/ {
      sub(/^codex_reviews:[[:space:]]*/, "")
      sub(/[[:space:]]*$/, "")
      print
      exit
    }
  ' "$ARTIFACT_DIR/config.md")"
fi

# Normalise codex_reviews to exactly "true" or "false" before any use.  An
# unexpected value (which could carry terminal control sequences from a
# crafted config.md) is treated as "false" and never echoed verbatim.
case "$_codex_reviews" in
  true|false) ;;
  *) _codex_reviews="false" ;;
esac

# Probe Codex availability for the detected host.  Capture the exit code so we
# can propagate it exactly (no remapping) when short-circuiting.  No
# 2>/dev/null suppression so that any check_codex_available diagnostic (e.g.
# unrecognised host, unsafe HOME) reaches the operator.
if check_codex_available "$_detected_host"; then
  _codex_available="true"
  _check_exit=0
else
  _check_exit=$?
  _codex_available="false"
fi

# Mismatch warning: detected-host Codex availability disagrees with the
# codex_reviews config value.  Decoupled from the short-circuit below (T7):
# the warning fires on ANY availability-vs-config disagreement, including the
# copilot-cli + codex_reviews=false case where check_codex_available trivially
# succeeds.  Warning-only — does not gate dispatch and does not override the
# transport's exit code.  Fires at most once per dispatch (single >&2 emission).
if [[ "$_codex_available" != "$_codex_reviews" ]]; then
  echo "[mismatch] detected host=${_detected_host} (codex available=${_codex_available}), codex_reviews config=${_codex_reviews}" >&2
fi

# check_codex_available short-circuit (T7): when Codex is unavailable but the
# run config requested Codex reviews, abort before invoking the transport.
# Emit a single-line stderr diagnostic and propagate the EXACT non-zero exit
# code returned by check_codex_available (no remapping, no log-and-continue).
# When codex_reviews=false the wrapper falls through to dispatch unchanged so
# callers that exercise the dispatch surface in isolation are not affected.
if [[ "$_codex_available" == "false" && "$_codex_reviews" == "true" ]]; then
  echo "[codex-unavailable] check_codex_available exit=${_check_exit} for host=${_detected_host} — aborting Codex dispatch" >&2
  exit "$_check_exit"
fi

# Emit the transport marker and dispatch.
#
# Copilot CLI (task-tool) → first-party path: assemble the full reviewer
# prompt and write it to <round-dir>/.dispatch/<tag>.prompt so the
# orchestrator can pass the file reference to the Task tool as
# DISPATCH_FILE=<path>.  Emit the DISPATCH_FILE= reference to stdout (the
# orchestrator-facing dispatch payload stays a prompt-file reference; the
# prompt body never enters the orchestrator's tool-call arguments).  Record
# a first_party manifest entry and exit 0.
#
# Claude Code (shell-pipeline) → third-party path: pipe the assembled prompt
# to run-third-party-llm.sh.  Capture the dispatcher's stdout to extract a
# JOB_ID line if present.  After a successful dispatch, persist the manifest
# entry with the captured job_id.  Exit code is propagated unchanged from
# the transport; on non-zero we persist a "failed" manifest entry so the
# round's attempted dispatch is auditable.
if [[ "$_detected_host" == "copilot-cli" ]]; then
  echo "[transport: task-tool]" >&2
  # First-party dispatch: write assembled prompt to a .dispatch/ file so the
  # orchestrator can reference it via DISPATCH_FILE= without embedding the
  # prompt body in its tool-call arguments (per design.md CD-1 PATH A).
  _fp_dispatch_dir="$OUTPUT_DIR/.dispatch"
  mkdir -p "$_fp_dispatch_dir" || { echo "error: cannot create dispatch dir $_fp_dispatch_dir" >&2; exit 1; }
  _fp_prompt_file="$_fp_dispatch_dir/$REVIEWER_TAG.prompt"
  # Write prompt via mktemp + mv -f to avoid a TOCTOU symlink attack: the
  # rm-f then open(2)-for-redirect pair is not atomic.  mktemp uses O_EXCL
  # (symlink-safe); rename(2) replaces the destination atomically without
  # following symlinks.
  _fp_tmp=""
  if ! _fp_tmp="$(mktemp "${_fp_prompt_file}.tmp.XXXXXX")"; then
    echo "error: mktemp failed for first-party prompt tmpfile" >&2
    exit 1
  fi
  # Install signal-cleanup trap for _fp_tmp so the assembled prompt (which
  # contains subject code) is removed if SIGINT/SIGTERM fires before mv-promotion
  # completes.  Mirror of the _manifest_tmp relay+trap pattern.
  trap 'rm -f "$_fp_tmp" 2>/dev/null || true' EXIT INT TERM
  if ! compose_prompt > "$_fp_tmp"; then
    rm -f "$_fp_tmp"; _fp_tmp=""
    trap - EXIT INT TERM
    echo "error: compose_prompt failed for first-party dispatch" >&2
    exit 1
  fi
  if ! mv -f "$_fp_tmp" "$_fp_prompt_file"; then
    rm -f "$_fp_tmp"; _fp_tmp=""
    trap - EXIT INT TERM
    echo "error: mv -f failed promoting first-party prompt tmpfile" >&2
    exit 1
  fi
  # mv succeeded: tmpfile has been promoted; clear relay and disarm trap before
  # calling emit_first_party_manifest_entry (which installs its own traps).
  _fp_tmp=""
  trap - EXIT INT TERM
  # Emit the orchestrator-facing DISPATCH_FILE reference to stdout.
  printf 'DISPATCH_FILE=%s\n' "$_fp_prompt_file"
  emit_first_party_manifest_entry "$_fp_prompt_file"
  exit 0
fi

echo "[transport: shell-pipeline]" >&2

# Third-party (shell-pipeline) dispatch path.
# DISPATCHER existence check is here (not at module-init scope) so the
# first-party copilot-cli path is never blocked by a missing dispatcher
# binary.  Only the third-party branch needs the dispatcher.
DISPATCHER="$REPO_ROOT/scripts/run-third-party-llm.sh"
if [[ ! -x "$DISPATCHER" && ! -r "$DISPATCHER" ]]; then
  echo "error: run-third-party-llm.sh not found at $DISPATCHER" >&2
  exit 1
fi

# Build dispatcher argv. --provider codex is hardcoded; --model, --output-file,
# and --artifact-dir come from the shim's caller. Optional --timeout-seconds
# is forwarded when present.
DISPATCHER_ARGS=(
  --provider codex
  --model "$MODEL"
  --output-file "$OUTPUT_FILE"
  --artifact-dir "$ARTIFACT_DIR"
)
if [[ -n "$TIMEOUT_SECONDS" ]]; then
  DISPATCHER_ARGS+=(--timeout-seconds "$TIMEOUT_SECONDS")
fi

# Capture the dispatcher's stdout to extract a JOB_ID line if present.
# A future dispatch-companion.sh will emit JOB_ID; current dispatchers may
# not, in which case a missing JOB_ID on success is treated as a dispatcher
# bug and the script fails loud.
# On dispatch failure (non-zero exit), persist a "failed" manifest entry so
# the round's attempted dispatch is auditable, then propagate the exit code.
_dispatch_stdout=""
_dispatch_exit=0
_dispatch_stdout="$( set -o pipefail; compose_prompt | bash "$DISPATCHER" "${DISPATCHER_ARGS[@]}" )" \
  || _dispatch_exit=$?

# Forward all dispatcher stdout lines to our stdout EXCEPT JOB_ID= lines,
# which are silently consumed for manifest persistence.  This preserves the
# pass-through behavior expected by callers that inspect script stdout (e.g.,
# transport-marker tests), while letting the manifest writer capture the
# background job identifier.
_job_id=""
if [[ -n "$_dispatch_stdout" ]]; then
  while IFS= read -r _line; do
    if [[ "$_line" =~ ^JOB_ID= ]]; then
      _job_id="${_line#JOB_ID=}"
    else
      printf '%s\n' "$_line"
    fi
  done <<< "$_dispatch_stdout"
fi

if [[ "$_dispatch_exit" -ne 0 ]]; then
  # Dispatch failed: persist a "failed" audit entry so the round is auditable,
  # then propagate the non-zero exit code.
  # Run in a subshell so that emit_dispatch_manifest_entry's internal exit 1
  # (e.g., on jq failure) does not mask the real dispatcher exit code.
  ( emit_dispatch_manifest_entry "" "failed" ) || true
  exit "$_dispatch_exit"
fi

if [[ -z "$_job_id" ]]; then
  echo "error: dispatcher exited 0 but emitted no JOB_ID" >&2
  exit 1
fi

_validate_job_id "$_job_id"
emit_dispatch_manifest_entry "$_job_id" "pending"
exit 0
