#!/usr/bin/env bash
# second-reviewer-available.sh — host-aware second-reviewer availability probe.
#
# Detects the active host (via _host-detect.sh), looks up the host's default
# second-reviewer vendor (via _resolve-lib.sh's host x vendor matrix), and exits
# 0 when that vendor is potentially reachable on this host. An optional
# `--vendor <name>` flag overrides the default lookup for operator/diagnostic
# runs.
#
# Usage:
#   second-reviewer-available.sh [--vendor <name>]
#
# Exit 0: the requested/default second-reviewer vendor is potentially available
#         for the detected host.
# Exit 1: the detected host names no default second-reviewer vendor, the vendor
#         is absent from the host x vendor matrix, or the vendor is unreachable.
# Exit 2: invalid invocation (unknown flag, missing flag value, or positional
#         argument). Distinct exit code so callers can distinguish a usage
#         error from a substantive unavailable verdict.
#
# Stdout: on success, the resolved vendor id (diagnostic only; not consumed by
#         SKILL prose).
# Stderr: on exit 1, exactly one line beginning `[second-reviewer-unavailable]`
#         naming the detected host, the requested/default vendor, and the
#         specific cause (no-default / explicit-none / unrecognized-vendor).
#         On exit 2, a single-line `second-reviewer-available: <reason>`
#         diagnostic plus the usage line.
#
# Boundary: this probe checks REACHABILITY only. It does NOT read `model_routing:`
# and does NOT enforce primary/second vendor distinctness — that invariant is
# enforced at matrix-lookup time by _resolve-lib.sh's resolve_second_reviewer_vendor.
# Single source of truth: the host x vendor matrix lives in _resolve-lib.sh; this
# probe carries no parallel host table.
#
# Bash 3.2 portable: no mapfile, no declare -A, no ${var,,}, no coproc.

set -u

_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd -P)"

_usage() {
  echo "Usage: second-reviewer-available.sh [--vendor <name>]" >&2
}

# Argument parsing. `--vendor <name>` (or `--vendor=<name>`) is the only
# accepted form. Positional arguments, unknown flags, empty vendor values,
# and flag-shaped vendor values are rejected with exit 2 so a typo like
# `--artifact-dir foo` or `--vendor --bogus` cannot be silently consumed as
# a vendor name (the class-of-bug v0.7.2.4 hotfix closes — see
# tests/unit/test-second-reviewer-available.bats § "argument hardening").
_vendor=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --vendor)
      if [ "$#" -lt 2 ]; then
        echo "second-reviewer-available: --vendor requires a value" >&2
        _usage
        exit 2
      fi
      _vendor="$2"
      shift 2
      ;;
    --vendor=*)
      _vendor="${1#--vendor=}"
      shift
      ;;
    --*)
      echo "second-reviewer-available: unknown flag: $1" >&2
      _usage
      exit 2
      ;;
    *)
      echo "second-reviewer-available: positional arguments not accepted (got: $1)" >&2
      _usage
      exit 2
      ;;
  esac
  # Validate the vendor value at the parse site so empty / flag-shaped values
  # are rejected as invocation errors (exit 2), not silently treated as "use
  # default" (which masks a typo) and not later misreported as substantive
  # unavailability (exit 1, the misleading-error class the hotfix exists to
  # fix). Only enforce on branches that just assigned to _vendor.
  case "$_vendor" in
    "")
      echo "second-reviewer-available: --vendor requires a non-empty value" >&2
      _usage
      exit 2
      ;;
    -*)
      echo "second-reviewer-available: --vendor value must not begin with '-' (got: $_vendor)" >&2
      _usage
      exit 2
      ;;
  esac
done

# Source the shared host-detection primitive and routing-resolution library
# under their source-only guards so no wrapper main logic runs.
QRSPI_SOURCE_ONLY=1 . "$_SCRIPT_DIR/_host-detect.sh"
QRSPI_SOURCE_ONLY=1 . "$_SCRIPT_DIR/_resolve-lib.sh"

_host="$(detect_host)"
_default_vendor="$(lookup_default_second_reviewer "$_host")"

if [ -z "$_vendor" ]; then
  _vendor="$_default_vendor"
fi

# Substantive unavailability — exit 1 with a cause-specific diagnostic so the
# operator can distinguish "this host has no default" from "the matrix doesn't
# know this vendor name" from "explicit none".
if [ -z "$_default_vendor" ] || [ "$_default_vendor" = "none" ]; then
  printf '[second-reviewer-unavailable] host=%s vendor=%s — host names no default second-reviewer vendor\n' \
    "$_host" "$_vendor" >&2
  exit 1
fi
if [ "$_vendor" = "none" ]; then
  printf '[second-reviewer-unavailable] host=%s vendor=none — explicit none\n' \
    "$_host" >&2
  exit 1
fi
if ! second_reviewer_vendor_known "$_vendor"; then
  printf '[second-reviewer-unavailable] host=%s vendor=%s — unrecognized vendor (expected one of: openai-codex, anthropic-claude); pass --vendor <name> or omit for host default\n' \
    "$_host" "$_vendor" >&2
  exit 1
fi

# Reachable: emit the resolved vendor for diagnostic/verbose runs and exit 0.
printf '%s\n' "$_vendor"
exit 0
