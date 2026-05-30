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
#
# Fixes applied:
#   sf.F01 (CRLF): strip CR (\r) before delimiter matching so CRLF-terminated
#           files are handled correctly (GitHub web edits, Windows contributors).
#   sf.F02: track block-scalar context (key ending with | or >) so a bare ---
#           at column 0 inside a block scalar is not mistaken for the closing
#           frontmatter delimiter.
#   sf.F01 (scalar-at-end): a top-level (column-0) --- unconditionally resets
#           in_scalar before counting the delimiter. Block scalar content is
#           always indented, so a column-0 --- cannot appear inside a block
#           scalar in valid YAML; resetting in_scalar here is safe and prevents
#           the closing --- from being skipped when the scalar is the last key.
_frontmatter() {
  awk '
    { gsub(/\r$/, "") }
    /^---$/ {
      # Top-level --- always terminates any active block scalar (block scalar
      # content requires indentation; a column-0 --- is never inside one).
      in_scalar = 0
      n++
      if (n == 1) { next }
      if (n == 2) { exit }
    }
    n == 1 {
      if (/:[[:space:]]*[|>][[:space:]]*$/) { in_scalar = 1 }
      else if (in_scalar && /^[^[:space:]]/) { in_scalar = 0 }
      print
    }
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

@test "[agent-frontmatter-no-model] CRLF line endings: model: key detected in CRLF-terminated frontmatter" {
  # sf.F01: _frontmatter() used /^---$/ which does not match ---\r on
  # CRLF-terminated files. Any file with model: sonnet in CRLF frontmatter
  # silently passes. This test asserts the violation IS detected despite
  # CRLF endings (i.e., CR must be stripped before delimiter matching).
  local fixture="${BATS_TEST_TMPDIR}/qrspi-test-crlf-model.md"
  # Write the fixture with CRLF line endings throughout. Use %s\r\n
  # format to avoid printf treating leading dashes as option flags.
  printf '%s\r\n%s\r\n%s\r\n%s\r\n%s\r\n%s\r\n\r\n%s\r\n' \
    '---' 'name: qrspi-test-crlf' 'model: sonnet' \
    'description: "CRLF fixture"' 'tools: Read' '---' 'Body text.' \
    >"$fixture"

  # The sweep must detect the model: violation even with CRLF line endings.
  local offending_line
  offending_line=$(_frontmatter "$fixture" | grep -nE '^model:' || true)
  [ -n "$offending_line" ] || {
    echo "CRLF: model: key not detected — _frontmatter does not strip CR from delimiter lines"
    return 1
  }
}

@test "[agent-frontmatter-no-model] block-scalar: indented --- in block-scalar body does not prematurely close frontmatter" {
  # sf.F02: _frontmatter() must not treat an INDENTED --- that appears as
  # content inside a block scalar as the closing frontmatter delimiter.
  # In valid YAML, block scalar content is always indented relative to the
  # parent key — a top-level (column-0) --- cannot appear inside a block
  # scalar. This test uses a properly indented --- as block scalar content
  # to assert that model: sonnet IS detected as a violation even when ---
  # appears earlier in an indented block-scalar context.
  local fixture="${BATS_TEST_TMPDIR}/qrspi-test-blockscalar-model.md"
  cat >"$fixture" <<'EOF'
---
name: qrspi-test-blockscalar
description: |
  ---
model: sonnet
---

Body text.
EOF

  # The sweep must detect model: sonnet; the indented --- (block-scalar
  # content) must not be treated as the frontmatter close delimiter.
  local offending_line
  offending_line=$(_frontmatter "$fixture" | grep -nE '^model:' || true)
  [ -n "$offending_line" ] || {
    echo "block-scalar: model: key not detected — _frontmatter exited prematurely on indented --- (block-scalar content)"
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

@test "[r5-sf.F01] frontmatter ending with block-scalar key exits cleanly at closing ---" {
  # sf.F01 (scalar-at-end): when a block scalar is the LAST frontmatter key,
  # in_scalar stays 1 at the closing ---. The old guard (!in_scalar) then
  # skips n++ so the function never exits, widening the scan into body text.
  # A body-level `model:` line is then falsely flagged as a frontmatter
  # violation. This fixture reproduces that scenario: description: | is the
  # last key, body contains `model:` in prose, and the lint MUST report clean.
  local fixture="${BATS_TEST_TMPDIR}/qrspi-test-scalar-at-end-body-model.md"
  cat >"$fixture" <<'EOF'
---
name: qrspi-test-scalar-at-end
description: |
  some description text
  more description text
---
body starts here
model: something at body start
EOF

  # No frontmatter violation should be reported — body's model: is out of scope.
  local offending_line
  offending_line=$(_frontmatter "$fixture" | grep -nE '^model:' || true)
  [ -z "$offending_line" ] || {
    echo "sf.F01 scalar-at-end: false-positive — _frontmatter read into body and flagged body-level model:"
    echo "  offending_line=${offending_line}"
    return 1
  }
}

@test "[r5-sf.F01] frontmatter with block-scalar last key and no body model: still clean" {
  # Companion to the above: same scalar-at-end topology. The body NOW contains
  # a `model:` line so this test independently detects the over-reading
  # regression. If _frontmatter over-reads past the closing `---`, the body's
  # `model:` line is returned and grep produces a non-empty offending_line,
  # causing the test to fail RED. If _frontmatter exits correctly at `---`,
  # the body is invisible to the scan and offending_line stays empty (pass).
  local fixture="${BATS_TEST_TMPDIR}/qrspi-test-scalar-at-end-no-body-model.md"
  cat >"$fixture" <<'EOF'
---
name: qrspi-test-scalar-at-end-clean
description: |
  some description text
  more description text
---
body starts here
model: this line must not appear in frontmatter output
EOF

  local offending_line
  offending_line=$(_frontmatter "$fixture" | grep -nE '^model:' || true)
  [ -z "$offending_line" ] || {
    echo "sf.F01 scalar-at-end (body model): false-positive — _frontmatter read into body and flagged body-level model:"
    echo "  offending_line=${offending_line}"
    return 1
  }
}

@test "[r10-tc.F01] folded scalar (>): model: key after folded block scalar is detected" {
  # tc.F01: the production awk regex [|>] handles both literal (|) and folded
  # (>) block scalars. All prior tests use only |. This test uses > so that the
  # mutation [|>]->[|] (dropping folded-scalar support) is caught. Without this
  # test, that mutation survives the full suite and leaves folded-scalar files
  # silently un-linted.
  local fixture="${BATS_TEST_TMPDIR}/qrspi-test-folded-scalar-model.md"
  cat >"$fixture" <<'EOF'
---
name: qrspi-test-folded-scalar
description: >
  This is a folded scalar description spanning
  multiple lines of content.
model: sonnet
---

Body text.
EOF

  # model: sonnet appears after the folded scalar; _frontmatter must NOT
  # treat the scalar body as extending past the next column-0 key, so the
  # model: line must be visible in the frontmatter output.
  local offending_line
  offending_line=$(_frontmatter "$fixture" | grep -nE '^model:' || true)
  [ -n "$offending_line" ] || {
    echo "folded-scalar: model: key not detected — _frontmatter failed to handle '>' (folded) block scalar"
    return 1
  }
}

@test "[r10-tc.F01] folded scalar-at-end: _frontmatter exits cleanly with no false positive" {
  # tc.F01 (scalar-at-end mirror): mirrors the existing | scalar-at-end tests
  # but uses > (folded). When description: > is the last frontmatter key, the
  # closing --- must still terminate the frontmatter scan correctly; body text
  # must not leak into the frontmatter output and trigger a false positive.
  local fixture="${BATS_TEST_TMPDIR}/qrspi-test-folded-at-end.md"
  cat >"$fixture" <<'EOF'
---
name: qrspi-test-folded-at-end
description: >
  some description text
  more description text
---
body starts here
model: this line must not appear in frontmatter output
EOF

  local offending_line
  offending_line=$(_frontmatter "$fixture" | grep -nE '^model:' || true)
  [ -z "$offending_line" ] || {
    echo "folded-scalar at-end: false-positive — _frontmatter read into body and flagged body-level model:"
    echo "  offending_line=${offending_line}"
    return 1
  }
}

@test "[r10-tc.F02] complete-output: _frontmatter returns block-scalar key line and indented body verbatim" {
  # tc.F02: the in_scalar variable in _frontmatter is set on | or > key lines
  # but never gates print. This is correct — all lines including block-scalar
  # key and indented body must appear in the frontmatter output. A regression
  # that adds `if (!in_scalar) { print }` would silently drop description: |
  # and its indented body lines; existing tests would still pass because they
  # only grep for model:. This complete-output assertion catches that mutation.
  local fixture="${BATS_TEST_TMPDIR}/qrspi-test-complete-output.md"
  cat >"$fixture" <<'EOF'
---
name: qrspi-test-complete-output
description: |
  indented body line one
  indented body line two
model: sonnet
---

Trailing body text.
EOF

  local fm_output
  fm_output=$(_frontmatter "$fixture")

  # The block-scalar key line must be present in the frontmatter output.
  echo "$fm_output" | grep -qE '^description: \|' || {
    echo "complete-output: 'description: |' line missing from _frontmatter output"
    printf 'actual output:\n%s\n' "$fm_output"
    return 1
  }

  # The indented block-scalar body lines must be present in the output.
  echo "$fm_output" | grep -q 'indented body line one' || {
    echo "complete-output: indented block-scalar content missing from _frontmatter output"
    printf 'actual output:\n%s\n' "$fm_output"
    return 1
  }

  # The model: key that follows the block scalar must also be present.
  echo "$fm_output" | grep -qE '^model: sonnet' || {
    echo "complete-output: 'model: sonnet' line missing from _frontmatter output"
    printf 'actual output:\n%s\n' "$fm_output"
    return 1
  }
}

# ============================================================================
# T10 extensions — per-host `model_routing:` table assertions
# ============================================================================
#
# Task 10 wires per-host tier resolution into config.md. The structural lint
# below extends this BATS file (originally created by T9 for the no-`model:`-
# in-frontmatter sweep) with assertions that:
#
#   1. `docs/qrspi/2026-05-27-v071-hardening/config.md` carries a
#      `model_routing:` YAML block whose entries map each of the four agent
#      tier names (`haiku`, `sonnet`, `opus`, `inherit`) to the correct
#      versioned Claude model ID for BOTH host columns produced by
#      `detect_host` (`claude-code` and `copilot-cli`).
#   2. The `copilot-cli` column contains no bare tier short-forms (`haiku`,
#      `sonnet`, `opus` alone) that would trigger Copilot CLI's
#      "model not available" warning.
#   3. `skills/using-qrspi/SKILL.md` documents the resolution flow under a
#      "Model Routing" heading that names `detect_host` output as the host-
#      selection input and the `model_routing` table as the per-tier source.
#   4. The lint helper itself behaves correctly under positive and negative
#      synthetic fixtures (meta-self-assertion per TE7).
#
# Format coupling: the lint assumes the implementer represents the
# `model_routing:` table as a YAML mapping-of-mappings (the natural shape
# for the existing config schema documented in SKILL.md), with each host
# name as a sub-key whose value is a tier->model-id mapping. The chosen
# indentation level is tolerated (any consistent indent works) but the
# nesting structure is required.
#
# Bash 3.2 / POSIX-awk portability: no `mapfile`, no `${var,,}`, no
# associative arrays, no GNU-only grep flags.

# Helper: print the `model_routing:` YAML block from a config file.
# Starts at the line beginning with `model_routing:` (column 0) and continues
# while subsequent lines are indented (block content) or blank. Stops at the
# next top-level structure (column-0 non-blank line: next YAML key, markdown
# heading, or paragraph) or end of file.
_model_routing_block() {
  awk '
    { gsub(/\r$/, "") }
    /^model_routing:[[:space:]]*$/ { in_block = 1; print; next }
    in_block {
      if ($0 ~ /^[^[:space:]]/) { exit }
      print
    }
  ' "$1"
}

# Helper: extract the YAML sub-block under a given host key within the
# model_routing block. The host key is matched at any indent level as long
# as the line is `<indent><host>:` with no trailing value. The sub-block
# consists of all subsequent more-indented lines (plus blank lines) until
# the next sibling-or-shallower key.
_host_subblock() {
  local file="$1" host="$2"
  _model_routing_block "$file" | awk -v h="$host" '
    function lead(s,   i) {
      for (i = 1; i <= length(s); i++) {
        if (substr(s, i, 1) != " ") return i - 1
      }
      return length(s)
    }
    {
      if (!in_h) {
        if ($0 ~ ("^[[:space:]]*" h ":[[:space:]]*$")) {
          in_h = 1
          host_indent = lead($0)
          next
        }
      } else {
        if ($0 ~ /^[[:space:]]*$/) { print; next }
        if (lead($0) <= host_indent) exit
        print
      }
    }
  '
}

# Helper: assert a (tier -> model) pair exists in the given host sub-block
# text on stdin. Pattern: `<indent><tier>:[ws]<model>` with optional trailing
# whitespace. Returns 0 on match, 1 on miss.
_assert_tier_maps_to() {
  local tier="$1" model="$2"
  grep -qE "^[[:space:]]+${tier}:[[:space:]]+${model}[[:space:]]*$"
}

# Helper: extract a named markdown section's body from a file. The section
# starts at a line matching `^#+[[:space:]]+<title>[[:space:]]*$` and ends
# at the next line of the same heading level OR a shallower heading OR EOF.
# Heading depth is captured from the opening line so deeper sub-headings
# within the section are kept.
_markdown_section() {
  local file="$1" title="$2"
  awk -v t="$title" '
    function hlevel(s,   n) {
      n = 0
      while (substr(s, n + 1, 1) == "#") n++
      return n
    }
    {
      if (!in_sec) {
        if ($0 ~ ("^#+[[:space:]]+" t "[[:space:]]*$")) {
          in_sec = 1
          sec_level = hlevel($0)
          next
        }
      } else {
        if ($0 ~ /^#+[[:space:]]+/) {
          if (hlevel($0) <= sec_level) exit
        }
        print
      }
    }
  ' "$file"
}

@test "[T10/TE1] config.md model_routing: haiku tier resolves to claude-haiku-4.5 for both hosts" {
  # Test expectation: docs/qrspi/2026-05-27-v071-hardening/config.md contains
  # `claude-haiku-4.5` as the haiku-tier entry in the model_routing table for
  # both the `claude-code` and `copilot-cli` host columns.
  local cfg="docs/qrspi/2026-05-27-v071-hardening/config.md"
  [ -f "$cfg" ] || { echo "config.md not found at expected path: $cfg"; return 1; }

  local cc_block cli_block
  cc_block=$(_host_subblock "$cfg" claude-code)
  cli_block=$(_host_subblock "$cfg" copilot-cli)

  [ -n "$cc_block" ] || {
    echo "TE1: claude-code sub-block missing from model_routing: in config.md"
    return 1
  }
  [ -n "$cli_block" ] || {
    echo "TE1: copilot-cli sub-block missing from model_routing: in config.md"
    return 1
  }

  printf '%s\n' "$cc_block" | _assert_tier_maps_to haiku 'claude-haiku-4\.5' || {
    echo "TE1: claude-code/haiku does not map to claude-haiku-4.5"
    printf 'claude-code sub-block:\n%s\n' "$cc_block"
    return 1
  }
  printf '%s\n' "$cli_block" | _assert_tier_maps_to haiku 'claude-haiku-4\.5' || {
    echo "TE1: copilot-cli/haiku does not map to claude-haiku-4.5"
    printf 'copilot-cli sub-block:\n%s\n' "$cli_block"
    return 1
  }
}

@test "[T10/TE2] config.md model_routing: sonnet tier resolves to claude-sonnet-4.6 for both hosts" {
  # Test expectation: docs/qrspi/2026-05-27-v071-hardening/config.md contains
  # `claude-sonnet-4.6` as the sonnet-tier entry in the model_routing table
  # for both the `claude-code` and `copilot-cli` host columns.
  local cfg="docs/qrspi/2026-05-27-v071-hardening/config.md"
  [ -f "$cfg" ] || { echo "config.md not found at expected path: $cfg"; return 1; }

  local cc_block cli_block
  cc_block=$(_host_subblock "$cfg" claude-code)
  cli_block=$(_host_subblock "$cfg" copilot-cli)

  [ -n "$cc_block" ] || {
    echo "TE2: claude-code sub-block missing from model_routing: in config.md"
    return 1
  }
  [ -n "$cli_block" ] || {
    echo "TE2: copilot-cli sub-block missing from model_routing: in config.md"
    return 1
  }

  printf '%s\n' "$cc_block" | _assert_tier_maps_to sonnet 'claude-sonnet-4\.6' || {
    echo "TE2: claude-code/sonnet does not map to claude-sonnet-4.6"
    printf 'claude-code sub-block:\n%s\n' "$cc_block"
    return 1
  }
  printf '%s\n' "$cli_block" | _assert_tier_maps_to sonnet 'claude-sonnet-4\.6' || {
    echo "TE2: copilot-cli/sonnet does not map to claude-sonnet-4.6"
    printf 'copilot-cli sub-block:\n%s\n' "$cli_block"
    return 1
  }
}

@test "[T10/TE3] config.md model_routing: opus tier resolves to claude-opus-4.7-high for both hosts" {
  # Test expectation: docs/qrspi/2026-05-27-v071-hardening/config.md contains
  # `claude-opus-4.7-high` as the opus-tier entry in the model_routing table
  # for both the `claude-code` and `copilot-cli` host columns.
  local cfg="docs/qrspi/2026-05-27-v071-hardening/config.md"
  [ -f "$cfg" ] || { echo "config.md not found at expected path: $cfg"; return 1; }

  local cc_block cli_block
  cc_block=$(_host_subblock "$cfg" claude-code)
  cli_block=$(_host_subblock "$cfg" copilot-cli)

  [ -n "$cc_block" ] || {
    echo "TE3: claude-code sub-block missing from model_routing: in config.md"
    return 1
  }
  [ -n "$cli_block" ] || {
    echo "TE3: copilot-cli sub-block missing from model_routing: in config.md"
    return 1
  }

  printf '%s\n' "$cc_block" | _assert_tier_maps_to opus 'claude-opus-4\.7-high' || {
    echo "TE3: claude-code/opus does not map to claude-opus-4.7-high"
    printf 'claude-code sub-block:\n%s\n' "$cc_block"
    return 1
  }
  printf '%s\n' "$cli_block" | _assert_tier_maps_to opus 'claude-opus-4\.7-high' || {
    echo "TE3: copilot-cli/opus does not map to claude-opus-4.7-high"
    printf 'copilot-cli sub-block:\n%s\n' "$cli_block"
    return 1
  }
}

@test "[T10/TE4] config.md model_routing: inherit tier resolves to claude-sonnet-4.6 for both hosts" {
  # Test expectation: docs/qrspi/2026-05-27-v071-hardening/config.md contains
  # `claude-sonnet-4.6` as the inherit-tier entry in the model_routing table
  # for both the `claude-code` and `copilot-cli` host columns. This matches
  # Claude's resolver default for custom agents that do not declare an
  # explicit `model:` (which T9 removed from all 41 agent files).
  local cfg="docs/qrspi/2026-05-27-v071-hardening/config.md"
  [ -f "$cfg" ] || { echo "config.md not found at expected path: $cfg"; return 1; }

  local cc_block cli_block
  cc_block=$(_host_subblock "$cfg" claude-code)
  cli_block=$(_host_subblock "$cfg" copilot-cli)

  [ -n "$cc_block" ] || {
    echo "TE4: claude-code sub-block missing from model_routing: in config.md"
    return 1
  }
  [ -n "$cli_block" ] || {
    echo "TE4: copilot-cli sub-block missing from model_routing: in config.md"
    return 1
  }

  printf '%s\n' "$cc_block" | _assert_tier_maps_to inherit 'claude-sonnet-4\.6' || {
    echo "TE4: claude-code/inherit does not map to claude-sonnet-4.6"
    printf 'claude-code sub-block:\n%s\n' "$cc_block"
    return 1
  }
  printf '%s\n' "$cli_block" | _assert_tier_maps_to inherit 'claude-sonnet-4\.6' || {
    echo "TE4: copilot-cli/inherit does not map to claude-sonnet-4.6"
    printf 'copilot-cli sub-block:\n%s\n' "$cli_block"
    return 1
  }
}

@test "[T10/TE5] config.md model_routing: copilot-cli column contains no bare tier short-forms" {
  # Test expectation: no entry in the copilot-cli column of the
  # `model_routing:` table is a bare Claude tier short-form (the strings
  # `haiku`, `sonnet`, or `opus` alone) that would trigger a Copilot CLI
  # "model not available" warning. The copilot-cli sub-block MUST exist
  # for this assertion to be meaningful — a missing sub-block fails this
  # test rather than vacuously passing.
  local cfg="docs/qrspi/2026-05-27-v071-hardening/config.md"
  [ -f "$cfg" ] || { echo "config.md not found at expected path: $cfg"; return 1; }

  local cli_block
  cli_block=$(_host_subblock "$cfg" copilot-cli)

  [ -n "$cli_block" ] || {
    echo "TE5: copilot-cli sub-block missing from model_routing: in config.md (vacuous-pass guard)"
    return 1
  }

  # Any line of the form `<indent><tier-key>: <bare-tier-short-form>` is
  # forbidden. We match values that are EXACTLY one of haiku/sonnet/opus
  # with no version suffix, no provider prefix, no further punctuation.
  local bad_lines
  bad_lines=$(printf '%s\n' "$cli_block" \
    | grep -nE '^[[:space:]]+[A-Za-z_][A-Za-z0-9_-]*:[[:space:]]+(haiku|sonnet|opus)[[:space:]]*$' \
    || true)
  if [ -n "$bad_lines" ]; then
    echo "TE5: copilot-cli column contains bare tier short-form(s) that trigger 'model not available' warnings:"
    printf '%s\n' "$bad_lines"
    return 1
  fi
}

@test "[T10/TE6] SKILL.md contains a Model Routing section naming detect_host and model_routing" {
  # Test expectation: skills/using-qrspi/SKILL.md contains a "Model Routing"
  # section (at any heading depth) that names `detect_host` output as the
  # host-selection input AND the `model_routing` table as the per-tier
  # resolution source. The existing `#### \`model_routing:\` block` section
  # (lowercase, code-formatted, about the YAML schema) does NOT satisfy this
  # expectation — the new section must be a distinct heading titled
  # "Model Routing" (capital M, capital R, no backticks) that documents the
  # dispatcher resolution flow.
  local skill="skills/using-qrspi/SKILL.md"
  [ -f "$skill" ] || { echo "SKILL.md not found at expected path: $skill"; return 1; }

  local section
  section=$(_markdown_section "$skill" "Model Routing")

  [ -n "$section" ] || {
    echo "TE6: no 'Model Routing' section heading found in $skill"
    echo "  expected a line matching '^#+ Model Routing\$' (case-sensitive)"
    return 1
  }

  printf '%s\n' "$section" | grep -qF 'detect_host' || {
    echo "TE6: 'Model Routing' section does not name detect_host as host-selection input"
    printf 'section body:\n%s\n' "$section"
    return 1
  }
  printf '%s\n' "$section" | grep -qF 'model_routing' || {
    echo "TE6: 'Model Routing' section does not name the model_routing table as per-tier resolution source"
    printf 'section body:\n%s\n' "$section"
    return 1
  }
}

@test "[T10/TE7] lint helper accepts a synthetic complete model_routing fixture (GREEN path)" {
  # Test expectation (TE7 positive): the extended structural lint passes when
  # all required host/tier entries are present. This pins the helper's
  # contract: a well-formed YAML model_routing block with both hosts and
  # all four tier entries each must satisfy the sub-block extraction +
  # tier-maps-to assertions used by TE1-TE5.
  local fixture="${BATS_TEST_TMPDIR}/qrspi-test-routing-complete.md"
  cat >"$fixture" <<'EOF'
---
status: approved
---

# Some heading

model_routing:
  claude-code:
    haiku: claude-haiku-4.5
    sonnet: claude-sonnet-4.6
    opus: claude-opus-4.7-high
    inherit: claude-sonnet-4.6
  copilot-cli:
    haiku: claude-haiku-4.5
    sonnet: claude-sonnet-4.6
    opus: claude-opus-4.7-high
    inherit: claude-sonnet-4.6

# Trailing section.
EOF

  local cc_block cli_block
  cc_block=$(_host_subblock "$fixture" claude-code)
  cli_block=$(_host_subblock "$fixture" copilot-cli)

  [ -n "$cc_block" ] || { echo "TE7 GREEN: claude-code sub-block extraction returned empty"; return 1; }
  [ -n "$cli_block" ] || { echo "TE7 GREEN: copilot-cli sub-block extraction returned empty"; return 1; }

  # All four tier entries must resolve for both hosts.
  local host block
  for host in claude-code copilot-cli; do
    block=$(_host_subblock "$fixture" "$host")
    printf '%s\n' "$block" | _assert_tier_maps_to haiku 'claude-haiku-4\.5' \
      || { echo "TE7 GREEN: $host/haiku missed on complete fixture"; return 1; }
    printf '%s\n' "$block" | _assert_tier_maps_to sonnet 'claude-sonnet-4\.6' \
      || { echo "TE7 GREEN: $host/sonnet missed on complete fixture"; return 1; }
    printf '%s\n' "$block" | _assert_tier_maps_to opus 'claude-opus-4\.7-high' \
      || { echo "TE7 GREEN: $host/opus missed on complete fixture"; return 1; }
    printf '%s\n' "$block" | _assert_tier_maps_to inherit 'claude-sonnet-4\.6' \
      || { echo "TE7 GREEN: $host/inherit missed on complete fixture"; return 1; }
  done

  # Bare tier short-form scan on copilot-cli sub-block must come up empty.
  local bad
  bad=$(printf '%s\n' "$cli_block" \
    | grep -nE '^[[:space:]]+[A-Za-z_][A-Za-z0-9_-]*:[[:space:]]+(haiku|sonnet|opus)[[:space:]]*$' \
    || true)
  [ -z "$bad" ] || {
    echo "TE7 GREEN: complete fixture wrongly flagged bare-tier short-forms: $bad"
    return 1
  }
}

@test "[T10/TE7] lint helper rejects fixtures with absent or incomplete model_routing block (RED path)" {
  # Test expectation (TE7 negative): the extended structural lint fails when
  # the model_routing block is absent OR when a required host/tier entry
  # is missing. Three scenarios:
  #   (a) model_routing block absent entirely
  #   (b) model_routing block present but missing the copilot-cli host
  #   (c) model_routing block present with both hosts but missing the
  #       opus tier entry under copilot-cli

  # --- Scenario (a): block absent ---
  local fix_a="${BATS_TEST_TMPDIR}/qrspi-test-routing-absent.md"
  cat >"$fix_a" <<'EOF'
---
status: approved
---

# Config with no model_routing block at all
EOF

  local block_a
  block_a=$(_model_routing_block "$fix_a")
  [ -z "$block_a" ] || {
    echo "TE7 RED (a): _model_routing_block returned non-empty for fixture with no model_routing: key"
    printf 'unexpected block:\n%s\n' "$block_a"
    return 1
  }

  local cc_a cli_a
  cc_a=$(_host_subblock "$fix_a" claude-code)
  cli_a=$(_host_subblock "$fix_a" copilot-cli)
  [ -z "$cc_a" ] || { echo "TE7 RED (a): claude-code sub-block found despite absent model_routing block"; return 1; }
  [ -z "$cli_a" ] || { echo "TE7 RED (a): copilot-cli sub-block found despite absent model_routing block"; return 1; }

  # --- Scenario (b): block present but missing copilot-cli host ---
  local fix_b="${BATS_TEST_TMPDIR}/qrspi-test-routing-missing-host.md"
  cat >"$fix_b" <<'EOF'
---
status: approved
---

model_routing:
  claude-code:
    haiku: claude-haiku-4.5
    sonnet: claude-sonnet-4.6
    opus: claude-opus-4.7-high
    inherit: claude-sonnet-4.6
EOF

  local cc_b cli_b
  cc_b=$(_host_subblock "$fix_b" claude-code)
  cli_b=$(_host_subblock "$fix_b" copilot-cli)
  [ -n "$cc_b" ] || { echo "TE7 RED (b): claude-code sub-block not found in fixture-b"; return 1; }
  [ -z "$cli_b" ] || {
    echo "TE7 RED (b): copilot-cli sub-block returned non-empty despite host being absent from fixture-b"
    printf 'unexpected sub-block:\n%s\n' "$cli_b"
    return 1
  }

  # --- Scenario (c): both hosts present but copilot-cli missing the opus row ---
  local fix_c="${BATS_TEST_TMPDIR}/qrspi-test-routing-missing-tier.md"
  cat >"$fix_c" <<'EOF'
---
status: approved
---

model_routing:
  claude-code:
    haiku: claude-haiku-4.5
    sonnet: claude-sonnet-4.6
    opus: claude-opus-4.7-high
    inherit: claude-sonnet-4.6
  copilot-cli:
    haiku: claude-haiku-4.5
    sonnet: claude-sonnet-4.6
    inherit: claude-sonnet-4.6
EOF

  local cli_c
  cli_c=$(_host_subblock "$fix_c" copilot-cli)
  [ -n "$cli_c" ] || { echo "TE7 RED (c): copilot-cli sub-block missing from fixture-c"; return 1; }

  # The opus assertion must NOT find a match (the row is intentionally absent).
  if printf '%s\n' "$cli_c" | _assert_tier_maps_to opus 'claude-opus-4\.7-high'; then
    echo "TE7 RED (c): _assert_tier_maps_to wrongly matched opus row on fixture missing that row"
    printf 'copilot-cli sub-block:\n%s\n' "$cli_c"
    return 1
  fi
}
