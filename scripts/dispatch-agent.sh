#!/usr/bin/env bash
# dispatch-agent.sh — universal reviewer/agent dispatch entry point.
#
# Renamed from the legacy review wrapper (CD-1 vendor-neutral dispatch rename). Two
# invocation modes share this entry point:
#   - Batched form (`--step/--round/--output-dir/--artifact/--agents`): resolves
#     N reviewers in one call, emits one `MODE=first_party …` spec line per
#     first-party reviewer to stdout, and records each dispatch in
#     `<output-dir>/.dispatch-manifest.json`.
#   - Single-reviewer form (the historical flag surface below): assembles one
#     reviewer prompt and either writes a first-party DISPATCH_FILE or forwards
#     the assembled prompt over stdin to `scripts/dispatch-companion.sh`.
#
# Per-task implementer dispatch shim: this script no longer drives the Codex broker
# directly. It preserves its existing caller-facing flag surface (assembling
# the reviewer prompt from the reviewer-protocol body, the named agent body
# with frontmatter stripped, the stdout-fallback emission override, and a Dispatch
# parameters block), and then forwards the assembled prompt over stdin to
# `scripts/dispatch-companion.sh` with `--provider codex --model <id>
# --output-file <path> --artifact-dir <dir>`. Transport selection
# (codex-broker) is config-driven via the `codex` entry in
# `<artifact-dir>/config.md`'s `providers:` block — this shim does NOT pass
# a transport flag. The dispatcher's exit code is propagated unchanged.
#
# Usage (existing flag surface preserved, three new required flags added
# for the dispatcher hand-off):
#   scripts/dispatch-agent.sh \
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
export REPO_ROOT

# Repo-boundary guard for every prompt-ingested path argument. Sourced
# from a shared lib so dispatch-companion.sh's launch-mode `--prompt-file`
# surface uses the same canonical-$REPO_ROOT/ enforcement.
# shellcheck source=scripts/lib/path-guard.sh
. "$SCRIPT_DIR/lib/path-guard.sh"
command -v assert_path_under_repo_root >/dev/null 2>&1 \
  || { echo "error: assert_path_under_repo_root not defined after sourcing path-guard.sh; aborting (fail-closed)" >&2; exit 1; }

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

