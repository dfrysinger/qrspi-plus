#!/usr/bin/env bash
# =============================================================================
# scripts/detect-interaction-mode.sh
# Usage: detect-interaction-mode.sh  (no arguments)
# Exit 0: detection succeeded (including safe-default branch)
# Exit non-zero: invalid QRSPI_INTERACTION_MODE value, or positional arg supplied
# Stdout: KEY=VALUE pairs, one per line; DETECTION_TYPE ∈ {shell-verdict, llm-context, user-override-only}
#
# shell-verdict:      PLATFORM=<name> DETECTION_TYPE=shell-verdict VERDICT=auto|interactive EVIDENCE=<signal>
# llm-context:        PLATFORM=<name> DETECTION_TYPE=llm-context INSTRUCTION=<prose>
# user-override-only: PLATFORM=<name> DETECTION_TYPE=user-override-only VERDICT=interactive EVIDENCE=<override-chain-result>
#
# The script NEVER writes .interaction-mode-audit.json or any other file.
# The orchestrator is the exclusive writer of <round-dir>/.interaction-mode-audit.json
# (single-writer principle per design.md CD-4 §I.7 L671).
#
# =============================================================================
# LOCKED PLATFORM DIRECTORY
# (verified at design time + implementation-start runtime observation, 2026-06-03)
#
# | Platform discriminator | Auto-mode signal | Script output shape |
# |---|---|---|
# | `COPILOT_CLI=1` (Copilot CLI; observed on v1.0.57-1, signal not documented in
# |   `copilot help environment` or official autopilot docs but injected at runtime) |
# |   `<autopilot_mode>` block in active context containing the literal sentence
# |   "Autopilot mode is currently active."  Durable per-turn injection while
# |   autopilot is on.  Verified by direct toggle-and-observe in session `fff21ea0`
# |   on 2026-05-31. | DETECTION_TYPE=llm-context |
# |---|---|---|
# | Claude Code (CLAUDE_PROJECT_DIR set, no COPILOT_CLI env, Claude Code's standard
# |   system-reminder framing present) | `## Auto Mode Active` system-reminder block
# |   in active context.  Documented precedent in `qrspi/skills/goals/SKILL.md` and
# |   other plugin skills that already condition on the same signal. |
# |   DETECTION_TYPE=llm-context |
# |---|---|---|
# | Unknown / unrecognized host | n/a | DETECTION_TYPE=user-override-only |
#
# =============================================================================
# OVERRIDE CHAIN
# (consulted for any `user-override-only` host, AND for top-level user override
#  on any host before host detection runs)
#
# 1. QRSPI_INTERACTION_MODE=auto|interactive env var (highest precedence for
#    testing and explicit user opt-in)
# 2. Safe-default `interactive` (never auto-halt on a misread)
#
# =============================================================================
# Encapsulation rule.
#
# No SKILL.md prose, no agent body, and no _shared/ snippet references per-host
# signal names directly (env var names, system-reminder strings, etc.).  They all
# consult scripts/detect-interaction-mode.sh and act on its output.  The script's
# source is the only place where per-host detection knowledge lives.  When a new
# host CLI is supported (or an existing host adds a shell-visible or in-context
# auto signal that previously was undocumented), the script gains one new branch —
# no consumer prose changes.
#
# =============================================================================
# Implementation-start verification citation block
# (Iron Law per design.md CD-4 §I.7 L619-626)
#
# Verification date: 2026-06-03
# Observation method: direct runtime observation in active Copilot CLI session
# Host CLI verified: Copilot CLI v1.0.57-1
#   - COPILOT_CLI_BINARY_VERSION=1.0.57-1 observed in env at implementation time
#   - COPILOT_CLI=1 observed as the sole discriminator signal
#   - COPILOT_AGENT_SESSION_ID=fff21ea0-f5c1-5736-8915-9b157f49df28 (matches
#     design.md's referenced verification session)
#   - `<autopilot_mode>` block with "Autopilot mode is currently active." confirmed
#     as the durable per-turn injection per design.md L613
#   - `copilot help environment` does NOT document the COPILOT_CLI signal or the
#     autopilot_mode context injection (design-time finding still holds as of today)
# Claude Code signal:
#   - CLAUDE_PROJECT_DIR set by Claude Code at session startup
#   - `## Auto Mode Active` system-reminder string cited in qrspi/skills/goals/SKILL.md
#     and qrspi/skills/design/SKILL.md (canonical usage, verified 2026-06-03)
# No new signals discovered; design-time findings still accurate.
#
# =============================================================================
# bash 3.2 portable: no mapfile, no declare -A, no ${var,,}, no coproc.
set -euo pipefail

