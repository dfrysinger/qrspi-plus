---
finding_id: F01
severity: high
change_type: correctness
referenced_files: [tests/unit/test-detect-interaction-mode.bats]
---
Claim: non-final assertions (lines 572/574/576) are vacuous under bats because "only the last command determines pass/fail." ORCHESTRATOR: DECLINED — FALSE POSITIVE. Empirically disproven: the suite carries `bats_require_minimum_version 1.5.0` (line 41), which opts into modern bats-core fail-fast semantics (test body runs under set -e + ERR trap). Verified on bats 1.13.0: a non-final `false` or non-final failing `grep -q` FAILS the test (see /tmp experiment — tests 1 & 2 failed at the non-final command). sf-claude saw the 1.5.0 line but wrongly concluded the opt-in was absent. All 46 tests pass and every assertion (final or not) is enforced. Same root misconception invalidates F02/F03/F04.
