#!/usr/bin/env bash
set -euo pipefail

# agent_is_subagent <envelope_json>
#
# Returns 0 if the hook envelope's `agent_id` field is set to a non-empty string,
# indicating the call comes from a subagent (Agent tool dispatch). Returns 1 if
# the field is missing, null, empty, or the input is malformed.
#
# This is the only mechanism for distinguishing main chat from subagent in the
# new asymmetric hook. Do NOT use CWD for this distinction — see spec section
# "Hook behavior / Subagent vs main-chat detection".
agent_is_subagent() {
  local envelope_json="$1"
  local agent_id

  agent_id=$(printf '%s' "$envelope_json" | jq -r '.agent_id // empty' 2>/dev/null) || return 1
  [[ -n "$agent_id" ]]
}
