---
finding_id: R4-F02
reviewer: silent-failure-claude
round: 4
severity: medium
change_type: clarity
referenced_files:
  - tests/unit/test-dispatch-agent.bats
status: open
---

# Dispatch `$WRAPPER` call silences stderr and does not capture exit code

**File/lines:** `tests/unit/test-dispatch-agent.bats:1206-1212`

```bash
"$WRAPPER" \
  --step spec --round 1 --output-dir "$round_dir" \
  --artifact "$TMP_DIR/plan.md" \
  --agents "spec-codex=$REPO_ROOT/agents/qrspi-spec-reviewer.md" \
  >/dev/null 2>&1
```

Both stdout and stderr to /dev/null; no `|| rc=$?` capture. If WRAPPER exits non-zero (agent file missing, --step parse error, etc.), bats's ERR trap fires at L1212 with no diagnostic. Subsequent `[ -f "$manifest" ]` then fails as a downstream symptom. This is the test's setup step — a silent failure here cascades through every later assertion.

**Suggested fix:** capture rc + stderr to tmpfile; emit stderr on rc!=0 before returning.
