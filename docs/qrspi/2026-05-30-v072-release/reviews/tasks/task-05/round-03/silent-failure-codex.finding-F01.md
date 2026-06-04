---
finding_id: F01
reviewer_tag: silent-failure-codex
round: 3
severity: medium
change_type: correctness
referenced_files:
  - tests/unit/test-change-type-partition.bats:295-297
artifact: tests/unit/test-change-type-partition.bats
---

# Swallowed setup failures in symlink hardening test

Materialized from chat-only response by gpt-5.3-codex.

```bash
_run_fan_in_on_fixture "$src" \
  || true
```

This suppresses `_run_fan_in_on_fixture` non-zero returns, which are the helper's named setup-failure signals (95..99 for missing fixture, unsafe basename, mktemp/cp/pwd failures).

Silent-failure impact: the test continues even when sandbox setup fails, masking the real root cause; later assertions may fail (or pass under stale state) for the wrong reason. Defeats the helper contract comment that call sites must surface setup errors.

Fix: remove `|| true`; either require helper success here, or capture/validate the return code explicitly and fail loudly on setup-failure codes (95–99). If the test intentionally drives a known-failing helper path, capture `rc=$?` and assert the expected code, not blanket-suppress.
