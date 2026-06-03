#!/usr/bin/env bash
# second-reviewer-available.sh — host-aware second-reviewer availability probe.
#
# Detects the active host (via _host-detect.sh), looks up the host's default
# second-reviewer vendor (via _resolve-lib.sh's host x vendor matrix), and exits
# 0 when that vendor is potentially reachable on this host. An optional positional
# <vendor> argument overrides the default lookup for operator/diagnostic runs.
#
# Usage:
#   second-reviewer-available.sh [<vendor>]
#
# Exit 0: the requested/default second-reviewer vendor is potentially available
#         for the detected host.
# Exit 1: the detected host names no default second-reviewer vendor, the vendor
#         is absent from the host x vendor matrix, or the vendor is unreachable.
#
# Stdout: on success, the resolved vendor id (diagnostic only; not consumed by
#         SKILL prose).
# Stderr: on failure, exactly one line beginning `[second-reviewer-unavailable]`
#         naming the detected host and the requested/default vendor.
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

# Source the shared host-detection primitive and routing-resolution library
# under their source-only guards so no wrapper main logic runs.
QRSPI_SOURCE_ONLY=1 . "$_SCRIPT_DIR/_host-detect.sh"
QRSPI_SOURCE_ONLY=1 . "$_SCRIPT_DIR/_resolve-lib.sh"

_host="$(detect_host)"

_default_vendor="$(lookup_default_second_reviewer "$_host")"

# optional <vendor> override; else the host default
if [ "$#" -ge 1 ] && [ -n "$1" ]; then
  _vendor="$1"
else
  _vendor="$_default_vendor"
fi

# Unavailable when the host names no default second-reviewer vendor (unknown /
# unsupported host — reachability is host-dependent, so an override cannot make
# an unsupported host available), the requested vendor is `none`, or the vendor
# is not a recognised matrix vendor.
if [ "$_default_vendor" = "none" ] || [ "$_vendor" = "none" ] || ! second_reviewer_vendor_known "$_vendor"; then
  printf '[second-reviewer-unavailable] host=%s vendor=%s — no reachable second reviewer for this host\n' \
    "$_host" "$_vendor" >&2
  exit 1
fi

# Reachable: emit the resolved vendor for diagnostic/verbose runs and exit 0.
printf '%s\n' "$_vendor"
exit 0
