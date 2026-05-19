#!/usr/bin/env bash
# g4-cache-probe.sh — G4 Mechanism A cache-probe (Plan-time measurement).
#
# Dispatches three reviewer prompts that share a byte-identical system prefix
# and a varying per-call tail, captures the Anthropic cache-hit usage metadata
# (`cache_creation_input_tokens`, `cache_read_input_tokens`) from each response,
# and writes a one-page spike report that records the Path A vs Path B decision
# for the Mechanism-A-only sub-decision (see design.md G4 — does Claude Code's
# Agent({}) dispatch path already cache stable prefixes automatically?).
#
# The script is the producer of the deliverable at
# `docs/qrspi/2026-05-17-v07-release/spikes/g4-cache-probe.md` — that path is
# the spike-deliverable location declared in structure.md Slice 7.
#
# Usage:
#   scripts/g4-cache-probe.sh --report-out <path>
#
# Exit codes:
#   0   report written + decision recorded
#   1   validation failure, dispatch failure, or report-write failure
#
# Bash 3.2-compatible (macOS system /bin/bash).

set -u

# ---------------------------------------------------------------------------
# Argument parsing.
# ---------------------------------------------------------------------------
REPORT_OUT=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --report-out)
      [ "$#" -ge 2 ] || { echo "g4-cache-probe: --report-out requires a value" >&2; exit 1; }
      REPORT_OUT="$2"
      shift 2
      ;;
    *)
      echo "g4-cache-probe: unrecognised argument: $1" >&2
      exit 1
      ;;
  esac
done

if [ -z "$REPORT_OUT" ]; then
  echo "g4-cache-probe: validation: --report-out is required" >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Resolve --report-out to its canonical absolute path via realpath (or
# parent-resolution when the file does not yet exist). The path-validation
# check below operates on the resolved path, not the raw argument — a naive
# string-prefix check would miss traversal attempts like
# `docs/qrspi/../../../etc/shadow`.
# ---------------------------------------------------------------------------
resolve_canonical_path() {
  local p="$1"
  local resolved
  if resolved=$(/usr/bin/env python3 -c 'import os, sys; print(os.path.realpath(sys.argv[1]))' "$p" 2>/dev/null); then
    [ -n "$resolved" ] && { printf '%s\n' "$resolved"; return 0; }
  fi
  # Fallback for environments without python3: resolve parent + basename.
  local parent base parent_abs
  parent=$(dirname -- "$p")
  base=$(basename -- "$p")
  if [ ! -d "$parent" ]; then
    return 1
  fi
  if ! parent_abs=$(cd "$parent" 2>/dev/null && pwd -P); then
    return 1
  fi
  printf '%s/%s\n' "$parent_abs" "$base"
}

RESOLVED_REPORT_OUT=""
if ! RESOLVED_REPORT_OUT=$(resolve_canonical_path "$REPORT_OUT"); then
  echo "g4-cache-probe: path-validation: cannot resolve --report-out '$REPORT_OUT' (parent directory does not exist)" >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Path-validation: resolved path must lie under docs/qrspi/. The check is
# applied to the resolved path so traversal attempts (raw arg string-prefix
# `docs/qrspi/` that resolves outside) are rejected.
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd -P)"
ALLOWED_PREFIX="$REPO_ROOT/docs/qrspi/"

case "$RESOLVED_REPORT_OUT" in
  "$ALLOWED_PREFIX"*) ;;
  *)
    echo "g4-cache-probe: path-validation: resolved --report-out '$RESOLVED_REPORT_OUT' lies outside the declared spike-deliverable location under '$ALLOWED_PREFIX'" >&2
    exit 1
    ;;
esac

# ---------------------------------------------------------------------------
# Lock-file discipline. Remove any prior sentinel/lock at <report-out-dir>/
# g4-cache-probe.lock so a stale lock from a failed prior run does not
# survive into the new invocation. On successful completion we recreate the
# lock atomically containing the same run_id as the report. Mid-run failure
# leaves no lock — T36 downstream consumers detect stale reports by absence
# of a fresh lock or a run_id mismatch between report and lock.
# ---------------------------------------------------------------------------
REPORT_DIR="$(dirname "$RESOLVED_REPORT_OUT")"
LOCK_PATH="$REPORT_DIR/g4-cache-probe.lock"

