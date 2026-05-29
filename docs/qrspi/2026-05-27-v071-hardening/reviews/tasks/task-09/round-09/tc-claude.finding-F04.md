# tc-claude · Finding F04 · Round 09

**Task:** T9 – Remove `model:` from agent frontmatter  
**Artifact:** `tests/unit/test-agent-frontmatter-no-model.bats`  
**Commit under review:** cumulative diff to d889166  
**Change type:** test quality / pre-existing (cross-reference sf-claude R08 F02)  
**Severity:** low

---

## Description — Message-shape test embeds a stale `_frontmatter` that diverges from production

> **Pre-existing finding:** sf-claude identified this issue in R08 as
> `sf-claude.finding-F02.md` (severity: low, confirmed unresolved in R09 diff).
> This finding re-raises it from the test-coverage perspective for the
> TC reviewer chain.

### Location
`tests/unit/test-agent-frontmatter-no-model.bats`, lines 133–135:

```bash
_frontmatter() {
  awk '/^---$/{n++;if(n==1){next}if(n==2){exit}}n==1{print}' "$1"
}
```

### Test-coverage dimension (beyond the silent-failure angle)

The message-shape test (`[…per-file failure message names the offending file
path]`, lines 97–159) is the **only test that exercises the main sweep's
per-file detection and message construction in isolation** — using a
controlled fixture instead of real agent files.

However, the `_frontmatter` embedded in `sweep-one-file.sh` is the
**pre-fix one-liner** lacking all three production fix layers:

| Fix layer | Production `_frontmatter` | Embedded stub |
|---|---|---|
| CRLF stripping (`gsub(/\r$/, "")`) | ✓ line 32 | ✗ absent |
| Block-scalar tracking (`in_scalar`) | ✓ lines 42–43 | ✗ absent |
| Scalar-at-end reset (`in_scalar=0` before `n++`) | ✓ line 36 | ✗ absent |

This creates a **test isolation gap**: the message-shape test does not
exercise the production `_frontmatter` code at all.  It exercises an older
version.

### Coverage consequence

If the production `_frontmatter` were refactored — e.g., the `gsub` moved,
or the `n==1` guard restructured — the message-shape test would not detect
whether that refactoring broke message construction for CRLF or block-scalar
inputs, because the embedded stub is entirely separate.

The fix suggested by sf-claude R08 remains the correct resolution:
synchronise the stub with the production helper, or rewrite the
message-shape test to directly call the production `_frontmatter` (which
is already in scope within the same bats file) rather than writing a
separate script.

### Simplest fix

The message-shape test can call the production `_frontmatter` directly
without creating `sweep-one-file.sh` at all, since both are defined in the
same bats file:

```bash
@test "[agent-frontmatter-no-model] per-file failure message names the offending file path" {
  local fixture="${BATS_TEST_TMPDIR}/qrspi-test-frontmatter-msg-shape.md"
  cat >"$fixture" <<'EOF'
---
name: qrspi-test-fixture
model: sonnet
description: "Synthetic fixture for message-shape test"
tools: Read
---

Body text does not affect the lint.
EOF

  # Use the production _frontmatter (defined in this file) directly.
  local offending_line
  offending_line=$(_frontmatter "$fixture" | grep -nE '^model:' || true)

  local rendered_msg=""
  if [ -n "$offending_line" ]; then
    rendered_msg="${fixture}: forbidden top-level frontmatter key 'model:' -> ${offending_line}"
  fi

  [[ "$rendered_msg" == *"$fixture"* ]] || {
    echo "message did not include fixture path; got: $rendered_msg"
    return 1
  }
  [[ "$rendered_msg" == *"forbidden top-level frontmatter key 'model:'"* ]] || {
    echo "message did not include error format text; got: $rendered_msg"
    return 1
  }
}
```

This approach:
- Calls the production `_frontmatter` (all fix layers active)
- Tests the message format directly (same string construction as the real sweep)
- Does not require a subshell script or `run`
- Would catch a CRLF regression in message-format context if the fixture were CRLF-terminated