# assert_file_exists <label> <path> — verify a required file exists; exits 1
# with a clear diagnostic when it does not.  Defined early (before the batch
# block) so it is available in both batched-mode and single-mode code paths.
assert_file_exists() {
  local label="$1"
  local p="$2"
  if [[ ! -f "$p" ]]; then
    echo "error: ${label} not found: $p" >&2
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
# JOB_ID is stored in the manifest and later passed to await-round.sh via
# shlex.split (shell=False); a job ID containing shlex-special characters
# causes shlex.split to raise ValueError, which marks the manifest entry
# failed and silently drops the finding. Restricting to a safe token grammar
# prevents that denial-of-service vector. Only called when the value is non-empty.
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

# Internal helper for _append_manifest_entry: emit a named error, clean up the
# manifest tmpfile + relay, disarm traps, release the lock dir, restore caller
# opts, and exit 1. Safe to call when $_manifest_tmp is empty (mktemp-failed
# branch) — rm -f "" is a no-op.
_append_manifest_fail() {
  local _msg="$1"
  echo "error: _append_manifest_entry: $_msg" >&2
  rm -f "$_manifest_tmp" 2>/dev/null || true
  _manifest_tmp=""
  trap - EXIT INT TERM
  rmdir "$_lock_dir" 2>/dev/null || true
  eval "$_saved_opts"
  exit 1
}

# Install the 3-trap signal-cleanup pattern for the first-party prompt tmpfile.
# Mirror of the _manifest_tmp pattern in _append_manifest_entry: three separate
# traps so INT/TERM exit with their canonical codes (130 = 128+SIGINT,
# 143 = 128+SIGTERM) instead of being swallowed by a bare cleanup.
_install_fp_traps() {
  trap 'rm -f "$_fp_tmp" 2>/dev/null || true' EXIT
  trap 'rm -f "$_fp_tmp" 2>/dev/null || true; exit 130' INT
  trap 'rm -f "$_fp_tmp" 2>/dev/null || true; exit 143' TERM
}

# Cleanup the first-party prompt tmpfile: rm, clear the relay, disarm traps.
# Used by both success-path (after mv promotes the tmpfile) and error-path
# (after a named-failure exit-1 in the calling site). Safe when $_fp_tmp is
# empty (mktemp-failed branch) — rm -f "" is a no-op.
_cleanup_fp_tmp() {
  rm -f "$_fp_tmp" 2>/dev/null || true
  _fp_tmp=""
  trap - EXIT INT TERM
}

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
      # Portable mtime fetch:
      #   Try GNU `stat -c %Y` first (Linux/alpine CI), then BSD `stat -f %m` (macOS).
      #   NOTE: GNU `stat -f` means "report filesystem info" (NOT format-string);
      #   probing BSD-style `-f` first would succeed with wrong-semantic garbage on
      #   stdout (not stderr), poisoning $_mtime and breaking arithmetic below.
      # Validate the result is numeric; fall back to $_now if anything went wrong
      # (e.g. lock dir released between -d test and stat).
      local _mtime
      _mtime=$(stat -c %Y "$_lock_dir" 2>/dev/null || stat -f %m "$_lock_dir" 2>/dev/null || echo "$_now")
      case "$_mtime" in
        ''|*[!0-9]*) _mtime="$_now" ;;
      esac
      local _lock_age=$(( _now - _mtime ))
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
    _append_manifest_fail "mktemp failed for manifest tmp"
  fi
  # Mirror tmp into the script-level relay so the EXIT/INT/TERM traps can
  # clean it up if a signal fires before the mv-promotion completes.
  _manifest_tmp="$tmp"
  if [[ -f "$manifest" ]]; then
    if ! jq --argjson new "$entry" '. + [$new]' "$manifest" > "$tmp"; then
      _append_manifest_fail "jq append failed"
    fi
  else
    if ! jq -n --argjson new "$entry" '[$new]' > "$tmp"; then
      _append_manifest_fail "jq init failed"
    fi
  fi
  # Validate output is parseable JSON array before clobbering.
  if ! jq -e 'type == "array"' "$tmp" > /dev/null; then
    _append_manifest_fail "produced non-array output"
  fi
  if ! mv "$tmp" "$manifest"; then
    _append_manifest_fail "mv failed"
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
    --arg await_cmd "$REPO_ROOT/scripts/dispatch-companion.sh await $job_id" \
    --arg split_cmd "$REPO_ROOT/scripts/third-party-finding-splitter.sh --round-dir $OUTPUT_DIR --tag $REVIEWER_TAG" \
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

# _validate_agent_name_charset <agent_name> — guards the `<agent>` interpolation
# fed into the subagent author-marker GIT_AUTHOR_NAME wrap (G5). The valid
# agent-name charset is `[a-z0-9-]+`: lowercase letters, digits, and hyphen,
# with at least one character. Empty strings are rejected explicitly (the
# `^[a-z0-9-]+$` regex already excludes them, but the explicit `-z` test
# documents the intent — prevents the silent `GIT_AUTHOR_NAME=qrspi-` failure
# mode where the marker would carry no discriminator). Any character outside
# the charset (uppercase, underscore, whitespace, control bytes, path
# separators, etc.) halts dispatch with the `agent-name-charset-invalid:`
# named diagnostic and exits non-zero BEFORE any GIT_AUTHOR_NAME export and
# before any subprocess (including the dispatch-companion) is invoked, so a
# malformed agent-name value can never produce a silently-malformed subagent
# commit author or reach a child git command.
_validate_agent_name_charset() {
  local agent_name="${1:-}"
  if [[ -z "$agent_name" || ! "$agent_name" =~ ^[a-z0-9-]+$ ]]; then
    echo "agent-name-charset-invalid: agent name '${agent_name}' does not match the valid charset [a-z0-9-]+ (would produce a silently-malformed subagent author marker); refusing to dispatch" >&2
    exit 1
  fi
}

# Source guard: when QRSPI_SOURCE_ONLY=1, return after loading function
# definitions so that function-isolation tests can source this file and call
# detect_host / check_codex_available directly without triggering argument
# parsing or validation.
#
# `return 0` is only valid in a sourced context.  When the script is executed
# directly (`bash dispatch-agent.sh`) the failed `return` does not abort
# execution and would fall through into argument parsing.
# `return 0 2>/dev/null || exit 0` works in both modes: `return 0` succeeds
# when sourced; `exit 0` fires when executed directly.
if [[ "${QRSPI_SOURCE_ONLY:-}" == "1" ]]; then
  return 0 2>/dev/null || exit 0
fi

