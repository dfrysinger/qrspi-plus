# sf-claude · Finding F02 · Round 08

**Task:** T9 – Remove `model:` from agent frontmatter  
**Artifact:** `tests/unit/test-agent-frontmatter-no-model.bats`  
**Commit under review:** a73ecb8 (b431a7f..a73ecb8)  
**Change type:** correctness (pre-existing; not introduced by R7)  
**Severity:** low

---

## Description — `sweep-one-file.sh` inline `_frontmatter` is the pre-fix stub

### Location
`tests/unit/test-agent-frontmatter-no-model.bats`, lines 133–135 (inside the `[…per-file failure message…]` test):

```bash
_frontmatter() {
  awk '/^---$/{n++;if(n==1){next}if(n==2){exit}}n==1{print}' "$1"
}
```

### What this is
The message-shape test (line 97–159) dynamically writes a `sweep-one-file.sh` script into `$BATS_TEST_TMPDIR` and `run`s it against a fixture. To do so it embeds a copy of `_frontmatter` inline in the script. That embedded copy is the **original, unfixed** version of the helper — it lacks all three fix layers that the production helper (lines 30–47) now applies:

| Fix layer | Production helper (lines 30–47) | Embedded stub (line 134) |
|---|---|---|
| CRLF stripping | `gsub(/\r$/, "")` | ✗ absent |
| Block-scalar tracking | `in_scalar` flag, `/:[[:space:]]*[\|>]…/` | ✗ absent |
| Scalar-at-end reset | `in_scalar = 0` before `n++` at `---` | ✗ absent |

### Silent-failure scenario
The test's stated purpose is **only message-shape verification** — that the rendered output string includes the offending file path and the `"forbidden top-level frontmatter key 'model:'"` marker. The current fixture (lines 112–121) is a plain LF-terminated file with `model: sonnet` in simple frontmatter (no block scalars). The stub's missing fixes are irrelevant for this specific fixture, so the test passes correctly today.

However, the divergence becomes a silent-failure risk if:

1. **A CRLF fixture is used** — the stub's `_frontmatter` silently skips the CRLF file's frontmatter entirely (can't match `---\r`), `offending_line` stays empty, the script emits no output, and the message-shape assertions fail. But critically, the test would fail for the *wrong* reason — diagnosed as a message-format regression when it is actually a stub incompleteness.
2. **The stub is read as a reference** — the stub comment at line 131 says it "mirrors the per-file detection + message construction used in the main sweep test." A developer reading this to understand the detection logic encounters an outdated, buggy copy without any indication it is simplified.
3. **A block-scalar fixture is added** — analogous to (1): the stub prematurely exits on an indented `---` inside a block scalar, returning no output, masking the regression the test was meant to catch.

### Why it is in scope despite being pre-existing
The R7 change did not introduce this divergence, but the dispatch explicitly asks to flag any other silent-failure paths in the test code or `_frontmatter`. The stub/production divergence is a standing silent-failure trap in the test suite.

### Recommended fix
Synchronise the stub by either:

**Option A** — Inline the production helper verbatim (preferred; ensures the message-shape test continues to exercise identical logic):
```bash
_frontmatter() {
  awk '
    { gsub(/\r$/, "") }
    /^---$/ {
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
```

**Option B** — Add a comment explicitly marking the stub as intentionally simplified and documenting which fix layers are deliberately omitted (appropriate only if the test scope truly never needs CRLF/block-scalar fixtures).

---

## Edge cases from dispatch — summary

All three edge cases asked about are **handled correctly** by the production `_frontmatter`:

| Edge case | Result |
|---|---|
| Body `model:` at column 0 vs indented | `grep -nE '^model:'` matches only column-0; indented body keys correctly ignored. ✓ |
| Body `model:` adjacent to `---` vs after blank line | `_frontmatter` exits at the second `---`; body position is irrelevant. ✓ |
| Empty body vs single-line body | Same — awk exits unconditionally at second `---` regardless of body content. ✓ |