# ---------------------------------------------------------------------------
# Usage guard: no positional arguments accepted
# ---------------------------------------------------------------------------
if [[ $# -gt 0 ]]; then
  echo "Usage: detect-interaction-mode.sh  (no arguments)" >&2
  echo "  This helper emits one KEY=VALUE pair per line describing the" >&2
  echo "  interaction-mode detection result for the active host." >&2
  echo "  It accepts no positional arguments." >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Override chain: QRSPI_INTERACTION_MODE (highest precedence)
# If set, it overrides host detection entirely.
# ---------------------------------------------------------------------------
if [[ -n "${QRSPI_INTERACTION_MODE:-}" ]]; then
  case "${QRSPI_INTERACTION_MODE}" in
    auto|interactive)
      # Determine the platform token at override time so the audit tuple is accurate.
      # Mirrors the host-detection discriminators below; intentionally bounded duplication.
      if [[ "${COPILOT_CLI:-}" == "1" ]]; then
        _override_platform="copilot-cli"
      elif [[ -n "${CLAUDE_PROJECT_DIR:-}" ]]; then
        _override_platform="claude-code"
      else
        _override_platform="unknown"
      fi
      # Emit full user-override-only shape: PLATFORM, DETECTION_TYPE, VERDICT, EVIDENCE
      # (design I.7 L655-664; L675: orchestrator copies all four directly from stdout)
      printf 'PLATFORM=%s\n' "${_override_platform}"
      printf 'DETECTION_TYPE=user-override-only\n'
      printf 'VERDICT=%s\n' "${QRSPI_INTERACTION_MODE}"
      printf 'EVIDENCE=QRSPI_INTERACTION_MODE=%s override\n' "${QRSPI_INTERACTION_MODE}"
      exit 0
      ;;
    *)
      printf 'Error: QRSPI_INTERACTION_MODE=%s is not a valid value.\n' \
        "${QRSPI_INTERACTION_MODE}" >&2
      printf 'Allowed values: auto, interactive\n' >&2
      exit 1
      ;;
  esac
fi

# ---------------------------------------------------------------------------
# Host detection
# ---------------------------------------------------------------------------

if [[ "${COPILOT_CLI:-}" == "1" ]]; then
  # --- Copilot CLI branch ---
  # Discriminator: COPILOT_CLI=1 (observed on v1.0.57-1; injected at runtime;
  # not documented in `copilot help environment` but confirmed by direct
  # toggle-and-observe in session fff21ea0 on 2026-05-31).
  # Auto-mode signal: <autopilot_mode> block in active context containing
  # "Autopilot mode is currently active."
  printf 'PLATFORM=copilot-cli\n'
  printf 'DETECTION_TYPE=llm-context\n'
  # The INSTRUCTION tells the orchestrator LLM how to inspect its own context.
  # Kept as a single KEY=VALUE line per the output-shape contract.
  printf "INSTRUCTION=Inspect your active context for a block delimited by <autopilot_mode> ... </autopilot_mode> tags. If the block is present AND its body contains the literal sentence 'Autopilot mode is currently active.', the session is auto-mode; otherwise interactive.\n"
  exit 0

elif [[ -n "${CLAUDE_PROJECT_DIR:-}" ]]; then
  # --- Claude Code branch ---
  # Discriminator: CLAUDE_PROJECT_DIR set (Claude Code sets this env var at
  # session startup; confirmed via qrspi/skills/goals/SKILL.md canonical usage
  # of ## Auto Mode Active as the system-reminder marker).
  # Auto-mode signal: ## Auto Mode Active system-reminder block in active context.
  printf 'PLATFORM=claude-code\n'
  printf 'DETECTION_TYPE=llm-context\n'
  printf "INSTRUCTION=Inspect your active context for a system-reminder block containing the literal string '## Auto Mode Active'. If present, the session is auto-mode; otherwise interactive.\n"
  exit 0

else
  # --- Unknown host / safe-default branch ---
  # No recognized host discriminator present.  Defer to override chain:
  # QRSPI_INTERACTION_MODE was already checked above and was absent.
  # Apply safe-default: interactive (never auto-halt on a misread).
  printf 'PLATFORM=unknown\n'
  printf 'DETECTION_TYPE=user-override-only\n'
  printf 'VERDICT=interactive\n'
  printf 'EVIDENCE=no host signal; QRSPI_INTERACTION_MODE absent; safe default applied\n'
  exit 0
fi