# ---------------------------------------------------------------------------
# Batched dispatch mode (CD-1 #3 universal entry point).
#
# When invoked with the batched flag surface (`--step` / `--agents`), this
# entry point resolves N reviewers in a single call: for each `tag=agent-file`
# pair it resolves the agent's tier -> vendor -> model, assembles the reviewer
# prompt into `<output-dir>/.dispatch/<tag>.prompt`, and — for first-party
# (host x vendor) routings — emits one spec line to stdout:
#
#   MODE=first_party TAG=<tag> SUBAGENT_TYPE=<agent-name> MODEL=<model> PROMPT_FILE=<abs-path>
#
# Each dispatch is recorded in `<output-dir>/.dispatch-manifest.json`. Third-
# party routings record a `mode=background` manifest entry (drained later by
# await-round.sh) and emit no spec line. The prompt body is NEVER echoed to
# stdout — only the small spec line.
#
# The single-reviewer flag surface (further below) is preserved unchanged for
# ad-hoc invocations; batched mode is detected before single-mode arg parsing.
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# Marker-injection / value-emission guards. These helpers are hoisted above
# the batch-mode dispatch block so both batch and single-mode prompt
# assembly can reject inputs that would split or forge structural lines.
#
# We reject any value or file that contains ANY of the structural wrapper
# markers (closing OR opening), because either side of a marker pair
# breaks the invariant. Embedded newline/carriage-return characters are
# rejected on every emitted scalar surface — even when the value passes
# every other validation, an unguarded \n in a substituted value
# synthesizes a forged Dispatch-parameters key/value pair.
# ---------------------------------------------------------------------------
FORBIDDEN_MARKERS=(
  "<<<AGENT-BODY-END>>>"
  "<<<UNTRUSTED-SCOPE-HINT-START"
  "<<<UNTRUSTED-SCOPE-HINT-END"
  "<<<UNTRUSTED-ARTIFACT-START"
  "<<<UNTRUSTED-ARTIFACT-END"
)

reject_if_contains_marker_file() {
  local label="$1"
  local path="$2"
  local marker
  for marker in "${FORBIDDEN_MARKERS[@]}"; do
    if grep -F -q -- "$marker" "$path" 2>/dev/null; then
      echo "error: ${label} contains the wrapper-private marker '${marker}' (path: $path). This would defeat the prompt's structural carve-outs; reject the input." >&2
      exit 1
    fi
  done
}

reject_if_value_unsafe_for_emission() {
  local label="$1"
  local value="$2"
  case "$value" in
    *$'\n'*|*$'\r'*)
      echo "error: ${label} contains an embedded newline/carriage-return; reject (would synthesize forged structural lines on emission)." >&2
      exit 1 ;;
  esac
  local marker
  for marker in "${FORBIDDEN_MARKERS[@]}"; do
    if [[ "$value" == *"$marker"* ]]; then
      echo "error: ${label} contains the wrapper-private marker '${marker}'. This would defeat the prompt's structural carve-outs; reject the input." >&2
      exit 1
    fi
  done
}

# Backward-compatible alias for the prior name (single-mode call sites).
reject_if_contains_marker_value() {
  reject_if_value_unsafe_for_emission "$@"
}

reject_if_path_unsafe_for_emission() {
  local label="$1"
  local path="$2"
  reject_if_value_unsafe_for_emission "${label} path" "$path"
}

_is_batch_mode=false
for _arg in "$@"; do
  case "$_arg" in
    --step|--agents) _is_batch_mode=true; break ;;
  esac
done

