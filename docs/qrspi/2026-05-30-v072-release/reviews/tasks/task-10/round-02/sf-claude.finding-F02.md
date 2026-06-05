---
finding_id: R2-F02
reviewer_tag: sf-claude
severity: high
change_type: correctness
referenced_files:
  - tests/acceptance/v07-phase1/test-phase1-acceptance.bats#L2023-L2030
  - tests/acceptance/v07-phase1/test-phase1-acceptance.bats#L1880-L1886
---

# AC4 re-introduces the known `grep -q 2>/dev/null` / missing-file silent-pass bug that AC8 already documents

The same test file explicitly documents this anti-pattern at L1880–L1886:

```bash
# NOTE (T09 R2 fix): grep -q exits 2 (not 1) when the file is missing or
# unreadable, but the surrounding if grep -q ...; then ...FAIL...; fi treats
# both exit-1 ("not found") and exit-2 ("file missing") as the not-found
# branch — so a future rename or relocation of either target would
# silently pass this regression-pin. Explicit existence checks close that gap.
[ -f "$REPO_ROOT/agents/qrspi-finding-verifier.md" ] \
  || { echo "AC8 precondition failed: ...missing"; return 1; }
```

The new G28 AC4 test at L2023–L2030 introduces the exact same anti-pattern, and makes it worse by adding `2>/dev/null`:

```bash
if grep -q "spec-claude.finding-F01" "$tmp/kept-findings.txt" 2>/dev/null; then
  echo "sub-threshold clarity-60 finding reached kept-findings.txt — override path leaked"
  return 1
fi
if grep -q "spec-claude.finding-F02" "$tmp/kept-findings.txt" 2>/dev/null; then
  echo "sub-threshold correctness-65 finding reached kept-findings.txt — override path leaked"
  return 1
fi
```

**What goes wrong:** When `verifier-fan-in.sh` exits 0 but never writes `kept-findings.txt`:
- `grep -q "spec-claude.finding-F01" /nonexistent 2>/dev/null` → exits 2
- `if exit-code-2` → body does NOT execute → test silently passes

The `2>/dev/null` additionally suppresses stderr "No such file or directory", leaving zero indication kept-findings.txt was never written.

**Contrast with AC6 (L1922–L1923)** which correctly asserts at-floor findings ARE present:
```bash
grep -q "spec-claude.finding-F01" "$tmp/kept-findings.txt" \
  || { echo "correctness 70 (at floor) was dropped"; return 1; }
```
This fails loudly when the file is absent.

**Severity HIGH because this is a regression-on-known-bug:** The same test file already documents the anti-pattern; AC4 reintroduces it within the same diff.

**Fix (mirror AC8 fix pattern):**
```bash
[ -f "$tmp/kept-findings.txt" ] \
  || { echo "kept-findings.txt was not written by fan-in script"; return 1; }
```
Then remove `2>/dev/null` from both grep calls.

**Convergent with sf-codex R2 F01 (severity MED there).**