# Ensure the report directory exists; fail loud on mkdir failure (e.g.,
# read-only filesystem, permission denied).
if ! mkdir -p "$REPORT_DIR" 2>/dev/null; then
  echo "g4-cache-probe: report-write: cannot create report directory '$REPORT_DIR' (permission denied or read-only filesystem)" >&2
  exit 1
fi

rm -f "$LOCK_PATH" 2>/dev/null || true

# Generate a unique run identifier for this invocation. Used in both the
# report header and the post-success lock file.
RUN_ID="$(date -u "+%Y-%m-%dT%H:%M:%SZ")-$$"

# ---------------------------------------------------------------------------
# Stable system-prompt prefix. The byte-identity assertion in T36's pinned
# fixture compares the assembled prefix bytes across the three dispatches —
# the prefix is concretely defined as the bytes from the start of the
# assembled system-message body through the end of the verbatim
# `skills/reviewer-protocol/SKILL.md` content embedded here. The per-dispatch
# tail begins immediately after the stable prefix.
# ---------------------------------------------------------------------------
REVIEWER_PROTOCOL_PATH="$REPO_ROOT/skills/reviewer-protocol/SKILL.md"
if [ ! -f "$REVIEWER_PROTOCOL_PATH" ]; then
  echo "g4-cache-probe: missing-input: reviewer-protocol body not found at $REVIEWER_PROTOCOL_PATH" >&2
  exit 1
fi

build_stable_prefix() {
  # The verbatim body of reviewer-protocol/SKILL.md IS the stable prefix.
  cat "$REVIEWER_PROTOCOL_PATH"
}

build_per_call_tail() {
  # $1 = call index (1, 2, 3). The tail differs by index so each dispatch is
  # a distinct prompt — only the trailing per-call section varies.
  printf '\n\n## Per-Dispatch Reviewer Task (call %s)\n\nProbe call %s — emit `NO_FINDINGS` and return.\n' "$1" "$1"
}

# ---------------------------------------------------------------------------
# Dispatch. The probe issues three dispatches via the universal dispatcher
# (T03) using the `anthropic` provider entry from config.md. Each dispatch
# captures `cache_creation_input_tokens` and `cache_read_input_tokens` from
# the response usage metadata.
#
# In the autonomous-pipeline harness, the dispatcher is invoked end-to-end;
# the operator runs this script against the live Anthropic API to populate
# the report's measured fields. The script itself fails loud on any
# dispatch failure rather than writing a partial report.
# ---------------------------------------------------------------------------
DISPATCHER="$REPO_ROOT/scripts/run-third-party-llm.sh"
if [ ! -f "$DISPATCHER" ]; then
  echo "g4-cache-probe: missing-input: universal dispatcher not found at $DISPATCHER" >&2
  exit 1
fi

# Probe provider entry — operator MUST add an `anthropic-probe` provider entry
# to <artifact-dir>/config.md with transport_type that surfaces the cache
# metadata fields. The artifact-dir is derived from the resolved report path:
# the report's grandparent is the run's artifact directory (since reports
# live at <artifact-dir>/spikes/g4-cache-probe.md per structure.md).
ARTIFACT_DIR="$(dirname "$REPORT_DIR")"

# Capture three responses. Each dispatch writes its result to a tmp file;
# usage metadata is extracted from the response body by the dispatcher's
# transport adapter when present. Any non-zero dispatch exit causes the
# probe to fail loud without writing a partial report.
declare_dispatch_outputs() {
  CACHE_CREATION_1=""; CACHE_READ_1=""
  CACHE_CREATION_2=""; CACHE_READ_2=""
  CACHE_CREATION_3=""; CACHE_READ_3=""
}
declare_dispatch_outputs

# Stable prefix is built once and reused — the byte-identity invariant is
# preserved by reusing the same captured string across all three dispatches.
STABLE_PREFIX="$(build_stable_prefix)"

