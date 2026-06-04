---
finding_id: R3-F01
reviewer_tag: spec-codex
severity: low
change_type: clarity
referenced_files: [tests/unit/test-scope-tagger-dispatch.bats, scripts/round-prepare.sh]
---

# Prior-artifact failure tests assert `status -ne 0`, not the specific `exit 1`

**Observed:** The four prior-artifact loud-failure tests assert only non-zero exit:
- missing anchor — L736 (`-ne 0`)
- malformed anchor (new R2) — L759 (`-ne 0`)
- missing scope-set — L819 (`-ne 0`)
- empty scope-set (new R2) — L848 (`-ne 0`)

The corresponding `scripts/round-prepare.sh` branches all deterministically `exit 1` (L190, L202, L213, L217), distinct from the SHA-correctness codes exit 10 (L130), 11 (L170), 12 (L159). The sibling SHA-check tests DO pin exact codes (L653/672/690/714).

**Mitigating factor:** each test also asserts a unique diagnostic substring (`malformed`/`empty` + the specific filename), which already discriminates the branch — an exit-10/11/12 path would not emit those substrings. So the branch IS pinned via the message; only the exit-code number is loose.

**Residual risk:** a change that swapped a prior-artifact branch's `exit 1` for `exit 11` while keeping the message would silently drift the documented exit-code contract (1 = prior-artifact integrity; 11 = worktree integrity) without test failure.

**Disposition: ADOPT (uniform).** Tighten all four prior-artifact failure tests from `[ "$status" -ne 0 ]` to `[ "$status" -eq 1 ]` (with updated message text). Applied across all four siblings — not just the two new tests — to keep the family consistent. String-only assertion change; no refactor, no production-code change.
