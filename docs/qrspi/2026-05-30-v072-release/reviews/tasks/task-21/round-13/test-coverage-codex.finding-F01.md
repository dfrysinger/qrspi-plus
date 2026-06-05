---
finding_id: R13-F01
severity: medium
change_type: scope
reviewer_tag: test-coverage-codex
referenced_files: [tests/unit/test-dispatch-agent.bats, scripts/dispatch-companion.sh]
---

# Missing behavioral test for `--prompt-file` raw-path boundary guard

Launch mode of `scripts/dispatch-companion.sh` accepts raw `--prompt-file`
(L606–617) and enforces boundary checks (L645–649, L660–664). Strong
behavioral tests exist for `--round-dir` rejection (test-dispatch-agent.bats
L1978–2056) but **none exist for `--prompt-file`**. The audit test
(L1735–1743) is structural and can pass without runtime enforcement, and
even allows a docs-only fallback branch.

Risk: a regression in `--prompt-file` boundary enforcement could land
green.

Suggested addition: launch-mode test that passes `--prompt-file` from
outside `$REPO_ROOT` (readable file) with in-repo `--round-dir`; assert
non-zero exit plus `resolves outside repository` diagnostic.
