---
finding_id: R4-F03
reviewer: silent-failure-claude
round: 4
severity: low
change_type: clarity
referenced_files:
  - tests/unit/test-dispatch-agent.bats
status: open
---

# `jq 2>/dev/null` masks malformed `.round-complete.json` errors

**File/lines:** `tests/unit/test-dispatch-agent.bats:1241-1243`

```bash
entry_status="$(jq -r '.entries[]|select(.tag=="spec-codex")|.status' "$complete_path" 2>/dev/null | head -1)"
```

If round-complete.json is malformed, jq fails non-zero with descriptive error, but `2>/dev/null` discards it AND the pipe-to-head masks the exit code. `entry_status` silently becomes `""` and the assertion fails with no signal differentiating "file structurally wrong" from "drain produced wrong status."

**Suggested fix:** drop `2>/dev/null`; let jq's stderr pass through.
