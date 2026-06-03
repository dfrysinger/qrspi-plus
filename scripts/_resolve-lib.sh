#!/usr/bin/env bash
# _resolve-lib.sh — shared routing-resolution library (G22 / design.md CD-1).
#
# Sourced by scripts/dispatch-agent.sh and friends. Implements the tier-resolution
# algorithm: agent-frontmatter `tier:` parsing, the tier precedence chain,
# tier -> (vendor, model) lookup from config.md `model_routing:`, the host x
# vendor matrix lookup, and the `none`-tier halt rule.
#
# NOT implemented here: the `trusted_path:` short-circuit is a dispatch-site
# concern evaluated at the main-chat dispatcher BEFORE this library is consulted
# (it bypasses the tier chain entirely); this library is intentionally not its
# enforcement point.
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

# _normalize_tier_value <raw-value>
# Strips a whitespace-preceded inline `#` comment, then ALL whitespace (both
# surrounding AND internal), from a routing row's VALUE. Bash 3.2 portable.
_normalize_tier_value() {
  printf '%s' "$1" | sed -E 's/[[:space:]]+#.*$//' | tr -d '[:space:]'
}

# _halt_unconfigured_tier <tier-name>
# Prints the shared unconfigured-tier (`none`/absent-row) diagnostic to stderr
# and returns 1. Single source for the two byte-identical none halts so the
# message cannot drift between the absent-row and explicit-`none` branches.
# Bash 3.2 portable.
_halt_unconfigured_tier() {
  printf '[routing] HALT: tier "%s" resolves to none (unconfigured tier); ' "$1" >&2
  printf 'no silent fallback to a neighboring tier — configure model_routing.%s in config.md.\n' "$1" >&2
  return 1
}

# _validate_tier <tier-name>
# Allowlist-guards a tier name against the five legal tiers; halts loudly
# (diagnostic to stderr) and returns 1 on mismatch.
_validate_tier() {
  case "$1" in
    extra-low|low|medium|high|extra-high) return 0 ;;
    *) printf '[routing] HALT: invalid tier "%s" (not one of extra-low|low|medium|high|extra-high)\n' "$1" >&2; return 1 ;;
  esac
}

# resolve_tier <agent-file> [<tier-override>]
# Applies the precedence chain and echoes the resolved tier name.
resolve_tier() {
  local agent_file="$1" tier_override="${2:-}"

  # Layer 1: per-dispatch --tier-override flag (highest precedence).
  if [ -n "$tier_override" ]; then
    _validate_tier "$tier_override" || return 1
    printf '%s\n' "$tier_override"
    return 0
  fi

  # Layer 2: the agent `tier:` frontmatter field.
  local agent_tier=""
  if [ -n "$agent_file" ] && [ -f "$agent_file" ] && [ -r "$agent_file" ]; then
    agent_tier="$(grep -E '^tier:[[:space:]]+' "$agent_file" 2>/dev/null \
      | head -1 | sed -E 's/^tier:[[:space:]]+//' | tr -d '[:space:]')"
  fi
  if [ -n "$agent_tier" ]; then
    _validate_tier "$agent_tier" || return 1
    printf '%s\n' "$agent_tier"
    return 0
  fi

  # Layer 3: default_tier: from config.md. Distinguish a missing/unreadable
  # CONFIG_MD (Layer 3 cannot even be consulted) from a present config that
  # simply lacks a default_tier: — the Layer-4 warning below names the cause.
  local default_tier="" config_present=1
  if [ -n "${CONFIG_MD:-}" ] && [ -f "${CONFIG_MD:-}" ] && [ -r "${CONFIG_MD:-}" ]; then
    default_tier="$(grep -E '^default_tier:[[:space:]]+' "$CONFIG_MD" 2>/dev/null \
      | head -1 | sed -E 's/^default_tier:[[:space:]]+//' | tr -d '[:space:]')"
  else
    config_present=0
  fi
  if [ -n "$default_tier" ]; then
    _validate_tier "$default_tier" || return 1
    printf '%s\n' "$default_tier"
    return 0
  fi

  # Layer 4: hardcoded `medium` fallback with a LOUD warning. Last resort —
  # reaching this layer means neither agent `tier:` nor config `default_tier:`
  # was available, which is a migration smell worth shouting about. The warning
  # names WHY Layer 3 was skipped so an operator with a correct config is not
  # sent down the wrong repair path (the `medium` value itself is known-legal,
  # so it is not re-validated).
  if [ "$config_present" -eq 0 ]; then
    printf '[routing] WARN: no tier resolved (CONFIG_MD unset/missing — Layer 3 default_tier: could not be consulted); falling back to hardcoded medium\n' >&2
  else
    printf '[routing] WARN: no tier resolved (config present but no default_tier:); falling back to hardcoded medium\n' >&2
  fi
  printf 'medium\n'
  return 0
}

