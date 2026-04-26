#!/usr/bin/env bats

setup() {
  source "$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)/hooks/lib/agent.sh"
}

@test "agent_is_subagent: returns 0 when agent_id is set" {
  run agent_is_subagent '{"agent_id":"sub-abc123","tool_name":"Edit"}'
  [ "$status" -eq 0 ]
}

@test "agent_is_subagent: returns 1 when agent_id is empty string" {
  run agent_is_subagent '{"agent_id":"","tool_name":"Edit"}'
  [ "$status" -ne 0 ]
}

@test "agent_is_subagent: returns 1 when agent_id field is missing" {
  run agent_is_subagent '{"tool_name":"Edit"}'
  [ "$status" -ne 0 ]
}

@test "agent_is_subagent: returns 1 when agent_id is null" {
  run agent_is_subagent '{"agent_id":null,"tool_name":"Edit"}'
  [ "$status" -ne 0 ]
}

@test "agent_is_subagent: returns 1 on malformed JSON" {
  run agent_is_subagent '{not json'
  [ "$status" -ne 0 ]
}

@test "agent_is_subagent: returns 1 on empty input" {
  run agent_is_subagent ''
  [ "$status" -ne 0 ]
}
