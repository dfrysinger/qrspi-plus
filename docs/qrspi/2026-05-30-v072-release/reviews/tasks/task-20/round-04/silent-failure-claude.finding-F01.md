---
finding_id: R4-F01
reviewer: silent-failure-claude
round: 4
severity: medium
change_type: clarity
referenced_files:
  - tests/unit/test-dispatch-agent.bats
status: open
---

# `await-round.sh` stderr silenced — all diagnostic output lost on test failure

**File/line:** `tests/unit/test-dispatch-agent.bats:1228`

```bash
"$REPO_ROOT/scripts/await-round.sh" --round-dir "$round_dir" >/dev/null 2>&1 || await_rc=$?
```

`2>&1` discards every diagnostic from await-round.sh — the very script this test is designed to exercise. When the test fails at L1249 `[ "$await_rc" -eq 0 ]`, the developer sees a bare line reference with no signal differentiating "path validator rejected relative path" from "companion timed out" from "splitter missing." The falsifying test for the R3-F01 fix loses its primary diagnostic when something regresses.

**Suggested fix:** capture stderr to a tmpfile and echo it on failure (only redirect stdout to /dev/null).