# resolve_model <tier>
# Looks up the tier's `{ vendor:, model: }` entry in config.md `model_routing:`.
# HALTS LOUDLY (non-zero, no silent fallback) when the tier resolves to `none`
# or is unconfigured — the diagnostic names the unconfigured tier.
resolve_model() {
  local tier="$1"

  # Validate $tier against the legal allowlist BEFORE any interpolation into a
  # grep/sed pattern (rejects a crafted `low|medium` ERE-alternation injection
  # and a `/`-bearing tier that would break the sed delimiter).
  _validate_tier "$tier" || return 1

  # Distinguish an unset/unreadable CONFIG_MD from a present config in which the
  # tier is simply absent or `none`. A missing config is a config-path error,
  # NOT an unconfigured-tier error — emit a DISTINCT diagnostic so an operator
  # with a correct config is not sent down the wrong repair path.
  if [ -z "${CONFIG_MD:-}" ] || [ ! -f "${CONFIG_MD:-}" ] || [ ! -r "${CONFIG_MD:-}" ]; then
    printf '[routing] HALT: CONFIG_MD is unset or not a readable file; ' >&2
    printf 'cannot resolve model_routing for tier "%s".\n' "$tier" >&2
    return 1
  fi

  # Fetch the tier's routing row. The `^[[:space:]]+` anchor REQUIRES the row be
  # indented under `model_routing:`, rejecting a column-0 out-of-block shadow.
  local row=""
  row="$(grep -E "^[[:space:]]+${tier}:[[:space:]]" "$CONFIG_MD" 2>/dev/null | head -1)"

  # An empty row means the tier is not present in the block (unconfigured tier).
  if [ -z "$row" ]; then
    _halt_unconfigured_tier "$tier"
    return 1
  fi

  # Strip the `${tier}:` key prefix, then normalize ONCE (strip any inline
  # `# comment` + surrounding whitespace). The SAME normalized value drives both
  # the none-check and the success emit, so an inline comment can neither defeat
  # the none-halt nor leak into the emitted value.
  local value
  value="$(printf '%s\n' "$row" | sed -E "s/^[[:space:]]+${tier}:[[:space:]]+//")"
  value="$(_normalize_tier_value "$value")"

  # Malformed-row guard: the row was PRESENT (matched the grep) but carries no
  # value after key-strip + normalization (e.g. `  medium:   ` — key + trailing
  # whitespace, or a row that is all inline comment). This is a DISTINCT failure
  # from an unconfigured tier — the tier IS named in the block, just emptily —
  # so it must HALT loudly rather than silently emit a blank line with exit 0.
  if [ -z "$value" ]; then
    printf '[routing] HALT: tier "%s" row is present in model_routing but carries no value ' "$tier" >&2
    printf '(malformed/empty row); refusing to emit an empty result — set model_routing.%s in config.md.\n' "$tier" >&2
    return 1
  fi

  # none-tier halt: a tier configured as `none` (operator opt-in surface left
  # unconfigured) must HALT, never silently fall back to a neighboring tier.
  if [ "$value" = "none" ]; then
    _halt_unconfigured_tier "$tier"
    return 1
  fi

  # Echo the vendor/model object portion for the caller to parse.
  printf '%s\n' "$value"
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
