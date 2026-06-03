#!/usr/bin/env bash
# _host-detect.sh — source-safe canonical host-detection primitive.
#
# Provides a single `detect_host` function that maps the active execution
# environment to a canonical host identifier using ENVIRONMENT SIGNALS ONLY.
# It performs NO filesystem probes (no HOME-based globs, no path existence
# checks) and has NO wrapper side effects: sourcing it is always safe, even
# under QRSPI_SOURCE_ONLY=1.
#
# Canonical host identifiers:
#   copilot-cli   — COPILOT_CLI=1 in the environment.
#   claude-code   — CLAUDE_PROJECT_DIR set to a non-empty value.
#   unknown       — no recognised host signal.
#
# Precedence: COPILOT_CLI is checked before CLAUDE_PROJECT_DIR so a host that
# exports both signals resolves deterministically to copilot-cli.
#
# Note on codex-cli: the codex-cli identifier is enumerated in the documented
# host set, but no detection branch ships this release — a Codex env signal
# with no copilot/claude signal falls through to `unknown`. The codex-cli
# detection branch is intentionally deferred (see design.md: Codex CLI host
# support is out of scope for v0.7.2).
#
# Bash 3.2 portable: no mapfile, no declare -A, no ${var,,}, no coproc.

# detect_host
# Echoes exactly one canonical host identifier and returns 0.
detect_host() {
  if [ "${COPILOT_CLI:-}" = "1" ]; then
    printf 'copilot-cli\n'
    return 0
  fi
  if [ -n "${CLAUDE_PROJECT_DIR:-}" ]; then
    printf 'claude-code\n'
    return 0
  fi
  printf 'unknown\n'
  return 0
}

# Allow `QRSPI_SOURCE_ONLY=1 source _host-detect.sh` without side effects.
# Sourcing this file never runs detect_host; the guard simply documents the
# source-only contract and short-circuits any future trailing main logic.
if [ "${QRSPI_SOURCE_ONLY:-}" = "1" ]; then
  return 0 2>/dev/null || true
fi
