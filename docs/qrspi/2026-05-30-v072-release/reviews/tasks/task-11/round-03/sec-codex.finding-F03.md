---
finding_id: R3-F03
reviewer: sec-codex
severity: low
change_type: correctness
referenced_files:
  - scripts/run-codex-review.sh
---

# F03 — Unbounded stdout capture enables memory-exhaustion DoS

**File:** scripts/run-codex-review.sh lines 809-813

```bash
_dispatch_stdout="$( set -o pipefail; compose_prompt | bash "$DISPATCHER" "${DISPATCHER_ARGS[@]}" )" \
  || _dispatch_exit=$?
```

Entire dispatcher stdout is buffered into a shell variable with no size cap. A malicious or compromised dispatcher (or an upstream service it relays from) emitting hundreds of MB of stdout causes high memory use and potential OOM kill of the orchestrator process.

**Impact:** denial-of-service of the dispatch wrapper / orchestrator process.

**Fix sketch:** stream dispatcher stdout through a `head -c <cap>` (e.g., 4MB cap) before assignment, or write to a tempfile with `truncate` after a size cap and re-read. Bound the cap based on realistic JOB_ID payload size (a few KB).

**Disposition:** low severity — practical exposure is limited (dispatchers are repo-controlled scripts, not arbitrary remote code). File as backlog if not addressed in T11; record decision in fan-in.
