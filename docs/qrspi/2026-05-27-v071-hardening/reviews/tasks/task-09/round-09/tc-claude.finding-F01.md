# tc-claude · Finding F01 · Round 09

**Task:** T9 – Remove `model:` from agent frontmatter  
**Artifact:** `tests/unit/test-agent-frontmatter-no-model.bats`  
**Commit under review:** cumulative diff to d889166  
**Change type:** coverage gap  
**Severity:** medium

---

## Description — Folded block scalar (`>`) is never exercised by a test fixture

### Location
`tests/unit/test-agent-frontmatter-no-model.bats`, line 42:

```awk
if (/:[[:space:]]*[|>][[:space:]]*$/) { in_scalar = 1 }
```

### What the code covers vs. what tests cover

The `_frontmatter` helper's block-scalar branch explicitly handles **both** the
literal (`|`) and folded (`>`) YAML block scalar indicators in a single regex.

The test suite covers the `|` path with the fixture at line 191–200:

```
description: |
  ---
model: sonnet
```

There is **no fixture** that uses `>`:

```
description: >
  some
  folded content
model: sonnet
```

### Why this matters

YAML permits either indicator interchangeably for block scalars in agent
frontmatter. A regression that broke only the `>` branch — for example, a
typo that changed `[|>]` to `[|]`, or a re-implementation that hard-coded the
literal indicator — would leave the `|` test passing while the `>` case silently
passes through an incorrect code path.

The `in_scalar` flag is set under both indicators by the same branch, so a
`>`-only regression would require the regex to be incorrect in a very targeted
way; however, the complete absence of a `>` fixture means the branch is not
independently verified and any such regression would produce a green suite.

### Concrete undetected mutation

```diff
-  if (/:[[:space:]]*[|>][[:space:]]*$/) { in_scalar = 1 }
+  if (/:[[:space:]]*[|][[:space:]]*$/)  { in_scalar = 1 }
```

All 8 current tests continue to pass after this mutation.

### Recommended fix

Add a dedicated fixture that uses a folded block scalar (`>`) with a `model:`
key after it, and assert the violation is detected:

```bash
@test "[agent-frontmatter-no-model] folded-block-scalar: model: key detected after > block scalar" {
  local fixture="${BATS_TEST_TMPDIR}/qrspi-test-folded-scalar-model.md"
  cat >"$fixture" <<'EOF'
---
name: qrspi-test-folded
description: >
  folded description text
model: sonnet
---

Body text.
EOF

  local offending_line
  offending_line=$(_frontmatter "$fixture" | grep -nE '^model:' || true)
  [ -n "$offending_line" ] || {
    echo "folded-scalar: model: key not detected — _frontmatter exited prematurely"
    return 1
  }
}
```

A companion scope-fence test — a `>` block scalar as the **last** frontmatter
key with a body `model:` line — would also guard the scalar-at-end path for
the folded variant:

```bash
@test "[r5-sf.F01] folded-block-scalar last key: body model: not falsely flagged" {
  local fixture="${BATS_TEST_TMPDIR}/qrspi-test-folded-at-end.md"
  cat >"$fixture" <<'EOF'
---
name: qrspi-test-folded-at-end
description: >
  folded description text
---
body starts here
model: body-only, must not appear in frontmatter output
EOF

  local offending_line
  offending_line=$(_frontmatter "$fixture" | grep -nE '^model:' || true)
  [ -z "$offending_line" ] || {
    echo "folded-scalar-at-end: false-positive — _frontmatter read into body"
    echo "  offending_line=${offending_line}"
    return 1
  }
}
```
