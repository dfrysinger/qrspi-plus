#!/usr/bin/env bash
# _resolve-lib.sh — shared routing-resolution library (G22 / design.md CD-1).
#
# Sourced by scripts/dispatch-agent.sh and friends. Single source of truth for
# the resolution algorithm: agent-frontmatter `tier:` parsing, the tier
# precedence chain, tier -> (vendor, model) lookup from config.md
# `model_routing:`, host x vendor matrix lookup, and the `none`-tier halt rule.
#
# Bash 3.2 portable. Guard with QRSPI_SOURCE_ONLY=1 to source without running.
#
# ---------------------------------------------------------------------------
# Tier resolution precedence chain (top wins) — design.md CD-1 #1:
#   1. `--tier-override` flag at the dispatch site (per-dispatch override; used
#      by plan->implementer for per-task complexity variance). Highest layer.
#   2. The agent's `tier:` frontmatter field (parsed from the agent .md file).
#   3. `default_tier:` from config.md (covers agents missing `tier:` during
#      migration).
#   4. Hardcoded fallback `medium` with a LOUD warning to stderr (last resort).
#
# `none`-tier halt — design.md CD-1 #2: a dispatch whose resolved tier is
# configured as `none` in `model_routing:` halts loudly (non-zero exit, no
# silent fallback to a neighboring tier or to an agent-bundled model). The
# diagnostic names the unconfigured tier so operators see which tier was
# targeted; opaque error messages are not acceptable.
#
# Host x vendor matrix (design.md §G27 D5) — implemented by
# lookup_host_vendor_path / lookup_default_second_reviewer:
#
# | Host          | Claude        | Codex         | DeepSeek (v0.7.3+) | Default second-reviewer vendor |
# |---------------|---------------|---------------|--------------------|--------------------------------|
# | Claude Code   | first-party   | third-party   | third-party        | `openai-codex`                 |
# | Codex CLI*    | third-party   | first-party   | third-party        | `anthropic-claude` (v0.7.3+)   |
# | Copilot CLI   | first-party   | first-party   | third-party        | `openai-codex`                 |
#
# *Codex CLI host support deferred to v0.7.3+.
# ---------------------------------------------------------------------------

# resolve_tier <agent-file> [<tier-override>]
# Applies the precedence chain and echoes the resolved tier name.
resolve_tier() {
  local agent_file="$1" tier_override="${2:-}"

  # Layer 1: per-dispatch --tier-override flag (highest precedence).
  if [ -n "$tier_override" ]; then
    printf '%s\n' "$tier_override"
    return 0
  fi

  # Layer 2: the agent `tier:` frontmatter field.
  local agent_tier=""
  if [ -n "$agent_file" ] && [ -f "$agent_file" ]; then
    agent_tier="$(grep -E '^tier:[[:space:]]+' "$agent_file" 2>/dev/null \
      | head -1 | sed -E 's/^tier:[[:space:]]+//' | tr -d '[:space:]')"
  fi
  if [ -n "$agent_tier" ]; then
    printf '%s\n' "$agent_tier"
    return 0
  fi

  # Layer 3: default_tier: from config.md.
  local default_tier=""
  if [ -n "${CONFIG_MD:-}" ] && [ -f "${CONFIG_MD:-}" ]; then
    default_tier="$(grep -E '^default_tier:[[:space:]]+' "$CONFIG_MD" 2>/dev/null \
      | head -1 | sed -E 's/^default_tier:[[:space:]]+//' | tr -d '[:space:]')"
  fi
  if [ -n "$default_tier" ]; then
    printf '%s\n' "$default_tier"
    return 0
  fi

  # Layer 4: hardcoded `medium` fallback with a LOUD warning. Last resort —
  # reaching this layer means neither agent `tier:` nor config `default_tier:`
  # was available, which is a migration smell worth shouting about.
  printf '[routing] WARN: no tier resolved; falling back to hardcoded medium\n' >&2
  printf 'medium\n'
  return 0
}

# resolve_model <tier>
# Looks up the tier's `{ vendor:, model: }` entry in config.md `model_routing:`.
# HALTS LOUDLY (non-zero, no silent fallback) when the tier resolves to `none`
# or is unconfigured — the diagnostic names the unconfigured tier.
resolve_model() {
  local tier="$1"
  local row=""
  if [ -n "${CONFIG_MD:-}" ] && [ -f "${CONFIG_MD:-}" ]; then
    row="$(grep -E "^[[:space:]]*${tier}:[[:space:]]" "$CONFIG_MD" 2>/dev/null | head -1)"
  fi

  # none-tier halt: a tier configured as `none` (operator opt-in surface left
  # unconfigured) must HALT, never silently fall back to a neighboring tier.
  if [ -z "$row" ] || printf '%s' "$row" | grep -Eq "^[[:space:]]*${tier}:[[:space:]]+none[[:space:]]*$"; then
    printf '[routing] HALT: tier "%s" resolves to none (unconfigured tier); ' "$tier" >&2
    printf 'no silent fallback to a neighboring tier — configure model_routing.%s in config.md.\n' "$tier" >&2
    return 1
  fi

  # Echo the vendor/model object portion for the caller to parse.
  printf '%s\n' "$row" | sed -E "s/^[[:space:]]*${tier}:[[:space:]]+//"
  return 0
}

# lookup_host_vendor_path <host> <vendor>
# Returns `first-party` or `third-party` per the host x vendor matrix above.
lookup_host_vendor_path() {
  local host="$1" vendor="$2"
  case "$host:$vendor" in
    claude-code:claude|copilot-cli:claude|copilot-cli:codex|codex-cli:codex) printf 'first-party\n' ;;
    *) printf 'third-party\n' ;;
  esac
}

# lookup_default_second_reviewer <host>
# Returns the default second-reviewer vendor id for the host (or `none`).
lookup_default_second_reviewer() {
  local host="$1"
  case "$host" in
    claude-code|copilot-cli) printf 'openai-codex\n' ;;
    codex-cli) printf 'anthropic-claude\n' ;;
    *) printf 'none\n' ;;
  esac
}

# Allow `QRSPI_SOURCE_ONLY=1 source _resolve-lib.sh` without side effects.
if [ "${QRSPI_SOURCE_ONLY:-}" = "1" ]; then
  return 0 2>/dev/null || true
fi
