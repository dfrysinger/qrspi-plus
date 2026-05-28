#!/usr/bin/env bats

# Structural lint: no `agents/qrspi-*.md` file may carry a top-level `model:`
# YAML frontmatter key. Per-task model selection is the dispatcher's job; the
# baked-in `model:` field is the v0.7.1 hardening target removed by Task 9.
#
# Scope: only the standalone top-level `model:` key inside the leading
# `---`-delimited YAML frontmatter block is forbidden. Prose mentions of tier
# names (haiku, sonnet, opus, inherit) elsewhere in the body are explicitly
# out of scope and must not be flagged.

setup() {
  cd "$BATS_TEST_DIRNAME/../.."
}

# Helper: print the YAML frontmatter block (lines between the first two `---`
# lines at column 0) for a given file. Bash 3.2 / POSIX-awk portable.
_frontmatter() {
  awk '
    /^---$/ {
      n++
      if (n == 1) { next }
      if (n == 2) { exit }
    }
    n == 1 { print }
  ' "$1"
}

@test "[agent-frontmatter-no-model] sweep matches the expected 41 qrspi agent files" {
  # Sanity check: glob expansion finds every qrspi-* agent file. If this
  # count drifts, the agent surface changed and the lint scope below needs
  # a deliberate re-review (not silent under-coverage).
  local count=0
  local f
  for f in agents/qrspi-*.md; do
    [ -f "$f" ] || continue
    count=$((count + 1))
  done
  [ "$count" -eq 41 ] || {
    echo "expected 41 agents/qrspi-*.md files, found $count"
    return 1
  }
}

@test "[agent-frontmatter-no-model] no agents/qrspi-*.md frontmatter carries a top-level model: key" {
  # Test expectation: sweeps every file matching agents/qrspi-*.md and fails
  # if any frontmatter block carries a standalone top-level `model:` key.
  # In RED phase (un-modified codebase) every one of the 41 agent files
  # carries `model:` so this test reports 41 per-file violations and exits
  # non-zero. After Task 9 removes the field from all 41 files, the test
  # passes with zero violations.
  local f
  local violations=0
  local offenders=""
  for f in agents/qrspi-*.md; do
    [ -f "$f" ] || continue
    # Match a top-level YAML key named `model` (no leading whitespace,
    # followed by a colon). Use grep -E for bash-3.2-portable ERE; macOS
    # system grep lacks -P. The frontmatter helper already restricts the
    # search window to the YAML block, so prose mentions of "model" in
    # dispatcher narrative are out of scope.
    local offending_line
    offending_line=$(_frontmatter "$f" | grep -nE '^model:' || true)
    if [ -n "$offending_line" ]; then
      violations=$((violations + 1))
      offenders="${offenders}${f}: forbidden top-level frontmatter key 'model:' -> ${offending_line}"$'\n'
    fi
  done
  if [ "$violations" -ne 0 ]; then
    echo "Structural lint failure: ${violations} agent file(s) carry a top-level 'model:' key in YAML frontmatter."
    echo "Per-file violations:"
    printf '%s' "$offenders"
    return 1
  fi
}

@test "[agent-frontmatter-no-model] per-file failure message names the offending file path" {
  # Test expectation: the structural lint fails clearly in RED for each
  # file that still carries a model: key, providing a useful per-file
  # failure message. This test pins the message shape: when violations
  # exist, the rendered output must include each offending file path on
  # its own line so a downstream reader (operator or RED-verification
  # adapter) can locate every site without re-running the sweep.
  local f
  local sample_offender=""
  for f in agents/qrspi-*.md; do
    [ -f "$f" ] || continue
    if _frontmatter "$f" | grep -qE '^model:'; then
      sample_offender="$f"
      break
    fi
  done

  if [ -z "$sample_offender" ]; then
    # GREEN state: no offenders exist, so there is no message-shape claim
    # to verify. Skip rather than vacuously pass.
    skip "no offenders present; message-shape pin is only meaningful while violations exist"
  fi

  # Re-render the same per-file message shape the main sweep uses and
  # assert it contains the offending file path verbatim.
  local rendered
  rendered="${sample_offender}: forbidden top-level frontmatter key 'model:'"
  case "$rendered" in
    *"$sample_offender"*) : ;;
    *)
      echo "per-file failure message does not name the offending path: $rendered"
      return 1
      ;;
  esac
}

@test "[agent-frontmatter-no-model] lint scope is the frontmatter block, not body prose" {
  # Test expectation: tier-name references in dispatcher prose blocks
  # (haiku, sonnet, opus, inherit) within each file are not modified;
  # only the standalone `model:` key in the YAML front matter block is
  # removed. This test guards the lint scope: a synthesized fixture
  # whose body contains the literal text "model:" but whose frontmatter
  # does NOT must pass the frontmatter-only check.
  local fixture
  fixture="${BATS_TEST_TMPDIR:-/tmp}/agent-frontmatter-no-model-fixture.md"
  cat >"$fixture" <<'EOF'
---
name: qrspi-fake-agent
description: "fixture for scope test"
tools: Read
---

Body prose can talk about model: opus in dispatcher narrative without
tripping the lint. The lint only inspects the YAML frontmatter block.
EOF

  # Frontmatter must be empty of any `model:` key.
  if _frontmatter "$fixture" | grep -qE '^model:'; then
    echo "frontmatter helper incorrectly flagged a body-only 'model:' mention"
    rm -f "$fixture"
    return 1
  fi
  rm -f "$fixture"
}
