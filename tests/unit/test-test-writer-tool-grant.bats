#!/usr/bin/env bats

# Structural pin for agents/qrspi-test-writer.md tool-grant contract per
# the test-writer task spec. Asserts the frontmatter tools: line carries
# all four read-side tools and that the body prose justifying the grant
# is still present.

setup() {
  AGENT_FILE="$BATS_TEST_DIRNAME/../../agents/qrspi-test-writer.md"
  export AGENT_FILE
}

# =============================================================================
# Helper — frontmatter tools: line extraction
# =============================================================================

get_tools_line() {
  awk '/^---$/{n++; next} n==1 && /^tools:/{print; exit}' "$AGENT_FILE"
}

# ---------------------------------------------------------------------------
# File presence
# ---------------------------------------------------------------------------

@test "agent file exists" {
  [ -f "$AGENT_FILE" ]
}

# ---------------------------------------------------------------------------
# Frontmatter tools: line — key presence check
# ---------------------------------------------------------------------------

@test "frontmatter tools: line exists in frontmatter" {
  local tools_line
  tools_line=$(get_tools_line)
  if [ -z "$tools_line" ]; then
    echo "FAIL: no 'tools:' key found in frontmatter of $AGENT_FILE" >&2
    return 1
  fi
}

# ---------------------------------------------------------------------------
# Frontmatter tools: line — membership checks (order-independent)
# ---------------------------------------------------------------------------

@test "frontmatter tools: line contains Read" {
  local tools_line
  tools_line=$(get_tools_line)
  if [ -z "$tools_line" ]; then
    echo "FAIL: tools: key absent from frontmatter — cannot check for 'Read'" >&2
    return 1
  fi
  if ! echo "$tools_line" | grep -qw "Read"; then
    echo "FAIL: tool name 'Read' is missing from tools: line: $tools_line" >&2
    return 1
  fi
}

@test "frontmatter tools: line contains Write" {
  local tools_line
  tools_line=$(get_tools_line)
  if [ -z "$tools_line" ]; then
    echo "FAIL: tools: key absent from frontmatter — cannot check for 'Write'" >&2
    return 1
  fi
  if ! echo "$tools_line" | grep -qw "Write"; then
    echo "FAIL: tool name 'Write' is missing from tools: line: $tools_line" >&2
    return 1
  fi
}

@test "frontmatter tools: line contains Grep" {
  local tools_line
  tools_line=$(get_tools_line)
  if [ -z "$tools_line" ]; then
    echo "FAIL: tools: key absent from frontmatter — cannot check for 'Grep'" >&2
    return 1
  fi
  if ! echo "$tools_line" | grep -qw "Grep"; then
    echo "FAIL: tool name 'Grep' is missing from tools: line: $tools_line" >&2
    return 1
  fi
}

@test "frontmatter tools: line contains Glob" {
  local tools_line
  tools_line=$(get_tools_line)
  if [ -z "$tools_line" ]; then
    echo "FAIL: tools: key absent from frontmatter — cannot check for 'Glob'" >&2
    return 1
  fi
  if ! echo "$tools_line" | grep -qw "Glob"; then
    echo "FAIL: tool name 'Glob' is missing from tools: line: $tools_line" >&2
    return 1
  fi
}

# ---------------------------------------------------------------------------
# Body preservation — "Survey existing tests before writing" sentence
# ---------------------------------------------------------------------------

@test "agent body contains Survey existing tests before writing sentence" {
  local body
  body=$(awk '/^---$/{n++; next} n>=2{print}' "$AGENT_FILE")
  echo "$body" | grep -qF "Survey existing tests before writing"
}