if [[ "$_is_batch_mode" == "true" ]]; then
  BATCH_STEP=""
  BATCH_ROUND=""
  BATCH_OUTPUT_DIR=""
  BATCH_ARTIFACT=""
  BATCH_AGENTS=""
  BATCH_TIER_OVERRIDE=""
  BATCH_TASK_BRANCH=""
  BATCH_IMPL_COMMIT=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --step)              require_value "--step" "$#";              BATCH_STEP="$2"; shift 2 ;;
      --round)             require_value "--round" "$#"
                           if [[ ! "$2" =~ ^[0-9]+$ ]]; then
                             echo "error: --round must be a non-negative integer (got: $2)" >&2
                             exit 1
                           fi
                           BATCH_ROUND="$2"; shift 2 ;;
      --output-dir)        require_value "--output-dir" "$#";        BATCH_OUTPUT_DIR="$2"; shift 2 ;;
      --artifact)          require_value "--artifact" "$#";          BATCH_ARTIFACT="$2"; shift 2 ;;
      --agents)            require_value "--agents" "$#";            BATCH_AGENTS="$2"; shift 2 ;;
      --tier-override)     require_value "--tier-override" "$#";     BATCH_TIER_OVERRIDE="$2"; shift 2 ;;
      --task-branch)       require_value "--task-branch" "$#";       BATCH_TASK_BRANCH="$2"; shift 2 ;;
      --implementer-commit) require_value "--implementer-commit" "$#"; BATCH_IMPL_COMMIT="$2"; shift 2 ;;
      *)
        echo "error: unrecognized flag in batched dispatch: $1" >&2
        exit 1 ;;
    esac
  done

  if [[ -z "$BATCH_STEP" ]];       then echo "error: --step required"        >&2; exit 1; fi
  if [[ -z "$BATCH_ROUND" ]];      then echo "error: --round required"       >&2; exit 1; fi
  if [[ -z "$BATCH_OUTPUT_DIR" ]]; then echo "error: --output-dir required"  >&2; exit 1; fi
  # Mirror single-mode's --output-dir discipline: allowlist-validate the path
  # (rejects \n/\r/marker bytes/non-grammar chars) BEFORE any use, then run
  # the emission guard so a newline-bearing value cannot forge sibling
  # Dispatch-parameter lines via the `printf 'round_subdir: %s\n'` site.
  _validate_output_dir "$BATCH_OUTPUT_DIR"
  reject_if_path_unsafe_for_emission "--output-dir" "$BATCH_OUTPUT_DIR"
  if [[ -z "$BATCH_AGENTS" ]];     then echo "error: --agents required"      >&2; exit 1; fi

  # Source the routing-resolution library for tier -> model + host x vendor
  # matrix lookups. QRSPI_SOURCE_ONLY keeps the source side-effect-free.
  _resolve_lib="$REPO_ROOT/scripts/_resolve-lib.sh"
  if [[ -r "$_resolve_lib" ]]; then
    # shellcheck disable=SC1090
    QRSPI_SOURCE_ONLY=1 . "$_resolve_lib" || true
  fi

  mkdir -p "$BATCH_OUTPUT_DIR/.dispatch" \
    || { echo "error: cannot create dispatch dir $BATCH_OUTPUT_DIR/.dispatch" >&2; exit 1; }

  # If the batch references a config.md (model_routing source), expose it to the
  # resolve-lib functions via CONFIG_MD. Look beside the output-dir's artifact
  # tree only when not already set by the caller.
  _batch_host="$(detect_host)"

  # strip_frontmatter_batch <file> — drop the leading YAML frontmatter block.
  strip_frontmatter_batch() {
    awk '/^---$/ && n<2 {n++; next} n>=2 {print}' "$1"
  }

  # Resolve the absolute artifact path (relative paths resolve under REPO_ROOT).
  BATCH_ARTIFACT_ABS=""
  if [[ -n "$BATCH_ARTIFACT" ]]; then
    if [[ "$BATCH_ARTIFACT" == /* ]]; then
      BATCH_ARTIFACT_ABS="$BATCH_ARTIFACT"
    else
      BATCH_ARTIFACT_ABS="$REPO_ROOT/$BATCH_ARTIFACT"
    fi
  fi
  # Apply repo-boundary guard AFTER existence check and BEFORE any cat/read.
  # Two-step pattern mirrors single-mode: existence fails with a clear diagnostic,
  # then the boundary check rejects traversal before any prompt emission.
  if [[ -n "$BATCH_ARTIFACT_ABS" ]]; then
    assert_file_exists "--artifact" "$BATCH_ARTIFACT_ABS"
    assert_path_under_repo_root "--artifact" "$BATCH_ARTIFACT_ABS"
    # The raw --artifact value is later substituted into the prompt
    # skeleton via `<<<UNTRUSTED-ARTIFACT-START id=%s>>>`; protect against
    # newline/marker injection symmetrically with the single-mode path
    # surface.
    reject_if_path_unsafe_for_emission "--artifact" "$BATCH_ARTIFACT"
    reject_if_contains_marker_file "--artifact body" "$BATCH_ARTIFACT_ABS"
  fi

  REVIEWER_PROTOCOL_ABS="$REPO_ROOT/skills/reviewer-protocol/SKILL.md"
  EMISSION_OVERRIDE_ABS="$REPO_ROOT/skills/reviewer-protocol/stdout-fallback-emission.md"

  # Per-vendor fallback model — used only when config.md model_routing cannot be
  # consulted (e.g., ad-hoc invocation without a run config). A loud warning is
  # emitted so the operator knows resolution degraded to a default.
  _fallback_model_for_vendor() {
    case "$1" in
      codex) printf 'gpt-5.3-codex\n' ;;
      *)     printf 'claude-sonnet-4.6\n' ;;
    esac
  }

  # Parse the comma-separated --agents list into tag=agent pairs (bash 3.2: no
  # mapfile). Each pair is `tag=<agent-file-path-or-name>`.
  _saved_ifs="$IFS"
  IFS=','
  set -f
  # shellcheck disable=SC2086
  set -- $BATCH_AGENTS
  set +f
  IFS="$_saved_ifs"

  _emitted_any=false
  for _pair in "$@"; do
    [[ -z "$_pair" ]] && continue
    if [[ "$_pair" != *=* ]]; then
      echo "error: --agents entry must be tag=agent (got: $_pair)" >&2
      exit 1
    fi
    _tag="${_pair%%=*}"
    _agent_ref="${_pair#*=}"
    if [[ -z "$_tag" || -z "$_agent_ref" ]]; then
      echo "error: --agents entry must have non-empty tag and agent (got: $_pair)" >&2
      exit 1
    fi
    # Tag allowlist: mirrors single-mode --reviewer-tag grammar. Prevents crafted
    # tags from redirecting the assembled prompt to attacker-controlled paths via
    # the prompt-file path construction below.
    if [[ ! "$_tag" =~ ^[a-z][a-z0-9_-]*$ ]]; then
      echo "error: --agents tag must match [a-z][a-z0-9_-]* (got: $_tag)" >&2
      exit 1
    fi

    # Resolve agent file path: an absolute path or a repo-relative path is used
    # verbatim; a bare agent name resolves to agents/<name>.md.
    if [[ "$_agent_ref" == /* ]]; then
      _agent_file="$_agent_ref"
    elif [[ -f "$REPO_ROOT/$_agent_ref" ]]; then
      _agent_file="$REPO_ROOT/$_agent_ref"
    else
      _agent_file="$REPO_ROOT/agents/${_agent_ref}.md"
    fi
    if [[ ! -f "$_agent_file" ]]; then
      echo "error: agent file not found for tag '$_tag': $_agent_file" >&2
      exit 1
    fi
    # Apply repo-boundary guard AFTER existence check and BEFORE any
    # strip_frontmatter_batch/resolve_tier read (spec line 19).
    assert_path_under_repo_root "--agents" "$_agent_file"
    _agent_name="$(basename "${_agent_file%.md}")"

    # G5 subagent author-marker env wrap: validate the agent-name charset
    # BEFORE composing GIT_AUTHOR_NAME so an out-of-charset value cannot
    # produce a silently-malformed marker on dispatched subagent commits.
    # The wrap is exported into the per-iteration environment so every
    # subprocess this loop launches (the dispatch-companion below, plus any
    # child git command in the subagent's session) inherits the marker.
    _validate_agent_name_charset "$_agent_name"
    export GIT_AUTHOR_NAME="qrspi-${_agent_name}"

    # Vendor is encoded in the tag suffix (e.g., quality-claude -> claude,
    # spec-codex -> codex). Default to claude when no recognised suffix.
    case "$_tag" in
      *-codex) _vendor="codex" ;;
      *-claude) _vendor="claude" ;;
      *) _vendor="claude" ;;
    esac

    # Resolve tier (per-tag override allowed) -> model.
    _tier_override_for_tag=""
    if [[ -n "$BATCH_TIER_OVERRIDE" ]]; then
      # tier-override is a comma-list of tag=tier; pick this tag's entry if any.
      _to_saved_ifs="$IFS"; IFS=','
      for _to in $BATCH_TIER_OVERRIDE; do
        if [[ "$_to" == "$_tag="* ]]; then
          _tier_override_for_tag="${_to#*=}"
        fi
      done
      IFS="$_to_saved_ifs"
    fi

    _tier="medium"
    if declare -f resolve_tier >/dev/null 2>&1; then
      _tier="$(resolve_tier "$_agent_file" "$_tier_override_for_tag" 2>/dev/null || echo medium)"
      [[ -z "$_tier" ]] && _tier="medium"
    fi

    _model=""
    if declare -f resolve_model >/dev/null 2>&1 && [[ -n "${CONFIG_MD:-}" ]]; then
      _model="$(resolve_model "$_tier" 2>/dev/null | sed -E 's/.*model:[[:space:]]*//; s/[[:space:]]*}[[:space:]]*$//' || true)"
    fi
    if [[ -z "$_model" ]]; then
      _model="$(_fallback_model_for_vendor "$_vendor")"
      echo "[routing] WARN: model_routing unavailable for tier '$_tier'; tag '$_tag' falling back to default model '$_model'" >&2
    fi

    # Host x vendor matrix: first-party or third-party.
    _path="first-party"
    if declare -f lookup_host_vendor_path >/dev/null 2>&1; then
      _path="$(lookup_host_vendor_path "$_batch_host" "$_vendor")"
    fi

    # Assemble the reviewer prompt into <output-dir>/.dispatch/<tag>.prompt.
    _prompt_file="$BATCH_OUTPUT_DIR/.dispatch/${_tag}.prompt"
    {
      [[ -f "$REVIEWER_PROTOCOL_ABS" ]] && strip_frontmatter_batch "$REVIEWER_PROTOCOL_ABS"
      printf '\n\n---\n\n'
      strip_frontmatter_batch "$_agent_file"
      printf '\n\n---\n\n'
      [[ -f "$EMISSION_OVERRIDE_ABS" ]] && cat "$EMISSION_OVERRIDE_ABS"
      printf '\n\n<<<AGENT-BODY-END>>>\n'
      printf '\n## Dispatch parameters\n\n'
      if [[ -n "$BATCH_ARTIFACT_ABS" ]]; then
        printf 'artifact_body:\n'
        printf '<<<UNTRUSTED-ARTIFACT-START id=%s>>>\n' "$BATCH_ARTIFACT"
        cat "$BATCH_ARTIFACT_ABS"
        printf '\n<<<UNTRUSTED-ARTIFACT-END id=%s>>>\n' "$BATCH_ARTIFACT"
      fi
      printf 'round_subdir: %s\n' "$BATCH_OUTPUT_DIR"
      printf 'round: %s\n' "$BATCH_ROUND"
      printf 'reviewer_tag: %s\n' "$_tag"
    } > "$_prompt_file" \
      || { echo "error: failed to assemble prompt for tag '$_tag'" >&2; exit 1; }

    # Set the globals the manifest helpers read, then record the dispatch.
    REVIEWER_TAG="$_tag"
    AGENT_FILE="$_agent_file"
    MODEL="$_model"
    OUTPUT_DIR="$BATCH_OUTPUT_DIR"

    if [[ "$_path" == "first-party" ]]; then
      # Emit the orchestrator-facing spec line (prompt body stays on disk).
      printf 'MODE=first_party TAG=%s SUBAGENT_TYPE=%s MODEL=%s PROMPT_FILE=%s\n' \
        "$_tag" "$_agent_name" "$_model" "$_prompt_file"
      emit_first_party_manifest_entry "$_prompt_file" "$_vendor" "$_model"
      _emitted_any=true
    else
      # Third-party routing: launch the dispatch-companion in background and
      # capture the JOB_ID it prints on stdout, then record a `pending`
      # manifest entry whose `await_cmd` carries that real job-id. Without
      # this real launch, the manifest's await_cmd would carry an empty
      # job-id and await-round.sh could never drain the entry.
      _launch_out=""
      _launch_rc=0
      _launch_out=$("$REPO_ROOT/scripts/dispatch-companion.sh" \
        --vendor "$_vendor" \
        --model "$_model" \
        --prompt-file "$_prompt_file" \
        --round-dir "$BATCH_OUTPUT_DIR" \
        --tag "$_tag" 2>&1) || _launch_rc=$?
      if [[ "$_launch_rc" -ne 0 ]]; then
        echo "[dispatch-agent] WARN: dispatch-companion launch failed for tag '$_tag' (rc=$_launch_rc): $_launch_out" >&2
        emit_dispatch_manifest_entry "" "failed"
        continue
      fi
      _job_id=$(printf '%s\n' "$_launch_out" | sed -n 's/^JOB_ID=//p' | head -1)
      if [[ -z "$_job_id" ]]; then
        echo "[dispatch-agent] WARN: dispatch-companion launch produced no JOB_ID line for tag '$_tag'" >&2
        emit_dispatch_manifest_entry "" "failed"
        continue
      fi
      # Inline grammar check (mirrors _validate_job_id allowlist) so a
      # broker-supplied job-id outside the safe-token grammar is logged and
      # recorded as a failed manifest entry instead of hard-exiting the
      # batch loop. A bare _validate_job_id call here would `exit 1` after
      # the upstream broker job had already been launched, orphaning that
      # running job (no manifest entry → await-round.sh cannot drain it)
      # and aborting any remaining tags in the batch.
      if ! [[ "$_job_id" =~ ^[A-Za-z0-9_:@.-]+$ ]]; then
        echo "[dispatch-agent] WARN: dispatch-companion returned invalid JOB_ID for tag '$_tag' (orphaned broker job, no manifest entry): '$_job_id'" >&2
        emit_dispatch_manifest_entry "" "failed"
        continue
      fi
      emit_dispatch_manifest_entry "$_job_id" "pending"
    fi
  done

  # Loud one-line audit signal across the whole batch (host-relative routing).
  echo "[dispatch-agent] step=$BATCH_STEP round=$BATCH_ROUND host=$_batch_host agents dispatched (manifest: $BATCH_OUTPUT_DIR/.dispatch-manifest.json)" >&2
  exit 0
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --agent-file)     require_value "--agent-file"   "$#"; AGENT_FILE="$2"; shift 2 ;;
    --reviewer-tag)
      require_value "--reviewer-tag" "$#"
      # Allowlist validation: --reviewer-tag is concatenated
      # into the dispatch-manifest JSON entry. Restricting it to a safe
      # token grammar ([a-z][a-z0-9_-]*) is defense-in-depth alongside the
      # jq-based JSON construction below — it ensures crafted tags
      # carrying JSON-structural characters cannot reach the manifest
      # writer at all. The grammar mirrors the existing reviewer-tag
      # values used in this codebase (e.g. <reviewer>-<vendor> tokens).
      if [[ ! "$2" =~ ^[a-z][a-z0-9_-]*$ ]]; then
        echo "error: --reviewer-tag must match [a-z][a-z0-9_-]* (got: $2)" >&2
        exit 1
      fi
      REVIEWER_TAG="$2"; shift 2 ;;
    --output-dir)
      require_value "--output-dir" "$#"
      _validate_output_dir "$2"
      OUTPUT_DIR="$2"; shift 2 ;;
    --round)          require_value "--round"        "$#"
                      if [[ ! "$2" =~ ^[0-9]+$ ]]; then
                        echo "error: --round must be a non-negative integer (got: $2)" >&2
                        exit 1
                      fi
                      ROUND="$2"; shift 2 ;;
    --model)
      require_value "--model" "$#"
      # Allowlist validation: --model is concatenated into
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

