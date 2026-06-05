---
finding_id: R2-F02
severity: medium
change_type: correctness
artifact: code
round: 2
reviewer: silent-failure-codex
model: gpt-5.3-codex
referenced_files:
  - tests/acceptance/v07-phase1/test-phase1-acceptance.bats#L1585
  - tests/acceptance/v07-phase1/test-phase1-acceptance.bats#L1590
---

# AC8 grep exit-code semantics silently pass on file-missing

**Location:** AC8 (`[reviewer-model-audit AC8]`) at `tests/acceptance/v07-phase1/test-phase1-acceptance.bats:1585,1590`.

**Defect:** The `grep -qF` exit codes are:
- 0 = pattern found
- 1 = pattern not found
- 2 = file error (missing, unreadable, etc.)

The test uses the pattern `if grep -qF 'verified.md' "$file"; then FAIL_message; fi` — which correctly fails on "found" (exit 0) and passes on "not found" (exit 1). BUT exit 2 (file missing or unreadable) ALSO takes the "not-found" branch and silently passes.

If `agents/qrspi-finding-verifier.md` or `scripts/verifier-fan-in.sh` is renamed, moved, or deleted in a future refactor, AC8 will report PASS — exactly the regression scenario the test was designed to catch (drift in the verifier or fan-in script).

**Suggested fix:** Add a precondition assertion that the target files exist before greppng:

```bash
[ -f "$REPO_ROOT/agents/qrspi-finding-verifier.md" ] \
  || { echo "AC8 precondition failed: agents/qrspi-finding-verifier.md missing"; return 1; }
[ -f "$REPO_ROOT/scripts/verifier-fan-in.sh" ] \
  || { echo "AC8 precondition failed: scripts/verifier-fan-in.sh missing"; return 1; }
```

Alternatively, distinguish the grep exit code explicitly:

```bash
grep -qF 'verified.md' "$REPO_ROOT/agents/qrspi-finding-verifier.md"
local rc=$?
case "$rc" in
  0) echo "verifier agent body references 'verified.md' — aggregate-header output target leaked"; return 1 ;;
  1) ;;  # pattern not found — pass
  *) echo "AC8 grep failed against agents/qrspi-finding-verifier.md (rc=$rc)"; return 1 ;;
esac
```
