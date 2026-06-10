#!/usr/bin/env bats

# Bug 2 (v0.7.2.5 hotfix): every qrspi agent file MUST carry both frontmatter
# fields so Task-tool subagent spawn works on both platforms:
#   - `tools:`         (claude-code vocabulary, capitalized: Read, Write, Bash, ...)
#   - `allowed-tools:` (copilot-cli vocabulary, lowercase: read, write, edit, create, bash, ...)
#
# Each platform silently ignores the unrecognized field. Without `allowed-tools`,
# Copilot CLI's Task tool spawned subagents that fell back to a default allowlist
# missing the disk-write tools, causing per-finding files to never materialize on
# disk (the cascade that triggered Bug 3).
#
# This test asserts both fields are present and that `allowed-tools:` only uses
# the recognized lowercase copilot-cli tool names.

setup() {
  cd "$BATS_TEST_DIRNAME/../.."
}

@test "every qrspi agent file carries a tools: line (claude-code compat)" {
  for f in agents/qrspi-*.md; do
    awk '/^---$/{n++; if(n==2) exit} n==1' "$f" | grep -qE '^tools:[[:space:]]' \
      || { echo "$f missing tools: field"; return 1; }
  done
  return 0
}

@test "every qrspi agent file carries an allowed-tools: line (copilot-cli compat)" {
  for f in agents/qrspi-*.md; do
    awk '/^---$/{n++; if(n==2) exit} n==1' "$f" | grep -qE '^allowed-tools:[[:space:]]' \
      || { echo "$f missing allowed-tools: field (Bug 2: Copilot CLI Task tool needs lowercase allowed-tools)"; return 1; }
  done
  return 0
}

@test "allowed-tools values use only lowercase copilot-cli vocabulary" {
  # Copilot CLI tool vocabulary (from app.js sUn map): bash, shell, write, edit,
  # create, memory, store_memory, vote_memory, read, view, glob, grep, ls, task,
  # webfetch, web_fetch, websearch, web_search.
  # Reject any uppercase letter (the claude-code-style capitalized form) and any
  # token not in the recognized set.
  local recognized='^(bash|shell|write|edit|create|memory|store_memory|vote_memory|read|view|glob|grep|ls|task|webfetch|web_fetch|websearch|web_search)$'
  for f in agents/qrspi-*.md; do
    local line
    line=$(awk '/^---$/{n++; if(n==2) exit} n==1 && /^allowed-tools:/' "$f" | head -1)
    [ -n "$line" ] || continue
    local val
    val=$(echo "$line" | sed -E 's|^allowed-tools:[[:space:]]*||; s|^\[||; s|\]$||')
    # Each comma-separated token must match the recognized vocabulary.
    IFS=',' read -ra toks <<< "$val"
    for raw in "${toks[@]}"; do
      local t
      t=$(echo "$raw" | sed -E 's|^[[:space:]]+||; s|[[:space:]]+$||')
      [ -z "$t" ] && continue
      if [[ "$t" =~ [A-Z] ]]; then
        echo "$f allowed-tools contains uppercase token '$t' (Copilot CLI requires lowercase)"; return 1
      fi
      if ! [[ "$t" =~ $recognized ]]; then
        echo "$f allowed-tools contains unrecognized token '$t' (not in copilot-cli vocabulary)"; return 1
      fi
    done
  done
  return 0
}

@test "agent files granting Write also grant edit + create in allowed-tools (full write coverage)" {
  # Copilot CLI splits the Write capability across three distinct tool names
  # (write, edit, create — all kind:write in the bundle's sUn map). Granting
  # only `write` would leave Edit/Create denied, so any agent whose claude-code
  # tools: line includes Write must list all three in allowed-tools.
  for f in agents/qrspi-*.md; do
    local fm tools_line allowed_line
    fm=$(awk '/^---$/{n++; if(n==2) exit} n==1' "$f")
    tools_line=$(echo "$fm" | grep -E '^tools:' | head -1)
    echo "$tools_line" | grep -qE '\bWrite\b' || continue
    allowed_line=$(echo "$fm" | grep -E '^allowed-tools:' | head -1)
    for needed in write edit create; do
      echo "$allowed_line" | grep -qE "\b${needed}\b" \
        || { echo "$f: tools: lists Write but allowed-tools missing '$needed'"; return 1; }
    done
  done
  return 0
}