AGENT_FILE_ABS="$(resolve_path "$AGENT_FILE")"
assert_file_exists "agent-file" "$AGENT_FILE_ABS"
assert_path_under_repo_root "agent-file" "$AGENT_FILE_ABS"

# G5 subagent author-marker env wrap (single-reviewer / low-level path).
# Derive the agent-name from the agent-file basename (mirrors the manifest
# helpers' `basename "${AGENT_FILE%.md}"` formula), validate it against the
# agent-name charset, and export GIT_AUTHOR_NAME=qrspi-<agent> so every
# subprocess this script launches downstream (the dispatch-companion shell
# pipeline, plus the first-party copilot-cli prompt-file path) inherits the
# subagent author marker. Validating here — after existence + repo-boundary
# checks but before any compose_prompt or dispatcher invocation — guarantees
# an invalid agent-name halts dispatch with the `agent-name-charset-invalid:`
# named diagnostic before any subagent git command can run. The wrap is set
# on EVERY dispatched git command in the subagent's session via env
# inheritance, not just the first one.
_AGENT_NAME_FOR_MARKER="$(basename "${AGENT_FILE_ABS%.md}")"
_validate_agent_name_charset "$_AGENT_NAME_FOR_MARKER"
export GIT_AUTHOR_NAME="qrspi-${_AGENT_NAME_FOR_MARKER}"

