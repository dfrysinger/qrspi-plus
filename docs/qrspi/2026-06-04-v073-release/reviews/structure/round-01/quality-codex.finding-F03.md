---
artifact: structure
reviewer_tag: quality-codex
finding_id: quality-codex-F03
change_type: clarity
severity: medium
location: docs/qrspi/2026-06-04-v073-release/structure.md:156-158
---

## `upstream-paths.sh` declares valid steps with no mapped behavior

The interface says `--step` is one of `goals | questions | research | design | phasing | structure | plan | parallelize | implement | integrate | test | replan`, but the File Map/test coverage only defines known-step expectations for Goals, Questions, Research, Design, Phasing, Structure, Parallelize, Replan, plus Plan's mode-aware branch.

If `implement`, `integrate`, and `test` are supported known steps, Structure needs their upstream artifact sets and tests. If they are meant to fall through as unknown-step always-appended-only behavior, remove them from the "One of" list or label them explicitly as accepted fallthrough values.
