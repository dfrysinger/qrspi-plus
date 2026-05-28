---
finding_id: R3-F01
severity: high
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-17-v07-release/plan.md:L1291-L1305
artifact: plan
round: 3
reviewer: silent-failure-claude
---

T43 reads the T33 spike report to determine whether to skip (Path A) or implement (Path B), but its test expectations have no requirement that T43 fails loudly when the spike report file is absent, malformed, or contains no recognizable decision line. This is a silent-default failure: if the report is missing at dispatch time, T43 has no specified behavior — it may silently default to Path A (skip, never insert markers) or silently default to Path B (insert markers unconditionally), either of which produces a wrong outcome with no caller-visible diagnostic.

By contrast, T36's `test-cache-hit-rate.bats` already has the analogous explicit check: "When the T33 spike-report deliverable is absent, malformed, or does not contain a recognizable Path A or Path B decision line, `test-cache-hit-rate.bats` fails with a loud diagnostic naming the missing/malformed prerequisite and does NOT silently default to either path." T43 has no equivalent requirement.

Additionally, T43's description says the decision-token is read from `docs/qrspi/2026-05-17-v07-release/spikes/g4-cache-probe.md`, but the test expectations do not specify what happens if the lock-file/run-ID freshness check (established by T33 and enforced by T36) fails at T43 dispatch time. T36 checks for stale report via the lock-file run-ID match before running BATS assertions. T43 has no analogous pre-flight check — it could silently consume a stale prior-run report and implement the wrong path.

**Fix:** Add a test expectation to T43 requiring that when the T33 spike-report file is absent, malformed, or contains no recognizable Path A or Path B decision line, T43's implementer dispatch fails with a loud diagnostic before making any change to `scripts/run-third-party-llm.sh` or writing any implementation log entry. Also add a test expectation that the lock-file run-ID freshness check from T33 is consulted before T43 reads the decision line, matching the same stale-report-detection contract T36 enforces.