REVIEWER_PROTOCOL_ABS="$REPO_ROOT/skills/reviewer-protocol/SKILL.md"
assert_file_exists "reviewer-protocol/SKILL.md" "$REVIEWER_PROTOCOL_ABS"

EMISSION_OVERRIDE_ABS="$REPO_ROOT/skills/reviewer-protocol/stdout-fallback-emission.md"
assert_file_exists "stdout-fallback-emission.md" "$EMISSION_OVERRIDE_ABS"

# Parse the agent's `skills:` frontmatter field to discover additional
# shared skills the agent depends on (load chain unchanged from earlier shim refactor).
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
  assert_path_under_repo_root "skill[$skill_name]" "$skill_path"
  ADDITIONAL_SKILL_PATHS+=("$skill_path")
done <<< "$SKILL_NAMES_OUTPUT"

PRIMARY_ABS=()
for sc in "${PRIMARY_PATHS[@]}"; do
  abs="$(resolve_path "$sc")"
  assert_file_exists "$PRIMARY_FIELD" "$abs"
  assert_path_under_repo_root "$PRIMARY_FIELD" "$abs"
  PRIMARY_ABS+=("$abs")
done

TASK_DEF_ABS=""
if [[ -n "$TASK_DEF" ]]; then
  TASK_DEF_ABS="$(resolve_path "$TASK_DEF")"
  assert_file_exists "task-def" "$TASK_DEF_ABS"
  assert_path_under_repo_root "task-def" "$TASK_DEF_ABS"
