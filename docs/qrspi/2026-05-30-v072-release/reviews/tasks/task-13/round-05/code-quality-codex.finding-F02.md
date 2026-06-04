---
finding_id: R5-F02
severity: low
change_type: test
referenced_files: [tests/unit/test-scope-tagger-dispatch.bats]
disposition: accepted-with-issues (declined — helper-extraction refactor out of cap-bend scope)
---

# F02 — DRY / test bootstrap duplication (non-blocking, declined)

Many new [T13] tests duplicate the repo/bootstrap sequence (mktemp, git init, base/r1/r2 commits,
mkdir task/round-*). cq-codex suggests extracting helpers (setup_repo, make_round_commits,
invoke_round_prepare).

DISPOSITION: Declined for this release. Extracting shared helpers would refactor the existing
passing tests (and the just-added ones), a substantive change beyond this additive cap-bend round.
bats idiom also favors explicit per-test fixtures for independent readability (cs-claude made the
same judgment call in round 4). Recorded as deferred test-hygiene.
