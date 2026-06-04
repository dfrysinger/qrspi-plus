---
finding_id: R2-F03
reviewer_tag: cq-claude
severity: low
change_type: clarity
referenced_files:
  - tests/acceptance/v07-phase1/test-phase1-acceptance.bats#L2025-L2032
---

# Temp-dir cleanup does not run on behavior-half failure

The AC4 test creates a temp dir, runs the fan-in script, then calls `rm -rf "$tmp"` at a fixed point in the body — before the prose-check half. If either of the two early `return 1` branches in the behavior half fires, the function exits before reaching `rm -rf "$tmp"`, leaving the temp directory behind.

```bash
  if grep -q "spec-claude.finding-F01" "$tmp/kept-findings.txt" 2>/dev/null; then
    echo "sub-threshold clarity-60 finding reached kept-findings.txt — override path leaked"
    return 1          # ← $tmp never cleaned
  fi
  if grep -q "spec-claude.finding-F02" "$tmp/kept-findings.txt" 2>/dev/null; then
    echo "sub-threshold correctness-65 finding reached kept-findings.txt — override path leaked"
    return 1          # ← $tmp never cleaned
  fi

  rm -rf "$tmp"       # ← only reached on success path
```

The leak is small (one temp dir per run) and self-repairs on OS reboot, but it is a cleanup discipline gap.

**Fix:** Use a `trap` to guarantee cleanup regardless of exit path:

```bash
local tmp
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
```

Or promote the cleanup into the BATS `teardown()` function if the suite has one.

**Convergent with cq-codex R2-F02.**