fi

COMPANION_ABS=()
for i in "${!COMPANION_PATHS[@]}"; do
  cpath="${COMPANION_PATHS[$i]}"
  cname="${COMPANION_NAMES[$i]}"
  abs="$(resolve_path "$cpath")"
  assert_file_exists "companion[$cname]" "$abs"
  assert_path_under_repo_root "companion[$cname]" "$abs"
  COMPANION_ABS+=("$abs")
done

if [[ -n "$DIFF_FILE" ]]; then
  DIFF_FILE="$(resolve_path "$DIFF_FILE")"
  if [[ ! -f "$DIFF_FILE" ]]; then
    echo "error: diff-file not found: $DIFF_FILE" >&2
    exit 1
  fi
  assert_path_under_repo_root "diff-file" "$DIFF_FILE"
fi

# ---------------------------------------------------------------------------
# Marker-injection guards on per-flag inputs. The helpers (FORBIDDEN_MARKERS,
# reject_if_contains_marker_file, reject_if_value_unsafe_for_emission,
# reject_if_path_unsafe_for_emission) are defined above the batch-mode
# dispatch block so both batch and single-mode paths can call them; this
# section only wires them onto the single-mode arg surface.
# ---------------------------------------------------------------------------
for i in "${!PRIMARY_PATHS[@]}"; do
  reject_if_path_unsafe_for_emission "${PRIMARY_FIELD}" "${PRIMARY_PATHS[$i]}"