run_one_dispatch() {
  # $1 = call index; on success, prints two tab-separated values:
  #   <cache_creation_input_tokens>\t<cache_read_input_tokens>
  # On dispatch failure, returns non-zero.
  local idx="$1"
  local prompt_file response_file
  prompt_file="$(mktemp -t g4-cache-probe-prompt.XXXXXX)" || return 1
  response_file="$(mktemp -t g4-cache-probe-resp.XXXXXX)" || { rm -f "$prompt_file"; return 1; }

  {
    printf '%s' "$STABLE_PREFIX"
    build_per_call_tail "$idx"
  } > "$prompt_file"

  # Dispatch via the universal dispatcher. The transport's response-handling
  # path is responsible for surfacing cache metadata; the probe reads the
  # metadata from a sidecar JSON file the dispatcher writes alongside the
  # response when the transport exposes it. The sidecar path convention is
  # `<output-file>.usage.json` per the dispatcher's usage-metadata contract.
  local dispatch_rc=0
  bash "$DISPATCHER" \
    --artifact-dir "$ARTIFACT_DIR" \
    --provider anthropic-probe \
    --model claude-sonnet-4-5-20250929 \
    --output-file "$response_file" \
    < "$prompt_file" \
    || dispatch_rc=$?

  rm -f "$prompt_file"

  if [ "$dispatch_rc" -ne 0 ]; then
    rm -f "$response_file"
    return "$dispatch_rc"
  fi

  # Extract cache metadata from the sidecar. When the sidecar is absent
  # (transport did not surface cache fields at all), emit a literal `none`
  # sentinel so the report can distinguish "no cache metadata exposed" from
  # "metadata exposed but zero hits".
  local usage_sidecar="${response_file}.usage.json"
  local cc cr
  if [ -f "$usage_sidecar" ]; then
    cc=$(node -e 'const fs=require("fs");try{const j=JSON.parse(fs.readFileSync(process.argv[1],"utf8"));process.stdout.write(String(j.cache_creation_input_tokens ?? "none"));}catch(e){process.stdout.write("none");}' "$usage_sidecar" 2>/dev/null)
    cr=$(node -e 'const fs=require("fs");try{const j=JSON.parse(fs.readFileSync(process.argv[1],"utf8"));process.stdout.write(String(j.cache_read_input_tokens ?? "none"));}catch(e){process.stdout.write("none");}' "$usage_sidecar" 2>/dev/null)
  else
    cc="none"
    cr="none"
  fi

  rm -f "$response_file" "$usage_sidecar"
  printf '%s\t%s\n' "$cc" "$cr"
  return 0
}

run_dispatch_or_abort() {
  local idx="$1"
  local out rc=0
  out=$(run_one_dispatch "$idx") || rc=$?
  if [ "$rc" -ne 0 ]; then
    echo "g4-cache-probe: dispatch-failure: probe call $idx failed (exit $rc); no partial report written" >&2
    exit 1
  fi
  printf '%s' "$out"
}

# Execute three dispatches in strict sequence so the second/third observe
# whatever cache state the first established.
DISPATCH_1="$(run_dispatch_or_abort 1)"
CACHE_CREATION_1="${DISPATCH_1%%	*}"
CACHE_READ_1="${DISPATCH_1##*	}"

DISPATCH_2="$(run_dispatch_or_abort 2)"
CACHE_CREATION_2="${DISPATCH_2%%	*}"
CACHE_READ_2="${DISPATCH_2##*	}"

DISPATCH_3="$(run_dispatch_or_abort 3)"
CACHE_CREATION_3="${DISPATCH_3%%	*}"
CACHE_READ_3="${DISPATCH_3##*	}"

# ---------------------------------------------------------------------------
# Decision derivation. The decision branch is:
#   - "metadata not exposed at all": all six cache fields are the `none` sentinel.
#   - "metadata exposed but zero hits": fields are numeric; cache_read on
#     calls 2 and 3 both == 0.
#   - "Path A (auto-cache active)": cache_read on calls 2 OR 3 > 0.
# Path B (marker insertion required) is the consequence when "metadata
# exposed but zero hits" is observed AND a follow-up cache_control-marker
# probe confirms hits then materialize.
# ---------------------------------------------------------------------------
metadata_exposed="true"
case "$CACHE_CREATION_1$CACHE_READ_1$CACHE_CREATION_2$CACHE_READ_2$CACHE_CREATION_3$CACHE_READ_3" in
  "nonenonenonenonenonenone") metadata_exposed="false" ;;
esac

DECISION=""
if [ "$metadata_exposed" = "false" ]; then
  DECISION="Metadata not exposed — Agent({}) dispatch responses do not surface Anthropic cache-hit usage fields. Path B is REQUIRED: Mechanism A scope expands to include cache_control marker insertion at the Anthropic SDK boundary, AND a follow-up measurement task must verify the markers produce surfaced hits."
