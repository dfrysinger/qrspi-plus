---
finding_id: R3-F01
reviewer_tag: sf-codex
round: 3
severity: medium
change_type: correctness
referenced_files: [scripts/run-codex-review.sh]
---

# sf-codex F01: jq failure in manifest entry build is ignored

**File:** scripts/run-codex-review.sh:49-51, 612-631
**Category:** Swallowed errors / Silent fallback

**What happens:** The script explicitly runs without `set -e`, then builds `entry` via command substitution:
```bash
entry="$(jq -nc ...)"
```
but never checks that `jq` succeeded. If `jq` is missing or errors, `entry` becomes empty and execution continues into manifest write logic.

**Why this is silent:** The script proceeds as if success, writing a manifest with no valid dispatch object (first write can become effectively `[]`), so the run "succeeds" while dropping required `tag/host/vendor/model` audit metadata.

**Impact:** Fail-open observability gap: dispatch can continue with a malformed/empty manifest trail, making failures hard to detect and post-run provenance inaccurate.
