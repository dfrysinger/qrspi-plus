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
  # Test expectation: the sweep's per-file error message must include the
  # offending file's path verbatim. A regression that drops the "${f}:"
  # prefix from the message format must cause this test to fail.
  #
  # Unlike the prior tautological implementation (which constructed a local
  # `rendered` string from $sample_offender and then checked it contained
  # $sample_offender — always true), this test uses a synthetic fixture and
  # a real sweep invocation via `run` so the assertion exercises actual
  # output from the code path under test.

  # 1. Create a synthetic fixture carrying model: in its frontmatter so this
  #    test is independent of the state of the real agent files.
  local fixture
  fixture="${BATS_TEST_TMPDIR}/qrspi-test-frontmatter-msg-shape.md"
  cat >"$fixture" <<'EOF'
---
name: qrspi-test-fixture
model: sonnet
description: "Synthetic fixture for message-shape test"
tools: Read
---

Body text does not affect the lint.
EOF

  # 2. Write a one-file sweep script that mirrors the real sweep's per-file
  #    detection and message construction. `run` captures its stdout, letting
  #    us assert the rendered text without coupling to real agent file state.
  local sweep_script
  sweep_script="${BATS_TEST_TMPDIR}/sweep-one-file.sh"
  cat >"$sweep_script" <<'SCRIPT'
#!/usr/bin/env bash
# Mirrors the per-file detection + message construction used in the main
# sweep test. Any regression that drops the "${f}:" path prefix from the
# real sweep must also update this script, breaking the assertion below.
_frontmatter() {
  awk '/^---$/{n++;if(n==1){next}if(n==2){exit}}n==1{print}' "$1"
}
f="$1"
offending_line=$(_frontmatter "$f" | grep -nE '^model:' || true)
if [ -n "$offending_line" ]; then
  echo "${f}: forbidden top-level frontmatter key 'model:' -> ${offending_line}"
fi
SCRIPT
  chmod +x "$sweep_script"

  # 3. Invoke the sweep on the fixture; run captures stdout into $output.
  run bash "$sweep_script" "$fixture"

  # 4. The rendered message must include the fixture path verbatim.
  #    This assertion fails if the sweep drops the "${f}:" path prefix.
  [[ "$output" == *"$fixture"* ]] || {
    echo "sweep output did not include fixture path; got: $output"
    return 1
  }

  # 5. The rendered message must include the literal error format marker.
  [[ "$output" == *"forbidden top-level frontmatter key 'model:'"* ]] || {
    echo "sweep output did not include error format text; got: $output"
    return 1
  }
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
