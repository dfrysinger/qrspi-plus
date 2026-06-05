---
reviewer: test-coverage-codex
round: 5
finding_id: R5-F03
severity: low
change_type: correctness
referenced_files: [scripts/await-round.sh, tests/unit/test-await-round.bats]
---

# F03 — `await-round.sh` first-party-only no-op path not covered

task-20.md L56 expects first-party-only safety. tests/unit/test-await-round.bats:48-60 covers empty-manifest no-op but not a manifest containing only mode=first_party entries. await-round.sh:241-245 skips non-background entries — that branch is untested. Regression in first-party manifest handling would not be caught.