done
if [[ -n "$TASK_DEF" ]]; then
  reject_if_path_unsafe_for_emission "task-def" "$TASK_DEF"
fi
for i in "${!COMPANION_PATHS[@]}"; do
  reject_if_path_unsafe_for_emission "companion[${COMPANION_NAMES[$i]}]" "${COMPANION_PATHS[$i]}"
done
if [[ -n "$DIFF_FILE" ]]; then
  reject_if_path_unsafe_for_emission "diff-file" "$DIFF_FILE"
fi

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
# Prompt-assembly helpers (unchanged from earlier shim refactor)
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
# This shim does NOT pass a transport flag — transport selection is
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
# to dispatch-companion.sh.  Capture the dispatcher's stdout to extract a
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
  # Install signal-cleanup trap BEFORE mktemp so any signal between mktemp
  # success and the if-check fires with relay still "" (rm -f "" is a no-op).
  _install_fp_traps
  if ! _fp_tmp="$(mktemp "${_fp_prompt_file}.tmp.XXXXXX")"; then
    _cleanup_fp_tmp
    echo "error: mktemp failed for first-party prompt tmpfile" >&2
    exit 1
  fi
  if ! compose_prompt > "$_fp_tmp"; then
    _cleanup_fp_tmp
    echo "error: compose_prompt failed for first-party dispatch" >&2
    exit 1
  fi
  if ! mv -f "$_fp_tmp" "$_fp_prompt_file"; then
    _cleanup_fp_tmp
    echo "error: mv -f failed promoting first-party prompt tmpfile" >&2
    exit 1
  fi
  # mv succeeded: tmpfile has been promoted; clear relay and disarm trap before
  # calling emit_first_party_manifest_entry (which installs its own traps).
  _cleanup_fp_tmp
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
DISPATCHER="$REPO_ROOT/scripts/dispatch-companion.sh"
if [[ ! -x "$DISPATCHER" && ! -r "$DISPATCHER" ]]; then
  echo "error: dispatch-companion.sh not found at $DISPATCHER" >&2
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
