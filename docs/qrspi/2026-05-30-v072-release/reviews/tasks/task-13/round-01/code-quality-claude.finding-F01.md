---
reviewer: code-quality-claude
task: 13
round: 1
severity: low
dimension: DRY
file: tests/unit/test-scope-tagger-dispatch.bats
---

## Finding F01 — Repeated git-repo setup boilerplate across the 8 `round-prepare.sh` integration tests

Eight new `[T13]` tests each stand up a throwaday git repo with the same opening
incantation (diff lines ~135-141, 161-169, 184-189, 197-202, 216-220, 237-243,
258-265, 280-290):

```bash
local tmp; tmp="$(mktemp -d)"
cd "$tmp"
git init -q
git -c user.email=t@t -c user.name=t commit --allow-empty -qm base
local base_sha; base_sha="$(git rev-parse HEAD)"
```

The `git -c user.email=t@t -c user.name=t commit --allow-empty -qm <msg>` line
alone is copy-pasted ~15 times. This is the dominant duplication in the new
block. Two small helpers — e.g. `_mk_repo` (mktemp + init + base commit, echoing
the base SHA) and `_commit <msg>` (the `-c user.*` commit + echo HEAD) — would
collapse each test's preamble to one or two lines and make the actual
behavior-under-test (the flags passed to `round-prepare.sh` and the asserted
exit code) the visually dominant part of each test.

Severity is low: the duplication is mechanical and harmless to correctness, but
it inflates the block by ~80 lines and means any change to the fixture shape
(e.g. git identity, default-branch naming) must be applied in eight places.
