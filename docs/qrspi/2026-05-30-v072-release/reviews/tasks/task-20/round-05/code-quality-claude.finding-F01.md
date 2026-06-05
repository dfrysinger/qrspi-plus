---
finding_id: R5-F01
reviewer: code-quality-claude
round: 5
severity: low
change_type: clarity
referenced_files:
  - tests/unit/test-dispatch-agent.bats
status: accepted-with-issues
---

# DRY: wrapper-capture diagnostic block copy-pasted across both e2e tests

The 14-line wrapper rc/stderr capture block at L1138-1155 (job_id test) is identical to L1222-1238 (drain test) except for an extra `rm -rf "$round_dir"` in test 1's early-exit path (unnecessary since round_dir lives under $TMP_DIR and teardown sweeps it).

A `run_wrapper_or_fail` BATS helper would collapse both call sites to a single line. **Accepted with issues** — minor refactor, deferred to v0.7.3 backlog. Does not block T20 closure.
