---
finding_id: R6-F02
reviewer_tag: code-quality-codex
round: 6
severity: medium
change_type: test-quality
referenced_files: [tests/unit/test-config-model-routing.bats:421-470, tests/unit/test-config-model-routing.bats:497-510]
---

# code-quality-codex F02 — present-but-unreadable CONFIG_MD untested

Behavioral tests cover CONFIG_MD unset/missing but NOT present-but-unreadable,
leaving the "distinct config-path diagnostic" branch unpinned for the exact
failure mode the resolver comments claim to defend against.

**Orchestrator adjudication: KEEP/FIX.** Bundled with the `-f`→`-r` fix
(code-quality-codex.F01 / silent-failure-codex.F03): add a present-but-unreadable
behavioral test asserting the truthful config-path halt.

Chat-only return persisted by orchestrator.
