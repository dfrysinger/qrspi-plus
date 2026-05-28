---
finding_id: R5-F01
severity: low
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/plan.md:L1311-L1312]
artifact: plan
round: 5
reviewer: security-claude
---

T43's test expectations cover two cases for the `g4-cache-probe.lock` freshness check: (a) lock file absent, and (b) lock file present with a mismatching `run_id:`. They do not specify the required behavior when the lock file exists but is malformed — for example, a file that is empty, binary, or was truncated mid-write by a crash during T33's atomic create step.

**What the spec says today.** T43 test expectations (plan.md L1312): "When the T33 spike report exists but its `run_id:` does not match the `run_id:` recorded in the colocated `g4-cache-probe.lock` sentinel file... T43's conditional-precondition evaluation exits with a loud diagnostic naming the stale-report condition." T36's test expectations (plan.md L1122) say: "When the lock file is absent, or when the report's `run_id:` does not match the lock's `run_id:`, the pin fails with a loud diagnostic."

Neither T43 nor T36 specifies the required behavior when the lock file exists but cannot be parsed to yield a run_id string. An implementation author reading these specs could reasonably choose any of: (a) treat parse failure as a run_id mismatch and fail loudly (safe), (b) treat parse failure as "absent" and fail loudly (safe), or (c) treat parse failure as a non-blocking warning and proceed with some default behavior (fail-open — unsafe, because T43 would then modify `<artifact-dir>/config.md` without verified spike freshness).

**The risk.** T33 creates the lock file atomically after a complete successful run. However, atomicity in shell scripts usually means `mv` from a temp file. If T33 dies between the temp write and the mv (e.g., OOM kill during a long probe), the lock file might not exist. But if the lock file was partially created by a different mechanism (race condition, operator manual touch, corrupted tmp-to-final rename on an NFS filesystem), the file could exist with 0 bytes or unparseable content. The consequence of option (c) above is that T43 would flip `emit_cache_control_markers: true` in config.md based on an unverified (possibly stale) spike report, contaminating the measurement integrity the dual-flag gate was designed to protect.

**Fix.** Add one test expectation to T43 covering the malformed-lock case:

> When the `g4-cache-probe.lock` file exists but its content cannot be parsed to extract a `run_id:` value (e.g., the file is empty, contains only whitespace, or contains no line matching the `run_id:` key pattern), T43's conditional-precondition evaluation treats the lock as malformed, exits with a loud diagnostic naming the malformed-lock condition (distinct from the stale-report and absent-lock diagnostics), and makes no edits to `<artifact-dir>/config.md`.

T36's `test-cache-hit-rate.bats` should similarly gain a malformed-lock fixture alongside its absent-lock and run_id-mismatch fixtures. This is the symmetric closure of the "fail loudly on any lock-file anomaly" contract the design intends.
