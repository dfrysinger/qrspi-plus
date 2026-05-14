#!/usr/bin/env bats

# Structural pin for agents/qrspi-test-writer.md tool-grant contract (G3).
# Asserts the frontmatter tools: line carries all four read-side tools and
# that the body prose justifying the grant is still present.

AGENT_FILE="agents/qrspi-test-writer.md"

# ---------------------------------------------------------------------------
# File presence
# ---------------------------------------------------------------------------

@test "agent file exists" {
  [ -f "$AGENT_FILE" ]
}

# ---------------------------------------------------------------------------
# Frontmatter tools: line — membership checks (order-independent)
# ---------------------------------------------------------------------------

@test "frontmatter tools: line contains Read" {
  local tools_line
  tools_line=$(awk '/^---$/{n++; next} n==1 && /^tools:/{print; exit}' "$AGENT_FILE")
  [ -n "$tools_line" ]
  echo "$tools_line" | grep -qE '\bRead\b'
}

@test "frontmatter tools: line contains Write" {
  local tools_line
  tools_line=$(awk '/^---$/{n++; next} n==1 && /^tools:/{print; exit}' "$AGENT_FILE")
  [ -n "$tools_line" ]
  echo "$tools_line" | grep -qE '\bWrite\b'
}

@test "frontmatter tools: line contains Grep" {
  local tools_line
  tools_line=$(awk '/^---$/{n++; next} n==1 && /^tools:/{print; exit}' "$AGENT_FILE")
  [ -n "$tools_line" ]
  echo "$tools_line" | grep -qE '\bGrep\b'
}

@test "frontmatter tools: line contains Glob" {
  local tools_line
  tools_line=$(awk '/^---$/{n++; next} n==1 && /^tools:/{print; exit}' "$AGENT_FILE")
  [ -n "$tools_line" ]
  echo "$tools_line" | grep -qE '\bGlob\b'
}

# ---------------------------------------------------------------------------
# Body preservation — "Survey existing tests before writing" sentence
# ---------------------------------------------------------------------------

@test "agent body contains Survey existing tests before writing sentence" {
  local body
  body=$(awk '/^---$/{n++; next} n>=2{print}' "$AGENT_FILE")
  echo "$body" | grep -qF "Survey existing tests before writing"
}
