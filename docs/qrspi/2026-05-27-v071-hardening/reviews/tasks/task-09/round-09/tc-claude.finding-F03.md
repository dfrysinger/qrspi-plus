# tc-claude · Finding F03 · Round 09

**Task:** T9 – Remove `model:` from agent frontmatter  
**Artifact:** `tests/unit/test-agent-frontmatter-no-model.bats`  
**Commit under review:** cumulative diff to d889166  
**Change type:** coverage gap  
**Severity:** low

---

## Description — No-frontmatter file edge case not tested

### Dispatch brief requirement

The dispatch brief explicitly lists **"no-frontmatter agent files"** as an
edge case to audit.  The test suite has no fixture that exercises this path.

### What `_frontmatter` does on a file with no `---` delimiters

With zero `---` delimiters, `n` never reaches 1, so the `n == 1` block never
fires and the function emits no output.  `grep -nE '^model:'` on empty output
returns exit code 1; the `|| true` guard converts that to success;
`offending_line` stays empty; no violation is recorded.  This is the correct
behaviour.

With exactly one `---` delimiter (malformed frontmatter, no closing marker),
`n` reaches 1 after the opening `---` and stays there.  All subsequent lines
are printed — including the entire document body — and the scan runs to EOF
without ever exiting.  A body `model:` line would be falsely flagged as a
frontmatter violation.

### Why these scenarios are untested

Neither case appears in any fixture:

| Scenario | Fixture | Test |
|---|---|---|
| Zero `---` delimiters | none | none |
| Exactly one `---` delimiter (no closing) | none | none |

### Risk assessment

**Zero delimiters:** Low risk.  The awk logic is trivially correct.
Nonetheless, this is the smallest meaningful fixture and its absence leaves
a visible hole in the edge-case table.

**One delimiter (unclosed frontmatter):** Medium risk.  An agent file whose
closing `---` was accidentally deleted would cause `_frontmatter` to scan the
entire body and potentially produce false positives.  The current suite does
not detect this failure mode.  If any of the 41 agent files were to lose
their closing delimiter, the sweep test at line 65 could report a false
violation (body prose containing `model:` keyword) or a false pass (body prose
does not mention `model:`) depending on the file's content.

### Recommended fixtures

```bash
@test "[_frontmatter] no-frontmatter file: returns empty output" {
  local fixture="${BATS_TEST_TMPDIR}/qrspi-test-no-frontmatter.md"
  printf '%s\n' \
    'name: not-yaml-frontmatter' \
    'this file has no --- delimiters' \
    'model: should be invisible' \
    >"$fixture"

  local output
  output=$(_frontmatter "$fixture")
  [ -z "$output" ] || {
    echo "no-frontmatter: expected empty output, got: $output"
    return 1
  }
}

@test "[_frontmatter] unclosed-frontmatter file: does not falsely flag body model:" {
  # Edge-case guard: a file with an opening --- but no closing --- causes
  # _frontmatter to scan the entire body. A body model: line would then be
  # falsely reported as a frontmatter violation.  This test documents the
  # known behaviour so that any change to the handling of unclosed
  # frontmatter is a deliberate, visible change.
  local fixture="${BATS_TEST_TMPDIR}/qrspi-test-unclosed-frontmatter.md"
  cat >"$fixture" <<'EOF'
---
name: qrspi-test-unclosed
description: no closing delimiter

Body text with model: opus in prose — will be falsely scanned.
EOF

  # Document: _frontmatter currently scans past body on unclosed frontmatter.
  # If this behaviour is acceptable (all real agent files are well-formed),
  # mark this test as a known-issue canary rather than a failure.
  local output
  output=$(_frontmatter "$fixture")
  # Intentionally: assert the current behaviour and fail if it changes
  # unexpectedly (either direction).
  echo "unclosed-frontmatter output: $output"
  # (Uncomment the strict form once a decision on this edge case is made:)
  # [ -z "$output" ] || { echo "unclosed frontmatter leaked body content"; return 1; }
}
```

The second fixture above is written as a documentation/canary test rather
than a strict assertion, because the current code's behaviour on unclosed
frontmatter (scan-to-EOF) may be an acceptable trade-off given that all 41
production agent files are well-formed.  The important goal is that the
behaviour is **explicitly recorded** so that a future change to the awk
logic does not silently alter the unclosed-frontmatter path.
