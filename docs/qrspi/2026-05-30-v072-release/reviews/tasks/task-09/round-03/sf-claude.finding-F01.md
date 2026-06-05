---
finding_id: R3-F01
reviewer_tag: sf-claude
round: 3
severity: medium
change_type: correctness
referenced_files: [scripts/run-codex-review.sh]
---

# sf-claude F01: jq exit code not checked in emit_dispatch_manifest_entry — silent malformed manifest

**Location:** scripts/run-codex-review.sh lines 611-617 (R2 change)

```bash
local entry
entry="$(jq -nc --arg tag "$REVIEWER_TAG" ... '{tag: $tag, ...}')"
```

R2 replaced `printf -v entry` (always succeeds) with `jq -nc` command substitution. Script runs WITHOUT `set -e` by design (line 49-51). If jq is absent or fails for any reason, bash leaves `entry=""` and execution continues to:

```bash
printf '[\n  %s\n]\n' "$entry" > "$tmp"
```

Producing invalid JSON:
```
[
  
]
```

`mv "$tmp" "$manifest"` then atomically replaces any valid manifest with corruption. Function returns 0; dispatch proceeds. The very audit trail T09 exists to protect is silently corrupted.

**New regression introduced by R2.** The previous `printf -v` could never produce this outcome.

**Why medium not low:** The manifest is the audit trail T09 protects. A silently corrupted manifest is exactly the class of failure T09 guards against. Vector requires jq absent/broken in execution environment (unlikely in normal operation), but the security property is violated silently when it occurs.

**Minimal fix:** Add explicit exit-code guard:
```bash
entry="$(jq -nc ... )" \
  || { echo "error: jq failed building dispatch-manifest entry (jq exit $?)" >&2; exit 1; }
```

Alternative: dependency check `command -v jq` in argument-validation block (296-338) so failure is diagnosed before the call site.

**CONVERGENT with sf-codex F01 — both reviewers raised the same finding independently. Strong signal.**
