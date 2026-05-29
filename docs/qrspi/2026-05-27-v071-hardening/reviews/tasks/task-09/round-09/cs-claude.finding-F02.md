# cs-claude · Finding F02 · Embedded sweep-script `_frontmatter` diverges from main helper but comment says "mirrors"

**File:** `tests/unit/test-agent-frontmatter-no-model.bats`
**Lines:** 128–141 (worktree lines 128–141; the `sweep-one-file.sh` heredoc)
**Severity:** Polish / Non-blocking
**Category:** Inconsistency / Misleading Comment

---

## What the code does today

Inside the `[agent-frontmatter-no-model] per-file failure message names the
offending file path` test, a one-file sweep script is written to a tmpdir
heredoc.  That script contains its own inline `_frontmatter`:

```bash
_frontmatter() {
  awk '/^---$/{n++;if(n==1){next}if(n==2){exit}}n==1{print}' "$1"
}
```

The comment immediately above it says:

> Mirrors the per-file detection + message construction used in the main sweep
> test. Any regression that drops the "${f}:" path prefix from the real sweep
> must also update this script, breaking the assertion below.

## The problem

The embedded function is **not** a mirror of the real `_frontmatter`. It omits
the `gsub(/\r$/, "")` CRLF fix that the main helper carries.  The two functions
will produce different output if the fixture has CRLF line endings.

In this specific test the fixture is written with a POSIX heredoc (`<<'EOF'`),
so it always has LF-only endings and the divergence is harmless today.  But:

1. The "mirrors" claim is factually false, which erodes trust in comments
   generally.
2. A future maintainer who adds another correctness property to the real
   `_frontmatter` (e.g. a second `gsub` for some other encoding edge case) will
   not know to update the embedded copy because the comment implies they are
   kept in sync.

## Proposed fix

Correct the comment to state the limited scope of the embedded function:

```bash
# Minimal detection + message construction for format-only assertions.
# Fixture is LF-terminated by heredoc construction; CRLF handling omitted
# intentionally to keep this script orthogonal to portability concerns.
_frontmatter() {
  awk '/^---$/{n++;if(n==1){next}if(n==2){exit}}n==1{print}' "$1"
}
```

Alternatively (if Finding F01 is applied), the main helper becomes
equally simple (3 rules, just adds `gsub`), and the embedded copy could
include the `gsub` line at negligible complexity cost, making it a true mirror.
