---
finding_id: R3-F02
severity: medium
change_type: test-coverage
referenced_files:
  - tests/unit/test-dispatch-agent.bats
---
The new round-3 e2e test `task-20 end-to-end: --agents batched dispatch of third-party tag records non-empty job_id in manifest` (test-dispatch-agent.bats:1110-1157) only asserts the manifest has a non-empty `job_id`. It does NOT invoke `scripts/await-round.sh` against the manifest, so it cannot detect R3-F01 (the drain rejection) or any future regression in the actual end-to-end async chain. The test stops one step before the chain breaks.

Existing tests `test-await-round.bats:64-105` use stub-based fixtures with absolute paths in their await_cmd/split_cmd, bypassing the realpath-against-DISPATCH_CWD path that production manifests trigger. Coverage gap for the dispatch-agent → await-round seam.

**Fix path:**
Extend the round-3 e2e test (or add a sibling) to:
1. Run dispatch-agent --agents (already present) — produces real-shape manifest.
2. Drive `scripts/await-round.sh --round-dir <d>` against that manifest.
3. Assert rc=0 AND `<round-dir>/.dispatch/<tag>.raw` exists with the stub marker AND `.round-complete.json` reports the entry as drained-with-findings.

This will fail against `4ab29a1` HEAD (proving falsifiability for R3-F01) and pass after R3-F01's manifest-emission fix lands.