elif [ "$CACHE_READ_2" = "0" ] && [ "$CACHE_READ_3" = "0" ]; then
  DECISION="Metadata exposed but zero hits — Agent({}) dispatch surfaces the cache fields but does NOT cache stable prefixes automatically. Path B selected: Mechanism A scope expands to include cache_control marker insertion at the Anthropic SDK boundary."
else
  DECISION="Path A selected — Agent({}) dispatch path already caches stable prefixes automatically. Mechanism A scope is instrument + measure only; cache_control marker insertion is NOT required."
fi

# ---------------------------------------------------------------------------
# Write the report. The write is atomic: write to a tmp file first, then
# rename. If the rename fails (read-only filesystem, permission denied), the
# script exits 1 without leaving a partial report at the target path.
# ---------------------------------------------------------------------------
TMP_REPORT="$(mktemp -t g4-cache-probe-report.XXXXXX)" || {
  echo "g4-cache-probe: report-write: mktemp failed for report scratch file" >&2
  exit 1
}

cat > "$TMP_REPORT" <<REPORT_EOF
---
run_id: $RUN_ID
artifact: g4-cache-probe
generated_by: scripts/g4-cache-probe.sh
---

# G4 Mechanism A Cache-Probe Report

## Run

- run_id: $RUN_ID
- invocation_timestamp: $RUN_ID

## Measurement: Cache Metadata Exposure

Does the Claude Code Agent({}) dispatch response surface Anthropic cache-hit
metadata fields (\`cache_creation_input_tokens\`, \`cache_read_input_tokens\`)?

- metadata_exposed: $metadata_exposed

## Measurement: Captured Cache-Hit Values

Each row is one of the three probe dispatches. All three dispatches share a
byte-identical system-prompt prefix (the verbatim body of
\`skills/reviewer-protocol/SKILL.md\`); only the per-call tail varies.

| call | cache_creation_input_tokens | cache_read_input_tokens |
| ---- | --------------------------- | ----------------------- |
| 1    | $CACHE_CREATION_1           | $CACHE_READ_1           |
| 2    | $CACHE_CREATION_2           | $CACHE_READ_2           |
| 3    | $CACHE_CREATION_3           | $CACHE_READ_3           |

The \`none\` sentinel means the response payload did not include the field at
all (distinct from a numeric \`0\`, which means the field was present but no
cache hit occurred).

## Decision

Pending — operator runs scripts/g4-cache-probe.sh against live Anthropic API before this decision lands.

Once the live run completes, the Decision line above is replaced verbatim by
the derived decision below. The derivation rule (and the three possible
branches: "metadata not exposed", "metadata exposed but zero hits", "Path A
auto-cache active") is the rule the script applies after capturing the three
dispatches.

Derived (from the captured values above, applied at write-time):

$DECISION

## Consumers

- T36 \`test-cache-hit-rate.bats\` consumes this report's Decision section to
  select its Path-A vs Path-B fixture set (the Path-conditional fixture pin).
- Any follow-up \`cache_control\` marker-insertion task is gated by the
  Decision section above; T43 (conditional, Wave 9) is skipped when Path A
  is selected.
REPORT_EOF

# Atomic move to the final report path; fail loud on write failure.
if ! mv "$TMP_REPORT" "$RESOLVED_REPORT_OUT" 2>/dev/null; then
  rm -f "$TMP_REPORT"
  echo "g4-cache-probe: report-write: cannot write report to '$RESOLVED_REPORT_OUT' (permission denied, read-only filesystem, or parent missing)" >&2
  exit 1
fi

# Create the post-success lock file carrying the same run_id. The lock is
# the freshness signal T36 reads to detect a stale prior-run report.
TMP_LOCK="$(mktemp -t g4-cache-probe-lock.XXXXXX)" || {
  echo "g4-cache-probe: report-write: mktemp failed for lock scratch file" >&2
  exit 1
}
printf 'run_id: %s\n' "$RUN_ID" > "$TMP_LOCK"
if ! mv "$TMP_LOCK" "$LOCK_PATH" 2>/dev/null; then
  rm -f "$TMP_LOCK"
  echo "g4-cache-probe: report-write: cannot write lock file to '$LOCK_PATH'" >&2
  exit 1
fi

exit 0
